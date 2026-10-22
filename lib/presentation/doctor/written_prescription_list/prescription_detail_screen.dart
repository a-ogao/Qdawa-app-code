import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'dart:typed_data';
import 'dart:ui' as ui;
import 'package:shared_preferences/shared_preferences.dart';

class PrescriptionDetailScreen extends StatefulWidget {
  final String prescriptionId;

  const PrescriptionDetailScreen({
    Key? key,
    required this.prescriptionId,
  }) : super(key: key);

  @override
  _PrescriptionDetailScreenState createState() =>
      _PrescriptionDetailScreenState();
}

class _PrescriptionDetailScreenState extends State<PrescriptionDetailScreen> {
  Map<String, dynamic>? prescriptionData;
  bool isLoading = true;
  String? errorMessage;

  @override
  void initState() {
    super.initState();
    _fetchPrescriptionDetails();
  }

  Future<void> _fetchPrescriptionDetails() async {
    try {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });

      // Get doctor ID from SharedPreferences
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? userDataString = prefs.getString('userData');

      if (userDataString == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'User data not available';
        });
        return;
      }

      Map<String, dynamic> userData = json.decode(userDataString);
      String? doctorId = userData['id']?.toString();

      if (doctorId == null) {
        setState(() {
          isLoading = false;
          errorMessage = 'Doctor ID not found';
        });
        return;
      }

      print("\n📋 === FETCHING PRESCRIPTION DETAILS ===");
      print("API URL: ${AppConfig.buildApiUrl('writeprescriptionview')}");
      print("Doctor ID: $doctorId");
      print("Prescription ID: ${widget.prescriptionId}");

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('writeprescriptionview')),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'user_id': doctorId,
          'prescription_id': widget.prescriptionId,
        }),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("=== END FETCHING PRESCRIPTION DETAILS ===\n");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true) {
          setState(() {
            prescriptionData = data['data'];
            isLoading = false;
          });
          print("✅ Loaded prescription details successfully");
          print("📝 Signature data: ${data['data']['pre_signature']}");
          print(
              "📝 Signature type: ${data['data']['pre_signature']?.runtimeType}");
          print(
              "📝 Signature length: ${data['data']['pre_signature']?.toString().length}");
        } else {
          setState(() {
            isLoading = false;
            errorMessage =
                data['message'] ?? 'Failed to load prescription details';
          });
        }
      } else {
        setState(() {
          isLoading = false;
          errorMessage = 'Server error: ${response.statusCode}';
        });
      }
    } catch (e) {
      print("❌ Error fetching prescription details: $e");
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
        title: Text(
          "Prescription Details",
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
          onPressed: () => Navigator.pop(context),
        ),
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
          child: isLoading
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      CircularProgressIndicator(
                        color: Color(0XFF4675C0),
                      ),
                      SizedBox(height: 16),
                      Text(
                        'Loading prescription details...',
                        style: TextStyle(
                          color: Colors.grey[600],
                          fontSize: 16,
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
                            color: Colors.red[400],
                          ),
                          SizedBox(height: 16),
                          Text(
                            'Error',
                            style: TextStyle(
                              color: Colors.red[600],
                              fontSize: 20,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          SizedBox(height: 8),
                          Text(
                            errorMessage!,
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                            textAlign: TextAlign.center,
                          ),
                          SizedBox(height: 24),
                          ElevatedButton(
                            onPressed: _fetchPrescriptionDetails,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: Color(0XFF4675C0),
                              padding: EdgeInsets.symmetric(
                                horizontal: 24,
                                vertical: 12,
                              ),
                            ),
                            child: Text(
                              'Retry',
                              style: TextStyle(
                                color: Colors.white,
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    )
                  : prescriptionData == null
                      ? Center(
                          child: Text(
                            'No prescription data available',
                            style: TextStyle(
                              color: Colors.grey[600],
                              fontSize: 16,
                            ),
                          ),
                        )
                      : _buildPrescriptionDetails(),
        ),
      ),
    );
  }

  Widget _buildPrescriptionDetails() {
    final prescription = prescriptionData!;
    final items = prescription['items'] as List<dynamic>? ?? [];

    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header Card
          _buildHeaderCard(prescription),

          SizedBox(height: 16),

          // Patient Information Card
          _buildPatientInfoCard(prescription),

          SizedBox(height: 16),

          // Prescription Items Card
          _buildPrescriptionItemsCard(items),

          if (prescription['pre_notes'] != null &&
              prescription['pre_notes'].toString().isNotEmpty) ...[
            SizedBox(height: 16),
            _buildNotesCard(prescription),
          ],

          SizedBox(height: 16),

          // Signature Card
          if (prescription['pre_signature'] != null) ...[
            SizedBox(height: 16),
            _buildSignatureCard(prescription),
          ] else ...[
            SizedBox(height: 16),
            _buildSignatureCard(
                prescription), // Show even if null for debugging
          ],
        ],
      ),
    );
  }

  Widget _buildHeaderCard(Map<String, dynamic> prescription) {
    return Container(
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
      padding: EdgeInsets.all(20),
      child: Row(
        children: [
          Container(
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0XFF4675C0).withOpacity(0.1),
              borderRadius: BorderRadius.circular(8),
            ),
            child: Text(
              '${prescription['pre_prescription_number'] ?? 'N/A'}',
              style: TextStyle(
                color: Color(0XFF4675C0),
                fontSize: 16,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Spacer(),
          Icon(
            Icons.description_outlined,
            color: Color(0XFF4675C0),
            size: 24,
          ),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard(Map<String, dynamic> prescription) {
    return Container(
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
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.person_outline,
                color: Color(0XFF4675C0),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Patient Information',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          _buildInfoRow('Name', '${prescription['pre_patient_name'] ?? 'N/A'}'),
          _buildInfoRow(
              'Gender', '${prescription['pre_patient_gender'] ?? 'N/A'}'),
          _buildInfoRow('Age', '${prescription['pre_patient_age'] ?? 'N/A'}'),
          _buildInfoRow(
              'Patient ID', '${prescription['pre_patient_id'] ?? 'N/A'}'),
          _buildInfoRow(
              'Created Date', '${prescription['pre_created_dt'] ?? 'N/A'}'),
        ],
      ),
    );
  }

  Widget _buildPrescriptionItemsCard(List<dynamic> items) {
    return Container(
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
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.medication_outlined,
                color: Color(0XFF4675C0),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Prescription Items',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          if (items.isEmpty)
            Text(
              'No prescription items found',
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 16,
              ),
            )
          else
            ...items.asMap().entries.map((entry) {
              final index = entry.key;
              final item = entry.value;
              return Column(
                children: [
                  if (index > 0) SizedBox(height: 16),
                  _buildMedicineItem(item, index + 1),
                  if (index < items.length - 1) Divider(height: 24),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildMedicineItem(Map<String, dynamic> item, int index) {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey[200]!,
          width: 1,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                decoration: BoxDecoration(
                  color: Color(0XFF4675C0),
                  borderRadius: BorderRadius.circular(4),
                ),
                child: Text(
                  '$index',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
              SizedBox(width: 12),
              Expanded(
                child: Text(
                  '${item['pit_medicine_name'] ?? 'Unknown Medicine'}',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                    color: Colors.black87,
                  ),
                ),
              ),
            ],
          ),
          SizedBox(height: 12),
          Row(
            children: [
              Expanded(
                child: _buildMedicineInfoRow(
                    'Generic Name', '${item['pit_generic_name'] ?? 'N/A'}'),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildMedicineInfoRow('Strength',
                    '${item['pit_strength'] ?? 'N/A'} ${item['pit_unit'] ?? ''}'),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMedicineInfoRow(
                    'Route', '${item['pit_route'] ?? 'N/A'}'),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildMedicineInfoRow('Dosage',
                    '${item['pit_dosage_per_time'] ?? 'N/A'} per time'),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMedicineInfoRow(
                    'Frequency', _buildFrequencyText(item)),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildMedicineInfoRow(
                    'Duration', '${item['pit_duration'] ?? 'N/A'} days'),
              ),
            ],
          ),
          SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _buildMedicineInfoRow(
                    'Quantity', '${item['pit_quantity'] ?? 'N/A'} units'),
              ),
              SizedBox(width: 16),
              Expanded(
                child: _buildMedicineInfoRow(
                    'Refill', '${item['pit_refill'] ?? '0'}'),
              ),
            ],
          ),
        ],
      ),
    );
  }

  String _buildFrequencyText(Map<String, dynamic> item) {
    List<String> times = [];
    if (item['pit_frequency_mn'] == 1 || item['pit_frequency_mn'] == '1')
      times.add('Morning');
    if (item['pit_frequency_af'] == 1 || item['pit_frequency_af'] == '1')
      times.add('Afternoon');
    if (item['pit_frequency_en'] == 1 || item['pit_frequency_en'] == '1')
      times.add('Evening');
    if (item['pit_frequency_nt'] == 1 || item['pit_frequency_nt'] == '1')
      times.add('Night');

    if (times.isEmpty) {
      return '${item['pit_times_per_day'] ?? 'N/A'} times/day';
    }

    return times.join(', ');
  }

  Widget _buildNotesCard(Map<String, dynamic> prescription) {
    return Container(
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
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.note_outlined,
                color: Color(0XFF4675C0),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Doctor\'s Notes',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: Text(
              '${prescription['pre_notes'] ?? 'No notes available'}',
              style: TextStyle(
                fontSize: 16,
                color: Colors.black87,
                height: 1.5,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureCard(Map<String, dynamic> prescription) {
    return Container(
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
      padding: EdgeInsets.all(20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.draw_outlined,
                color: Color(0XFF4675C0),
                size: 20,
              ),
              SizedBox(width: 8),
              Text(
                'Doctor\'s Signature',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
            ],
          ),
          SizedBox(height: 16),
          Container(
            width: double.infinity,
            height: 100,
            decoration: BoxDecoration(
              color: Colors.grey[50],
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: Colors.grey[200]!,
                width: 1,
              ),
            ),
            child: prescription['pre_signature'] != null &&
                    prescription['pre_signature'].toString().isNotEmpty
                ? _buildSignatureImage(prescription['pre_signature'])
                : Center(
                    child: Text(
                      'No Signature Available',
                      style: TextStyle(
                        fontSize: 16,
                        color: Colors.grey[600],
                      ),
                    ),
                  ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureImage(dynamic signatureData) {
    try {
      String base64String = signatureData.toString();

      // Remove data URL prefix if present (e.g., "data:image/png;base64,")
      if (base64String.contains(',')) {
        base64String = base64String.split(',')[1];
      }

      // Decode base64 to bytes
      Uint8List bytes = base64Decode(base64String);

      return Container(
        width: double.infinity,
        height: 100,
        child: Image.memory(
          bytes,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            print("❌ Error displaying signature image: $error");
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.error_outline,
                    color: Colors.red,
                    size: 24,
                  ),
                  SizedBox(height: 4),
                  Text(
                    'Error loading signature',
                    style: TextStyle(
                      fontSize: 12,
                      color: Colors.red,
                    ),
                  ),
                ],
              ),
            );
          },
        ),
      );
    } catch (e) {
      print("❌ Error decoding signature: $e");
      return Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              Icons.error_outline,
              color: Colors.red,
              size: 24,
            ),
            SizedBox(height: 4),
            Text(
              'Invalid signature data',
              style: TextStyle(
                fontSize: 12,
                color: Colors.red,
              ),
            ),
          ],
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              '$label:',
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey[600],
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black87,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineInfoRow(String label, String value) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: TextStyle(
            fontSize: 12,
            color: Colors.grey[600],
            fontWeight: FontWeight.w500,
          ),
        ),
        SizedBox(height: 4),
        Text(
          value,
          style: TextStyle(
            fontSize: 14,
            color: Colors.black87,
            fontWeight: FontWeight.w600,
          ),
        ),
      ],
    );
  }
}
