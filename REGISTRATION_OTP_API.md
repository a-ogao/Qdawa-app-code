# Registration OTP API Documentation

## Base URL
```
https://quikdawa.com/QdawaAPIs/public/index.php
```

---

## 🔐 Registration OTP Flow APIs

### 1. User Registration (Sends OTP Automatically)
**Endpoint:** `POST /insert_user`

**Description:** 
- Creates a new user account in the system
- Automatically generates and sends OTP via SMS to the user's registered mobile number
- Returns user data including user ID for OTP verification

**Request Headers:**
```
Content-Type: multipart/form-data
```

**Request Body (Form Data):**
```
first_name: "John"
phone_number: "254712345678"  // Format: 254 + phone number (without leading 0)
pha_address: "123 Main Street, Nairobi"
email: "user@example.com"
username: "john_doe"
password: "SecurePassword123"
user_type: "patient" | "pharmacist" | "rider" | "healthcare_provider"
license: [File] (optional, required for pharmacist)
certificate: [File] (optional, required for pharmacist)
id_proof: [File] (optional, required for pharmacist)
```

**Response (200 OK - Registration Successful):**
```json
{
  "success": true,
  "status": "success",
  "message": "Registration successful! OTP sent to your mobile number.",
  "data": {
    "id": 123,
    "usr_user_type": "patient",
    "usr_username": "john_doe",
    "usr_email": "user@example.com",
    "usr_mobile_number": "+254712345678",
    "usr_first_name": "John",
    "usr_verify_status": "0"  // "0" = not verified, needs OTP verification
  }
}
```

**Response (200 OK - Registration Failed):**
```json
{
  "success": false,
  "status": "error",
  "message": "Registration failed. Email/username already exists.",
  "data": null
}
```

**Response (400 Bad Request - Validation Error):**
```json
{
  "success": false,
  "status": "error",
  "message": "Please fill all required fields",
  "data": null
}
```

**Implementation Notes:**
- After successful registration, automatically generate a 6-digit OTP
- Send OTP via SMS to the user's registered mobile number
- Store OTP in database/cache with:
  - User ID
  - OTP code (hashed)
  - Expiry timestamp (5 minutes from generation)
  - Created timestamp
- Return user data including user ID in the response
- User account should be marked as unverified until OTP is verified

---

### 2. Verify OTP for Registration
**Endpoint:** `POST /verify_otp`

**Description:**
- Verifies the OTP code entered by the user during registration
- Validates OTP is correct, not expired, and matches the user account
- Marks user account as verified if OTP is valid
- Returns success response allowing user to proceed to login/dashboard

**Request Headers:**
```
Content-Type: application/x-www-form-urlencoded
```

**Request Body:**
```json
{
  "usr_id": "123",      // User ID received from registration response
  "usr_otp": "123456"   // 6-digit OTP code entered by user
}
```

**Response (200 OK - OTP Valid):**
```json
{
  "success": true,
  "status": "success",
  "message": "OTP verified successfully. Registration complete!",
  "data": {
    "usr_id": "123",
    "usr_verify_status": "1",  // "1" = verified
    "verified_at": "2024-01-15 10:40:00"
  }
}
```

**Response (200 OK - OTP Invalid):**
```json
{
  "success": false,
  "status": "error",
  "message": "Invalid OTP code. Please check and try again.",
  "data": null
}
```

**Response (200 OK - OTP Expired):**
```json
{
  "success": false,
  "status": "error",
  "message": "OTP has expired. Please request a new OTP.",
  "data": null
}
```

**Response (200 OK - OTP Already Used):**
```json
{
  "success": false,
  "status": "error",
  "message": "This OTP has already been used. Please request a new OTP.",
  "data": null
}
```

**Response (400 Bad Request - Missing Fields):**
```json
{
  "success": false,
  "status": "error",
  "message": "Please provide user ID and OTP code",
  "data": null
}
```

**Response (429 Too Many Requests - Too Many Attempts):**
```json
{
  "success": false,
  "status": "error",
  "message": "Too many verification attempts. Please request a new OTP.",
  "data": null
}
```

**Implementation Notes:**
- Validate that user ID and OTP code are provided
- Find the user account by user ID
- Retrieve stored OTP from database/cache for that user
- Verify:
  - OTP code matches (compare hashed values)
  - OTP is not expired (check expiry timestamp)
  - OTP has not been used before (mark as used after verification)
  - Maximum 5 verification attempts per OTP
- If valid:
  - Update user account: set `usr_verify_status` to "1" (verified)
  - Update `verified_at` timestamp
  - Mark OTP as used in database
  - Return success response
- If invalid, return appropriate error message

---

### 3. Resend OTP for Registration
**Endpoint:** `POST /resend_otp`

**Description:**
- Resends OTP to the user's registered mobile number
- Useful when user didn't receive the initial OTP or it expired
- Generates a new OTP and invalidates the previous one

**Request Headers:**
```
Content-Type: application/x-www-form-urlencoded
```

**Request Body:**
```json
{
  "usr_id": "123"  // User ID received from registration response
}
```

**Response (200 OK - OTP Resent):**
```json
{
  "success": true,
  "status": "success",
  "message": "OTP resent successfully to your registered mobile number",
  "data": {
    "masked_phone": "+254******5678",  // Last 4 digits visible
    "otp_expires_in": 300,             // OTP expiry time in seconds (5 minutes)
    "resend_available_in": 60          // Resend OTP available after 60 seconds
  }
}
```

**Response (200 OK - User Not Found):**
```json
{
  "success": false,
  "status": "error",
  "message": "User not found. Please register again.",
  "data": null
}
```

