import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import 'dart:convert';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_switch.dart';
import '../presentation/order_list_screen/order_list_screen.dart';

class FeedbackScreen extends StatefulWidget {
  const FeedbackScreen({Key? key}) : super(key: key);

  @override
  _FeedbackScreenState createState() => _FeedbackScreenState();
}

class _FeedbackScreenState extends State<FeedbackScreen> {
  TextEditingController deliveryFeedbackController = TextEditingController();
  TextEditingController pharmacyFeedbackController = TextEditingController();
  double deliveryRating = 0.0; // Separate rating for delivery
  double pharmacyRating = 0.0; // Separate rating for pharmacy
  String userType = "delivery"; // Default user type
  String myorder = "";
  @override
  void initState() {
    super.initState();
    _loadUserType();
  }

  // Fetch user type from SharedPreferences
  Future<void> _loadUserType() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    setState(() {
      userType = prefs.getString('myordertype') ?? "delivery";
      myorder = prefs.getString('myorderid') ?? "";
      // Default to delivery
    });
  }

  // Send feedback to backend
  Future<void> submitFeedback() async {
    String deliveryFeedback = deliveryFeedbackController.text.trim();
    String pharmacyFeedback = pharmacyFeedbackController.text.trim();
    String deliveryRatingg = deliveryRating.toString();
    String pharmacyRatingg = pharmacyRating.toString();
    if (userType == "delivery" &&
        deliveryFeedback.isEmpty &&
        pharmacyFeedback.isEmpty) {
      _showSnackbar("Please enter your feedback.");
      return;
    } else if (userType != "delivery" && pharmacyFeedback.isEmpty) {
      _showSnackbar("Please enter pharmacy feedback.");
      return;
    }

    String apiUrl = AppConfig.buildApiUrl('submit_feedback');
    Map<String, dynamic> data = {
      "order_id": myorder,
      "delivery_rating": userType == "delivery" ? deliveryRatingg : '0.0',
      "pharmacy_rating": pharmacyRatingg,
      "delivery_feedback": userType == "delivery" ? deliveryFeedback : "",
      "pharmacy_feedback": pharmacyFeedback,
    };

    try {
      var response = await http.post(
        Uri.parse(apiUrl),
        body: data,
      );

      if (response.statusCode == 200) {
        _showSnackbar("Thank you for your feedback!");
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => OrderListScreen(),
          ),
        );
        setState(() {
          deliveryRating = 0.0;
          pharmacyRating = 0.0;
          deliveryFeedbackController.clear();
          pharmacyFeedbackController.clear();
        });
      } else {
        _showSnackbar("Failed to submit feedback.");
      }
    } catch (e) {
      _showSnackbar("Error: $e");
    }
  }

  void _showSnackbar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        title: Text(
          "Feedback",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Show Delivery Feedback only if user type is "delivery"
              if (userType == "delivery") _buildDeliveryFeedback(),

              // Always show Pharmacy Feedback
              _buildPharmacyFeedback(),

              SizedBox(height: 10.0),

              // Submit Button
              Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Padding(
                    padding:
                        EdgeInsets.symmetric(vertical: 16.h, horizontal: 10.h),
                    child: CustomElevatedButton(
                      text: "Submit Feedback",
                      onPressed: submitFeedback,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  /// Delivery Person Feedback Widget
  Widget _buildDeliveryFeedback() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Rate Delivery Experience",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 5.0),
        Center(
          child: RatingBar.builder(
            initialRating: deliveryRating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (rating) {
              setState(() {
                deliveryRating = rating;
              });
            },
          ),
        ),
        SizedBox(height: 10.0),
        Text("Delivery Feedback",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 5.0),
        TextField(
          controller: deliveryFeedbackController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Write your feedback about delivery...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: EdgeInsets.all(12.0),
          ),
        ),
        SizedBox(height: 10.0),
      ],
    );
  }

  /// Pharmacy Feedback Widget
  Widget _buildPharmacyFeedback() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text("Rate Pharmacy Experience",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 5.0),
        Center(
          child: RatingBar.builder(
            initialRating: pharmacyRating,
            minRating: 1,
            direction: Axis.horizontal,
            allowHalfRating: true,
            itemCount: 5,
            itemPadding: EdgeInsets.symmetric(horizontal: 4.0),
            itemBuilder: (context, _) => Icon(Icons.star, color: Colors.amber),
            onRatingUpdate: (rating) {
              setState(() {
                pharmacyRating = rating;
              });
            },
          ),
        ),
        SizedBox(height: 10.0),
        Text("Pharmacy Feedback",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        SizedBox(height: 5.0),
        TextField(
          controller: pharmacyFeedbackController,
          maxLines: 3,
          decoration: InputDecoration(
            hintText: "Write your feedback about pharmacy...",
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
            contentPadding: EdgeInsets.all(12.0),
          ),
        ),
      ],
    );
  }
}
