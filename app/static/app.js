/* =============================================================================
   Event & Ticket Booking System - Client Application Logic
   BCSE302L - Database Systems | Review III
   ============================================================================= */

let currentEventCategories = [];
let inspectorExpanded = false;

document.addEventListener("DOMContentLoaded", () => {
  checkHealth();
  loadCatalog();
  onUserChanged();
});

// Toast Helper
function showToast(message, type = "info") {
  const container = document.getElementById("toastContainer");
  const toast = document.createElement("div");
  toast.className = `toast toast-${type}`;
  toast.innerHTML = `
    <span style="font-weight:700; font-size:0.75rem;">[${type.toUpperCase()}]</span>
    <div style="font-size: 0.85rem;">${message}</div>
  `;
  container.appendChild(toast);
  setTimeout(() => {
    toast.style.opacity = '0';
    toast.style.transform = 'translateX(100%)';
    toast.style.transition = 'all 0.3s ease';
    setTimeout(() => toast.remove(), 300);
  }, 4000);
}

// Transaction Inspector
function updateInspector(operation, sql, triggers, effect) {
  document.getElementById("inspOperation").innerText = operation;
  document.getElementById("inspSql").innerText = sql;
  document.getElementById("inspTriggers").innerText = triggers;
  document.getElementById("inspEffect").innerText = effect;

  const drawer = document.getElementById("inspectorDrawer");
  if (drawer.classList.contains("collapsed")) {
    drawer.classList.remove("collapsed");
    document.getElementById("inspectorToggleIcon").innerText = "Click to Collapse";
    inspectorExpanded = true;
  }
}

function toggleInspector() {
  const drawer = document.getElementById("inspectorDrawer");
  inspectorExpanded = !inspectorExpanded;
  if (inspectorExpanded) {
    drawer.classList.remove("collapsed");
    document.getElementById("inspectorToggleIcon").innerText = "Click to Collapse";
  } else {
    drawer.classList.add("collapsed");
    document.getElementById("inspectorToggleIcon").innerText = "Click to Expand";
  }
}

// Health & System Metrics
async function checkHealth() {
  try {
    const res = await fetch("/api/health");
    const data = await res.json();
    const dot = document.getElementById("statusDot");
    const text = document.getElementById("dbStatusText");

    if (data.connected) {
      dot.style.background = "var(--accent-emerald)";
      dot.style.boxShadow = "0 0 8px var(--accent-emerald)";
      text.innerText = "PostgreSQL 16 · Online (8 Tables in BCNF)";

      if (data.stats && !data.stats.error) {
        document.getElementById("metricBookings").innerText = data.stats.booking || "25";
        document.getElementById("metricRevenue").innerText = "₹" + Number(data.stats.total_revenue || 0).toLocaleString();
        document.getElementById("metricCancellations").innerText = data.stats.cancellation || "10";
      }
    } else {
      dot.style.background = "var(--accent-rose)";
      dot.style.boxShadow = "0 0 8px var(--accent-rose)";
      text.innerText = "PostgreSQL Disconnected: " + (data.error || "Connect host 5432");
    }
  } catch (err) {
    document.getElementById("dbStatusText").innerText = "API Server Connecting...";
  }
}

// Tab Switching
function switchTab(tabId) {
  document.querySelectorAll(".section-pane").forEach(p => p.classList.remove("active"));
  document.querySelectorAll(".tab-btn").forEach(b => b.classList.remove("active"));

  document.getElementById(tabId).classList.add("active");
  event.target.classList.add("active");

  if (tabId === 'walletPane') loadUserWallet();
  if (tabId === 'organizerPane') loadOrganizerEvents();
  if (tabId === 'adminPane') loadAdminData();
}

// User Changing
function onUserChanged() {
  const select = document.getElementById("activeUserSelect");
  const selectedOption = select.options[select.selectedIndex];
  const role = selectedOption.getAttribute("data-role");

  // Load relevant data
  loadUserWallet();
  if (role === 'ORGANIZER') {
    loadOrganizerEvents();
  }
}

// Modal Helpers
function openModal(id) {
  document.getElementById(id).classList.add("active");
}
function closeModal(id) {
  document.getElementById(id).classList.remove("active");
}

// =============================================================================
// CATALOG & BOOKING
// =============================================================================

