# QuikDawa Doctor Role Technical Specification (Flutter -> Electron)

This document is generated from the existing Flutter codebase and focuses **only** on the **Doctor User Role** (`usr_user_type == 'healthcare_provider'`). Other roles are intentionally ignored.

The pharmacy role specification lives in [`techspec.md`](techspec.md).

If any field/shape is marked **Assumed**, it is inferred from multiple code paths or from inconsistent server key naming.

---

## 1. Project Overview

### Purpose of the application
QuikDawa is a health/commerce workflow app that supports multiple user roles and order/quotation lifecycles. This document covers **only the “Doctor User Role”** (stored as `healthcare_provider` in the API) and the screens/APIs reachable/used by a doctor, including shared profile/account screens.

### Doctor user role responsibilities
A doctor user is responsible for:
- Viewing dashboard counters (patients, prescriptions, orders, notifications).
- **Writing digital prescriptions** (medicine lines, patient details, digital signature).
- **Scanning prescriptions** (camera/gallery → AI processing → pharmacy selection).
- Managing **prescription/quotation requests** submitted on behalf of patients:
  - Viewing request list and status.
  - Viewing pharmacy quotations received per request.
  - Accepting quotations (pay & place order) or cancelling/rejecting quotes.
- Managing **patient list** linked to the doctor.
- Viewing **patient details** and initiating scan-prescription flow for a patient.
- Browsing **pharmacy list** (for prescription routing / selection).
- Tracking **orders** (all orders and delivered orders).
- Viewing **order details** and delivery/pickup status timeline.
- Viewing **written prescription history** and prescription detail (items, signature, notes).
- Handling **doctor notifications** (marking notifications as read).
- Registering **new patients** in the doctor-assisted flow (`save_docuser`).
- Managing the doctor **profile/account** (edit info, change phone/email, delete account — shared screens).

### Key features used by doctor
- Role-based landing after login (`usr_user_type == 'healthcare_provider'`).
- Doctor sidebar navigation (`Navbar`) + route-driven screen transitions.
- Search/filter UI for prescriptions, quotations, orders, patients, pharmacies.
- Medicine autocomplete (suggestion API) when writing prescriptions.
- Patient lookup by phone when writing prescriptions.
- Digital signature capture on write-prescription screen.
- Push notification registration via OneSignal (device registration).
- Advertisement banner on dashboard (`getBanner`) with optional deep-link actions.

---

## 2. Authentication Flow (Doctor Role)

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
    "usr_user_type": "healthcare_provider",
    "usr_username": "dr_smith",
    "usr_email": "doctor@example.com",
    "usr_mobile_number": "+254712345678"
  },
  "verify_user": "1"
}
```

Error case:
- On non-200 status, the UI attempts `jsonDecode(response.body)` and reads `message`.
- If response body appears to be HTML (server error), it shows a generic server error message.

### Role-based navigation after login
When `verify_user == '1'`:
- `usr_user_type == 'healthcare_provider'` → `DoctordashboardScreen`
- Other types route to pharmacist, rider, or patient dashboard (out of scope).

When `verify_user != '1'` → `UserVerificationScreen`.

### Token handling (JWT/session/etc.)
- Token stored in `SharedPreferences` key: `sessionToken`
- User data stored in key: `userData` (JSON string of the `user` object from API)
- “Remember me” persists:
  - `saved_email`
  - `saved_password`
  - `remember_me` boolean

### Logout mechanism
Component: `lib/presentation/doctor/navbar/navbar_widget.dart` (`Navbar` drawer)

Logout behavior:
- Reads saved credentials: `saved_email`, `saved_password`, `remember_me`
- Calls `prefs.clear()`
- If `remember_me` was enabled, restores `saved_email`, `saved_password`, `remember_me=true`
- Routes to: `/sign_in_screen`

No server-side logout call exists in this code.

---

## Doctor-specific account verification OTP (if required)
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
  - on success and `usr_user_type == 'healthcare_provider'`, navigates to `DoctordashboardScreen`

Resend API:
- `POST https://quikdawa.com/QdawaAPIs/public/index.php/resend_otp`
- Request (form):
```json
{
  "usr_id": "123"
}
```

---

## 3. Screen-by-Screen Breakdown (VERY IMPORTANT)

For each screen used by the doctor role, this section includes: purpose, desktop UI layout conversion, user actions, API integration, business logic, and state management.

---

## Screen Name: DoctordashboardScreen

### 1. Purpose
- Shows doctor overview:
  - Quick actions: **Scan Prescription**, **Write Prescription**
  - Service tiles: Patient, Pharmacy, Messages (notifications)
  - Statistics: Patients, Prescriptions, New Patients, Orders
- Initializes push notification registration if `sessionToken` exists.
- Checks pending push notification navigation via `NotificationService.getPendingNotification()`.
- Optionally loads advertisement banner (`getBanner`).

