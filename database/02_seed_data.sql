-- =============================================================================
-- BCSE302L - Database Systems | Review II & III: Comprehensive Seed Data (DML)
-- Project: Event and Ticket Booking System
-- Database: PostgreSQL 16+
-- Authors: Kevin T John (24BYB0163), Govind B Nair (24BYB0101), Shaarav S (24BYB0118)
--
-- Exactly matches the Review II Report specification:
--   VENUE: 10 | USERS: 16 | EVENT: 12 | SEAT_CATEGORY: 26 |
--   BOOKING: 25 | TICKET: 36 | PAYMENT: 27 | CANCELLATION: 10
-- =============================================================================

-- Clear existing data in reverse dependency order
TRUNCATE TABLE CANCELLATION, PAYMENT, TICKET, BOOKING, SEAT_CATEGORY, EVENT, USERS, VENUE RESTART IDENTITY CASCADE;

-- -----------------------------------------------------------------------------
-- 1. SEED VENUES (10 Venues across major Indian tech and cultural hubs)
-- -----------------------------------------------------------------------------
INSERT INTO VENUE (venue_id, venue_name, location, capacity) VALUES
(1,  'Grand Arena Exhibition Centre',      'Whitefield, Bangalore, Karnataka',         5000),
(2,  'Tech Park International Auditorium',  'OMR Road, Chennai, Tamil Nadu',            1200),
(3,  'Royal Opera House Heritage Hall',     'Charni Road, Mumbai, Maharashtra',          800),
(4,  'Jawaharlal Nehru National Stadium',   'Lodhi Road, New Delhi, Delhi',            25000),
(5,  'Palace Grounds Convention Centre',    'Bellary Road, Bangalore, Karnataka',      15000),
(6,  'Netaji Indoor Stadium',               'Eden Gardens, Kolkata, West Bengal',      12000),
(7,  'Shilpakala Vedika',                   'Hitec City, Hyderabad, Telangana',         2500),
(8,  'Marine Drive Open Grounds',           'Ernakulam, Kochi, Kerala',                 8000),
(9,  'Siri Fort Auditorium',                'August Kranti Marg, New Delhi, Delhi',     1800),
(10, 'Rajasthan International Centre',      'Jhalana Doongri, Jaipur, Rajasthan',       2500);

SELECT setval('venue_venue_id_seq', 10);