async function loadCatalog() {
  try {
    const res = await fetch("/api/catalog");
    const data = await res.json();
    const grid = document.getElementById("eventsGrid");
    grid.innerHTML = "";

    if (!data.success || data.events.length === 0) {
      grid.innerHTML = `<div style="color: var(--text-muted);">No upcoming events currently found.</div>`;
      return;
    }

    data.events.forEach(evt => {
      const card = document.createElement("div");
      card.className = "event-card";
      card.innerHTML = `
        <div>
          <div class="event-card-header">
            <span class="event-tag">${evt.venue_name}</span>
            <h3 class="event-title">${evt.event_name}</h3>
          </div>
          <div class="event-meta">
            <div class="event-meta-item"><strong>Date:</strong> ${evt.event_date} at ${evt.event_time}</div>
            <div class="event-meta-item"><strong>Location:</strong> ${evt.location}</div>
            <div class="event-meta-item"><strong>Organizer:</strong> ${evt.organizer_name}</div>
            <div class="event-meta-item"><strong>Remaining Seats:</strong> <span style="color: var(--accent-cyan); font-weight: 600;">${evt.remaining_seats}</span></div>
          </div>
        </div>
        <div class="event-card-footer">
          <div>
            <div class="price-label">Starting From</div>
            <div class="price-amount">₹${Number(evt.starting_price_inr).toFixed(2)}</div>
          </div>
          <button class="btn btn-primary" onclick="openBookModal(${evt.event_id}, '${evt.event_name.replace(/'/g, "\\'")}')">
            Book Seats
          </button>
        </div>
      `;
      grid.appendChild(card);
    });
  } catch (err) {
    showToast("Failed to fetch event catalog", "error");
  }
}

async function openBookModal(eventId, eventName) {
  document.getElementById("bookModalTitle").innerText = `Book: ${eventName}`;
  document.getElementById("bookEventId").value = eventId;
  document.getElementById("bookSeatsInput").value = "";

  try {
    const res = await fetch(`/api/events/${eventId}`);
    const data = await res.json();
    if (!data.success) {
      showToast(data.error, "error");
      return;
    }

    currentEventCategories = data.categories;
    const catSelect = document.getElementById("bookCategorySelect");
    catSelect.innerHTML = "";

    currentEventCategories.forEach(cat => {
      const opt = document.createElement("option");
      opt.value = cat.category_id;
      opt.dataset.price = cat.price;
      opt.dataset.available = cat.available_seats;
      opt.innerText = `${cat.category_name} (₹${Number(cat.price).toFixed(2)} | Avail: ${cat.available_seats}/${cat.total_seats})`;
      catSelect.appendChild(opt);
    });

    updateBookingPricePreview();
    openModal("bookModal");
  } catch (err) {
    showToast("Error loading event tiers", "error");
  }
}

function updateBookingPricePreview() {
  const catSelect = document.getElementById("bookCategorySelect");
  if (!catSelect.selectedIndex) return;
  const opt = catSelect.options[catSelect.selectedIndex];
  const price = parseFloat(opt.dataset.price || 0);

  const seatsRaw = document.getElementById("bookSeatsInput").value;
  const seats = seatsRaw.split(",").map(s => s.trim()).filter(s => s.length > 0);

  document.getElementById("bookTierPrice").innerText = `₹${price.toFixed(2)}`;
  document.getElementById("bookTotalEstimate").innerText = `₹${(price * seats.length).toFixed(2)}`;
}