File: `lib/presentation/doctor/dashboard_screen/dashboard.dart`

### 2. UI Layout (Desktop-Oriented)
- Top bar: title “Doctor Dashboard” + notification icon with badge.
- Left sidebar: persistent sidebar (desktop replacement for Flutter `Drawer`).
- Main content:
  - Two prominent action cards: Scan Prescription, Write Prescription
  - Services grid (3 columns): Patient, Pharmacy, Messages
  - Statistics section as responsive grid (2×2 cards)
- “My Orders” preview exists in code but is **commented out / hidden** for doctor dashboard.

Reusable components (recommended):
- `DoctorCountersSummaryCard`
- `DoctorQuickActionCard`
- `NotificationBadgeIcon`

### 3. User Actions
- Tap **Scan Prescription** → `ScanPrescriptionScreen`
- Tap **Write Prescription** → `WritePrescriptionScreen`
- Tap service tiles:
  - Patient → `/patientlist_screen`
  - Pharmacy → `/dupharmacy_list`
  - Messages → `/doctor_notification`
- Tap statistics cards:
  - Patients / New Patients → `/patientlist_screen`
  - Prescriptions → `/quotationrequest_dpatient_screen`
  - Orders → `/dorder_list_screen`
- Tap notification badge → `/doctor_notification`
- Banner tap (if loaded):
  - `click_action == 'prescription'` → saves `action_type` / `action_value` to prefs → `ScanPrescriptionScreen`
  - `click_action == 'url'` → opens external URL

### 4. API Integration
1. `POST .../doctorcounters`
   - Request body (form):
```json
{ "usr_id": "123" }
```
   - Response (example, **Assumed** from usage):
```json
{
  "quotations": 10,
  "orders": 5,
  "totalAmount": "KSH 50000",
  "delivered": 3,
  "newPat": 2,
  "notification": 4,
  "patientCount": 25
}
```
   - Fallback: if `quotations` is 0/null, app calls `get_quotation_drequest` and uses list length.

2. `POST .../getLastThreeOrders` (fetched but UI hidden)
   - Request: `{ "usr_id": "123" }`
   - Response: `{ "success": true, "orders": [...] }`

3. `POST .../getBanner` (optional)
   - No auth body in current code
   - Response includes `banner_base64`, `advertisement.click_action`, `advertisement.action_value`

4. `POST .../get_quotation_drequest` (prescription count fallback only)
   - Request: `{ "usr_id": "123" }`
   - Response: `{ "quotations": [...] }`

### 5. Business Logic
- Push notification navigation:
  - `prescription_received` / `prescription_approved` + `prescription_id` → `/writtenprescriptions` (route name in code; verify route map)
  - `order_placed` / `order_ready` + `order_id` → `/DorderListScreen`
- Location permission requested via `Geolocator` (`_getLocation`) but not blocking dashboard render.

### 6. State Management Logic
- Loads `counters` once (`fetchCounters`), optionally patches quotations count.
- `fetchOrders` runs on init but orders widget is not shown.
- Notification init + pending notification check on `initState`.

---

## Screen Name: DQuotationRequestScreen (Prescriptions List)

### 1. Purpose
- Lists doctor’s prescription/quotation **requests** (not pharmacy responses).
- Search by request ID.
- Tap row: if status is **not** `pending`, navigate to pharmacy quotation list for that request; if `pending`, show snackbar “Please Wait for Quotation!”.

File: `lib/presentation/doctor/quotation_list_screen/quotationrequest_patient_screen.dart`

Route: `/quotationrequest_dpatient_screen`

### 2. UI Layout (Desktop-Oriented)
- Sidebar + top bar “Prescriptions” with count badge.
- Search bar.
- Table/list columns:
  - Request ID, Patient Name, Created Date, Status

### 3. User Actions
- Search as user types (filters `qre_request_id`).
- Click row:
  - `qre_quotation_status != pending` → `/quotation_dlist_screen` with `{ Requestid }`
  - `pending` → snackbar only

### 4. API Integration
1. `POST .../get_quotation_drequest`
   - Request (form):
```json
{ "usr_id": "123" }
```
   - Response (example, **Assumed**):
```json
{
  "quotations": [
    {
      "qre_request_id": "REQ-12345",
      "qre_quotation_status": "received",
      "qre_created_dt": "2024-01-15 10:30:00",
      "patient_name": "John Doe",
      "pat_first_name": "John",
      "usr_first_name": "John"
    }
  ]
}
```
   Patient name resolution order in UI: `patient_name` → `pat_first_name` → `usr_first_name`.

2. Counters: `POST .../doctorcounters` with `{ "usr_id": "123" }`

### 5. Business Logic
- Local filtering: `qre_request_id` contains search query.

### 6. State Management Logic
- Loads quotations and counters on init.
- Filters locally without refetching.

---

## Screen Name: DQuotationListScreen (Pharmacy Quotations per Request)

