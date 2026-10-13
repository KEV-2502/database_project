-- =============================================================================
-- BCSE302L - Database Systems | Review II: Seed Data (DML)
-- Project: Event and Ticket Booking System
-- Database: PostgreSQL (15+)
-- =============================================================================

-- Clear existing data
TRUNCATE TABLE CANCELLATION, PAYMENT, TICKET, BOOKING, SEAT_CATEGORY, EVENT, USERS, VENUE RESTART IDENTITY CASCADE;

-- -----------------------------------------------------------------------------
-- 1. SEED VENUES
-- -----------------------------------------------------------------------------
INSERT INTO VENUE (venue_name, location, capacity) VALUES
('Grand Arena Exhibition Centre', 'Whitefield, Bangalore, Karnataka', 5000),
('Tech Park International Auditorium', 'OMR Road, Chennai, Tamil Nadu', 1200),
('Royal Opera House Heritage Hall', 'Charni Road, Mumbai, Maharashtra', 800),
('Jawaharlal Nehru National Stadium', 'Lodhi Road, New Delhi, Delhi', 25000);

-- -----------------------------------------------------------------------------
-- 2. SEED USERS (Admin, Organizers, and Customers)
-- -----------------------------------------------------------------------------
INSERT INTO USERS (name, email, password_hash, phone, role) VALUES
('Amit Sharma (Admin)', 'admin@ticketpro.com', 'scrypt:32768:8:1$salted_admin_hash_9812', '+91-9876543210', 'ADMIN'),
('Priya Nair (Organizer)', 'priya.events@pulse.com', 'scrypt:32768:8:1$salted_org_hash_1102', '+91-9811223344', 'ORGANIZER'),
('Rohan Patel (Organizer)', 'rohan.patel@liveent.in', 'scrypt:32768:8:1$salted_org_hash_4491', '+91-9822334455', 'ORGANIZER'),
('Kevin T John', 'kevin.john2024@vitstudent.ac.in', 'scrypt:32768:8:1$salted_usr_hash_3321', '+91-9445566778', 'CUSTOMER'),
('Govind B Nair', 'govind.nair2024@vitstudent.ac.in', 'scrypt:32768:8:1$salted_usr_hash_5542', '+91-9556677889', 'CUSTOMER'),
('Shaarav S', 'shaarav.s2024@vitstudent.ac.in', 'scrypt:32768:8:1$salted_usr_hash_7761', '+91-9667788990', 'CUSTOMER'),
('Ananya Iyer', 'ananya.iyer@vitstudent.ac.in', 'scrypt:32768:8:1$salted_usr_hash_8892', '+91-9778899001', 'CUSTOMER'),
('Rahul Verma', 'rahul.verma@techcorp.com', 'scrypt:32768:8:1$salted_usr_hash_9901', '+91-9889900112', 'CUSTOMER');

-- -----------------------------------------------------------------------------
-- 3. SEED EVENTS
-- -----------------------------------------------------------------------------
INSERT INTO EVENT (venue_id, organizer_id, event_name, event_date, event_time, description) VALUES
(1, 2, 'ElectroBeat Music Festival 2026', '2026-11-20', '18:00:00', 'Premier annual electronic music concert featuring international and domestic EDM artists.'),
(2, 3, 'National AI & Cloud Architecture Summit', '2026-12-05', '09:30:00', 'A full-day conference exploring Generative AI, distributed databases, and high-scale cloud platforms.'),
(3, 2, 'Symphony of Strings: Classical Gala', '2026-10-30', '19:00:00', 'An enchanting acoustic orchestral evening performing Indian and Western classical compositions.'),
(4, 3, 'All-India Inter-University T20 Final', '2026-11-15', '14:30:00', 'Championship clash of the premier collegiate cricket tournament with 25,000 live spectators.'),
(2, 2, 'Comedy Spotlight Live: Standup Showcase', '2026-12-18', '20:00:00', 'An uncensored evening of stand-up comedy with 4 top headlining acts.');

