# QuikDawa API Response Documentation

## Base URL
```
https://quikdawa.com/QdawaAPIs/public/index.php
```

---

## 🔐 Authentication APIs

### Login
**Endpoint:** `POST /login`

**Request Body:**
```json
{
  "usr_email": "user@example.com",
  "usr_password_hash": "password123"
}
```

**Response (200 OK):**
```json
{
  "token": "session_token_string",
  "user": {
    "id": 123,
    "usr_user_type": "pharmacist" | "patient" | "delivery_person" | "doctor",
    "usr_username": "john_doe",
    "usr_email": "user@example.com",
    "usr_mobile_number": "+254712345678"
  },
  "verify_user": "1"  // "1" = verified, otherwise needs verification
}
```

### Forgot Password (OTP Flow)
**Note:** For complete documentation of the Forgot Password OTP flow APIs, see [FORGOT_PASSWORD_OTP_API.md](./FORGOT_PASSWORD_OTP_API.md)

**Endpoints:**
- `POST /forgot_password_send_otp` - Send OTP to user's registered mobile number
- `POST /forgot_password_verify_otp` - Verify OTP code and get verification token
- `POST /forgot_password_change` - Change password using verification token

### Registration (OTP Flow)
**Note:** For complete documentation of the Registration OTP flow APIs, see [REGISTRATION_OTP_API.md](./REGISTRATION_OTP_API.md)

**Endpoints:**
- `POST /insert_user` - Register new user and automatically send OTP
- `POST /verify_otp` - Verify OTP code to complete registration
- `POST /resend_otp` - Resend OTP to user's registered mobile number

---

## 📊 Dashboard & Counter APIs

### User Counters (Patient/Doctor)
**Endpoint:** `POST /usercounters`

**Request Body:**
```json
{
  "usr_id": "123"
}
```

**Response (200 OK):**
```json
{
  "quotations": 5,
  "orders": 12,
  "totalAmount": "KES 15000",
  "delivered": 8,
  "notification": 3
}
```

### Pharmacy Counters
**Endpoint:** `POST /pharmacycounters`

**Request Body:**
```json
{
  "usr_id": "123"
}
```

**Response (200 OK):**
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

### Delivery Counters (Rider)
**Endpoint:** `POST /deliverycounters`

**Request Body:**
```json
{
  "usr_id": "123"
}
```

**Response (200 OK):**
```json
{
  "quotations": 0,
  "orders": 15,
  "totalAmount": "KSH 0",
  "delivered": 10,
  "notification": 2
}
```

### Get Last 3 Orders (Pharmacy)
**Endpoint:** `POST /getLastThreepOrders`

**Request Body:**
```json
{
  "usr_id": "123"
}
```

**Response (200 OK):**
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

---

## 📦 Order APIs

### Get Delivery Orders (Rider - Delivered Orders)
**Endpoint:** `POST /get_delivery_order`

**Request Body:**
```json
{
  "usr_id": "123"
}
```

**Response (200 OK):**
```json
{
  "orders": [
    {
      "id": 456,
      "qre_request_id": "REQ-12345",
      "ord_delivery_charge": "500",
      "del_delivered_time": "2024-01-15 14:30:00",
      "pha_first_name": "Malibu Pharmacy Limited",  // Pharmacy name (where order was picked)
      "pharmacy_name": "Malibu Pharmacy Limited",    // Alternative field
      "organization_name": "Malibu Pharmacy",       // Alternative field
      "pha_name": "Malibu",                          // Alternative field
      "usr_username": "customer_name",              // Customer name
      "ord_order_status": "delivered",
      "ord_total_amount": 5000,
      "adr_address_1": "123 Main Street"
    }
  ]
}
```

### Get Delivery View (Rider - Order Details)
**Endpoint:** `POST /get_deliveryview`

**Request Body:**
```json
{
  "order_id": "456"
}
```

**Response (200 OK):**
```json
{
  "orders": [
    {
      "del_delivery_otp": "1234",
      "del_delivery_status": "pickedup" | "pending" | "delivered",
      "del_pickup_time": "2024-01-15 12:00:00",
      "del_delivered_time": "2024-01-15 14:30:00",
      "pha_first_name": "Malibu Pharmacy Limited",
      "pha_address": "123 Pharmacy Street, Nairobi",
      "usr_username": "John Doe",
      "adr_address_1": "456 Customer Street, Nairobi",
      "ord_order_status": "delivered",
      "delivery_rating": 4.5
    }
  ]
}
```

### Get Pharmacy Orders
**Endpoint:** `POST /get_pharmacy_order`

**Request Body:**
```json
{
  "usr_id": "123"
}
```

**Response (200 OK):**
```json
{
  "orders": [
    {
      "id": 456,
      "ord_order_status": "pending" | "ready" | "dispatched" | "delivered",
      "ord_total_amount": 5000,
      "ord_order_type": "delivery" | "pickup",
      "usr_username": "customer_name",
      "adr_address_1": "123 Main Street",
      "qre_request_id": "REQ-12345"
    }
  ]
}
```

