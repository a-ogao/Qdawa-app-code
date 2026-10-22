import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import 'dart:convert';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_icon_button.dart';
import '../../widgets/custom_text_form_field.dart';
import '../pharmacy_list_screen/pharmacy_list_screen.dart';
import '../delivery_details/delivery_details.dart'; // Import the SignUpScreen
import 'package:shared_preferences/shared_preferences.dart';
import '../doctor/doctoruser_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'dart:io';
import 'package:http/http.dart' as http;

class ScannedPrescriptionScreen extends StatefulWidget {
  @override
  _ScannedPrescriptionScreenState createState() =>
      _ScannedPrescriptionScreenState();
}

class _ScannedPrescriptionScreenState extends State<ScannedPrescriptionScreen> {
  List<dynamic> _prescriptions = [];
  TextEditingController toponeController = TextEditingController();
  String userType = "";
  String scantype = "";
  bool _isProcessing = true;

  @override
  void initState() {
    super.initState();
    _loadPrescriptions();
    _autoProceed();
  }

  // Function to load prescription data from SharedPreferences
  Future<void> _loadPrescriptions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? prescriptionData = prefs.getString('prescription');
    String? userDataString = prefs.getString('userData');
    scantype = prefs.getString('scantype').toString();
    if (userDataString != null) {
      final Map<String, dynamic> userData = json.decode(userDataString);
      String userId = userData['id'].toString() ?? '';
      userType = userData['usr_user_type'].toString() ?? '';
      print(userType);
      if (userId.isEmpty) {
        setState(() {
          print("User ID not found. Please log in again.");
        });
        return;
      }
    }
    if (prescriptionData != null) {
      setState(() {
        _prescriptions = jsonDecode(prescriptionData);
      });
      print("Loaded Prescriptions: $_prescriptions");
    } else {
      print("No prescription data found in SharedPreferences.");
    }
  }

  Future<void> _saveUpdatedPrescriptions() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.remove('prescription'); // Remove previous
    await prefs.setString(
        'prescription', jsonEncode(_prescriptions)); // Save updated
    print("Updated prescriptions saved: $_prescriptions");
  }

  // Auto proceed function to skip user review
  Future<void> _autoProceed() async {
    // Wait for 2 seconds to show processing
    await Future.delayed(Duration(seconds: 2));

    if (mounted) {
      setState(() {
        _isProcessing = false;
      });

      // Automatically proceed to next screen
      await _proceedToNext();
    }
  }

  // Extract the proceed logic into a separate method
  Future<void> _proceedToNext() async {
    if (userType == 'healthcare_provider' && scantype != 'userside') {
      var userId = "0";
      await _saveUpdatedPrescriptions();
      //  await _uploadLabReport(userId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DoctoruserScreen(),
        ),
      );
    } else {
      var userId = "0";
      await _saveUpdatedPrescriptions();
      await _uploadLabReport(userId);
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (context) => DeliveryScreen(),
        ),
      );
    }
  }

  File? _labReportFile;
  String? _labReportFileName;

  Future<void> _pickLabReport() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg'],
    );

    if (result != null) {
      setState(() {
        _labReportFile = File(result.files.single.path!);
        _labReportFileName = result.files.single.name;
      });
    }
  }

  Future<void> _uploadLabReport(String userId) async {
    if (_labReportFile == null) return;

    var request = http.MultipartRequest(
      'POST',
      Uri.parse(AppConfig.buildApiUrl('uploadlab_report')),
    );

    request.fields['user_id'] = userId;
    request.files.add(await http.MultipartFile.fromPath(
      'lab_report',
      _labReportFile!.path,
    ));

    var response = await request.send();
    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);

      String? filePath = data['path'];
      if (filePath != null) {
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('lab_report_file_path', filePath);
        print("Saved file path to session: $filePath");
      } else {
        print("File path not found in response.");
      }
    } else {
      print("Failed to upload lab report. Status: ${response.statusCode}");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      resizeToAvoidBottomInset: false,
      body: SafeArea(
        child: Container(
          height: SizeUtils.height,
          width: double.maxFinite,
          child: Stack(
            alignment: Alignment.center,
            children: [
              Container(
                height: SizeUtils.height,
                child: Stack(
                  alignment: Alignment.center,
                  children: [
                    Container(
                      width: double.maxFinite,
                      padding: EdgeInsets.symmetric(
                        horizontal: 16.h,
                        vertical: 22.h,
                      ),
                      decoration: AppDecoration.fillGray.copyWith(
                        borderRadius: BorderRadiusStyle.roundedBorder30,
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Spacer(flex: 18),
                          _isProcessing
                              ? _buildProcessingScreen()
                              : _buildPrescriptionList(context),
                          Spacer(flex: 10),
                          if (!_isProcessing &&
                              userType != 'healthcare_provider')
                            Padding(
                              padding: const EdgeInsets.all(12.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    "Upload Lab Report (Optional):",
                                    style: theme.textTheme.titleSmall,
                                  ),
                                  SizedBox(height: 8),
                                  Row(
                                    children: [
                                      SizedBox(
                                        width:
                                            160, // You can adjust this width as needed
                                        child: ElevatedButton.icon(
                                          onPressed: _pickLabReport,
                                          icon: Icon(Icons.upload_file),
                                          label: Text("Choose File"),
                                          style: ElevatedButton.styleFrom(
                                            foregroundColor: Colors.white,
                                            backgroundColor:
                                                Theme.of(context).primaryColor,
                                          ),
                                        ),
                                      ),
                                      SizedBox(width: 10),
                                      Flexible(
                                        child: Text(
                                          _labReportFileName ??
                                              "No file selected",
                                          overflow: TextOverflow.ellipsis,
                                        ),
                                      )
                                    ],
                                  ),
                                ],
                              ),
                            ),
                          Spacer(flex: 82),
                          if (!_isProcessing)
                            CustomElevatedButton(
                              text: "Next",
                              margin: EdgeInsets.only(
                                left: 16.h,
                                right: 14.h,
                              ),
                              rightIcon: Container(
                                margin: EdgeInsets.only(left: 2.h),
                                child: CustomImageView(
                                  imagePath:
                                      ImageConstant.imgArrowrightGray5003,
                                  height: 24.h,
                                  width: 24.h,
                                  fit: BoxFit.contain,
                                ),
                              ),
                              onPressed: _proceedToNext,
                            ),
                        ],
                      ),
                    ),
                    Align(
                      alignment: Alignment.topCenter,
                      child: SizedBox(
                        width: double.maxFinite,
                        child: Column(
                          mainAxisSize: MainAxisSize.min,
                          children: [_buildTopHeader(context)],
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

  Widget _buildProcessingScreen() {
    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(right: 6.h),
      padding: EdgeInsets.symmetric(vertical: 40.h, horizontal: 20.h),
      decoration: AppDecoration.fFFFFFDropShadow.copyWith(
        borderRadius: BorderRadiusStyle.roundedBorder5,
      ),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(
            valueColor: AlwaysStoppedAnimation<Color>(Color(0XFF4675C0)),
            strokeWidth: 3,
          ),
          SizedBox(height: 24.h),
          Text(
            "Processing Prescription...",
            style: theme.textTheme.titleMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
            textAlign: TextAlign.center,
          ),
          SizedBox(height: 8.h),
          Text(
            "AI is analyzing your prescription and preparing it for submission",
            style: theme.textTheme.bodyMedium?.copyWith(
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionList(BuildContext context) {
    return _prescriptions.isEmpty
        ? const Center(
            child: Text("No prescriptions found."),
          )
        : Container(
            width: double.maxFinite,
            margin: EdgeInsets.only(right: 6.h),
            padding: EdgeInsets.symmetric(vertical: 6.h),
            decoration: AppDecoration.fFFFFFDropShadow.copyWith(
              borderRadius: BorderRadiusStyle.roundedBorder5,
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Row
                SizedBox(
                  width: double.maxFinite,
                  child: Column(
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text("Sr.",
                                style: theme.textTheme.titleMedium,
                                textAlign: TextAlign.center),
                          ),
                          Expanded(
                            flex: 4,
                            child: Text("Item Name",
                                style: theme.textTheme.titleMedium),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text("Quantity",
                                style: theme.textTheme.titleMedium),
                          ),
                          if (userType == 'healthcare_provider')
                            Expanded(
                              flex: 3,
                              child: Text("Dosage",
                                  style: theme.textTheme.titleMedium),
                            ),
                        ],
                      ),
                      SizedBox(height: 4.h),
                      Divider(),
                    ],
                  ),
                ),
                SizedBox(height: 10.h),

                // List of Prescriptions
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _prescriptions.length,
                  itemBuilder: (context, index) {
                    final prescription = _prescriptions[index];
                    return Container(
                      width: double.maxFinite,
                      margin: EdgeInsets.only(left: 6.h, bottom: 6.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.start,
                        children: [
                          Expanded(
                            flex: 1,
                            child: Text(
                              "${index + 1}",
                              style: theme.textTheme.titleSmall,
                              textAlign: TextAlign.center,
                            ),
                          ),
                          Expanded(
                            flex: 4,
                            child: userType == 'healthcare_provider'
                                ? TextFormField(
                                    initialValue: prescription['medicine_name'],
                                    decoration: const InputDecoration(
                                      border: InputBorder.none,
                                      isDense: true,
                                      contentPadding: EdgeInsets.zero,
                                    ),
                                    style: theme.textTheme.titleSmall,
                                    onChanged: (value) {
                                      _prescriptions[index]['medicine_name'] =
                                          value;
                                    },
                                  )
                                : Text(
                                    prescription['medicine_name'] ?? 'Unknown',
                                    style: theme.textTheme.titleSmall,
                                  ),
                          ),
                          Expanded(
                            flex: 2,
                            child: Text(
                              "${int.tryParse(prescription['quantity'].toString()) ?? 1}",
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                          if (userType == 'healthcare_provider')
                            Expanded(
                              flex: 3,
                              child: DropdownButtonFormField<int>(
                                value: _prescriptions[index]['dosage'] != null
                                    ? int.tryParse(_prescriptions[index]
                                            ['dosage']
                                        .toString())
                                    : 0,
                                items: List.generate(
                                  5,
                                  (i) => DropdownMenuItem<int>(
                                    value: i,
                                    child: Text(i.toString(),
                                        style: theme.textTheme.titleSmall),
                                  ),
                                ),
                                decoration: const InputDecoration(
                                  border: InputBorder.none,
                                  isDense: true,
                                  contentPadding: EdgeInsets.zero,
                                ),
                                style: theme.textTheme.titleSmall,
                                onChanged: (value) {
                                  _prescriptions[index]['dosage'] = value ?? 0;
                                },
                              ),
                            ),
                        ],
                      ),
                    );
                  },
                ),

                SizedBox(height: 10.h),

                // Add More Button (only for healthcare_provider)
                if (userType == 'healthcare_provider')
                  Align(
                    alignment: Alignment.centerRight,
                    child: Padding(
                      padding: EdgeInsets.only(right: 16.h),
                      child: TextButton.icon(
                        onPressed: () {
                          setState(() {
                            _prescriptions.add({
                              'medicine_name': '',
                              'quantity': 1,
                              'dosage': '',
                            });
                          });
                        },
                        icon: Icon(Icons.add, size: 18.h),
                        label:
                            Text("Add More", style: theme.textTheme.titleSmall),
                      ),
                    ),
                  ),

                SizedBox(height: 12.h),
              ],
            ),
          );
  }

  /// Section Widget for the top header
  Widget _buildTopHeader(BuildContext context) {
    return SizedBox(
      width: double.maxFinite,
      child: Align(
        alignment: Alignment.topCenter,
        child: Container(
          padding: EdgeInsets.all(18.h),
          decoration: AppDecoration.fillPrimary,
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(context);
                },
                child: CustomImageView(
                  imagePath: ImageConstant.imgArrowDown,
                  // height: 14.h,
                  // width: 24.h,
                  // alignment: Alignment.topCenter,
                  // margin: EdgeInsets.only(top: 7.h),
                ),
              ),
              Spacer(),
              Text(
                "Prescription Read",
                style: CustomTextStyles.titleMediumWhiteA700Bold,
              ),
              Padding(
                padding: EdgeInsets.only(left: 0.h, top: 31.h, right: 150.h),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
