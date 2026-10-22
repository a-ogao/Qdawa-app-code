# QuikDawa Pharmacy Role Technical Specification (Flutter -> Electron)

This document is the **Pharmacy User Role** technical specification, generated from the existing Flutter codebase. It focuses **only** on the **Pharmacy User Role** (`usr_user_type == 'pharmacist'`). Other roles are documented separately.

**Related specifications:**
- **Doctor role:** [`techspec-doc.md`](techspec-doc.md) (`usr_user_type == 'healthcare_provider'`)
- **Supplementary pharmacy API notes:** [`pharmacy_tech.md`](pharmacy_tech.md)

If any field/shape is marked **Assumed**, it is inferred from multiple code paths or from inconsistent server key naming.

---

## 1. Project Overview

### Purpose of the application
QuikDawa is a health/commerce workflow app that supports multiple user roles and order/quotation lifecycles. This document covers **only the “Pharmacy User Role”** and the screens/APIs reachable/used by a pharmacist (including shared profile/account screens that pharmacists can access).

### Pharmacy user role responsibilities
A pharmacist user is responsible for:
- Viewing dashboard counters and recent orders.
- Managing **quotation requests** for prescriptions:
  - Reviewing quotation requests.
  - Submitting quotation items (medicine amounts/dosage/qty) back to the user.
  - Viewing quotation details once submitted/processed.
  - Viewing the written prescription (items, notes, signature).
- Managing **OTC (Over-The-Counter) requests**:
  - Submitting OTC quotations (including symptom-based requests).
  - Rejecting OTC requests with a reason.
- Processing **orders**:
  - Viewing all/pharmacy-filtered orders.
  - Viewing order details (payment info, line items, order status).
  - Assigning delivery riders (for delivery orders).
  - Verifying pickup/delivery OTP and updating order/delivery statuses.
- Handling **payments overview** (“Total Sales” list).
- Handling **pharmacy notifications** (marking notifications as read).
- Managing the pharmacist **customers list** (patients who placed orders with the pharmacist).
- Generating **prescription reports** (PDF) for a date range.
- Managing the pharmacist **profile/account** (edit info, change phone/email, delete account).

### Key features used by pharmacy
- Role-based landing after login (`usr_user_type == 'pharmacist'`).
- Pharmacy sidebar navigation + route-driven screen transitions.
- Search/filter UI for orders, quotations, OTC requests, customers.
- OTP verification for order lifecycle transitions.
- Notification badge + notification list, with read/unread behavior.
- PDF report generation for pharmacy prescriptions.
- Push notification registration via OneSignal (device registration).

---

## 2. Authentication Flow (Pharmacy Role)

### Login screen UI elements
Screen: `lib/presentation/sign_in_screen/sign_in_screen.dart` (`SignInScreen`)

Desktop-oriented UI elements to recreate:
- Username/email input (`usr_email`)
- Password input (`usr_password_hash`)
- “Remember me” checkbox
- “Forgot Password?” link
- “Sign In” primary button
- Background gradient + centered auth card
- Loading overlay (“Signing in...”)

Validation implemented:
- Username/email must be non-empty.
- Password must be non-empty and length >= 6.

### API endpoint for login
Endpoint in code:
- `AppConfig.buildApiUrl('login')`
- Full URL (from `AppConfig`): `https://quikdawa.com/QdawaAPIs/public/index.php/login`

Method: `POST`

Headers:
- `Content-Type: application/x-www-form-urlencoded`

### Request payload (POST data)
Form fields:
```json
{
  "usr_email": "user@example.com",
  "usr_password_hash": "password123"
}
```
Note: despite the field name `usr_password_hash`, the app sends the raw controller value to this endpoint.

### Response structure (success & error)
Success case (code checks `statusCode == 200` and body contains keys `token` and `user`):
```json
{
  "token": "session_token_string",
  "user": {
    "id": 123,
    "usr_user_type": "pharmacist",
    "usr_username": "john_doe",
    "usr_email": "user@example.com",
    "usr_mobile_number": "+254712345678"
  },
  "verify_user": "1"
}
```

Error case:
- On non-200 status, the UI attempts `jsonDecode(response.body)` and reads `message`.
- If response body appears to be HTML (server error), it shows a generic server error message.

### Token handling (JWT/session/etc.)
- Token stored in `SharedPreferences` key: `sessionToken`
- User data stored in key: `userData` (JSON string of the `user` object from API)
- “Remember me” persists:
  - `saved_email`
  - `saved_password`
  - `remember_me` boolean

### Logout mechanism
Component: `lib/presentation/pharmacy/nav_bar/navbar_widget.dart` (`Navbar` drawer)

Logout behavior:
- Reads saved credentials: `saved_email`, `saved_password`, `remember_me`
- Calls `prefs.clear()`
- If `remember_me` was enabled, restores `saved_email`, `saved_password`, `remember_me=true`
- Routes to: `/sign_in_screen`

No server-side logout call exists in this code.

---

## Pharmacy-specific account verification OTP (if required)
Screen: `lib/presentation/user_verification_screen/user_verification_screen.dart` (`UserVerificationScreen`)

