import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Add http package for API calls
import '../../core/config/app_config.dart';
import 'dart:convert'; // For parsing JSON
import '../../core/app_export.dart';
import '../../widgets/custom_search_view.dart';
import '../../widgets/custom_elevated_button.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../order_list_screen/order_list_screen.dart';
import 'dart:convert';
import '../../../core/app_export.dart';
import '../../../theme/custom_button_style.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../../../widgets/custom_switch.dart';
import '../../../widgets/custom_text_form_field.dart';
import 'order_list_screen/order_list_screen.dart';

class RiderListScreen extends StatefulWidget {
  final int orderidd;
  final String ordertypee;
  RiderListScreen({
    required this.orderidd,
    required this.ordertypee,
  });
  @override
  _RiderListScreenState createState() => _RiderListScreenState();
}

class _RiderListScreenState extends State<RiderListScreen> {
  TextEditingController searchController = TextEditingController();
  List<dynamic> pharmacies = []; // Store pharmacy data
  int? selectedPharmacyId; // Store only one selected pharmacy ID
  bool isLoading = true; // Track loading state
  String pharmacyid = "";
  List<dynamic> filteredPharmacies = [];
  @override
  void initState() {
    super.initState();
    fetchPharmacies(); // Fetch pharmacy data when the screen is loaded
  }

