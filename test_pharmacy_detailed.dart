import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Detailed Pharmacy API Test - After API Changes\n');
  print('=' * 80);
  
  try {
    final url = 'https://quikdawa.com/QdawaAPIs/public/index.php/get_pharmacy';
    
    print('📤 Request Details:');
    print('  URL: $url');
    print('  Method: POST');
    print('  Body: phid=0');
    print('  Headers: Content-Type: application/x-www-form-urlencoded\n');
    
    final stopwatch = Stopwatch()..start();
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'phid': '0'},
    );
    stopwatch.stop();
    
    print('📥 Response Details:');
    print('  Status Code: ${response.statusCode}');
    print('  Response Time: ${stopwatch.elapsedMilliseconds}ms');
    print('  Response Size: ${response.body.length} bytes (~${(response.body.length / 1024).toStringAsFixed(2)} KB)');
    print('  Response Headers: ${response.headers}\n');
    
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        
        print('✅ JSON Parsed Successfully\n');
        print('📊 Response Structure:');
        print('  - success: ${data['success']}');
        print('  - data type: ${data['data'].runtimeType}');
        
        if (data['data'] != null) {
          final pharmacies = data['data'] as List;
          print('  - data length: ${pharmacies.length}\n');
          
          print('📋 All Pharmacies (${pharmacies.length} total):');
          print('=' * 80);
          
          for (int i = 0; i < pharmacies.length; i++) {
            final pharmacy = pharmacies[i];
            print('\n[${i + 1}] Pharmacy ID: ${pharmacy['usr_id']}');
            print('    Username: ${pharmacy['usr_username']}');
            print('    Email: ${pharmacy['usr_email']}');
            print('    Organization: ${pharmacy['org_organization_name'] ?? 'N/A'}');
            print('    Name: ${pharmacy['pha_first_name'] ?? ''} ${pharmacy['pha_last_name'] ?? ''}'.trim());
            print('    Mobile: ${pharmacy['usr_mobile_number']}');
            print('    License: ${pharmacy['pha_license_number'] ?? 'N/A'}');
          }
          
          // Search for Kerich
          print('\n\n🔍 Searching for "kerichpharmaceuticalslimited@gmail.com":');
          print('=' * 80);
          
          final searchEmail = 'kerichpharmaceuticalslimited@gmail.com'.toLowerCase();
          var found = false;
          
          for (var pharmacy in pharmacies) {
            final email = (pharmacy['usr_email'] as String?)?.toLowerCase() ?? '';
            final username = (pharmacy['usr_username'] as String?)?.toLowerCase() ?? '';
            final orgName = (pharmacy['org_organization_name'] as String?)?.toLowerCase() ?? '';
            final firstName = (pharmacy['pha_first_name'] as String?)?.toLowerCase() ?? '';
            
            if (email.contains('kerich') || 
                username.contains('kerich') ||
                orgName.contains('kerich') ||
                firstName.contains('kerich') ||
                email == searchEmail) {
              found = true;
              print('\n✅ FOUND MATCH!');
              print('   ID: ${pharmacy['usr_id']}');
              print('   Email: ${pharmacy['usr_email']}');
              print('   Username: ${pharmacy['usr_username']}');
              print('   Organization: ${pharmacy['org_organization_name']}');
              print('   Name: ${pharmacy['pha_first_name']} ${pharmacy['pha_last_name']}');
              break;
            }
          }
          
          if (!found) {
            print('❌ NOT FOUND in current response');
            print('\n💡 Checking for similar matches...');
            
            var similarFound = false;
            for (var pharmacy in pharmacies) {
              final email = (pharmacy['usr_email'] as String?)?.toLowerCase() ?? '';
              final orgName = (pharmacy['org_organization_name'] as String?)?.toLowerCase() ?? '';
              
              if (email.contains('pharmaceutical') || orgName.contains('pharmaceutical')) {
                similarFound = true;
                print('   - ${pharmacy['org_organization_name']} (${pharmacy['usr_email']})');
              }
            }
            
            if (!similarFound) {
              print('   No pharmaceutical companies found');
            }
          }
          
          print('\n\n📝 Raw JSON Response (first 2000 chars):');
          print('=' * 80);
          final jsonString = jsonEncode(data);
          print(jsonString.length > 2000 ? jsonString.substring(0, 2000) + '...' : jsonString);
          
        } else {
          print('⚠️  data field is null');
        }
      } catch (e) {
        print('❌ Error parsing JSON: $e');
        print('\nRaw response (first 1000 chars):');
        print(response.body.length > 1000 ? response.body.substring(0, 1000) + '...' : response.body);
      }
    } else {
      print('❌ Request failed with status: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (error) {
    print('❌ Error: $error');
  }
  
  print('\n' + '=' * 80);
}