-- -----------------------------------------------------------------------------
-- 2. SEED USERS (16 Principals: 1 Admin, 3 Organizers, 12 Customers)
-- -----------------------------------------------------------------------------
INSERT INTO USERS (user_id, name, email, password_hash, phone, role) VALUES
-- Admin
(1,  'Amit Sharma (Admin)',       'admin@ticketpro.com',                'scrypt:32768:8:1$salted_admin_hash_9812', '+91-9876543210', 'ADMIN'),
-- Organizers
(2,  'Priya Nair (Organizer)',    'priya.events@pulse.com',             'scrypt:32768:8:1$salted_org_hash_1102',   '+91-9811223344', 'ORGANIZER'),
(3,  'Rohan Patel (Organizer)',   'rohan.patel@liveent.in',             'scrypt:32768:8:1$salted_org_hash_4491',   '+91-9822334455', 'ORGANIZER'),
(9,  'Meera Kapoor (Organizer)',  'meera.k@stagecraft.in',              'scrypt:32768:8:1$salted_org_hash_7719',   '+91-9833445566', 'ORGANIZER'),
-- Academic Customers (@vitstudent.ac.in)
(4,  'Kevin T John',              'kevin.john2024@vitstudent.ac.in',    'scrypt:32768:8:1$salted_usr_hash_3321',   '+91-9445566778', 'CUSTOMER'),
(5,  'Govind B Nair',             'govind.nair2024@vitstudent.ac.in',   'scrypt:32768:8:1$salted_usr_hash_5542',   '+91-9556677889', 'CUSTOMER'),
(6,  'Shaarav S',                 'shaarav.s2024@vitstudent.ac.in',     'scrypt:32768:8:1$salted_usr_hash_7761',   '+91-9667788990', 'CUSTOMER'),
(7,  'Ananya Iyer',               'ananya.iyer@vitstudent.ac.in',       'scrypt:32768:8:1$salted_usr_hash_8892',   '+91-9778899001', 'CUSTOMER'),
(10, 'Arjun Reddy',               'arjun.reddy2024@vitstudent.ac.in',   'scrypt:32768:8:1$salted_usr_hash_1029',   '+91-9900112233', 'CUSTOMER'),
(13, 'Divya Menon',               'divya.menon2024@vitstudent.ac.in',   'scrypt:32768:8:1$salted_usr_hash_1304',   '+91-9933445566', 'CUSTOMER'),
-- Professional Customers
(8,  'Rahul Verma',               'rahul.verma@techcorp.com',           'scrypt:32768:8:1$salted_usr_hash_9901',   '+91-9889900112', 'CUSTOMER'),
(11, 'Sneha Kulkarni',            'sneha.kulkarni@globaltech.com',      'scrypt:32768:8:1$salted_usr_hash_1182',   '+91-9911223344', 'CUSTOMER'),
(12, 'Aditya Rao',                'aditya.rao@innovate.org',            'scrypt:32768:8:1$salted_usr_hash_1293',   '+91-9922334455', 'CUSTOMER'),
(14, 'Vikram Malhotra',           'vikram.m@fintech.io',                'scrypt:32768:8:1$salted_usr_hash_1415',   '+91-9944556677', 'CUSTOMER'),
(15, 'Fatima Sheikh',             'fatima.sheikh@designstudio.com',     'scrypt:32768:8:1$salted_usr_hash_1526',   '+91-9955667788', 'CUSTOMER'),
(16, 'Rajesh Kumar',              'rajesh.k@logistics.net',             'scrypt:32768:8:1$salted_usr_hash_1637',   '+91-9966778899', 'CUSTOMER');

SELECT setval('users_user_id_seq', 16);

-- -----------------------------------------------------------------------------
-- 3. SEED EVENTS (12 Events across venues and organizers)
-- -----------------------------------------------------------------------------
INSERT INTO EVENT (event_id, venue_id, organizer_id, event_name, event_date, event_time, description) VALUES
(1,  1, 2, 'ElectroBeat Music Festival 2026',         '2026-11-20', '18:00:00', 'Premier annual electronic music concert featuring international and domestic EDM artists.'),
(2,  2, 3, 'National AI & Cloud Architecture Summit', '2026-12-05', '09:30:00', 'A full-day conference exploring Generative AI, distributed databases, and high-scale cloud platforms.'),
(3,  3, 2, 'Symphony of Strings: Classical Gala',      '2026-10-30', '19:00:00', 'An enchanting acoustic orchestral evening performing Indian and Western classical compositions.'),
(4,  4, 3, 'All-India Inter-University T20 Final',    '2026-11-15', '14:30:00', 'Championship clash of the premier collegiate cricket tournament with 25,000 live spectators.'),
(5,  2, 2, 'Comedy Spotlight Live: Standup Showcase',  '2026-12-18', '20:00:00', 'An uncensored evening of stand-up comedy with 4 top headlining acts.'),
(6,  7, 3, 'Hyderabad Startup & Innovation Expo 2026', '2026-11-08', '10:00:00', 'Two-hall expo where 150 startups exhibit deep tech prototypes to VC investors.'),
(7,  6, 2, 'Arijit Singh Live in Concert',             '2026-12-24', '18:30:00', 'Mega stadium musical performance with an 80-piece live orchestra and visual spectacle.'),
(8,  1, 2, 'VIT Riviera Cultural Night',               '2026-11-28', '17:00:00', 'Flagship inter-university annual cultural festival pro-show and awards ceremony.'),
(9,  8, 9, 'Kochi Global Literature & Arts Fest',      '2026-12-12', '10:00:00', 'Coastal literature dialogues, author panels, book releases, and regional art workshops.'),
(10, 9, 9, 'Delhi International Film Premiere',        '2026-11-22', '19:00:00', 'Red carpet gala screening of award-winning independent world cinema features.'),
(11, 1, 3, 'Bangalore Tech Hackathon Finale',          '2026-10-25', '09:00:00', '48-hour continuous coding sprint where top 50 student teams present AI solutions.'),
(12, 7, 9, 'National Cyber Defense Conclave',          '2026-12-02', '10:00:00', 'Cybersecurity summit addressing zero trust architecture, threat intelligence, and forensics.');

