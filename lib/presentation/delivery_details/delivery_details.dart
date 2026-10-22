import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import 'dart:convert';
import 'dart:async';
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/app_export.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_image_view.dart';
import '../pharmacy_list_screen/pharmacy_list_screen.dart';
import 'package:geolocator/geolocator.dart';

class DeliveryScreen extends StatefulWidget {
  @override
  _DeliveryScreenState createState() => _DeliveryScreenState();
}

class _DeliveryScreenState extends State<DeliveryScreen> {
  bool isDeliverySelected = true;
  bool isLoading = false; // Added loading state

  TextEditingController addressController = TextEditingController();
  TextEditingController cityController = TextEditingController();
  TextEditingController postalCodeController = TextEditingController();
  String? usr_id;
  double? latitude;
  double? longitude;
  String usertype = "";
  @override
  void initState() {
    super.initState();
    loadUserData();
  }

  Future<void> loadUserData() async {
    if (isLoading) return; // Prevent multiple taps
    setState(() {
      isLoading = true; // Start loading
    });
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('userData');
    String? patientid = prefs.getString('patientid');

    if (userDataString != null) {
      Map<String, dynamic> userData = json.decode(userDataString);
      usertype = userData['usr_user_type'].toString() ?? '';
      if (usertype == 'healthcare_provider') {
        usr_id = patientid.toString();
      } else {
        usr_id = userData['id'].toString();
      }
      fetchExistingAddress();
    }
  }

  Future<void> fetchExistingAddress() async {
    if (usr_id == null) return;

    try {
      var response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('get_address')),
        body: {'usr_id': usr_id.toString()}, // Fix applied here
      );
      //print(response.body);
      if (response.statusCode == 200) {
        Map<String, dynamic> responseData = json.decode(response.body);
        if (responseData['status'] == "success" &&
            responseData['data'] != null) {
          setState(() {
            addressController.text =
                responseData['data']['adr_address_1'] ?? "";
            cityController.text = responseData['data']['adr_city'] ?? "";
            postalCodeController.text =
                responseData['data']['adr_postal_code'] ?? "";
            print(addressController);
          });
        }
      }
    } catch (e) {
      print("Error fetching address: $e");
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  Future<void> submitData() async {
    if (isLoading) return; // Prevent multiple taps

    print("[DeliveryScreen] submitData() called");

    // Validate input fields
    if (isDeliverySelected &&
        (addressController.text.trim().isEmpty ||
            cityController.text.trim().isEmpty ||
            postalCodeController.text.trim().isEmpty)) {
      print(
          "[DeliveryScreen] Validation failed: one or more address fields are empty");
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("All address fields are required")),
      );
      return;
    }

    setState(() {
      isLoading = true; // Start loading
    });

    SharedPreferences prefs = await SharedPreferences.getInstance();
    print("[DeliveryScreen] SharedPreferences loaded");

    Map<String, dynamic> data = {
      "type": isDeliverySelected ? "delivery" : "pickup",
    };
    print("[DeliveryScreen] Order type: ${data["type"]}, isDeliverySelected=$isDeliverySelected");

    if (usr_id == null) {
      print(
          "[DeliveryScreen] WARNING: usr_id is null before submitting delivery data");
    } else {
      print("[DeliveryScreen] Using usr_id=$usr_id");
    }

    try {
      // Check location permission first
      LocationPermission permission = await Geolocator.checkPermission();
      print("[DeliveryScreen] Initial location permission: $permission");

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
        print(
            "[DeliveryScreen] Location permission after request: $permission");
        if (permission == LocationPermission.denied) {
          // User denied permission, continue without location
          print("Location permission denied, proceeding without coordinates");
          latitude = null;
          longitude = null;
        }
      }

      if (permission == LocationPermission.deniedForever) {
        // Permission permanently denied, continue without location
        print(
            "Location permission permanently denied, proceeding without coordinates");
        latitude = null;
        longitude = null;
      } else {
        // Permission granted (or already whileInUse/always)
        try {
          final serviceEnabled =
              await Geolocator.isLocationServiceEnabled().timeout(
                    const Duration(seconds: 5),
                    onTimeout: () => false,
                  );
          print("[DeliveryScreen] isLocationServiceEnabled=$serviceEnabled");

          if (!serviceEnabled) {
            print(
                "[DeliveryScreen] Location services disabled, proceeding without coordinates");
            latitude = null;
            longitude = null;
          } else {
            Position position = await Geolocator.getCurrentPosition(
              desiredAccuracy: LocationAccuracy.medium,
            ).timeout(
              const Duration(seconds: 10),
            );
            latitude = position.latitude;
            longitude = position.longitude;
            print("Location obtained: $latitude, $longitude");
          }
        } on TimeoutException catch (e) {
          print(
              "[DeliveryScreen] Timeout while checking/obtaining location: $e, proceeding without coordinates");
          latitude = null;
          longitude = null;
        } catch (e) {
          print("Error getting location: $e, proceeding without coordinates");
          latitude = null;
          longitude = null;
        }
      }

      if (isDeliverySelected) {
        Map<String, dynamic> requestData = {
          'address': addressController.text.trim(),
          'city': cityController.text.trim(),
          'postal_code': postalCodeController.text.trim(),
          'usr_id': usr_id,
          'latitude': latitude ?? 0.0,
          'longitude': longitude ?? 0.0,
        };
        print("[DeliveryScreen] Sending save_address request with data: "
            "address='${requestData['address']}', "
            "city='${requestData['city']}', "
            "postal_code='${requestData['postal_code']}', "
            "usr_id='${requestData['usr_id']}', "
            "latitude=${requestData['latitude']}, "
            "longitude=${requestData['longitude']}");

        var response = await http.post(
          Uri.parse(AppConfig.buildApiUrl('save_address')),
          headers: {"Content-Type": "application/json"},
          body: jsonEncode(requestData),
        );

        print(
            "[DeliveryScreen] save_address response: status=${response.statusCode}, body=${response.body}");

        if (response.statusCode == 200) {
          await prefs.setString('ordertype', jsonEncode(data));
          print(
              "[DeliveryScreen] Address saved successfully, navigating to PharmacyListScreen");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Address saved successfully!")),
          );

          Navigator.push(
            context,
            MaterialPageRoute(builder: (context) => PharmacyListScreen()),
          );
        } else {
          print(
              "[DeliveryScreen] Failed to save order, status=${response.statusCode}");
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Failed to save order")),
          );
        }
      } else {
        await prefs.setString('ordertype', jsonEncode(data));
        print(
            "[DeliveryScreen] Pickup selected, navigating to PharmacyListScreen");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Pickup selected!")),
        );

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => PharmacyListScreen()),
        );
      }
    } catch (e) {
      print("[DeliveryScreen] Exception in submitData: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      print("[DeliveryScreen] submitData() finished, resetting isLoading=false");
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
          "Delivery or Pickup",
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
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    "Delivery Required",
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Switch(
                    value: isDeliverySelected,
                    onChanged: (value) {
                      setState(() {
                        isDeliverySelected = value;
                      });
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              Expanded(
                child: SingleChildScrollView(
                  child: isDeliverySelected
                      ? Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              "Enter Delivery Address",
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: addressController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "Enter your address",
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: cityController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "Enter your city",
                              ),
                            ),
                            const SizedBox(height: 10),
                            TextField(
                              controller: postalCodeController,
                              decoration: const InputDecoration(
                                border: OutlineInputBorder(),
                                hintText: "Enter your postal code",
                              ),
                            ),
                          ],
                        )
                      : const Center(
                          child: Text(
                            "Pickup from store",
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                ),
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