### 1. Purpose
- Shows **pharmacy quotations** received for a single prescription request ID.
- Search across pharmacy name, license, phone, amount, status.
- Tap row: if status not `pending` or `otc_rejected`, open quotation detail view.

File: `lib/presentation/doctor/quotation_list_screen/quotation_list_screen.dart`

Route: `/quotation_dlist_screen` — args: `{ Requestid: string }`

### 2. UI Layout (Desktop-Oriented)
- Top bar: “Quotation Request ID: #…”
- Search bar.
- Table columns:
  - Request/Quote ID, Pharmacy Name, License/Address, Contact, Total Amount, Status, Reject Reason (if any)

### 3. User Actions
- Search locally.
- Tap row → `/dquotation_view_screen` with `{ rid: <quotation id> }` when status allows.

### 4. API Integration
1. `POST .../get_quotation_drequestid`
   - Request (form):
```json
{
  "usr_id": "123",
  "request_id": "REQ-12345"
}
```
   - Response:
```json
{
  "quotations": [
    {
      "id": "456",
      "pha_first_name": "Malibu Pharmacy",
      "pha_license_number": "LIC-001",
      "pha_alt_phone_number": "+254...",
      "quo_total_amount": 5000,
      "qre_quotation_status": "received",
      "qre_reject_reason": ""
    }
  ]
}
```

### 5. Business Logic
- Navigation blocked for `pending` and `otc_rejected` statuses.

### 6. State Management Logic
- Reads route args in `addPostFrameCallback`, then fetches once.

---

## Screen Name: DQuotationViewScreen

### 1. Purpose
- Read-only view of quotation line items, totals, pharmacy name, delivery charge.
- When status is `received`: **Pay & Place Order** or **Cancel Quote**.
- Cancel uses `rejectquotation` API with reason dialog.

File: `lib/presentation/doctor/quotation_view_screen/quotation_view_screen.dart`

Route: `/dquotation_view_screen` — args: `{ rid: string }`

### 2. UI Layout (Desktop-Oriented)
- Header with pharmacy name.
- Table: Item Name, Dosage, Qty, Price, Amount
- Summary: delivery charge, total, order type
- Action buttons (status-dependent):
  - `received` → Pay & Place Order, Cancel Quote
  - `cancelled` → “Order Cancelled” label
  - else → “Order Placed” label

### 3. User Actions
- **Pay & Place Order** (status `received`) → `PaymentOptionsScreen(qid)` (shared payment flow)
- **Cancel Quote** → modal for reason → `rejectquotation`
- Alternate path in code: `_placeOrder(qid)` → `place_order` → `/transaction_details_screen` (may be legacy vs payment screen)

### 4. API Integration
1. Fetch details:
   - `POST .../get_doctorquotation_details`
   - Request (form):
```json
{
  "usr_id": "123",
  "request_id": "456"
}
```
   - Response: `{ "quotations": [ { line items + totals + qre_quotation_status, qid, ... } ] }`

2. Reject/cancel quote:
   - `POST .../rejectquotation`
   - Request (form):
```json
{
  "qid": "789",
  "reason": "Patient chose another pharmacy"
}
```

3. Place order (direct, JSON body):
   - `POST .../place_order`
   - Headers: `Content-Type: application/json`
   - Body:
```json
{ "quo_id": "789" }
```
   - On success: saves `trid` in prefs → `/transaction_details_screen`

### 5. Business Logic
- Delivery vs pickup: inferred from `quo_delivery_charge` and `qre_order_type`.
- Total amount taken from first quotation row’s `quo_total_amount` in loop (**Assumed** single-pharmacy selection).

### 6. State Management Logic
- Loads once when `rid` arg is present.

---

## Screen Name: WritePrescriptionScreen

### 1. Purpose
- Compose a full digital prescription:
  - Doctor details (from API + session)
  - Patient details (search by phone or manual entry)
  - Multiple medicine rows (autocomplete, dosage, frequency MN/AF/EN/NT, duration, quantity, refill)
  - Digital signature pad
- Submit → `writeprescription` → save data to prefs → navigate to pharmacy selection (`DeliveryScreen` in `medicine_request.dart`).

File: `lib/presentation/doctor/write_prescription_screen/write_prescription_screen.dart`

### 2. UI Layout (Desktop-Oriented)
- Landscape-oriented form (code locks orientation during edit).
- Sections:
  - Doctor Details (name, email, phone, license)
  - Patient Details (phone search, name, gender, age)
  - Prescription number (auto-generated display)
  - Medicine table (editable rows + Add More)
  - Digital signature canvas
  - Submit button

### 3. User Actions
- Search patient by phone (min length triggers API).
- Add/remove medicine rows.
- Draw signature.
- Submit prescription → pharmacy selection flow.

