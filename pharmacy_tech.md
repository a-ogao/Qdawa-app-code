# Pharmacy Side Technical Documentation
## QuikDawa Flutter Application

**Document Version:** 1.0  
**Last Updated:** 2024  
**Base API URL:** `https://quikdawa.com/QdawaAPIs/public/index.php`

---

## Table of Contents
1. [Authentication & Login](#authentication--login)
2. [Dashboard](#dashboard)
3. [Quotation Management](#quotation-management)
4. [Order Management](#order-management)
5. [OTC (Over-The-Counter) Requests](#otc-over-the-counter-requests)
6. [Rider Management](#rider-management)
7. [Notifications](#notifications)
8. [Reports](#reports)
9. [Payment Management](#payment-management)
10. [OTP & Order Dispatch](#otp--order-dispatch)
11. [Navigation Structure](#navigation-structure)
12. [Layout & UI Components](#layout--ui-components)

---

## Authentication & Login

### Login Screen
**File:** `lib/presentation/sign_in_screen/sign_in_screen.dart`

#### Layout Structure
- **Header Section:**
  - QuikDawa logo (circular with shadow)
  - App name: "QuikDawa"
  - Tagline: "Your Health, Our Priority"
  - Gradient background (Blue with white)

- **Form Container:**
  - White card with rounded corners (24px radius)
  - Shadow effect for elevation
  - Welcome section: "Welcome Back!" title
  - Form fields with enhanced styling

- **Input Fields:**
  - Username/Email field with person icon
  - Password field with lock icon and visibility toggle
  - Remember me checkbox
  - Forgot password link

- **Buttons:**
  - Sign In button with gradient (Blue #4675C0)
  - Privacy Policy link
  - Sign Up link

#### API Request: Login

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/login`

**Request Headers:**
```
Content-Type: application/x-www-form-urlencoded
```

**Request Body:**
```javascript
{
  'usr_email': string,        // User email/username
  'usr_password_hash': string  // User password
}
```

**Response (200 OK):**
```json
{
  "token": "session_token_string",
  "user": {
    "id": number,
    "usr_user_type": "pharmacist",
    "usr_username": string,
    "usr_email": string,
    "usr_mobile_number": string
  },
  "verify_user": "1"  // "1" = verified, otherwise redirect to verification
}
```

**Navigation Flow:**
- If `verify_user == '1'` and `usr_user_type == 'pharmacist'` → Navigate to `PharmacyDashboardScreen`
- If `verify_user != '1'` → Navigate to `UserVerificationScreen`
- Error responses show SnackBar with error message

**Session Management:**
- Stores `sessionToken` in SharedPreferences
- Stores `userData` (JSON encoded) in SharedPreferences
- If "Remember Me" checked: saves email and password
- Token used for authenticated API requests

---

## Dashboard

### Pharmacy Dashboard Screen
**File:** `lib/presentation/pharmacy/pharmacy_dashboard_screen/pharmacy_dashboard_screen.dart`

#### Layout Structure

**AppBar:**
- Title: "Pharmacy Dashboard"
- Menu hamburger icon (opens drawer)
- Notification bell icon with badge count
- Blue background (#4675C0)

**Services Grid (3 columns):**
1. **Quotations** - Navigate to quotation requests
2. **Orders** - Navigate to order list
3. **Riders** - Navigate to rider list
4. **Reports** - Navigate to reports
5. **Messages** - Navigate to notifications
6. **Doctors** - Navigate to doctor list

**Statistics Section:**
- Grid layout (2 columns):
  - Prescriptions count (Blue icon)
  - OTC count (Red icon)
  - Total Sales amount (Green, KSH currency)
  - Customers count (Purple icon)
  - Pending orders (Orange icon)
  - Dispatched orders (Teal icon)

**Recent Orders Section:**
- Last 3 orders displayed
- Shows: Pharmacy name, status, amount, date
- "View All" link to complete order list
- Empty state with icon if no orders

#### API Request: Fetch Dashboard Counters

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/pharmacycounters`

**Request Body:**
```javascript
{
  'usr_id': string  // Pharmacy user ID from session
}
```

**Response (200 OK):**
```json
{
  "quotations": number,      // Prescription requests count
  "otc": number,             // OTC requests count
  "orders": number,          // Total orders count
  "totalAmount": "KSH 0",    // Total sales amount
  "delivered": number,       // Delivered orders count
  "pending": number,         // Pending orders count
  "notification": number,    // Unread notifications count
  "patient": number          // Total customers count
}
```

#### API Request: Fetch Last 3 Orders

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/getLastThreepOrders`

**Request Body:**
```javascript
{
  'usr_id': string  // Pharmacy user ID
}
```

**Response (200 OK):**
```json
{
  "success": boolean,
  "orders": [
    {
      "pha_first_name": string,
      "ord_order_status": string,  // "Delivered", "Pending", etc.
      "ord_total_amount": number,
      "ord_created_dt": string     // ISO date string
    }
  ]
}
```

---

## Quotation Management

### Quotation Requests Screen
**File:** `lib/presentation/pharmacy/quotation_requests_pharmacy_screen/quotation_requests_pharmacy_screen.dart`

#### Layout Structure

**AppBar:**
- Title: "Quotation Requests"
- Notification bell with badge
- Request count badge
- Search functionality

**Search Section:**
- White rounded container with search icon
- Real-time filtering by:
  - Request ID
  - Customer name
  - Amount
  - Address
  - Phone number
  - Date

**Quotation List:**
- Card-based list items
- Each item shows:
  - Request ID
  - Customer name
  - Address
  - Phone number
  - Date
  - Total amount
  - Status (Pending, Submitted, etc.)
- Tap item to view details

#### API Request: Fetch Quotation Requests

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/get_pharmacy_request`

**Request Body:**
```javascript
{
  'pharmacy_id': string  // Pharmacy user ID
}
```

**Response (200 OK):**
```json
{
  "quotations": [
    {
      "id": number,
      "qre_request_id": string,
      "usr_username": string,
      "pat_first_name": string,
      "adr_address_1": string,
      "usr_mobile_number": string,
      "quo_total_amount": number,
      "quo_created_dt": string,
      "qre_quotation_status": string,  // "pending", "submitted", etc.
      "qre_orignalfilepath": string,   // Prescription image path
      "prescription_id": string,       // Written prescription ID (if available)
      "qre_doctor_id": string           // Doctor ID (if available)
    }
  ]
}
```

### Submit Quotation Screen
**File:** `lib/presentation/pharmacy/quotation_requests_pharmacy_screen/submit_quotation_screen.dart`

#### Layout Structure

**Header:**
- Quotation Request ID
- Prescription view options:
  - Written prescription button (if prescription_id exists)
  - Scanned prescription image thumbnail

**Address Section:**
- Delivery address display (if delivery order)
- Pickup order indicator (if no address)
- "Get Location" button with Google Maps integration

**Quotation Items Table:**
- Columns:
  - Item Name (editable)
  - Dosage (dropdown: 0-4)
  - Quantity (editable)
  - Price per unit (editable)
  - Amount (auto-calculated: qty × price)
- Add new item button
- Delivery charge field (for delivery orders only)
- Total amount display

**Actions:**
- Download Lab Report button (if lab_filepath exists)
- Submit Quotation button (only if status is "pending")

#### API Request: Fetch Quotation Details

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/quotation_details`

**Request Body:**
```javascript
{
  'usr_id': string,      // Pharmacy user ID
  'request_id': string    // Quotation request ID
}
```

**Response (200 OK):**
```json
{
  "quotations": [
    {
      "qre_id": number,
      "qri_item_name": string,
      "qri_qty": number,
      "qri_item_dosage": string,
      "qre_order_type": string,       // "delivery" or "pickup"
      "qre_orignalfilepath": string,
      "lab_filepath": string,          // Optional lab report path
      "prescription_id": string,       // Optional written prescription ID
      "qre_doctor_id": string,         // Optional doctor ID
      "usr_id_created_by": number,
      "qre_quotation_status": string
    }
  ],
  "address": [
    {
      "adr_address_1": string,
      "adr_city": string,
      "adr_postal_code": string,
      "latitude": string,
      "longitude": string
    }
  ]
}
```

#### API Request: Submit Quotation

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/pharmacy_submit_quotation`

**Request Body:**
```javascript
{
  'pharmacy_id': string,
  'quotations': string  // JSON encoded array:
  /*
  [
    {
      "request_id": number,
      "item_name": string,
      "item_amount_perunit": string,
      "item_qty": string,
      "item_amount": string,
      "item_dose": string,
      "usr_id": number,
      "doctor_id": number,  // Optional
      "qre_order_type": string,
      "delivery_charge": string
    }
  ]
  */
}
```

**Response (200 OK):**
```json
{
  "success": boolean,
  "message": "Quotation Submitted Successfully and sent to User!"
}
```

#### API Request: View Written Prescription

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/writeprescriptionview`

**Request Body:**
```javascript
{
  'prescription_id': string,
  'doctor_id': string  // Optional
}
```

**Response:** Returns prescription details in formatted view

---

## Order Management

### Order List Screen
**File:** `lib/presentation/pharmacy/order_list_screen/order_list_screen.dart`

#### Layout Structure

**AppBar:**
- Title: "Order List"
- Notification bell with badge
- Order count badge
- Search functionality

**Order List Items:**
- Card-based layout
- Each order shows:
  - Order ID
  - Customer name
  - Order status
  - Order type (Delivery/Pickup)
  - Total amount
  - Address (for delivery orders)
  - Quotation request ID
- Tap to view order details

#### API Request: Fetch Orders

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/get_pharmacy_order`

**Request Body:**
```javascript
{
  'usr_id': string  // Pharmacy user ID
}
```

**Response (200 OK):**
```json
{
  "orders": [
    {
      "id": number,
      "ord_order_status": string,      // "pending", "ready", "delivered", etc.
      "ord_total_amount": number,
      "ord_order_type": string,        // "delivery" or "pickup"
      "usr_username": string,
      "adr_address_1": string,
      "qre_request_id": string
    }
  ]
}
```

### Order View Screen
**File:** `lib/presentation/pharmacy/order_view/order_view.dart`

#### Layout Structure

**Order Status Timeline:**
- Visual timeline showing order progression:
  - Order Placed
  - Processing
  - Ready for Dispatch
  - Dispatched
  - Delivered

**Order Details:**
- Order ID
- Customer information
- Items list with quantities and prices
- Total amount
- Delivery charge (if applicable)
- Payment mode
- Payment details (varies by payment type)

**Payment Details Display:**
- **M-Pesa:**
  - Transaction ID
  - Transaction date
  - Payment status
- **Insurance:**
  - Policy number
  - Insurance name
  - Date of birth
  - Created date
- **Coupon:**
  - Guardian name
  - Coupon GUID
  - Organization name
  - Beneficiary details

**Actions:**
- "Ready for Dispatch" button (updates status to "ready")
- "Choose Rider" option
- OTP verification for dispatch

#### API Request: View Order Details

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/order_view`

**Request Body:**
```javascript
{
  'order_id': string
}
```

**Response (200 OK):**
```json
{
  "order": {
    "ord_id": number,
    "ord_order_status": string,
    "ord_total_amount": number,
    "ord_delivery_charge": number,
    "ord_payment_mode": string,        // "mobile_payment", "insurance", "coupon"
    "pharmacy_rating": number
  },
  "items": [
    {
      "qit_item_name": string,
      "qit_qty": number,
      "qit_item_amount": number
    }
  ]
}
```

#### API Request: Update Order Status

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/update_ostatus`

**Request Body:**
```javascript
{
  'order_id': string,
  'ord_order_status': string  // "ready", "dispatched", "delivered", etc.
}
```

#### API Request: Get Payment Details

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/get_payment_details`

**Request Body:**
```javascript
{
  'order_id': string,
  'payment_mode': string  // "mobile_payment", "insurance", "coupon"
}
```

**Response (200 OK):**
```json
{
  "payment_data": {
    // For mobile_payment:
    "tra_transaction_id": string,
    "tra_created_dt": string,
    "payment_status": string,
    
    // For insurance:
    "ins_policy_number": string,
    "ins_name": string,
    "ins_dob": string,
    "ins_created_dt": string,
    
    // For coupon:
    "guardian_name": string,
    "coupon_guid": string,
    "guardian_phone": string,
    "organization_name": string,
    "beneficiary_name": string,
    "beneficiary_dob": string,
    "status": string
  }
}
```

### Pending Orders Screen
**File:** `lib/presentation/pharmacy/order_list_screen/pending_order_list_screen.dart`

Similar structure to Order List Screen but filters only pending orders.

**API:** Uses same `get_pharmacy_order` endpoint, filters by status client-side.

### Delivered Orders Screen
**File:** `lib/presentation/pharmacy/order_list_screen/delivered_order_list_screen.dart`

**API Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/get_pharmacy_dorder`

Similar structure, shows only delivered orders.

---

## OTC (Over-The-Counter) Requests

### OTC Requests Screen
**File:** `lib/presentation/pharmacy/quotation_requests_pharmacy_screen/pharmacy_usersymptoms_screen.dart`

#### Layout Structure

**AppBar:**
- Title: "OTC Requests"
- Notification bell
- Search functionality

**OTC Request List:**
- Card items showing:
  - Request ID
  - Customer information
  - Request date
  - Status
  - Total amount (if quotation submitted)

#### API Request: Fetch OTC Requests

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/get_pharmacy_symrequest`

**Request Body:**
```javascript
{
  'pharmacy_id': string
}
```

**Response (200 OK):**
```json
{
  "quotations": [
    {
      "qre_request_id": string,
      "requesttype": "Sym",  // Indicates symptom-based request
      "usr_username": string,
      "quo_total_amount": number,
      "quo_created_dt": string
    }
  ]
}
```

### Submit OTC Quotation Screen
**File:** `lib/presentation/pharmacy/quotation_requests_pharmacy_screen/submit_otc_screen.dart`

#### Layout Structure

**Symptom Details Section:**
- Expandable section showing:
  - Year of Birth
  - Safety Information
  - Symptoms description
  - Duration
  - Triggers
  - Severity
  - Medical History
  - Current Medications
  - Previous Remedies
  - Lifestyle Factors

**Quotation Items:**
- Similar to prescription quotation form
- Item name, quantity, price per unit, amount
- Delivery charge (if delivery order)
- Total amount

**Actions:**
- Submit OTC Quotation button
- Reject Request button (with reason dialog)

#### API Request: Submit OTC Quotation

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/pharmacy_otcsubmit_quotation`

**Request Body:**
```javascript
{
  'pharmacy_id': string,
  'quotations': string  // JSON encoded array (similar to prescription submission)
}
```

#### API Request: Reject OTC Request

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/reject_request`

**Request Body:**
```javascript
{
  'request_id': string,
  'reason': string  // Rejection reason
}
```

---

## Rider Management

### Rider List Screen
**File:** `lib/presentation/pharmacy/riderlist_screen.dart`

#### Layout Structure

**AppBar:**
- Title: "Riders List"
- Rider count badge
- Search functionality

**Rider List:**
- Card items showing:
  - Rider ID
  - Name
  - Phone number
  - Email
  - Total orders delivered
  - Rating (star display)
  - Status badge (Active/Inactive)
- Tap to select rider (for order assignment)

#### API Request: Fetch Riders

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/get_ridersnew`

**Request Body:** None (empty POST)

**Response (200 OK):**
```json
{
  "success": boolean,
  "data": [
    {
      "id": number,
      "usr_username": string,
      "usr_first_name": string,
      "usr_email": string,
      "usr_mobile_number": string,
      "total_orders": number,
      "delivery_rating": number,
      "totaluser": number  // For rating calculation
    }
  ]
}
```

### Choose Rider Screen
**File:** `lib/presentation/pharmacy/rider_choose_screen.dart`

Used for assigning a rider to an order. Similar to rider list but with selection confirmation.

**API Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/get_riders`

---

## Notifications

### Notification Screen
**File:** `lib/presentation/pharmacy/notification_screen/notification_screen.dart`

#### Layout Structure

**AppBar:**
- Title: "Notifications"
- Notification count badge

**Notification List:**
- Card items showing:
  - Notification icon (pharmacy icon)
  - Remark/Message
  - Timestamp
  - Status badge (New/Read)
- Notifications automatically marked as read when screen opens

#### API Request: Fetch Notifications

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/get_pharmacy_notification`

**Request Body:**
```javascript
{
  'usr_id': string
}
```

**Response (200 OK):**
```json
{
  "quotations": [  // Note: API uses "quotations" key for notifications
    {
      "noti_remark": string,
      "noti_created_dt": string,
      "noti_status": string  // "read" or "unread"
    }
  ]
}
```

#### API Request: Update Notification Status

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/update_nstatus`

**Request Body:**
```javascript
{
  'usr_id': string
}
```

Marks all notifications as read.

---

## Reports

### Pharmacy Reports Screen
**File:** `lib/presentation/pharmacy/pharmcy_reports.dart`

#### Layout Structure

**Date Range Selection:**
- From Date picker
- To Date picker
- Generate Report button

**Report Generation:**
- Fetches prescriptions for date range
- Generates PDF report with:
  - Report title
  - Date range
  - Table with columns:
    - Medicine name
    - Date
    - Quantity
- Opens PDF in external viewer

#### API Request: Fetch Prescriptions for Report

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/fetchpharmacy_Prescriptions`

**Request Body:**
```javascript
{
  "from_date": string,  // Format: "yyyy-MM-dd"
  "to_date": string,    // Format: "yyyy-MM-dd"
  "usr_id": string
}
```

**Response (200 OK):**
```json
{
  "success": boolean,
  "data": [
    {
      "qit_item_name": string,
      "qit_created_dt": string,
      "qit_qty": number
    }
  ]
}
```

**PDF Generation:**
- Uses `pdf` package
- Table format with borders
- Saved to device documents directory
- Opens with `open_filex` package

---

## Payment Management

### Payment List Screen
**File:** `lib/presentation/pharmacy/payment_pharmacy_screen.dart`

#### Layout Structure

**AppBar:**
- Title: "Payment List"
- Back button

**Search Section:**
- Search by Patient Name or Order ID

**Payment List:**
- Displays payment transactions
- Shows payment details based on mode

#### API Request: Fetch Payments

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/get_payments`

**Request Body:**
```javascript
{
  'usr_id': string
}
```

**Response (200 OK):**
```json
{
  "success": boolean,
  "data": [
    {
      // Payment transaction details
      // Structure varies by payment mode
    }
  ]
}
```

---

## OTP & Order Dispatch

### OTP Screen
**File:** `lib/presentation/pharmacy/otp_screen/otp_screen.dart`

#### Functionality

**OTP Verification for Order Dispatch:**
- Input OTP sent to rider
- Verify OTP to confirm dispatch
- Resend OTP option

#### API Request: Verify OTP Status

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/verify_statusotp`

**Request Body:**
```javascript
{
  'order_id': string,
  'otp': string
}
```

#### API Request: Resend OTP

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/orderresend_otp`

**Request Body:**
```javascript
{
  'order_id': string
}
```

#### API Request: Update Delivery Status

**Endpoint:** `POST https://quikdawa.com/QdawaAPIs/public/index.php/delivery_dstatus`

**Request Body:**
```javascript
{
  'order_id': string,
  'status': string
}
```

---

## Navigation Structure

### Main Navigation (Drawer)
**File:** `lib/presentation/pharmacy/nav_bar/navbar_widget.dart`

**Menu Items:**
1. Dashboard → `/pharmcy_dashboard_screen`
2. Quotations → `/quotation_requests_pharmacy_screen`
3. OTC Requests → `/pharmacy_usersymptoms_screen`
4. Orders → `/Pharmacy_order_list_screen`
5. Profile → `/profile_screen`
6. Logout → Clears session, navigates to `/sign_in_screen`

### Route Configuration
**File:** `lib/routes/app_routes.dart`

**Pharmacy Routes:**
- `/pharmcy_dashboard_screen` → `PharmacyDashboardScreen`
- `/quotation_requests_pharmacy_screen` → `QuotationRequestsPharmacyScreen`
- `/Pharmacy_order_list_screen` → `PharmacyOrderListScreen`
- `/Pending_order_list_screen` → `PendingOrderListScreen`
- `/dPharmacy_order_list_screen` → `dPharmacyOrderListScreen` (Delivered)
- `/pharmacy_notification` → `PharmacyNotificationScreen`
- `/pharmacy_reports` → `PReportsPage`
- `/payment_pharmacy_screen` → `PaymentListScreen`
- `/riderlist_screen` → `vRiderListScreen`
- `/pharmacy_usersymptoms_screen` → `PharmacySymptomsScreen`

---

## Layout & UI Components

### Color Scheme
- **Primary Blue:** `#4675C0`
- **Background:** `Colors.grey[50]`
- **Card Background:** `Colors.white`
- **Error Red:** `Colors.red`
- **Success Green:** `Colors.green`

### Common UI Patterns

**1. AppBar Pattern:**
- Blue background (#4675C0)
- White title text
- Menu hamburger icon
- Notification bell with badge (top-right)

**2. Card Layout:**
- White background
- Rounded corners (16px)
- Shadow elevation
- Padding: 16-20px

**3. Search Section:**
- White container with rounded corners
- Search icon on left
- Clear button appears when text entered
- Real-time filtering

**4. Empty States:**
- Centered icon (48px)
- Title text
- Subtitle description
- Appropriate icon for context

**5. Loading States:**
- Circular progress indicator
- Loading message
- Centered layout

**6. Statistics Cards:**
- Grid layout (2 columns)
- Icon with colored background
- Title text
- Value text (bold)
- Tap to navigate to detail screen

### Form Components

**Text Fields:**
- Rounded input borders (16px radius)
- Icon prefix
- Grey background when filled
- Blue border on focus

**Buttons:**
- Gradient background (primary blue)
- White text
- Rounded corners (16px)
- Elevated with shadow

**Dropdowns:**
- Rounded borders
- Icon indicators
- Blue accent color

---

## Error Handling

### API Error Patterns

1. **Network Errors:**
   - Displays SnackBar with error message
   - Red background for errors
   - Green background for success

2. **Validation Errors:**
   - Form field validation messages
   - Required field indicators
   - Format validation (email, phone, etc.)

3. **Empty Responses:**
   - Shows empty state UI
   - Helpful message to user
   - No error thrown

### Session Management

**Token Storage:**
- Stored in SharedPreferences as `sessionToken`
- User data stored as `userData` (JSON encoded)
- Session checked on app launch (SplashScreen)

**Logout:**
- Clears all SharedPreferences
- Restores "Remember Me" credentials if applicable
- Navigates to sign-in screen

---

## Data Flow Summary

1. **Login** → Get token & user data → Store in SharedPreferences → Navigate to Dashboard
2. **Dashboard** → Fetch counters & recent orders → Display statistics → Navigate to features
3. **Quotations** → Fetch requests → Filter/Search → View details → Submit quotation
4. **Orders** → Fetch orders → Filter by status → View details → Update status → Assign rider
5. **OTC** → Fetch symptom requests → View details → Submit/reject quotation
6. **Notifications** → Fetch notifications → Auto-mark as read → Display list
7. **Reports** → Select date range → Fetch data → Generate PDF → Open file

---

## API Endpoints Summary

| Feature | Method | Endpoint | Purpose |
|---------|--------|----------|---------|
| Login | POST | `/login` | Authenticate pharmacy user |
| Counters | POST | `/pharmacycounters` | Get dashboard statistics |
| Recent Orders | POST | `/getLastThreepOrders` | Get last 3 orders |
| Quotation Requests | POST | `/get_pharmacy_request` | Get prescription requests |
| Quotation Details | POST | `/quotation_details` | Get quotation items |
| Submit Quotation | POST | `/pharmacy_submit_quotation` | Submit prescription quotation |
| View Prescription | POST | `/writeprescriptionview` | View written prescription |
| Orders | POST | `/get_pharmacy_order` | Get all orders |
| Delivered Orders | POST | `/get_pharmacy_dorder` | Get delivered orders |
| Order View | POST | `/order_view` | Get order details |
| Update Order Status | POST | `/update_ostatus` | Update order status |
| Payment Details | POST | `/get_payment_details` | Get payment information |
| OTC Requests | POST | `/get_pharmacy_symrequest` | Get OTC requests |
| Submit OTC | POST | `/pharmacy_otcsubmit_quotation` | Submit OTC quotation |
| Reject Request | POST | `/reject_request` | Reject quotation request |
| Rider List | POST | `/get_ridersnew` | Get available riders |
| Notifications | POST | `/get_pharmacy_notification` | Get notifications |
| Update Notification | POST | `/update_nstatus` | Mark notifications as read |
| Reports | POST | `/fetchpharmacy_Prescriptions` | Get prescription data for reports |
| Payments | POST | `/get_payments` | Get payment transactions |
| Verify OTP | POST | `/verify_statusotp` | Verify OTP for dispatch |
| Resend OTP | POST | `/orderresend_otp` | Resend OTP to rider |
| Delivery Status | POST | `/delivery_dstatus` | Update delivery status |

---

## File Structure

```
lib/presentation/pharmacy/
├── nav_bar/
│   └── navbar_widget.dart                    # Navigation drawer
├── notification_screen/
│   ├── notification_screen.dart              # Notification list
│   └── widgets/
│       └── notification_item_widget.dart
├── order_list_screen/
│   ├── order_list_screen.dart                # All orders
│   ├── pending_order_list_screen.dart        # Pending orders
│   ├── delivered_order_list_screen.dart      # Delivered orders
│   └── widgets/
│       └── order_list_one_item_widget.dart
├── order_view/
│   ├── order_view.dart                       # Order details view
│   └── widgets/
│       ├── columnorderplac_item_widget.dart
│       ├── columntime_item_widget.dart
│       └── columnview_item_widget.dart
├── otp_screen/
│   └── otp_screen.dart                       # OTP verification
├── payment_pharmacy_screen.dart              # Payment list
├── pharmacy_dashboard_screen/
│   ├── pharmacy_dashboard_screen.dart        # Main dashboard
│   └── widgets/
│       ├── gridquotation_item_widget.dart
│       └── quotationsgrid_item_widget.dart
├── pharmcy_reports.dart                      # Reports generation
├── quotation_requests_pharmacy_screen/
│   ├── quotation_requests_pharmacy_screen.dart  # Quotation list
│   ├── submit_quotation_screen.dart          # Submit prescription quote
│   ├── submit_otc_screen.dart                # Submit OTC quote
│   ├── pharmacy_usersymptoms_screen.dart      # OTC requests list
│   ├── pharmacy_prescription_view_screen.dart # View written prescription
│   ├── view_quotation_screen.dart             # View quotation
│   └── widgets/
│       ├── listravindersin_item_widget.dart
│       └── otc_list_widget.dart
├── rider_choose_screen.dart                  # Select rider
├── riderlist_screen.dart                     # Rider list
└── success_two_screen/
    └── success_two_screen.dart               # Success confirmation
```

---

## Technical Notes

### State Management
- Uses Flutter StatefulWidget pattern
- SharedPreferences for session and user data storage
- State updates via `setState()` method

### HTTP Client
- Uses `http` package for API calls
- Content-Type: `application/x-www-form-urlencoded` (mostly)
- Error handling via try-catch blocks
- Response parsing using `dart:convert`

### Image Handling
- Network images for prescription scans
- URL format: `https://quikdawa.com/QdawaAPIs/public/storage/{filePath}`
- Image preview in dialogs and headers

### Geolocation
- Uses `geolocator` package
- Google Maps integration via `url_launcher`
- Location coordinates from address data

### PDF Generation
- Uses `pdf` package
- Table-based report layout
- File saving via `path_provider`
- File opening via `open_filex`

---

## Future Enhancements

Potential improvements for pharmacy functionality:
1. Real-time order status updates
2. Push notifications for new quotations
3. Advanced filtering and sorting
4. Bulk quotation submission
5. Rider assignment automation
6. Analytics dashboard with charts
7. Export reports in multiple formats
8. Offline mode support
9. Multi-language support
10. Dark mode support

---

**End of Documentation**






