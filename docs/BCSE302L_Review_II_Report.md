# BCSE302L – Database Systems: Review II Report
## EVENT AND TICKET BOOKING SYSTEM

**Team Members:**
- **Kevin T John** — `24BYB0163`
- **Govind B Nair** — `24BYB0101`
- **Shaarav S** — `24BYB0118`

---

## 1. Overview of Review II Deliverables
Review II advances the relational database design from Review I into a fully instantiated, verified database implementation on **PostgreSQL 16**. The key deliverables fulfilled include:
1. **Physical Schema Implementation (DDL)**: Complete `CREATE TABLE` definitions with primary keys, foreign key constraints (`ON DELETE CASCADE` / `ON DELETE RESTRICT`), unique constraints, and check constraints.
2. **Realistic Sample Dataset (DML)**: Population across all 8 relational tables (`VENUE`, `USERS`, `EVENT`, `SEAT_CATEGORY`, `BOOKING`, `TICKET`, `PAYMENT`, `CANCELLATION`).
3. **Advanced SQL Query Portfolio**:
   - Single-table queries with filtering, sorting, and pattern matching.
   - Multi-table joins (2-way, 3-way, 5-way joins and Outer Joins).
   - Aggregate statistics with `GROUP BY` and `HAVING` filters.
   - Nested subqueries (`SCALAR`, `IN`, `EXISTS`, and `ALL`).
   - Advanced analytical Window Functions (`DENSE_RANK()`, `ROW_NUMBER()`, running sums).
   - Relational Database Views for decoupled application access.

---

## 2. Table-by-Table Schema & Constraint Summary

| Entity | Primary Key | Foreign Key References | Unique / Check Constraints |
| :--- | :--- | :--- | :--- |
| **`VENUE`** | `venue_id` | — | `capacity > 0` |
| **`USERS`** | `user_id` | — | `email` (UK), `phone` (UK), `role IN ('CUSTOMER', 'ORGANIZER', 'ADMIN')` |
| **`EVENT`** | `event_id` | `venue_id` $\rightarrow$ `VENUE(venue_id)`, `organizer_id` $\rightarrow$ `USERS(user_id)` | Referential integrity with `ON DELETE RESTRICT` |
| **`SEAT_CATEGORY`** | `category_id` | `event_id` $\rightarrow$ `EVENT(event_id) ON DELETE CASCADE` | `price >= 0`, `total_seats > 0`, `0 <= available_seats <= total_seats` |
| **`BOOKING`** | `booking_id` | `event_id` $\rightarrow$ `EVENT(event_id)`, `user_id` $\rightarrow$ `USERS(user_id)` | `total_amount >= 0`, `status IN ('PENDING', 'CONFIRMED', 'CANCELLED')` |
| **`TICKET`** | `ticket_id` | `booking_id` $\rightarrow$ `BOOKING(booking_id) ON DELETE CASCADE`, `category_id` $\rightarrow$ `SEAT_CATEGORY(category_id)` | `UNIQUE(category_id, seat_number)`, `price >= 0`, `status IN ('VALID', 'USED', 'CANCELLED')` |
| **`PAYMENT`** | `payment_id` | `booking_id` $\rightarrow$ `BOOKING(booking_id) ON DELETE CASCADE` | `amount_paid >= 0`, `payment_method` enum, `status` enum |
| **`CANCELLATION`** | `cancel_id` | `booking_id` $\rightarrow$ `BOOKING(booking_id) ON DELETE CASCADE` | `booking_id` (UK, guarantees $1:0..1$), `refund_amount >= 0`, `status` enum |

---

## 3. Physical DDL Table Creation Specifications

Below are the detailed column outlines and exact PostgreSQL `CREATE TABLE` scripts executed for each entity:

### 3.1 `VENUE` Table
* **Outline**:
  - `venue_id` (`SERIAL`, PK): Unique auto-incrementing ID.
  - `venue_name` (`VARCHAR(150)`, NOT NULL): Official facility name.
  - `location` (`VARCHAR(255)`, NOT NULL): City & address.
  - `capacity` (`INT`, NOT NULL): Seating capacity, constrained by `CHECK (capacity > 0)`.
  - `created_at` (`TIMESTAMP`, DEFAULT CURRENT_TIMESTAMP).

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

