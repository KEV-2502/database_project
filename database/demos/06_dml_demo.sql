-- =============================================================================
-- BCSE302L - Database Systems | Review II & III: DML Operations Demo
-- Project: Event and Ticket Booking System
-- Database: PostgreSQL 16+
-- Demonstrates realistic INSERT, UPDATE, DELETE & Constraint Rejections
-- =============================================================================

\echo '========================================================================'
\echo 'D1. INSERT: Register a new verified Event Organizer'
\echo '========================================================================'
INSERT INTO USERS (name, email, password_hash, phone, role)
VALUES ('Nikhil Joshi (Organizer)', 'nikhil.j@rajasthanlive.in',
        'scrypt:32768:8:1$salted_org_hash_8801', '+91-9977889900', 'ORGANIZER')
RETURNING user_id, name, role, created_at;

\echo '========================================================================'
\echo 'D2. INSERT: Schedule an event at the unused Jaipur venue (venue 10)'
\echo '========================================================================'
INSERT INTO EVENT (venue_id, organizer_id, event_name, event_date, event_time, description)
VALUES (10, (SELECT user_id FROM USERS WHERE email = 'nikhil.j@rajasthanlive.in'),
        'Rajasthan Folk Music Festival', '2027-02-14', '17:30:00',
        'Evening of Manganiyar and Langa folk music under the desert sky.')
RETURNING event_id, event_name, event_date, venue_id;

\echo '========================================================================'
\echo 'D3. INSERT: Add two seat categories for the new festival'
\echo 'trg_category_capacity validates: 300 + 1800 <= 2500 venue capacity'
\echo '========================================================================'
INSERT INTO SEAT_CATEGORY (event_id, category_name, price, total_seats, available_seats)
SELECT event_id, c.name, c.price, c.seats, c.seats
FROM EVENT,
     (VALUES ('Maharaja Enclosure', 1800.00, 300),
             ('Open Lawn', 450.00, 1800)) AS c(name, price, seats)
WHERE event_name = 'Rajasthan Folk Music Festival'
RETURNING category_id, event_id, category_name, price, total_seats;

\echo '========================================================================'
\echo 'D4. INSERT (Expected Error): Venue with zero capacity'
\echo 'CHECK (capacity > 0) strictly rejects invalid venues'
\echo '========================================================================'
DO $$
BEGIN
    INSERT INTO VENUE (venue_name, location, capacity)
    VALUES ('Pop-up Rooftop Stage', 'Indiranagar, Bangalore, Karnataka', 0);
EXCEPTION WHEN check_violation THEN
    RAISE NOTICE 'SUCCESSFULLY BLOCKED: Check constraint chk_venue_capacity rejected capacity = 0';
END $$;

\echo '========================================================================'
\echo 'D5. UPDATE: Organizer raises Comedy Showcase General Seating price by 10%'
\echo '========================================================================'
UPDATE SEAT_CATEGORY
SET price = ROUND(price * 1.10, 2)
WHERE event_id = 5 AND category_name = 'General Seating'
RETURNING category_id, category_name, price;

\echo '========================================================================'
\echo 'D6. DELETE: Organizer withdraws the newly created folk festival'
\echo 'ON DELETE CASCADE automatically removes child seat categories'
\echo '========================================================================'
DELETE FROM EVENT
WHERE event_name = 'Rajasthan Folk Music Festival'
RETURNING event_id, event_name;