**Response (429 Too Many Requests - Rate Limit):**
```json
{
  "success": false,
  "status": "error",
  "message": "Too many OTP requests. Please try again after 60 seconds.",
  "data": null
}
```

**Implementation Notes:**
- Validate that user ID is provided
- Check if user account exists
- Implement rate limiting (max 3 resend requests per 10 minutes per user)
- Generate a new 6-digit OTP
- Invalidate previous OTP for this user
- Store new OTP in database/cache with expiry timestamp
- Send new OTP via SMS to user's registered mobile number
- Return masked phone number for display

---

## 🔄 Complete Registration Flow Example

### Step 1: User submits registration form
**Request:**
```http
POST /insert_user
Content-Type: multipart/form-data

first_name=John&phone_number=254712345678&email=user@example.com&username=john_doe&password=SecurePassword123&user_type=patient
```

**Response:**
```json
{
  "success": true,
  "status": "success",
  "message": "Registration successful! OTP sent to your mobile number.",
  "data": {
    "id": 123,
    "usr_user_type": "patient",
    "usr_username": "john_doe",
    "usr_email": "user@example.com",
    "usr_mobile_number": "+254712345678",
    "usr_verify_status": "0"
  }
}
```

### Step 2: User enters OTP code
**Request:**
```http
POST /verify_otp
Content-Type: application/x-www-form-urlencoded

usr_id=123&usr_otp=123456
```

**Response:**
```json
{
  "success": true,
  "status": "success",
  "message": "OTP verified successfully. Registration complete!",
  "data": {
    "usr_id": "123",
    "usr_verify_status": "1",
    "verified_at": "2024-01-15 10:40:00"
  }
}
```

### Step 3: User can now login (if needed)
After successful OTP verification, user can proceed to login screen or be automatically logged in.

---

## 📋 Database Schema Requirements

### OTP Storage Table (if using database)
```sql
CREATE TABLE registration_otps (
    id INT PRIMARY KEY AUTO_INCREMENT,
    usr_id INT NOT NULL,
    otp_hash VARCHAR(255) NOT NULL,     -- hashed OTP code
    otp_code VARCHAR(6) NOT NULL,       -- plain OTP for SMS (delete after sending)
    expires_at DATETIME NOT NULL,
    is_used TINYINT(1) DEFAULT 0,
    attempts INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_usr_id (usr_id),
    INDEX idx_expires_at (expires_at)
);
```

### User Table Updates
```sql
ALTER TABLE users ADD COLUMN usr_verify_status VARCHAR(1) DEFAULT '0';
ALTER TABLE users ADD COLUMN verified_at DATETIME NULL;
```

---

## 🔒 Security Considerations

1. **OTP Generation:**
   - Generate random 6-digit numeric OTP
   - Use cryptographically secure random number generator
   - Store OTP hash in database, not plain text

2. **OTP Expiry:**
   - OTP expires after 5 minutes
   - OTP can only be used once
   - Maximum 5 verification attempts per OTP

3. **Rate Limiting:**
   - Maximum 3 OTP requests per 10 minutes per user
   - Maximum 5 OTP verification attempts per OTP
   - Implement exponential backoff for repeated failures

4. **Input Validation:**
   - Sanitize all user inputs
   - Validate user ID is numeric
   - Validate OTP is exactly 6 digits
   - Prevent SQL injection and XSS attacks

5. **Account Status:**
   - User account should remain unverified until OTP is verified
   - Unverified accounts should not be able to login
   - After OTP verification, mark account as verified

6. **Logging:**
   - Log all OTP verification attempts (successful and failed)
   - Log IP address and timestamp
   - Monitor for suspicious activity patterns

---

## 📱 Mobile App Integration Notes

1. **Step 1 - Registration:**
   - User fills registration form
   - App calls `/insert_user` endpoint
   - On success, store user data (especially `id`) in SharedPreferences
   - Navigate to OTP verification screen
   - Display masked phone number to user

2. **Step 2 - OTP Verification:**
   - User enters 6-digit OTP code
   - App calls `/verify_otp` endpoint with `usr_id` and `usr_otp`
   - On success, update user data in SharedPreferences
   - Navigate to appropriate dashboard based on user type
   - Show success message: "Registration complete!"

3. **Resend OTP:**
   - Provide "Resend Code" option after 60 seconds
   - App calls `/resend_otp` endpoint with `usr_id`
   - On success, show message and allow user to enter new OTP

4. **Error Handling:**
   - Display user-friendly error messages
   - Handle network errors gracefully
   - Provide "Resend OTP" option if OTP expired
   - Allow user to go back and restart registration if needed

5. **State Management:**
   - Store user ID from registration response
   - Store user data temporarily until OTP is verified
   - Clear temporary data after successful verification or cancellation

---

## 🧪 Testing Checklist

### API 1: Registration
- [ ] Valid registration data creates account successfully
- [ ] OTP is sent via SMS automatically
- [ ] User data is returned with user ID
- [ ] Duplicate email/username returns error
- [ ] Missing required fields returns error
- [ ] File uploads work for pharmacist documents

### API 2: Verify OTP
- [ ] Valid OTP returns success and marks user as verified
- [ ] Invalid OTP returns error
- [ ] Expired OTP returns error
- [ ] Used OTP returns error
- [ ] Too many attempts returns error
- [ ] User account status is updated correctly

### API 3: Resend OTP
- [ ] Valid user ID resends OTP successfully
- [ ] Invalid user ID returns error
- [ ] Rate limiting works correctly
- [ ] Previous OTP is invalidated
- [ ] New OTP is sent via SMS

---

## 📞 Support

For any questions or issues regarding these APIs, please contact the development team.

**Last Updated:** 2024-01-15
**API Version:** 1.0