### 3.2 `USERS` Table
* **Outline**:
  - `user_id` (`SERIAL`, PK): Unique user ID.
  - `name` (`VARCHAR(100)`, NOT NULL): User's legal name.
  - `email` (`VARCHAR(150)`, NOT NULL, UNIQUE): Unique email identifier.
  - `password_hash` (`VARCHAR(255)`, NOT NULL): Salted password digest.
  - `phone` (`VARCHAR(20)`, NOT NULL, UNIQUE): Contact phone number.
  - `role` (`VARCHAR(20)`, NOT NULL, DEFAULT 'CUSTOMER'): Constrained to `'CUSTOMER'`, `'ORGANIZER'`, or `'ADMIN'`.
  - `created_at` (`TIMESTAMP`, DEFAULT CURRENT_TIMESTAMP).

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

### 3.3 `EVENT` Table
* **Outline**:
  - `event_id` (`SERIAL`, PK): Unique event ID.
  - `venue_id` (`INT`, NOT NULL, FK $\rightarrow$ `VENUE(venue_id) ON DELETE RESTRICT`).
  - `organizer_id` (`INT`, NOT NULL, FK $\rightarrow$ `USERS(user_id) ON DELETE RESTRICT`).
  - `event_name` (`VARCHAR(200)`, NOT NULL): Name of event.
  - `event_date` (`DATE`, NOT NULL): Scheduled date.
  - `event_time` (`TIME`, NOT NULL): Scheduled time.
  - `description` (`TEXT`): Extended synopsis.
  - `created_at` (`TIMESTAMP`, DEFAULT CURRENT_TIMESTAMP).

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

### 3.4 `SEAT_CATEGORY` Table
* **Outline**:
  - `category_id` (`SERIAL`, PK): Unique category ID.
  - `event_id` (`INT`, NOT NULL, FK $\rightarrow$ `EVENT(event_id) ON DELETE CASCADE`).
  - `category_name` (`VARCHAR(50)`, NOT NULL): Tier name (e.g., VIP, Gold, General).
  - `price` (`NUMERIC(10, 2)`, NOT NULL, CHECK $\ge 0$).
  - `total_seats` (`INT`, NOT NULL, CHECK $> 0$).
  - `available_seats` (`INT`, NOT NULL, CHECK $0 \le \text{available\_seats} \le \text{total\_seats}$).

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

### 3.5 `BOOKING` Table
* **Outline**:
  - `booking_id` (`SERIAL`, PK): Unique transaction reference.
  - `event_id` (`INT`, NOT NULL, FK $\rightarrow$ `EVENT(event_id) ON DELETE RESTRICT`).
  - `user_id` (`INT`, NOT NULL, FK $\rightarrow$ `USERS(user_id) ON DELETE RESTRICT`).
  - `booking_date` (`TIMESTAMP`, NOT NULL, DEFAULT CURRENT_TIMESTAMP).
  - `total_amount` (`NUMERIC(10, 2)`, NOT NULL, DEFAULT 0.00, CHECK $\ge 0$).
  - `status` (`VARCHAR(20)`, NOT NULL, DEFAULT 'PENDING', CHECK IN ('PENDING', 'CONFIRMED', 'CANCELLED')).

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

### 3.6 `TICKET` Table
* **Outline**:
  - `ticket_id` (`SERIAL`, PK): Unique ticket pass ID.
  - `booking_id` (`INT`, NOT NULL, FK $\rightarrow$ `BOOKING(booking_id) ON DELETE CASCADE`).
  - `category_id` (`INT`, NOT NULL, FK $\rightarrow$ `SEAT_CATEGORY(category_id) ON DELETE RESTRICT`).
  - `seat_number` (`VARCHAR(20)`, NOT NULL): Unique seat identifier within category.
  - `price` (`NUMERIC(10, 2)`, NOT NULL, CHECK $\ge 0$).
  - `status` (`VARCHAR(20)`, NOT NULL, DEFAULT 'VALID', CHECK IN ('VALID', 'USED', 'CANCELLED')).
  - `CONSTRAINT uq_category_seat UNIQUE (category_id, seat_number)`: Prevents duplicate seat allocation.

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

### 3.7 `PAYMENT` Table
* **Outline**:
  - `payment_id` (`SERIAL`, PK): Unique payment record ID.
  - `booking_id` (`INT`, NOT NULL, FK $\rightarrow$ `BOOKING(booking_id) ON DELETE CASCADE`).
  - `payment_date` (`TIMESTAMP`, NOT NULL, DEFAULT CURRENT_TIMESTAMP).
  - `amount_paid` (`NUMERIC(10, 2)`, NOT NULL, CHECK $\ge 0$).
  - `payment_method` (`VARCHAR(30)`, NOT NULL, CHECK IN ('CARD', 'UPI', 'NET_BANKING', 'WALLET')).
  - `status` (`VARCHAR(20)`, NOT NULL, DEFAULT 'PENDING', CHECK IN ('SUCCESS', 'FAILED', 'PENDING', 'REFUNDED')).

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

