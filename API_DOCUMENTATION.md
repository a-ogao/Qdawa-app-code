# QuikDawa Medicine & Prescription APIs

## Base URL
```
https://quikdawa.com/QdawaAPIs/public/index.php
```

## Authentication
All APIs require user authentication via `usr_id` parameter or session-based authentication.

---

## 🔍 Medicine Search & Suggestion APIs

### 1. Search Medicines (Autocomplete)
**Endpoint:** `POST /searchMedicines`

**Description:** Search for medicines with autocomplete functionality for prescription writing.

**Request Body:**
```json
{
  "query": "paracetamol",
  "limit": "10"
}
```

**Parameters:**
- `query` (string, required): Search term (minimum 2 characters)
- `limit` (string, optional): Maximum number of results (default: 10)

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "id": "med_001",
      "name": "Paracetamol 500mg",
      "generic_name": "Acetaminophen",
      "strength": "500",
      "unit": "mg",
      "form": "tablet",
      "manufacturer": "ABC Pharma",
      "category": "Analgesic",
      "description": "Pain relief medication"
    },
    {
      "id": "med_002", 
      "name": "Paracetamol Syrup",
      "generic_name": "Acetaminophen",
      "strength": "120",
      "unit": "mg/5ml",
      "form": "syrup",
      "manufacturer": "XYZ Pharma",
      "category": "Analgesic",
      "description": "Liquid pain relief for children"
    }
  ],
  "message": "Medicines found successfully"
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "No medicines found",
  "data": []
}
```

---

### 2. Get Medicine Details
**Endpoint:** `POST /getMedicineDetails`

**Description:** Get detailed information about a specific medicine.

**Request Body:**
```json
{
  "medicine_id": "med_001"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "id": "med_001",
    "name": "Paracetamol 500mg",
    "generic_name": "Acetaminophen",
    "strength": "500",
    "unit": "mg",
    "form": "tablet",
    "manufacturer": "ABC Pharma",
    "category": "Analgesic",
    "description": "Pain relief medication",
    "dosage_instructions": "Take 1-2 tablets every 4-6 hours",
    "contraindications": "Liver disease, alcohol abuse",
    "side_effects": "Nausea, rash, liver damage with overdose",
    "storage_conditions": "Store at room temperature",
    "expiry_date": "2025-12-31",
    "price": "50.00",
    "currency": "KSH",
    "availability": true,
    "pharmacy_count": 15
  }
}
```

---

## 📝 Prescription Management APIs

### 3. Submit Prescription
**Endpoint:** `POST /submitPrescription`

**Description:** Submit a new prescription with medicines and doctor signature.

**Request Body:**
```json
{
  "doctor_id": "doc_123",
  "patient_id": "pat_456",
  "prescription_items": [
    {
      "medicine_id": "med_001",
      "medicine_name": "Paracetamol 500mg",
      "generic_name": "Acetaminophen",
      "strength": "500",
      "unit": "mg",
      "route": "oral",
      "dosage_per_time": "1",
      "frequency": {
        "MN": 1,
        "AF": 1, 
        "EN": 1,
        "NT": 0
      },
      "times_per_day": "3",
      "duration": "7",
      "quantity": "21",
      "refill": "0"
    },
    {
      "medicine_id": "med_002",
      "medicine_name": "Amoxicillin 250mg",
      "generic_name": "Amoxicillin",
      "strength": "250",
      "unit": "mg",
      "route": "oral",
      "dosage_per_time": "1",
      "frequency": {
        "MN": 1,
        "AF": 1,
        "EN": 1,
        "NT": 0
      },
      "times_per_day": "3",
      "duration": "10",
      "quantity": "30",
      "refill": "0"
    }
  ],
  "signature": "base64_encoded_signature_image",
  "notes": "Patient has allergy to penicillin - use alternative if needed"
}
```

**Response:**
```json
{
  "success": true,
  "data": {
    "prescription_id": "pres_789",
    "prescription_number": "PRES-2024-001",
    "doctor_id": "doc_123",
    "patient_id": "pat_456",
    "created_at": "2024-01-15T10:30:00Z",
    "status": "active",
    "total_medicines": 2,
    "estimated_cost": "150.00",
    "currency": "KSH"
  },
  "message": "Prescription submitted successfully"
}
```

**Error Response:**
```json
{
  "success": false,
  "message": "Failed to submit prescription",
  "error": "Invalid medicine ID: med_999"
}
```

---

### 4. Get Patient List (for Doctor)
**Endpoint:** `POST /getPatientList`

**Description:** Get list of patients for a specific doctor.

**Request Body:**
```json
{
  "doctor_id": "doc_123"
}
```

**Response:**
```json
{
  "success": true,
  "data": [
    {
      "patient_id": "pat_456",
      "first_name": "John",
      "last_name": "Doe",
      "email": "john.doe@email.com",
      "phone": "+254712345678",
      "date_of_birth": "1990-05-15",
      "gender": "male",
      "last_visit": "2024-01-10T14:30:00Z",
      "total_prescriptions": 5,
      "active_prescriptions": 2
    },
    {
      "patient_id": "pat_789",
      "first_name": "Jane",
      "last_name": "Smith", 
      "email": "jane.smith@email.com",
      "phone": "+254798765432",
      "date_of_birth": "1985-08-22",
      "gender": "female",
      "last_visit": "2024-01-12T09:15:00Z",
      "total_prescriptions": 3,
      "active_prescriptions": 1
    }
  ],
  "message": "Patient list retrieved successfully"
}
```

---

## 🏥 Additional Prescription APIs

### 5. Get Prescription History
**Endpoint:** `POST /getPrescriptionHistory`

**Description:** Get prescription history for a patient.

**Request Body:**
```json
{
  "patient_id": "pat_456",
  "doctor_id": "doc_123",
  "limit": "20"
}
```

### 6. Update Prescription Status
**Endpoint:** `POST /updatePrescriptionStatus`

**Description:** Update prescription status (active, completed, cancelled).

**Request Body:**
```json
{
  "prescription_id": "pres_789",
  "status": "completed",
  "notes": "Patient completed full course"
}
```

### 7. Get Prescription Details
**Endpoint:** `POST /getPrescriptionDetails`

**Description:** Get detailed information about a specific prescription.

**Request Body:**
```json
{
  "prescription_id": "pres_789"
}
```

---

## 📊 Medicine Categories & Forms

### Supported Medicine Routes:
- **Oral**: Tablets, capsules, syrups (by mouth)
- **Parenteral**: Injections, IV infusions (bypass GI)
- **Mucosal**: Eye drops, nasal sprays, suppositories
- **Irrigation**: Wound irrigation, bladder irrigation
- **Other**: Transdermal patches, inhalations, etc.

### Medicine Forms:
- Tablets
- Capsules
- Syrups
- Injections
- Drops
- Creams/Ointments
- Patches
- Suppositories

---

## 🔧 Implementation Notes

### Frontend Integration:
1. **Medicine Autocomplete**: Use `MedicineAutocomplete` widget for real-time search
2. **Debounced Search**: 500ms delay to avoid excessive API calls
3. **Loading States**: Show loading indicators during API calls
4. **Error Handling**: Display user-friendly error messages

### Backend Requirements:
1. **Database Tables**:
   - `medicines` - Medicine master data
   - `prescriptions` - Prescription headers
   - `prescription_items` - Individual medicine items
   - `doctors` - Doctor information
   - `patients` - Patient information

2. **Search Optimization**:
   - Full-text search on medicine names
   - Index on generic names and categories
   - Caching for frequently searched medicines

3. **Security**:
   - Validate doctor-patient relationships
   - Encrypt sensitive prescription data
   - Audit trail for prescription changes

---

## 📱 Mobile App Integration

### Medicine Search Flow:
1. User types in medicine field
2. API call triggered after 500ms delay
3. Display suggestions with medicine details
4. User selects medicine
5. Auto-populate medicine information
6. Calculate quantity based on frequency/duration

### Prescription Submission Flow:
1. Validate all required fields
2. Check doctor and patient IDs
3. Verify signature exists
4. Submit to API with loading state
5. Show success/error message
6. Navigate back on success

---

## 🚀 Testing

### Test Data:
```json
{
  "test_medicines": [
    {
      "name": "Paracetamol 500mg",
      "generic_name": "Acetaminophen",
      "strength": "500",
      "unit": "mg"
    },
    {
      "name": "Amoxicillin 250mg", 
      "generic_name": "Amoxicillin",
      "strength": "250",
      "unit": "mg"
    }
  ]
}
```

### API Testing:
- Use Postman collection for testing
- Test with various search queries
- Validate response formats
- Check error handling scenarios

---

## 📈 Performance Considerations

1. **Caching**: Cache frequently searched medicines
2. **Pagination**: Limit search results to 10-20 items
3. **Debouncing**: Prevent excessive API calls
4. **Offline Support**: Cache recent searches locally
5. **Image Optimization**: Compress signature images

---

## 🔒 Security & Compliance

1. **Data Encryption**: Encrypt prescription data
2. **Access Control**: Verify doctor-patient relationships
3. **Audit Logging**: Log all prescription activities
4. **HIPAA Compliance**: Ensure patient data privacy
5. **Signature Validation**: Verify digital signatures

---

*This documentation covers the complete medicine suggestion and prescription management system for QuikDawa application.*

