-- =============================================================================
-- BCSE302L - Database Systems | Review II: Comprehensive SQL Queries
-- Project: Event and Ticket Booking System
-- Database: PostgreSQL (15+)
-- Contains categorized queries for academic review, viva, and lab execution.
-- =============================================================================

-- =============================================================================
-- SECTION 1: BASIC SELECTION, FILTERING & STRING MATCHING
-- =============================================================================

-- Query 1.1: List all upcoming events in November and December 2026 ordered chronologically
SELECT event_id, event_name, event_date, event_time, description
FROM EVENT
WHERE event_date BETWEEN '2026-11-01' AND '2026-12-31'
ORDER BY event_date ASC, event_time ASC;

-- Query 1.2: Search for users registered with institutional academic emails (@vitstudent.ac.in)
SELECT user_id, name, email, phone, role
FROM USERS
WHERE email LIKE '%@vitstudent.ac.in'
ORDER BY name ASC;

-- Query 1.3: Retrieve high-capacity venues (capacity >= 2000) situated in metropolitan areas
SELECT venue_id, venue_name, location, capacity
FROM VENUE
WHERE capacity >= 2000
ORDER BY capacity DESC;

-- =============================================================================
-- SECTION 2: MULTI-TABLE JOINS (INNER, LEFT, AND MULTI-WAY)
-- =============================================================================

-- Query 2.1 [INNER JOIN]: Detailed booking receipts with Customer Name, Event Name, and Venue
SELECT 
    b.booking_id,
    u.name AS customer_name,
    u.email AS customer_email,
    e.event_name,
    e.event_date,
    v.venue_name,
    b.total_amount,
    b.status AS booking_status
FROM BOOKING b
JOIN USERS u ON b.user_id = u.user_id
JOIN EVENT e ON b.event_id = e.event_id
JOIN VENUE v ON e.venue_id = v.venue_id
ORDER BY b.booking_id ASC;

-- Query 2.2 [LEFT OUTER JOIN]: All venues and their hosted events (including venues with 0 events)
SELECT 
    v.venue_id,
    v.venue_name,
    v.location,
    v.capacity,
    COALESCE(e.event_name, '--- No Scheduled Event ---') AS scheduled_event,
    e.event_date
FROM VENUE v
LEFT JOIN EVENT e ON v.venue_id = e.venue_id
ORDER BY v.venue_id, e.event_date;

-- Query 2.3 [5-TABLE JOIN]: Comprehensive digital ticket breakdown for each attendee
SELECT 
    t.ticket_id,
    b.booking_id,
    u.name AS attendee_name,
    e.event_name,
    sc.category_name AS seat_tier,
    t.seat_number,
    t.price AS ticket_price,
    t.status AS ticket_status,
    v.venue_name
FROM TICKET t
JOIN BOOKING b ON t.booking_id = b.booking_id
JOIN USERS u ON b.user_id = u.user_id
JOIN SEAT_CATEGORY sc ON t.category_id = sc.category_id
JOIN EVENT e ON sc.event_id = e.event_id
JOIN VENUE v ON e.venue_id = v.venue_id
ORDER BY t.ticket_id ASC;

-- =============================================================================
-- SECTION 3: AGGREGATE FUNCTIONS, GROUP BY & HAVING CLAUSES
-- =============================================================================

-- Query 3.1: Total revenue, total tickets booked, and average ticket price per event
SELECT 
    e.event_id,
    e.event_name,
    COUNT(t.ticket_id) AS total_tickets_issued,
    COALESCE(SUM(t.price), 0.00) AS gross_ticket_sales,
    COALESCE(ROUND(AVG(t.price), 2), 0.00) AS avg_ticket_price
FROM EVENT e
LEFT JOIN SEAT_CATEGORY sc ON e.event_id = sc.event_id
LEFT JOIN TICKET t ON sc.category_id = t.category_id AND t.status = 'VALID'
GROUP BY e.event_id, e.event_name
ORDER BY gross_ticket_sales DESC;

-- Query 3.2 [HAVING Clause]: Organizers who have scheduled more than 1 event
SELECT 
    u.user_id AS organizer_id,
    u.name AS organizer_name,
    u.email,
    COUNT(e.event_id) AS total_events_organized
