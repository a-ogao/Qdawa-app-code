import 'package:flutter/material.dart';
import 'package:timelines_plus/timelines_plus.dart';
import 'package:http/http.dart' as http;
import '../../../core/config/app_config.dart';
import 'dart:convert';
import '../../../core/app_export.dart';
import 'widgets/columnorderplac_item_widget.dart';
import 'widgets/columntime_item_widget.dart';
import 'widgets/columnview_item_widget.dart';
import '../../../theme/custom_button_style.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_switch.dart';
import '../../../widgets/custom_text_form_field.dart';

import 'package:shared_preferences/shared_preferences.dart';

class DOrderTrackStatusScreen extends StatefulWidget {
  final String orderId;

  const DOrderTrackStatusScreen({Key? key, required this.orderId})
      : super(key: key);

  @override
  State<DOrderTrackStatusScreen> createState() =>
      _OrderTrackStatusScreenState();
}

class _OrderTrackStatusScreenState extends State<DOrderTrackStatusScreen> {
  List<Map<String, dynamic>> orderStatuses = [];
  List<Map<String, dynamic>> orders = [];

  bool isLoading = true;
  String currentStatus = '';
  String ord_order_type = '';
  String feedbackstatus = '';
  double totalAmount = 0.0;
  double delivery = 0.0;
  double rating = 0.0;
  String otp = "";
  TextEditingController toponeController = TextEditingController();
  String pharmacy = "Malibu Pharmacy Limited"; // Default pharmacy name
  TextEditingController feedbackController =
      TextEditingController(); // Feedback field controller
  double userRating = 0.0; // Stores user rating

  @override
  void initState() {
    super.initState();
    fetchOrderTrackingData(widget.orderId);
  }