UI:
- OTP entry (6 digits) using `PinCodeTextField`
- “Verify” button
- “Resend Code” link

API:
- `verify_otp` endpoint (used on verify)
- `resend_otp` endpoint (used on resend)

Verify API:
- `POST https://quikdawa.com/QdawaAPIs/public/index.php/verify_otp`
- Request (form):
```json
{
  "usr_id": "123",
  "usr_otp": "123456"
}
```
- Response logic:
  - code checks `response.statusCode == 200 && responseData['status'] == "success"`
  - on success and `usr_user_type == 'pharmacist'`, navigates to `PharmacyDashboardScreen`

Resend API:
- `POST https://quikdawa.com/QdawaAPIs/public/index.php/resend_otp`
- Request (form):
```json
{
  "usr_id": "123"
}
```
- No strict response parsing is required by UI; it only checks status code.

---

## 3. Screen-by-Screen Breakdown (VERY IMPORTANT)

For each screen used by pharmacy role, this section includes: purpose, desktop UI layout conversion, user actions, API integration, business logic, and state management.

---

## Screen Name: PharmacyDashboardScreen

### 1. Purpose
- Shows pharmacy overview:
  - Counters: quotations, OTC, total sales, customers, pending, dispatched, notifications.
  - “My Orders” preview: last 3 orders from API.
- Initializes push notification registration if `sessionToken` exists and device not registered.
- Checks pending push notification navigation via `NotificationService.getPendingNotification()` and routes accordingly.

### 2. UI Layout (Desktop-Oriented)
- Top bar: title “Pharmacy Dashboard” + notification icon with badge.
- Left sidebar: use a persistent sidebar (desktop replacement for Flutter `Drawer`).
- Main content:
  - Tiles/grid for services (Quotations, Orders, Riders, Reports, Messages, Doctors).
  - “Statistics” section as a responsive grid of cards.
  - “My Orders” as a table for desktop.
- Responsive behavior:
  - fixed sidebar + content region with max width constraints.
  - tiles wrap naturally on larger widths.

Reusable components (recommended):
- `PharmacyCountersSummaryCard`
- `OrdersPreviewTable`
- `NotificationBadgeIcon`

### 3. User Actions
- Click tiles:
  - Quotations -> `/quotation_requests_pharmacy_screen`
  - OTC -> `/pharmacy_usersymptoms_screen`
  - Total Sales -> `/payment_pharmacy_screen`
  - Customers -> `/pharmacy_customers_list_screen`
  - Pending -> `/Pending_order_list_screen`
  - Dispatched -> `/dPharmacy_order_list_screen`
- Click notification badge (if badge count > 0) -> `/pharmacy_notification`
- Use sidebar navigation.

### 4. API Integration
1. `POST .../pharmacycounters`
   - Request body (form):
```json
{ "usr_id": "123" }
```
   - Response (example):
```json
{
  "quotations": 10,
  "otc": 5,
  "orders": 25,
  "totalAmount": "KSH 50000",
  "delivered": 20,
  "pending": 3,
  "notification": 7,
  "patient": 50
}
```
   - Error cases:
     - JSON parsing failure or server returns HTML => fallback default counters (assumed zeros).

2. `POST .../getLastThreepOrders`
   - Request body (form):
```json
{ "usr_id": "123" }
```
   - Response (example from docs):
```json
{
  "success": true,
  "orders": [
    {
      "pha_first_name": "Malibu Pharmacy Limited",
      "ord_order_status": "Delivered",
      "ord_total_amount": 5000,
      "ord_created_dt": "2024-01-15 10:30:00"
    }
  ]
}
```
   - Error cases:
     - server error/exception => recent orders not shown, `isLoading` ends.

### 5. Business Logic
- Push notification navigation:
  - based on `type` and IDs in pending notification data.

### 6. State Management Logic
- Loads:
  - `counters` once (`fetchCounters`)
  - `orderss` once (`fetchOrders`)
  - notification registration and pending notification navigation on init.

---

## Screen Name: QuotationRequestsPharmacyScreen

### 1. Purpose
- Displays pharmacy quotation requests.
- Search/filter locally.
- Tap row:
  - if status is `pending` -> go to Submit Quotation
  - else -> go to View Quotation

### 2. UI Layout (Desktop-Oriented)
- Sidebar + top bar “Quotation Requests”.
- Search bar above a table.
- Table columns:
  - Request ID, Patient Name, Location, Phone, Total Amount, Status, Created Date

### 3. User Actions
- Search as user types.
- Click row:
  - pending -> `/submit_quotation_screen` args `{id: item.id}`
  - else -> `/view_quotation_screen` args `{id: item.id}`

### 4. API Integration
1. `POST .../get_pharmacy_request`
   - Request (form):
```json
{ "pharmacy_id": "123" }
```
   - Response (example from docs):