SELECT setval('event_event_id_seq', 12);

-- -----------------------------------------------------------------------------
-- 4. SEED SEAT CATEGORIES (26 Categories)
-- -----------------------------------------------------------------------------
INSERT INTO SEAT_CATEGORY (category_id, event_id, category_name, price, total_seats, available_seats) VALUES
-- Event 1: ElectroBeat Music Festival (Venue cap: 5000)
(1,  1,  'VIP Lounge',            3500.00,  200,   200),
(2,  1,  'Golden Circle',         1800.00,  800,   798),
(3,  1,  'General Admission',      950.00, 2500,  2500),

-- Event 2: AI Summit (Venue cap: 1200)
(4,  2,  'Corporate Delegate',    2800.00,  300,   299),
(5,  2,  'Student Pass',           850.00,  500,   500),

-- Event 3: Classical Gala (Venue cap: 800)
(6,  3,  'Royal Box',             4000.00,   50,    50),
(7,  3,  'Orchestra Stalls',      1500.00,  350,   350),

-- Event 4: T20 Final (Venue cap: 25000)
(8,  4,  'Pavilion Club',         4500.00, 1000,  1000),
(9,  4,  'East Stand Tier-1',     1600.00, 4000,  3998),
(10, 4,  'North General Stand',    600.00, 12000, 12000),

-- Event 5: Standup Comedy (Venue cap: 1200)
(11, 5,  'Front Row Premium',     1200.00,  100,    98),
(12, 5,  'General Seating',        600.00,  400,   400),

-- Event 6: Startup Expo (Venue cap: 2500)
(13, 6,  'Platinum Delegate',     2500.00,  400,   400),
(14, 6,  'Visitor Expo Pass',      500.00, 1500,  1500),

-- Event 7: Arijit Singh Concert (Venue cap: 12000)
(15, 7,  'Platinum Floor',        5000.00,  500,   498),
(16, 7,  'Gold Tier',             2800.00, 2500,  2499),
(17, 7,  'Silver Bleachers',      1200.00, 6000,  5999),

-- Event 8: Riviera Night (Venue cap: 5000)
(18, 8,  'Pro-Show VIP',          1500.00, 1000,  1000),
(19, 8,  'Student General',        300.00, 3500,  3500),

-- Event 9: Literature Fest (Venue cap: 8000)
(20, 9,  'Festival Delegate',     1200.00,  800,   800),
(21, 9,  'Single Day Pass',        400.00, 2000,  2000),

-- Event 10: Film Premiere (Venue cap: 1800)
(22, 10, 'Red Carpet Premiere',   3000.00,  300,   300),
(23, 10, 'General Screening',      750.00, 1000,  1000),

-- Event 11: Hackathon Finale (Venue cap: 5000)
(24, 11, 'Team Pass',             1000.00,  200,   197),
(25, 11, 'Observer Pass',          300.00,  500,   500),

-- Event 12: Cyber Defense (Venue cap: 2500)
(26, 12, 'Security Pro Pass',     3500.00,  300,   300);

SELECT setval('seat_category_category_id_seq', 26);

