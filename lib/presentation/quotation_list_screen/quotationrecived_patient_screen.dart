import 'package:flutter/material.dart';
import '../nav_bar/navbar_widget.dart'; // Import the Navbar widget
import '../../core/config/app_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../widgets/custom_search_view.dart';
import 'widgets/quotation_request_item_widget.dart';

class QuotationReceivedScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  _QuotationRequestScreenState createState() => _QuotationRequestScreenState();
}

class _QuotationRequestScreenState extends State<QuotationReceivedScreen> {
  final TextEditingController searchController = TextEditingController();
  List<dynamic> quotations = [];
  List<dynamic> filteredQuotations = [];
  bool isLoading = true;
  Map<String, dynamic> counters = {
    "quotations": 0,
    "orders": 0,
    "totalAmount": "KES 0",
    "delivered": 0,
    "notification": 0,
  };
  @override
  void initState() {
    super.initState();
    fetchCounters();

    _fetchQuotations();
    searchController.addListener(_filterQuotations);
  }

  Future<void> fetchCounters() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('userData');

      if (userDataString == null) {
        print("User data is not available");
        return;
      }

      final Map<String, dynamic> userData = json.decode(userDataString);
      final int? userId = userData['id'];

      if (userId == null) {
        print("User ID is not available in userData");
        return;
      }
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('usercounters')),
        body: {'usr_id': userId.toString()},
      );
      if (response.statusCode == 200) {
        setState(() {
          counters = json.decode(response.body);
        });
      }
    } catch (e) {
      print("Error fetching quotations: $e");
    }
  }

  Future<void> _fetchQuotations() async {
    try {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('userData');

      if (userDataString == null) {
        print("User data is not available");
        return;
      }
      final Map<String, dynamic> userData = json.decode(userDataString);

      final int? userId = userData['id'];
      if (userId == null) {
        print("User ID is not available in userData");
        return;
      }

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('get_quotation_received')),
        body: {'usr_id': userId.toString()},
      );
      print(response.body);
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        setState(() {
          quotations = data['quotations'] ?? [];
          filteredQuotations = quotations;
          isLoading = false;
        });
      } else {
        print("Failed to fetch quotations: ${response.statusCode}");
      }
    } catch (e) {
      print("Error fetching quotations: $e");
    }
  }

  void _filterQuotations() {
    final query = searchController.text.trim();
    if (query.isEmpty) {
      setState(() {
        filteredQuotations = quotations;
      });
      return;
    }
    setState(() {
      filteredQuotations = quotations.where((quotation) {
        final requestId = quotation['qre_request_id']?.toString() ?? '';
        return requestId.contains(query);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: widget._scaffoldKey,
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(
          "Quotations",
          style: TextStyle(color: Colors.white, fontSize: 24),
        ),
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () => widget._scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none, // Allow badge to overflow
            children: [
              GestureDetector(
                onTap: () {
                  if (counters["notification"]?.toString() != "0" &&
                      counters["notification"]?.toString().isNotEmpty == true) {
                    Navigator.pushNamed(
                      context,
                      '/notification', // Replace with your route
                    );
                  } // Replace with your route
                },
                child: Container(
                  margin: EdgeInsets.only(right: 8.0),
                  height: 36.0,
                  width: 36.0,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
                    Icons.notifications,
                    color: Colors.white,
                    size: 24.0,
                  ),
                ),
              ),
              (counters["notification"]?.toString() != "0" &&
                      counters["notification"]?.toString().isNotEmpty == true)
                  ? Positioned(
                      right: 0, // Align to the right edge
                      top: -6, // Move badge above the icon
                      child: Container(
                        padding: EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                              color: Colors.white,
                              width: 1.5), // White border for better visibility
                        ),
                        constraints: BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          counters["notification"]
                              .toString(), // Replace with dynamic count
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
            ],
          ),
        ],
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      drawer: Navbar(scaffoldKey: widget._scaffoldKey),
      body: SafeArea(
        child: Column(
          children: [
            _buildSearchAndFilterRow(),
            Expanded(
              child: isLoading
                  ? Center(child: CircularProgressIndicator())
                  : filteredQuotations.isEmpty
                      ? Center(child: Text("No quotations available"))
                      : _buildQuotationList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuotationList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 12),
      separatorBuilder: (context, index) => Padding(
        padding: EdgeInsets.symmetric(vertical: 8),
        child: Divider(thickness: 1.5, color: Colors.grey[300]),
      ),
      itemCount: filteredQuotations.length,
      itemBuilder: (context, index) {
        final quotation = filteredQuotations[index];
        //print(quotation['qre_request_id']);
        return Padding(
          padding: EdgeInsets.symmetric(vertical: 8),
          child: QuotationRequestItemWidget(
            Requestid: quotation['qre_request_id']?.toString() ?? '',

            quoteamount:
                '\KSH ${quotation['quo_total_amount']?.toString() ?? '0'}', // Default to '0' if null
            requeststatus: quotation['qre_quotation_status']?.toString() ?? '',
            requestdate: quotation['qre_created_dt']?.toString() ?? '',
            qstatus: quotation['qre_quotation_status']?.toString() ?? '',
          ),
        );
      },
    );
  }

  Widget _buildSearchAndFilterRow() {
    return Padding(
      padding: EdgeInsets.all(5),
      child: Row(
        children: [
          Expanded(
            child: SizedBox(
              height: 38, // Slimmer height for the search bar
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: "Search by Request ID",
                  border: OutlineInputBorder(),
                  contentPadding:
                      EdgeInsets.symmetric(vertical: 4.0, horizontal: 12.0),
                  hintStyle: TextStyle(fontSize: 12.0),
                ),
              ),
            ),
          ),
          Visibility(
            visible: searchController.text.isNotEmpty,
            child: IconButton(
              icon: Icon(Icons.clear),
              onPressed: () {
                searchController.clear();
              },
            ),
          ),
        ],
      ),
    );
  }
}