```json
{
  "quotations": [
    {
      "id": 789,
      "qre_request_id": "REQ-12345",
      "usr_username": "customer_name",
      "pat_first_name": "John",
      "adr_address_1": "123 Main Street",
      "usr_mobile_number": "+254712345678",
      "quo_total_amount": 5000,
      "quo_created_dt": "2024-01-15 10:30:00",
      "qre_quotation_status": "pending",
      "qre_orignalfilepath": "prescriptions/prescription_123.jpg",
      "prescription_id": "PRES-123",
      "qre_doctor_id": "DOC-456"
    }
  ]
}
```
   - Error cases:
     - status != 200 => lists empty
     - unexpected response keys => lists empty

2. Counters:
- `POST .../pharmacycounters` with `{ "usr_id": "123" }`

### 5. Business Logic
- Local filtering uses keys:
  - `qre_request_id`, `usr_username`, `quo_total_amount`, `adr_address_1`, `quo_created_dt`, `usr_mobile_number`.

### 6. State Management Logic
- Loads `quotations` and `counters` on init.
- Filters locally without refetching.

---

## Screen Name: SubmitQuotationScreen

### 1. Purpose
- Submit quotation line items for a specific quotation request.

### 2. UI Layout (Desktop-Oriented)
- Sidebar + top app bar.
- Header:
  - “Quotation Request #<id>”
  - prescription view button + image thumbnail (if file path exists)
- Main form:
  - Convert row editor into a desktop table with editable columns:
    - Item Name (editable)
    - Qty (editable)
    - Per Unit Amt (editable)
    - Amount (computed read-only)
    - Dose (mapped to `item_dose` in payload)
  - “Add More” action adds a new row.
  - If delivery: show delivery charges input.
- Submit button bottom/right.

### 3. User Actions
- Edit values; computed amount updates.
- Submit Quotation button is shown when status is pending.
- View prescription details from header.

### 4. API Integration
1. Fetch quotation items:
   - `POST .../quotation_details`
   - Request (form):
```json
{
  "usr_id": "123",
  "request_id": "456"
}
```
   - Response (Assumed from docs/usage):
     - `quotations[]` + `address[]`

2. Submit quotation:
   - `POST .../pharmacy_submit_quotation`
   - Request (form):
     - `pharmacy_id` = userData.id
     - `quotations` = JSON-encoded array of line items

   - Example payload shape from docs (stringified array):
```json
{
  "pharmacy_id": "123",
  "quotations": "[{\"request_id\":789,\"item_amount_perunit\":\"50\",\"item_qty\":\"10\",\"item_amount\":\"500\",\"item_dose\":\"2\",\"item_name\":\"Paracetamol\",\"usr_id\":456,\"doctor_id\":789,\"qre_order_type\":\"delivery\",\"delivery_charge\":\"200\"}]"
}
```

   - Response (example from docs):
```json
{
  "success": true,
  "message": "Quotation Submitted Successfully and sent to User!"
}
```

3. Prescription view:
   - `POST .../writeprescriptionview`

### 5. Business Logic
- Validate each item:
  - amount must be > 0; otherwise submission aborts.
- Totals computed in UI:
  - sum(qty * perUnit) + delivery charge (if delivery).

### 6. State Management Logic
- Loads quotation details once on init.
- Initializes per-row `TextEditingController`s after fetch.
- Recalculates totals on input change.

---

## Screen Name: ViewQuotationScreen

### 1. Purpose
- Read-only view of quotation items and totals.
- Shows prescription view option if `prescription_id` is present.

### 2. UI Layout (Desktop-Oriented)
- Table for items:
  - Item Name, Dosage, Qty, Per-Unit Price, Amount
- Summary:
  - Delivery charges (if > 0)
  - Total

### 3. User Actions
- Tap prescription icon -> `PharmacyPrescriptionViewScreen`

### 4. API Integration
1. Fetch quotation view details:
   - `POST .../view_quotation_details`
   - Request (form):
```json
{
  "usr_id": "123",
  "request_id": "456"
}
```
   - Response:
     - `quotations[]` contains per-item fields and totals fields like `quo_total_amount`, `quo_delivery_charge`, `quo_quotation_status`.

### 5. Business Logic
- Delivery vs pickup inferred:
  - `quo_delivery_charge` > 0 => delivery.

### 6. State Management Logic
- Loads once on init, then renders.

---

## Screen Name: PharmacySymptomsScreen (OTC Requests)

### 1. Purpose
- Lists OTC requests assigned to the pharmacist.
- Search by request id.
- Tap row:
  - pending -> submit OTC
  - else -> view quotation

### 2. UI Layout (Desktop-Oriented)
- Sidebar + top bar “OTC Requests”.
- Search bar.
- Table view:
  - Request ID, Patient Name, Location, Phone, Total Amount, Status

### 3. User Actions
- Search.
- Click row -> submit/view screens.

### 4. API Integration
1. `POST .../get_pharmacy_symrequest`
   - Request (form):
```json
{ "pharmacy_id": "123" }
```
   - Response (example from docs, partial):
```json
{
  "quotations": [
    {
      "qre_request_id": "REQ-12345",
      "requesttype": "Sym",
      "usr_username": "customer_name",
      "quo_total_amount": 3000,
      "quo_created_dt": "2024-01-15 10:30:00"
    }
  ]
}
```

2. Counters:
- `POST .../pharmacycounters`