  Future<void> fetchPharmacies() async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('get_riders')),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            pharmacies = data['data'];
            filteredPharmacies = pharmacies;
            isLoading = false;
          });
        } else {
          setState(() {
            isLoading = false;
          });
          _showError("Failed to fetch rider data.");
        }
      } else {
        setState(() {
          isLoading = false;
        });
        _showError("Failed to fetch riders. Please try again.");
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      _showError("An error occurred: $error");
    }
  }

  void _showError(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  void _togglePharmacySelection(int id) {
    setState(() {
      if (selectedPharmacyId == id) {
        selectedPharmacyId = null; // Deselect if already selected
      } else {
        selectedPharmacyId = id; // Select a new pharmacy
      }
    });
  }

  Future<void> _updateOrderStatus() async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('update_ostatus')),
        body: {
          'order_id': widget.orderidd.toString(),
          'ord_order_status': 'ready',
          'riderid': selectedPharmacyId.toString(),
        },
      );
      //  print(response.body);
      if (response.statusCode == 200) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(
                  "Order is ready for dispatch, and a delivery person has been successfully assigned and otp sent to rider!"),
              backgroundColor: Colors.green),
        );

        Navigator.pushReplacement(
          context,
          MaterialPageRoute(
              builder: (context) =>
                  PharmacyOrderListScreen()), // Navigate to Order List
        );
      } else {
        print("Failed to update order status.");
      }
    } catch (e) {
      print("Error updating order status: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        backgroundColor: Theme.of(context).colorScheme.primary,
        // centerTitle: true,
        automaticallyImplyLeading: false, // hide default back button
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context); // go back to previous screen
          },
        ),
        title: Text(
          "Choose Rider",
          style: TextStyle(color: Colors.white),
        ),
      ),
      body: SafeArea(
        child: Column(
          children: [
            // Top Header
            // _buildTopHeader(),
            // Search Bar
            _buildSearchSection(),

            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : Column(
                      children: [
                        Expanded(child: _buildPharmacyList()),
                        Padding(
                          padding: EdgeInsets.all(16),
                          child: CustomElevatedButton(
                            height: 50,
                            width: double.infinity,
                            text: "Submit",
                            margin: EdgeInsets.only(top: 10),
                            onPressed: () {
                              if (selectedPharmacyId == null) {
                                ScaffoldMessenger.of(context).showSnackBar(
                                  SnackBar(
                                    content: Text(
                                        "Please select a rider before submitting."),
                                    backgroundColor: Colors.red,
                                  ),
                                );
                              } else {
                                _updateOrderStatus();
                              }
                            },
                            alignment: Alignment.center,
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

  void _filterRiders() {
    final query = searchController.text.toLowerCase();

    setState(() {
      if (query.isEmpty) {
        filteredPharmacies = pharmacies;
      } else {
        filteredPharmacies = pharmacies.where((rider) {
          return (rider['usr_username']?.toLowerCase().contains(query) ??
                  false) ||
              (rider['usr_username']?.toLowerCase().contains(query) ?? false) ||
              (rider['usr_email']?.toLowerCase().contains(query) ?? false) ||
              (rider['usr_mobile_number']?.toLowerCase().contains(query) ??
                  false) ||
              (rider['total_orders']?.toString().contains(query) ?? false);
        }).toList();
      }
    });
  }

  Widget _buildSearchSection() {
    return Padding(
      padding: EdgeInsets.all(8),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38,
              child: TextField(
                controller: searchController,
                onChanged: (_) => _filterRiders(),
                decoration: InputDecoration(
                  hintText: "Search by name, email, phone...",
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                  hintStyle: TextStyle(fontSize: 12.0),
                ),
              ),
            ),
          ),
          if (searchController.text.isNotEmpty)
            IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                searchController.clear();
                _filterRiders(); // Reset the filter
              },
            ),
        ],
      ),
    );
  }

  /// Build Pharmacy List
  Widget _buildPharmacyList() {
    return ListView.builder(
      itemCount: filteredPharmacies.length,
      padding: EdgeInsets.symmetric(horizontal: 16),
      itemBuilder: (context, index) {
        final pharmacy = filteredPharmacies[index];
        final isSelected =
            selectedPharmacyId == pharmacy['id']; // Single selection check
        // Prevent division by zero
        return GestureDetector(
          onTap: () {
            _togglePharmacySelection(pharmacy['id']); // Toggle selection
          },
          child: Card(
            margin: EdgeInsets.only(bottom: 12),
            elevation: 2,
            color: isSelected
                ? Colors.blue[100]
                : Colors.white, // Highlight selected
            child: ListTile(
              title: Text(
                "${pharmacy['usr_first_name'] ?? ''} ${pharmacy['usr_username'] ?? ''}",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.bold,
                ),
              ),
              subtitle: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  if (pharmacy['usr_username'] != null &&
                      pharmacy['usr_username'].toString().isNotEmpty)
                    Text("Rider Name: ${pharmacy['usr_username']}"),
                  if (pharmacy['usr_mobile_number'] != null &&
                      pharmacy['usr_mobile_number'].toString().isNotEmpty)
                    Text("Phone: ${pharmacy['usr_mobile_number']}"),
                  if (pharmacy['usr_email'] != null &&
                      pharmacy['usr_email'].toString().isNotEmpty)
                    Text("Email: ${pharmacy['usr_email']}"),
                  SizedBox(height: 5),

                  // Rating Star Widget
                ],
              ),
              trailing: Icon(
                isSelected ? Icons.check_circle : Icons.circle_outlined,
                color: isSelected ? Colors.blue : Colors.grey,
              ),
            ),
          ),
        );
      },
    );
  }

  /// Build Top Header with Back Button
  Widget _buildTopHeader() {
    return Container(
      padding: EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.primary,
        // borderRadius: BorderRadius.vertical(
        //   bottom: Radius.circular(20),
        // ),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Row(
            children: [
              GestureDetector(
                onTap: () {
                  Navigator.pop(
                      context); // Go back when the back button is pressed
                },
                child: Icon(Icons.arrow_back, color: Colors.white),
              ),
              SizedBox(
                  width: 8), // Add some spacing between back button and title
              Text(
                "Choose Rider",
                style: TextStyle(
                  color: Colors.white,
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          CircleAvatar(
            backgroundColor: Colors.redAccent,
            radius: 12,
            child: Text(
              pharmacies.length.toString(),
              style: TextStyle(color: Colors.white, fontSize: 14),
            ),
          ),
        ],
      ),
    );
  }
}
