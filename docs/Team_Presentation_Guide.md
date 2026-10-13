# BCSE302L – Database Systems: Team Presentation & Demo Guide
## EVENT AND TICKET BOOKING SYSTEM

**Team Members:**
- **Kevin T John** (`24BYB0163`) — Core Architecture, Venues, Users & Events
- **Govind B Nair** (`24BYB0101`) — Seating Categories, Ticket Inventory & Bookings
- **Shaarav S** (`24BYB0118`) — Payments, Cancellations & Advanced Analytics

---

## 👥 1. Individual Member Presentation Allocation

```
┌────────────────────────────────────────────────────────────────────────┐
│  MEMBER 1: Kevin T John (24BYB0163)                                    │
│  Tables: VENUE, USERS, EVENT                                           │
│  Queries: 1.1, 1.2, 2.2 (Outer Joins, String Search, Date Filters)     │
│  Theory: Introduction, System Scope, 1NF & 2NF Normalization           │
├────────────────────────────────────────────────────────────────────────┤
│  MEMBER 2: Govind B Nair (24BYB0101)                                   │
│  Tables: SEAT_CATEGORY, BOOKING, TICKET                                │
│  Queries: 2.1, 2.3 (5-Table Join), 3.1 & 3.2 (Aggregations, HAVING)    │
│  Theory: Seating Model, Double-Booking Prevention, 3NF Normalization   │
├────────────────────────────────────────────────────────────────────────┤
│  MEMBER 3: Shaarav S (24BYB0118)                                       │
│  Tables: PAYMENT, CANCELLATION                                         │
│  Queries: 3.3, 4.3 (NOT EXISTS Subquery), 5.1 & 5.2 (Window Funcs),    │
│           Views (v_public_event_catalog, v_customer_ticket_wallet)      │
│  Theory: Payment Retries, Unique Cancellations, BCNF Normalization     │
└────────────────────────────────────────────────────────────────────────┘
```

---

## 🏛️ 2. Comprehensive Table Outlines & DDL Statements

Below is the complete architectural outline and production SQL DDL for all 8 entities, assigned by team member module.

---

### Module A: Core System Entities (Lead: Kevin T John — 24BYB0163)

#### Table 1: `VENUE` Outline
* **Purpose**: Records physical venue facilities, geographical addresses, and overall crowd capacity.
* **Attributes**:
  * `venue_id` (`SERIAL`, **PRIMARY KEY**): Auto-incrementing unique identifier.
  * `venue_name` (`VARCHAR(150)`, **NOT NULL**): Commercial name of the facility.
  * `location` (`VARCHAR(255)`, **NOT NULL**): Full street/city address.
  * `capacity` (`INT`, **NOT NULL**, `CHECK (capacity > 0)`): Maximum building safety limit.
  * `created_at` (`TIMESTAMP`, `DEFAULT CURRENT_TIMESTAMP`): Audit creation timestamp.

```sql
CREATE TABLE VENUE (
    venue_id SERIAL PRIMARY KEY,
    venue_name VARCHAR(150) NOT NULL,
    location VARCHAR(255) NOT NULL,
    capacity INT NOT NULL,
    created_at TIMESTAMP DEFAULT CURRENT_TIMESTAMP,
    CONSTRAINT chk_venue_capacity CHECK (capacity > 0)
);
```

#### Table 2: `USERS` Outline
* **Purpose**: Manages system principals across all three roles with uniqueness constraints.
* **Attributes**:
  * `user_id` (`SERIAL`, **PRIMARY KEY**): Auto-incrementing unique identifier.
  * `name` (`VARCHAR(100)`, **NOT NULL**): Full user display name.
  * `email` (`VARCHAR(150)`, **NOT NULL**, **UNIQUE**): Unique email address used for login.
  * `password_hash` (`VARCHAR(255)`, **NOT NULL**): Salted hash of authentication credentials.
  * `phone` (`VARCHAR(20)`, **NOT NULL**, **UNIQUE**): Verified contact telephone number.
  * `role` (`VARCHAR(20)`, **NOT NULL**, `DEFAULT 'CUSTOMER'`, `CHECK IN ('CUSTOMER', 'ORGANIZER', 'ADMIN')`).
  * `created_at` (`TIMESTAMP`, `DEFAULT CURRENT_TIMESTAMP`): User registration timestamp.

```sql
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
```