### 5. Business Logic
- Local filtering:
  - checks `qre_request_id` contains query.

### 6. State Management Logic
- Loads on init (`fetchQuotations`) and supports pull-to-refresh in UI.

---

## Screen Name: SubmitOTCScreen

### 1. Purpose
- Submit OTC quotation items for a specific OTC request.
- Symptom-based requests show symptom details with a toggle.
- Allows rejecting OTC with a reason.

### 2. UI Layout (Desktop-Oriented)
- Header section:
  - Delivery address or pickup order info
  - Delivery “Get Location” button (opens Google Maps URL)
- Optional symptom details collapsible card.
- Items table (editable):
  - Sr., Item Name, Qty, Per Unit Amt, Amount (computed read-only)
  - Delete row button appears for indexes != 0 (when requesttype == Sym)
- Total summary includes delivery charge if delivery.
- Bottom buttons:
  - Submit Quotation
  - Reject OTC (opens dialog)

### 3. User Actions
- Toggle symptom details.
- Edit item fields; computed totals update.
- Reject OTC: enter reason; submit `reject_request`.
- Submit OTC: validate amount per line; submit `pharmacy_otcsubmit_quotation`.

### 4. API Integration
1. Fetch OTC request item data:
   - `POST .../quotation_details`
   - Request (form):
```json
{
  "usr_id": "123",
  "request_id": "456"
}
```
   - Response includes `quotations[]`, `address[]`, and `symtoms[]` (for symptom request type).

2. Reject OTC request:
   - `POST .../reject_request`
   - Request (form):
```json
{
  "request_id": "456",
  "reason": "string"
}
```

3. Submit OTC quotation:
   - `POST .../pharmacy_otcsubmit_quotation`
   - Request (form):
     - `pharmacy_id`
     - `quotations` JSON-encoded array built from edited UI

### 5. Business Logic
- Validation:
  - item `amount` must be > 0
- Symptom details mapping uses symptom object keys:
  - `mds_year`, `mds_safety`, `mds_symptom_desc`, `mds_duration`, `mds_triggers`, `mds_severity`, `mds_medicalhistory`,
  - `mds_currentmedications`, `mds_previousremedies`, `mds_lifestylefactors`

### 6. State Management Logic
- Loads `quotations`, `address`, `symtoms` on init once.
- Initializes controllers.
- Updates computed values on edit.

---

## Screen Name: PharmacyPrescriptionViewScreen

### 1. Purpose
- Display written prescription details:
  - header info
  - patient info
  - prescribed medicines with frequency
  - notes
  - doctor signature (base64 or data URL)

### 2. UI Layout (Desktop-Oriented)
- Use 2-column desktop layout:
  - Left: prescription info + patient info + medicines list/table
  - Right: signature image/card (if available)
- Medicines rendered as table-like list entries.
- Notes card and signature card shown conditionally.

### 3. User Actions
- Back navigation.
- Retry on error state.

### 4. API Integration
1. Fetch written prescription details:
   - `POST .../writeprescriptionview`
   - Request body JSON:
```json
{
  "prescription_id": "PRES-123"
}
```
   - Response:
     - expects `{ "success": true, "data": { ... } }`
   - UI reads:
     - `data.pre_prescription_number`, `data.pre_patient_name`, `data.items[]` etc.
     - `data.pre_signature` (signature string)

### 5. Business Logic
- Frequency string is built based on:
  - `pit_frequency_mn`, `pit_frequency_af`, `pit_frequency_en`, `pit_frequency_nt`

### 6. State Management Logic
- Loads on init; renders loading/error/empty states.

---

## Screen Name: PharmacyOrderListScreen

### 1. Purpose
- Pharmacy order list (all non-filtered by status).

### 2. UI Layout (Desktop-Oriented)
- Top bar “Order List”.
- Search bar.
- Status filters row of chips.
- Table/list of orders; desktop should use a table for efficient scanning.

### 3. User Actions
- Search orders.
- Click filter chips.
- Click row -> OrderView.

### 4. API Integration
1. Counters:
   - `POST .../pharmacycounters`
2. Orders:
   - `POST .../get_pharmacy_order`
   - Request body: `{ "usr_id": "123" }`
   - Response: `data['orders']` list.

### 5. Business Logic
- Client-side filtering uses:
  - `ord_order_status` and multiple searchable fields.

### 6. State Management Logic
- Loads in init:
  - `counters`
  - orders future
- Refresh indicator not present in this screen’s list build; main lists use `FutureBuilder`.

---

## Screen Name: PendingOrderListScreen

### 1. Purpose
- Shows orders that are NOT `delivered` and NOT `dispatched`.

### 2. UI Layout (Desktop-Oriented)
- Top bar “Pending Orders”.
- Search bar.
- Stats card with pending count.
- Orders table/list.

### 3. User Actions
- Search.
- Pull-to-refresh.
- Click row -> OrderView.

### 4. API Integration
1. Counters:
   - `POST .../pharmacycounters`
2. Orders:
   - `POST .../get_pharmacy_order`
   - Request body `{ "usr_id": "123" }`
   - Response orders filtered client-side by status.

