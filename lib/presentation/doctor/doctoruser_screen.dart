import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_image_view.dart';
import '../pharmacy_list_screen/pharmacy_list_screen.dart';
import 'package:geolocator/geolocator.dart';
import '../delivery_details/delivery_details.dart';

class DoctoruserScreen extends StatefulWidget {
  @override
  _DoctoruserScreenState createState() => _DoctoruserScreenState();
}

class _DoctoruserScreenState extends State<DoctoruserScreen> {
  bool isDeliverySelected = true;
  bool isLoading = false; // Added loading state

  TextEditingController addressController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController postalCodeController = TextEditingController();
  int? usr_id;
  double? latitude;
  double? longitude;
  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    if (isLoading) return; // Prevent multiple taps
    setState(() {
      isLoading = false; // Start loading
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('userData');
    if (userDataString != null) {
      Map<String, dynamic> userData = json.decode(userDataString);
      usr_id = userData['id'];
      // fetchExistingUser();
    }
  }

  Future<void> submitData() async {
    if (isLoading) return; // Prevent multiple taps
    //  print(usr_id);
    // Validate input fields
    if ((addressController.text.trim().isEmpty ||
        cityController.text.trim().isEmpty ||
        postalCodeController.text.trim().isEmpty)) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All Patient fields are required")),
      );
      return;
    }

    setState(() {
      isLoading = true; // Start loading
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    try {
      Map<String, dynamic> requestData = {
        'patient_email': addressController.text.trim(),
        'contact_no': cityController.text.trim(),
        'patient_name': postalCodeController.text.trim(),
        'doctor_id': usr_id,
      };

      var response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('save_docuser')),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(requestData),
      );

      print('Status Code: ${response.statusCode}');
      print('Headers: ${response.headers}');
      print('Body: ${response.body}');

      Map<String, dynamic>? responseBody;
      try {
        responseBody = json.decode(response.body);
      } catch (e) {
        throw Exception("Invalid JSON response: ${response.body}");
      }

      if (response.statusCode == 200 && responseBody != null) {
        await prefs.setString(
            'patientid', responseBody['patientid'].toString());
        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DeliveryScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(responseBody?['message'] ?? 'Unknown error'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      print("Exception caught: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text("Unable to save the Patient info"),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        backgroundColor: AppDecoration.fillPrimary.color,
        title: const Text(
          "Enter Patient Details",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0),
          child: Column(
            children: [
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                    child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    TextField(
                      controller: postalCodeController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter Patient Name",
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: addressController,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter Patient Email",
                      ),
                    ),
                    const SizedBox(height: 10),
                    TextField(
                      controller: cityController,
                      keyboardType: TextInputType.phone,
                      decoration: const InputDecoration(
                        border: OutlineInputBorder(),
                        hintText: "Enter Patient Contact No",
                      ),
                      onChanged: (value) {
                        if (!value.startsWith('254') && value.length < 13) {
                          cityController.text =
                              '254' + value.replaceFirst(RegExp(r'^0+'), '');
                          cityController.selection = TextSelection.fromPosition(
                            TextPosition(offset: cityController.text.length),
                          );
                        }
                      },
                    ),
                    const SizedBox(height: 10),
                  ],
                )),
              ),
              Padding(
                padding: const EdgeInsets.only(top: 16.0, bottom: 16.0),
                child: isLoading
                    ? const CircularProgressIndicator() // Show loading
                    : CustomElevatedButton(
                        text: isLoading ? "Please wait..." : "Next",
                        onPressed:
                            isLoading ? null : submitData, // Disable if loading
                      ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