### 4. API Integration
1. Doctor details:
   - `POST .../api/get_doc_detail` via `ApiService.getDoctorDetails`
   - Request (form): `{ "usr_id": "123" }`
   - Optional header: `Authorization: Bearer <sessionToken>`
   - Response shapes handled: direct map, `{ data: {} }`, `{ doctor: {} }`

2. Medicine search:
   - `POST https://quikdawa.com/suggestion.php`
   - Body: `{ "medicine_name": "para" }` (min 3 chars)
   - Response: array or `{ data: [] }` or `{ medicines: [] }`

3. Patient search:
   - `GET https://quikdawa.com/search_patient.php?search=<phone>`
   - Returns array of patients or single object or `{ message }` if not found

4. Patient list (optional helper):
   - `POST .../getPatientList` — `{ "doctor_id": "123" }` — **Assumed** used in supporting flows

5. Submit prescription:
   - `POST .../writeprescription`
   - Headers: `Content-Type: application/json`
   - Body (JSON):
```json
{
  "doctor_id": "123",
  "patient_id": "456",
  "prescription_number": "RX1232401151430",
  "patient_data": {
    "id": "456",
    "name": "John Doe",
    "phone": "+254...",
    "gender": "Male",
    "age": "35"
  },
  "prescription_items": [
    {
      "medicine_id": "",
      "medicine_name": "Paracetamol",
      "generic_name": "",
      "strength": "500mg",
      "unit": "tablet",
      "route": "oral",
      "dosage_per_time": "1",
      "frequency": { "MN": 1, "AF": 0, "EN": 1, "NT": 0 },
      "times_per_day": "2",
      "duration": "5",
      "quantity": "10",
      "refill": "0"
    }
  ],
  "signature": "<base64>",
  "notes": "",
  "created_at": "2026-05-15 10:30:00"
}
```

### 5. Business Logic
- Prescription number format: `RX` + 3-digit doctor ID + YY + MM + DD + HH + MM (e.g. `RX1232405151430`).
- Validates doctor ID and at least one medicine row before submit.
- On success saves to SharedPreferences:
  - `prescription` (JSON array for pharmacy flow)
  - `prescription_number`
  - `mtype` = `'2'` (written prescription, same as scan flow type 2)
  - `filepath` / `orignalfilepath` = empty strings
- Navigates to `DeliveryScreen` (medicine request / delivery type selection).

### 6. State Management Logic
- Loads doctor details on init.
- Per-row `TextEditingController`s for medicine fields.
- `isSubmitting` guards double submit.

---

## Screen Name: ScanPrescriptionScreen (Doctor flow)

### 1. Purpose
- Capture prescription image (camera/gallery).
- Send to AI processing endpoint.
- Continue to scanned prescription review and pharmacy selection (shared patient flow).

File: `lib/presentation/scan_prescription_screen/scan_prescription_screen.dart`

### 2. API Integration
- `POST https://quikdawa.com/AIP/processnew.php` (`AppConfig.aipProcessUrl`)
- Multipart/form upload of image file (**Assumed** from AIP integration pattern)

### 3. Business Logic
- Dashboard banner with `action_type=prescription` pre-fills `action_value` in prefs before opening this screen.
- `PatientViewScreen` sets `scantype` = `"userside"` and `patientid` before scan.

---

## Screen Name: WrittenPrescriptionListScreen

### 1. Purpose
- Lists all prescriptions written by the logged-in doctor.
- Search by prescription number, patient name, gender, date.
- Tap row → `PrescriptionDetailScreen`.

File: `lib/presentation/doctor/written_prescription_list/written_prescription_list.dart`

Route: `/written_prescription_list` (also referenced as `/writtenprescriptions` in notification handler — verify route registration)

### 2. UI Layout (Desktop-Oriented)
- Top bar “Written Prescriptions” + count badge.
- Search bar.
- Table: Prescription #, Patient Name, Gender, Created Date

### 3. User Actions
- Search locally.
- Tap row → detail screen with `prescriptionId`.

### 4. API Integration
1. `POST .../fetchDoctorPrescriptions`
   - Headers: `Content-Type: application/json`
   - Body (JSON):
```json
{ "user_id": "123" }
```
   - Response:
```json
{
  "success": true,
  "data": [
    {
      "pre_prescription_number": "RX1232405151430",
      "pre_patient_name": "John Doe",
      "pre_patient_gender": "Male",
      "pre_created_dt": "2024-01-15",
      "id": "99"
    }
  ]
}
```

### 6. State Management Logic
- Loads doctor ID from `userData` then fetches prescriptions.

---

## Screen Name: PrescriptionDetailScreen

### 1. Purpose
- View full written prescription: patient info, medicine lines, notes, base64 signature image.

File: `lib/presentation/doctor/written_prescription_list/prescription_detail_screen.dart`

### 4. API Integration
1. `POST .../writeprescriptionview`
   - Headers: `Content-Type: application/json`
   - Body (JSON):
```json
{
  "user_id": "123",
  "prescription_id": "99"
}
```
   - Response:
