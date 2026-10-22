import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'package:flutter_rating_bar/flutter_rating_bar.dart';
import '../../../core/config/app_config.dart';

class vRiderListScreen extends StatefulWidget {
  @override
  _RiderListScreenState createState() => _RiderListScreenState();
}

class _RiderListScreenState extends State<vRiderListScreen> {
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
        Uri.parse(AppConfig.buildApiUrl('get_ridersnew')),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      );
      //print(response.body);
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true && data['data'] != null) {
          setState(() {
            // print(response.body);
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Riders List",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
        elevation: 0,
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${filteredPharmacies.length} riders",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        backgroundColor: Color(0XFF4675C0),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0XFF4675C0).withOpacity(0.05),
              Colors.grey[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 16),
              _buildEnhancedSearchSection(),
              SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? _buildLoadingState()
                    : filteredPharmacies.isEmpty
                        ? _buildEmptyState()
                        : _buildEnhancedRiderList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedRiderList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: BouncingScrollPhysics(),
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemCount: filteredPharmacies.length,
      itemBuilder: (context, index) {
        final rider = filteredPharmacies[index];
        final int totalUsers = rider['totaluser'] ?? 3;
        final double rating = (totalUsers > 0)
            ? (rider['delivery_rating'] ?? 2) / totalUsers
            : 0.0;

        final isSelected = selectedPharmacyId == rider['id'];

        return GestureDetector(
          onTap: () => _togglePharmacySelection(rider['id']),
          child: Container(
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(16),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.06),
                  blurRadius: 12,
                  offset: Offset(0, 4),
                  spreadRadius: 0,
                ),
              ],
              border: isSelected
                  ? Border.all(color: Color(0XFF4675C0), width: 2)
                  : null,
            ),
            child: Padding(
              padding: EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Rider ID and Status badges in same row
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Container(
                        padding:
                            EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: Color(0XFF4675C0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          "#${rider['id'] ?? 'N/A'}",
                          style: TextStyle(
                            color: Color(0XFF4675C0),
                            fontSize: 14,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                      _buildRiderStatusBadge(rider),
                    ],
                  ),

                  SizedBox(height: 16),

                  // Rider Name
                  Row(
                    children: [
                      Icon(
                        Icons.person_outline,
                        size: 20,
                        color: Color(0XFF4675C0),
                      ),
                      SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          "${rider['usr_first_name'] ?? ''} ${rider['usr_username'] ?? ''}",
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.bold,
                            color: Color(0XFF4675C0),
                          ),
                        ),
                      ),
                    ],
                  ),

                  SizedBox(height: 12),

                  // Phone Number
                  if (rider['usr_mobile_number'] != null)
                    Row(
                      children: [
                        Icon(
                          Icons.phone_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Text(
                          rider['usr_mobile_number'],
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[600],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                  if (rider['usr_mobile_number'] != null) SizedBox(height: 8),

                  // Email
                  if (rider['usr_email'] != null)
                    Row(
                      children: [
                        Icon(
                          Icons.email_outlined,
                          size: 16,
                          color: Colors.grey[600],
                        ),
                        SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            rider['usr_email'],
                            style: TextStyle(
                              fontSize: 14,
                              color: Colors.grey[600],
                              fontWeight: FontWeight.w500,
                            ),
                            maxLines: 1,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),

                  if (rider['usr_email'] != null) SizedBox(height: 12),

                  // Total Orders and Rating
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Total Orders
                      if (rider['total_orders'] != null)
                        Container(
                          padding:
                              EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          decoration: BoxDecoration(
                            color: Colors.green.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(
                              color: Colors.green.withOpacity(0.3),
                              width: 1,
                            ),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Icon(
                                Icons.shopping_bag_outlined,
                                size: 16,
                                color: Colors.green,
                              ),
                              SizedBox(width: 6),
                              Text(
                                "${rider['total_orders']} orders",
                                style: TextStyle(
                                  fontSize: 12,
                                  fontWeight: FontWeight.w600,
                                  color: Colors.green,
                                ),
                              ),
                            ],
                          ),
                        ),

                      // Rating
                      Row(
                        children: [
                          RatingBarIndicator(
                            rating: rating,
                            itemBuilder: (context, _) =>
                                Icon(Icons.star, color: Colors.amber),
                            itemCount: 5,
                            itemSize: 16,
                            direction: Axis.horizontal,
                          ),
                          SizedBox(width: 6),
                          Text(
                            rating.toStringAsFixed(1),
                            style: TextStyle(
                              fontWeight: FontWeight.w600,
                              fontSize: 14,
                              color: Colors.grey[700],
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  Widget _buildRiderStatusBadge(Map<String, dynamic> rider) {
    // You can customize this based on rider status if available
    Color statusColor = Colors.blue;
    String statusText = "Active";
    IconData statusIcon = Icons.check_circle;

    return Container(
      padding: EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusColor.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusIcon,
            size: 16,
            color: statusColor,
          ),
          SizedBox(width: 6),
          Text(
            statusText,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusColor,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedSearchSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Padding(
        padding: EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(
              Icons.search,
              color: Colors.grey[600],
              size: 20,
            ),
            SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: (_) => _filterRiders(),
                decoration: InputDecoration(
                  hintText: "Search riders...",
                  border: InputBorder.none,
                  hintStyle: TextStyle(
                    color: Colors.grey[500],
                    fontSize: 16,
                  ),
                  contentPadding: EdgeInsets.symmetric(vertical: 16),
                ),
                style: TextStyle(
                  fontSize: 16,
                  color: Colors.black87,
                ),
              ),
            ),
            if (searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[600]),
                onPressed: () {
                  searchController.clear();
                  _filterRiders();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildLoadingState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: CircularProgressIndicator(
              valueColor: AlwaysStoppedAnimation<Color>(Color(0XFF4675C0)),
              strokeWidth: 3,
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Loading riders...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please wait while we fetch rider data',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: Colors.white,
              shape: BoxShape.circle,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: Offset(0, 10),
                ),
              ],
            ),
            child: Icon(
              Icons.delivery_dining_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No riders found',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Try adjusting your search criteria',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }
}