async function submitBooking(e) {
  e.preventDefault();
  const userId = document.getElementById("activeUserSelect").value;
  const categoryId = document.getElementById("bookCategorySelect").value;
  const seatsRaw = document.getElementById("bookSeatsInput").value;
  const seats = seatsRaw.split(",").map(s => s.trim()).filter(s => s.length > 0);

  if (seats.length === 0) {
    showToast("Please enter at least one seat number", "error");
    return;
  }

  try {
    const res = await fetch("/api/bookings", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ user_id: userId, category_id: categoryId, seats: seats })
    });
    const data = await res.json();

    if (data.success) {
      showToast(`Booking #${data.booking_id} created successfully!`, "success");
      closeModal("bookModal");

      updateInspector(
        `Transaction 1: Atomic Booking Creation for User ${userId}`,
        `CALL sp_book_tickets(${userId}, ${categoryId}, ARRAY${JSON.stringify(seats)}, NULL);`,
        "trg_ticket_validate (prices tickets), trg_ticket_inventory (decrements available_seats)",
        `Booking ID: ${data.booking_id} created in PENDING status.\nDatabase Notices:\n${(data.notices || []).join('\n')}`
      );

      checkHealth();
      loadCatalog();
      loadUserWallet();

      // Offer immediate payment
      setTimeout(() => {
        openPaymentModal(data.booking_id, document.getElementById("bookTotalEstimate").innerText);
      }, 600);
    } else {
      showToast(data.error, "error");
      updateInspector(
        "Booking Rejection / Integrity Violation",
        `CALL sp_book_tickets(${userId}, ${categoryId}, ARRAY${JSON.stringify(seats)}, NULL);`,
        "UNIQUE constraint uq_category_seat OR capacity check",
        `Database Exception:\n${data.error}`
      );
    }
  } catch (err) {
    showToast("Network error submitting booking", "error");
  }
}

// =============================================================================
// WALLET, PAYMENTS & CANCELLATIONS
// =============================================================================

async function loadUserWallet() {
  const userId = document.getElementById("activeUserSelect").value;
  try {
    // 1. Load user bookings
    const bRes = await fetch(`/api/users/${userId}/bookings`);
    const bData = await bRes.json();
    const bTable = document.getElementById("userBookingsTableBody");
    bTable.innerHTML = "";

    if (bData.success && bData.bookings.length > 0) {
      bData.bookings.forEach(b => {
        const tr = document.createElement("tr");
        let badgeClass = "badge-info";
        if (b.status === "CONFIRMED") badgeClass = "badge-success";
        if (b.status === "PENDING") badgeClass = "badge-pending";
        if (b.status === "CANCELLED") badgeClass = "badge-cancelled";

        let actionHtml = `<span style="color: var(--text-muted); font-size: 0.8rem;">No actions</span>`;
        if (b.status === "PENDING") {
          actionHtml = `
            <button class="btn btn-success btn-sm" onclick="openPaymentModal(${b.booking_id}, '₹${Number(b.total_amount).toFixed(2)}')">
              Pay Now (sp_make_payment)
            </button>
          `;
        } else if (b.status === "CONFIRMED" && !b.cancellation_status) {
          actionHtml = `
            <button class="btn btn-danger btn-sm" onclick="openCancelModal(${b.booking_id})">
              Cancel Booking (sp_cancel_booking)
            </button>
          `;
        } else if (b.cancellation_status) {
          actionHtml = `<span class="badge badge-cancelled">Refunded: ₹${Number(b.refund_amount || 0).toFixed(2)}</span>`;
        }

        tr.innerHTML = `
          <td><strong>#${b.booking_id}</strong></td>
          <td>${b.event_name}</td>
          <td>${b.event_date}</td>
          <td>${b.venue_name}</td>
          <td style="font-weight: 600;">₹${Number(b.total_amount).toFixed(2)}</td>
          <td><span class="badge ${badgeClass}">${b.status}</span></td>
          <td>${actionHtml}</td>
        `;
        bTable.appendChild(tr);
      });
    } else {
      bTable.innerHTML = `<tr><td colspan="7" style="text-align: center; color: var(--text-muted);">No bookings found for active user.</td></tr>`;
    }

    // 2. Load digital tickets
    const tRes = await fetch(`/api/users/${userId}/tickets`);
    const tData = await tRes.json();
    const tTable = document.getElementById("userTicketsTableBody");
    tTable.innerHTML = "";

    if (tData.success && tData.tickets.length > 0) {
      tData.tickets.forEach(t => {
        const tr = document.createElement("tr");
        let tBadge = t.ticket_status === 'VALID' ? 'badge-success' : 'badge-cancelled';
        tr.innerHTML = `
          <td>#${t.ticket_id}</td>
          <td>#${t.booking_id}</td>
          <td>${t.event_name}</td>
          <td>${t.venue_name}</td>
          <td><span class="event-tag">${t.tier}</span></td>
          <td><strong style="color: var(--accent-cyan);">${t.seat_number}</strong></td>
          <td>₹${Number(t.price).toFixed(2)}</td>
          <td><span class="badge ${tBadge}">${t.ticket_status}</span></td>
        `;
        tTable.appendChild(tr);
      });
    } else {
      tTable.innerHTML = `<tr><td colspan="8" style="text-align: center; color: var(--text-muted);">No issued tickets for this user.</td></tr>`;
    }
  } catch (err) {
    showToast("Error loading wallet details", "error");
  }
}