-- -----------------------------------------------------------------------------
-- 5. SEED BOOKINGS (25 Bookings: Covers Confirmed, Cancelled, and Pending)
-- -----------------------------------------------------------------------------
INSERT INTO BOOKING (booking_id, event_id, user_id, booking_date, total_amount, status) VALUES
(1,   1,  4,  '2026-10-01 10:15:00', 3600.00, 'CONFIRMED'),
(2,   2,  5,  '2026-10-03 14:20:00', 2800.00, 'CONFIRMED'),
(3,   4,  6,  '2026-10-05 16:45:00', 3200.00, 'CONFIRMED'),
(4,   3,  7,  '2026-10-07 11:30:00', 4000.00, 'CANCELLED'),
(5,   5,  8,  '2026-10-08 19:10:00', 2400.00, 'CONFIRMED'),
(6,   4,  4,  '2026-10-09 21:05:00', 4500.00, 'PENDING'),
(7,   6,  10, '2026-09-02 12:00:00',  500.00, 'CONFIRMED'),
(8,   6,  13, '2026-09-05 17:40:00',  500.00, 'CONFIRMED'),
(9,   7,  11, '2026-10-10 11:00:00', 5000.00, 'CONFIRMED'),
(10,  7,  11, '2026-10-10 11:15:00', 5000.00, 'CONFIRMED'),
(11,  7,  11, '2026-10-10 11:30:00', 2000.00, 'CONFIRMED'),
(12,  7,  6,  '2026-10-11 15:00:00', 2400.00, 'CONFIRMED'),
(13,  1,  14, '2026-10-12 10:00:00', 3500.00, 'CONFIRMED'),
(14,  2,  12, '2026-10-12 12:30:00', 2800.00, 'CANCELLED'),
(15,  11, 10, '2026-10-12 14:00:00', 3000.00, 'CONFIRMED'),
(16,  8,  7,  '2026-10-12 16:00:00', 3000.00, 'CONFIRMED'),
(17,  1,  15, '2026-10-13 09:00:00', 7000.00, 'CONFIRMED'),
(18,  5,  16, '2026-10-13 14:00:00', 1200.00, 'CONFIRMED'),
(19,  9,  5,  '2026-10-13 15:30:00', 1200.00, 'CONFIRMED'),
(20,  10, 8,  '2026-10-13 17:00:00', 3000.00, 'CONFIRMED'),
(21,  12, 11, '2026-10-13 18:30:00', 3500.00, 'CONFIRMED'),
(22,  4,  5,  '2026-10-13 09:15:00', 1600.00, 'PENDING'),
(23,  1,  13, '2026-10-13 20:00:00', 1800.00, 'CONFIRMED'),
(24,  11, 15, '2026-10-14 08:30:00',  600.00, 'CONFIRMED'),
(25,  8,  4,  '2026-10-14 09:00:00',  600.00, 'CANCELLED');

SELECT setval('booking_booking_id_seq', 25);

-- -----------------------------------------------------------------------------
-- 6. SEED TICKETS (36 Tickets: VALID, CANCELLED, and USED)
-- -----------------------------------------------------------------------------
INSERT INTO TICKET (ticket_id, booking_id, category_id, seat_number, price, status) VALUES
-- Booking 1 (ElectroBeat: Golden Circle)
(1,  1,  2,  'GC-101', 1800.00, 'VALID'),
(2,  1,  2,  'GC-102', 1800.00, 'VALID'),

-- Booking 2 (AI Summit: Corporate Delegate)
(3,  2,  4,  'DEL-042', 2800.00, 'VALID'),

-- Booking 3 (T20 Final: East Stand Tier-1)
(4,  3,  9,  'ES1-501', 1600.00, 'VALID'),
(5,  3,  9,  'ES1-502', 1600.00, 'VALID'),

-- Booking 4 (Classical Gala: Royal Box -> Cancelled)
(6,  4,  6,  'RB-012', 4000.00, 'CANCELLED'),

-- Booking 5 (Standup Comedy: Front Row Premium)
(7,  5,  11, 'FR-005', 1200.00, 'VALID'),
(8,  5,  11, 'FR-006', 1200.00, 'VALID'),

-- Booking 6 (Pending stale booking tickets)
(9,  6,  8,  'PC-015', 4500.00, 'VALID'),

-- Bookings 7 & 8 (Startup Expo Visitor)
(10, 7,  14, 'EXP-001', 500.00, 'VALID'),
(11, 8,  14, 'EXP-002', 500.00, 'VALID'),

-- Bookings 9, 10, 11 (Arijit Singh Concert)
(12, 9,  15, 'PF-001', 5000.00, 'VALID'),
(13, 10, 15, 'PF-002', 5000.00, 'VALID'),
(14, 11, 17, 'SB-101', 1000.00, 'VALID'),
(15, 11, 17, 'SB-102', 1000.00, 'VALID'),