-- -----------------------------------------------------------------------------
-- 4. SEED SEAT CATEGORIES (Quotas & Pricing)
-- -----------------------------------------------------------------------------
-- ElectroBeat Festival (event_id: 1)
INSERT INTO SEAT_CATEGORY (event_id, category_name, price, total_seats, available_seats) VALUES
(1, 'VIP Lounge', 3500.00, 200, 200),
(1, 'Golden Circle', 1800.00, 800, 798),   -- 2 booked
(1, 'General Admission', 950.00, 2500, 2500);

-- AI Summit (event_id: 2)
INSERT INTO SEAT_CATEGORY (event_id, category_name, price, total_seats, available_seats) VALUES
(2, 'Corporate Delegate', 2800.00, 300, 299), -- 1 booked
(2, 'Student Pass', 850.00, 500, 500);

-- Classical Gala (event_id: 3)
INSERT INTO SEAT_CATEGORY (event_id, category_name, price, total_seats, available_seats) VALUES
(3, 'Royal Box', 4000.00, 50, 50),            -- 1 booked then cancelled -> restored
(3, 'Orchestra Stalls', 1500.00, 350, 350);

-- Cricket Final (event_id: 4)
INSERT INTO SEAT_CATEGORY (event_id, category_name, price, total_seats, available_seats) VALUES
(4, 'Pavilion Club', 4500.00, 1000, 1000),
(4, 'East Stand Tier-1', 1600.00, 4000, 3998),-- 2 booked
(4, 'North General Stand', 600.00, 12000, 12000);

-- Standup Showcase (event_id: 5)
INSERT INTO SEAT_CATEGORY (event_id, category_name, price, total_seats, available_seats) VALUES
(5, 'Front Row Premium', 1200.00, 100, 98),   -- 2 booked
(5, 'General Seating', 600.00, 400, 400);

-- -----------------------------------------------------------------------------
-- 5. SEED BOOKINGS
-- -----------------------------------------------------------------------------
-- Booking 1: Kevin books 2 Golden Circle tickets for EDM (CONFIRMED)
INSERT INTO BOOKING (booking_id, event_id, user_id, booking_date, total_amount, status) VALUES
(1, 1, 4, '2026-10-01 10:15:00', 3600.00, 'CONFIRMED');

-- Booking 2: Govind books 1 Corporate Delegate pass for AI Summit (CONFIRMED)
INSERT INTO BOOKING (booking_id, event_id, user_id, booking_date, total_amount, status) VALUES
(2, 2, 5, '2026-10-03 14:20:00', 2800.00, 'CONFIRMED');

-- Booking 3: Shaarav books 2 East Stand tickets for Cricket Final (CONFIRMED)
INSERT INTO BOOKING (booking_id, event_id, user_id, booking_date, total_amount, status) VALUES
(3, 4, 6, '2026-10-05 16:45:00', 3200.00, 'CONFIRMED');

-- Booking 4: Ananya books 1 Royal Box ticket (CANCELLED)
INSERT INTO BOOKING (booking_id, event_id, user_id, booking_date, total_amount, status) VALUES
(4, 3, 7, '2026-10-07 11:30:00', 4000.00, 'CANCELLED');

-- Booking 5: Rahul books 2 Front Row tickets for Standup (CONFIRMED)
INSERT INTO BOOKING (booking_id, event_id, user_id, booking_date, total_amount, status) VALUES
(5, 5, 8, '2026-10-08 19:10:00', 2400.00, 'CONFIRMED');

-- Booking 6: Kevin attempts to book Pavilion Club ticket (PENDING / failed attempt)
INSERT INTO BOOKING (booking_id, event_id, user_id, booking_date, total_amount, status) VALUES
(6, 4, 4, '2026-10-09 21:05:00', 4500.00, 'PENDING');

