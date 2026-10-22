# Forgot Password OTP API Documentation

## Base URL
```
https://quikdawa.com/QdawaAPIs/public/index.php
```

---

## 🔐 Forgot Password Flow APIs

### 1. Send OTP for Password Reset
**Endpoint:** `POST /forgot_password_send_otp`

**Description:** 
- Validates if the account exists (by email, username, or phone number)
- If account exists, generates and sends OTP via SMS to the user's registered mobile number
- Returns success response with masked phone number for display

**Request Headers:**
```
Content-Type: application/x-www-form-urlencoded
```

**Request Body:**
```json
{
  "identifier": "user@example.com"  // Can be email, username, or phone number
}
```

**Alternative Request Body (if supporting separate fields):**
```json
{
  "usr_email": "user@example.com",      // Optional: email address
  "usr_username": "john_doe",            // Optional: username
  "usr_mobile_number": "+254712345678"  // Optional: phone number
}
```

**Response (200 OK - Account Found):**
```json
{
  "success": true,
  "status": "success",
  "message": "OTP sent successfully to your registered mobile number",
  "data": {
    "masked_phone": "+254******5678",  // Last 4 digits visible
    "otp_expires_in": 300,             // OTP expiry time in seconds (5 minutes)
    "resend_available_in": 60          // Resend OTP available after 60 seconds
  }
}
```

**Response (200 OK - Account Not Found):**
```json
{
  "success": false,
  "status": "error",
  "message": "No account found with the provided information. Please check and try again.",
  "data": null
}
```