### 5. Business Logic
- Pending logic:
  - `status != 'delivered' && status != 'dispatched'`

### 6. State Management Logic
- Loads counters + orders on init.
- Refresh re-fetches orders.

---

## Screen Name: dPharmacyOrderListScreen (Dispatched/Delivered List)

### 1. Purpose
- Displays dispatched/delivered list from `get_pharmacy_dorder`.

### 2. UI Layout (Desktop-Oriented)
- Top bar “Dispatched Order List”.
- Search bar.
- Orders list.

### 4. API Integration
- Counters: `pharmacycounters`
- Orders: `get_pharmacy_dorder`
  - request `{ "usr_id": "123" }`
  - reads `data['orders']`

### 6. State Management Logic
- Loads on init; list refresh is via `RefreshIndicator`.

---

## Screen Name: OrderView

### 1. Purpose
- Order detail view:
  - line items
  - payment information (depends on payment mode)
  - order status
- Provides pharmacist actions to progress order lifecycle:
  - “Ready to Dispatch” for delivery (assign rider -> sets order `ready` and triggers OTP flow)
  - “Enter Pickup Code” or “Dispatch” for OTP verification

### 2. UI Layout (Desktop-Oriented)
- Top header: “Order Info”
- Main content:
  - Left column: order id, last activity, delivery charges, line items table, totals
  - Right column: payment details card based on payment mode
- Bottom action area:
  - conditional buttons for rider assignment/OTP verification

### 3. User Actions
- Depending on `ordertype` and `currentStatus`:
  - delivery + pending -> confirmation dialog -> RiderListScreen
  - delivery + ready -> OTP -> dispatched
  - pickup + pending -> OTP -> pickedup
  - delivered/pickedup/dispatched show status text only

### 4. API Integration
1. `POST .../order_view`
   - Request (form):
```json
{ "order_id": "456" }
```
   - Response:
     - `order` header object
     - `items[]`
   - Code reads:
     - `ord_order_status`
     - `ord_payment_mode`
     - `ord_total_amount`
     - `ord_delivery_charge`
     - `pharmacy_rating`
     - `tra_transaction_id` and payment status fields (varied names)

2. `POST .../get_payment_details`
   - Request (form):
```json
{
  "order_id": "456",
  "payment_mode": "mobile_payment"
}
```
   - Response:
     - uses `data['payment_data']` structure by mode.

3. Status updates:
- Pharmacist does **not** call update immediately from this screen (the confirmation dialog to update status is commented out).
- Actual updates occur in:
  - `RiderListScreen` -> `update_ostatus` with `ord_order_status=ready` and `riderid`
  - `OtpInputScreen` -> `update_ostatus` or `delivery_dstatus`

### 5. Business Logic
- Payment mode:
  - `mobile_payment` -> show transaction id/date/status
  - `insurance` -> show policy info
  - `coupon` -> show guardian/coupon/beneficiary info

### 6. State Management Logic
- Loads on init and re-renders:
  - fetch `order_view`
  - fetch `get_payment_details`

---

## Screen Name: RiderListScreen (Choose Rider)

### 1. Purpose
- Display available delivery riders.
- Select exactly one rider.
- “Submit” triggers:
  - `update_ostatus` with `ord_order_status='ready'` and selected `riderid`.

### 2. UI Layout (Desktop-Oriented)
- Search box.
- Table of riders:
  - ID, Name, Phone, Email, Total Orders, Rating (if available)
- Selection:
  - radio buttons
- Submit button.

### 4. API Integration
1. Fetch riders:
   - `POST .../get_riders`
   - Request:
     - code posts with no body (only headers)
   - Response:
     - expects `data['success'] == true && data['data'] != null`
     - uses rider fields: `id`, `usr_username`, `usr_email`, `usr_mobile_number`, `total_orders` (if present)

2. Update order status:
   - `POST .../update_ostatus`
   - Request body (form):
```json
{
  "order_id": "456",
  "ord_order_status": "ready",
  "riderid": "789"
}
```

### 5. Business Logic
- If no rider selected: prevent submit and show snackbar.

### 6. State Management Logic
- Loads riders once on init.
- Client-side search filtering.

---

## Screen Name: vRiderListScreen (Legacy/Alternate)
This is also a rider listing screen but uses:
- `POST .../get_ridersnew`

In this spec, the primary rider flow for pharmacist is:
- `OrderView` -> `RiderListScreen` (choose rider) -> `OtpInputScreen` or next transitions.

---

## Screen Name: OtpInputScreen

### 1. Purpose
- Verify OTP for pickup/delivery transitions.
- Resend OTP.
- Update order/delivery status after valid OTP.

### 2. UI Layout (Desktop-Oriented)
- Centered title + OTP inputs (6-digit)
- Resend button link
- Primary verify button

### 3. User Actions
- Enter OTP digits and verify.
- Resend OTP.

### 4. API Integration
1. Resend OTP:
   - `POST .../orderresend_otp`
   - Request (form):
```json
{
  "order_id": "456",
  "order_type": "pickup"
}
```

2. Verify OTP:
   - `POST .../verify_statusotp`
   - Request (form):