FROM USERS u
JOIN EVENT e ON u.user_id = e.organizer_id
WHERE u.role = 'ORGANIZER'
GROUP BY u.user_id, u.name, u.email
HAVING COUNT(e.event_id) > 1;

-- Query 3.3: Total booking count and revenue by payment method
SELECT 
    p.payment_method,
    COUNT(p.payment_id) AS total_transactions,
    SUM(CASE WHEN p.status = 'SUCCESS' THEN p.amount_paid ELSE 0 END) AS successful_amount,
    COUNT(CASE WHEN p.status = 'FAILED' THEN 1 END) AS failed_attempts
FROM PAYMENT p
GROUP BY p.payment_method
ORDER BY successful_amount DESC;

-- =============================================================================
-- SECTION 4: NESTED SUBQUERIES (SCALAR, IN, EXISTS)
-- =============================================================================

-- Query 4.1 [Scalar Subquery]: Seat categories priced higher than the overall average ticket price
SELECT 
    sc.category_id,
    e.event_name,
    sc.category_name,
    sc.price
FROM SEAT_CATEGORY sc
JOIN EVENT e ON sc.event_id = e.event_id
WHERE sc.price > (SELECT AVG(price) FROM SEAT_CATEGORY)
ORDER BY sc.price DESC;

-- Query 4.2 [Subquery with IN]: Customers who have placed at least one confirmed booking
SELECT user_id, name, email, phone
FROM USERS
WHERE user_id IN (
    SELECT DISTINCT user_id 
    FROM BOOKING 
    WHERE status = 'CONFIRMED'
);

-- Query 4.3 [Correlated Subquery with NOT EXISTS]: Customers who have never cancelled any booking
SELECT u.user_id, u.name, u.email
FROM USERS u
WHERE u.role = 'CUSTOMER'
  AND NOT EXISTS (
      SELECT 1 
      FROM BOOKING b
      JOIN CANCELLATION c ON b.booking_id = c.booking_id
      WHERE b.user_id = u.user_id
  );

-- Query 4.4 [Nested with ALL]: Event with the maximum single seat price
SELECT e.event_name, sc.category_name, sc.price
FROM SEAT_CATEGORY sc
JOIN EVENT e ON sc.event_id = e.event_id
WHERE sc.price >= ALL (SELECT price FROM SEAT_CATEGORY);

-- =============================================================================
-- SECTION 5: ADVANCED ANALYTICAL WINDOW FUNCTIONS
-- =============================================================================

-- Query 5.1 [DENSE_RANK]: Rank events based on gross revenue generated
SELECT 
    e.event_name,
    v.venue_name,
    COALESCE(SUM(b.total_amount), 0) AS total_revenue,
    DENSE_RANK() OVER (ORDER BY COALESCE(SUM(b.total_amount), 0) DESC) AS revenue_rank
FROM EVENT e
JOIN VENUE v ON e.venue_id = v.venue_id
LEFT JOIN BOOKING b ON e.event_id = b.event_id AND b.status = 'CONFIRMED'
GROUP BY e.event_id, e.event_name, v.venue_name;

-- Query 5.2 [ROW_NUMBER & Running Total]: Cumulative revenue progression over time
SELECT 
    b.booking_id,
    b.booking_date,
    u.name AS customer_name,
    b.total_amount,
    ROW_NUMBER() OVER (ORDER BY b.booking_date) AS booking_sequence,
    SUM(b.total_amount) OVER (ORDER BY b.booking_date ROWS BETWEEN UNBOUNDED PRECEDING AND CURRENT ROW) AS cumulative_revenue
FROM BOOKING b
JOIN USERS u ON b.user_id = u.user_id
WHERE b.status = 'CONFIRMED'
ORDER BY b.booking_date;

-- =============================================================================
-- SECTION 6: DATABASE VIEWS
-- =============================================================================

-- View 6.1: Public catalog of upcoming events with venue details and available tickets
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

-- View 6.2: Customer Digital Ticket Wallet View
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

-- Sample invocation of views
SELECT * FROM v_public_event_catalog ORDER BY event_date ASC;
SELECT * FROM v_customer_ticket_wallet WHERE user_id = 4;
