import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../core/config/app_config.dart';
import '../../../theme/custom_button_style.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_switch.dart';
import '../../../widgets/custom_text_form_field.dart';
import 'pharmacy_usersymptoms_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'package:geolocator/geolocator.dart';

class SubmitOTCScreen extends StatefulWidget {
  final int id;

  const SubmitOTCScreen({required this.id, Key? key}) : super(key: key);

  @override
  _SubmitOTCScreenState createState() => _SubmitOTCScreenState();
}

class _SubmitOTCScreenState extends State<SubmitOTCScreen> {
  List<dynamic> quotations = [];
  List<dynamic> address = [];
  List<dynamic> symtoms = [];
  bool isLoading = true;
  double totalAmount = 0;
  String ordertypee = ''; // Define ordertypee at the class level
  bool showSymptomDetails = false; // 🔹 Default: Hidden

  String prescriptionImageUrl =
      AppConfig.aipInputUrl("2025-03-07/67ca9b829d6e3.png");
  List<TextEditingController> perunitControllers = [];
  List<TextEditingController> amountControllers = [];
  List<TextEditingController> qtyControllers = [];
  List<TextEditingController> itemControllers = [];
  TextEditingController deliveryChargeController =
      TextEditingController(text: "0");
  Map<String, dynamic> symptomData = {};
  bool _isSubmitting = false;

  @override
  void initState() {
    super.initState();

    fetchQuotationItems(widget.id);
  }

  Future<void> fetchQuotationItems(int id) async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('userData');

      if (userDataString == null) {
        // Handle missing userData (e.g., redirect to login)
        print("User data is not available");
        return;
      }
      final Map<String, dynamic> userData = json.decode(userDataString);

      // Extract the 'id' field
      final int? userId = userData['id'];

      if (userId == null) {
        // Handle missing 'id' in userData
        print("User ID is not available in userData");
        return;
      }

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('quotation_details')),
        body: {
          'usr_id': userId.toString(),
          'request_id': id.toString(), // Convert to string
        }, // Pass requestId here
      );
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (!mounted) return;
        setState(() {
          quotations = data['quotations'] ?? [];
          address = data['address'] ?? [];
          symtoms = data['symtoms'] ?? [];
          String requesttypee = quotations.first['requesttype'];
          if (requesttypee.toLowerCase() == "Sym") {
            symptomData = {
              "Year of Birth":
                  symtoms.first['mds_year']?.toString() ?? "Not available",
              "Safety Information":
                  symtoms.first['mds_safety']?.toString() ?? "Not available",
              "Symptoms": symtoms.first['mds_symptom_desc'] ?? "Not available",
              "Duration": symtoms.first['mds_duration'] ?? "Not available",
              "Triggers": symtoms.first['mds_triggers'] ?? "Not available",
              "Severity": symtoms.first['mds_severity'] ?? "N/A",
              "Medical History":
                  symtoms.first['mds_medicalhistory'] ?? "Not available",
              "Current Medications":
                  symtoms.first['mds_currentmedications'] ?? "Not available",
              "Previous Remedies":
                  symtoms.first['mds_previousremedies'] ?? "Not available",
              "Lifestyle Factors":
                  symtoms.first['mds_lifestylefactors'] == "Y" ? "Yes" : "No",
            };
            print(symptomData);
          }

          isLoading = false;
          initializeControllers(); // Initialize controllers after data is set
        });
      } else {
        print("Failed to fetch quotations: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching quotations: $e");
    }
  }

  void initializeControllers() {
    amountControllers.clear();
    perunitControllers.clear();
    qtyControllers.clear();
    for (var quotation in quotations) {
      amountControllers.add(TextEditingController(
        text: "0",
      ));
      perunitControllers.add(TextEditingController(
        text: "0",
      ));
      qtyControllers.add(TextEditingController(
        text: quotation['qri_qty']?.toString() ?? "0",
      ));
      itemControllers.add(TextEditingController(
        text: quotation['qri_item_name']?.toString() ?? "0",
      ));
    }
  }

  void _showRejectReasonDialog() {
    TextEditingController reasonController = TextEditingController();

    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Reject OTC"),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Text("Please provide a reason for rejection:"),
              SizedBox(height: 10),
              TextField(
                controller: reasonController,
                decoration: InputDecoration(
                  hintText: "Enter reason",
                  border: OutlineInputBorder(),
                ),
                maxLines: 3,
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(context); // Close dialog
              },
              child: Text("Cancel"),
            ),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                //backgroundColor: Colors.blue, // Button background color
                foregroundColor: Colors.white, // Text color
              ),
              onPressed: () {
                if (reasonController.text.isNotEmpty) {
                  Navigator.pop(context); // Close dialog
                  _rejectrequest(reasonController.text); // Call reject function
                } else {
                  ScaffoldMessenger.of(context).showSnackBar(
                    SnackBar(content: Text("Please enter a reason")),
                  );
                }
              },
              child: Text("Submit"),
            ),
          ],
        );
      },
    );
  }

  void _rejectrequest(String reason) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('reject_request')),
        body: {
          'request_id': widget.id.toString(), // Convert to string
          'reason': reason, // Send rejection reason
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['message'] ??
                  "OTC Request Rejected Successfully and sent to User!"),
              backgroundColor: Colors.green),
        );

        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => PharmacySymptomsScreen()));
      } else {
        print("Failed to reject request: ${response.statusCode}");
      }
    } catch (e) {
      print("Error rejecting request: $e");
    }
  }