```json
{
  "order_id": "456",
  "otp": "123456"
}
```
   - Response:
     - code treats `statusCode == 200` as valid OTP.

3. Update order status:
   - `POST .../update_ostatus`
   - Request (form):
```json
{
  "order_id": "456",
  "ord_order_status": "pickedup"
}
```
   - For delivery:
```json
{
  "order_id": "456",
  "ord_order_status": "dispatched"
}
```

4. Update delivery status (for delivery_person):
   - `POST .../delivery_dstatus`
   - Request (form):
```json
{
  "order_id": "456",
  "del_delivery_status": "delivered"
}
```

### 5. Business Logic
- OTP length must be exactly 6.
- Navigation on success:
  - pickup/delivery -> `PharmacyOrderListScreen`
  - delivery_person -> `DeliveredOrdersItem()`

### 6. State Management Logic
- Stores OTP input in 6 text controllers.
- Minimal state: `_isResending` and OTP controllers.

---

## Screen Name: PaymentListScreen (Total Sales)

### 1. Purpose
- Displays “Total Sales” summary and list of payment/order records.
- Search/filter by request id, patient, status.

### 2. UI Layout (Desktop-Oriented)
- Top bar “Total Sales” with notification sidebar.
- Summary card with:
  - Total Amount
  - Total Orders
- Search bar.
- Table of payment records:
  - Request ID, Patient, Amount, Status, Date

### 4. API Integration
1. Payments:
   - `POST .../get_payments`
   - Request (form):
```json
{ "usr_id": "123" }
```
   - Response:
     - expects `body['success'] == true && body['data'] != null`
     - reads list from `body['data']`

Total amount calculation:
- sums `ord_total_amount` from each record (UI note says delivery charge excluded).

### 6. State Management Logic
- loads once on init.
- pull-to-refresh reloads.
- filtering is local (`filteredPayments`).

---

## Screen Name: PharmacyNotificationScreen

### 1. Purpose
- Fetch notifications for the pharmacist.
- Marks them as read after fetch.

### 2. UI Layout (Desktop-Oriented)
- Top bar “Notifications”.
- Table/list:
  - Remark, Created date, Status badge

### 4. API Integration
1. Fetch notifications:
   - `POST .../get_pharmacy_notification`
   - Request body:
```json
{ "usr_id": "123" }
```
   - Response:
     - `quotations[]` (used as notifications)

2. Mark notifications as read:
   - `POST .../update_nstatus`
   - Request body:
```json
{ "usr_id": "123" }
```

### 5. Business Logic
- badge uses `noti_status`:
  - `read` => green “Read”
  - else => orange “New”

### 6. State Management Logic
- loads on init; sets `isLoading=false` after fetch.
- immediate read update call.

---

## Screen Name: PharmacyCustomersListScreen

### 1. Purpose
- Show patients/customers linked to pharmacist orders.
- Search and refresh.

### 2. UI Layout (Desktop-Oriented)
- Search input above a table.
- Table columns:
  - Customer ID, Patient Name, Username, Mobile, Total Orders

### 4. API Integration
1. Fetch customers:
   - `POST .../get_pharmacy_customers`
   - Request (form):
```json
{ "usr_id": "123" }
```
   - Response format may vary (code supports multiple shapes):
     - `{ data: [...] }`
     - `{ success: true, data: [...] }`
     - `{ customers: [...] }`
     - direct array

### 6. State Management Logic
- loads once on init and refreshes on pull-to-refresh.

---

## Screen Name: PReportsPage (Prescription Reports)

### 1. Purpose
- Generate a prescription report PDF for a date range.

### 2. UI Layout (Desktop-Oriented)
- Top bar “Prescription Reports”.
- Date pickers:
  - From Date
  - To Date
- “Generate Report” button.

### 4. API Integration
1. Fetch prescriptions:
   - `POST .../fetchpharmacy_Prescriptions`
   - Request (form):
```json
{
  "from_date": "YYYY-MM-DD",
  "to_date": "YYYY-MM-DD",
  "usr_id": "123"
}
```
   - Response:
     - expects `success == true` and `data` list

### 9. Business/Third party
- PDF generation: `pdf` and `open_filex`

---

## Screen Name: ProfileScreen (Pharmacy Account)

### 1. Purpose
- Display profile and account actions.
- Supports edit profile, change phone/email, delete account.

### 2. UI Layout (Desktop-Oriented)
- Sidebar + top bar “Profile”.
- Header card with avatar, name, user type badge.
- Full-width actions card with action list items.

### 4. API Integration
- Delete:
  - `POST .../delete_pharmacist` when `userType == "pharmacist"`
  - Request (form):
```json
{ "usr_id": "123" }
```

### 6. State Management Logic
- loads `userData` from local storage on init.

---

## Screen Name: EditProfileScreen

### 1. Purpose
- Update pharmacist profile details.

### 2. UI Layout (Desktop-Oriented)
- Form:
  - First name, Email, Phone number, Address (pharmacist only), Username
- Save button.

### 4. API Integration
1. Load user:
   - `POST .../get_user`
   - Request (form):
```json
{ "usr_id": "123" }
```
2. Update user:
   - `POST .../update_user`
   - Request (form):
