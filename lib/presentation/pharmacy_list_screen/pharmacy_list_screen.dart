import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Add http package for API calls
import '../../core/config/app_config.dart';
import 'package:quikdawa_a3/presentation/dashboard_screen/dashboard_screen.dart';
import 'dart:convert'; // For parsing JSON
import 'package:shared_preferences/shared_preferences.dart';
import '../success_two_screen/success_two_screen.dart'; // Import the SignUpScreen
import 'package:flutter_rating_bar/flutter_rating_bar.dart';

class PharmacyListScreen extends StatefulWidget {
  PharmacyListScreen({Key? key}) : super(key: key);

  @override
  _PharmacyListScreenState createState() => _PharmacyListScreenState();
}

class _PharmacyListScreenState extends State<PharmacyListScreen> {
  TextEditingController searchController = TextEditingController();
  List<dynamic> pharmacies = []; // Store pharmacy data
  List<int> selectedPharmacyIds = []; // Track selected pharmacy IDs
  bool isLoading = true; // Track loading state
  String pharmacyid = "";
  List<dynamic> filteredPharmacies = [];
  List<Map<String, String>> labmedicines = [];

  @override
  void initState() {
    super.initState();
    fetchPharmacies();
    searchController.addListener(
      _filterPharmacies,
    ); // Fetch pharmacy data when the screen is loaded
  }