```json
{
  "success": true,
  "data": {
    "pre_prescription_number": "RX...",
    "pre_patient_name": "...",
    "pre_signature": "<base64>",
    "items": []
  }
}
```

---

## Screen Name: DUPatientListScreen

### 1. Purpose
- Lists patients associated with the doctor.
- Search/filter locally (**search UI present**; list variable named `pharmacies` in code).

File: `lib/presentation/doctor/patientlist_screen.dart`

Route: `/patientlist_screen`

### 4. API Integration
1. `POST .../get_patients`
   - Request (form):
```json
{ "usr_id": "123" }
```
   - Response:
```json
{
  "success": true,
  "data": [
    {
      "id": "456",
      "pat_first_name": "John",
      "usr_username": "johndoe",
      "usr_mobile_number": "+254..."
    }
  ]
}
```

### 3. User Actions
- Tap patient → `/patientview_screen` with patient id (**Assumed** from navigation patterns in file)

---

## Screen Name: PatientViewScreen

### 1. Purpose
- Display patient and linked doctor summary.
- **Scan Prescription** CTA for this patient.

File: `lib/presentation/doctor/petientview_screen.dart`

Route: `/patientview_screen` — requires `patientid` constructor arg

### 4. API Integration
1. `POST .../get_patientid`
   - Request (form):
```json
{ "patientid": "456" }
```
   - Response:
```json
{
  "patients": { "id": "456", ... },
  "doctor": { ... }
}
```

### 5. Business Logic
- Saves `patientid` and `scantype=user_side` to SharedPreferences.
- Scan button → `ScanPrescriptionScreen`.

---

## Screen Name: DoctoruserScreen (Register Patient)

### 1. Purpose
- Quick patient registration in doctor-assisted ordering flow before delivery/pharmacy selection.

File: `lib/presentation/doctor/doctoruser_screen.dart`

### 4. API Integration
1. `POST .../save_docuser`
   - Headers: `Content-Type: application/json`
   - Body (**Assumed** — field names map to mislabeled controllers in UI):
```json
{
  "patient_email": "<from addressController>",
  "contact_no": "<from cityController>",
  "patient_name": "<from postalCodeController>",
  "doctor_id": 123
}
```
   - On success: saves `patientid` → `DeliveryScreen`

---

## Screen Name: DUPharmacyListScreen

### 1. Purpose
- Browse pharmacies (optionally filtered by banner `action_value` as `phid`).
- Used in doctor prescription routing context.

File: `lib/presentation/doctor/dpharmacy_list.dart`

Route: `/dupharmacy_list`

### 4. API Integration
1. `POST .../get_pharmacy`
   - Request (form):
```json
{ "phid": "0" }
```
   - `phid` read from SharedPreferences `action_value` if set, else `"0"`
   - Response:
```json
{
  "success": true,
  "data": [
    {
      "org_organization_name": "Malibu Pharmacy Ltd",
      "pha_first_name": "Malibu",
      "pha_last_name": "Pharmacy",
      "pha_alt_phone_number": "+254...",
      "usr_mobile_number": "+254..."
    }
  ]
}
```

---

## Screen Name: DoctorOrderListScreen

### 1. Purpose
- Lists all orders placed under the doctor’s patients/requests.
- Search by order ID or status.

File: `lib/presentation/doctor/order_list_screen/order_list_screen.dart`

Route: `/dorder_list_screen`

### 4. API Integration
1. `POST .../get_doctor_order`
   - Request: `{ "usr_id": "123" }`
   - Response: `{ "orders": [ ... ] }`

2. Counters: `POST .../doctorcounters`

### 3. User Actions
- Tap order row → `/doctororderview` with `orderId` (**via** `order_list_one_item_widget.dart`)

---

## Screen Name: DDoctorOrderListScreen (Delivered Orders)

### 1. Purpose
- Lists **delivered** orders for the doctor.
- Includes notification icon in app bar.

File: `lib/presentation/doctor/order_list_screen/ddoctor_order_list_screen.dart`

Route: `/ddoctor_order_list_screen`

### 4. API Integration
1. `POST .../get_doctor_dorder`
   - Request: `{ "usr_id": "123" }`
   - Response: `{ "orders": [ ... ] }`

---

## Screen Name: DOrderTrackStatusScreen

### 1. Purpose
- Order detail + status timeline + line items + OTP display (read-only for doctor).
- Pharmacy name, totals, delivery charge, feedback/rating display.

File: `lib/presentation/doctor/order_track_status_screen/order_track_status_screen.dart`

Route: `/doctororderview` — requires `orderId`

### 4. API Integration
1. `POST .../order_view`
   - Request (form):
```json
{ "order_id": "123" }
```
   - Response (**Assumed**):
