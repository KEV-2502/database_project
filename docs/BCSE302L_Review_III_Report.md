# BCSE302L – Database Systems: Review III Report & Final Demonstration Guide
## EVENT AND TICKET BOOKING SYSTEM
### Integrated Database Application & Real-World Transactions

**Course:** BCSE302L – Database Systems  
**Faculty:** Ramkumar T | **Slot:** GT+TG1  
**Team Members:**
- **Kevin T John** — `24BYB0163` (Tables: `VENUE`, `USERS`, `EVENT`)
- **Govind B Nair** — `24BYB0101` (Tables: `SEAT_CATEGORY`, `BOOKING`, `TICKET`)
- **Shaarav S** — `24BYB0118` (Tables: `PAYMENT`, `CANCELLATION`)

---

## 1. Executive Summary & Review III Objectives
Review III represents the culmination of the Database Systems project, integrating the relational schema (Review I) and the physical database objects (Review II) with an interactive **Python Application** connected to **PostgreSQL 16**.

In strict accordance with the **Review III Evaluation Rubric**:
1. **Integrated Database Operation (2 Marks)**: Verification that constraints, triggers, procedures, functions, and views work harmoniously.
2. **Real-World Transactions (3 Marks)**: Live demonstration of 7 end-to-end business transactions.
3. **SQL/PLSQL Interaction (2 Marks)**: The application delegates business logic to PL/pgSQL routines rather than running duplicated procedural client logic.
4. **Output & Reports (1 Mark)**: Generation of live occupancy reports, refund schedules, customer lifetime spend reports, and wallet views.
5. **Documentation & Viva (2 Marks)**: Comprehensive report, architectural defense, and viva readiness.

---

## 2. Interactive Demonstration Architecture
The system implements the mandatory 5-stage transaction execution flow:

```
[ User Action (Web / CLI) ]
             │
             ▼
[ Python Database Driver (psycopg2) ]
             │
             ▼
[ PostgreSQL 16 PL/pgSQL Engine ]
  ├── Stored Procedures (sp_book_tickets, sp_make_payment, sp_cancel_booking)
  ├── Triggers (trg_ticket_validate, trg_ticket_inventory, trg_category_capacity, trg_payment_confirm_booking)
  ├── Functions (fn_calculate_refund, fn_event_occupancy, fn_customer_lifetime_spend)
  └── Cursors (sp_settle_approved_cancellations, sp_expire_stale_bookings)
             │
             ▼
[ Database Processing & State Mutation ]
  ├── Atomic Multi-Row Inserts & Updates
  ├── Constraint Checks (CHECK, UNIQUE, FK RESTRICT/CASCADE)
  └── Derived Attribute Synchronization (available_seats, total_amount)
             │
             ▼
[ Result Return & Live Notice Propagation ]
```

---

## 3. Real-World Transaction Breakdown (Evaluation Table)

| # | Transaction Name | User Operation | Tables Involved | SQL / PL/SQL Executed | Database Effect | Result Generated |
| :-: | :--- | :--- | :--- | :--- | :--- | :--- |
| **T1** | **Atomic Ticket Booking** | Customer selects event tier & seats (e.g. GC-201, GC-202) | `USERS`, `SEAT_CATEGORY`, `EVENT`, `BOOKING`, `TICKET` | `sp_book_tickets`, `trg_ticket_validate`, `trg_ticket_inventory` | Inserts PENDING booking; inserts tickets; decrements `available_seats`; calculates `total_amount` | Booking created & returned to caller |
| **T2** | **Payment Lifecycle & Retry** | Payment is declined, customer retries with alternative method | `BOOKING`, `PAYMENT` | `sp_make_payment`, `trg_payment_confirm_booking` | Records FAILED attempt; retry records SUCCESS; trigger shifts status `PENDING` $\rightarrow$ `CONFIRMED` | Booking confirmed, full payment audit trail preserved |
| **T3** | **Double-Booking Prevention** | Second customer attempts to book an already reserved seat | `BOOKING`, `TICKET`, `SEAT_CATEGORY` | `sp_book_tickets`, constraint `uq_category_seat` | Unique constraint raises error; atomic procedure rolls back entirely | Error message returned, zero ghost rows left |
| **T4** | **Venue Over-Capacity Guard** | Organizer attempts to add seats exceeding physical venue capacity | `SEAT_CATEGORY`, `EVENT`, `VENUE` | `trg_category_capacity` | Trigger calculates $\sum \text{seats}$ vs `capacity` and aborts insert | Exception raised explaining over-allocation |
| **T5** | **Policy-Based Cancellation** | Customer requests booking cancellation | `BOOKING`, `CANCELLATION`, `TICKET`, `PAYMENT`, `SEAT_CATEGORY` | `sp_cancel_booking`, `fn_calculate_refund`, `trg_ticket_inventory` | `fn_calculate_refund` calculates time-decay refund; tickets cancelled; seats restored; payment refunded | Refund issued, seats made available for other buyers |
| **T6** | **Batch Cancellation Settlement** | Nightly admin job settles all APPROVED cancellations | `CANCELLATION`, `BOOKING`, `USERS`, `TICKET`, `PAYMENT` | Explicit Cursor: `sp_settle_approved_cancellations` | Explicit cursor locks rows (`FOR UPDATE OF c`), loops row-by-row, settles refunds, sets status `PROCESSED` | Batch settlement report printed with total refunded |
| **T7** | **Stale Checkout Expiration** | System clears unpaid reservations older than 24h | `BOOKING`, `PAYMENT`, `TICKET` | Parameterized Cursor: `sp_expire_stale_bookings` | Parameterized cursor identifies expired checkouts, cancels tickets, restores seats | Stale holds released, available seats updated |