-- Booking 12 (Arijit Singh Concert)
(16, 12, 17, 'SB-201', 1200.00, 'VALID'),
(17, 12, 17, 'SB-202', 1200.00, 'VALID'),

-- Booking 13 (ElectroBeat VIP)
(18, 13, 1,  'VIP-001', 3500.00, 'VALID'),

-- Booking 14 (AI Summit Corporate -> Cancelled)
(19, 14, 4,  'DEL-099', 2800.00, 'CANCELLED'),

-- Booking 15 (Hackathon Team Pass)
(20, 15, 24, 'TEAM-045', 1000.00, 'VALID'),
(21, 15, 24, 'TEAM-046', 1000.00, 'VALID'),
(22, 15, 24, 'TEAM-047', 1000.00, 'VALID'),

-- Booking 16 (Riviera VIP)
(23, 16, 18, 'VIP-050', 1500.00, 'VALID'),
(24, 16, 18, 'VIP-051', 1500.00, 'VALID'),

-- Booking 17 (ElectroBeat VIP)
(25, 17, 1,  'VIP-010', 3500.00, 'VALID'),
(26, 17, 1,  'VIP-011', 3500.00, 'VALID'),

-- Booking 18 (Standup Front Row)
(27, 18, 11, 'FR-020', 1200.00, 'VALID'),

-- Booking 19 (Literature Fest)
(28, 19, 20, 'LIT-008', 1200.00, 'VALID'),

-- Booking 20 (Film Premiere Red Carpet)
(29, 20, 22, 'RC-001', 3000.00, 'VALID'),

-- Booking 21 (Cyber Defense Pro)
(30, 21, 26, 'SEC-005', 3500.00, 'VALID'),

-- Booking 22 (Pending stale checkout)
(31, 22, 9,  'ES1-777', 1600.00, 'VALID'),

-- Booking 23 (ElectroBeat Golden Circle)
(32, 23, 2,  'GC-301', 1800.00, 'VALID'),

-- Booking 24 (Hackathon Observer)
(33, 24, 25, 'OBS-010', 300.00, 'VALID'),
(34, 24, 25, 'OBS-011', 300.00, 'VALID'),

-- Booking 25 (Riviera Student General -> Cancelled)
(35, 25, 19, 'STU-001', 300.00, 'CANCELLED'),
(36, 25, 19, 'STU-002', 300.00, 'CANCELLED');

SELECT setval('ticket_ticket_id_seq', 36);