#### Table 3: `EVENT` Outline
* **Purpose**: Stores events hosted at a venue and managed by a verified organizer.
* **Attributes**:
  * `event_id` (`SERIAL`, **PRIMARY KEY**): Auto-incrementing unique identifier.
  * `venue_id` (`INT`, **NOT NULL**, **FOREIGN KEY** $\rightarrow$ `VENUE(venue_id) ON DELETE RESTRICT`).
  * `organizer_id` (`INT`, **NOT NULL**, **FOREIGN KEY** $\rightarrow$ `USERS(user_id) ON DELETE RESTRICT`).
  * `event_name` (`VARCHAR(200)`, **NOT NULL**): Official event title.
  * `event_date` (`DATE`, **NOT NULL**): Scheduled date of the event.
  * `event_time` (`TIME`, **NOT NULL**): Scheduled start time.
  * `description` (`TEXT`): Detailed agenda or synopsis.
  * `created_at` (`TIMESTAMP`, `DEFAULT CURRENT_TIMESTAMP`): Record creation timestamp.

```sql
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
```

---

### Module B: Inventory & Booking Engine (Lead: Govind B Nair — 24BYB0101)

#### Table 4: `SEAT_CATEGORY` Outline
* **Purpose**: Models tier-based seating quotas and pricing per event.
* **Attributes**:
  * `category_id` (`SERIAL`, **PRIMARY KEY**): Unique identifier for the category.
  * `event_id` (`INT`, **NOT NULL**, **FOREIGN KEY** $\rightarrow$ `EVENT(event_id) ON DELETE CASCADE`).
  * `category_name` (`VARCHAR(50)`, **NOT NULL**): Tier designation (e.g., VIP, Gold, General).
  * `price` (`NUMERIC(10, 2)`, **NOT NULL**, `CHECK (price >= 0)`): Base price per seat.
  * `total_seats` (`INT`, **NOT NULL**, `CHECK (total_seats > 0)`): Total configured seats.
  * `available_seats` (`INT`, **NOT NULL**, `CHECK (available_seats >= 0 AND available_seats <= total_seats)`).

```sql
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
```

#### Table 5: `BOOKING` Outline
* **Purpose**: Represents a transaction session initiated by a customer to purchase event tickets.
* **Attributes**:
  * `booking_id` (`SERIAL`, **PRIMARY KEY**): Unique booking transaction identifier.
  * `event_id` (`INT`, **NOT NULL**, **FOREIGN KEY** $\rightarrow$ `EVENT(event_id) ON DELETE RESTRICT`).
  * `user_id` (`INT`, **NOT NULL**, **FOREIGN KEY** $\rightarrow$ `USERS(user_id) ON DELETE RESTRICT`).
  * `booking_date` (`TIMESTAMP`, **NOT NULL**, `DEFAULT CURRENT_TIMESTAMP`).
  * `total_amount` (`NUMERIC(10, 2)`, **NOT NULL**, `DEFAULT 0.00`, `CHECK (total_amount >= 0)`).
  * `status` (`VARCHAR(20)`, **NOT NULL**, `DEFAULT 'PENDING'`, `CHECK IN ('PENDING', 'CONFIRMED', 'CANCELLED')`).

```sql
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
```

#### Table 6: `TICKET` Outline
* **Purpose**: Models individual physical/digital passes issued under a booking.
* **Attributes**:
  * `ticket_id` (`SERIAL`, **PRIMARY KEY**): Unique individual ticket pass identifier.
  * `booking_id` (`INT`, **NOT NULL**, **FOREIGN KEY** $\rightarrow$ `BOOKING(booking_id) ON DELETE CASCADE`).
  * `category_id` (`INT`, **NOT NULL**, **FOREIGN KEY** $\rightarrow$ `SEAT_CATEGORY(category_id) ON DELETE RESTRICT`).
  * `seat_number` (`VARCHAR(20)`, **NOT NULL**): Seat identification string (e.g., 'GC-101').
  * `price` (`NUMERIC(10, 2)`, **NOT NULL**, `CHECK (price >= 0)`): Invoiced ticket price.
  * `status` (`VARCHAR(20)`, **NOT NULL**, `DEFAULT 'VALID'`, `CHECK IN ('VALID', 'USED', 'CANCELLED')`).
  * **Composite Key Constraint**: `UNIQUE (category_id, seat_number)` strictly prevents double-booking the same seat within a category.

```sql
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
```

---

### Module C: Payments, Cancellations & Analytics (Lead: Shaarav S — 24BYB0118)

