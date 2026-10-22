import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../core/config/app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../../widgets/custom_elevated_button.dart';
import 'package:timelines_plus/timelines_plus.dart';
import '../../pharmacy/otp_screen/otp_screen.dart';

class DeliveryDetailScreen extends StatefulWidget {
  final int orderId;
  final String requestId;
  const DeliveryDetailScreen(
      {Key? key, required this.orderId, required this.requestId})
      : super(key: key);

  @override
  _DeliveryDetailScreenState createState() => _DeliveryDetailScreenState();
}

class _DeliveryDetailScreenState extends State<DeliveryDetailScreen> {
  bool isLoading = true;
  bool hasError = false;
  List<dynamic> trackingData = [];
  String otp = "Loading...";

  @override
  void initState() {
    super.initState();
    fetchDeliveryDetails();
  }

  Future<void> fetchDeliveryDetails() async {
    final String apiUrl = AppConfig.buildApiUrl('get_deliveryview');

    try {
      final response = await http.post(
        Uri.parse(apiUrl),
        body: {"order_id": widget.orderId.toString()},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        setState(() {
          trackingData = data["orders"];
          otp = trackingData.first['del_delivery_otp']?.toString() ?? "N/A";
          print(otp);
          // otp = data["otp"] ?? "N/A";
          isLoading = false;
        });
      } else {
        setState(() {
          hasError = true;
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        hasError = true;
        isLoading = false;
      });
    }
  }

  Widget build(BuildContext context) {
    String del_delivery_status = "";
    String motp = "";
    if (trackingData.isNotEmpty) {
      del_delivery_status =
          trackingData.first['del_delivery_status'].toString();
      motp = trackingData.first['del_delivery_otp'].toString();
    }
    return Scaffold(
      backgroundColor: Colors.grey[100],
      appBar: AppBar(
        // backgroundColor: Colors.blue[800],
        title: Text(
          "Delivery Detail ",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        backgroundColor:
            theme.colorScheme.primary, // ✅ Ensures title is centered
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // ✅ Back arrow
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            SizedBox(height: 20.h),
            _buildTrackingCard(),
            Spacer(flex: 52),
            if (del_delivery_status == 'pending')
              CustomElevatedButton(
                text: "OTP : $motp",
                margin: EdgeInsets.only(left: 16.h, right: 14.h),
                // onPressed: _submittQuotation,
              ),
            if (del_delivery_status == 'pickedup')
              CustomElevatedButton(
                text: "Enter Delivery OTP",
                margin: EdgeInsets.only(left: 16.h, right: 14.h),
                onPressed: () {
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => OtpInputScreen(
                          orderidd: widget
                              .orderId, // ✅ Remove unnecessary `.toString()`
                          ordertypee: "delivery_person"),
                    ),
                  );
                },
              ),
            if (del_delivery_status == 'delivered') _buildRatingSection(),
            SizedBox(height: 10.h),
          ],
        ),
      ),
    );
  }

  Widget _buildRatingSection() {
    double rating = 0.0;
    if (trackingData.isNotEmpty) {
      rating =
          double.tryParse(trackingData.first['delivery_rating'].toString()) ??
              0.0;
    }
    return Container(
      margin: EdgeInsets.symmetric(vertical: 16.h),
      padding: EdgeInsets.all(12.h),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8.h),
        boxShadow: [
          BoxShadow(color: Colors.black26, blurRadius: 4, spreadRadius: 1),
        ],
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(
            "Rating",
            style: TextStyle(fontSize: 18.h, fontWeight: FontWeight.bold),
          ),
          SizedBox(height: 8.h),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(5, (index) {
              return Icon(
                index < rating ? Icons.star : Icons.star_border,
                color: Colors.amber,
                size: 24.h,
              );
            }),
          ),
        ],
      ),
    );
  }

  Widget _buildTrackingCard() {
    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: SizedBox(
        height: 500, // Adjust the height as per your requirement
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Title Bar
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12.0),
              decoration: BoxDecoration(
                color: theme.colorScheme.primary,
                borderRadius: const BorderRadius.only(
                  topLeft: Radius.circular(12),
                  topRight: Radius.circular(12),
                ),
              ),
              child: Text(
                "Delivery Details #${widget.requestId}",
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                  color: Colors.white,
                ),
              ),
            ),
            // Timeline
            SizedBox(
              height: 400, // Adjust the height as needed
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: ListView.builder(
                  shrinkWrap: true,
                  physics:
                      NeverScrollableScrollPhysics(), // Prevent conflicts with parent scroll
                  itemCount: trackingData.length,
                  itemBuilder: (context, index) {
                    final order = trackingData[index];
                    return _buildTimeline(order);
                  },
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildTimeline(Map<String, dynamic> order) {
    return Timeline.tileBuilder(
      shrinkWrap: true,
      theme: TimelineThemeData(
        nodePosition: 0.1,
        connectorTheme: ConnectorThemeData(thickness: 2.0, color: Colors.grey),
        indicatorTheme: IndicatorThemeData(size: 20.0, color: Colors.blue),
      ),
      builder: TimelineTileBuilder.connected(
        connectionDirection: ConnectionDirection.before,
        itemCount: 2,
        contentsBuilder: (context, index) {
          if (index == 0) {
            return _buildPickupInfo(order);
          } else {
            return _buildDeliveryInfo(order);
          }
        },
        indicatorBuilder: (context, index) {
          return Icon(
            index == 0 ? Icons.store : Icons.home,
            color: Colors.blue[800],
          );
        },
        connectorBuilder: (context, index, type) {
          return SolidLineConnector(color: Colors.grey);
        },
      ),
    );
  }

  Widget _buildPickupInfo(Map<String, dynamic> order) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "Start:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text("🏥 Pharmacy: ${order['pha_first_name'] ?? 'N/A'}"),
          Text("📍 Address: ${order['pha_address'] ?? 'N/A'}"),
          Text(
            "🚚 Pickup Status: ${order['del_delivery_status'].toUpperCase()}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: order['del_delivery_status'] == 'pending'
                  ? Colors.orange
                  : Colors.green,
            ),
          ),
          Text("⏰ Pickup Time: ${order['del_pickup_time']}"),
        ],
      ),
    );
  }

  Widget _buildDeliveryInfo(Map<String, dynamic> order) {
    // Check if order status is "Delivered" (case-insensitive)
    final orderStatus = order['ord_order_status']?.toString().toLowerCase() ?? '';
    final isDelivered = orderStatus == 'delivered';
    
    // Mask patient name and address if order is delivered
    final patientName = isDelivered 
        ? '*******' 
        : (order['usr_username'] ?? 'N/A');
    final address = isDelivered 
        ? '*******' 
        : (order['adr_address_1'] ?? 'N/A');
    
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            "End:",
            style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
          ),
          SizedBox(height: 4),
          Text("👤 Customer: $patientName"),
          Text("📍 Address: $address"),
          Text(
            "🚚 Delivery Status: ${order['ord_order_status'].toUpperCase()}",
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: order['ord_order_status'] == 'dispatched'
                  ? Colors.orange
                  : Colors.green,
            ),
          ),
          Text(
            "⏳ Delivered Time: ${order['del_delivered_time'] ?? 'Not Delivered Yet'}",
          ),
        ],
      ),
    );
  }
}