### Get Pharmacy Delivered Orders
**Endpoint:** `POST /get_pharmacy_dorder`

**Request Body:**
```json
{
  "usr_id": "123"
}
```

**Response (200 OK):**
```json
{
  "orders": [
    {
      "id": 456,
      "ord_order_status": "delivered",
      "ord_total_amount": 5000,
      "ord_order_type": "delivery",
      "usr_username": "customer_name",
      "adr_address_1": "123 Main Street",
      "qre_request_id": "REQ-12345"
    }
  ]
}
```

### Order View (Order Details)
**Endpoint:** `POST /order_view`

**Request Body:**
```json
{
  "order_id": "456"
}
```

**Response (200 OK):**
```json
{
  "order": {
    "ord_id": 456,
    "ord_order_status": "delivered",
    "ord_total_amount": 5000,
    "ord_delivery_charge": 500,
    "ord_payment_mode": "mobile_payment" | "insurance" | "coupon",
    "ord_order_type": "delivery" | "pickup",
    "pharmacy_rating": 4.5,
    "pha_first_name": "Malibu Pharmacy Limited",
    "qre_request_id": "REQ-12345",
    "feedback_status": "1" | "0"
  },
  "items": [
    {
      "qit_item_name": "Paracetamol 500mg",
      "qit_qty": 10,
      "qit_item_amount": 500
    }
  ],
  "del_delivery_otp": "1234"
}
```

### Patient Prescriptions (Orders List)
**Endpoint:** `POST /api/patient_prescriptions`

**Request Body:**
```json
{
  "usr_id": 123,
  "per_page": 100
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "order_id": 456,
      "id": 456,
      "request_id": "REQ-12345",
      "quotation_request_id": "QRE-12345",
      "qre_request_id": "QRE-12345",
      "organization_name": "Malibu Pharmacy Limited",
      "pharmacy_name": "Malibu Pharmacy Limited",
      "amount": 5000,
      "amount_label": "KES 5000",
      "currency": "KES",
      "order_date": "2024-01-15",
      "order_date_iso": "2024-01-15T10:30:00Z",
      "status": "pending" | "delivered",
      "status_label": "Pending" | "Delivered"
    }
  ]
}
```

---

## 💰 Payment APIs

### Get Payment Details
**Endpoint:** `POST /get_payment_details`

**Request Body:**
```json
{
  "order_id": "456",
  "payment_mode": "mobile_payment" | "insurance" | "coupon"
}
```

**Response (200 OK):**

**For Mobile Payment:**
```json
{
  "payment_data": {
    "tra_transaction_id": "MPESA123456",
    "tra_created_dt": "2024-01-15 10:30:00",
    "payment_status": "completed"
  }
}
```

**For Insurance:**
```json
{
  "payment_data": {
    "ins_policy_number": "POL-123456",
    "ins_name": "NHIF",
    "ins_dob": "1990-01-01",
    "ins_created_dt": "2024-01-15 10:30:00"
  }
}
```

**For Coupon:**
```json
{
  "payment_data": {
    "guardian_name": "John Doe",
    "coupon_guid": "COUPON-123456",
    "guardian_phone": "+254712345678",
    "organization_name": "Health Organization",
    "beneficiary_name": "Jane Doe",
    "beneficiary_dob": "2000-01-01",
    "status": "active"
  }
}
```

---

## 📋 Quotation APIs

### Get Pharmacy Quotation Requests
**Endpoint:** `POST /get_pharmacy_request`

**Request Body:**
```json
{
  "pharmacy_id": "123"
}
```

**Response (200 OK):**
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
      "qre_quotation_status": "pending" | "submitted",
      "qre_orignalfilepath": "prescriptions/prescription_123.jpg",
      "prescription_id": "PRES-123",
      "qre_doctor_id": "DOC-456"
    }
  ]
}
```

### Quotation Details
**Endpoint:** `POST /quotation_details`

**Request Body:**
```json
{
  "usr_id": "123",
  "request_id": "REQ-12345"
}
```

**Response (200 OK):**
```json
{
  "quotations": [
    {
      "qre_id": 789,
      "qri_item_name": "Paracetamol 500mg",
      "qri_qty": 10,
      "qri_item_dosage": "2",
      "qre_order_type": "delivery" | "pickup",
      "qre_orignalfilepath": "prescriptions/prescription_123.jpg",
      "lab_filepath": "lab_reports/lab_123.pdf",
      "prescription_id": "PRES-123",
      "qre_doctor_id": "DOC-456",
      "usr_id_created_by": 123,
      "qre_quotation_status": "pending"
    }
  ],
  "address": [
    {
      "adr_address_1": "123 Main Street",
      "adr_city": "Nairobi",
      "adr_postal_code": "00100",
      "latitude": "-1.2921",
      "longitude": "36.8219"
    }
  ]
}
```

### Submit Quotation
**Endpoint:** `POST /pharmacy_submit_quotation`

**Request Body:**
```json
{
  "pharmacy_id": "123",
  "quotations": "[{\"request_id\":789,\"item_name\":\"Paracetamol\",\"item_amount_perunit\":\"50\",\"item_qty\":\"10\",\"item_amount\":\"500\",\"item_dose\":\"2\",\"usr_id\":456,\"doctor_id\":789,\"qre_order_type\":\"delivery\",\"delivery_charge\":\"200\"}]"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Quotation Submitted Successfully and sent to User!"
}
```

---

## 🏥 OTC (Over-The-Counter) APIs

### Get Pharmacy OTC Requests
**Endpoint:** `POST /get_pharmacy_symrequest`

**Request Body:**
```json
{
  "pharmacy_id": "123"
}
```

**Response (200 OK):**
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

---

## 🚴 Rider APIs

### Get Riders List
**Endpoint:** `POST /get_ridersnew`

**Request Body:** (Empty POST)

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "id": 123,
      "usr_username": "rider_name",
      "usr_first_name": "John",
      "usr_email": "rider@example.com",
      "usr_mobile_number": "+254712345678",
      "total_orders": 50,
      "delivery_rating": 4.5,
      "totaluser": 40
    }
  ]
}
```

