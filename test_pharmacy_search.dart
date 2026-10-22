import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Searching for pharmacy: kerichpharmaceuticalslimited@gmail.com\n');
  
  try {
    final url = 'https://quikdawa.com/QdawaAPIs/public/index.php/get_pharmacy';
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'phid': '0'}, // Get all pharmacies
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      
      if (data['success'] == true && data['data'] != null) {
        final pharmacies = data['data'] as List;
        
        print('📊 Total Pharmacies in System: ${pharmacies.length}\n');
        
        // Search for the specific email
        final searchEmail = 'kerichpharmaceuticalslimited@gmail.com';
        final foundPharmacy = pharmacies.firstWhere(
          (pharmacy) => (pharmacy['usr_email'] as String?)?.toLowerCase() == searchEmail.toLowerCase(),
          orElse: () => null,
        );
        
        if (foundPharmacy != null) {
          print('✅ FOUND PHARMACY!\n');
          print('📋 Pharmacy Details:');
          print('─' * 80);
          foundPharmacy.forEach((key, value) {
            print('  $key: $value');
          });
          print('─' * 80);
          
          print('\n📝 Formatted Details:');
          print('  ID: ${foundPharmacy['usr_id']}');
          print('  Username: ${foundPharmacy['usr_username']}');
          print('  Email: ${foundPharmacy['usr_email']}');
          print('  Mobile: ${foundPharmacy['usr_mobile_number']}');
          print('  Name: ${foundPharmacy['pha_first_name'] ?? ''} ${foundPharmacy['pha_last_name'] ?? ''}'.trim());
          print('  Organization: ${foundPharmacy['org_organization_name'] ?? 'N/A'}');
          print('  License: ${foundPharmacy['pha_license_number'] ?? 'N/A'}');
          print('  Alt Phone: ${foundPharmacy['pha_alt_phone_number'] ?? 'N/A'}');
          print('  Rating: ${foundPharmacy['pharmacy_rating']}');
          print('  Total Users: ${foundPharmacy['totaluser']}');
        } else {
          print('❌ Pharmacy NOT FOUND in current results\n');
          print('📋 All Available Pharmacies:');
          print('─' * 80);
          for (int i = 0; i < pharmacies.length; i++) {
            final pharmacy = pharmacies[i];
            print('\n${i + 1}. ${pharmacy['org_organization_name'] ?? pharmacy['pha_first_name'] ?? 'Unknown'}');
            print('   Email: ${pharmacy['usr_email']}');
            print('   ID: ${pharmacy['usr_id']}');
          }
          print('─' * 80);
          
          print('\n💡 Possible reasons:');
          print('  - Pharmacy may not be registered in the system');
          print('  - Pharmacy may be filtered out (check phid parameter)');
          print('  - Pharmacy may be inactive or deleted');
          print('  - Email may be different in the system');
        }
      }
    } else {
      print('❌ API request failed: ${response.statusCode}');
    }
  } catch (error) {
    print('❌ Error: $error');
  }
}