```json
{
  "order": {
    "ord_order_status": "dispatched",
    "ord_order_type": "delivery",
    "pha_first_name": "Malibu Pharmacy",
    "ord_total_amount": "5000",
    "ord_delivery_charge": "200",
    "feedback_status": "0",
    "pharmacy_rating": "4.5"
  },
  "items": [ { "item_name": "...", "item_qty": "10", ... } ],
  "del_delivery_otp": "123456"
}
```
   - Saves `myordertype`, `myorderid` to SharedPreferences.

---

## Screen Name: DoctorNotificationScreen

### 1. Purpose
- Fetch doctor notifications.
- Mark all notifications as read after fetch.

File: `lib/presentation/doctor/notification_screen/notification_screen.dart`

Route: `/doctor_notification`

### 2. UI Layout (Desktop-Oriented)
- Sidebar + top bar “Notifications”.
- List: ID, Remark, Created Date, Status badge

### 4. API Integration
1. Fetch:
   - `POST .../get_doctor_notification`
   - Request: `{ "usr_id": "123" }`
   - Response formats handled:
     - direct JSON array, or
     - `{ quotations: [] }`, `{ notifications: [] }`, `{ data: [] }`

2. Mark read:
   - `POST .../update_nstatus`
   - Request: `{ "usr_id": "123" }`

### 5. Business Logic
- List item fields: `id`, `noti_remark`, `noti_created_dt`, `noti_status`

---

## Screen Name: ProfileScreen (Doctor Account — Shared)

### 1. Purpose
- Display profile and account actions (shared with other roles).
- Edit profile, change phone/email/password, delete account.

File: `lib/presentation/profile_screen/profile_screen.dart`

Route: `/profile_screen`

### 4. API Integration
- Same shared endpoints as patient/pharmacy profile where applicable:
  - `POST .../get_user`
  - `POST .../update_user`
  - `POST .../update_mobile`
  - `POST .../update_email`
  - Delete endpoint varies by `usr_user_type` (**Assumed** `delete_doctor` or generic delete — verify in `profile_screen.dart` for healthcare_provider branch)

---

## Shared Post-Prescription Flow (Doctor uses patient commerce screens)

After write/scan prescription, the doctor is routed through shared screens:

| Step | Screen | Route / File | Notes |
|------|--------|--------------|-------|
| Delivery type | `DeliveryScreen` | `medicine_request.dart` | Pickup vs delivery |
| Delivery address | `DeliveryDetails` | `delivery_details.dart` | If delivery |
| Pharmacy pick | `PharmacyListScreen` | `pharmacy_list_screen.dart` | Uses prefs `prescription`, `mtype` |
| Payment | `PaymentOptionsScreen` | `payment_option.dart` | After quotation `received` |
| Transaction | `TransactionDetailsScreen` | `transaction_details_screen.dart` | After `place_order` |

These screens use patient-oriented APIs; document separately if building doctor-only Electron app — doctor role **does** navigate into them today.

---

## 4. API Master List (Doctor role only)

All endpoints below are used directly by doctor role screens or `ApiService` helpers called from doctor screens.

Base API URL (from `AppConfig`):
`https://quikdawa.com/QdawaAPIs/public/index.php`

Legacy/auxiliary URLs:
- Medicine suggestions: `https://quikdawa.com/suggestion.php`
- Patient search: `https://quikdawa.com/search_patient.php`
- AIP processing: `https://quikdawa.com/AIP/processnew.php`

### Auth
- `POST /login`
- `POST /verify_otp`
- `POST /resend_otp`

### Push Notifications (OneSignal)
- `POST /api/register_device`
  - called by `NotificationService.registerDevice`
  - uses `Authorization: Bearer <sessionToken>` and JSON body

### Doctor Dashboard
- `POST /doctorcounters`
- `POST /getLastThreeOrders` (loaded; UI hidden)
- `POST /getBanner`
- `POST /get_quotation_drequest` (counter fallback)

### Prescriptions (Write / View)
- `POST /writeprescription` (JSON)
- `POST /fetchDoctorPrescriptions` (JSON)
- `POST /writeprescriptionview` (JSON)
- `POST /api/get_doc_detail` (form + optional Bearer token)
- `POST /getPatientList` (**Assumed** helper)
- External: `POST /suggestion.php` (medicine search)
- External: `GET /search_patient.php` (patient search)

### Prescription / Quotation Requests
- `POST /get_quotation_drequest`
- `POST /get_quotation_drequestid`
- `POST /get_doctorquotation_details`
- `POST /rejectquotation`
- `POST /place_order` (JSON)

### Orders
- `POST /get_doctor_order`
- `POST /get_doctor_dorder`
- `POST /order_view`

### Patients
- `POST /get_patients`
- `POST /get_patientid`
- `POST /save_docuser` (JSON)

### Pharmacies
- `POST /get_pharmacy`

### Notifications
- `POST /get_doctor_notification`
- `POST /update_nstatus`

### Profile / Account (shared)
- `POST /get_user`
- `POST /update_user`
- `POST /update_mobile`
- `POST /update_email`
- Account delete endpoint (**verify role branch in ProfileScreen**)