```json
{
  "first_name": "John",
  "email": "john@example.com",
  "phone_number": "0712345678",
  "pha_address": "Nairobi",
  "username": "john_doe",
  "usr_id": "123"
}
```

---

## Screen Name: ChangePhoneNumberScreen / ChangeEmailScreen

### Purpose
- Update phone/email through dedicated forms.

### API Integration
Change Phone:
- `POST .../get_user` (load current phone)
- `POST .../update_mobile` with `{ usr_id, phone_number }`

Change Email:
- `POST .../get_user` (load current email)
- `POST .../update_email` with `{ usr_id, email }`

---

## 4. API Master List (Pharmacy role only)

All endpoints below are used directly by pharmacy role screens.

Base API URL:
`https://quikdawa.com/QdawaAPIs/public/index.php`

### Auth
- `POST /login`
- `POST /verify_otp`
- `POST /resend_otp`

### Push Notifications (OneSignal)
- `POST /api/register_device`
  - called by `NotificationService.registerDevice`
  - uses `Authorization: Bearer <sessionToken>` and JSON body

### Pharmacy Dashboard
- `POST /pharmacycounters`
- `POST /getLastThreepOrders`

### Orders
- `POST /get_pharmacy_order`
- `POST /get_pharmacy_dorder`
- `POST /order_view`
- `POST /get_payment_details`
- `POST /update_ostatus`
- `POST /delivery_dstatus`

### OTP & Status
- `POST /orderresend_otp`
- `POST /verify_statusotp`

### Quotation / Prescription
- `POST /get_pharmacy_request`
- `POST /quotation_details`
- `POST /pharmacy_submit_quotation`
- `POST /view_quotation_details`
- `POST /reject_request`
- `POST /writeprescriptionview`

### OTC (Over-The-Counter)
- `POST /get_pharmacy_symrequest`
- `POST /pharmacy_otcsubmit_quotation`

### Payments (Total Sales)
- `POST /get_payments`

### Notifications
- `POST /get_pharmacy_notification`
- `POST /update_nstatus`

### Customers
- `POST /get_pharmacy_customers`

### Reports
- `POST /fetchpharmacy_Prescriptions`

### Riders / Delivery Assignment
- `POST /get_riders`
- `POST /get_ridersnew` (alternate list screen)

### Profile / Account
- `POST /get_user`
- `POST /update_user`
- `POST /update_mobile`
- `POST /update_email`
- `POST /delete_pharmacist`

---

## 5. Data Models (Request/Response JSON)

This section includes representative payload shapes used by the pharmacy role.

Where server response naming is inconsistent, fields are marked **Assumed**.

### Auth
LoginRequest (form-urlencoded):
```json
{
  "usr_email": "string",
  "usr_password_hash": "string"
}
```

### Push Notification registration
RegisterDeviceRequest (JSON):
```json
{
  "player_id": "string",
  "usr_id": 123,
  "device_type": "android|ios|web",
  "device_name": "string"
}
```

### Pharmacy counters
```json
{ "usr_id": "string" }
```

### Orders
GetPharmacyOrdersRequest:
```json
{ "usr_id": "string" }
```

OrderViewRequest:
```json
{ "order_id": "string" }
```

GetPaymentDetailsRequest:
```json
{
  "order_id": "string",
  "payment_mode": "mobile_payment|insurance|coupon"
}
```

UpdateOrderStatusRequest:
```json
{
  "order_id": "string",
  "ord_order_status": "ready|pickedup|dispatched|delivered"
}
```

Rider assignment (extra rider id):
```json
{
  "order_id": "string",
  "ord_order_status": "ready",
  "riderid": "string"
}
```

DeliveryStatusRequest:
```json
{
  "order_id": "string",
  "del_delivery_status": "pickedup|delivered"
}
```

### Quotations
GetPharmacyQuotationRequestsRequest:
```json
{ "pharmacy_id": "string" }
```

QuotationDetailsRequest:
```json
{
  "usr_id": "string",
  "request_id": "string"
}
```

SubmitQuotationRequest (form, with stringified JSON array):
```json
{
  "pharmacy_id": "string",
  "quotations": "stringified array"
}
```

RejectRequestRequest:
```json
{
  "request_id": "string",
  "reason": "string"
}
```

ViewQuotationDetailsRequest:
```json
{
  "usr_id": "string",
  "request_id": "string"
}
```

WritePrescriptionViewRequest:
```json
{
  "prescription_id": "string"
}
```

### OTC
GetPharmacyOTCRequestsRequest:
```json
{
  "pharmacy_id": "string"
}
```

OTC submit:
```json
{
  "pharmacy_id": "string",
  "quotations": "stringified array"
}
```

### Payments
GetPaymentsRequest:
```json
{ "usr_id": "string" }
```

### Notifications
GetPharmacyNotificationRequest:
```json
{ "usr_id": "string" }
```

UpdateNotificationStatusRequest:
```json
{ "usr_id": "string" }
```

### Customers
GetPharmacyCustomersRequest:
```json
{ "usr_id": "string" }
```

