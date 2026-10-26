-- =============================================================================
-- BCSE302L - Database Systems | Review II & III: Stored Procedures, Functions,
-- Cursors, and Triggers (PL/pgSQL)
-- Project: Event and Ticket Booking System
-- Database: PostgreSQL 16+
-- Authors: Kevin T John (24BYB0163), Govind B Nair (24BYB0101), Shaarav S (24BYB0118)
-- =============================================================================

-- Clean up existing triggers and routines
DROP TRIGGER IF EXISTS trg_category_capacity ON SEAT_CATEGORY CASCADE;
DROP TRIGGER IF EXISTS trg_ticket_validate ON TICKET CASCADE;
DROP TRIGGER IF EXISTS trg_ticket_inventory ON TICKET CASCADE;
DROP TRIGGER IF EXISTS trg_payment_confirm_booking ON PAYMENT CASCADE;

DROP FUNCTION IF EXISTS trgfn_category_capacity() CASCADE;
DROP FUNCTION IF EXISTS trgfn_ticket_validate() CASCADE;
DROP FUNCTION IF EXISTS trgfn_ticket_inventory() CASCADE;
DROP FUNCTION IF EXISTS trgfn_payment_confirm_booking() CASCADE;

DROP PROCEDURE IF EXISTS sp_book_tickets(INT, INT, TEXT[], INT) CASCADE;
DROP PROCEDURE IF EXISTS sp_make_payment(INT, VARCHAR, BOOLEAN) CASCADE;
DROP PROCEDURE IF EXISTS sp_cancel_booking(INT, TEXT) CASCADE;
DROP PROCEDURE IF EXISTS sp_settle_approved_cancellations() CASCADE;
DROP PROCEDURE IF EXISTS sp_expire_stale_bookings(INTERVAL) CASCADE;

DROP FUNCTION IF EXISTS fn_calculate_refund(INT, TIMESTAMP) CASCADE;
DROP FUNCTION IF EXISTS fn_event_occupancy(INT) CASCADE;
DROP FUNCTION IF EXISTS fn_customer_lifetime_spend(INT) CASCADE;

-- =============================================================================
-- SECTION 1: BUSINESS FUNCTIONS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Function 1: fn_calculate_refund
-- Applies standard tiered refund policy based on days left before event date:
--   >= 14 days : 100% refund
--   7-13 days  : 75% refund
--   2-6 days   : 50% refund
--   < 2 days   : 0% refund
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_calculate_refund(
    p_booking_id INT,
    p_cancel_date TIMESTAMP DEFAULT CURRENT_TIMESTAMP
) RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_amount NUMERIC(10, 2);
    v_event_date DATE;
    v_days_left INT;
    v_percent NUMERIC;
BEGIN
    SELECT b.total_amount, e.event_date
    INTO v_amount, v_event_date
    FROM BOOKING b
    JOIN EVENT e ON e.event_id = b.event_id
    WHERE b.booking_id = p_booking_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking % does not exist', p_booking_id;
    END IF;

    v_days_left := v_event_date - p_cancel_date::DATE;

    v_percent := CASE
        WHEN v_days_left >= 14 THEN 1.00
        WHEN v_days_left >= 7  THEN 0.75
        WHEN v_days_left >= 2  THEN 0.50
        ELSE 0.00
    END;

    RETURN ROUND(v_amount * v_percent, 2);
END;
$$;

