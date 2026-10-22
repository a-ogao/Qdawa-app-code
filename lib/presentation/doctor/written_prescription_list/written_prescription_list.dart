import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'prescription_detail_screen.dart';

class WrittenPrescriptionListScreen extends StatefulWidget {
  const WrittenPrescriptionListScreen({Key? key}) : super(key: key);

  @override
  _WrittenPrescriptionListScreenState createState() =>
      _WrittenPrescriptionListScreenState();
}

class _WrittenPrescriptionListScreenState
    extends State<WrittenPrescriptionListScreen> {
  TextEditingController searchController = TextEditingController();
  List<dynamic> prescriptions = [];
  List<dynamic> filteredPrescriptions = [];
  bool isLoading = true;
  String? errorMessage;
  String? doctorId;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
    // Listen to search text changes
    searchController.addListener(_filterPrescriptions);
  }

  void _filterPrescriptions() {
    final query = searchController.text.toLowerCase();
    setState(() {
      filteredPrescriptions = prescriptions.where((prescription) {
        final prescriptionNumber =
            prescription['pre_prescription_number']?.toString().toLowerCase() ??
                '';
        final patientName =
            prescription['pre_patient_name']?.toString().toLowerCase() ?? '';
        final patientGender =
            prescription['pre_patient_gender']?.toString().toLowerCase() ?? '';
        final createdDate =
            prescription['pre_created_dt']?.toString().toLowerCase() ?? '';
        return prescriptionNumber.contains(query) ||
            patientName.contains(query) ||
            patientGender.contains(query) ||
            createdDate.contains(query);
      }).toList();
    });
  }

  @override
  void dispose() {
    searchController.dispose();
    super.dispose();
  }

  Future<void> _loadDoctorData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('userData');

    if (userDataString != null) {
      try {
        Map<String, dynamic> userData = json.decode(userDataString);
        doctorId = userData['id']?.toString();
        print("👨‍⚕️ Doctor ID loaded: $doctorId");

        if (doctorId != null) {
          await _fetchPrescriptions();
        } else {
          setState(() {
            isLoading = false;
            errorMessage = 'Doctor ID not found';
          });
        }
      } catch (e) {
        print("❌ Error loading doctor data: $e");
        setState(() {
          isLoading = false;
          errorMessage = 'Error loading doctor data';
        });
      }
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'User data not available';
      });
    }
  }

  Future<void> _fetchPrescriptions() async {
    if (doctorId == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print("\n📋 === FETCHING DOCTOR PRESCRIPTIONS ===");
      print("API URL: ${AppConfig.buildApiUrl('fetchDoctorPrescriptions')}");
      print("Doctor ID: $doctorId");

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('fetchDoctorPrescriptions')),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({'user_id': doctorId}),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("=== END FETCHING PRESCRIPTIONS ===\n");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          setState(() {
            prescriptions = data['data'] ?? [];
            filteredPrescriptions = prescriptions;
            isLoading = false;
          });
          print("✅ Loaded ${prescriptions.length} prescriptions");
        } else {
          setState(() {
            isLoading = false;
            errorMessage = data['message'] ?? 'Failed to load prescriptions';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      print("❌ Error fetching prescriptions: $e");
      setState(() {
        isLoading = false;
        errorMessage = 'Network error: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0XFF4675C0),
        elevation: 0,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
        title: Text(
          'Written Prescriptions',
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${filteredPrescriptions.length} prescriptions",
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
              Color(0XFF4675C0).withOpacity(0.05),
              Colors.grey[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 16),
              _buildEnhancedSearchSection(),
              SizedBox(height: 20),
              // Content
              Expanded(
                child: isLoading
                    ? Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            CircularProgressIndicator(
                              valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0XFF4675C0)),
                            ),
                            SizedBox(height: 16),
                            Text(
                              'Loading prescriptions...',
                              style: TextStyle(
                                color: Colors.grey[600],
                                fontSize: 14,
                              ),
                            ),
                          ],
                        ),
                      )
                    : errorMessage != null
                        ? Center(
                            child: Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.error_outline,
                                  size: 64,
                                  color: Colors.red[300],
                                ),
                                SizedBox(height: 16),
                                Text(
                                  errorMessage!,
                                  textAlign: TextAlign.center,
                                  style: TextStyle(
                                    color: Colors.grey[600],
                                    fontSize: 16,
                                  ),
                                ),
                                SizedBox(height: 16),
                                ElevatedButton(
                                  onPressed: _fetchPrescriptions,
                                  style: ElevatedButton.styleFrom(
                                    backgroundColor: Color(0XFF4675C0),
                                    padding: EdgeInsets.symmetric(
                                      horizontal: 24,
                                      vertical: 12,
                                    ),
                                  ),
                                  child: Text('Retry'),
                                ),
                              ],
                            ),
                          )
                        : filteredPrescriptions.isEmpty
                            ? Center(
                                child: Column(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    Icon(
                                      Icons.description_outlined,
                                      size: 64,
                                      color: Colors.grey[400],
                                    ),
                                    SizedBox(height: 16),
                                    Text(
                                      'No prescriptions written yet',
                                      style: TextStyle(
                                        color: Colors.grey[600],
                                        fontSize: 16,
                                      ),
                                    ),
                                  ],
                                ),
                              )
                            : RefreshIndicator(
                                onRefresh: _fetchPrescriptions,
                                color: Color(0XFF4675C0),
                                child: ListView.builder(
                                  padding: EdgeInsets.symmetric(vertical: 12),
                                  itemCount: filteredPrescriptions.length,
                                  itemBuilder: (context, index) {
                                    final prescription =
                                        filteredPrescriptions[index];
                                    return _buildPrescriptionCard(prescription);
                                  },
                                ),
                              ),
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
            color: Colors.black.withOpacity(0.08),
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
            Icon(
              Icons.search,
              color: Colors.grey[600],
              size: 24,
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search prescriptions...',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding: EdgeInsets.symmetric(vertical: 14),
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ),
            if (searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(
                  Icons.clear,
                  color: Colors.grey[600],
                  size: 20,
                ),
                onPressed: () {
                  searchController.clear();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionCard(Map<String, dynamic> prescription) {
    String prescriptionNumber =
        prescription['pre_prescription_number']?.toString() ?? 'N/A';
    String patientName =
        prescription['pre_patient_name']?.toString() ?? 'Unknown';
    String patientGender = prescription['pre_patient_gender']?.toString() ?? '';
    String patientAge = prescription['pre_patient_age']?.toString() ?? '';
    String createdDate = prescription['pre_created_dt']?.toString() ?? '';

    // Format date
    String formattedDate = '';
    if (createdDate.isNotEmpty) {
      try {
        DateTime date = DateTime.parse(createdDate);
        formattedDate =
            '${date.day}/${date.month}/${date.year} ${date.hour}:${date.minute.toString().padLeft(2, '0')}';
      } catch (e) {
        formattedDate = createdDate.split(' ')[0];
      }
    }

    return GestureDetector(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PrescriptionDetailScreen(
              prescriptionId: prescription['id'].toString(),
            ),
          ),
        );
      },
      child: Container(
        margin: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 16,
              offset: Offset(0, 4),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Padding(
          padding: EdgeInsets.all(20),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Left side - Prescription info
              Expanded(
                flex: 3,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Prescription number with badge
                    Row(
                      children: [
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: Color(0XFF4675C0).withOpacity(0.1),
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            prescriptionNumber,
                            style: TextStyle(
                              color: Color(0XFF4675C0),
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),

                    SizedBox(height: 12),

                    // Patient name
                    if (patientName.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.person_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              patientName,
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Colors.black87,
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),

                    if (patientName.isNotEmpty) SizedBox(height: 8),

                    // Patient details (gender, age)
                    if (patientGender.isNotEmpty || patientAge.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.info_outline,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              '${patientGender.isNotEmpty ? patientGender : ''}'
                              '${patientGender.isNotEmpty && patientAge.isNotEmpty ? ', ' : ''}'
                              '${patientAge.isNotEmpty ? '$patientAge years' : ''}',
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),

                    if (patientGender.isNotEmpty || patientAge.isNotEmpty)
                      SizedBox(height: 8),

                    // Date info
                    if (formattedDate.isNotEmpty)
                      Row(
                        children: [
                          Icon(
                            Icons.calendar_today_outlined,
                            size: 16,
                            color: Colors.grey[600],
                          ),
                          SizedBox(width: 8),
                          Expanded(
                            child: Text(
                              formattedDate,
                              style: TextStyle(
                                fontSize: 14,
                                color: Colors.grey[700],
                                fontWeight: FontWeight.w500,
                              ),
                            ),
                          ),
                        ],
                      ),
                  ],
                ),
              ),

              SizedBox(width: 16),

              // Right side - View button only
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.end,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    // View details button
                    GestureDetector(
                      onTap: () {
                        Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => PrescriptionDetailScreen(
                              prescriptionId: prescription['id'].toString(),
                            ),
                          ),
                        );
                      },
                      child: Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                        decoration: BoxDecoration(
                          color: Color(0XFF4675C0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: Color(0XFF4675C0).withOpacity(0.3),
                            width: 1,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Icon(
                              Icons.visibility_outlined,
                              size: 16,
                              color: Color(0XFF4675C0),
                            ),
                            SizedBox(width: 6),
                            Text(
                              'View',
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: Color(0XFF4675C0),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