  Future<void> fetchPharmacies() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? action_value = prefs.getString('action_value');
      if (action_value != null) {
        pharmacyid = action_value.toString();
      } else {
        pharmacyid = "0";
      }
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('get_pharmacy')),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'phid': pharmacyid.toString()},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          // Debug: Print first pharmacy to verify org_organization_name is present
          if (data['data'].isNotEmpty) {
            print('First pharmacy data: ${data['data'][0]}');
            print(
              'org_organization_name: ${data['data'][0]['org_organization_name']}',
            );
          }
          setState(() {
            pharmacies = data['data'];
            filteredPharmacies = pharmacies;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          _showError("Failed to fetch pharmacy data.");
        }
      } else {
        setState(() {
          isLoading = false;
        });
        _showError("Failed to fetch pharmacies. Please try again.");
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      _showError("An error occurred: $error");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(message)));
  }

  void _togglePharmacySelection(int id) {
    setState(() {
      if (selectedPharmacyIds.contains(id)) {
        selectedPharmacyIds.remove(id); // Deselect if already selected
      } else {
        selectedPharmacyIds.add(id); // Add to selected list
      }
    });
  }

  String _getPharmacyDisplayName(Map<String, dynamic> pharmacy) {
    // Priority: org_organization_name > pha_first_name + pha_last_name
    // Check if org_organization_name exists and has a value
    final orgNameValue = pharmacy['org_organization_name'];

    // Debug print
    print('=== Pharmacy Display Name Check ===');
    print('org_organization_name value: $orgNameValue');
    print('org_organization_name type: ${orgNameValue?.runtimeType}');
    print('Full pharmacy data: $pharmacy');

    // Check if org_organization_name exists and is not null/empty
    if (orgNameValue != null) {
      String orgName = '';

      // Handle different types (String, int, etc.)
      if (orgNameValue is String) {
        orgName = orgNameValue.trim();
      } else {
        orgName = orgNameValue.toString().trim();
      }

      // Check if it's a valid non-empty string (not "null", not empty)
      if (orgName.isNotEmpty && orgName.toLowerCase() != 'null') {
        print('✓ RETURNING org_organization_name: "$orgName"');
        return orgName;
      } else {
        print('✗ org_organization_name is empty or "null": "$orgName"');
      }
    } else {
      print('✗ org_organization_name is null');
    }

    // Fallback to first_name + last_name
    final firstName = pharmacy['pha_first_name']?.toString().trim() ?? '';
    final lastName = pharmacy['pha_last_name']?.toString().trim() ?? '';
    final fullName = "$firstName $lastName".trim();
    final displayName = fullName.isNotEmpty
        ? fullName
        : firstName.isNotEmpty
            ? firstName
            : 'Unknown Pharmacy';
    print('✗ RETURNING fallback name: "$displayName"');
    print('===================================');
    return displayName;
  }

  void _filterPharmacies() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredPharmacies = pharmacies.where((pharmacy) {
        final displayName = _getPharmacyDisplayName(pharmacy).toLowerCase();
        final firstName =
            (pharmacy['pha_first_name'] ?? '').toString().toLowerCase();
        final lastName =
            (pharmacy['pha_last_name'] ?? '').toString().toLowerCase();
        final orgName =
            (pharmacy['org_organization_name'] ?? '').toString().toLowerCase();

        return displayName.contains(query) ||
            firstName.contains(query) ||
            lastName.contains(query) ||
            orgName.contains(query);
      }).toList();
    });
  }

  Future<void> _submitRequest() async {
    if (selectedPharmacyIds.isEmpty) {
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text("No pharmacies selected!")));
      return;
    }

    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? prescriptionData = prefs.getString('prescription');
      String? requestedMedicines = prefs.getString('medicines');
      String? symptoms = prefs.getString('symptoms');
      String? duration = prefs.getString('duration') ?? '';
      String? triggers = prefs.getString('triggers') ?? '';
      String? name = prefs.getString('name') ?? '';
      String? phone = prefs.getString('phone') ?? '';
      labmedicines = [
        {"medicine_name": "", "quantity": "1"},
      ];
      String? address = prefs.getString('address') ?? '';
      String? gender = prefs.getString('gender') ?? 'M';

      String? medicalHistory = prefs.getString('medicalHistory') ?? '';
      String? currentMedications = prefs.getString('currentMedications') ?? '';
      String? previousRemedies = prefs.getString('previousRemedies') ?? '';
      String? lifestyleFactors = prefs.getString('lifestyleFactors') ?? 'N';
      String? year = prefs.getString('year') ?? '';
      String? pregnancyStatus = prefs.getString('pregnancyStatus') ?? '';
      int? severity = prefs.getInt('severity');
      String? userDataString = prefs.getString('userData');
      String? filepath = prefs.getString('filepath');
      String? orignalfilepath = prefs.getString('orignalfilepath');
      String? prescriptionNumber = prefs.getString('prescription_number');

      String? mtype = prefs.getString('mtype');
      String orderType = '';
      String usertype = '';
      String? usr_id = '';
      String? doctor_id = '';
      String? lab_filepath = '';
      if (userDataString != null) {
        Map<String, dynamic> userData = json.decode(userDataString);
        usertype = userData['usr_user_type'].toString() ?? '';
        lab_filepath = prefs.getString('lab_report_file_path');

        if (usertype == 'healthcare_provider') {
          String? patientid = prefs.getString('patientid');

          usr_id = patientid.toString();
          doctor_id = userData['id'].toString();
        } else {
          usr_id = userData['id'].toString();
        }

        String? ordertype = prefs.getString('ordertype');
        if (ordertype != null) {
          orderType = jsonDecode(ordertype)['type'];
        }

        List<String> pharmacyIdsAsString =
            selectedPharmacyIds.map((id) => id.toString()).toList();

        Map<String, String> requestBody = {
          'pharmacy_id': pharmacyIdsAsString.join(','),
          'ordertype': orderType,
          'usr_id': usr_id?.toString() ?? '',
          'doctor_id': doctor_id?.toString() ?? '',
          'lab_filepath': lab_filepath?.toString() ?? '',
        };

        if (mtype != '2') {
          requestBody['pname'] = name ?? "";
          requestBody['address'] = address ?? "";
          requestBody['phone'] = phone ?? "";
          requestBody['gender'] = gender ?? "";
        }
        String apiUrl = '';

        if (mtype == '1') {
          // Handle symptoms submission only, no request ID
          apiUrl = AppConfig.buildApiUrl('submit_symptoms');
          requestBody['symptoms'] = symptoms ?? "";
          requestBody['duration'] = duration ?? "";
          requestBody['triggers'] = triggers ?? "";
          requestBody['medicalHistory'] = medicalHistory ?? "";
          requestBody['currentMedications'] = currentMedications ?? "";
          requestBody['previousRemedies'] = previousRemedies ?? "";
          requestBody['lifestyleFactors'] = lifestyleFactors ?? "";
          requestBody['mds_year'] = year ?? "";
          requestBody['mds_safety'] = pregnancyStatus ?? "";
          requestBody['mds_severity'] = severity?.toString() ?? "";

          final response = await http.post(
            Uri.parse(apiUrl),
            headers: {'Content-Type': 'application/x-www-form-urlencoded'},
            body: requestBody,
          );

          if (response.statusCode == 200) {
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(
                  "Symptoms Submitted and Request sent to Successfully!",
                ),
              ),
            );

            Navigator.push(
              context,
              MaterialPageRoute(builder: (context) => DashboardScreen()),
            );
          } else {
            _showError("Failed to submit symptoms. Please try again.");
          }

          return; // Stop execution here (no request ID needed)
        } else if (mtype == '3') {
          apiUrl = AppConfig.buildApiUrl('choose_pharmacy');
          requestBody['prescriptions'] = jsonEncode(
            labmedicines,
          ); // 🔥 this is important
          requestBody['requesttype'] = "Labreport";
        } else if (mtype == '0') {
          apiUrl = AppConfig.buildApiUrl('choose_pharmacy');
          requestBody['prescriptions'] = requestedMedicines ?? "";
          requestBody['requesttype'] = "Manual";
        } else if (mtype == '2') {
          // print(requestBody);
          apiUrl = AppConfig.buildApiUrl('choose_pharmacy');
          requestBody['pre_image'] = filepath ?? "";
          requestBody['orignalfilepath'] = orignalfilepath ?? "";
          requestBody['prescriptions'] = prescriptionData ?? "";
          requestBody['requesttype'] = "Scan";
          // Include prescription number for written prescriptions
          if (prescriptionNumber != null && prescriptionNumber.isNotEmpty) {
            requestBody['prescription_number'] = prescriptionNumber;
          }
        }

        // Send request
        final response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: requestBody,
        );
        print(response.body);
        if (response.statusCode == 200) {
          var responseData = jsonDecode(response.body);
          var request_id = responseData['request_id'];
          await prefs.setString('request_id', jsonEncode(request_id));
          await prefs.setString('scantype', "");

          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Request Submitted Successfully!")),
          );

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => SuccessTwoScreen()),
          );

          setState(() {
            selectedPharmacyIds.clear();
          });
        } else {
          _showError("Failed to submit request. Please try again.");
        }
      }
    } catch (error) {
      _showError("An error occurred: $error");
    }
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Select Pharmacy",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: Color(0XFF4675C0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${filteredPharmacies.length} pharmacies",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0XFF4675C0).withValues(alpha: 0.05),
              Colors.grey[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 16.0),
              _buildEnhancedSearchSection(),
              SizedBox(height: 20.0),
              Expanded(
                child: isLoading
                    ? _buildLoadingState()
                    : filteredPharmacies.isEmpty
                        ? _buildEmptyState()
                        : _buildEnhancedPharmacyList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedSearchSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey[600], size: 20),
            SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search pharmacies...",
                  hintStyle: TextStyle(color: Colors.grey[500], fontSize: 14),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 12),
                ),
                style: TextStyle(fontSize: 14),
              ),
            ),
            if (searchController.text.isNotEmpty)
              GestureDetector(
                onTap: () {
                  searchController.clear();
                },
                child: Icon(Icons.clear, color: Colors.grey[600], size: 20),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0XFF4675C0)),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Loading pharmacies...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please wait while we fetch available pharmacies',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.local_pharmacy_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No pharmacies found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: TextStyle(fontSize: 14, color: Colors.grey[600]),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedPharmacyList() {
    return Column(
      children: [
        Expanded(
          child: ListView.builder(
            itemCount: filteredPharmacies.length,
            padding: EdgeInsets.symmetric(horizontal: 16),
            itemBuilder: (context, index) {
              final pharmacy = filteredPharmacies[index];
              final isSelected = selectedPharmacyIds.contains(
                pharmacy['usr_id'],
              );
              final int totalUsers = (pharmacy['totaluser'] ?? 0);
              final double rating = (totalUsers > 0)
                  ? (pharmacy['pharmacy_rating'] ?? 0) / totalUsers
                  : 0.0;

              return Container(
                margin: EdgeInsets.only(bottom: 12),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  border: isSelected
                      ? Border.all(color: Color(0XFF4675C0), width: 2)
                      : null,
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withValues(alpha: 0.08),
                      blurRadius: 12,
                      offset: Offset(0, 4),
                      spreadRadius: 0,
                    ),
                  ],
                ),
                child: Material(
                  color: Colors.transparent,
                  child: InkWell(
                    borderRadius: BorderRadius.circular(16),
                    onTap: () {
                      _togglePharmacySelection(pharmacy['usr_id']);
                    },
                    child: Padding(
                      padding: EdgeInsets.all(16),
                      child: Row(
                        children: [
                          // Selection indicator
                          Container(
                            width: 24,
                            height: 24,
                            decoration: BoxDecoration(
                              shape: BoxShape.circle,
                              border: Border.all(
                                color: isSelected
                                    ? Color(0XFF4675C0)
                                    : Colors.grey[400]!,
                                width: 2,
                              ),
                              color: isSelected
                                  ? Color(0XFF4675C0)
                                  : Colors.transparent,
                            ),
                            child: isSelected
                                ? Icon(
                                    Icons.check,
                                    color: Colors.white,
                                    size: 16,
                                  )
                                : null,
                          ),
                          SizedBox(width: 16),

                          // Pharmacy icon
                          Container(
                            width: 50,
                            height: 50,
                            decoration: BoxDecoration(
                              color: Color(0XFF4675C0).withValues(alpha: 0.1),
                              borderRadius: BorderRadius.circular(12),
                            ),
                            child: Icon(
                              Icons.local_pharmacy_outlined,
                              color: Color(0XFF4675C0),
                              size: 24,
                            ),
                          ),
                          SizedBox(width: 16),

                          // Pharmacy details
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  _getPharmacyDisplayName(pharmacy),
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.w600,
                                    color: Colors.grey[800],
                                  ),
                                ),
                                SizedBox(height: 4),
                                if (pharmacy['pha_license_number'] != null &&
                                    pharmacy['pha_license_number']
                                        .toString()
                                        .isNotEmpty)
                                  Text(
                                    "License: ${pharmacy['pha_license_number']}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                if (pharmacy['pha_alt_phone_number'] != null &&
                                    pharmacy['pha_alt_phone_number']
                                        .toString()
                                        .isNotEmpty)
                                  Text(
                                    "Phone: ${pharmacy['pha_alt_phone_number']}",
                                    style: TextStyle(
                                      fontSize: 12,
                                      color: Colors.grey[600],
                                    ),
                                  ),
                                SizedBox(height: 8),
                                Row(
                                  children: [
                                    RatingBarIndicator(
                                      rating: rating,
                                      itemBuilder: (context, index) =>
                                          Icon(Icons.star, color: Colors.amber),
                                      itemCount: 5,
                                      itemSize: 16.0,
                                      direction: Axis.horizontal,
                                    ),
                                    SizedBox(width: 8),
                                    Text(
                                      rating.toStringAsFixed(1),
                                      style: TextStyle(
                                        fontSize: 12,
                                        fontWeight: FontWeight.w500,
                                        color: Colors.grey[700],
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              );
            },
          ),
        ),

        // Submit Button
        Container(
          padding: EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: Colors.white,
            boxShadow: [
              BoxShadow(
                color: Colors.black.withValues(alpha: 0.1),
                blurRadius: 10,
                offset: Offset(0, -2),
              ),
            ],
          ),
          child: SafeArea(
            child: SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed:
                    selectedPharmacyIds.isNotEmpty ? _submitRequest : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: Color(0XFF4675C0),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  elevation: 0,
                ),
                child: Text(
                  "Submit Request (${selectedPharmacyIds.length} selected)",
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),
          ),
        ),
      ],
    );
  }
}