  Future<void> fetchOrderTrackingData(String orderId) async {
    final url = Uri.parse(AppConfig.buildApiUrl('order_view'));
    try {
      final response = await http.post(url, body: {'order_id': orderId});
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString(
            'myordertype', data['order']['ord_order_type'].toString());
        await prefs.setString('myorderid', widget.orderId.toString());

        setState(() {
          orders = List<Map<String, dynamic>>.from(data['items'] ?? []);
          orderStatuses = data['order'] != null ? [data['order']] : [];
          // print(orderStatuses);
          // print(orders);
          currentStatus = data['order']['ord_order_status'] ?? '';
          ord_order_type = data['order']['ord_order_type'] ?? '';
          pharmacy = data['order']['pha_first_name'] ?? '';
          otp = data['del_delivery_otp'] ?? '';
          // currentStatus = orderStatuses.isNotEmpty
          //   ? orderStatuses.last['ord_order_status'] ?? ''
          //   : '';
          //print(currentStatus);
          totalAmount =
              double.tryParse(data['order']['ord_total_amount'].toString()) ??
                  0.0;
          delivery = double.tryParse(
                  data['order']['ord_delivery_charge'].toString()) ??
              0.0;
          feedbackstatus = data['order']['feedback_status'].toString() ?? '';
          //print(feedbackstatus);
          rating =
              double.tryParse(data['order']['pharmacy_rating'].toString()) ??
                  0.0;
          isLoading = false;
        });
      } else {
        print('Failed to load order statuses: ${response.body}');
      }
    } catch (e) {
      print('Error occurred: $e');
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        title: Text(
          "Track Order",
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        backgroundColor: theme.colorScheme.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            // Go back to the previous screen
            Navigator.pop(context);
          },
        ),
      ),
      body: SafeArea(
        child: isLoading
            ? const Center(child: CircularProgressIndicator())
            : Stack(
                alignment: Alignment.center,
                children: [
                  SingleChildScrollView(
                    physics:
                        AlwaysScrollableScrollPhysics(), // Enables scrolling
                    child: Padding(
                      padding: EdgeInsets.symmetric(horizontal: 6.h),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          SizedBox(height: 10.h), // To adjust for the header
                          Padding(
                            padding: EdgeInsets.only(right: 6.h),
                            child: CustomTextFormField(
                              controller: toponeController,
                              hintText: pharmacy.isNotEmpty
                                  ? "Pharmacy Name : $pharmacy"
                                  : 'Malibu Pharmacy Limited',
                              textInputAction: TextInputAction.done,
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 20.h,
                                vertical: 14.h,
                              ),
                              hintStyle: TextStyle(
                                color: Colors.white,
                                fontSize: 16.0,
                              ),
                              borderDecoration:
                                  TextFormFieldStyleHelper.fillPrimary,
                              fillColor: theme.colorScheme.primary,
                            ),
                          ),
                          SizedBox(height: 20.h),
                          _buildDefaultSection(),
                          SizedBox(height: 50.h),
                          Padding(
                            padding: EdgeInsets.only(left: 4.h),
                            child: Container(
                              padding: EdgeInsets.symmetric(
                                  vertical: 14.0,
                                  horizontal: 20.0), // Padding around the text
                              decoration: BoxDecoration(
                                color: theme.colorScheme
                                    .primary, // Background color for the bar
                                borderRadius: BorderRadius.circular(
                                    5.0), // Rounded corners for the container
                                boxShadow: [
                                  BoxShadow(
                                    color: Colors.black
                                        .withOpacity(0.2), // Shadow color
                                    spreadRadius: 2, // Spread of the shadow
                                    blurRadius: 6, // Blur effect of the shadow
                                    offset: Offset(0, 4), // Shadow offset
                                  ),
                                ],
                              ),
                              child: Center(
                                child: Text(
                                  "Order Tracking",
                                  style: CustomTextStyles.titleMediumBlack900
                                      .copyWith(
                                    color: Colors
                                        .white, // Text color set to white for contrast
                                    fontSize:
                                        16.0, // Adjust text size as needed
                                    fontWeight: FontWeight.bold, // Bold text
                                  ),
                                ),
                              ),
                            ),
                          ),

                          SizedBox(height: 50.h),
                          _buildTimelineWithLabels(),
                          SizedBox(height: 10.h),
                        ],
                      ),
                    ),
                  ),
                  // _buildTopHeader(),
                ],
              ),
      ),
    );
  }

  Widget _buildDefaultSection() {
    return orders.isEmpty
        ? const Center(child: Text("No Orders found."))
        : Container(
            width: double.infinity,
            margin: EdgeInsets.only(right: 6.h),
            padding: EdgeInsets.symmetric(vertical: 8.h),
            decoration: AppDecoration.fFFFFFDropShadow.copyWith(
              borderRadius: BorderRadiusStyle.roundedBorder5,
            ),
            child: Column(
              children: [
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.h),
                  child: Row(
                    children: [
                      Expanded(
                        flex: 3,
                        child: Text(
                          "Medicine",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Dosage",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          "Qty",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Text(
                          "Price",
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      Expanded(
                        flex: 2,
                        child: Text(
                          "Amount",
                          textAlign: TextAlign.right, // Ensures right alignment
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                ListView.builder(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: orders.length,
                  itemBuilder: (context, index) {
                    final order = orders[index];
                    return Padding(
                      padding:
                          EdgeInsets.symmetric(horizontal: 16.h, vertical: 8.h),
                      child: Row(
                        children: [
                          Expanded(
                              flex: 3,
                              child: Text(order['oit_item_name'] ?? "Unknown",
                                  textAlign: TextAlign.left,
                                  style: theme.textTheme.titleSmall)),
                          Expanded(
                              flex: 2,
                              child: Text(
                                order['oit_item_dosage'] != null
                                    ? order['oit_item_dosage'].toString()
                                    : "0",
                                style: theme.textTheme.titleSmall,
                                textAlign: TextAlign.left,
                              )),
                          Expanded(
                              flex: 1,
                              child: Text(
                                order['oit_qty'].toString(),
                                style: theme.textTheme.titleSmall,
                                textAlign: TextAlign.left,
                              )),
                          Expanded(
                              flex: 1,
                              child: Text(
                                order['oit_amount_per_unit'].toString(),
                                style: theme.textTheme.titleSmall,
                                textAlign: TextAlign.left,
                              )),
                          Expanded(
                              flex: 2,
                              child: Text(
                                "\ ${order['oit_amount']}",
                                style: theme.textTheme.titleSmall,
                                textAlign: TextAlign.right,
                              )),
                        ],
                      ),
                    );
                  },
                ),
                if (ord_order_type == 'delivery') const Divider(),
                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 10.h),
                  child: Row(
                    children: [
                      Expanded(
                        child: Align(
                          alignment: Alignment
                              .topRight, // Ensures "Total" stays on the left
                          child: Text(
                            "Delivery Charges :  KSH",
                            style: TextStyle(fontWeight: FontWeight.bold),
                            //style: theme.textTheme.titleSmall,
                          ),
                        ),
                      ),
                      Expanded(
                        child: Row(
                          mainAxisAlignment: MainAxisAlignment
                              .end, // Align everything to the right
                          children: [
                            Text(
                              delivery.toStringAsFixed(2), // Amount
                              style: TextStyle(fontWeight: FontWeight.bold),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                //Divider(),
                Divider(color: appTheme.gray300),
                SizedBox(height: 8.h),

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
                            "Total :  KSH",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                      Expanded(
                        flex: 1,
                        child: Align(
                          alignment: Alignment
                              .centerRight, // Ensures amount is right-aligned
                          child: Text(
                            "${totalAmount.toStringAsFixed(2)}",
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          );
  }

  Widget _buildTopHeader() {
    return Align(
      alignment: Alignment.topCenter,
      child: Container(
        color: theme.colorScheme.primary,
        height: 60.h,
        padding: EdgeInsets.symmetric(horizontal: 20.h),
        child: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
            ),
            Text("Track Order",
                style: TextStyle(color: Colors.white, fontSize: 18)),
          ],
        ),
      ),
    );
  }

  String _capitalize(String text) {
    if (text.isEmpty) return '';
    return text[0].toUpperCase() + text.substring(1);
  }

  /// Timeline Section
  /// Timeline Section
  Widget _buildTimelineWithLabels() {
    List<Map<String, dynamic>> filteredStatuses = [];
    List<String> statusSequence = [];
    if (ord_order_type == 'delivery') {
      statusSequence = ['pending', 'ready', 'dispatched', 'delivered'];
    } else {
      statusSequence = ['pending', 'ready', 'pickedup'];
    }

    // Normalize `currentStatus`
    String normalizedCurrentStatus = currentStatus?.toLowerCase().trim() ?? '';
    int currentStatusIndex = statusSequence.indexOf(normalizedCurrentStatus);
    print('Current Status Index: $currentStatusIndex');

    if (currentStatusIndex != -1) {
      for (int i = 0; i <= currentStatusIndex; i++) {
        String targetStatus = statusSequence[i];

        var statusesForCurrentStep = orderStatuses
            .where((status) =>
                (status['ord_order_status']?.toString().toLowerCase().trim() ??
                    '') ==
                targetStatus)
            .toList();

        if (statusesForCurrentStep.isEmpty) {
          filteredStatuses.add({
            'ord_order_status': targetStatus,
            'status': 'No data available',
            'ord_modified_dt': '' // Provide a placeholder date if needed
          });
        } else {
          filteredStatuses.addAll(statusesForCurrentStep);
        }

        print('Statuses up to index $i: $statusesForCurrentStep');
      }
    } else {
      filteredStatuses = orderStatuses;
      print('Showing all statuses: $filteredStatuses');
    }
    return Container(
      margin: EdgeInsets.only(right: 8.h),
      height: 200.h,
      width: double.infinity,
      child: Timeline.tileBuilder(
        shrinkWrap: true,
        theme: TimelineThemeData(
          nodePosition: 0.3,
          indicatorPosition: 0.3,
        ),
        builder: TimelineTileBuilder.connected(
          connectionDirection: ConnectionDirection.before,
          itemCount: filteredStatuses.length,
          oppositeContentsBuilder: (context, index) {
            return Padding(
              padding:
                  EdgeInsets.only(top: 8.0), // Add some padding for spacing
              child: Column(
                crossAxisAlignment:
                    CrossAxisAlignment.start, // Align to the left
                children: [
                  Text(
                    filteredStatuses[index]['ord_modified_dt'] ?? 'N/A',
                    style: TextStyle(
                      fontSize: 14.0, // Font size for the date
                      fontWeight: FontWeight.bold, // Make the date bold
                      color: Colors.black87, // Dark color for better contrast
                    ),
                  ),
                  SizedBox(
                      height: 4.0), // Small spacing between date and status
                ],
              ),
            );
          },
          indicatorBuilder: (context, index) {
            return ColumnviewItemWidget(
              color: _getStatusColor(
                  filteredStatuses[index]['ord_order_status'] ?? ''),
            );
          },
          contentsBuilder: (context, index) {
            return ColumnorderplacItemWidget(
              status: _capitalize(
                  filteredStatuses[index]['ord_order_status'] ?? ''),
            );
          },
          connectorBuilder: (context, index, type) {
            return SolidLineConnector(
              thickness: 2.h,
              color: appTheme.gray30001,
            );
          },
        ),
      ),
    );
  }

  /// Status Color Mapping (Show all statuses progressively)
  Color _getStatusColor(String status) {
    switch (status) {
      case 'pending':
        return Colors.blue; // Primary color
      case 'ready':
        return Colors.orange; // Secondary status color
      case 'dispatched':
        return Colors.purple; // Status colors in sequence
      case 'pickedup':
        return Colors.red;
      case 'delivered':
        return Colors.green; // Final status
      default:
        return appTheme.gray30001;
    }
  }
}