### 3.8 `CANCELLATION` Table
* **Outline**:
  - `cancel_id` (`SERIAL`, PK): Unique cancellation record ID.
  - `booking_id` (`INT`, NOT NULL, UNIQUE, FK $\rightarrow$ `BOOKING(booking_id) ON DELETE CASCADE`): UNIQUE constraint enforces $1:0..1$.
  - `cancel_date` (`TIMESTAMP`, NOT NULL, DEFAULT CURRENT_TIMESTAMP).
  - `reason` (`TEXT`): User reason for cancellation.
  - `refund_amount` (`NUMERIC(10, 2)`, NOT NULL, DEFAULT 0.00, CHECK $\ge 0$).
  - `status` (`VARCHAR(20)`, NOT NULL, DEFAULT 'REQUESTED', CHECK IN ('REQUESTED', 'APPROVED', 'PROCESSED', 'REJECTED')).

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

## 4. Performance Indexes
To accelerate high-frequency joins and search predicates:
```sql
CREATE INDEX idx_event_date ON EVENT(event_date);
CREATE INDEX idx_booking_user ON BOOKING(user_id);
CREATE INDEX idx_booking_event ON BOOKING(event_id);
CREATE INDEX idx_ticket_booking ON TICKET(booking_id);
CREATE INDEX idx_ticket_category ON TICKET(category_id);
CREATE INDEX idx_payment_booking ON PAYMENT(booking_id);
```


---

## 5. Review II Query Suite: Execution Results & Explanations

### 5.1 Multi-Table Joins


#### Query: Comprehensive Digital Ticket Breakdown (5-Table Join)
Demonstrates traversal across `TICKET`, `BOOKING`, `USERS`, `SEAT_CATEGORY`, `EVENT`, and `VENUE`:

```sql
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
```

**Output:**
```
 ticket_id | booking_id | attendee_name |                event_name                |     seat_tier      | seat_number | ticket_price | ticket_status |             venue_name             
-----------+------------+---------------+------------------------------------------+--------------------+-------------+--------------+---------------+------------------------------------
         1 |          1 | Kevin T John  | ElectroBeat Music Festival 2026          | Golden Circle      | GC-101      |      1800.00 | VALID         | Grand Arena Exhibition Centre
         2 |          1 | Kevin T John  | ElectroBeat Music Festival 2026          | Golden Circle      | GC-102      |      1800.00 | VALID         | Grand Arena Exhibition Centre
         3 |          2 | Govind B Nair | National AI & Cloud Architecture Summit  | Corporate Delegate | DEL-042     |      2800.00 | VALID         | Tech Park International Auditorium
         4 |          3 | Shaarav S     | All-India Inter-University T20 Final     | East Stand Tier-1  | ES1-501     |      1600.00 | VALID         | Jawaharlal Nehru National Stadium
         5 |          3 | Shaarav S     | All-India Inter-University T20 Final     | East Stand Tier-1  | ES1-502     |      1600.00 | VALID         | Jawaharlal Nehru National Stadium
         6 |          4 | Ananya Iyer   | Symphony of Strings: Classical Gala      | Royal Box          | RB-012      |      4000.00 | CANCELLED     | Royal Opera House Heritage Hall
         7 |          5 | Rahul Verma   | Comedy Spotlight Live: Standup Showcase  | Front Row Premium  | FR-005      |      1200.00 | VALID         | Tech Park International Auditorium
         8 |          5 | Rahul Verma   | Comedy Spotlight Live: Standup Showcase  | Front Row Premium  | FR-006      |      1200.00 | VALID         | Tech Park International Auditorium
```

---

### 5.2 Aggregate Functions with GROUP BY and HAVING

#### Query: Event Sales & Average Ticket Price Performance
Calculates total issued tickets, gross revenue, and average ticket price per event:

```sql
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
```

