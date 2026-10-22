import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Testing get_pharmacy API - Full Response\n');
  
  try {
    final url = 'https://quikdawa.com/QdawaAPIs/public/index.php/get_pharmacy';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'phid': '0'},
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      print('✅ API Call Successful!\n');
      print('📊 Summary:');
      print('  - Status Code: ${response.statusCode}');
      print('  - Success: ${data['success']}');
      print('  - Total Pharmacies: ${(data['data'] as List).length}');
      print('  - Response Size: ${(response.body.length / 1024).toStringAsFixed(2)} KB\n');
      
      print('📄 Full JSON Response:');
      print('─' * 80);
      // Pretty print JSON
      final encoder = JsonEncoder.withIndent('  ');
      print(encoder.convert(data));
      print('─' * 80);
      
      print('\n📋 Detailed Pharmacy List:');
      print('─' * 80);
      final pharmacies = data['data'] as List;
      for (int i = 0; i < pharmacies.length; i++) {
        final pharmacy = pharmacies[i];
        print('\nPharmacy ${i + 1}:');
        print('  ID: ${pharmacy['usr_id']}');
        print('  Username: ${pharmacy['usr_username']}');
        print('  Email: ${pharmacy['usr_email']}');
        print('  Mobile: ${pharmacy['usr_mobile_number']}');
        print('  First Name: ${pharmacy['pha_first_name'] ?? 'N/A'}');
        print('  Last Name: ${pharmacy['pha_last_name'] ?? 'N/A'}');
        print('  Organization: ${pharmacy['org_organization_name'] ?? 'N/A'}');
        print('  License: ${pharmacy['pha_license_number'] ?? 'N/A'}');
        print('  Alt Phone: ${pharmacy['pha_alt_phone_number'] ?? 'N/A'}');
        print('  Rating: ${pharmacy['pharmacy_rating']}');
        print('  Total Users: ${pharmacy['totaluser']}');
      }
      
      print('\n\n🔍 Cache Analysis:');
      print('─' * 80);
      print('  ❌ No caching mechanism found in code');
      print('  ❌ Data not stored in SharedPreferences');
      print('  ❌ Data only stored in memory (lost on screen dispose)');
      print('  ✅ API call made fresh every time fetchPharmacies() is called');
      
      print('\n\n⚠️  Limit Analysis:');
      print('─' * 80);
      print('  ❌ No pagination parameters (limit, offset, page)');
      print('  ❌ No maximum limit enforced');
      print('  ✅ Currently returns ${pharmacies.length} pharmacies');
      print('  ⚠️  If pharmacy count grows, performance may degrade');
      
    } else {
      print('❌ Request failed with status code: ${response.statusCode}');
      print('Response: ${response.body}');
    }
  } catch (error) {
    print('❌ Error: $error');
  }
}


