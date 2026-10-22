# Prescription Counter API Issue - Doctor Dashboard

## Problem Description
In the Doctor Dashboard, the **Prescription counter shows 0**, but when the user clicks on "Prescriptions", the list screen displays actual prescriptions. This indicates a mismatch between the counter API and the prescription list API.

## API Endpoints Comparison

### 1. Counter API (Currently Returning 0)
**Endpoint:** `doctorcounters`  
**Full URL:** `https://quikdawa.com/QdawaAPIs/public/index.php/doctorcounters`  
**Method:** `POST`  
**Request Body:**
```json
{
  "usr_id": "<user_id>"
}
```
**Content-Type:** `application/x-www-form-urlencoded` (form data)

**Expected Response Structure:**
```json
{
  "quotations": 0,  // ← This is showing 0 but should match actual count
  "orders": 0,
  "totalAmount": "KSH 0",
  "delivered": 0,
  "newPat": 0,
  "notification": 0
}
```

**Location in Code:** `lib/presentation/doctor/dashboard_screen/dashboard.dart` (lines 222-225)

---

### 2. Prescription List API (Working Correctly)
**Endpoint:** `get_quotation_drequest`  
**Full URL:** `https://quikdawa.com/QdawaAPIs/public/index.php/get_quotation_drequest`  
**Method:** `POST`  
**Request Body:**
```json
{
  "usr_id": "<user_id>"
}
```
**Content-Type:** `application/x-www-form-urlencoded` (form data)

**Response Structure:**
```json
{
  "quotations": [
    {
      // prescription objects...
    }
  ]
}
```

**Location in Code:** 
- Counter fallback: `lib/presentation/doctor/dashboard_screen/dashboard.dart` (lines 260-263)
- Prescription list screen: `lib/presentation/doctor/quotation_list_screen/quotationrequest_patient_screen.dart` (lines 86-89)

---

## Issue Analysis

The `doctorcounters` endpoint is returning `quotations: 0`, but the `get_quotation_drequest` endpoint returns actual prescription data. The counter value should match the count of prescriptions returned by `get_quotation_drequest`.

## Current Workaround

The app currently has a fallback mechanism that:
1. First calls `doctorcounters` to get all counters
2. If `quotations` is 0 or null, it makes a second API call to `get_quotation_drequest`
3. Counts the prescriptions from the list and updates the counter

**Code Location:** `lib/presentation/doctor/dashboard_screen/dashboard.dart` (lines 233-280)

## Required Fix

The `doctorcounters` endpoint should return the correct count of prescriptions in the `quotations` field, matching what `get_quotation_drequest` returns.

**Expected Behavior:**
- When `get_quotation_drequest` returns N prescriptions, `doctorcounters` should return `quotations: N`
- Both endpoints should use the same filtering/counting logic for consistency

## Testing

To verify the fix:
1. Call `doctorcounters` with a valid `usr_id`
2. Call `get_quotation_drequest` with the same `usr_id`
3. Compare: `doctorcounters.quotations` should equal `get_quotation_drequest.quotations.length`

---

**Date:** Generated automatically  
**Priority:** High (affects user experience - counter shows incorrect data)