---

## 🔔 Notification APIs

### Get Pharmacy Notifications
**Endpoint:** `POST /get_pharmacy_notification`

**Request Body:**
```json
{
  "usr_id": "123"
}
```

**Response (200 OK):**
```json
{
  "quotations": [
    {
      "noti_remark": "New quotation request received",
      "noti_created_dt": "2024-01-15 10:30:00",
      "noti_status": "read" | "unread"
    }
  ]
}
```

### Update Notification Status
**Endpoint:** `POST /update_nstatus`

**Request Body:**
```json
{
  "usr_id": "123"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Notifications marked as read"
}
```

---

## 📊 Report APIs

### Fetch Pharmacy Prescriptions (for Reports)
**Endpoint:** `POST /fetchpharmacy_Prescriptions`

**Request Body:**
```json
{
  "from_date": "2024-01-01",
  "to_date": "2024-12-31",
  "usr_id": "123"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "data": [
    {
      "qit_item_name": "Paracetamol 500mg",
      "qit_created_dt": "2024-01-15 10:30:00",
      "qit_qty": 10
    }
  ]
}
```

---

## 🔐 OTP & Status APIs

### Verify OTP Status
**Endpoint:** `POST /verify_statusotp`

**Request Body:**
```json
{
  "order_id": "456",
  "otp": "1234"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "OTP verified successfully"
}
```

### Resend OTP
**Endpoint:** `POST /orderresend_otp`

**Request Body:**
```json
{
  "order_id": "456"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "OTP resent successfully"
}
```

### Update Order Status
**Endpoint:** `POST /update_ostatus`

**Request Body:**
```json
{
  "order_id": "456",
  "ord_order_status": "ready" | "dispatched" | "delivered"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Order status updated"
}
```

### Update Delivery Status
**Endpoint:** `POST /delivery_dstatus`

**Request Body:**
```json
{
  "order_id": "456",
  "status": "pickedup" | "delivered"
}
```

**Response (200 OK):**
```json
{
  "success": true,
  "message": "Delivery status updated"
}
```

---

## 📝 Prescription APIs

### View Written Prescription
**Endpoint:** `POST /writeprescriptionview`

**Request Body:**
```json
{
  "prescription_id": "PRES-123",
  "doctor_id": "DOC-456"
}
```

**Response (200 OK):**
Returns formatted prescription view (HTML or structured data)

---

## 🎯 Banner API

### Get Banner
**Endpoint:** `POST /getBanner`

**Request Body:** (Empty POST)

**Response (200 OK):**
```json
{
  "banner": [
    {
      "banner_image": "banners/banner_123.jpg",
      "banner_url": "https://example.com",
      "banner_title": "Special Offer"
    }
  ]
}
```

---

## 📌 Important Notes

### Common Field Names for Pharmacy Name:
When working with delivery/rider APIs, pharmacy name may appear in different fields:
- `pha_first_name` (most common)
- `pharmacy_name`
- `organization_name`
- `pha_name`

### Status Values:
- **Order Status:** `pending`, `ready`, `dispatched`, `delivered`
- **Delivery Status:** `pending`, `pickedup`, `delivered`
- **Quotation Status:** `pending`, `submitted`, `rejected`
- **Notification Status:** `read`, `unread`

### Date Formats:
- Most dates are in format: `"YYYY-MM-DD HH:MM:SS"`
- ISO dates: `"YYYY-MM-DDTHH:MM:SSZ"`
- Date only: `"YYYY-MM-DD"`

### Error Responses:
All APIs may return error responses in the format:
```json
{
  "success": false,
  "message": "Error message here"
}
```

---

*Last Updated: Based on codebase analysis*
