---

## 5. Data Models (Request/Response JSON)

Representative payload shapes used by the doctor role.

### Auth
LoginRequest (form-urlencoded):
```json
{
  "usr_email": "string",
  "usr_password_hash": "string"
}
```

LoginResponse (success):
```json
{
  "token": "string",
  "user": {
    "id": 123,
    "usr_user_type": "healthcare_provider",
    "usr_username": "string",
    "usr_email": "string",
    "usr_mobile_number": "string"
  },
  "verify_user": "1"
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

### Doctor counters
```json
{ "usr_id": "string" }
```

### Quotation requests (doctor)
GetDoctorQuotationRequestsRequest:
```json
{ "usr_id": "string" }
```

GetDoctorQuotationByRequestIdRequest:
```json
{
  "usr_id": "string",
  "request_id": "string"
}
```

GetDoctorQuotationDetailsRequest:
```json
{
  "usr_id": "string",
  "request_id": "string"
}
```

RejectQuotationRequest:
```json
{
  "qid": "string",
  "reason": "string"
}
```

PlaceOrderRequest (JSON):
```json
{ "quo_id": "string" }
```

### Write prescription
WritePrescriptionRequest (JSON): see WritePrescriptionScreen section.

FetchDoctorPrescriptionsRequest (JSON):
```json
{ "user_id": "string" }
```

WritePrescriptionViewRequest (JSON):
```json
{
  "user_id": "string",
  "prescription_id": "string"
}
```

GetDoctorDetailsRequest:
```json
{ "usr_id": "string" }
```

### Orders
GetDoctorOrdersRequest:
```json
{ "usr_id": "string" }
```

GetDoctorDeliveredOrdersRequest:
```json
{ "usr_id": "string" }
```

OrderViewRequest:
```json
{ "order_id": "string" }
```

### Patients
GetPatientsRequest:
```json
{ "usr_id": "string" }
```

GetPatientByIdRequest:
```json
{ "patientid": "string" }
```

SaveDocUserRequest (JSON):
```json
{
  "patient_email": "string",
  "contact_no": "string",
  "patient_name": "string",
  "doctor_id": 123
}
```

### Pharmacies
GetPharmacyRequest:
```json
{ "phid": "string" }
```

### Notifications
GetDoctorNotificationRequest:
```json
{ "usr_id": "string" }
```

UpdateNotificationStatusRequest:
```json
{ "usr_id": "string" }
```

---

## 6. Navigation Flow (Text-based)

Doctor role flow:
- `SignInScreen`
  - if verified & `healthcare_provider` → `DoctordashboardScreen`
  - else → `UserVerificationScreen`
- `UserVerificationScreen`
  - OTP verify → `DoctordashboardScreen` (healthcare_provider)
- `DoctordashboardScreen`
  - Drawer (`Navbar`):
    - Dashboard → `/doctordashboard_screen`
    - Quotations → `/quotationrequest_dpatient_screen`
    - Orders → `/dorder_list_screen`
    - Prescriptions → `/written_prescription_list`
    - Profile → `/profile_screen`
  - Quick actions:
    - Scan → `ScanPrescriptionScreen`
    - Write → `WritePrescriptionScreen`
  - Services: Patient, Pharmacy, Messages
  - Stats shortcuts → patient list, prescriptions, orders
  - Notifications icon → `/doctor_notification`
- `DQuotationRequestScreen` (Prescriptions)
  - non-pending row → `DQuotationListScreen` (`/quotation_dlist_screen`)
  - pending → snackbar only
- `DQuotationListScreen`
  - eligible row → `DQuotationViewScreen` (`/dquotation_view_screen`)
- `DQuotationViewScreen`
  - received → `PaymentOptionsScreen` or `place_order` → `TransactionDetailsScreen`
  - cancel → `rejectquotation` → pop to list
- `WritePrescriptionScreen`
  - submit success → `DeliveryScreen` → … → `PharmacyListScreen` (shared flow)
- `WrittenPrescriptionListScreen`
  - row → `PrescriptionDetailScreen`
- `DUPatientListScreen`
  - row → `PatientViewScreen` → Scan Prescription
- `DoctorOrderListScreen` / `DDoctorOrderListScreen`
  - row → `DOrderTrackStatusScreen` (`/doctororderview`)
- Supporting:
  - `DUPharmacyListScreen`
  - `DoctorNotificationScreen`
  - `DoctoruserScreen` (patient register)
  - `ProfileScreen` + edit/change forms

---

## 7. Desktop UI/UX Guidelines (Windows/Electron)

### Sidebar navigation
- Replace mobile `Drawer` with persistent left sidebar for all doctor routes (same pattern as pharmacy spec).

### Tables instead of cards
- Prescription requests, pharmacy quotations, orders, written prescriptions, patients:
  - use data tables with sortable columns on desktop.

### Modals for actions
- Cancel quote reason → modal dialog.
- Patient phone search results → dropdown or modal picker.
- Delete profile confirmation → modal dialog.

### Large screen optimization
- Write Prescription: use full-width medicine grid; keep signature panel visible alongside form (two-column layout).
- Dashboard: statistics in 4-column grid on wide screens.

### Keyboard shortcuts (recommended)
Assumed for Electron (not in Flutter code):
- `Ctrl+K` focus list search
- `Esc` clears search / closes modal
- `Enter` opens selected row

---

## 8. Edge Cases & Validations

### Invalid inputs
- Login: email non-empty; password non-empty and length >= 6
- OTP: exactly 6 digits
- Write prescription: doctor ID required; at least one medicine row; signature recommended
- Cancel quote: reason must be non-empty
- DoctoruserScreen: all three fields required (labels are misnamed in UI but validation checks non-empty)

### Network failure
- try/catch with spinners, empty states, and SnackBars
- Written prescription list shows `errorMessage` string on failure

### Empty states
- “No quotations available”, “No Notifcation available”, “No doctors found”, etc. — replicate per screen

### Loading states
- Per-screen `CircularProgressIndicator` or skeleton tables

### Known code inconsistencies (for Electron rebuild)
- User type string is `healthcare_provider`, not `doctor`
- `DoctoruserScreen` maps wrong controller names to API fields (**verify with backend**)
- Notification deep link uses `/writtenprescriptions` but route constant is `/written_prescription_list`
- Dashboard orders preview is disabled in UI but API still called
- `lib/core/config/app_config.dart` currently sets `baseDomain` to `prod.quikdawa.com`; this document standardizes on `quikdawa.com` to match `techspec.md`

---

## 9. Third-Party Integrations (Doctor)

### Push notifications
- OneSignal (`onesignal_flutter`)
- Device registration: `POST /api/register_device` with Bearer token

### AI prescription scanning
- AIP endpoint: `https://quikdawa.com/AIP/processnew.php`
- Storage input URL helper: `AppConfig.aipInputUrl(filePath)`

