# get_pharmacy API Endpoint Details

## Endpoint Information

### Base URL
```
https://prod.quikdawa.com/QdawaAPIs/public/index.php
```

### Full Endpoint
```
POST https://prod.quikdawa.com/QdawaAPIs/public/index.php/get_pharmacy
```

---

## Request Details

### HTTP Method
```
POST
```

### Headers
```
Content-Type: application/x-www-form-urlencoded
```

### Request Body (Form Data)
```
phid=0
```

**Parameters:**
- `phid` (string, required): Pharmacy ID filter
  - `"0"` = Returns all pharmacies
  - Specific ID (e.g., `"67"`) = Returns specific pharmacy or filtered list

---

## Example Request

### Using cURL
```bash
curl -X POST https://prod.quikdawa.com/QdawaAPIs/public/index.php/get_pharmacy \
  -H "Content-Type: application/x-www-form-urlencoded" \
  -d "phid=0"
```

### Using Dart/Flutter
```dart
import 'package:http/http.dart' as http;

final response = await http.post(
  Uri.parse('https://prod.quikdawa.com/QdawaAPIs/public/index.php/get_pharmacy'),
  headers: {'Content-Type': 'application/x-www-form-urlencoded'},
  body: {'phid': '0'},
);
```

### Using JavaScript/Fetch
```javascript
fetch('https://prod.quikdawa.com/QdawaAPIs/public/index.php/get_pharmacy', {
  method: 'POST',
  headers: {
    'Content-Type': 'application/x-www-form-urlencoded',
  },
  body: new URLSearchParams({
    phid: '0'
  })
})
.then(response => response.json())
.then(data => console.log(data));
```

### Using Postman
- **Method:** POST
- **URL:** `https://prod.quikdawa.com/QdawaAPIs/public/index.php/get_pharmacy`
- **Headers:**
  - `Content-Type: application/x-www-form-urlencoded`
- **Body (x-www-form-urlencoded):**
  - Key: `phid`
  - Value: `0`

---

## Response Format

### Success Response (200 OK)
```json
{
  "success": true,
  "data": [
    {
      "usr_id": 67,
      "usr_username": "togo",
      "usr_email": "Togo.joshua@gmail.com",
      "usr_mobile_number": "254721255644",
      "pha_first_name": "Joshua",
      "pha_license_number": null,
      "pha_alt_phone_number": "254721255644",
      "pha_last_name": null,
      "org_organization_name": "ST. JOHN PHARMACEUTICALS",
      "pharmacy_rating": 0,
      "totaluser": 0
    }
    // ... more pharmacies
  ]
}
```

### Response Fields
| Field | Type | Description |
|-------|------|-------------|
| `success` | boolean | API call success status |
| `data` | array | List of pharmacy objects |
| `usr_id` | number | User/Pharmacy ID |
| `usr_username` | string | Username |
| `usr_email` | string | Email address |
| `usr_mobile_number` | string | Mobile phone number |
| `pha_first_name` | string | First name |
| `pha_last_name` | string | Last name (nullable) |
| `pha_license_number` | string | License number (nullable) |
| `pha_alt_phone_number` | string | Alternative phone number |
| `org_organization_name` | string | Organization/Company name |
| `pharmacy_rating` | number | Total rating points |
| `totaluser` | number | Total number of users/ratings |

---

## Test Examples

### Get All Pharmacies
```bash
# Request
POST /get_pharmacy
Body: phid=0

# Response: Returns all pharmacies in system
```

### Get Specific Pharmacy (if supported)
```bash
# Request
POST /get_pharmacy
Body: phid=67

# Response: Returns pharmacy with ID 67 (or filtered list)
```

---

## Current Implementation in Code

**File:** `lib/presentation/pharmacy_list_screen/pharmacy_list_screen.dart`

```dart
final response = await http.post(
  Uri.parse(AppConfig.buildApiUrl('get_pharmacy')),
  headers: {'Content-Type': 'application/x-www-form-urlencoded'},
  body: {'phid': pharmacyid.toString()},
);
```

**File:** `lib/core/config/app_config.dart`

```dart
static const String baseDomain = 'https://prod.quikdawa.com';
static const String baseApiUrl = '$baseDomain/QdawaAPIs/public/index.php';

static String buildApiUrl(String endpoint) {
  final cleanEndpoint = endpoint.startsWith('/') 
      ? endpoint.substring(1) 
      : endpoint;
  return '$baseApiUrl/$cleanEndpoint';
}
```

---

## Notes

- **No Pagination:** Currently returns all pharmacies in a single response
- **No Limits:** No limit parameter in request or response
- **No Caching:** API call is made fresh every time
- **Filtering:** Only by `phid` parameter (0 for all, or specific ID)

---

*Last Updated: Based on current codebase analysis*


