import 'package:flutter/material.dart';
import 'package:http/http.dart' as http; // Add http package for API calls
import '../../core/config/app_config.dart';
import 'dart:convert'; // For parsing JSON
import 'package:shared_preferences/shared_preferences.dart';
import '../dpharmacy_list/widget/pharmacy_list_item_widget.dart';

class DUPharmacyListScreen extends StatefulWidget {
  DUPharmacyListScreen({Key? key}) : super(key: key);

  @override
  _DUPharmacyListScreenState createState() => _DUPharmacyListScreenState();
}

class _DUPharmacyListScreenState extends State<DUPharmacyListScreen> {
  TextEditingController searchController = TextEditingController();
  List<dynamic> pharmacies = []; // Store pharmacy data
  List<int> selectedPharmacyIds = [];
  List<dynamic> filteredPharmacies = [];
// Track selected pharmacy IDs
  bool isLoading = true; // Track loading state
  String pharmacyid = "";
  @override
  void initState() {
    super.initState();
    fetchPharmacies();
    searchController.addListener(_filterPharmacies); // Add search filter
    // Fetch pharmacy data when the screen is loaded
  }

  Future<void> fetchPharmacies() async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? action_value = prefs.getString('action_value');
      if (action_value != null) {
        pharmacyid = action_value.toString();
      } else {
        pharmacyid = "0";
      }
      final response = await http.post(
          Uri.parse(AppConfig.buildApiUrl('get_pharmacy')),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: {'phid': pharmacyid.toString()});

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
          _showError("Failed to fetch pharmacy data.");
        }
      } else {
        setState(() {
          isLoading = false;
        });
        _showError("Failed to fetch pharmacies. Please try again.");
      }
    } catch (error) {
      setState(() {
        isLoading = false;
      });
      _showError("An error occurred: $error");
    }
  }

  void _filterPharmacies() {
    final query = searchController.text.toLowerCase();

    setState(() {
      filteredPharmacies = pharmacies.where((pharmacy) {
        final orgName =
            (pharmacy['org_organization_name'] ?? '').toString().toLowerCase();
        final name =
            "${pharmacy['pha_first_name'] ?? ''} ${pharmacy['pha_last_name'] ?? ''}"
                .toLowerCase();
        final phone = "${pharmacy['pha_alt_phone_number'] ?? ''}".toLowerCase();
        final mobile = "${pharmacy['usr_mobile_number'] ?? ''}".toLowerCase();

        return orgName.contains(query) ||
            name.contains(query) ||
            phone.contains(query) ||
            mobile.contains(query);
      }).toList();
    });
  }

  String? _errorMessage;

  void _showError(String message) {
    setState(() {
      _errorMessage = message;
      isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Pharmacies List",
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
        actions: [
          Container(
            margin: EdgeInsets.only(right: 16),
            padding: EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.2),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              "${filteredPharmacies.length} pharmacies",
              style: TextStyle(
                color: Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
        ],
        backgroundColor: Color(0XFF4675C0),
        elevation: 0,
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
                child: _buildContent(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildContent() {
    if (isLoading) {
      return _buildLoadingState();
    }

    if (_errorMessage != null) {
      return _buildErrorState(_errorMessage!);
    }

    if (filteredPharmacies.isEmpty) {
      return _buildEmptyState();
    }

    return _buildEnhancedPharmacyList();
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
                onChanged: (_) => setState(() {}),
                decoration: InputDecoration(
                  hintText: "Search pharmacies...",
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
                  setState(() {});
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
            'Loading pharmacies...',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Please wait while we fetch your data',
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(String error) {
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
              Icons.error_outline,
              size: 48,
              color: Colors.red[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'Error loading pharmacies',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w600,
              color: Colors.grey[700],
            ),
          ),
          SizedBox(height: 8),
          Text(
            error,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
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
              Icons.local_pharmacy_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No pharmacies found',
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

  Widget _buildEnhancedPharmacyList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      physics: BouncingScrollPhysics(),
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemCount: filteredPharmacies.length,
      itemBuilder: (context, index) {
        final pharmacy = filteredPharmacies[index];
        final int totalUsers = (pharmacy['totaluser'] ?? 0);
        final double rating = (totalUsers > 0)
            ? (pharmacy['pharmacy_rating'] ?? 0) / totalUsers
            : 0.0;

        return Container(
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
          ),
          child: Padding(
            padding: EdgeInsets.symmetric(vertical: 8),
            child: PharmacyListItemWidget(
              id: pharmacy['usr_id']?.toString() ?? '',
              pharmacyName: (pharmacy['org_organization_name'] != null &&
                      pharmacy['org_organization_name'].toString().trim().isNotEmpty)
                  ? pharmacy['org_organization_name'].toString().trim()
                  : "${pharmacy['pha_first_name'] ?? ''} ${pharmacy['pha_last_name'] ?? ''}"
                      .trim(),
              licenseNumber: pharmacy['pha_license_number']?.toString() ?? '',
              phone: pharmacy['pha_alt_phone_number']?.toString() ?? '',
              mobile: pharmacy['usr_mobile_number']?.toString() ?? '',
              rating: rating,
              totalUsers: totalUsers,
            ),
          ),
        );
      },
    );
  }
}
