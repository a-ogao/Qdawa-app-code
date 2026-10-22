import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter/rendering.dart';
import 'dart:ui' as ui;
import 'dart:typed_data';
import 'dart:convert';
import '../navbar/navbar_widget.dart';
import '../../../widgets/medicine_autocomplete.dart';
import '../../../core/api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../delivery_details/delivery_details.dart';

class WritePrescriptionScreen extends StatefulWidget {
  const WritePrescriptionScreen({Key? key}) : super(key: key);

  @override
  _WritePrescriptionScreenState createState() =>
      _WritePrescriptionScreenState();
}

class _WritePrescriptionScreenState extends State<WritePrescriptionScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  String? doctorId;
  String? patientId;
  bool isSubmitting = false;
  Map<String, dynamic>? doctorData;
  Map<String, dynamic>? patientData;
  String displayPrescriptionNumber =
      'Loading...'; // Will be updated after doctor data loads

  // Patient form controllers
  final TextEditingController patientPhoneController = TextEditingController();
  final TextEditingController patientNameController = TextEditingController();
  final TextEditingController patientGenderController = TextEditingController();
  final TextEditingController patientAgeController = TextEditingController();

  // Patient search variables
  List<Map<String, dynamic>> patientSuggestions = [];
  bool isSearchingPatient = false;
  String? selectedPatientId;
  Map<String, dynamic>? selectedPatientData;

  List<Map<String, dynamic>> prescriptionItems = [
    {
      'medicineType':
          'oral', // Options: 'oral', 'parenteral', 'mucosal', 'irrigation', 'other'
      'drugName': '',
      'frequency': {'MN': 0, 'AF': 0, 'EN': 0, 'NT': 0},
      'timesPerDay': '2',
      'duration': '1',
      'quantity': '0',
      'unit': 'units',
      'refill': '0',
      'controllers': {
        'drugName': TextEditingController(),
        'MN': TextEditingController(text: '0'),
        'AF': TextEditingController(text: '0'),
        'EN': TextEditingController(text: '0'),
        'NT': TextEditingController(text: '0'),
        'timesPerDay': TextEditingController(text: '2'),
        'duration': TextEditingController(text: '1'),
        'quantity': TextEditingController(text: '0'),
      }
    }
  ];
  Uint8List? signatureImage;

  @override
  void initState() {
    super.initState();
    // Force landscape orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.landscapeLeft,
      DeviceOrientation.landscapeRight,
    ]);

    // Convert any existing boolean values to integers
    _convertBooleanFrequencies();
    _loadUserDataAndDoctorDetails();

    // Set default Kenya country code
    patientPhoneController.text = '+254';

    // Add listener for phone number changes
    patientPhoneController.addListener(_onPhoneNumberChanged);
  }

  Future<void> _loadUserDataAndDoctorDetails() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    // Load basic doctor data from userData to get usr_id
    String? userDataString = prefs.getString('userData');
    if (userDataString != null) {
      try {
        final Map<String, dynamic> basicUserData =
            json.decode(userDataString) as Map<String, dynamic>;
        final String? usrId = basicUserData['id']?.toString();

        if (usrId != null && usrId.isNotEmpty) {
          doctorId = usrId;

          // Fetch full doctor details from API
          try {
            final apiDoctorData =
                await ApiService.getDoctorDetails(usrId);

            if (apiDoctorData != null) {
              doctorData = apiDoctorData;

              print("\n👨‍⚕️ === DOCTOR DATA LOADED FROM API ===");
              print("Doctor ID: $doctorId");
              print("Doctor Name: ${doctorData!['usr_username'] ?? doctorData!['usr_first_name']}");
              print("Doctor Email: ${doctorData!['usr_email']}");
              print("Doctor Phone: ${doctorData!['usr_mobile_number']}");
              print("License No: ${doctorData!['doc_license_no']}");
              print("Full Doctor Data: $doctorData");
              print("=== END DOCTOR DATA ===\n");
            } else {
              // Fallback: use basic userData if API fails
              doctorData = basicUserData;
              print("⚠️ get_doc_detail returned null, using basic userData.");
            }
          } catch (e) {
            // On any error, keep at least basic data
            doctorData = basicUserData;
            print("❌ Error fetching doctor details from API: $e");
          }
        } else {
          print("❌ usr_id not found in userData");
          doctorData = basicUserData;
        }
      } catch (e) {
        print("❌ Error decoding userData: $e");
        doctorData = null;
      }
    }

    // Load patient ID
    patientId = prefs.getString('selected_patient_id') ??
        prefs.getString('patientid') ??
        prefs.getString('user_id'); // Fallback to user_id if available

    print("\n👤 === PATIENT ID LOADING ===");
    print("selected_patient_id: ${prefs.getString('selected_patient_id')}");
    print("patientid: ${prefs.getString('patientid')}");
    print("user_id: ${prefs.getString('user_id')}");
    print("Final patientId: $patientId");

    // Debug: List all available keys
    Set<String> keys = prefs.getKeys();
    print("Available SharedPreferences keys: ${keys.toList()}");
    print("=== END PATIENT ID LOADING ===\n");

    // If no patient ID found, create one and save it
    if (patientId == null && doctorId != null) {
      // Use doctor ID as patient ID (numeric)
      patientId = doctorId;
      await prefs.setString('patientid', patientId!);
      print("💾 Created and saved new patient ID: $patientId");
    }

    setState(() {});

    // Update display prescription number after doctor data is loaded
    _updateDisplayPrescriptionNumber();
  }

  void _updateDisplayPrescriptionNumber() {
    setState(() {
      displayPrescriptionNumber = _generatePrescriptionNumber();
    });
  }

  // Phone number change handler
  void _onPhoneNumberChanged() {
    String phoneNumber = patientPhoneController.text;

    // Ensure Kenya country code is always present
    if (!phoneNumber.startsWith('+254')) {
      if (phoneNumber.startsWith('254')) {
        patientPhoneController.text = '+$phoneNumber';
      } else if (phoneNumber.startsWith('0')) {
        patientPhoneController.text = '+254${phoneNumber.substring(1)}';
      } else if (phoneNumber.isNotEmpty && !phoneNumber.startsWith('+')) {
        patientPhoneController.text = '+254$phoneNumber';
      }
    }

    // Search for patient when phone number is complete (Kenya format: +254XXXXXXXXX)
    if (phoneNumber.length >= 13 && phoneNumber.startsWith('+254')) {
      _searchPatient(phoneNumber);
    } else {
      setState(() {
        patientSuggestions = [];
        selectedPatientId = null;
        selectedPatientData = null;
      });
    }
  }

  // Search patient by phone number
  Future<void> _searchPatient(String phoneNumber) async {
    if (phoneNumber.length < 13) return;

    setState(() {
      isSearchingPatient = true;
    });

    try {
      final results = await ApiService.searchPatientByPhone(phoneNumber);
      setState(() {
        patientSuggestions = results;
        isSearchingPatient = false;
      });
    } catch (e) {
      setState(() {
        patientSuggestions = [];
        isSearchingPatient = false;
      });
      print('Error searching patient: $e');
    }
  }

  // Select patient from suggestions
  void _selectPatient(Map<String, dynamic> patient) {
    setState(() {
      selectedPatientId = patient['id']?.toString();
      selectedPatientData = patient;
      patientNameController.text = patient['usr_first_name'] ?? '';
      patientSuggestions = [];
    });
  }

  void _onMedicineSelected(Map<String, dynamic> medicine, int index) {
    setState(() {
      prescriptionItems[index]['drugName'] =
          medicine['medicine_name'] ?? medicine['name'] ?? '';
      prescriptionItems[index]['medicineId'] = medicine['id'] ?? '';
      prescriptionItems[index]['genericName'] = medicine['generic_name'] ?? '';
      prescriptionItems[index]['strength'] = medicine['strength'] ?? '';
      prescriptionItems[index]['unit'] = medicine['unit'] ?? '';

      // Auto-select route based on route_category from API
      String? routeCategory =
          medicine['route_category']?.toString().toLowerCase();
      if (routeCategory != null) {
        print("\n🎯 Auto-selecting route: $routeCategory");

        // Map route_category to medicineType
        if (routeCategory.contains('oral') || routeCategory.contains('mouth')) {
          prescriptionItems[index]['medicineType'] = 'oral';
        } else if (routeCategory.contains('injection') ||
            routeCategory.contains('iv') ||
            routeCategory.contains('parenteral') ||
            routeCategory.contains('infusion')) {
          prescriptionItems[index]['medicineType'] = 'parenteral';
        } else if (routeCategory.contains('drop') ||
            routeCategory.contains('spray') ||
            routeCategory.contains('nasal') ||
            routeCategory.contains('suppository') ||
            routeCategory.contains('mucosal')) {
          prescriptionItems[index]['medicineType'] = 'mucosal';
        } else if (routeCategory.contains('irrigation') ||
            routeCategory.contains('wash')) {
          prescriptionItems[index]['medicineType'] = 'irrigation';
        } else {
          prescriptionItems[index]['medicineType'] = 'other';
        }

        print(
            "Selected route type: ${prescriptionItems[index]['medicineType']}");
      }

      // Recalculate quantity with new route
      _calculateQuantity(prescriptionItems[index]);
    });
  }

  Future<void> _submitPrescription() async {
    // Validate patient details
    if (patientPhoneController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter patient phone number')),
      );
      return;
    }

    if (patientNameController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter patient name')),
      );
      return;
    }

    if (patientGenderController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please select patient gender')),
      );
      return;
    }

    if (patientAgeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please enter patient age')),
      );
      return;
    }

    if (doctorId == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Doctor information missing')),
      );
      return;
    }

    if (patientId == null) {
      // Create a temporary patient ID based on current user (numeric)
      patientId = doctorId ?? '999999';
      print("⚠️ Using temporary patient ID: $patientId");
    }

    // Ensure patient ID is numeric (remove any non-numeric characters)
    String numericPatientId = patientId!.replaceAll(RegExp(r'[^0-9]'), '');
    if (numericPatientId.isEmpty) {
      numericPatientId = '999999'; // Default fallback
    }
    patientId = numericPatientId;

    if (signatureImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add your signature')),
      );
      return;
    }

    // Check if prescription items are valid
    bool hasValidItems = prescriptionItems.any(
        (item) => (item['drugName']?.toString().trim().isNotEmpty ?? false));

    if (!hasValidItems) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Please add at least one medicine')),
      );
      return;
    }

    setState(() {
      isSubmitting = true;
    });

    try {
      // Generate prescription number
      String prescriptionNumber = _generatePrescriptionNumber();

      // Convert signature to base64
      String signatureBase64 = '';
      if (signatureImage != null) {
        signatureBase64 = base64Encode(signatureImage!);
        print("📝 Signature encoded: ${signatureBase64.length} characters");
      }

      // Prepare patient data
      Map<String, dynamic> patientData = {
        'id': selectedPatientId ?? patientId,
        'name': patientNameController.text.trim(),
        'phone': patientPhoneController.text.trim(),
        'gender': patientGenderController.text.trim(),
        'age': patientAgeController.text.trim(),
      };

      // Prepare prescription data
      List<Map<String, dynamic>> prescriptionData =
          prescriptionItems.map((item) {
        return {
          'medicine_id': item['medicineId'] ?? '',
          'medicine_name': item['drugName'] ?? '',
          'generic_name': item['genericName'] ?? '',
          'strength': item['strength'] ?? '',
          'unit': item['unit'] ?? '',
          'route': item['medicineType'] ?? 'oral',
          'dosage_per_time': '1',
          'frequency':
              item['frequency'] ?? {'MN': 0, 'AF': 0, 'EN': 0, 'NT': 0},
          'times_per_day': item['timesPerDay'] ?? '2',
          'duration': item['duration'] ?? '1',
          'quantity': item['quantity'] ?? '0',
          'refill': item['refill'] ?? '0',
        };
      }).toList();

      print("\n📋 === PRESCRIPTION DATA DEBUG ===");
      print("Patient Data: $patientData");
      print("Prescription Items: $prescriptionData");
      print("Signature Length: ${signatureBase64.length}");
      print("Prescription Number: $prescriptionNumber");
      print("=== END PRESCRIPTION DATA DEBUG ===\n");

      final result = await ApiService.submitPrescription(
        doctorId: doctorId!,
        patientId: patientId!,
        prescriptionItems: prescriptionData,
        signature: signatureBase64,
        prescriptionNumber: prescriptionNumber,
        patientData: patientData,
        notes: '', // You can add a notes field if needed
      );

      if (result['success'] == true) {
        // Save prescription data in SharedPreferences for pharmacy selection flow
        SharedPreferences prefs = await SharedPreferences.getInstance();

        // Convert prescription data to the format expected by pharmacy selection
        List<Map<String, dynamic>> pharmacyPrescriptionData =
            prescriptionData.map((item) {
          return {
            'medicine_name': item['medicine_name'] ?? '',
            'generic_name': item['generic_name'] ?? '',
            'strength': item['strength'] ?? '',
            'unit': item['unit'] ?? '',
            'route': item['route'] ?? '',
            'dosage_per_time': item['dosage_per_time'] ?? '1',
            'frequency_mn': item['frequency']['MN'] ?? 0,
            'frequency_af': item['frequency']['AF'] ?? 0,
            'frequency_en': item['frequency']['EN'] ?? 0,
            'frequency_nt': item['frequency']['NT'] ?? 0,
            'times_per_day': item['times_per_day'] ?? '2',
            'duration': item['duration'] ?? '1',
            'quantity': item['quantity'] ?? '0',
            'refill': item['refill'] ?? '0',
            'prescription_number':
                prescriptionNumber, // Include prescription number
          };
        }).toList();

        // Save prescription data (same format as AI response)
        await prefs.setString(
            'prescription', jsonEncode(pharmacyPrescriptionData));

        // Save prescription number for pharmacy selection flow
        await prefs.setString('prescription_number', prescriptionNumber);

        // Set mtype to '2' (same as scan prescription)
        await prefs.setString('mtype', '2');

        // Set empty file paths (not needed for written prescription)
        await prefs.setString('filepath', '');
        await prefs.setString('orignalfilepath', '');

        print("✅ Prescription data saved for pharmacy selection");
        print("📋 Prescription items: $pharmacyPrescriptionData");

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Prescription submitted successfully!')),
        );

        // Restore portrait orientation before navigating
        SystemChrome.setPreferredOrientations([
          DeviceOrientation.portraitUp,
          DeviceOrientation.portraitDown,
        ]);

        // Navigate to pharmacy selection flow (same as scan prescription)
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DeliveryScreen()),
        );
      } else {
        print("❌ API Error: ${result}");
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(result['message'] ??
                  result['error'] ??
                  'Failed to submit prescription')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      setState(() {
        isSubmitting = false;
      });
    }
  }

  void _convertBooleanFrequencies() {
    for (var item in prescriptionItems) {
      if (item['frequency'] != null) {
        ['MN', 'AF', 'EN', 'NT'].forEach((key) {
          if (item['frequency'][key] is bool) {
            item['frequency'][key] = item['frequency'][key] == true ? 1 : 0;
          }
        });
      }
    }
  }

  String _generatePrescriptionNumber() {
    final now = DateTime.now();

    // Get doctor ID (3 digits with leading zeros)
    String doctorIdStr = doctorId?.toString().padLeft(3, '0') ?? '000';

    // Get year (last 2 digits)
    String year = now.year.toString().substring(2);

    // Get month (2 digits with leading zero)
    String month = now.month.toString().padLeft(2, '0');

    // Get day (2 digits with leading zero)
    String day = now.day.toString().padLeft(2, '0');

    // Get hour (2 digits with leading zero)
    String hour = now.hour.toString().padLeft(2, '0');

    // Get minute (2 digits with leading zero)
    String minute = now.minute.toString().padLeft(2, '0');

    // Format: RX + doctorId + year + month + day + hour + minute
    String prescriptionNumber = 'RX$doctorIdStr$year$month$day$hour$minute';

    print("\n📋 Generated Prescription Number: $prescriptionNumber");
    print("   Doctor ID: $doctorIdStr");
    print(
        "   Date: ${now.year}-${now.month.toString().padLeft(2, '0')}-${now.day.toString().padLeft(2, '0')}");
    print(
        "   Time: ${now.hour.toString().padLeft(2, '0')}:${now.minute.toString().padLeft(2, '0')}");

    return prescriptionNumber;
  }

  @override
  void dispose() {
    // Dispose patient form controllers
    patientPhoneController.dispose();
    patientNameController.dispose();
    patientGenderController.dispose();
    patientAgeController.dispose();

    // Dispose all prescription item controllers
    for (var item in prescriptionItems) {
      if (item['controllers'] != null) {
        item['controllers'].values.forEach((controller) {
          if (controller is TextEditingController) {
            controller.dispose();
          }
        });
      }
    }

    // Restore original orientation
    SystemChrome.setPreferredOrientations([
      DeviceOrientation.portraitUp,
      DeviceOrientation.portraitDown,
    ]);
    super.dispose();
  }

  void _ensureControllers(Map<String, dynamic> item) {
    if (item['controllers'] == null) {
      // Convert boolean values to integers if they exist
      if (item['frequency'] != null) {
        ['MN', 'AF', 'EN', 'NT'].forEach((key) {
          if (item['frequency'][key] is bool) {
            item['frequency'][key] = item['frequency'][key] == true ? 1 : 0;
          }
        });
      }

      item['controllers'] = {
        'drugName': TextEditingController(text: item['drugName'] ?? ''),
        'MN': TextEditingController(
            text: (item['frequency']?['MN'] ?? 0).toString()),
        'AF': TextEditingController(
            text: (item['frequency']?['AF'] ?? 0).toString()),
        'EN': TextEditingController(
            text: (item['frequency']?['EN'] ?? 0).toString()),
        'NT': TextEditingController(
            text: (item['frequency']?['NT'] ?? 0).toString()),
        'timesPerDay': TextEditingController(text: item['timesPerDay'] ?? '2'),
        'duration': TextEditingController(text: item['duration'] ?? '1'),
        'quantity': TextEditingController(text: item['quantity'] ?? '0'),
      };
    }
  }

  void _calculateQuantity(Map<String, dynamic> item) {
    int duration = int.tryParse(item['duration'] ?? '1') ?? 1;
    String medicineType = item['medicineType'] ?? 'oral';
    double quantity = 0;

    if (medicineType == 'oral') {
      // Oral: by mouth (tablets, capsules, syrups)
      int frequencySum = (item['frequency']['MN'] ?? 0) +
          (item['frequency']['AF'] ?? 0) +
          (item['frequency']['EN'] ?? 0) +
          (item['frequency']['NT'] ?? 0);

      // Default dosage of 1 per administration
      quantity = 1.0 * frequencySum * duration;
      item['unit'] = 'units';
    } else if (medicineType == 'parenteral') {
      // Parenteral: injection/infusion (systemic, bypass GI)
      int frequencySum = (item['frequency']['MN'] ?? 0) +
          (item['frequency']['AF'] ?? 0) +
          (item['frequency']['EN'] ?? 0) +
          (item['frequency']['NT'] ?? 0);

      // Default dosage of 1 per administration
      quantity = 1.0 * frequencySum * duration;
      item['unit'] = 'doses';
    } else if (medicineType == 'mucosal') {
      // Mucosal: via mucous membranes (drops, sprays, suppositories)
      int timesPerDay = int.tryParse(item['timesPerDay'] ?? '2') ?? 2;
      // Default dosage of 2 drops per application
      quantity = 2.0 * timesPerDay * duration;
      item['unit'] = 'applications';
    } else if (medicineType == 'irrigation') {
      // Irrigation: washing body cavity/wound with solution
      int timesPerDay = int.tryParse(item['timesPerDay'] ?? '1') ?? 1;
      // Default volume of 100ml per irrigation
      quantity = 100.0 * timesPerDay * duration;
      item['unit'] = 'ml';
    } else {
      // Other: routes that don't neatly fit
      int timesPerDay = int.tryParse(item['timesPerDay'] ?? '2') ?? 2;
      // Default dosage of 1 per application
      quantity = 1.0 * timesPerDay * duration;
      item['unit'] = 'applications';
    }

    item['quantity'] = quantity.toString();

    // Ensure controllers exist and update the quantity controller
    _ensureControllers(item);
    if (item['controllers']['quantity'] != null) {
      item['controllers']['quantity'].text =
          '${quantity.toStringAsFixed(quantity.truncateToDouble() == quantity ? 0 : 1)} ${item['unit']}';
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Write Prescription",
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
      drawer: Navbar(scaffoldKey: _scaffoldKey),
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
          child: SingleChildScrollView(
            child: Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                children: [
                  _buildDoctorDetails(),
                  SizedBox(height: 20),
                  _buildPatientDetails(),
                  SizedBox(height: 20),
                  _buildPrescriptionTable(),
                  SizedBox(height: 20),
                  _buildAddMoreButton(),
                  SizedBox(height: 20),
                  _buildSignaturePad(),
                  SizedBox(height: 20),
                  _buildSubmitButton(),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildDoctorDetails() {
    String doctorName = doctorData != null
        ? (doctorData!['usr_username'] ??
            doctorData!['usr_first_name'] ??
            "Dr. Unknown")
        : "Loading...";
    String doctorEmail =
        doctorData != null ? (doctorData!['usr_email'] ?? "N/A") : "Loading...";
    String doctorPhone = doctorData != null
        ? (doctorData!['usr_mobile_number'] ?? "N/A")
        : "Loading...";
    String licenseNo = doctorData != null
        ? (doctorData!['org_license_number'] ??
            doctorData!['organization_license_number'] ??
            doctorData!['doctor_license_number'] ??
            doctorData!['doc_license_no'] ??
            doctorData!['license_no'] ??
            doctorData!['id']?.toString() ??
            "N/A")
        : "Loading...";

    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Doctor Details",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Color(0XFF4675C0),
            ),
          ),
          SizedBox(height: 15.0),
          _buildDetailLine("Doctor Name:", doctorName),
          SizedBox(height: 8.0),
          _buildDetailLine("Email:", doctorEmail),
          SizedBox(height: 8.0),
          _buildDetailLine("Phone:", doctorPhone),
          SizedBox(height: 8.0),
          _buildDetailLine("License No:", licenseNo),
          SizedBox(height: 8.0),
          _buildDetailLine("Date:", DateTime.now().toString().split(' ')[0]),
          SizedBox(height: 8.0),
          _buildDetailLine("Prescription No:", displayPrescriptionNumber),
        ],
      ),
    );
  }

  Widget _buildDetailLine(String label, String value) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        SizedBox(
          width: 120.0,
          child: Text(
            label,
            style: TextStyle(
              fontWeight: FontWeight.w500,
              fontSize: 14.0,
            ),
          ),
        ),
        Expanded(
          child: Text(
            value,
            style: TextStyle(
              fontSize: 14.0,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildPatientDetails() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Text(
                "Patient Details",
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Color(0XFF4675C0),
                ),
              ),
              SizedBox(width: 8),
              Text(
                "*",
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                  color: Colors.red,
                ),
              ),
            ],
          ),
          SizedBox(height: 15.0),
          Row(
            children: [
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Patient Phone Number *",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.0,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    Stack(
                      children: [
                        TextField(
                          controller: patientPhoneController,
                          decoration: InputDecoration(
                            hintText: "+254XXXXXXXXX",
                            border: OutlineInputBorder(
                              borderRadius: BorderRadius.circular(8.0),
                            ),
                            contentPadding: EdgeInsets.symmetric(
                              horizontal: 12.0,
                              vertical: 12.0,
                            ),
                          ),
                          style: TextStyle(fontSize: 14.0),
                          keyboardType: TextInputType.phone,
                        ),
                        if (isSearchingPatient)
                          Positioned(
                            right: 8,
                            top: 8,
                            child: SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                valueColor: AlwaysStoppedAnimation<Color>(
                                  Color(0XFF4675C0),
                                ),
                              ),
                            ),
                          ),
                      ],
                    ),
                    // Patient suggestions dropdown
                    if (patientSuggestions.isNotEmpty)
                      Container(
                        margin: EdgeInsets.only(top: 4),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.0),
                          border:
                              Border.all(color: Colors.grey.withOpacity(0.3)),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withOpacity(0.1),
                              blurRadius: 4,
                              offset: Offset(0, 2),
                            ),
                          ],
                        ),
                        child: ListView.builder(
                          shrinkWrap: true,
                          itemCount: patientSuggestions.length,
                          itemBuilder: (context, index) {
                            final patient = patientSuggestions[index];
                            return InkWell(
                              onTap: () => _selectPatient(patient),
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 12.0,
                                  vertical: 8.0,
                                ),
                                decoration: BoxDecoration(
                                  border: Border(
                                    bottom: BorderSide(
                                      color: Colors.grey.withOpacity(0.2),
                                      width: 0.5,
                                    ),
                                  ),
                                ),
                                child: Row(
                                  children: [
                                    Icon(
                                      Icons.person,
                                      size: 16,
                                      color: Color(0XFF4675C0),
                                    ),
                                    SizedBox(width: 8),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            patient['usr_first_name'] ??
                                                'Unknown',
                                            style: TextStyle(
                                              fontSize: 12,
                                              fontWeight: FontWeight.w600,
                                              color: Colors.black87,
                                            ),
                                          ),
                                          Text(
                                            patient['usr_email'] ?? '',
                                            style: TextStyle(
                                              fontSize: 10,
                                              color: Colors.grey[600],
                                            ),
                                          ),
                                        ],
                                      ),
                                    ),
                                    Icon(
                                      Icons.arrow_forward_ios,
                                      size: 12,
                                      color: Colors.grey[400],
                                    ),
                                  ],
                                ),
                              ),
                            );
                          },
                        ),
                      ),
                  ],
                ),
              ),
              SizedBox(width: 16.0),
              Expanded(
                flex: 2,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Patient Name *",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.0,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    TextField(
                      controller: patientNameController,
                      decoration: InputDecoration(
                        hintText: "Enter patient name",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 12.0,
                        ),
                      ),
                      style: TextStyle(fontSize: 14.0),
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.0),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Gender *",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.0,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    DropdownButtonFormField<String>(
                      value: patientGenderController.text.isEmpty
                          ? null
                          : patientGenderController.text,
                      decoration: InputDecoration(
                        hintText: "Select",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 12.0,
                        ),
                      ),
                      items: [
                        DropdownMenuItem(value: "Male", child: Text("Male")),
                        DropdownMenuItem(
                            value: "Female", child: Text("Female")),
                        DropdownMenuItem(value: "Other", child: Text("Other")),
                      ],
                      onChanged: (value) {
                        setState(() {
                          patientGenderController.text = value ?? '';
                        });
                      },
                    ),
                  ],
                ),
              ),
              SizedBox(width: 16.0),
              Expanded(
                flex: 1,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "Age *",
                      style: TextStyle(
                        fontWeight: FontWeight.w500,
                        fontSize: 14.0,
                      ),
                    ),
                    SizedBox(height: 8.0),
                    TextField(
                      controller: patientAgeController,
                      decoration: InputDecoration(
                        hintText: "Age",
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(8.0),
                        ),
                        contentPadding: EdgeInsets.symmetric(
                          horizontal: 12.0,
                          vertical: 12.0,
                        ),
                      ),
                      style: TextStyle(fontSize: 14.0),
                      keyboardType: TextInputType.number,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildFrequencyField(Map<String, dynamic> item) {
    String medicineType = item['medicineType'] ?? 'oral';

    if (medicineType == 'mucosal' ||
        medicineType == 'irrigation' ||
        medicineType == 'other') {
      // For mucosal, irrigation, other: show times per day
      return TextField(
        controller: item['controllers']['timesPerDay'],
        decoration: InputDecoration(
          hintText: "2",
          suffixText: "x/day",
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
          contentPadding: EdgeInsets.symmetric(horizontal: 6.0, vertical: 4.0),
        ),
        style: TextStyle(fontSize: 11.0),
        textAlign: TextAlign.center,
        keyboardType: TextInputType.number,
        onChanged: (value) {
          item['timesPerDay'] = value;
          _calculateQuantity(item);
        },
      );
    } else {
      // For oral and parenteral, show MN, AF, EN, NT
      return Row(
        children: [
          Expanded(
            child: Column(
              children: [
                Text("MN", style: TextStyle(fontSize: 9.0)),
                Container(
                  height: 35,
                  child: TextField(
                    controller: item['controllers']['MN'],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 2.0,
                        vertical: 4.0,
                      ),
                    ),
                    style: TextStyle(fontSize: 11.0),
                    onChanged: (value) {
                      int val = int.tryParse(value) ?? 0;
                      if (val >= 0 && val <= 9) {
                        setState(() {
                          item['frequency']['MN'] = val;
                          _calculateQuantity(item);
                        });
                      } else {
                        item['controllers']['MN'].text =
                            item['frequency']['MN'].toString();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Text("AF", style: TextStyle(fontSize: 9.0)),
                Container(
                  height: 35,
                  child: TextField(
                    controller: item['controllers']['AF'],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 2.0,
                        vertical: 4.0,
                      ),
                    ),
                    style: TextStyle(fontSize: 11.0),
                    onChanged: (value) {
                      int val = int.tryParse(value) ?? 0;
                      if (val >= 0 && val <= 9) {
                        setState(() {
                          item['frequency']['AF'] = val;
                          _calculateQuantity(item);
                        });
                      } else {
                        item['controllers']['AF'].text =
                            item['frequency']['AF'].toString();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Text("EN", style: TextStyle(fontSize: 9.0)),
                Container(
                  height: 35,
                  child: TextField(
                    controller: item['controllers']['EN'],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 2.0,
                        vertical: 4.0,
                      ),
                    ),
                    style: TextStyle(fontSize: 11.0),
                    onChanged: (value) {
                      int val = int.tryParse(value) ?? 0;
                      if (val >= 0 && val <= 9) {
                        setState(() {
                          item['frequency']['EN'] = val;
                          _calculateQuantity(item);
                        });
                      } else {
                        item['controllers']['EN'].text =
                            item['frequency']['EN'].toString();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
          SizedBox(width: 2),
          Expanded(
            child: Column(
              children: [
                Text("NT", style: TextStyle(fontSize: 9.0)),
                Container(
                  height: 35,
                  child: TextField(
                    controller: item['controllers']['NT'],
                    keyboardType: TextInputType.number,
                    textAlign: TextAlign.center,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 2.0,
                        vertical: 4.0,
                      ),
                    ),
                    style: TextStyle(fontSize: 11.0),
                    onChanged: (value) {
                      int val = int.tryParse(value) ?? 0;
                      if (val >= 0 && val <= 9) {
                        setState(() {
                          item['frequency']['NT'] = val;
                          _calculateQuantity(item);
                        });
                      } else {
                        item['controllers']['NT'].text =
                            item['frequency']['NT'].toString();
                      }
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      );
    }
  }

  Widget _buildPrescriptionTable() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Rx - Prescription",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Color(0XFF4675C0),
            ),
          ),
          SizedBox(height: 15.0),
          // Table Header
          Container(
            padding: EdgeInsets.symmetric(vertical: 10.0, horizontal: 8.0),
            decoration: BoxDecoration(
              color: Color(0XFF4675C0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(5.0),
            ),
            child: Row(
              children: [
                Expanded(
                    flex: 2,
                    child: Text("Route",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(
                    flex: 3,
                    child: Text("Drug Name",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(
                    flex: 2,
                    child: Text("Frequency",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(
                    flex: 1,
                    child: Text("Duration",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(
                    flex: 1,
                    child: Text("Quantity",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
                Expanded(
                    flex: 1,
                    child: Text("Refill",
                        style: TextStyle(
                            fontWeight: FontWeight.bold, fontSize: 12))),
              ],
            ),
          ),
          // Table Rows
          ...prescriptionItems.asMap().entries.map((entry) {
            Map<String, dynamic> item = entry.value;
            _ensureControllers(item); // Ensure controllers exist
            return Container(
              padding: EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
              decoration: BoxDecoration(
                border: Border(bottom: BorderSide(color: Colors.grey.shade300)),
              ),
              child: Row(
                children: [
                  // Medicine Type Dropdown
                  Expanded(
                    flex: 2,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: item['medicineType'] ?? 'oral',
                          isExpanded: true,
                          style:
                              TextStyle(fontSize: 10.0, color: Colors.black87),
                          items: [
                            DropdownMenuItem(
                              value: 'oral',
                              child: Row(
                                children: [
                                  Icon(Icons.medication,
                                      size: 14, color: Color(0XFF4675C0)),
                                  SizedBox(width: 3),
                                  Flexible(
                                      child: Text('Oral',
                                          style: TextStyle(fontSize: 10))),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'parenteral',
                              child: Row(
                                children: [
                                  Icon(Icons.vaccines,
                                      size: 14, color: Colors.red),
                                  SizedBox(width: 3),
                                  Flexible(
                                      child: Text('Parenteral',
                                          style: TextStyle(fontSize: 10))),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'mucosal',
                              child: Row(
                                children: [
                                  Icon(Icons.water_drop,
                                      size: 14, color: Colors.orange),
                                  SizedBox(width: 3),
                                  Flexible(
                                      child: Text('Mucosal',
                                          style: TextStyle(fontSize: 10))),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'irrigation',
                              child: Row(
                                children: [
                                  Icon(Icons.water,
                                      size: 14, color: Colors.blue),
                                  SizedBox(width: 3),
                                  Flexible(
                                      child: Text('Irrigation',
                                          style: TextStyle(fontSize: 10))),
                                ],
                              ),
                            ),
                            DropdownMenuItem(
                              value: 'other',
                              child: Row(
                                children: [
                                  Icon(Icons.more_horiz,
                                      size: 14, color: Colors.grey),
                                  SizedBox(width: 3),
                                  Flexible(
                                      child: Text('Other',
                                          style: TextStyle(fontSize: 10))),
                                ],
                              ),
                            ),
                          ],
                          onChanged: (value) {
                            setState(() {
                              item['medicineType'] = value;
                              _calculateQuantity(item);
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                  SizedBox(width: 8.0),
                  // Drug Name with Autocomplete
                  Expanded(
                    flex: 3,
                    child: MedicineAutocomplete(
                      controller: item['controllers']['drugName'],
                      onMedicineSelected: (medicine) =>
                          _onMedicineSelected(medicine, entry.key),
                      hintText: "Search medicine",
                      fontSize: 11.0,
                    ),
                  ),
                  SizedBox(width: 8.0),
                  // Frequency Field (conditional based on type)
                  Expanded(
                    flex: 2,
                    child: _buildFrequencyField(item),
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: item['controllers']['duration'],
                      decoration: InputDecoration(
                        hintText: "Days",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0)),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                      ),
                      style: TextStyle(fontSize: 12.0),
                      keyboardType: TextInputType.number,
                      onChanged: (value) {
                        setState(() {
                          item['duration'] = value.isEmpty ? '1' : value;
                          _calculateQuantity(item);
                        });
                      },
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    flex: 1,
                    child: TextField(
                      controller: item['controllers']['quantity'],
                      decoration: InputDecoration(
                        hintText: "Auto",
                        border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(5.0)),
                        contentPadding: EdgeInsets.symmetric(
                            horizontal: 8.0, vertical: 4.0),
                        fillColor: Colors.grey[100],
                        filled: true,
                      ),
                      style: TextStyle(fontSize: 12.0, color: Colors.grey[700]),
                      readOnly: true,
                    ),
                  ),
                  SizedBox(width: 8.0),
                  Expanded(
                    flex: 1,
                    child: Container(
                      padding: EdgeInsets.symmetric(horizontal: 8.0),
                      decoration: BoxDecoration(
                        border: Border.all(color: Colors.grey),
                        borderRadius: BorderRadius.circular(5.0),
                      ),
                      child: DropdownButtonHideUnderline(
                        child: DropdownButton<String>(
                          value: item['refill'] ?? '0',
                          isExpanded: true,
                          style:
                              TextStyle(fontSize: 12.0, color: Colors.black87),
                          items: List.generate(6, (index) {
                            return DropdownMenuItem<String>(
                              value: index.toString(),
                              child: Text(index.toString()),
                            );
                          }),
                          onChanged: (value) {
                            setState(() {
                              item['refill'] = value ?? '0';
                            });
                          },
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            );
          }).toList(),
        ],
      ),
    );
  }

  Widget _buildAddMoreButton() {
    return Align(
      alignment: Alignment.centerLeft,
      child: ElevatedButton.icon(
        onPressed: () {
          setState(() {
            prescriptionItems.add({
              'medicineType': 'oral',
              'drugName': '',
              'frequency': {'MN': 0, 'AF': 0, 'EN': 0, 'NT': 0},
              'timesPerDay': '2',
              'duration': '1',
              'quantity': '0',
              'unit': 'units',
              'refill': '0',
              'controllers': {
                'drugName': TextEditingController(),
                'MN': TextEditingController(text: '0'),
                'AF': TextEditingController(text: '0'),
                'EN': TextEditingController(text: '0'),
                'NT': TextEditingController(text: '0'),
                'timesPerDay': TextEditingController(text: '2'),
                'duration': TextEditingController(text: '1'),
                'quantity': TextEditingController(text: '0'),
              }
            });
          });
        },
        icon: Icon(Icons.add),
        label: Text("Add More"),
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0XFF4675C0),
          foregroundColor: Colors.white,
        ),
      ),
    );
  }

  Widget _buildSignaturePad() {
    return Container(
      padding: EdgeInsets.all(16.0),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10.0),
        boxShadow: [
          BoxShadow(
            color: Colors.black12,
            blurRadius: 5.0,
            spreadRadius: 1.0,
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Doctor's Digital Signature",
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
              color: Color(0XFF4675C0),
            ),
          ),
          SizedBox(height: 15.0),
          GestureDetector(
            onTap: () {
              _showSignaturePad();
            },
            child: Container(
              height: 100.0,
              width: double.infinity,
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400, width: 2.0),
                borderRadius: BorderRadius.circular(8.0),
                color: Colors.grey.shade50,
              ),
              child: signatureImage != null
                  ? ClipRRect(
                      borderRadius: BorderRadius.circular(6.0),
                      child: Image.memory(
                        signatureImage!,
                        fit: BoxFit.contain,
                        width: double.infinity,
                        height: double.infinity,
                      ),
                    )
                  : Center(
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.edit,
                            size: 30.0,
                            color: Colors.grey.shade600,
                          ),
                          SizedBox(height: 5.0),
                          Text(
                            "Tap to Sign",
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 14.0,
                            ),
                          ),
                        ],
                      ),
                    ),
            ),
          ),
          if (signatureImage != null) ...[
            SizedBox(height: 10.0),
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  "Signature saved",
                  style: TextStyle(
                    color: Colors.green,
                    fontSize: 12.0,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                TextButton(
                  onPressed: () {
                    setState(() {
                      signatureImage = null;
                    });
                  },
                  child: Text(
                    "Clear",
                    style: TextStyle(
                      color: Colors.red,
                      fontSize: 12.0,
                    ),
                  ),
                ),
              ],
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildSubmitButton() {
    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isSubmitting ? null : _submitPrescription,
        style: ElevatedButton.styleFrom(
          backgroundColor: Color(0XFF4675C0),
          foregroundColor: Colors.white,
          padding: EdgeInsets.symmetric(vertical: 15.0),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(10.0),
          ),
        ),
        child: isSubmitting
            ? Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  SizedBox(
                    width: 20,
                    height: 20,
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      valueColor: AlwaysStoppedAnimation<Color>(Colors.white),
                    ),
                  ),
                  SizedBox(width: 10),
                  Text(
                    "Submitting...",
                    style: TextStyle(
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ],
              )
            : Text(
                "Submit Prescription",
                style: TextStyle(
                  fontSize: 18.0,
                  fontWeight: FontWeight.bold,
                ),
              ),
      ),
    );
  }

  void _showSignaturePad() {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return SignatureDialog(
          onSignatureSaved: (Uint8List imageBytes) {
            setState(() {
              signatureImage = imageBytes;
            });
          },
        );
      },
    );
  }
}

class SignatureDialog extends StatefulWidget {
  final Function(Uint8List) onSignatureSaved;

  const SignatureDialog({Key? key, required this.onSignatureSaved})
      : super(key: key);

  @override
  _SignatureDialogState createState() => _SignatureDialogState();
}

class _SignatureDialogState extends State<SignatureDialog> {
  List<Offset?> points = <Offset?>[];
  bool hasSignature = false;
  bool isDrawing = false; // Track if mouse/finger is down
  final GlobalKey _signatureKey = GlobalKey();

  @override
  Widget build(BuildContext context) {
    return Dialog(
      child: Container(
        width: MediaQuery.of(context).size.width * 0.9,
        height: MediaQuery.of(context).size.height * 0.7,
        child: Column(
          children: [
            Container(
              padding: EdgeInsets.all(16.0),
              decoration: BoxDecoration(
                color: Color(0XFF4675C0),
                borderRadius: BorderRadius.only(
                  topLeft: Radius.circular(8.0),
                  topRight: Radius.circular(8.0),
                ),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    "Digital Signature",
                    style: TextStyle(
                      color: Colors.white,
                      fontSize: 18.0,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: Icon(Icons.close, color: Colors.white),
                  ),
                ],
              ),
            ),
            Expanded(
              child: Container(
                decoration: BoxDecoration(
                  color: Colors.white,
                  border: Border.all(color: Colors.grey.shade300, width: 2),
                ),
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return Listener(
                      onPointerDown: (details) {
                        // Use local position directly from the listener
                        Offset localPosition = details.localPosition;
                        setState(() {
                          isDrawing = true; // Start drawing
                          points.add(localPosition);
                          hasSignature = true;
                        });
                        print(
                            "Mouse down at: $localPosition (Canvas: ${constraints.biggest})");
                      },
                      onPointerMove: (details) {
                        // Only add points if mouse/finger is down (drawing)
                        if (isDrawing) {
                          Offset localPosition = details.localPosition;
                          setState(() {
                            points.add(localPosition);
                          });
                          print("Mouse drag to: $localPosition");
                        }
                      },
                      onPointerUp: (details) {
                        setState(() {
                          isDrawing = false; // Stop drawing
                          points.add(null); // Add null to separate strokes
                        });
                        print(
                            "Mouse up - stroke complete. Total points: ${points.length}");
                      },
                      child: Container(
                        width: double.infinity,
                        height: double.infinity,
                        child: RepaintBoundary(
                          key: _signatureKey,
                          child: CustomPaint(
                            painter: SignaturePainter(points),
                            size: constraints.biggest,
                          ),
                        ),
                      ),
                    );
                  },
                ),
              ),
            ),
            Container(
              padding: EdgeInsets.all(16.0),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  ElevatedButton(
                    onPressed: () {
                      setState(() {
                        points.clear();
                        hasSignature = false;
                        isDrawing = false; // Reset drawing state
                      });
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: Text("Clear"),
                  ),
                  ElevatedButton(
                    onPressed: hasSignature
                        ? () async {
                            try {
                              RenderRepaintBoundary boundary = _signatureKey
                                  .currentContext!
                                  .findRenderObject() as RenderRepaintBoundary;
                              ui.Image image =
                                  await boundary.toImage(pixelRatio: 3.0);
                              ByteData? byteData = await image.toByteData(
                                  format: ui.ImageByteFormat.png);
                              Uint8List pngBytes =
                                  byteData!.buffer.asUint8List();

                              widget.onSignatureSaved(pngBytes);
                              Navigator.pop(context);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Signature saved!"),
                                  backgroundColor: Colors.green,
                                ),
                              );
                            } catch (e) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text("Error saving signature: $e"),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            }
                          }
                        : null,
                    style: ElevatedButton.styleFrom(
                      backgroundColor:
                          hasSignature ? Color(0XFF4675C0) : Colors.grey,
                      foregroundColor: Colors.white,
                    ),
                    child: Text("Save"),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class SignaturePainter extends CustomPainter {
  final List<Offset?> points;

  SignaturePainter(this.points);

  @override
  void paint(Canvas canvas, Size size) {
    Paint paint = Paint()
      ..color = Colors.black
      ..strokeCap = StrokeCap.round
      ..strokeJoin = StrokeJoin.round
      ..strokeWidth = 3.0
      ..style = PaintingStyle.stroke;

    print(
        "Painting signature with ${points.length} points on canvas size: $size");

    if (points.isEmpty) {
      print("No points to paint");
      return;
    }

    // Paint setup for signature drawing
    paint.color = Colors.black;
    paint.style = PaintingStyle.stroke;

    // Draw all lines between consecutive non-null points
    for (int i = 0; i < points.length - 1; i++) {
      if (points[i] != null && points[i + 1] != null) {
        canvas.drawLine(points[i]!, points[i + 1]!, paint);
        print("Drawing line from ${points[i]} to ${points[i + 1]}");
      }
    }

    // Draw dots for single points
    paint.style = PaintingStyle.fill;
    for (int i = 0; i < points.length; i++) {
      if (points[i] != null) {
        canvas.drawCircle(points[i]!, 3.0, paint);
        print("Drawing dot at ${points[i]}");
      }
    }
  }

  @override
  bool shouldRepaint(SignaturePainter oldDelegate) {
    return true; // Always repaint to ensure real-time updates
  }
}