**Response (400 Bad Request - Invalid Input):**
```json
{
  "success": false,
  "status": "error",
  "message": "Please provide email, username, or phone number",
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

**Error Response (500 Internal Server Error):**
```json
{
  "success": false,
  "status": "error",
  "message": "Failed to send OTP. Please try again later.",
  "data": null
}
```

**Implementation Notes:**
- Validate that at least one identifier (email, username, or phone) is provided
- Check if account exists in database by matching any of the provided identifiers
- Generate a 6-digit OTP code
- Store OTP in database/cache with:
  - User ID
  - OTP code (hashed)
  - Expiry timestamp (5 minutes from generation)
  - Created timestamp
- Send OTP via SMS to the user's registered mobile number
- Implement rate limiting (max 3 requests per 10 minutes per identifier)
- Return masked phone number (show only last 4 digits) for security

---

### 2. Verify OTP for Password Reset
**Endpoint:** `POST /forgot_password_verify_otp`

**Description:**
- Validates the OTP code entered by the user
- Verifies OTP is valid, not expired, and matches the user account
- Returns success response if OTP is valid, allowing user to proceed to change password screen

**Request Headers:**
```
Content-Type: application/x-www-form-urlencoded
```

**Request Body:**
```json
{
  "identifier": "user@example.com",  // Same identifier used in step 1 (email, username, or phone)
  "otp_code": "123456"                // 6-digit OTP code entered by user
}
```

**Alternative Request Body (if supporting separate fields):**
```json
{
  "usr_email": "user@example.com",      // Optional: email address
  "usr_username": "john_doe",            // Optional: username
  "usr_mobile_number": "+254712345678", // Optional: phone number
  "otp_code": "123456"                   // 6-digit OTP code
}
```

**Response (200 OK - OTP Valid):**
```json
{
  "success": true,
  "status": "success",
  "message": "OTP verified successfully",
  "data": {
    "usr_id": "123",
    "verification_token": "reset_token_abc123xyz",  // Temporary token for password reset (valid for 10 minutes)
    "expires_at": "2024-01-15 10:35:00"
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
  "message": "Please provide identifier and OTP code",
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
- Validate that identifier and OTP code are provided
- Find the user account by identifier
- Retrieve stored OTP from database/cache for that user
- Verify:
  - OTP code matches (compare hashed values)
  - OTP is not expired (check expiry timestamp)
  - OTP has not been used before (mark as used after verification)
  - Maximum 5 verification attempts per OTP
- If valid, generate a temporary verification token (JWT or random string)
- Store verification token with:
  - User ID
  - Expiry timestamp (10 minutes from verification)
  - Created timestamp
- Mark OTP as used in database
- Return verification token to mobile app (app will use this token in step 3)

---

### 3. Change Password After OTP Verification
**Endpoint:** `POST /forgot_password_change`

**Description:**
- Validates the verification token from step 2
- Validates the new password meets requirements
- Updates the user's password in the database
- Invalidates the verification token and OTP after successful password change

**Request Headers:**
```
Content-Type: application/x-www-form-urlencoded
```

**Request Body:**
```json
{
  "identifier": "user@example.com",        // Same identifier used in previous steps
  "verification_token": "reset_token_abc123xyz",  // Token received from step 2
  "new_password": "NewSecurePassword123",  // New password (should be hashed on backend)
  "confirm_password": "NewSecurePassword123"  // Confirm password (for validation)
}
```

**Alternative Request Body (if supporting separate fields):**
```json
{
  "usr_email": "user@example.com",         // Optional: email address
  "usr_username": "john_doe",              // Optional: username
  "usr_mobile_number": "+254712345678",    // Optional: phone number
  "verification_token": "reset_token_abc123xyz",
  "new_password": "NewSecurePassword123",
  "confirm_password": "NewSecurePassword123"
}
```

**Response (200 OK - Password Changed Successfully):**
```json
{
  "success": true,
  "status": "success",
  "message": "Password changed successfully. Please login with your new password.",
  "data": {
    "usr_id": "123",
    "password_changed_at": "2024-01-15 10:40:00"
  }
}
```

**Response (200 OK - Invalid Token):**
```json
{
  "success": false,
  "status": "error",
  "message": "Invalid or expired verification token. Please start the password reset process again.",
  "data": null
}
```

**Response (200 OK - Token Expired):**
```json
{
  "success": false,
  "status": "error",
  "message": "Verification token has expired. Please verify OTP again.",
  "data": null
}
```

**Response (200 OK - Password Mismatch):**
```json
{
  "success": false,
  "status": "error",
  "message": "New password and confirm password do not match.",
  "data": null
}
```

**Response (200 OK - Weak Password):**
```json
{
  "success": false,
  "status": "error",
  "message": "Password must be at least 8 characters long and contain at least one letter and one number.",
  "data": null
}
```

**Response (200 OK - Same as Old Password):**
```json
{
  "success": false,
  "status": "error",
  "message": "New password cannot be the same as your current password.",
  "data": null
}
```

**Response (400 Bad Request - Missing Fields):**
```json
{
  "success": false,
  "status": "error",
  "message": "Please provide identifier, verification token, and new password",
  "data": null
}
```

**Implementation Notes:**
- Validate that all required fields are provided
- Find the user account by identifier
- Verify the verification token:
  - Token exists in database/cache
  - Token matches the user ID
  - Token is not expired (check expiry timestamp)
  - Token has not been used before
- Validate new password:
  - Minimum 8 characters
  - Contains at least one letter and one number
  - New password matches confirm password
  - New password is different from current password (compare hashed values)
- Hash the new password using the same algorithm as login (e.g., bcrypt, SHA-256)
- Update password in database:
  - Update `usr_password_hash` field in users table
  - Update `password_changed_at` timestamp
- Invalidate verification token (mark as used or delete)
- Invalidate any existing OTPs for this user
- Optionally: Log password change event for security audit
- Optionally: Send email notification to user about password change

---

## 🔄 Complete Flow Example

### Step 1: User clicks "Forgot Password" and enters email/username/phone
**Request:**
```http
POST /forgot_password_send_otp
Content-Type: application/x-www-form-urlencoded

identifier=user@example.com
```

**Response:**
```json
{
  "success": true,
  "status": "success",
  "message": "OTP sent successfully to your registered mobile number",
  "data": {
    "masked_phone": "+254******5678",
    "otp_expires_in": 300,
    "resend_available_in": 60
  }
}
```

### Step 2: User enters OTP code
**Request:**
```http
POST /forgot_password_verify_otp
Content-Type: application/x-www-form-urlencoded

identifier=user@example.com&otp_code=123456
```

**Response:**
```json
{
  "success": true,
  "status": "success",
  "message": "OTP verified successfully",
  "data": {
    "usr_id": "123",
    "verification_token": "reset_token_abc123xyz",
    "expires_at": "2024-01-15 10:35:00"
  }
}
```

### Step 3: User enters new password
**Request:**
```http
POST /forgot_password_change
Content-Type: application/x-www-form-urlencoded

identifier=user@example.com&verification_token=reset_token_abc123xyz&new_password=NewSecurePassword123&confirm_password=NewSecurePassword123
```

**Response:**
```json
{
  "success": true,
  "status": "success",
  "message": "Password changed successfully. Please login with your new password.",
  "data": {
    "usr_id": "123",
    "password_changed_at": "2024-01-15 10:40:00"
  }
}
```

---

## 📋 Database Schema Requirements

### OTP Storage Table (if using database)
```sql
CREATE TABLE password_reset_otps (
    id INT PRIMARY KEY AUTO_INCREMENT,
    usr_id INT NOT NULL,
    identifier VARCHAR(255) NOT NULL,  -- email, username, or phone
    otp_hash VARCHAR(255) NOT NULL,     -- hashed OTP code
    otp_code VARCHAR(6) NOT NULL,       -- plain OTP for SMS (delete after sending)
    expires_at DATETIME NOT NULL,
    is_used TINYINT(1) DEFAULT 0,
    attempts INT DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_usr_id (usr_id),
    INDEX idx_identifier (identifier),
    INDEX idx_expires_at (expires_at)
);
```

### Verification Token Storage Table (if using database)
```sql
CREATE TABLE password_reset_tokens (
    id INT PRIMARY KEY AUTO_INCREMENT,
    usr_id INT NOT NULL,
    identifier VARCHAR(255) NOT NULL,
    token VARCHAR(255) NOT NULL UNIQUE,
    expires_at DATETIME NOT NULL,
    is_used TINYINT(1) DEFAULT 0,
    created_at DATETIME DEFAULT CURRENT_TIMESTAMP,
    INDEX idx_token (token),
    INDEX idx_usr_id (usr_id),
    INDEX idx_expires_at (expires_at)
);
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
   - Maximum 3 OTP requests per 10 minutes per identifier
   - Maximum 5 OTP verification attempts per OTP
   - Implement exponential backoff for repeated failures

4. **Token Security:**
   - Verification token expires after 10 minutes
   - Token can only be used once
   - Use cryptographically secure token generation

5. **Password Requirements:**
   - Minimum 8 characters
   - At least one letter and one number
   - Cannot be same as current password
   - Hash password using secure algorithm (bcrypt recommended)

6. **Input Validation:**
   - Sanitize all user inputs
   - Validate email format if email is provided
   - Validate phone number format if phone is provided
   - Prevent SQL injection and XSS attacks

7. **Logging:**
   - Log all password reset attempts (successful and failed)
   - Log IP address and timestamp
   - Monitor for suspicious activity patterns

---

## 📱 Mobile App Integration Notes

1. **Step 1 - Send OTP:**
   - User enters email/username/phone on forgot password screen
   - App calls `/forgot_password_send_otp` endpoint
   - On success, navigate to OTP entry screen
   - Display masked phone number to user
   - Show countdown timer for OTP expiry

2. **Step 2 - Verify OTP:**
   - User enters 6-digit OTP code
   - App calls `/forgot_password_verify_otp` endpoint
   - On success, store verification token temporarily
   - Navigate to new password entry screen

3. **Step 3 - Change Password:**
   - User enters new password and confirm password
   - App validates passwords match on client side
   - App calls `/forgot_password_change` endpoint with verification token
   - On success, navigate to login screen
   - Show success message: "Password changed successfully. Please login."

4. **Error Handling:**
   - Display user-friendly error messages
   - Handle network errors gracefully
   - Provide "Resend OTP" option after 60 seconds
   - Allow user to go back and restart the process

5. **State Management:**
   - Store identifier (email/username/phone) throughout the flow
   - Store verification token after OTP verification
   - Clear all stored data after successful password change or cancellation

---

## 🧪 Testing Checklist

### API 1: Send OTP
- [ ] Valid email sends OTP successfully
- [ ] Valid username sends OTP successfully
- [ ] Valid phone number sends OTP successfully
- [ ] Invalid identifier returns error
- [ ] Rate limiting works correctly
- [ ] OTP is sent via SMS
- [ ] Masked phone number is returned correctly

### API 2: Verify OTP
- [ ] Valid OTP returns success with token
- [ ] Invalid OTP returns error
- [ ] Expired OTP returns error
- [ ] Used OTP returns error
- [ ] Too many attempts returns error
- [ ] Verification token is generated correctly

### API 3: Change Password
- [ ] Valid token and password changes password successfully
- [ ] Invalid token returns error
- [ ] Expired token returns error
- [ ] Weak password returns error
- [ ] Password mismatch returns error
- [ ] Same as old password returns error
- [ ] Password is hashed correctly in database
- [ ] User can login with new password

---

## 📞 Support

For any questions or issues regarding these APIs, please contact the development team.

**Last Updated:** 2024-01-15
**API Version:** 1.0