-- -----------------------------------------------------------------------------
-- 7. SEED PAYMENTS (27 Transactions: Multi-attempt retries, UPI, Cards, NetBanking)
-- -----------------------------------------------------------------------------
INSERT INTO PAYMENT (payment_id, booking_id, payment_date, amount_paid, payment_method, status) VALUES
(1,  1,  '2026-10-01 10:16:30', 3600.00, 'UPI',         'SUCCESS'),
(2,  2,  '2026-10-03 14:22:15', 2800.00, 'CARD',        'SUCCESS'),
(3,  3,  '2026-10-05 16:46:10', 3200.00, 'NET_BANKING', 'FAILED'),
(4,  3,  '2026-10-05 16:48:02', 3200.00, 'UPI',         'SUCCESS'),
(5,  4,  '2026-10-07 11:32:00', 4000.00, 'CARD',        'REFUNDED'),
(6,  5,  '2026-10-08 19:12:45', 2400.00, 'UPI',         'SUCCESS'),
(7,  6,  '2026-10-09 21:06:50', 4500.00, 'CARD',        'FAILED'),
(8,  7,  '2026-09-02 12:02:10',  500.00, 'UPI',         'SUCCESS'),
(9,  8,  '2026-09-05 17:42:00',  500.00, 'WALLET',      'SUCCESS'),
(10, 9,  '2026-10-10 11:02:00', 5000.00, 'CARD',        'SUCCESS'),
(11, 10, '2026-10-10 11:16:30', 5000.00, 'CARD',        'SUCCESS'),
(12, 11, '2026-10-10 11:31:00', 2000.00, 'UPI',         'SUCCESS'),
(13, 12, '2026-10-11 15:02:15', 2400.00, 'UPI',         'SUCCESS'),
(14, 13, '2026-10-12 10:03:00', 3500.00, 'NET_BANKING', 'SUCCESS'),
(15, 14, '2026-10-12 12:31:40', 2800.00, 'CARD',        'REFUNDED'),
(16, 15, '2026-10-12 14:02:00', 3000.00, 'UPI',         'SUCCESS'),
(17, 16, '2026-10-12 16:03:00', 3000.00, 'CARD',        'SUCCESS'),
(18, 17, '2026-10-13 09:02:30', 7000.00, 'CARD',        'SUCCESS'),
(19, 18, '2026-10-13 14:02:00', 1200.00, 'UPI',         'SUCCESS'),
(20, 19, '2026-10-13 15:32:00', 1200.00, 'NET_BANKING', 'SUCCESS'),
(21, 20, '2026-10-13 17:02:15', 3000.00, 'UPI',         'SUCCESS'),
(22, 21, '2026-10-13 18:32:00', 3500.00, 'CARD',        'SUCCESS'),
(23, 22, '2026-10-13 09:16:00', 1600.00, 'UPI',         'PENDING'),
(24, 23, '2026-10-13 20:02:00', 1800.00, 'UPI',         'SUCCESS'),
(25, 24, '2026-10-14 08:32:00',  600.00, 'WALLET',      'SUCCESS'),
(26, 25, '2026-10-14 09:02:00',  600.00, 'CARD',        'REFUNDED'),
(27, 1,  '2026-10-01 10:15:30', 3600.00, 'UPI',         'FAILED');

SELECT setval('payment_payment_id_seq', 27);

-- -----------------------------------------------------------------------------
-- 8. SEED CANCELLATION (10 Records: PROCESSED, APPROVED, REQUESTED, REJECTED)
-- -----------------------------------------------------------------------------
INSERT INTO CANCELLATION (cancel_id, booking_id, cancel_date, reason, refund_amount, status) VALUES
(1,  4,  '2026-10-07 15:40:00', 'Schedule conflict with academic conference', 4000.00, 'PROCESSED'),
(2,  14, '2026-10-12 18:00:00', 'Medical emergency in family',                 2200.00, 'PROCESSED'),
(3,  13, '2026-10-13 12:00:00', 'Client meeting scheduled on festival day',    3000.00, 'REQUESTED'),
(4,  16, '2026-10-13 17:00:00', 'Travel arrangements fell through',             2250.00, 'APPROVED'),
(5,  18, '2026-10-13 19:30:00', 'Event overlaps with company dinner',            900.00, 'APPROVED'),
(6,  19, '2026-10-13 20:15:00', 'Accidental double checkout by family',         1200.00, 'REQUESTED'),
(7,  20, '2026-10-13 21:00:00', 'Flight cancelled, cannot reach Delhi',         1500.00, 'REJECTED'),
(8,  21, '2026-10-13 22:30:00', 'Personal emergency',                           1750.00, 'REQUESTED'),
(9,  23, '2026-10-14 07:00:00', 'Work deadline shifted',                        1350.00, 'REQUESTED'),
(10, 25, '2026-10-14 09:15:00', 'Could not attend Riviera cultural night',       400.00, 'PROCESSED');

SELECT setval('cancellation_cancel_id_seq', 10);

-- -----------------------------------------------------------------------------
-- 9. SYNCHRONIZE DERIVED INVENTORY & BOOKING TOTALS
-- -----------------------------------------------------------------------------
UPDATE SEAT_CATEGORY sc
SET available_seats = total_seats - COALESCE((
    SELECT COUNT(*) 
    FROM TICKET t 
    WHERE t.category_id = sc.category_id AND t.status IN ('VALID', 'USED')
), 0);

UPDATE BOOKING b
SET total_amount = COALESCE((
    SELECT SUM(t.price) 
    FROM TICKET t 
    WHERE t.booking_id = b.booking_id
), 0.00);