// Method to submit the updated quotation
  void _submittQuotation() async {
    if (_isSubmitting) return; // Prevent double tap

    setState(() {
      _isSubmitting = true;
    });
    try {
      // Create a list of updated quotations with edited quantities and amounts
      List<Map<String, dynamic>> updatedQuotations = [];

      for (int i = 0; i < quotations.length; i++) {
        final amount = double.tryParse(amountControllers[i].text) ?? 0;

        if (amount <= 0) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(
                  "Please enter a valid amount for medicine: ${itemControllers[i].text}"),
              backgroundColor: Colors.red,
            ),
          );

          setState(() {
            _isSubmitting = false;
          });

          return; // Stop submission
        }
        updatedQuotations.add({
          'request_id': quotations[i]['myrequestid'],
          'item_amount_perunit': perunitControllers[i].text,
          'item_qty': qtyControllers[i].text,
          'item_amount': amountControllers[i].text,
          'item_name': itemControllers[i].text,
          'usr_id': quotations[i]['usr_id_created_by'],
          'qre_order_type': quotations[i]['qre_order_type'],
          'requesttype': quotations[i]['requesttype'],
          'delivery_charge': deliveryChargeController.text,
        });
      }

      // Prepare the request body
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('userData');
      final Map<String, dynamic> userData = json.decode(userDataString ?? '{}');
      final int? userId = userData['id'];
      if (userId == null) {
        print("User ID is not available");
        setState(() {
          _isSubmitting = false;
        });
        return;
      }

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('pharmacy_otcsubmit_quotation')),
        body: {
          'pharmacy_id': userId.toString(),
          'quotations': jsonEncode(updatedQuotations),
        },
      );
      // print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['message'] ??
                  "Quotation Submit Successfully and sent to User!"),
              backgroundColor: Colors.green),
        );

        Navigator.pushReplacement(context,
            MaterialPageRoute(builder: (context) => PharmacySymptomsScreen()));
      } else {
        print("Failed to submit quotation: ${response.statusCode}");
      }
    } catch (e) {
      print("Error submitting quotation: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Error: $e")),
      );
    } finally {
      setState(() {
        _isSubmitting = false;
      });
    }
  }

  Future<void> _getLocation(String latitude, String longitude) async {
    final Uri googleMapsUrl =
        Uri.parse("https://www.google.com/maps?q=$latitude,$longitude");
    // await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication);

    if (!await launchUrl(googleMapsUrl, mode: LaunchMode.externalApplication)) {
      throw 'Could not launch $googleMapsUrl';
    }
  }

  @override
  void dispose() {
    for (var controller in amountControllers) {
      controller.dispose();
    }
    for (var controller in perunitControllers) {
      controller.dispose();
    }
    for (var controller in qtyControllers) {
      controller.dispose();
    }
    for (var controller in itemControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildQuotationDetails(BuildContext context) {
    double totalAmount = 0;

    totalAmount = quotations.fold(
      0,
      (sum, quotation) {
        int index = quotations.indexOf(quotation);
        double qty = double.tryParse(qtyControllers[index].text) ?? 0;
        double perUnit = double.tryParse(perunitControllers[index].text) ?? 0;
        double itemTotal = qty * perUnit;
        return sum + itemTotal;
      },
    );

    // Use the same logic as address display to determine if it's delivery
    String adrAddress1 = '';
    String adrCity = '';
    String adrPostalCode = '';
    if (address.isNotEmpty) {
      adrAddress1 = address.first['adr_address_1'].toString();
      adrCity = address.first['adr_city'].toString();
      adrPostalCode = address.first['adr_postal_code'].toString();
    }
    bool isDeliveryOrder = address.isNotEmpty &&
        !(adrAddress1.isEmpty && adrCity.isEmpty && adrPostalCode.isEmpty);

    String requesttype = '';
    if (quotations.isNotEmpty) {
      requesttype = quotations.first['requesttype'].toString();
    }

    if (isDeliveryOrder) {
      double deliveryCharge =
          double.tryParse(deliveryChargeController.text) ?? 0;
      totalAmount += deliveryCharge;
    }

    return quotations.isEmpty
        ? const Center(child: Text("No quotations found."))
        : SingleChildScrollView(
            child: Container(
              width: double.maxFinite,
              margin: EdgeInsets.only(right: 6.h),
              padding: EdgeInsets.symmetric(vertical: 8.h),
              decoration: AppDecoration.fFFFFFDropShadow.copyWith(
                borderRadius: BorderRadiusStyle.roundedBorder5,
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  SizedBox(height: 6.h),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16.h),
                    child: Row(
                      children: [
                        Expanded(
                            flex: 1,
                            child: Text("Sr.",
                                style: theme.textTheme.titleMedium)),
                        Expanded(
                            flex: 3,
                            child: Text("Item Name",
                                style: theme.textTheme.titleMedium)),
                        Expanded(
                            flex: 1,
                            child: Text("Qty",
                                style: theme.textTheme.titleMedium)),
                        Expanded(
                            flex: 1,
                            child: Text("Price",
                                style: theme.textTheme.titleMedium)),
                        Expanded(
                          flex: 2,
                          child: Text("Amount",
                              style: theme.textTheme.titleMedium,
                              textAlign: TextAlign.end),
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                  SizedBox(height: 6.h),
                  ListView.builder(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: quotations.length,
                    itemBuilder: (context, index) {
                      return _buildQuotationRow(index);
                    },
                  ),
                  Divider(),
                  SizedBox(height: 8.h),

                  // Add Item Button
                  if (requesttype == 'Sym')
                    Align(
                      alignment: Alignment.centerRight,
                      child: TextButton.icon(
                        onPressed: _addNewQuotation,
                        icon: Icon(Icons.add, color: Colors.blue),
                        label: Text("Add More",
                            style: TextStyle(color: Colors.blue)),
                      ),
                    ),

                  if (isDeliveryOrder)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text("Delivery charges",
                                style: theme.textTheme.titleSmall,
                                textAlign: TextAlign.center),
                          ),
                          SizedBox(
                            width: 60,
                            child: TextFormField(
                              textAlign: TextAlign.right,
                              style: theme.textTheme.titleSmall,
                              controller: deliveryChargeController,
                              keyboardType: TextInputType.number,
                              onChanged: (value) {
                                setState(() {
                                  // Trigger rebuild to update total display
                                  // The total calculation is handled in _buildQuotationDetails method
                                });
                              },
                              decoration: InputDecoration(
                                hintText: "charge",
                                border: InputBorder.none,
                                contentPadding: EdgeInsets.zero,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ),
                  Divider(color: appTheme.gray300),
                  Padding(
                    padding: EdgeInsets.symmetric(horizontal: 10.h),
                    child: Row(
                      children: [
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment
                                .topRight, // Ensures "Total" stays on the left
                            child: Text(
                              "Total :",
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                        ),
                        Expanded(
                          flex: 1,
                          child: Align(
                            alignment: Alignment
                                .centerRight, // Ensures total amount stays on the right
                            child: Text(
                              "KSH: ${totalAmount.toStringAsFixed(2)}",
                              style: theme.textTheme.titleSmall,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          );
  }

// Method to build each row dynamically
  Widget _buildQuotationRow(int index) {
    String requesttype = '';
    if (quotations.isNotEmpty) {
      requesttype = quotations.first['requesttype'].toString();
    }
    final quotation = quotations[index];

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 2.h),
      child: Row(
        children: [
          Expanded(
              flex: 1,
              child: Text((index + 1).toString(),
                  style: theme.textTheme.titleSmall)),
          Expanded(
            flex: 3,
            child: TextFormField(
              controller: itemControllers[index],
              decoration: const InputDecoration(
                  hintText: "Name", border: InputBorder.none),
              keyboardType: TextInputType.text,
            ),
          ),
          Expanded(
            flex: 1,
            child: TextFormField(
              controller: qtyControllers[index],
              decoration: const InputDecoration(
                  hintText: "Qty", border: InputBorder.none),
              keyboardType: TextInputType.number,
              onChanged: (value) => _updateTotal(),
            ),
          ),
          Expanded(
            flex: 1,
            child: TextFormField(
              controller: perunitControllers[index],
              decoration: const InputDecoration(
                  hintText: "Per Unit Amt", border: InputBorder.none),
              keyboardType: TextInputType.number,
              onChanged: (value) => _updateTotal(),
            ),
          ),
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: amountControllers[index],
              decoration: const InputDecoration(
                  hintText: "Amount", border: InputBorder.none),
              keyboardType: TextInputType.number,
              readOnly: true,
              textAlign: TextAlign.end,
            ),
          ),
          if (index != 0) // Remove button for all rows except the first

            if (requesttype == 'Sym')
              IconButton(
                icon: Icon(Icons.delete, color: Colors.red),
                onPressed: () => _removeQuotation(index),
              ),
        ],
      ),
    );
  }

// Method to add new quotation row
  void _addNewQuotation() {
    setState(() {
      quotations.add({'qri_qty': '', 'qri_price': ''});
      itemControllers.add(TextEditingController());
      qtyControllers.add(TextEditingController());
      perunitControllers.add(TextEditingController());
      amountControllers.add(TextEditingController());
    });
  }

// Method to remove a quotation row
  void _removeQuotation(int index) {
    setState(() {
      quotations.removeAt(index);
      itemControllers.removeAt(index);
      qtyControllers.removeAt(index);
      perunitControllers.removeAt(index);
      amountControllers.removeAt(index);
    });
  }

// Method to update total amount dynamically
  void _updateTotal() {
    setState(() {
      double total = 0;
      for (int i = 0; i < quotations.length; i++) {
        double qty = double.tryParse(qtyControllers[i].text) ?? 0;
        double perUnit = double.tryParse(perunitControllers[i].text) ?? 0;
        double itemTotal = qty * perUnit;
        amountControllers[i].text = itemTotal.toStringAsFixed(2);
        total += itemTotal;
      }

      // Use the same logic as address display to determine if it's delivery
      String adrAddress1 = '';
      String adrCity = '';
      String adrPostalCode = '';
      if (address.isNotEmpty) {
        adrAddress1 = address.first['adr_address_1'].toString();
        adrCity = address.first['adr_city'].toString();
        adrPostalCode = address.first['adr_postal_code'].toString();
      }
      bool isDeliveryOrder = address.isNotEmpty &&
          !(adrAddress1.isEmpty && adrCity.isEmpty && adrPostalCode.isEmpty);

      if (isDeliveryOrder) {
        double deliveryCharge =
            double.tryParse(deliveryChargeController.text) ?? 0;
        total += deliveryCharge;
      }
      totalAmount = total;
    });
  }

  @override
  Widget build(BuildContext context) {
    String qre_quotation_status = '';
    if (quotations.isNotEmpty) {
      qre_quotation_status =
          quotations.first['qre_quotation_status'].toString();
    }
    String requesttypee = '';
    if (quotations.isNotEmpty) {
      requesttypee = quotations.first['requesttype'].toString();
    }

    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        title: Text("OTC Request",
            style: TextStyle(color: Colors.white, fontSize: 20)),
        centerTitle: true,
        backgroundColor: theme.colorScheme.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : SingleChildScrollView(
                // 🔹 Make entire UI scrollable
                child: Container(
                  width: double.infinity,
                  padding:
                      EdgeInsets.symmetric(horizontal: 16.h, vertical: 22.h),
                  child: Column(
                    children: [
                      _buildAddress(context),
                      SizedBox(height: 10),

                      // 🔹 Toggle Button for Symptoms
                      if (requesttypee == "Sym")
                        Column(
                          children: [
                            ElevatedButton.icon(
                              onPressed: () {
                                setState(() {
                                  showSymptomDetails = !showSymptomDetails;
                                });
                              },
                              icon: Icon(
                                showSymptomDetails
                                    ? Icons.keyboard_arrow_up
                                    : Icons.keyboard_arrow_down,
                                color: Colors.white, // Set icon color
                              ),
                              label: Text(
                                showSymptomDetails
                                    ? "Hide Symptoms"
                                    : "Show Symptoms",
                                style: TextStyle(
                                    color: Colors.white), // Set text color
                              ),
                              style: ElevatedButton.styleFrom(
                                backgroundColor: theme.colorScheme
                                    .primary, // Set button background color
                                foregroundColor: theme.colorScheme
                                    .primary, // Set button text/icon color

                                padding: EdgeInsets.symmetric(
                                    horizontal: 20, vertical: 12), // Padding
                              ),
                            ),
                            SizedBox(height: 10),
                          ],
                        ),

                      // 🔹 Show Symptom Details only when enabled
                      if (requesttypee == "Sym" && showSymptomDetails)
                        _buildSymptomDisplay(),
                      SizedBox(height: 10),
                      _buildQuotationHeader(context),
                      _buildQuotationDetails(context),
                      SizedBox(height: 15),
                      // 🔹 Buttons for actions
                      if (qre_quotation_status == 'pending') ...[
                        _isSubmitting
                            ? const CircularProgressIndicator() // Show loading indicator while submitting
                            : CustomElevatedButton(
                                text: "Submit Quotation",
                                margin:
                                    EdgeInsets.only(left: 16.h, right: 14.h),
                                rightIcon: Container(
                                  margin: EdgeInsets.only(left: 15.h),
                                  child: CustomImageView(
                                    imagePath:
                                        ImageConstant.imgArrowrightGray5003,
                                    height: 24.h,
                                    width: 24.h,
                                    fit: BoxFit.contain,
                                  ),
                                ),
                                onPressed: _submittQuotation,
                              ),
                        SizedBox(height: 10),
                        CustomElevatedButton(
                          text: "Reject OTC",
                          margin: EdgeInsets.only(left: 16.h, right: 14.h),
                          rightIcon: Container(
                            margin: EdgeInsets.only(left: 15.h),
                            child: CustomImageView(
                              imagePath: ImageConstant.imgArrowrightGray5003,
                              height: 24.h,
                              width: 24.h,
                              fit: BoxFit.contain,
                            ),
                          ),
                          onPressed: _showRejectReasonDialog,
                        ),
                      ],
                    ],
                  ),
                ),
              ),
      ),
    );
  }

  /// **Symptom Data Display Widget**
  Widget _buildSymptomDisplay() {
    return Card(
      elevation: 6,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text("🩺 Symptom Details",
                style: TextStyle(fontSize: 22, fontWeight: FontWeight.bold)),
            SizedBox(height: 10),
            _buildInfoRow(
                "Year of Birth",
                symtoms.isNotEmpty && symtoms.first['mds_year'] != null
                    ? symtoms.first['mds_year'].toString()
                    : "Not available"),
            _buildInfoRow(
                "Safety Information",
                symtoms.isNotEmpty && symtoms.first['mds_safety'] != null
                    ? symtoms.first['mds_safety'].toString()
                    : "Not available"),
            _buildInfoRow(
                "Symptoms",
                symtoms.isNotEmpty
                    ? symtoms.first['mds_symptom_desc'] ?? "Not available"
                    : "Not available"),
            _buildInfoRow(
                "Duration", symtoms.first['mds_duration'] ?? "Not available"),
            _buildInfoRow(
                "Triggers", symtoms.first['mds_triggers'] ?? "Not available"),
            _buildInfoRow("Severity", symtoms.first['mds_severity'] ?? "N/A"),
            _buildInfoRow("Medical History",
                symtoms.first['mds_medicalhistory'] ?? "Not available"),
            _buildInfoRow("Current Medications",
                symtoms.first['mds_currentmedications'] ?? "Not available"),
            _buildInfoRow("Previous Remedies",
                symtoms.first['mds_previousremedies'] ?? "Not available"),
            _buildInfoRow("Lifestyle Factors",
                symtoms.first['mds_lifestylefactors'] == "Y" ? "Yes" : "No"),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding:
          const EdgeInsets.symmetric(vertical: 4.0), // Add vertical spacing
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "$label: ",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 16,
              color: Colors.black87,
            ),
          ),
          Expanded(
            child: Text(
              value.isNotEmpty ? value : "N/A",
              style: TextStyle(
                fontSize: 16,
                color: Colors.black54,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildAddress(BuildContext context) {
    String adrAddress1 = '';
    String adrCity = '';
    String adrPostalCode = '';
    String longitude = '';
    String latitude = '';

    if (address.isNotEmpty) {
      adrAddress1 = address.first['adr_address_1'].toString();
      adrCity = address.first['adr_city'].toString();
      adrPostalCode = address.first['adr_postal_code'].toString();
      longitude = address.first['longitude'].toString();
      latitude = address.first['latitude'].toString();
    }
    String prescriptionImageUrll = '';
    String imageUrll = "";
    if (quotations.isNotEmpty) {
      prescriptionImageUrll = quotations.first['qre_pimage_path'].toString();
      imageUrll = prescriptionImageUrll
          .replaceAll('"', '')
          .trim()
          .toString(); // Remove extra double quotes
    }

    // Check if address is empty - show Pickup Order
    bool isPickupOrder = address.isEmpty ||
        (adrAddress1.isEmpty && adrCity.isEmpty && adrPostalCode.isEmpty);

    return Container(
      padding: EdgeInsets.all(12),
      margin: EdgeInsets.symmetric(vertical: 10, horizontal: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(10),
        boxShadow: [
          BoxShadow(
            color: Colors.grey.withOpacity(0.2),
            spreadRadius: 2,
            blurRadius: 5,
            offset: Offset(0, 3),
          ),
        ],
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          // Left Section: Delivery Address or Pickup Order
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isPickupOrder ? "Order Type" : "Delivery Address",
                  style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: Colors.black87),
                ),
                SizedBox(height: 8),

                // Address Display or Pickup Order
                Row(
                  children: [
                    Icon(
                      isPickupOrder ? Icons.store : Icons.location_on,
                      color: isPickupOrder ? Colors.orange : Colors.blueGrey,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        isPickupOrder
                            ? "Pickup Order"
                            : "$adrAddress1, $adrCity, $adrPostalCode",
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.black87,
                          fontWeight: isPickupOrder
                              ? FontWeight.w600
                              : FontWeight.normal,
                        ),
                        overflow: TextOverflow.ellipsis,
                        maxLines: 2,
                      ),
                    ),
                  ],
                ),

                SizedBox(height: 12),

                // Get Location Button (only show for delivery)
                if (!isPickupOrder)
                  ElevatedButton.icon(
                    onPressed: () => _getLocation(latitude, longitude),
                    icon: Icon(Icons.gps_fixed, color: Colors.white),
                    label: Text("Get Location"),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: Theme.of(context).colorScheme.primary,
                      foregroundColor: Colors.white,
                      padding:
                          EdgeInsets.symmetric(vertical: 12, horizontal: 20),
                    ),
                  ),
              ],
            ),
          ),

          // Right Section: Prescription View Icon
        ],
      ),
    );
  }

  /// Section Widget
  Widget _buildQuotationHeader(BuildContext context) {
    String requestId = '';
    String prescriptionImageUrll = '';
    String imageUrll = "";
    if (quotations.isNotEmpty) {
      requestId = quotations.first['qre_request_id'].toString();
      prescriptionImageUrll = quotations.first['qre_pimage_path'].toString();
      imageUrll = prescriptionImageUrll.replaceAll('"', '').trim().toString();
    }
    print(imageUrll);

    return Container(
      width: double.maxFinite,
      margin: EdgeInsets.only(right: 6.h),
      padding: EdgeInsets.symmetric(horizontal: 20.h, vertical: 12.h),
      decoration: AppDecoration.fillPrimary,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween, // Align left & right
        crossAxisAlignment: CrossAxisAlignment.center,
        children: [
          // Left Section: Quotation Request ID
          Text(
            "OTC Request #$requestId",
            style: CustomTextStyles.titleMediumWhiteA700SemiBold,
          ),

          // Right Section: Prescription View Icon
        ],
      ),
    );
  }
}
