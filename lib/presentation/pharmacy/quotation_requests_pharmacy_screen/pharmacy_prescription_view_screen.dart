import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import 'dart:convert';
import 'dart:typed_data';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class PharmacyPrescriptionViewScreen extends StatefulWidget {
  final String prescriptionId;
  final String? doctorId; // Optional doctor ID from quotation data

  const PharmacyPrescriptionViewScreen({
    Key? key,
    required this.prescriptionId,
    this.doctorId,
  }) : super(key: key);

  @override
  _PharmacyPrescriptionViewScreenState createState() =>
      _PharmacyPrescriptionViewScreenState();
}

class _PharmacyPrescriptionViewScreenState
    extends State<PharmacyPrescriptionViewScreen> {
  Map<String, dynamic>? prescriptionData;
  bool isLoading = true;
  String? errorMessage;
  String? doctorId;

  @override
  void initState() {
    super.initState();
    _loadDoctorData();
  }

  Future<void> _loadDoctorData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('userData');

    if (userDataString != null) {
      try {
        Map<String, dynamic> userData = json.decode(userDataString);
        doctorId = userData['id']?.toString();

        if (doctorId != null) {
          await _fetchPrescriptionDetails();
        } else {
          setState(() {
            isLoading = false;
            errorMessage = 'Doctor ID not found';
          });
        }
      } catch (e) {
        setState(() {
          isLoading = false;
          errorMessage = 'Error loading user data';
        });
      }
    } else {
      setState(() {
        isLoading = false;
        errorMessage = 'User data not available';
      });
    }
  }

  Future<void> _fetchPrescriptionDetails() async {
    if (doctorId == null) return;

    setState(() {
      isLoading = true;
      errorMessage = null;
    });

    try {
      print("\n📋 === FETCHING PRESCRIPTION DETAILS (PHARMACY) ===");
      print("API URL: ${AppConfig.buildApiUrl('writeprescriptionview')}");
      print("Prescription ID: ${widget.prescriptionId}");

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('writeprescriptionview')),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode({
          'prescription_id': widget.prescriptionId,
        }),
      );

      print("Response Status: ${response.statusCode}");
      print("Response Body: ${response.body}");
      print("=== END FETCHING PRESCRIPTION DETAILS ===\n");

      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        if (data['success'] == true && data['data'] != null) {
          setState(() {
            prescriptionData = data['data'];
            isLoading = false;
          });
          print("✅ Loaded prescription details successfully");
          print(
              "📋 Prescription Number: ${data['data']['pre_prescription_number']}");
          print("👤 Patient Name: ${data['data']['pre_patient_name']}");
          print(
              "💊 Items count: ${(data['data']['items'] as List?)?.length ?? 0}");
          print("📝 Signature data: ${data['data']['pre_signature']}");
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
          errorMessage = 'Failed to load prescription details';
        });
      }
    } catch (e) {
      setState(() {
        isLoading = false;
        errorMessage = 'Error: $e';
      });
      print("Error fetching prescription details: $e");
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
        leading: IconButton(
          icon: Icon(
            Icons.arrow_back,
            color: Colors.white,
          ),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        backgroundColor: Color(0XFF4675C0),
        elevation: 0,
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
              ? _buildLoadingState()
              : errorMessage != null
                  ? _buildErrorState()
                  : prescriptionData == null
                      ? _buildEmptyState()
                      : _buildPrescriptionDetails(),
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0XFF4675C0)),
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
    );
  }

  Widget _buildErrorState() {
    return Center(
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
            errorMessage!,
            style: TextStyle(
              color: Colors.red[600],
              fontSize: 16,
              fontWeight: FontWeight.w500,
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 24),
          ElevatedButton(
            onPressed: () {
              _fetchPrescriptionDetails();
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Color(0XFF4675C0),
              foregroundColor: Colors.white,
            ),
            child: Text('Retry'),
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
          Icon(
            Icons.description_outlined,
            size: 64,
            color: Colors.grey[400],
          ),
          SizedBox(height: 16),
          Text(
            'No prescription data available',
            style: TextStyle(
              color: Colors.grey[600],
              fontSize: 16,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionDetails() {
    return SingleChildScrollView(
      padding: EdgeInsets.all(16),
      child: Column(
        children: [
          _buildHeaderCard(),
          SizedBox(height: 16),
          _buildPatientInfoCard(),
          SizedBox(height: 16),
          _buildPrescriptionItemsCard(),
          SizedBox(height: 16),
          _buildNotesCard(),
          SizedBox(height: 16),
          _buildSignatureCard(),
        ],
      ),
    );
  }

  Widget _buildHeaderCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Prescription Information",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0XFF4675C0),
            ),
          ),
          SizedBox(height: 12),
          _buildInfoRow("Prescription Number",
              '${prescriptionData!['pre_prescription_number'] ?? 'N/A'}'),
          _buildInfoRow("Created Date",
              '${prescriptionData!['pre_created_dt'] ?? 'N/A'}'),
          _buildInfoRow(
              "Doctor ID", '${prescriptionData!['pre_doctor_id'] ?? 'N/A'}'),
        ],
      ),
    );
  }

  Widget _buildPatientInfoCard() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Patient Information",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0XFF4675C0),
            ),
          ),
          SizedBox(height: 12),
          _buildInfoRow("Patient Name",
              '${prescriptionData!['pre_patient_name'] ?? 'N/A'}'),
          _buildInfoRow(
              "Gender", '${prescriptionData!['pre_patient_gender'] ?? 'N/A'}'),
          _buildInfoRow(
              "Age", '${prescriptionData!['pre_patient_age'] ?? 'N/A'}'),
          _buildInfoRow(
              "Patient ID", '${prescriptionData!['pre_patient_id'] ?? 'N/A'}'),
        ],
      ),
    );
  }

  Widget _buildPrescriptionItemsCard() {
    List<dynamic> prescriptionItems = prescriptionData!['items'] ?? [];

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Prescribed Medicines",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0XFF4675C0),
            ),
          ),
          SizedBox(height: 12),
          if (prescriptionItems.isEmpty)
            Text(
              "No medicines prescribed",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            )
          else
            ...prescriptionItems
                .map((item) => _buildMedicineItem(item))
                .toList(),
        ],
      ),
    );
  }

  Widget _buildMedicineItem(Map<String, dynamic> item) {
    return Container(
      margin: EdgeInsets.only(bottom: 12),
      padding: EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey[300]!),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            item['pit_medicine_name']?.toString() ?? 'Unknown Medicine',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          _buildMedicineInfoRow(
              "Generic Name", '${item['pit_generic_name'] ?? 'N/A'}'),
          _buildMedicineInfoRow("Strength", '${item['pit_strength'] ?? 'N/A'}'),
          _buildMedicineInfoRow("Unit", '${item['pit_unit'] ?? 'N/A'}'),
          _buildMedicineInfoRow("Route", '${item['pit_route'] ?? 'N/A'}'),
          _buildMedicineInfoRow(
              "Dosage per Time", '${item['pit_dosage_per_time'] ?? 'N/A'}'),
          _buildMedicineInfoRow("Duration", '${item['pit_duration'] ?? 'N/A'}'),
          _buildMedicineInfoRow("Quantity", '${item['pit_quantity'] ?? 'N/A'}'),
          _buildMedicineInfoRow("Refill", '${item['pit_refill'] ?? 'N/A'}'),
          SizedBox(height: 4),
          Text(
            _buildFrequencyText(item),
            style: TextStyle(
              fontSize: 12,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  String _buildFrequencyText(Map<String, dynamic> item) {
    String frequency = "";

    if (item['pit_frequency_mn'] == 1 || item['pit_frequency_mn'] == '1') {
      frequency += "Morning ";
    }
    if (item['pit_frequency_af'] == 1 || item['pit_frequency_af'] == '1') {
      frequency += "Afternoon ";
    }
    if (item['pit_frequency_en'] == 1 || item['pit_frequency_en'] == '1') {
      frequency += "Evening ";
    }
    if (item['pit_frequency_nt'] == 1 || item['pit_frequency_nt'] == '1') {
      frequency += "Night ";
    }

    return frequency.isNotEmpty
        ? "Frequency: $frequency"
        : "Frequency: Not specified";
  }

  Widget _buildNotesCard() {
    String notes = prescriptionData!['pre_notes']?.toString() ?? '';

    if (notes.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Doctor's Notes",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0XFF4675C0),
            ),
          ),
          SizedBox(height: 12),
          Text(
            notes,
            style: TextStyle(
              fontSize: 14,
              color: Colors.black87,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSignatureCard() {
    String signatureData = prescriptionData!['pre_signature']?.toString() ?? '';

    if (signatureData.isEmpty) return SizedBox.shrink();

    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: Offset(0, 2),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Doctor's Signature",
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Color(0XFF4675C0),
            ),
          ),
          SizedBox(height: 12),
          _buildSignatureImage(signatureData),
        ],
      ),
    );
  }

  Widget _buildSignatureImage(dynamic signatureData) {
    try {
      print("🔍 Signature data type: ${signatureData.runtimeType}");
      print("🔍 Signature data length: ${signatureData.toString().length}");

      if (signatureData == null || signatureData.toString().isEmpty) {
        return Container(
          height: 100,
          width: double.infinity,
          decoration: BoxDecoration(
            color: Colors.grey[200],
            borderRadius: BorderRadius.circular(8),
          ),
          child: Center(
            child: Text(
              "No signature available",
              style: TextStyle(
                color: Colors.grey[600],
                fontSize: 14,
              ),
            ),
          ),
        );
      }

      // Handle base64 string
      String base64String = signatureData.toString();

      // Remove data URL prefix if present
      if (base64String.startsWith('data:image')) {
        base64String = base64String.split(',')[1];
      }

      Uint8List bytes = base64Decode(base64String);

      return Container(
        height: 120,
        width: double.infinity,
        decoration: BoxDecoration(
          border: Border.all(color: Colors.grey[300]!),
          borderRadius: BorderRadius.circular(8),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(8),
          child: Image.memory(
            bytes,
            fit: BoxFit.contain,
          ),
        ),
      );
    } catch (e) {
      print("❌ Error displaying signature: $e");
      return Container(
        height: 100,
        width: double.infinity,
        decoration: BoxDecoration(
          color: Colors.red[50],
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: Colors.red[200]!),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.error_outline,
                color: Colors.red[400],
                size: 24,
              ),
              SizedBox(height: 4),
              Text(
                "Error loading signature",
                style: TextStyle(
                  color: Colors.red[600],
                  fontSize: 12,
                ),
              ),
            ],
          ),
        ),
      );
    }
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 4),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 120,
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.w600,
                fontSize: 14,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 14,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineInfoRow(String label, String value) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 2),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 100,
            child: Text(
              "$label:",
              style: TextStyle(
                fontWeight: FontWeight.w500,
                fontSize: 12,
                color: Colors.black87,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
