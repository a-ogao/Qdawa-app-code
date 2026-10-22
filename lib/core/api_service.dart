import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import 'config/app_config.dart';

class ApiService {
  static final String baseUrl = AppConfig.baseApiUrl;

  // Medicine Suggestion API
  static Future<List<Map<String, dynamic>>> searchMedicines(
      String query) async {
    if (query.length < 3) {
      return [];
    }

    try {
      print("\n💊 === MEDICINE SEARCH API ===");
      print("Query: $query (${query.length} characters)");
      print("API: ${AppConfig.suggestionApiUrl}");

      final response = await http.post(
        Uri.parse(AppConfig.suggestionApiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          'medicine_name': query,
        },
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Handle different response formats
        List<Map<String, dynamic>> medicines = [];

        if (data is List) {
          medicines = List<Map<String, dynamic>>.from(data);
        } else if (data is Map && data['data'] != null) {
          medicines = List<Map<String, dynamic>>.from(data['data']);
        } else if (data is Map &&
            data['success'] == true &&
            data['medicines'] != null) {
          medicines = List<Map<String, dynamic>>.from(data['medicines']);
        }

        print("Found ${medicines.length} medicines");
        for (var med in medicines.take(3)) {
          print(
              "  - ${med['medicine_name'] ?? med['name']} (Route: ${med['route_category']})");
        }
        print("=== END MEDICINE SEARCH ===\n");

        return medicines;
      }
      return [];
    } catch (e) {
      print('❌ Error searching medicines: $e');
      return [];
    }
  }

  // Get Medicine Details
  static Future<Map<String, dynamic>?> getMedicineDetails(
      String medicineId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getMedicineDetails'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'medicine_id': medicineId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return data['data'];
        }
      }
      return null;
    } catch (e) {
      print('Error getting medicine details: $e');
      return null;
    }
  }

  // Submit Prescription
  static Future<Map<String, dynamic>> submitPrescription({
    required String doctorId,
    required String patientId,
    required List<Map<String, dynamic>> prescriptionItems,
    required String signature,
    required String prescriptionNumber,
    required Map<String, dynamic> patientData,
    String? notes,
  }) async {
    try {
      print("\n📋 === SUBMIT PRESCRIPTION API ===");
      print("API URL: ${AppConfig.buildApiUrl('writeprescription')}");
      print("Doctor ID: $doctorId");
      print("Patient ID: $patientId");
      print("Prescription Number: $prescriptionNumber");
      print("Prescription Items Count: ${prescriptionItems.length}");

      // Prepare the complete prescription data as JSON
      Map<String, dynamic> prescriptionData = {
        'doctor_id': doctorId,
        'patient_id': patientId,
        'prescription_number': prescriptionNumber,
        'patient_data': patientData,
        'prescription_items': prescriptionItems,
        'signature': signature,
        'notes': notes ?? '',
        'created_at': DateTime.now().toLocal().toString().split('.')[0],
      };

      print("Request Body (JSON): ${json.encode(prescriptionData)}");

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('writeprescription')),
        headers: {
          'Content-Type': 'application/json',
        },
        body: json.encode(prescriptionData),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("=== END SUBMIT PRESCRIPTION ===\n");

      if (response.statusCode == 200) {
        return json.decode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Failed to submit prescription',
          'error': 'HTTP ${response.statusCode}',
        };
      }
    } catch (e) {
      print('❌ Error submitting prescription: $e');
      return {
        'success': false,
        'message': 'Network error',
        'error': e.toString(),
      };
    }
  }

  // Search Patient by Phone Number
  static Future<List<Map<String, dynamic>>> searchPatientByPhone(
      String phoneNumber) async {
    try {
      print("\n👤 === PATIENT SEARCH API ===");
      print("Phone: $phoneNumber");
      print("API: ${AppConfig.searchPatientApiUrl}");

      final response = await http.get(
        Uri.parse('${AppConfig.searchPatientApiUrl}?search=$phoneNumber'),
        headers: {'Content-Type': 'application/json'},
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        // Check if it's an error message
        if (data is Map && data.containsKey('message')) {
          print("No patient found");
          print("=== END PATIENT SEARCH ===\n");
          return [];
        }

        // Handle array response
        if (data is List) {
          print("Found ${data.length} patients");
          print("=== END PATIENT SEARCH ===\n");
          return List<Map<String, dynamic>>.from(data);
        }

        // Handle single patient object
        if (data is Map) {
          print("Found 1 patient");
          print("=== END PATIENT SEARCH ===\n");
          return [Map<String, dynamic>.from(data)];
        }
      }

      print("No patients found");
      print("=== END PATIENT SEARCH ===\n");
      return [];
    } catch (e) {
      print('❌ Error searching patients: $e');
      return [];
    }
  }

  // Get Patient List for Doctor
  static Future<List<Map<String, dynamic>>> getPatientList(
      String doctorId) async {
    try {
      final response = await http.post(
        Uri.parse('$baseUrl/getPatientList'),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'doctor_id': doctorId},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data['success'] == true && data['data'] != null) {
          return List<Map<String, dynamic>>.from(data['data']);
        }
      }
      return [];
    } catch (e) {
      print('Error getting patient list: $e');
      return [];
    }
  }

  // Get Doctor Details
  static Future<Map<String, dynamic>?> getDoctorDetails(
      String userId) async {
    try {
      print("\n👨‍⚕️ === GET DOCTOR DETAILS API ===");
      print("API URL: ${AppConfig.buildApiUrl('api/get_doc_detail')}");
      print("usr_id: $userId");

      // Try to include the session token if available (for auth-protected endpoint)
      final prefs = await SharedPreferences.getInstance();
      final sessionToken = prefs.getString('sessionToken');

      final headers = <String, String>{
        'Content-Type': 'application/x-www-form-urlencoded',
        'Accept': 'application/json',
      };
      if (sessionToken != null && sessionToken.isNotEmpty) {
        headers['Authorization'] = 'Bearer $sessionToken';
      }

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('api/get_doc_detail')),
        headers: headers,
        body: {'usr_id': userId},
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");

      if (response.statusCode == 200) {
        final dynamic decoded = json.decode(response.body);

        // Handle common response shapes:
        // 1) { ...doctor fields... }
        // 2) { "success": true, "data": { ...doctor fields... } }
        // 3) { "success": true, "doctor": { ...doctor fields... } }
        if (decoded is Map<String, dynamic>) {
          if (decoded.containsKey('data') &&
              decoded['data'] is Map<String, dynamic>) {
            return decoded['data'] as Map<String, dynamic>;
          }
          if (decoded.containsKey('doctor') &&
              decoded['doctor'] is Map<String, dynamic>) {
            return decoded['doctor'] as Map<String, dynamic>;
          }
          // Fallback: return the whole map as-is
          return decoded;
        }

        print("❌ getDoctorDetails: unexpected JSON shape");
        return null;
      }
      print("❌ getDoctorDetails HTTP error ${response.statusCode}");
      return null;
    } catch (e) {
      print('Error getting doctor details: $e');
      return null;
    }
  }
}