function openPaymentModal(bookingId, amountStr) {
  document.getElementById("payBookingId").value = bookingId;
  document.getElementById("payBookingRef").innerText = `Booking #${bookingId}`;
  document.getElementById("payAmountDisplay").innerText = amountStr;
  openModal("paymentModal");
}

async function submitPayment() {
  const bookingId = document.getElementById("payBookingId").value;
  const method = document.getElementById("payMethodSelect").value;
  const sim = document.querySelector('input[name="paySimulate"]:checked').value === "true";

  try {
    const res = await fetch("/api/payments", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ booking_id: bookingId, payment_method: method, simulate_success: sim })
    });
    const data = await res.json();

    if (data.success) {
      closeModal("paymentModal");
      if (sim) {
        showToast(`Payment SUCCESS! Booking #${bookingId} confirmed!`, "success");
        updateInspector(
          `Transaction 2b: Successful Payment for Booking ${bookingId}`,
          `CALL sp_make_payment(${bookingId}, '${method}', TRUE);`,
          "trg_payment_confirm_booking (automatically changes status from PENDING to CONFIRMED)",
          `Payment row recorded. Booking confirmed.\nNotices:\n${(data.notices || []).join('\n')}`
        );
      } else {
        showToast(`Payment DECLINED as requested (Saved in audit trail for retry)`, "error");
        updateInspector(
          `Transaction 2a: Simulated Payment Decline for Booking ${bookingId}`,
          `CALL sp_make_payment(${bookingId}, '${method}', FALSE);`,
          "Audit trail: 1:N payment history preserved",
          `Payment row recorded with status FAILED. Booking remains PENDING.\nNotices:\n${(data.notices || []).join('\n')}`
        );
      }
      checkHealth();
      loadUserWallet();
    } else {
      showToast(data.error, "error");
    }
  } catch (err) {
    showToast("Payment processing error", "error");
  }
}

async function openCancelModal(bookingId) {
  document.getElementById("cancelBookingId").value = bookingId;
  document.getElementById("cancelBookingRef").innerText = `Booking #${bookingId}`;
  document.getElementById("cancelRefundQuote").innerText = "Calculating...";
  openModal("cancelModal");

  try {
    const res = await fetch(`/api/cancellations/quote/${bookingId}`);
    const data = await res.json();
    if (data.success) {
      document.getElementById("cancelRefundQuote").innerText = `₹${Number(data.refund_amount).toFixed(2)}`;
      updateInspector(
        `Dynamic Refund Quote for Booking ${bookingId}`,
        `SELECT fn_calculate_refund(${bookingId});`,
        "Time-decay sliding refund policy",
        `Calculated refund quote: ₹${Number(data.refund_amount).toFixed(2)}`
      );
    } else {
      document.getElementById("cancelRefundQuote").innerText = "Error";
    }
  } catch (err) {
    document.getElementById("cancelRefundQuote").innerText = "Error calculating";
  }
}

async function submitCancellation() {
  const bookingId = document.getElementById("cancelBookingId").value;
  const reason = document.getElementById("cancelReasonInput").value;

  try {
    const res = await fetch("/api/cancellations", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ booking_id: bookingId, reason: reason })
    });
    const data = await res.json();

    if (data.success) {
      showToast(`Booking #${bookingId} cancelled and refund processed!`, "success");
      closeModal("cancelModal");

      updateInspector(
        `Transaction 5: Booking Cancellation & Seat Restoration`,
        `CALL sp_cancel_booking(${bookingId}, '${reason}');`,
        "fn_calculate_refund (calculates amount), trg_ticket_inventory (restores available_seats)",
        `Tickets marked CANCELLED, Payments marked REFUNDED, Seats restored to inventory.\nNotices:\n${(data.notices || []).join('\n')}`
      );

      checkHealth();
      loadCatalog();
      loadUserWallet();
    } else {
      showToast(data.error, "error");
    }
  } catch (err) {
    showToast("Cancellation error", "error");
  }
}