### Medicine suggestions
- External PHP: `suggestion.php` on prod domain

### Patient search
- External PHP: `search_patient.php` on prod domain

### Maps / Location
- `Geolocator` used on dashboard (permission flow); pharmacy/patient screens may open maps in shared flows

### Digital signature
- Captured as image bytes → base64 in `writeprescription` payload
- Viewed from base64 in `PrescriptionDetailScreen`

---

## 10. Performance Considerations (Electron rebuild)

### Pagination & lazy loading
Current Flutter code fetches full lists with no pagination.

Electron rebuild should:
- paginate prescriptions, orders, patients, and pharmacy lists
- cache doctor counters and invalidate on explicit refresh

### API optimization
- Debounce medicine and patient search (3+ characters for medicines)
- Keep `doctorcounters` in session state; refresh on screen focus or pull-to-refresh

---

## 11. Route Reference (Doctor)

| Route constant | Path | Screen |
|----------------|------|--------|
| `doctordashboardScreen` | `/doctordashboard_screen` | `DoctordashboardScreen` |
| `dquotationRequestScreen` | `/quotationrequest_dpatient_screen` | `DQuotationRequestScreen` |
| `dquotationListScreen` | `/quotation_dlist_screen` | `DQuotationListScreen` |
| `dquotationViewScreen` | `/dquotation_view_screen` | `DQuotationViewScreen` |
| `DorderListScreen` | `/dorder_list_screen` | `DoctorOrderListScreen` |
| `ddoctororderlist` | `/ddoctor_order_list_screen` | `DDoctorOrderListScreen` |
| `dOrderTrackStatusScreen` | `/doctororderview` | `DOrderTrackStatusScreen` |
| `doctornotification` | `/doctor_notification` | `DoctorNotificationScreen` |
| `dpatientlist` | `/patientlist_screen` | `DUPatientListScreen` |
| `dpatientview` | `/patientview_screen` | `PatientViewScreen` |
| `dupharmacyListScreen` | `/dupharmacy_list` | `DUPharmacyListScreen` |
| `writtenprescriptions` | `/written_prescription_list` | `WrittenPrescriptionListScreen` |
| `profilescreen` | `/profile_screen` | `ProfileScreen` (shared) |
| `signInScreen` | `/sign_in_screen` | `SignInScreen` (shared) |
| `userVerificationScreen` | `/user_verification_screen` | `UserVerificationScreen` (shared) |
| `scanPrescriptionScreen` | `/scan_prescription_screen` | `ScanPrescriptionScreen` (shared) |

---

*Document generated from Flutter sources under `lib/presentation/doctor/` and related shared screens. Pair with [`techspec.md`](techspec.md) for pharmacy role and [`pharmacy_tech.md`](pharmacy_tech.md) for supplementary pharmacy API notes.*
