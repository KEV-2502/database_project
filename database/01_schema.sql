-- =============================================================================
-- BCSE302L - Database Systems | Review II: Schema Definition (DDL)
-- Project: Event and Ticket Booking System
-- Database: PostgreSQL (15+)
-- Authors: Kevin T John (24BYB0163), Govind B Nair (24BYB0101), Shaarav S (24BYB0118)
-- =============================================================================

-- Clean up existing tables in reverse dependency order
DROP TABLE IF EXISTS CANCELLATION CASCADE;
DROP TABLE IF EXISTS PAYMENT CASCADE;
DROP TABLE IF EXISTS TICKET CASCADE;
DROP TABLE IF EXISTS BOOKING CASCADE;
DROP TABLE IF EXISTS SEAT_CATEGORY CASCADE;
DROP TABLE IF EXISTS EVENT CASCADE;
DROP TABLE IF EXISTS USERS CASCADE;
DROP TABLE IF EXISTS VENUE CASCADE;

-- -----------------------------------------------------------------------------
-- 1. VENUE TABLE
-- Stores physical venue facilities, addresses, and overall capacity.
-- -----------------------------------------------------------------------------
CREATE TABLE VENUE (
    venue_id SERIAL PRIMARY KEY,
    venue_name VARCHAR(150) NOT NULL,
    location VARCHAR(255) NOT NULL,
    capacity INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_venue_capacity CHECK (capacity > 0)
);

-- -----------------------------------------------------------------------------
-- 2. USERS TABLE
-- Stores platform actors: Customers, Organizers, and Administrators.
-- -----------------------------------------------------------------------------
CREATE TABLE USERS (
    user_id SERIAL PRIMARY KEY,
    name VARCHAR(100) NOT NULL,
    email VARCHAR(150) NOT NULL UNIQUE,
    password_hash VARCHAR(255) NOT NULL,
    phone VARCHAR(20) NOT NULL UNIQUE,
    role VARCHAR(20) NOT NULL DEFAULT 'CUSTOMER',
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_user_role CHECK (role IN ('CUSTOMER', 'ORGANIZER', 'ADMIN'))
);

-- -----------------------------------------------------------------------------
-- 3. EVENT TABLE
-- Events created by an ORGANIZER and hosted at a VENUE.
-- -----------------------------------------------------------------------------
CREATE TABLE EVENT (
    event_id SERIAL PRIMARY KEY,
    venue_id INT NOT NULL,
    organizer_id INT NOT NULL,
    event_name VARCHAR(200) NOT NULL,
    event_date DATE NOT NULL,
    event_time TIME NOT NULL,
    description TEXT,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT fk_event_venue FOREIGN KEY (venue_id) 
        REFERENCES VENUE(venue_id) ON DELETE RESTRICT,
    CONSTRAINT fk_event_organizer FOREIGN KEY (organizer_id) 
        REFERENCES USERS(user_id) ON DELETE RESTRICT
);

-- -----------------------------------------------------------------------------
-- 4. SEAT_CATEGORY TABLE
-- Pricing tiers and seating quotas per event.
-- -----------------------------------------------------------------------------
CREATE TABLE SEAT_CATEGORY (
    category_id SERIAL PRIMARY KEY,
    event_id INT NOT NULL,
    category_name VARCHAR(50) NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    total_seats INT NOT NULL,
    available_seats INT NOT NULL,
    CONSTRAINT fk_category_event FOREIGN KEY (event_id) 
        REFERENCES EVENT(event_id) ON DELETE CASCADE,
    CONSTRAINT chk_category_price CHECK (price >= 0),
    CONSTRAINT chk_category_total_seats CHECK (total_seats > 0),
    CONSTRAINT chk_category_available_seats CHECK (available_seats >= 0 AND available_seats <= total_seats)
);

