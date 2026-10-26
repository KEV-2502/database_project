-- =============================================================================
-- BCSE302L - Database Systems | Review II & III: Real-World Transactions Demo
-- Project: Event and Ticket Booking System
-- Database: PostgreSQL 16+
-- Demonstrates 7 end-to-end transactional workflows matching Review II Section 9
-- =============================================================================

\echo '========================================================================'
\echo 'TRANSACTION 1: Customer books tickets atomically'
\echo 'Operation: Arjun Reddy (user 10) books GC-201 and GC-202 for Music Festival 2026'
\echo 'Procedures/Triggers: sp_book_tickets, trg_ticket_validate, trg_ticket_inventory'
\echo '========================================================================'
CALL sp_book_tickets(10, 2, ARRAY['GC-201', 'GC-202'], NULL);

SELECT b.booking_id, b.status, b.total_amount, t.seat_number, t.price, sc.available_seats
FROM BOOKING b
JOIN TICKET t ON t.booking_id = b.booking_id
JOIN SEAT_CATEGORY sc ON sc.category_id = t.category_id
WHERE b.booking_id = (SELECT MAX(booking_id) FROM BOOKING WHERE user_id = 10);

\echo '========================================================================'
\echo 'TRANSACTION 2: Payment fails, then succeeds on retry'
\echo 'Operation: Card declined, then customer retries and pays via UPI'
\echo 'Procedures/Triggers: sp_make_payment, trg_payment_confirm_booking'
\echo '========================================================================'
-- Step 2a: First attempt by card is declined
CALL sp_make_payment((SELECT MAX(booking_id) FROM BOOKING WHERE user_id = 10), 'CARD', FALSE);

-- Step 2b: Retry with UPI succeeds and auto-confirms booking via trigger
CALL sp_make_payment((SELECT MAX(booking_id) FROM BOOKING WHERE user_id = 10), 'UPI', TRUE);

SELECT p.payment_id, p.payment_method, p.amount_paid, p.status AS payment_status, b.status AS booking_status
FROM PAYMENT p 
JOIN BOOKING b ON b.booking_id = p.booking_id
WHERE b.booking_id = (SELECT MAX(booking_id) FROM BOOKING WHERE user_id = 10)
ORDER BY p.payment_id;

\echo '========================================================================'
\echo 'TRANSACTION 3: Double-booking attempt is blocked'
\echo 'Operation: Sneha Kulkarni tries to book seat GC-201 already held by Arjun'
\echo 'Integrity: UNIQUE constraint uq_category_seat causes entire procedure rollback'
\echo '========================================================================'
DO $$
BEGIN
    CALL sp_book_tickets(11, 2, ARRAY['GC-201'], NULL);
EXCEPTION WHEN unique_violation THEN
    RAISE NOTICE 'SUCCESSFULLY BLOCKED: Double-booking rejected by UNIQUE(category_id, seat_number)';
END $$;

\echo '========================================================================'
\echo 'TRANSACTION 4: Organizer cannot oversell venue capacity'
\echo 'Operation: Organizer tries to add 2000 seats to Royal Opera House (cap: 800)'
\echo 'Procedures/Triggers: trg_category_capacity raises exception before row write'
\echo '========================================================================'
DO $$
BEGIN
    INSERT INTO SEAT_CATEGORY (event_id, category_name, price, total_seats, available_seats)
    VALUES (3, 'Standing Promenade', 500.00, 2000, 2000);
EXCEPTION WHEN raise_exception THEN
    RAISE NOTICE 'SUCCESSFULLY BLOCKED: trg_category_capacity prevented venue overselling';
END $$;

\echo '========================================================================'
\echo 'TRANSACTION 5: Customer cancels booking with dynamic refund policy'
\echo 'Operation: Arjun cancels Hackathon passes (booking 15) 11 days before event'
\echo 'Procedures/Functions: sp_cancel_booking, fn_calculate_refund (75% tier)'
\echo '========================================================================'
CALL sp_cancel_booking(15, 'Could not attend Bangalore Hackathon');

SELECT b.booking_id, b.status AS booking_status, c.refund_amount, c.status AS cancel_status,
       (SELECT string_agg(seat_number || '=' || status, ', ') FROM TICKET WHERE booking_id = 15) AS ticket_states,
       (SELECT available_seats FROM SEAT_CATEGORY WHERE category_id = 24) AS team_pass_available_seats
FROM BOOKING b
JOIN CANCELLATION c ON c.booking_id = b.booking_id
WHERE b.booking_id = 15;

\echo '========================================================================'
\echo 'TRANSACTION 6: Administrator settles approved cancellations via Cursor'
\echo 'Operation: Nightly batch settlement loop processes APPROVED requests'
\echo 'Procedures/Cursors: sp_settle_approved_cancellations explicit cursor FOR UPDATE'
\echo '========================================================================'
CALL sp_settle_approved_cancellations();

SELECT c.cancel_id, c.booking_id, c.status AS cancel_status, c.refund_amount, b.status AS booking_status
FROM CANCELLATION c
JOIN BOOKING b ON b.booking_id = c.booking_id
WHERE c.cancel_id IN (4, 5)
ORDER BY c.cancel_id;

\echo '========================================================================'
\echo 'TRANSACTION 7: Unpaid checkouts released via Parameterized Cursor'
\echo 'Operation: Checkouts held in PENDING for over 24 hours are cancelled'
\echo 'Procedures/Cursors: sp_expire_stale_bookings parameterised cursor loop'
\echo '========================================================================'
CALL sp_expire_stale_bookings(INTERVAL '24 hours');

SELECT booking_id, user_id, booking_date, status
FROM BOOKING
WHERE booking_id IN (6, 22);
