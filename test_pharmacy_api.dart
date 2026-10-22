import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Testing get_pharmacy API...\n');
  
  // Test with phid=0 (all pharmacies)
  await testPharmacyAPI('0', 'All Pharmacies');
  
  print('\n' + '='*80 + '\n');
  
  // Test with a specific pharmacy ID (if you have one)
  // Uncomment and replace with actual pharmacy ID if needed
  // await testPharmacyAPI('123', 'Specific Pharmacy ID: 123');
}

Future<void> testPharmacyAPI(String phid, String testName) async {
  print('📋 Test: $testName');
  print('Request: phid=$phid\n');
  
  try {
    final url = 'https://quikdawa.com/QdawaAPIs/public/index.php/get_pharmacy';
    
    print('🌐 URL: $url');
    print('📤 Sending POST request...\n');
    
    final response = await http.post(
      Uri.parse(url),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {'phid': phid},
    );

    print('📥 Response Status Code: ${response.statusCode}');
    print('📏 Response Body Length: ${response.body.length} characters\n');
    
    if (response.statusCode == 200) {
      try {
        final data = jsonDecode(response.body);
        
        print('✅ Success: ${data['success']}');
        
        if (data['data'] != null) {
          final pharmacies = data['data'] as List;
          print('📊 Total Pharmacies Returned: ${pharmacies.length}\n');
          
          if (pharmacies.isNotEmpty) {
            print('📝 First Pharmacy Details:');
            print('─' * 80);
            final firstPharmacy = pharmacies[0];
            firstPharmacy.forEach((key, value) {
              print('  $key: $value');
            });
            print('─' * 80);
            
            if (pharmacies.length > 1) {
              print('\n📝 Sample of Additional Pharmacies:');
              final sampleSize = pharmacies.length > 5 ? 5 : pharmacies.length;
              for (int i = 1; i < sampleSize; i++) {
                print('\n  Pharmacy ${i + 1}:');
                print('    ID: ${pharmacies[i]['usr_id']}');
                print('    Name: ${pharmacies[i]['pha_first_name'] ?? ''} ${pharmacies[i]['pha_last_name'] ?? ''}');
                print('    Organization: ${pharmacies[i]['org_organization_name'] ?? 'N/A'}');
                print('    License: ${pharmacies[i]['pha_license_number'] ?? 'N/A'}');
              }
              
              if (pharmacies.length > 5) {
                print('\n  ... and ${pharmacies.length - 5} more pharmacies');
              }
            }
            
            // Analyze response structure
            print('\n📊 Response Analysis:');
            print('─' * 80);
            print('  Total Items: ${pharmacies.length}');
            print('  Response Size: ~${(response.body.length / 1024).toStringAsFixed(2)} KB');
            
            // Check for common fields
            final sample = pharmacies[0];
            print('\n  Available Fields:');
            sample.keys.forEach((key) {
              print('    - $key');
            });
            
            // Check for limits
            print('\n  ⚠️  Limit Analysis:');
            print('    - No pagination parameters sent');
            print('    - No limit parameter in request');
            print('    - All ${pharmacies.length} pharmacies returned in single response');
            if (pharmacies.length > 100) {
              print('    - ⚠️  WARNING: Large dataset (${pharmacies.length} items) may impact performance');
            }
          } else {
            print('⚠️  No pharmacies found in response');
          }
        } else {
          print('⚠️  Response data is null');
          print('Full response: ${jsonEncode(data)}');
        }
      } catch (e) {
        print('❌ Error parsing JSON: $e');
        print('Raw response (first 500 chars): ${response.body.substring(0, response.body.length > 500 ? 500 : response.body.length)}');
      }
    } else {
      print('❌ Request failed with status code: ${response.statusCode}');
      print('Response body: ${response.body}');
    }
  } catch (error) {
    print('❌ Error making request: $error');
  }
}