-- -----------------------------------------------------------------------------
-- 5. BOOKING TABLE
-- Customer reservations linked to an event.
-- -----------------------------------------------------------------------------
CREATE TABLE BOOKING (
    booking_id SERIAL PRIMARY KEY,
    event_id INT NOT NULL,
    user_id INT NOT NULL,
    booking_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    total_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    CONSTRAINT fk_booking_event FOREIGN KEY (event_id) 
        REFERENCES EVENT(event_id) ON DELETE RESTRICT,
    CONSTRAINT fk_booking_user FOREIGN KEY (user_id) 
        REFERENCES USERS(user_id) ON DELETE RESTRICT,
    CONSTRAINT chk_booking_total_amount CHECK (total_amount >= 0),
    CONSTRAINT chk_booking_status CHECK (status IN ('PENDING', 'CONFIRMED', 'CANCELLED'))
);

-- -----------------------------------------------------------------------------
-- 6. TICKET TABLE
-- Individual admission passes generated upon booking.
-- Unique seat numbers within a seat category prevent double booking.
-- -----------------------------------------------------------------------------
CREATE TABLE TICKET (
    ticket_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL,
    category_id INT NOT NULL,
    seat_number VARCHAR(20) NOT NULL,
    price NUMERIC(10, 2) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'VALID',
    CONSTRAINT fk_ticket_booking FOREIGN KEY (booking_id) 
        REFERENCES BOOKING(booking_id) ON DELETE CASCADE,
    CONSTRAINT fk_ticket_category FOREIGN KEY (category_id) 
        REFERENCES SEAT_CATEGORY(category_id) ON DELETE RESTRICT,
    CONSTRAINT uq_category_seat UNIQUE (category_id, seat_number),
    CONSTRAINT chk_ticket_price CHECK (price >= 0),
    CONSTRAINT chk_ticket_status CHECK (status IN ('VALID', 'USED', 'CANCELLED'))
);

-- -----------------------------------------------------------------------------
-- 7. PAYMENT TABLE
-- Financial transactions per booking.
-- Supports 1:N cardinality for handling retried or multiple attempts.
-- -----------------------------------------------------------------------------
CREATE TABLE PAYMENT (
    payment_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL,
    payment_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    amount_paid NUMERIC(10, 2) NOT NULL,
    payment_method VARCHAR(30) NOT NULL,
    status VARCHAR(20) NOT NULL DEFAULT 'PENDING',
    CONSTRAINT fk_payment_booking FOREIGN KEY (booking_id) 
        REFERENCES BOOKING(booking_id) ON DELETE CASCADE,
    CONSTRAINT chk_payment_amount CHECK (amount_paid >= 0),
    CONSTRAINT chk_payment_method CHECK (payment_method IN ('CARD', 'UPI', 'NET_BANKING', 'WALLET')),
    CONSTRAINT chk_payment_status CHECK (status IN ('SUCCESS', 'FAILED', 'PENDING', 'REFUNDED'))
);

-- -----------------------------------------------------------------------------
-- 8. CANCELLATION TABLE
-- Records booking cancellation and refund metadata.
-- 1:0..1 relationship enforced with UNIQUE(booking_id).
-- -----------------------------------------------------------------------------
CREATE TABLE CANCELLATION (
    cancel_id SERIAL PRIMARY KEY,
    booking_id INT NOT NULL UNIQUE,
    cancel_date TIMESTAMP NOT NULL DEFAULT CURRENT_TIMESTAMP,
    reason TEXT,
    refund_amount NUMERIC(10, 2) NOT NULL DEFAULT 0.00,
    status VARCHAR(20) NOT NULL DEFAULT 'REQUESTED',
    CONSTRAINT fk_cancel_booking FOREIGN KEY (booking_id) 
        REFERENCES BOOKING(booking_id) ON DELETE CASCADE,
    CONSTRAINT chk_cancel_refund CHECK (refund_amount >= 0),
    CONSTRAINT chk_cancel_status CHECK (status IN ('REQUESTED', 'APPROVED', 'PROCESSED', 'REJECTED'))
);

-- -----------------------------------------------------------------------------
-- Indexes for performance optimization on frequent queries & foreign keys
-- -----------------------------------------------------------------------------
CREATE INDEX idx_event_date ON EVENT(event_date);
CREATE INDEX idx_booking_user ON BOOKING(user_id);
CREATE INDEX idx_booking_event ON BOOKING(event_id);
CREATE INDEX idx_ticket_booking ON TICKET(booking_id);
CREATE INDEX idx_ticket_category ON TICKET(category_id);
CREATE INDEX idx_payment_booking ON PAYMENT(booking_id);
