import 'dart:convert';
import 'package:http/http.dart' as http;

void main() async {
  print('🔍 Searching for Kerich Pharmaceuticals with different parameters...\n');
  
  final searchEmail = 'kerichpharmaceuticalslimited@gmail.com';
  
  // Try different phid values
  final testCases = [
    {'phid': '0', 'description': 'All pharmacies (phid=0)'},
    {'phid': '', 'description': 'Empty phid'},
    // Try some common IDs
    {'phid': '1', 'description': 'phid=1'},
    {'phid': '10', 'description': 'phid=10'},
    {'phid': '20', 'description': 'phid=20'},
    {'phid': '30', 'description': 'phid=30'},
  ];
  
  for (var testCase in testCases) {
    print('📋 Testing: ${testCase['description']}');
    print('─' * 80);
    
    try {
      final url = 'https://quikdawa.com/QdawaAPIs/public/index.php/get_pharmacy';
      
      final response = await http.post(
        Uri.parse(url),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'phid': testCase['phid']!},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        
        if (data['success'] == true && data['data'] != null) {
          final pharmacies = data['data'] as List;
          
          print('  Found ${pharmacies.length} pharmacies');
          
          // Search for the email (case-insensitive)
          final found = pharmacies.where((pharmacy) {
            final email = (pharmacy['usr_email'] as String?)?.toLowerCase() ?? '';
            final username = (pharmacy['usr_username'] as String?)?.toLowerCase() ?? '';
            final orgName = (pharmacy['org_organization_name'] as String?)?.toLowerCase() ?? '';
            final firstName = (pharmacy['pha_first_name'] as String?)?.toLowerCase() ?? '';
            
            return email.contains('kerich') || 
                   username.contains('kerich') ||
                   orgName.contains('kerich') ||
                   firstName.contains('kerich');
          }).toList();
          
          if (found.isNotEmpty) {
            print('  ✅ FOUND MATCHING PHARMACY!\n');
            found.forEach((pharmacy) {
              print('    ID: ${pharmacy['usr_id']}');
              print('    Email: ${pharmacy['usr_email']}');
              print('    Username: ${pharmacy['usr_username']}');
              print('    Organization: ${pharmacy['org_organization_name'] ?? 'N/A'}');
              print('    Name: ${pharmacy['pha_first_name'] ?? ''} ${pharmacy['pha_last_name'] ?? ''}'.trim());
              print('');
            });
            return; // Found it, exit
          } else {
            print('  ❌ Not found in this result set\n');
          }
        }
      } else {
        print('  ❌ Request failed: ${response.statusCode}\n');
      }
    } catch (error) {
      print('  ❌ Error: $error\n');
    }
  }
  
  print('\n📊 Summary:');
  print('─' * 80);
  print('❌ Pharmacy with email "$searchEmail" NOT FOUND in any test case');
  print('\n💡 This could mean:');
  print('  1. The pharmacy is not registered in the system');
  print('  2. The pharmacy account is inactive or deleted');
  print('  3. The pharmacy is filtered by user permissions/role');
  print('  4. The email address in the system is different');
  print('  5. The pharmacy requires a specific phid parameter to be visible');
  print('\n📝 Current pharmacies in system:');
  print('  - ST. JOHN PHARMACEUTICALS (Togo.joshua@gmail.com)');
  print('  - BINSINA PHARMACEUTICALS LTD (cao_720@gmail.com)');
  print('  - PHARMAPLUS LTD (paulnakitare08@gmail.com)');
  print('  - GoodLife Pharmacy (ao_360@yahoo.com)');
}


