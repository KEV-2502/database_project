# Event and Ticket Booking System
### BCSE302L – Database Systems Course Project (Reviews I, II & III)

**Authors:**
- **Kevin T John** (`24BYB0163`) — Core Architecture, Venues, Users & Events
- **Govind B Nair** (`24BYB0101`) — Seating Categories, Ticket Inventory & Bookings
- **Shaarav S** (`24BYB0118`) — Payments, Cancellations & Advanced Analytics

**Faculty:** Ramkumar T | **Slot:** GT+TG1 | **Database:** PostgreSQL 16 (PL/pgSQL)

---

## 📁 Complete Project Structure

```
db project/
├── app/
│   ├── db.py                       # PostgreSQL 16 driver wrapper (psycopg2)
│   ├── server.py                   # Flask Web Server & REST API
│   ├── static/
│   │   ├── app.js                  # Client application logic & transaction inspector
│   │   └── style.css               # Modern dark-mode cyber design system
│   └── templates/
│       └── index.html              # Interactive Review III Web Dashboard
├── cli_app.py                      # Interactive Terminal CLI for live viva demonstrations
├── database/
│   ├── 01_schema.sql               # DDL: 8 Tables, Primary Keys, Foreign Keys, CHECK constraints
│   ├── 02_seed_data.sql            # DML: Comprehensive dataset (10+ records across all tables)
│   ├── 03_review2_queries.sql      # Review II SQL Queries (Joins, Aggregations, Subqueries, Views)
│   ├── 04_plsql.sql                # Review II & III: Procedures, Functions, Cursors, and Triggers
│   └── demos/
│       ├── 06_dml_demo.sql         # Section 6.4 DML operations & constraint verification
│       └── 07_transactions_demo.sql # Section 9: 7 Real-World Transaction workflows
├── docs/
│   ├── BCSE302L_Review_I_Report.md  # Complete Review I Documentation
│   ├── BCSE302L_Review_II_Report.md # Complete Review II Documentation
│   ├── BCSE302L_Review_III_Report.md# Review III Integrated System & Viva Guide
│   └── Team_Presentation_Guide.md  # Speaking script & table allocations
├── docker-compose.yml              # PostgreSQL 16 container service configuration
├── run_db.sh                       # Automation script for start/stop/init/queries/demo/psql
└── venv/                           # Python virtual environment (psycopg2-binary, flask)
```

---

## 🚀 Quick Start Guide

### 1. Database Setup
```bash
# Start PostgreSQL container
./run_db.sh start

# Apply schema (01), seed data (02), and PL/pgSQL routines (04)
./run_db.sh init

# Run Review II queries suite
./run_db.sh queries

# Run DML & Real-World Transaction demo scripts
./run_db.sh demo
```

### 2. Launch Interactive Application (Review III)

#### Option A: Modern Web Dashboard
```bash
source venv/bin/activate
python3 app/server.py
```
*Open [http://localhost:5050](http://localhost:5050) in your browser.*

#### Option B: Terminal Interactive CLI
```bash
source venv/bin/activate
python3 cli_app.py
```

---

## 🗄️ Database Connection Details
- **Host**: `localhost`
- **Port**: `5432`
- **Database Name**: `ticket_booking_system`
- **Username**: `postgres`
- **Password**: `postgrespassword`

---

## 🏛️ Database Tables & Member Allocation

| # | Table | Primary Key | Foreign Key References | Key Constraints & Business Rules | Lead Member |
| :-: | :--- | :--- | :--- | :--- | :--- |
| 1 | `VENUE` | `venue_id` | — | `capacity > 0` | Kevin |
| 2 | `USERS` | `user_id` | — | `email UNIQUE`, `phone UNIQUE`, `role CHECK ('CUSTOMER', 'ORGANIZER', 'ADMIN')` | Kevin |
| 3 | `EVENT` | `event_id` | `venue_id → VENUE`<br>`organizer_id → USERS` | `ON DELETE RESTRICT` protects active events from accidental deletion | Kevin |
| 4 | `SEAT_CATEGORY` | `category_id` | `event_id → EVENT` | `ON DELETE CASCADE`, `price >= 0`, `0 <= available_seats <= total_seats` | Govind |
| 5 | `BOOKING` | `booking_id` | `event_id → EVENT`<br>`user_id → USERS` | `total_amount >= 0`, `status CHECK ('PENDING', 'CONFIRMED', 'CANCELLED')` | Govind |
| 6 | `TICKET` | `ticket_id` | `booking_id → BOOKING`<br>`category_id → SEAT_CATEGORY` | `UNIQUE(category_id, seat_number)` strictly prevents double-booking | Govind |
| 7 | `PAYMENT` | `payment_id` | `booking_id → BOOKING` | `amount_paid >= 0`, supports $1:N$ failed/retry payment attempts | Shaarav |
| 8 | `CANCELLATION` | `cancel_id` | `booking_id → BOOKING` | `booking_id UNIQUE` enforces $1:0..1$ (prevents duplicate cancellations) | Shaarav |