// =============================================================================
// ORGANIZER PORTAL
// =============================================================================

async function loadOrganizerEvents() {
  const orgId = document.getElementById("activeUserSelect").value;
  try {
    const res = await fetch(`/api/organizers/${orgId}/events`);
    const data = await res.json();
    const table = document.getElementById("organizerEventsTableBody");
    table.innerHTML = "";

    if (data.success && data.events.length > 0) {
      data.events.forEach(e => {
        const tr = document.createElement("tr");
        tr.innerHTML = `
          <td><strong>#${e.event_id}</strong></td>
          <td>${e.event_name}</td>
          <td>${e.event_date}</td>
          <td>${e.venue_name} (Max: ${e.venue_capacity})</td>
          <td>${e.total_allocated_seats}</td>
          <td><span style="color: var(--accent-cyan); font-weight: 600;">${e.remaining_seats}</span></td>
          <td><strong style="color: var(--accent-emerald);">${Number(e.occupancy_pct).toFixed(2)}%</strong></td>
        `;
        table.appendChild(tr);
      });
    } else {
      table.innerHTML = `<tr><td colspan="7" style="text-align: center; color: var(--text-muted);">No events found. Make sure an Organizer role is selected above.</td></tr>`;
    }
  } catch (err) {
    showToast("Failed to load organizer events", "error");
  }
}

async function openAddCategoryModal() {
  const orgId = document.getElementById("activeUserSelect").value;
  try {
    const res = await fetch(`/api/organizers/${orgId}/events`);
    const data = await res.json();
    const sel = document.getElementById("newCatEventSelect");
    sel.innerHTML = "";

    if (data.success && data.events.length > 0) {
      data.events.forEach(e => {
        const opt = document.createElement("option");
        opt.value = e.event_id;
        opt.innerText = `${e.event_name} (Venue: ${e.venue_name}, Cap: ${e.venue_capacity})`;
        sel.appendChild(opt);
      });
      openModal("addCategoryModal");
    } else {
      showToast("Select an Organizer account with events first", "error");
    }
  } catch (err) {
    showToast("Error preparing modal", "error");
  }
}

async function submitNewCategory(e) {
  e.preventDefault();
  const eventId = document.getElementById("newCatEventSelect").value;
  const name = document.getElementById("newCatName").value;
  const price = document.getElementById("newCatPrice").value;
  const seats = document.getElementById("newCatSeats").value;

  try {
    const res = await fetch("/api/organizers/categories", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ event_id: eventId, category_name: name, price: price, total_seats: seats })
    });
    const data = await res.json();

    if (data.success) {
      showToast(`Category "${name}" added successfully!`, "success");
      closeModal("addCategoryModal");
      updateInspector(
        `Add Seat Category for Event ${eventId}`,
        `INSERT INTO SEAT_CATEGORY (event_id, category_name, price, total_seats, available_seats) VALUES (${eventId}, '${name}', ${price}, ${seats}, ${seats});`,
        "trg_category_capacity (validated seat total <= venue capacity)",
        "Seating tier created successfully without capacity violations."
      );
      loadOrganizerEvents();
      loadCatalog();
    } else {
      showToast(data.error, "error");
      updateInspector(
        `Transaction 4: Venue Over-Allocation Blocked`,
        `INSERT INTO SEAT_CATEGORY (event_id, category_name, price, total_seats, available_seats) VALUES (${eventId}, '${name}', ${price}, ${seats}, ${seats});`,
        "trg_category_capacity",
        `PostgreSQL Trigger Error Caught:\n${data.error}`
      );
    }
  } catch (err) {
    showToast("Error adding category", "error");
  }
}

// =============================================================================
// ADMIN & BATCH CURSORS
// =============================================================================