### Reports
FetchPharmacyPrescriptionsRequest:
```json
{
  "from_date": "YYYY-MM-DD",
  "to_date": "YYYY-MM-DD",
  "usr_id": "string"
}
```

---

## 6. Navigation Flow (Text-based)

Pharmacy role flow:
- `SignInScreen`
  - if verified & pharmacist -> `PharmacyDashboardScreen`
  - else -> `UserVerificationScreen`
- `UserVerificationScreen`
  - OTP verify -> `PharmacyDashboardScreen` (pharmacist)
- `PharmacyDashboardScreen`
  - Drawer:
    - Quotations -> `QuotationRequestsPharmacyScreen`
    - OTC -> `PharmacySymptomsScreen`
    - Orders -> `PharmacyOrderListScreen` (or pending/dispatched lists)
    - Profile -> `ProfileScreen`
  - Notifications icon -> `PharmacyNotificationScreen`
- `QuotationRequestsPharmacyScreen`
  - status pending -> `SubmitQuotationScreen`
  - else -> `ViewQuotationScreen`
- `SubmitQuotationScreen`
  - Submit -> back to `QuotationRequestsPharmacyScreen`
  - Prescription view -> `PharmacyPrescriptionViewScreen`
- `PharmacySymptomsScreen`
  - pending -> `SubmitOTCScreen`
  - else -> `ViewQuotationScreen`
- `SubmitOTCScreen`
  - Submit/Reject -> back to `PharmacySymptomsScreen`
  - Prescription view -> (modal in code) / or view quotation depending on flow
- `PharmacyOrderListScreen` / `PendingOrderListScreen` / `dPharmacyOrderListScreen`
  - row click -> `OrderView(orderId)`
- `OrderView`
  - delivery + pending -> confirm -> `RiderListScreen(orderId, orderType)`
  - delivery + ready -> OTP -> `OtpInputScreen` -> back to order list
  - pickup + pending -> OTP -> back to order list
- `RiderListScreen`
  - Submit -> `update_ostatus(ready + riderid)` -> back to order list
- `OtpInputScreen`
  - Resend -> `orderresend_otp`
  - Verify -> `verify_statusotp`
  - On success:
    - pickup -> `update_ostatus(pickedup)`
    - delivery -> `update_ostatus(dispatched)`
    - delivery_person -> `delivery_dstatus(delivered)`
- Supporting screens:
  - `PaymentListScreen` (Total Sales)
  - `PharmacyNotificationScreen`
  - `PharmacyCustomersListScreen`
  - `PReportsPage` (PDF generation)
  - `ProfileScreen` + edit/change/delete forms

---

## 7. Desktop UI/UX Guidelines (Windows/Electron)

### Sidebar navigation
- Replace mobile `Drawer` with persistent left sidebar for all pharmacy routes.

### Tables instead of cards
- Orders, quotations, OTC requests:
  - implement table rows for performance and scanning.
- Use status pills/badges for `pending/ready/dispatched/delivered/cancelled` and for notification status.

### Modals for actions
- Reject OTC reason -> modal dialog.
- Confirm dispatch -> modal dialog.
- Delete profile confirmation -> modal dialog.

### Large screen optimization
- Use max-width content container (e.g., 1200-1600px) and allow horizontal padding.
- Implement table pagination/sorting in Electron (not present in current Flutter code).

### Multi-column layouts
- OrderView: two-column layout (order/line items left, payment details right).
- Dashboard: statistics in a multi-column grid.

### Keyboard shortcuts (recommended)
Assumed for Electron implementation (no shortcuts in Flutter code):
- `Ctrl+K` focus list search
- `Esc` clears current search
- `Enter` opens selected row details

---

## 8. Edge Cases & Validations

### Invalid inputs
- Login:
  - username non-empty
  - password non-empty and length >= 6
- OTP entry:
  - OTP must be exactly 6 digits
- Submit quotation/OTC:
  - Each edited item amount must be > 0

### Network failure
- Flutter code uses try/catch and shows:
  - loading spinners during fetch
  - empty states if result arrays empty
  - sometimes error text; other times snackbars

### Empty states
- Implement per list screen:
  - “No orders found”, “No notifications”, “No OTC requests found”, etc.

### Loading states
- Use per screen spinners or skeleton tables.

---

## 9. Third-Party Integrations (Pharmacy)

### Push notifications
- OneSignal (via `onesignal_flutter`)
- Device registration:
  - `POST /api/register_device` with Authorization bearer token.

### PDF generation
- Pharmacy reports create a PDF file locally using `pdf` package and open it via `OpenFilex.open`.

### Maps
- “Get Location” in OTC/quotation flows opens Google Maps via `https://www.google.com/maps?q=<lat>,<lng>`.

---

## 10. Performance Considerations (Electron rebuild)

### Pagination & lazy loading
Current Flutter code:
- fetches full lists with no pagination parameters.

Electron rebuild should:
- implement pagination and sorting in UI for better performance
- optionally add caching to reduce API calls when switching between tabs/screens.

### API optimization
- Keep fetched data in memory per session.
- Refetch only on explicit refresh actions (pull-to-refresh or manual refresh).

---