---

## 4. Individual Team Speaking Roles & Viva Defense

### Member 1: Kevin T John (`24BYB0163`) — Lead for `VENUE`, `USERS`, `EVENT`
- **Tables Led**: `VENUE` (`capacity > 0`), `USERS` (`email`, `phone` UNIQUE, `role` CHECK), `EVENT` (`ON DELETE RESTRICT`).
- **Core Queries**:
  - *Query 1.1*: Chronological upcoming events filter (`BETWEEN`).
  - *Query 1.2*: LIKE pattern matching on `@vitstudent.ac.in`.
  - *Query 2.2*: Left Outer Join between `VENUE` and `EVENT` with `COALESCE` handling for empty venues.
- **Viva Focus**: Explain why `EVENT` uses `ON DELETE RESTRICT` with `VENUE` and `USERS` (to prevent cascading destruction of historical event records).

### Member 2: Govind B Nair (`24BYB0101`) — Lead for `SEAT_CATEGORY`, `BOOKING`, `TICKET`
- **Tables Led**: `SEAT_CATEGORY` (`0 <= available_seats <= total_seats`), `BOOKING` (`status` lifecycle), `TICKET` (`UNIQUE(category_id, seat_number)`).
- **Core Procedures & Triggers**:
  - `sp_book_tickets`: Atomic multi-ticket reservation.
  - `trg_ticket_validate` & `trg_ticket_inventory`: Price validation and real-time inventory deduction.
  - *Query 2.3*: 5-Table Join showing complete attendee ticket vouchers.
  - *Query 3.1*: Aggregate sales and average price per event (`GROUP BY`, `SUM`, `AVG`).
- **Viva Focus**: Explain how `UNIQUE(category_id, seat_number)` and atomic stored procedures prevent race conditions and double-booking.

### Member 3: Shaarav S (`24BYB0118`) — Lead for `PAYMENT`, `CANCELLATION` & Analytics
- **Tables Led**: `PAYMENT` ($1:N$ retries), `CANCELLATION` ($1:0..1$ via `booking_id UNIQUE`).
- **Core Procedures, Functions & Cursors**:
  - `fn_calculate_refund`: Sliding time-decay refund algorithm ($\ge 14\text{d}=100\%$, $7\text{--}13\text{d}=75\%$, $2\text{--}6\text{d}=50\%$, $<2\text{d}=0\%$).
  - `sp_settle_approved_cancellations`: Explicit cursor with `FOR UPDATE OF c` and `WHERE CURRENT OF`.
  - `sp_expire_stale_bookings`: Parameterized cursor for releasing unpaid checkouts.
  - *Query 4.3*: Correlated subquery using `NOT EXISTS` to find customers with zero cancellations.
  - *Query 5.1 & 5.2*: Analytical Window functions (`DENSE_RANK()`, running revenue progression).
- **Viva Focus**: Explain why `CANCELLATION.booking_id` is `UNIQUE` ($1:0..1$) and how cursors maintain row locks during batch settlement.

---

## 5. Instructions for Running the Demonstration

### Option A: Web Application Interface
```bash
# 1. Activate Python virtual environment
source venv/bin/activate

# 2. Launch Flask Web Application
python3 app/server.py

# 3. Open browser to http://localhost:5050
```

### Option B: Interactive Terminal CLI
```bash
# 1. Activate Python virtual environment
source venv/bin/activate

# 2. Run interactive CLI
python3 cli_app.py
```
