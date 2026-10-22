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
import 'quotation_requests_pharmacy_screen.dart';
import 'package:url_launcher/url_launcher.dart';
import 'pharmacy_prescription_view_screen.dart';
import '../../../widgets/zoomable_prescription_image_dialog.dart';

class SubmitQuotationScreen extends StatefulWidget {
  final int id;

  const SubmitQuotationScreen({required this.id, Key? key}) : super(key: key);

  @override
  _SubmitQuotationScreenState createState() => _SubmitQuotationScreenState();
}

class _SubmitQuotationScreenState extends State<SubmitQuotationScreen> {
  List<dynamic> quotations = [];
  List<dynamic> address = [];
  bool isLoading = true;
  bool _isSubmitting = false;

  String prescriptionImageUrl =
      AppConfig.aipInputUrl("2025-03-07/67ca9b829d6e3.png");
  List<TextEditingController> perunitControllers = [];
  List<TextEditingController> amountControllers = [];
  List<TextEditingController> qtyControllers = [];
  List<TextEditingController> itemControllers = [];
  List<TextEditingController> dosesControllers = [];
  TextEditingController deliveryChargeController =
      TextEditingController(text: "0");

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
    dosesControllers.clear();
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
      dosesControllers.add(TextEditingController(
        text: quotation['qri_item_dosage']?.toString() ?? "0",
      ));
    }
  }

  void _submitQuotation() async {
    if (_isSubmitting) return; // Prevent double tap

    setState(() {
      _isSubmitting = true;
    });

    try {
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

        final requestId = quotations[i]['myrequestid']?.toString() ??
            quotations[i]['qre_id']?.toString();
        if (requestId == null || requestId.isEmpty) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'Request ID is missing. Please go back and open the request again.',
              ),
              backgroundColor: Colors.red,
            ),
          );
          setState(() {
            _isSubmitting = false;
          });
          return;
        }

        updatedQuotations.add({
          'request_id': requestId,
          'item_amount_perunit': perunitControllers[i].text,
          'item_qty': qtyControllers[i].text,
          'item_amount': amountControllers[i].text,
          'item_dose': dosesControllers[i].text,
          'item_name': itemControllers[i].text,
          'usr_id': quotations[i]['usr_id_created_by'],
          'doctor_id': quotations[i]['qre_doctor_id'],
          'qre_order_type': quotations[i]['qre_order_type'],
          'delivery_charge': deliveryChargeController.text,
        });
      }

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
        Uri.parse(AppConfig.buildApiUrl('pharmacy_submit_quotation')),
        body: {
          'pharmacy_id': userId.toString(),
          'quotations': jsonEncode(updatedQuotations),
        },
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['message'] ??
                  "Quotation Submitted Successfully and sent to User!"),
              backgroundColor: Colors.green),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
            builder: (context) => QuotationRequestsPharmacyScreen(),
          ),
        );
      } else {
        print("Failed to submit quotation: ${response.statusCode}");
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text("Submission failed.")),
        );
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

  void _showPrescriptionImage() {
    if (quotations.isEmpty) return;
    final prescriptionImageUrll =
        quotations.first['qre_orignalfilepath'].toString();
    showZoomablePrescriptionImageDialog(context, prescriptionImageUrll);
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
    for (var controller in dosesControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Widget _buildQuotationDetails(BuildContext context) {
    double totalAmount = 0;

    totalAmount = quotations.fold(
      0,
      (sum, quotation) {
        int qIndex = quotations.indexOf(quotation);
        double qty = double.tryParse(qtyControllers[qIndex].text) ?? 0;
        double perUnit = double.tryParse(perunitControllers[qIndex].text) ?? 0;
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

    if (isDeliveryOrder) {
      double deliveryCharge =
          double.tryParse(deliveryChargeController.text) ?? 0;
      totalAmount += deliveryCharge;
    }

    return quotations.isEmpty
        ? const Center(child: Text("No quotations found."))
        : SingleChildScrollView(
            // ✅ Added Scrollable Widget
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
                            flex: 3,
                            child: Text(
                              "Item Name",
                            )),
                        Expanded(
                            flex: 2,
                            child: Text(
                              "Dosage",
                            )),
                        Expanded(
                            flex: 1,
                            child: Text(
                              "Qty",
                            )),
                        Expanded(
                            flex: 2,
                            child: Text(
                              "Price",
                            )),
                        Expanded(
                          flex: 2,
                          child: Text(
                            "Amount",
                            textAlign: TextAlign.end,
                          ),
                        ),
                      ],
                    ),
                  ),
                  Divider(),
                  SizedBox(height: 6.h),
                  ListView.builder(
                    shrinkWrap: true,
                    physics:
                        const NeverScrollableScrollPhysics(), // ✅ Prevent internal scrolling
                    itemCount: quotations.length,
                    itemBuilder: (context, index) {
                      final quotation = quotations[index];
                      double qty = double.tryParse(
                              qtyControllers[quotations.indexOf(quotation)]
                                  .text) ??
                          0;
                      double perUnit =
                          double.tryParse(perunitControllers[index].text) ?? 0;
                      double itemTotal = qty * perUnit;

                      amountControllers[index].text =
                          itemTotal.toStringAsFixed(2);

                      return Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 16.h, vertical: 2.h),
                        child: Row(
                          children: [
                            /* Expanded(
                                flex: 1,
                                child: Text((index + 1).toString(),
                                    style: theme.textTheme.titleSmall)),*/
                            Expanded(
                                flex: 3,
                                child: TextFormField(
                                  controller: itemControllers[index],
                                  decoration: const InputDecoration(
                                    hintText: "Name",
                                    border: InputBorder.none,
                                  ),
                                  style: const TextStyle(
                                    fontSize:
                                        12, // 👈 Change this value to your desired size
                                    // Optional
                                  ),
                                  keyboardType: TextInputType.text,
                                )),
                            SizedBox(width: 8),
                            Expanded(
                                flex: 2,
                                child: TextFormField(
                                  controller: dosesControllers[index],
                                  decoration: const InputDecoration(
                                    hintText: "Dosage",
                                    border: InputBorder.none,
                                    isDense: true,
                                  ),
                                  style: const TextStyle(
                                    fontSize: 12,
                                  ),
                                  keyboardType: TextInputType.text,
                                ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                                flex: 1,
                                child: TextFormField(
                                controller: qtyControllers[index],
                                decoration: const InputDecoration(
                                  hintText: "Qty",
                                  border: InputBorder.none,
                                ),
                                style: const TextStyle(
                                  fontSize: 12,
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    double newQty =
                                        double.tryParse(value) ?? 0;
                                    double newPerUnit = double.tryParse(
                                            perunitControllers[index].text) ??
                                        0;
                                    itemTotal = newQty * newPerUnit;
                                    amountControllers[index].text =
                                        itemTotal.toStringAsFixed(2);

                                    totalAmount = quotations.fold(
                                      0,
                                      (sum, quotation) {
                                        int qIndex = quotations.indexOf(quotation);
                                        double qty = double.tryParse(
                                                qtyControllers[qIndex].text) ??
                                            0;
                                        double perUnit = double.tryParse(
                                                perunitControllers[qIndex]
                                                    .text) ??
                                            0;
                                        double itemTotal = qty * perUnit;
                                        return sum + itemTotal;
                                      },
                                    );
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: perunitControllers[index],
                                decoration: const InputDecoration(
                                  hintText: "Per Unit Amt",
                                  border: InputBorder.none,
                                ),
                                style: const TextStyle(
                                  fontSize:
                                      12, // 👈 Change this value to your desired size
                                  // Optional
                                ),
                                keyboardType: TextInputType.number,
                                onChanged: (value) {
                                  setState(() {
                                    double newPerUnit =
                                        double.tryParse(value) ?? 0;
                                    double newQty = double.tryParse(
                                            qtyControllers[index].text) ??
                                        0;
                                    itemTotal = newQty * newPerUnit;
                                    amountControllers[index].text =
                                        itemTotal.toStringAsFixed(2);

                                    totalAmount = quotations.fold(
                                      0,
                                      (sum, quotation) {
                                        int qIndex = quotations.indexOf(quotation);
                                        double qty = double.tryParse(
                                                qtyControllers[qIndex].text) ??
                                            0;
                                        double perUnit = double.tryParse(
                                                perunitControllers[qIndex]
                                                    .text) ??
                                            0;
                                        double itemTotal = qty * perUnit;
                                        return sum + itemTotal;
                                      },
                                    );
                                  });
                                },
                              ),
                            ),
                            Expanded(
                              flex: 2,
                              child: TextFormField(
                                controller: amountControllers[index],
                                decoration: const InputDecoration(
                                  hintText: "Price",
                                  border: InputBorder.none,
                                ),
                                style: const TextStyle(
                                  fontSize:
                                      12, // 👈 Change this value to your desired size
                                  // Optional
                                ),
                                keyboardType: TextInputType.number,
                                readOnly: true,
                                textAlign: TextAlign.end,
                              ),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  Divider(),
                  Align(
                    alignment: Alignment.centerLeft,
                    child: IconButton(
                      onPressed: () {
                        setState(() {
                          quotations.add({
                            'qri_item_name': '',
                            'qri_qty': '',
                            'qri_unit_price': '',
                            'qre_order_type': quotations.isNotEmpty
                                ? quotations.first['qre_order_type']
                                : 'delivery',
                          });

                          itemControllers.add(TextEditingController());
                          dosesControllers
                              .add(TextEditingController(text: ''));
                          qtyControllers.add(TextEditingController());
                          perunitControllers.add(TextEditingController());
                          amountControllers.add(TextEditingController());
                        });
                      },
                      icon: Icon(Icons.add_circle_outline, color: Colors.green),
                      tooltip: "Add more",
                    ),
                  ),
                  Divider(),
                  SizedBox(height: 8.h),
                  if (isDeliveryOrder)
                    Padding(
                      padding: EdgeInsets.symmetric(horizontal: 40.h),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              "Delivery charges",
                              style: theme.textTheme.titleSmall,
                              textAlign: TextAlign.center,
                            ),
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
                              "Total",
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

  @override
  Widget build(BuildContext context) {
    String qre_quotation_status = '';
    if (quotations.isNotEmpty) {
      qre_quotation_status =
          quotations.first['qre_quotation_status'].toString();
    }
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        title: Text(
          "Quotation", // ✅ Title in center
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true, // ✅ Ensures title is centered
        backgroundColor: theme.colorScheme.primary, // ✅ Customize as needed
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // ✅ Back arrow
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Container(
                height: SizeUtils.height,
                width: double.maxFinite,
                padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 22.h),
                child: Column(
                  children: [
                    _buildAddress(context),
                    SizedBox(height: 10), // Add spacing
                    _buildQuotationHeader(context),
                    Expanded(
                      child: SingleChildScrollView(
                        child: _buildQuotationDetails(context),
                      ),
                    ),
                    // ✅ Show Download Button if lab_filepath is not blank
                    if (quotations.isNotEmpty &&
                        (quotations.first['lab_filepath']
                                ?.toString()
                                .isNotEmpty ??
                            false))
                      if (quotations.isNotEmpty &&
                          (quotations.first['lab_filepath']
                                  ?.toString()
                                  .isNotEmpty ??
                              false))
                        Padding(
                          padding: const EdgeInsets.only(bottom: 16.0),
                          child: CustomElevatedButton(
                            text: "Download Lab Report",
                            margin: EdgeInsets.only(left: 16.h, right: 14.h),
                            leftIcon: Container(
                              margin: EdgeInsets.only(right: 12.h),
                              child: Icon(
                                Icons.download,
                                color: Colors.white,
                                size: 24.h,
                              ),
                            ),
                            onPressed: () async {
                              final filePath = quotations.first['lab_filepath'];
                              final fullUrl =
                                  AppConfig.buildStorageUrl(filePath);

                              final uri = Uri.parse(fullUrl);
                              if (await canLaunchUrl(uri)) {
                                await launchUrl(uri,
                                    mode: LaunchMode.externalApplication);
                              } else {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(
                                      content:
                                          Text('Unable to open lab report.')),
                                );
                              }
                            },
                          ),
                        ),
                    if (qre_quotation_status == 'pending')
                      _isSubmitting
                          ? const CircularProgressIndicator() // Show loading indicator while submitting
                          : CustomElevatedButton(
                              text: "Submit Quotation",
                              margin: EdgeInsets.only(left: 16.h, right: 14.h),
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
                              onPressed: _submitQuotation,
                            ),
                  ],
                ),
              ),
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
      prescriptionImageUrll =
          quotations.first['qre_orignalfilepath'].toString();
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
    String? prescriptionId;
    String? doctorId;

    if (quotations.isNotEmpty) {
      requestId = quotations.first['qre_request_id'].toString();
      prescriptionImageUrll =
          quotations.first['qre_orignalfilepath'].toString();
      imageUrll = prescriptionImageUrll.replaceAll('"', '').trim().toString();
      // Get prescription_id and doctor_id if available
      prescriptionId = quotations.first['prescription_id']?.toString();
      doctorId = quotations.first['qre_doctor_id']?.toString();
    }
    print("Prescription Image URL: $imageUrll");
    print("Prescription ID: $prescriptionId");
    print("Doctor ID: $doctorId");
    print(
        "Quotation data keys: ${quotations.isNotEmpty ? quotations.first.keys.toList() : 'No quotations'}");

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
            "Quotation Request #$requestId",
            style: CustomTextStyles.titleMediumWhiteA700SemiBold,
          ),

          // Right Section: Prescription View Options
          Row(
            children: [
              // View Written Prescription Button (if prescription_id available)
              if (prescriptionId != null && prescriptionId.isNotEmpty)
                Container(
                  margin: EdgeInsets.only(right: 8),
                  child: GestureDetector(
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => PharmacyPrescriptionViewScreen(
                            prescriptionId: prescriptionId!,
                            doctorId: doctorId,
                          ),
                        ),
                      );
                    },
                    child: Container(
                      padding: EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: Colors.green[600],
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(color: Colors.white, width: 1),
                      ),
                      child: Icon(
                        Icons.description,
                        size: 20,
                        color: Colors.white,
                      ),
                    ),
                  ),
                ),

              // Prescription Image Icon (existing functionality)
              if (imageUrll.isNotEmpty && imageUrll != 'null')
                GestureDetector(
                  onTap: _showPrescriptionImage,
                  child: ClipRRect(
                    borderRadius: BorderRadius.circular(8),
                    child: Image.network(
                      imageUrll, // Replace with actual image URL
                      width: 50, // Adjust size as needed
                      height: 50,
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
            ],
          ),
        ],
      ),
    );
  }
}
