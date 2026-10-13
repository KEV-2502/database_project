# Event and Ticket Booking System
### BCSE302L – Database Systems Project

**Authors:**
- **Kevin T John** (`24BYB0163`)
- **Govind B Nair** (`24BYB0101`)
- **Shaarav S** (`24BYB0118`)

---

## 📁 Project Structure

```
dbpro/
├── docker-compose.yml              # PostgreSQL 16 container service configuration
├── run_db.sh                       # Automation script for start/stop/init/queries/psql
├── README.md                       # Master project overview & instructions
├── database/
│   ├── 01_schema.sql               # DDL: 8 Tables, Primary Keys, Foreign Keys, CHECK constraints
│   ├── 02_seed_data.sql            # DML: Realistic dataset for all entities
│   └── 03_review2_queries.sql      # Review II SQL Queries (Joins, Aggregations, Subqueries, Views)
└── docs/
    ├── BCSE302L_Review_I_Report.md  # Complete Review I Documentation (ER diagram, Normalization, Schema)
    └── BCSE302L_Review_II_Report.md # Complete Review II Documentation (DDL, DML, Query outputs)
```

---

## 🚀 Quick Start Guide

### 1. Start the PostgreSQL Database
```bash
./run_db.sh start
```

### 2. Initialize Schema & Seed Data
```bash
./run_db.sh init
```

### 3. Run Review II Queries
```bash
./run_db.sh queries
```

### 4. Open Interactive PostgreSQL CLI
```bash
./run_db.sh psql
```

### 5. Reset / Re-seed Anytime
```bash
./run_db.sh reset
```

---

## 🗄️ Database Connection Details
- **Host**: `localhost`
- **Port**: `5432`
- **Database Name**: `ticket_booking_system`
- **Username**: `postgres`
- **Password**: `postgrespassword`

---

## 📑 Academic Review Reports & Guides
- **Team Presentation & Demo Guide**: [docs/Team_Presentation_Guide.md](docs/Team_Presentation_Guide.md)
  - 3-Member speaking script & role assignments (**Kevin**, **Govind**, **Shaarav**)
  - Comprehensive Table Outlines & exact `CREATE TABLE` DDL blocks
  - Assigned queries, terminal walkthrough, and expected viva Q&A
- **Review I Report**: [docs/BCSE302L_Review_I_Report.md](docs/BCSE302L_Review_I_Report.md)
  - Problem Statement, Objectives, User Roles
  - ER Model (Mermaid Diagram & Cardinalities)
  - Relational Schema & Constraints
  - 1NF, 2NF, 3NF, BCNF Normalization proofs
- **Review II Report**: [docs/BCSE302L_Review_II_Report.md](docs/BCSE302L_Review_II_Report.md)
  - DDL Execution Summary & Table Outlines
  - Seed Dataset Analysis
  - Query outputs: Multi-Table Joins, Subqueries, Window Functions, and Views

---

## 🏛️ Database Tables & Outline Overview

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