async function loadAdminData() {
  try {
    const res = await fetch("/api/admin/customer-spend");
    const data = await res.json();
    const table = document.getElementById("customerSpendTableBody");
    table.innerHTML = "";

    if (data.success && data.report.length > 0) {
      data.report.forEach(r => {
        const tr = document.createElement("tr");
        tr.innerHTML = `
          <td>#${r.user_id}</td>
          <td><strong>${r.name}</strong></td>
          <td>${r.email}</td>
          <td>${r.phone}</td>
          <td>${r.total_bookings}</td>
          <td style="color: var(--accent-emerald); font-weight: 700;">₹${Number(r.lifetime_spend).toFixed(2)}</td>
        `;
        table.appendChild(tr);
      });
    }
  } catch (err) {
    showToast("Failed to load customer spend analytics", "error");
  }
}

async function runAdminSettle() {
  try {
    const res = await fetch("/api/admin/settle-cancellations", { method: "POST" });
    const data = await res.json();

    if (data.success) {
      showToast("Cancellation settlement cursor job finished!", "success");
      updateInspector(
        "Transaction 6: Batch Cancellation Settlement via Explicit Cursor",
        "CALL sp_settle_approved_cancellations();",
        "cur_requests CURSOR FOR ... FOR UPDATE OF c with WHERE CURRENT OF",
        `Settlement summary:\n${(data.notices || []).join('\n')}`
      );
      checkHealth();
      loadAdminData();
    } else {
      showToast(data.error, "error");
    }
  } catch (err) {
    showToast("Failed to run cursor job", "error");
  }
}

async function runAdminExpire() {
  try {
    const res = await fetch("/api/admin/expire-stale", {
      method: "POST",
      headers: { "Content-Type": "application/json" },
      body: JSON.stringify({ hours: 24 })
    });
    const data = await res.json();

    if (data.success) {
      showToast("Stale checkouts expired!", "success");
      updateInspector(
        "Transaction 7: Unpaid Checkouts Released via Parameterized Cursor",
        "CALL sp_expire_stale_bookings(INTERVAL '24 hours');",
        "cur_stale CURSOR (p_cutoff TIMESTAMP) FOR ...",
        `Expiration summary:\n${(data.notices || []).join('\n')}`
      );
      checkHealth();
    } else {
      showToast(data.error, "error");
    }
  } catch (err) {
    showToast("Failed to run expiry job", "error");
  }
}

// =============================================================================
// ACADEMIC QUERY SUITE
// =============================================================================

function onQuerySelected() {
  const sel = document.getElementById("querySelect");
  const qId = sel.value;
  // Trigger fetch to view SQL preview
  fetchQueryPreview(qId);
}

async function fetchQueryPreview(qId) {
  try {
    const res = await fetch(`/api/queries/${qId}`);
    const data = await res.json();
    if (data.success) {
      document.getElementById("querySqlBox").innerText = data.sql;
    }
  } catch (err) {}
}

async function executeSelectedQuery() {
  const qId = document.getElementById("querySelect").value;
  try {
    const res = await fetch(`/api/queries/${qId}`);
    const data = await res.json();

    if (!data.success) {
      showToast(data.error, "error");
      return;
    }

    document.getElementById("querySqlBox").innerText = data.sql;

    const thead = document.getElementById("queryResultHead");
    const tbody = document.getElementById("queryResultBody");
    thead.innerHTML = "";
    tbody.innerHTML = "";

    if (data.rows.length === 0) {
      tbody.innerHTML = `<tr><td style="text-align: center; color: var(--text-muted);">No records returned by query.</td></tr>`;
      return;
    }

    // Render columns
    const cols = Object.keys(data.rows[0]);
    const headerTr = document.createElement("tr");
    cols.forEach(col => {
      const th = document.createElement("th");
      th.innerText = col;
      headerTr.appendChild(th);
    });
    thead.appendChild(headerTr);

    // Render rows
    data.rows.forEach(r => {
      const tr = document.createElement("tr");
      cols.forEach(col => {
        const td = document.createElement("td");
        td.innerText = r[col] !== null ? r[col] : "NULL";
        tr.appendChild(td);
      });
      tbody.appendChild(tr);
    });

    updateInspector(
      `Academic SQL Execution: ${data.title}`,
      data.sql,
      "Direct PostgreSQL 16 Query Engine",
      `Query executed successfully. ${data.row_count} row(s) returned.`
    );

    showToast(`Query ${qId} executed: ${data.row_count} rows returned`, "success");
  } catch (err) {
    showToast("Error executing query", "error");
  }
}