**Output:**
```
 event_id |               event_name                | total_tickets_issued | gross_ticket_sales | avg_ticket_price 
----------+-----------------------------------------+----------------------+--------------------+------------------
        1 | ElectroBeat Music Festival 2026         |                    2 |            3600.00 |          1800.00
        4 | All-India Inter-University T20 Final    |                    2 |            3200.00 |          1600.00
        2 | National AI & Cloud Architecture Summit |                    1 |            2800.00 |          2800.00
        5 | Comedy Spotlight Live: Standup Showcase |                    2 |            2400.00 |          1200.00
        3 | Symphony of Strings: Classical Gala     |                    0 |               0.00 |             0.00
```

---

### 5.3 Nested Subqueries

#### Query: Correlated Subquery with NOT EXISTS (Zero Cancellations)
Identifies loyal customers who have placed bookings and never initiated a cancellation:

```sql
SELECT u.user_id, u.name, u.email
FROM USERS u
WHERE u.role = 'CUSTOMER'
  AND NOT EXISTS (
      SELECT 1 
      FROM BOOKING b
      JOIN CANCELLATION c ON b.booking_id = c.booking_id
      WHERE b.user_id = u.user_id
  );
```

**Output:**
```
 user_id |     name      |              email               
---------+---------------+----------------------------------
       4 | Kevin T John  | kevin.john2024@vitstudent.ac.in
       5 | Govind B Nair | govind.nair2024@vitstudent.ac.in
       6 | Shaarav S     | shaarav.s2024@vitstudent.ac.in
       8 | Rahul Verma   | rahul.verma@techcorp.com
```

---

### 5.4 Analytical Window Functions

#### Query: Revenue Ranking (`DENSE_RANK()`)
Ranks events by total confirmed revenue:

```sql
SELECT 
    e.event_name,
    v.venue_name,
    COALESCE(SUM(b.total_amount), 0) AS total_revenue,
    DENSE_RANK() OVER (ORDER BY COALESCE(SUM(b.total_amount), 0) DESC) AS revenue_rank
FROM EVENT e
JOIN VENUE v ON e.venue_id = v.venue_id
LEFT JOIN BOOKING b ON e.event_id = b.event_id AND b.status = 'CONFIRMED'
GROUP BY e.event_id, e.event_name, v.venue_name;
```

**Output:**
```
               event_name                |             venue_name             | total_revenue | revenue_rank 
-----------------------------------------+------------------------------------+---------------+--------------
 ElectroBeat Music Festival 2026         | Grand Arena Exhibition Centre      |       3600.00 |            1
 All-India Inter-University T20 Final    | Jawaharlal Nehru National Stadium  |       3200.00 |            2
 National AI & Cloud Architecture Summit | Tech Park International Auditorium |       2800.00 |            3
 Comedy Spotlight Live: Standup Showcase | Tech Park International Auditorium |       2400.00 |            4
 Symphony of Strings: Classical Gala     | Royal Opera House Heritage Hall    |             0 |            5
```

---

### 5.5 Database Views

#### Public Catalog View (`v_public_event_catalog`)
Enables the frontend or client application to query upcoming events with aggregated inventory and minimum pricing in a single call:

```sql
SELECT * FROM v_public_event_catalog ORDER BY event_date ASC;
```

**Output:**
```
 event_id |               event_name                | event_date | event_time |             venue_name             |             location             |     organizer_name      | remaining_seats | starting_price_inr 
----------+-----------------------------------------+------------+------------+------------------------------------+----------------------------------+-------------------------+-----------------+--------------------
        3 | Symphony of Strings: Classical Gala     | 2026-10-30 | 19:00:00   | Royal Opera House Heritage Hall    | Charni Road, Mumbai, Maharashtra | Priya Nair (Organizer)  |             400 |            1500.00
        4 | All-India Inter-University T20 Final    | 2026-11-15 | 14:30:00   | Jawaharlal Nehru National Stadium  | Lodhi Road, New Delhi, Delhi     | Rohan Patel (Organizer) |           16998 |             600.00
        1 | ElectroBeat Music Festival 2026         | 2026-11-20 | 18:00:00   | Grand Arena Exhibition Centre      | Whitefield, Bangalore, Karnataka | Priya Nair (Organizer)  |            3498 |             950.00
        2 | National AI & Cloud Architecture Summit | 2026-12-05 | 09:30:00   | Tech Park International Auditorium | OMR Road, Chennai, Tamil Nadu    | Rohan Patel (Organizer) |             799 |             850.00
        5 | Comedy Spotlight Live: Standup Showcase | 2026-12-18 | 20:00:00   | Tech Park International Auditorium | OMR Road, Chennai, Tamil Nadu    | Priya Nair (Organizer)  |             498 |             600.00
```