#### Table 7: `PAYMENT` Outline
* **Purpose**: Captures monetary payment attempts tied to a parent booking ($1 : N$ allows retrying failed checkouts).
* **Attributes**:
  * `payment_id` (`SERIAL`, **PRIMARY KEY**): Unique payment transaction identifier.
  * `booking_id` (`INT`, **NOT NULL**, **FOREIGN KEY** $\rightarrow$ `BOOKING(booking_id) ON DELETE CASCADE`).
  * `payment_date` (`TIMESTAMP`, **NOT NULL**, `DEFAULT CURRENT_TIMESTAMP`).
  * `amount_paid` (`NUMERIC(10, 2)`, **NOT NULL**, `CHECK (amount_paid >= 0)`): Monetary payment value.
  * `payment_method` (`VARCHAR(30)`, **NOT NULL**, `CHECK IN ('CARD', 'UPI', 'NET_BANKING', 'WALLET')`).
  * `status` (`VARCHAR(20)`, **NOT NULL**, `DEFAULT 'PENDING'`, `CHECK IN ('SUCCESS', 'FAILED', 'PENDING', 'REFUNDED')`).

```sql
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
```

#### Table 8: `CANCELLATION` Outline
* **Purpose**: Encapsulates ticket cancellation requests, timestamps, reasons, and refund disbursements.
* **Attributes**:
  * `cancel_id` (`SERIAL`, **PRIMARY KEY**): Unique cancellation entry identifier.
  * `booking_id` (`INT`, **NOT NULL**, **UNIQUE**, **FOREIGN KEY** $\rightarrow$ `BOOKING(booking_id) ON DELETE CASCADE`): **UNIQUE** constraint strictly ensures a $1:0..1$ relationship (no booking can be cancelled twice).
  * `cancel_date` (`TIMESTAMP`, **NOT NULL**, `DEFAULT CURRENT_TIMESTAMP`).
  * `reason` (`TEXT`): Customer cancellation justification.
  * `refund_amount` (`NUMERIC(10, 2)`, **NOT NULL**, `DEFAULT 0.00`, `CHECK (refund_amount >= 0)`).
  * `status` (`VARCHAR(20)`, **NOT NULL**, `DEFAULT 'REQUESTED'`, `CHECK IN ('REQUESTED', 'APPROVED', 'PROCESSED', 'REJECTED')`).

```sql
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
```

---

## 🎯 3. Live Presentation & Query Demo Sequence

### Member 1: Kevin T John (`24BYB0163`)
1. **Show schema initialization in terminal**:
   ```bash
   ./run_db.sh status
   ./run_db.sh psql
   ```
2. **Execute Table Inspection**:
   ```sql
   \dt
   \d VENUE
   \d EVENT
   ```
3. **Execute Assigned Queries**:
   * *Query 1.1*: Upcoming events in Nov–Dec 2026.
   * *Query 2.2*: Left Outer Join between `VENUE` and `EVENT` (`COALESCE` handling for empty venues).

---

### Member 2: Govind B Nair (`24BYB0101`)
1. **Demonstrate Double-Booking Prevention**:
   ```sql
   \d TICKET
   ```
   *(Point out `uq_category_seat` on `(category_id, seat_number)`).*
2. **Execute Assigned Queries**:
   * *Query 2.3*: 5-Table Join displaying attendee ticket vouchers across `TICKET`, `BOOKING`, `USERS`, `SEAT_CATEGORY`, `EVENT`, and `VENUE`.
   * *Query 3.1 & 3.2*: Aggregate calculations of gross sales per event, and `HAVING COUNT(e.event_id) > 1`.

---

### Member 3: Shaarav S (`24BYB0118`)
1. **Demonstrate Payment & Cancellation Constraints**:
   ```sql
   \d PAYMENT
   \d CANCELLATION
   ```
   *(Explain why `booking_id` in `CANCELLATION` is `UNIQUE` to prevent duplicate refunds).*
2. **Execute Assigned Queries**:
   * *Query 3.3*: Payment breakdown by method (`UPI`, `CARD`, `NET_BANKING`).
   * *Query 4.3*: Correlated subquery using `NOT EXISTS` to find customers with zero cancellations.
   * *Query 5.1 & 5.2*: Analytical window functions (`DENSE_RANK() OVER (...)` for top grossing events and cumulative running revenue).
   * *Views*: Query `v_public_event_catalog`.