-- Adjust sequence for booking_id
SELECT setval('booking_booking_id_seq', (SELECT MAX(booking_id) FROM BOOKING));

-- -----------------------------------------------------------------------------
-- 6. SEED TICKETS
-- -----------------------------------------------------------------------------
-- Booking 1 (EDM, Golden Circle: category_id 2)
INSERT INTO TICKET (booking_id, category_id, seat_number, price, status) VALUES
(1, 2, 'GC-101', 1800.00, 'VALID'),
(1, 2, 'GC-102', 1800.00, 'VALID');

-- Booking 2 (AI Summit, Corporate Delegate: category_id 4)
INSERT INTO TICKET (booking_id, category_id, seat_number, price, status) VALUES
(2, 4, 'DEL-042', 2800.00, 'VALID');

-- Booking 3 (Cricket Final, East Stand: category_id 7)
INSERT INTO TICKET (booking_id, category_id, seat_number, price, status) VALUES
(3, 7, 'ES1-501', 1600.00, 'VALID'),
(3, 7, 'ES1-502', 1600.00, 'VALID');

-- Booking 4 (Classical Gala, Royal Box: category_id 5) -> CANCELLED
INSERT INTO TICKET (booking_id, category_id, seat_number, price, status) VALUES
(4, 5, 'RB-012', 4000.00, 'CANCELLED');

-- Booking 5 (Standup Showcase, Front Row: category_id 9)
INSERT INTO TICKET (booking_id, category_id, seat_number, price, status) VALUES
(5, 9, 'FR-005', 1200.00, 'VALID'),
(5, 9, 'FR-006', 1200.00, 'VALID');

-- -----------------------------------------------------------------------------
-- 7. SEED PAYMENTS (Including multi-attempt history)
-- -----------------------------------------------------------------------------
-- Booking 1: Successful UPI payment
INSERT INTO PAYMENT (booking_id, payment_date, amount_paid, payment_method, status) VALUES
(1, '2026-10-01 10:16:30', 3600.00, 'UPI', 'SUCCESS');

-- Booking 2: Successful Card payment
INSERT INTO PAYMENT (booking_id, payment_date, amount_paid, payment_method, status) VALUES
(2, '2026-10-03 14:22:15', 2800.00, 'CARD', 'SUCCESS');

-- Booking 3: First attempt NET_BANKING failed (server timeout), second attempt UPI succeeded!
INSERT INTO PAYMENT (booking_id, payment_date, amount_paid, payment_method, status) VALUES
(3, '2026-10-05 16:46:10', 3200.00, 'NET_BANKING', 'FAILED'),
(3, '2026-10-05 16:48:02', 3200.00, 'UPI', 'SUCCESS');

-- Booking 4: Payment succeeded initially, later marked REFUNDED
INSERT INTO PAYMENT (booking_id, payment_date, amount_paid, payment_method, status) VALUES
(4, '2026-10-07 11:32:00', 4000.00, 'CARD', 'REFUNDED');

-- Booking 5: Successful UPI payment
INSERT INTO PAYMENT (booking_id, payment_date, amount_paid, payment_method, status) VALUES
(5, '2026-10-08 19:12:45', 2400.00, 'UPI', 'SUCCESS');

-- Booking 6: Payment failed (insufficient balance), remains PENDING
INSERT INTO PAYMENT (booking_id, payment_date, amount_paid, payment_method, status) VALUES
(6, '2026-10-09 21:06:50', 4500.00, 'CARD', 'FAILED');

-- -----------------------------------------------------------------------------
-- 8. SEED CANCELLATION
-- -----------------------------------------------------------------------------
-- Booking 4 was cancelled 23 days before event (eligible for 100% refund)
INSERT INTO CANCELLATION (booking_id, cancel_date, reason, refund_amount, status) VALUES
(4, '2026-10-07 15:40:00', 'Schedule conflict due to out-of-town academic conference', 4000.00, 'PROCESSED');