-- -----------------------------------------------------------------------------
-- Function 2: fn_event_occupancy
-- Computes seat occupancy percentage for an event across all its categories.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_event_occupancy(p_event_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_total INT;
    v_free INT;
BEGIN
    SELECT SUM(total_seats), SUM(available_seats)
    INTO v_total, v_free
    FROM SEAT_CATEGORY
    WHERE event_id = p_event_id;

    IF v_total IS NULL OR v_total = 0 THEN
        RETURN 0.00;
    END IF;

    RETURN ROUND((v_total - v_free) * 100.0 / v_total, 2);
END;
$$;

-- -----------------------------------------------------------------------------
-- Function 3: fn_customer_lifetime_spend
-- Calculates aggregate lifetime successful payments made by a customer.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION fn_customer_lifetime_spend(p_user_id INT)
RETURNS NUMERIC
LANGUAGE plpgsql
AS $$
DECLARE
    v_total NUMERIC(10, 2);
BEGIN
    SELECT COALESCE(SUM(p.amount_paid), 0.00)
    INTO v_total
    FROM PAYMENT p
    JOIN BOOKING b ON p.booking_id = b.booking_id
    WHERE b.user_id = p_user_id AND p.status = 'SUCCESS';

    RETURN v_total;
END;
$$;

-- =============================================================================
-- SECTION 2: TRIGGERS & TRIGGER FUNCTIONS
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Trigger 1: trg_category_capacity
-- Prevents event organizers from defining seats that exceed venue capacity.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trgfn_category_capacity()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_venue_cap INT;
    v_curr_total INT;
    v_new_total INT;
BEGIN
    SELECT v.capacity INTO v_venue_cap
    FROM EVENT e
    JOIN VENUE v ON e.venue_id = v.venue_id
    WHERE e.event_id = NEW.event_id;

    SELECT COALESCE(SUM(total_seats), 0) INTO v_curr_total
    FROM SEAT_CATEGORY
    WHERE event_id = NEW.event_id
      AND (TG_OP = 'INSERT' OR category_id <> NEW.category_id);

    v_new_total := v_curr_total + NEW.total_seats;

    IF v_new_total > v_venue_cap THEN
        RAISE EXCEPTION 'Venue over-allocation: event % would have % seats but the venue holds only %',
            NEW.event_id, v_new_total, v_venue_cap;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_category_capacity
BEFORE INSERT OR UPDATE ON SEAT_CATEGORY
FOR EACH ROW EXECUTE FUNCTION trgfn_category_capacity();

-- -----------------------------------------------------------------------------
-- Trigger 2: trg_ticket_validate
-- Ensures seat category matches event and sets the ticket price automatically.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trgfn_ticket_validate()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
DECLARE
    v_booking_event INT;
    v_booking_status VARCHAR(20);
    v_cat_event INT;
    v_cat_price NUMERIC(10, 2);
BEGIN
    SELECT event_id, status INTO v_booking_event, v_booking_status
    FROM BOOKING WHERE booking_id = NEW.booking_id;

    SELECT event_id, price INTO v_cat_event, v_cat_price
    FROM SEAT_CATEGORY WHERE category_id = NEW.category_id;

    IF v_booking_status = 'CANCELLED' THEN
        RAISE EXCEPTION 'Booking % is cancelled; no new tickets can be issued', NEW.booking_id;
    END IF;

    IF v_cat_event <> v_booking_event THEN
        RAISE EXCEPTION 'Seat category % belongs to event %, but booking % is for event %',
            NEW.category_id, v_cat_event, NEW.booking_id, v_booking_event;
    END IF;

    -- Automatically assign authoritative price from seat category
    NEW.price := v_cat_price;
    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_ticket_validate
BEFORE INSERT ON TICKET
FOR EACH ROW EXECUTE FUNCTION trgfn_ticket_validate();

-- -----------------------------------------------------------------------------
-- Trigger 3: trg_ticket_inventory
-- Keeps available_seats and booking total_amount synchronized in real-time.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trgfn_ticket_inventory()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF TG_OP = 'INSERT' THEN
        IF NEW.status IN ('VALID', 'USED') THEN
            UPDATE SEAT_CATEGORY 
            SET available_seats = available_seats - 1
            WHERE category_id = NEW.category_id;
        END IF;

        UPDATE BOOKING 
        SET total_amount = total_amount + NEW.price
        WHERE booking_id = NEW.booking_id;

        RETURN NEW;

    ELSIF TG_OP = 'UPDATE' THEN
        IF OLD.status IN ('VALID', 'USED') AND NEW.status = 'CANCELLED' THEN
            UPDATE SEAT_CATEGORY 
            SET available_seats = available_seats + 1
            WHERE category_id = NEW.category_id;
        ELSIF OLD.status = 'CANCELLED' AND NEW.status IN ('VALID', 'USED') THEN
            UPDATE SEAT_CATEGORY 
            SET available_seats = available_seats - 1
            WHERE category_id = NEW.category_id;
        END IF;

        RETURN NEW;

    ELSE -- DELETE
        IF OLD.status IN ('VALID', 'USED') THEN
            UPDATE SEAT_CATEGORY 
            SET available_seats = available_seats + 1
            WHERE category_id = OLD.category_id;

            UPDATE BOOKING 
            SET total_amount = GREATEST(total_amount - OLD.price, 0)
            WHERE booking_id = OLD.booking_id;
        END IF;

        RETURN OLD;
    END IF;
END;
$$;

CREATE TRIGGER trg_ticket_inventory
AFTER INSERT OR UPDATE OF status OR DELETE ON TICKET
FOR EACH ROW EXECUTE FUNCTION trgfn_ticket_inventory();

-- -----------------------------------------------------------------------------
-- Trigger 4: trg_payment_confirm_booking
-- Confirms booking status automatically when a SUCCESS payment is recorded.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE FUNCTION trgfn_payment_confirm_booking()
RETURNS TRIGGER
LANGUAGE plpgsql
AS $$
BEGIN
    IF NEW.status = 'SUCCESS' THEN
        UPDATE BOOKING
        SET status = 'CONFIRMED'
        WHERE booking_id = NEW.booking_id AND status = 'PENDING';

        RAISE NOTICE 'Booking % confirmed by payment %', NEW.booking_id, NEW.payment_id;
    END IF;

    RETURN NEW;
END;
$$;

CREATE TRIGGER trg_payment_confirm_booking
AFTER INSERT OR UPDATE OF status ON PAYMENT
FOR EACH ROW EXECUTE FUNCTION trgfn_payment_confirm_booking();

-- =============================================================================
-- SECTION 3: STORED PROCEDURES
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Procedure 1: sp_book_tickets
-- Atomically reserves one or more seats for a customer in a seat category.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_book_tickets(
    p_user_id INT,
    p_category_id INT,
    p_seats TEXT[],
    INOUT p_booking_id INT DEFAULT NULL
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_role VARCHAR(20);
    v_event_id INT;
    v_event_date DATE;
    v_available INT;
    v_seat TEXT;
BEGIN
    -- Verify customer role
    SELECT role INTO v_role FROM USERS WHERE user_id = p_user_id;
    IF v_role IS DISTINCT FROM 'CUSTOMER' THEN
        RAISE EXCEPTION 'User % is not a customer and cannot book tickets', p_user_id;
    END IF;

    -- Verify category existence, date, and availability
    SELECT sc.event_id, e.event_date, sc.available_seats
    INTO v_event_id, v_event_date, v_available
    FROM SEAT_CATEGORY sc 
    JOIN EVENT e ON e.event_id = sc.event_id
    WHERE sc.category_id = p_category_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Seat category % does not exist', p_category_id;
    END IF;

    IF v_event_date < CURRENT_DATE THEN
        RAISE EXCEPTION 'Event % has already taken place', v_event_id;
    END IF;

    IF v_available < array_length(p_seats, 1) THEN
        RAISE EXCEPTION 'Only % seat(s) left in category %', v_available, p_category_id;
    END IF;

    -- Create initial pending booking
    INSERT INTO BOOKING (event_id, user_id, total_amount, status)
    VALUES (v_event_id, p_user_id, 0.00, 'PENDING')
    RETURNING booking_id INTO p_booking_id;

    -- Insert each ticket (triggers will validate, price, and deduct available seats)
    FOREACH v_seat IN ARRAY p_seats LOOP
        INSERT INTO TICKET (booking_id, category_id, seat_number, price)
        VALUES (p_booking_id, p_category_id, v_seat, 0.00);
    END LOOP;

    RAISE NOTICE 'Booking % created for user % with % ticket(s)',
        p_booking_id, p_user_id, array_length(p_seats, 1);
END;
$$;

-- -----------------------------------------------------------------------------
-- Procedure 2: sp_make_payment
-- Records a payment attempt for a pending booking and handles retries.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_make_payment(
    p_booking_id INT,
    p_payment_method VARCHAR,
    p_simulate_success BOOLEAN DEFAULT TRUE
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_amount NUMERIC(10, 2);
    v_status VARCHAR(20);
    v_pay_status VARCHAR(20);
BEGIN
    SELECT status, total_amount INTO v_status, v_amount
    FROM BOOKING WHERE booking_id = p_booking_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking % does not exist', p_booking_id;
    END IF;

    IF v_status <> 'PENDING' THEN
        RAISE EXCEPTION 'Booking % is not in PENDING status (current: %)', p_booking_id, v_status;
    END IF;

    IF p_simulate_success THEN
        v_pay_status := 'SUCCESS';
    ELSE
        v_pay_status := 'FAILED';
    END IF;

    INSERT INTO PAYMENT (booking_id, payment_date, amount_paid, payment_method, status)
    VALUES (p_booking_id, CURRENT_TIMESTAMP, v_amount, p_payment_method, v_pay_status);

    RAISE NOTICE 'Payment of % via % for booking %: %', v_amount, p_payment_method, p_booking_id, v_pay_status;
END;
$$;

-- -----------------------------------------------------------------------------
-- Procedure 3: sp_cancel_booking
-- Immediately processes a cancellation request and calculates refund.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_cancel_booking(
    p_booking_id INT,
    p_reason TEXT
)
LANGUAGE plpgsql
AS $$
DECLARE
    v_status VARCHAR(20);
    v_refund NUMERIC(10, 2);
BEGIN
    SELECT status INTO v_status FROM BOOKING WHERE booking_id = p_booking_id;

    IF NOT FOUND THEN
        RAISE EXCEPTION 'Booking % does not exist', p_booking_id;
    END IF;

    IF v_status = 'CANCELLED' THEN
        RAISE EXCEPTION 'Booking % is already cancelled', p_booking_id;
    END IF;

    -- Calculate policy-based refund
    v_refund := fn_calculate_refund(p_booking_id);

    -- Record processed cancellation
    INSERT INTO CANCELLATION (booking_id, cancel_date, reason, refund_amount, status)
    VALUES (p_booking_id, CURRENT_TIMESTAMP, p_reason, v_refund, 'PROCESSED');

    -- Update tickets (returns inventory via trg_ticket_inventory)
    UPDATE TICKET SET status = 'CANCELLED' 
    WHERE booking_id = p_booking_id AND status = 'VALID';

    -- Update payment records to REFUNDED
    UPDATE PAYMENT SET status = 'REFUNDED' 
    WHERE booking_id = p_booking_id AND status = 'SUCCESS';

    -- Update booking status
    UPDATE BOOKING SET status = 'CANCELLED' 
    WHERE booking_id = p_booking_id;

    RAISE NOTICE 'Booking % cancelled, refund of % issued', p_booking_id, v_refund;
END;
$$;

-- =============================================================================
-- SECTION 4: CURSORS (BATCH ADMINISTRATIVE JOBS)
-- =============================================================================

-- -----------------------------------------------------------------------------
-- Cursor 1: sp_settle_approved_cancellations
-- Nightly admin batch job processing APPROVED cancellations using explicit cursor.
-- Employs FOR UPDATE OF c and WHERE CURRENT OF for concurrency protection.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_settle_approved_cancellations()
LANGUAGE plpgsql
AS $$
DECLARE
    cur_requests CURSOR FOR
        SELECT c.cancel_id, c.booking_id, c.cancel_date, u.name AS customer
        FROM CANCELLATION c
        JOIN BOOKING b ON b.booking_id = c.booking_id
        JOIN USERS u ON u.user_id = b.user_id
        WHERE c.status = 'APPROVED'
        ORDER BY c.cancel_date
        FOR UPDATE OF c;
    rec RECORD;
    v_refund NUMERIC(10, 2);
    v_count INT := 0;
    v_total NUMERIC(12, 2) := 0;
BEGIN
    OPEN cur_requests;
    LOOP
        FETCH cur_requests INTO rec;
        EXIT WHEN NOT FOUND;

        v_refund := fn_calculate_refund(rec.booking_id, rec.cancel_date);

        UPDATE TICKET SET status = 'CANCELLED' 
        WHERE booking_id = rec.booking_id AND status = 'VALID';

        UPDATE PAYMENT SET status = 'REFUNDED' 
        WHERE booking_id = rec.booking_id AND status = 'SUCCESS';

        UPDATE BOOKING SET status = 'CANCELLED' 
        WHERE booking_id = rec.booking_id;

        UPDATE CANCELLATION
        SET status = 'PROCESSED', refund_amount = v_refund
        WHERE CURRENT OF cur_requests;

        v_count := v_count + 1;
        v_total := v_total + v_refund;

        RAISE NOTICE 'Settled request % | booking % | % | refund %',
            rec.cancel_id, rec.booking_id, rec.customer, v_refund;
    END LOOP;
    CLOSE cur_requests;

    RAISE NOTICE 'Settlement complete: % request(s), total refunded %', v_count, v_total;
END;
$$;

-- -----------------------------------------------------------------------------
-- Cursor 2: sp_expire_stale_bookings
-- Releases unpaid checkout reservations using a parameterized cursor.
-- -----------------------------------------------------------------------------
CREATE OR REPLACE PROCEDURE sp_expire_stale_bookings(
    p_hold INTERVAL DEFAULT INTERVAL '24 hours'
)
LANGUAGE plpgsql
AS $$
DECLARE
    cur_stale CURSOR (p_cutoff TIMESTAMP) FOR
        SELECT b.booking_id, b.user_id, b.booking_date
        FROM BOOKING b
        WHERE b.status = 'PENDING'
          AND b.booking_date < p_cutoff
          AND NOT EXISTS (
              SELECT 1 FROM PAYMENT p
              WHERE p.booking_id = b.booking_id AND p.status = 'SUCCESS'
          );
    v_count INT := 0;
BEGIN
    FOR rec IN cur_stale(CURRENT_TIMESTAMP - p_hold) LOOP
        UPDATE TICKET SET status = 'CANCELLED' 
        WHERE booking_id = rec.booking_id AND status = 'VALID';

        UPDATE PAYMENT SET status = 'FAILED' 
        WHERE booking_id = rec.booking_id AND status = 'PENDING';

        UPDATE BOOKING SET status = 'CANCELLED' 
        WHERE booking_id = rec.booking_id;

        v_count := v_count + 1;
        RAISE NOTICE 'Expired booking % (user %, held since %)',
            rec.booking_id, rec.user_id, rec.booking_date;
    END LOOP;

    RAISE NOTICE '% stale booking(s) expired', v_count;
END;
$$;

-- =============================================================================
-- SECTION 5: RELATIONAL DATABASE VIEWS
-- =============================================================================

-- View 1: Public event catalog with computed remaining seats and starting prices
CREATE OR REPLACE VIEW v_public_event_catalog AS
SELECT 
    e.event_id,
    e.event_name,
    e.event_date,
    e.event_time,
    v.venue_name,
    v.location,
    u.name AS organizer_name,
    COALESCE(SUM(sc.available_seats), 0) AS remaining_seats,
    COALESCE(MIN(sc.price), 0.00) AS starting_price_inr
FROM EVENT e
JOIN VENUE v ON e.venue_id = v.venue_id
JOIN USERS u ON e.organizer_id = u.user_id
LEFT JOIN SEAT_CATEGORY sc ON e.event_id = sc.event_id
GROUP BY e.event_id, e.event_name, e.event_date, e.event_time, v.venue_name, v.location, u.name;

-- View 2: Customer digital ticket wallet
CREATE OR REPLACE VIEW v_customer_ticket_wallet AS
SELECT 
    b.user_id,
    u.name AS customer_name,
    b.booking_id,
    e.event_name,
    e.event_date,
    e.event_time,
    v.venue_name,
    t.ticket_id,
    sc.category_name AS tier,
    t.seat_number,
    t.price,
    t.status AS ticket_status
FROM TICKET t
JOIN BOOKING b ON t.booking_id = b.booking_id
JOIN USERS u ON b.user_id = u.user_id
JOIN SEAT_CATEGORY sc ON t.category_id = sc.category_id
JOIN EVENT e ON sc.event_id = e.event_id
JOIN VENUE v ON e.venue_id = v.venue_id;
