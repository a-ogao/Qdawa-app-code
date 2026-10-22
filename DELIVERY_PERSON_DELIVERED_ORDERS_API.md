# Delivery Person (Rider) - Delivered Orders API Response

## API Endpoint
**URL:** `https://quikdawa.com/QdawaAPIs/public/index.php/get_delivery_order`  
**Method:** `POST`

---

## Request

**Request Body:**
```json
{
  "usr_id": "123"
}
```

**Content-Type:** `application/x-www-form-urlencoded`

---

## Response (200 OK)

```json
{
  "orders": [
    {
      "id": 456,
      "qre_request_id": "REQ-12345",
      "ord_delivery_charge": "500",
      "del_delivered_time": "2024-01-15 14:30:00",
      "pha_first_name": "Malibu Pharmacy Limited",
      "pharmacy_name": "Malibu Pharmacy Limited",
      "organization_name": "Malibu Pharmacy",
      "pha_name": "Malibu",
      "usr_username": "customer_name",
      "ord_order_status": "delivered",
      "ord_total_amount": 5000,
      "adr_address_1": "123 Main Street"
    }
  ]
}
```

---

## Response Fields Description

| Field | Type | Description |
|-------|------|-------------|
| `orders` | Array | List of delivered orders |
| `orders[].id` | Number | Order ID |
| `orders[].qre_request_id` | String | Request/Quotation Request ID |
| `orders[].ord_delivery_charge` | String | Delivery charge amount |
| `orders[].del_delivered_time` | String | Delivery completion timestamp (format: "YYYY-MM-DD HH:MM:SS") |
| `orders[].pha_first_name` | String | **Pharmacy name** (primary field - where order was picked from) |
| `orders[].pharmacy_name` | String | **Pharmacy name** (alternative field) |
| `orders[].organization_name` | String | **Pharmacy name** (alternative field) |
| `orders[].pha_name` | String | **Pharmacy name** (alternative field) |
| `orders[].usr_username` | String | Customer username/name |
| `orders[].ord_order_status` | String | Order status (typically "delivered") |
| `orders[].ord_total_amount` | Number | Total order amount |
| `orders[].adr_address_1` | String | Delivery address |

---

## Notes

1. **Pharmacy Name Fields:** The API may return pharmacy name in any of these fields:
   - `pha_first_name` (most commonly used)
   - `pharmacy_name`
   - `organization_name`
   - `pha_name`
   
   The code checks all these fields to ensure pharmacy name is displayed correctly.

2. **Empty Response:** If no delivered orders exist, the response will be:
   ```json
   {
     "orders": []
   }
   ```

3. **Error Response:** If the request fails, the API may return an error or empty response.

---

## Example Usage in Code

```dart
final response = await http.post(
  Uri.parse('https://quikdawa.com/QdawaAPIs/public/index.php/get_delivery_order'),
  body: {'usr_id': userId.toString()},
);

if (response.statusCode == 200) {
  final data = json.decode(response.body);
  final orders = data['orders'] ?? [];
  
  // Access pharmacy name (checking multiple possible fields)
  final pharmacyName = order['pha_first_name']?.toString() ??
      order['pharmacy_name']?.toString() ??
      order['organization_name']?.toString() ??
      order['pha_name']?.toString() ??
      '';
}
```
















