import 'package:flutter/material.dart';
import '../nav_bar/navbar_widget.dart';
import '../../core/config/app_config.dart';
import '../../core/utils/patient_api_context.dart';
import '../../widgets/patient_profile_switcher.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../../widgets/custom_search_view.dart';
import 'widgets/quotation_request_item_widget.dart';

class QuotationRequestScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  _QuotationRequestScreenState createState() => _QuotationRequestScreenState();
}

class _QuotationRequestScreenState extends State<QuotationRequestScreen> {
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
      final body = await PatientApiContext.body();
      if (!body.containsKey('usr_id')) return;
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('usercounters')),
        body: body,
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
      final body = await PatientApiContext.body();
      if (!body.containsKey('usr_id')) return;

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('get_quotation_request')),
        body: body,
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
        final queryLower = query.toLowerCase();

        final requestId =
            quotation['qre_request_id']?.toString().toLowerCase() ?? '';
        final name =
            quotation['pat_first_name']?.toString().toLowerCase() ?? '';
        final amount =
            quotation['quo_total_amount']?.toString().toLowerCase() ?? '';
        final phone =
            quotation['qre_created_dt']?.toString().toLowerCase() ?? '';

        return requestId.contains(queryLower) ||
            name.contains(queryLower) ||
            amount.contains(queryLower) ||
            phone.contains(queryLower);
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: widget._scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: Text(
          "Quotations",
          style: TextStyle(
            color: Colors.white,
            fontSize: 24,
            fontWeight: FontWeight.bold,
          ),
        ),
        leading: IconButton(
          icon: Icon(Icons.menu, color: Colors.white),
          onPressed: () => widget._scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          PatientProfileSwitcher(onSwitched: () {
            fetchCounters();
            _fetchQuotations();
          }),
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  if (counters["notification"]?.toString() != "0" &&
                      counters["notification"]?.toString().isNotEmpty == true) {
                    Navigator.pushNamed(
                      context,
                      '/notification',
                    );
                  }
                },
                child: Container(
                  margin: EdgeInsets.only(right: 8.0),
                  height: 36.0,
                  width: 36.0,
                  decoration: BoxDecoration(
                    color: Colors.white.withOpacity(0.2),
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
                      right: 0,
                      top: -6,
                      child: Container(
                        padding: EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          counters["notification"].toString(),
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
        backgroundColor: Color(0XFF4675C0),
        elevation: 0,
      ),
      drawer: Navbar(scaffoldKey: widget._scaffoldKey),
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
              _buildEnhancedSearchAndFilterRow(),
              SizedBox(height: 20),
              Expanded(
                child: isLoading
                    ? _buildLoadingState()
                    : filteredQuotations.isEmpty
                        ? _buildEmptyState()
                        : _buildEnhancedQuotationList(),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedSearchAndFilterRow() {
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
                decoration: InputDecoration(
                  hintText: "Search quotations...",
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
                  _filterQuotations();
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
            'Loading quotations...',
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
              Icons.inbox_outlined,
              size: 48,
              color: Colors.grey[400],
            ),
          ),
          SizedBox(height: 24),
          Text(
            'No quotations found',
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

  Widget _buildEnhancedQuotationList() {
    return ListView.separated(
      padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      separatorBuilder: (context, index) => SizedBox(height: 12),
      itemCount: filteredQuotations.length,
      itemBuilder: (context, index) {
        final quotation = filteredQuotations[index];

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
            child: QuotationRequestItemWidget(
              Requestid: quotation['qre_request_id']?.toString() ?? '',
              quoteamount:
                  '\KSH ${quotation['quo_total_amount']?.toString() ?? '0'}',
              requeststatus:
                  quotation['qre_quotation_status']?.toString() ?? '',
              requestdate: quotation['qre_created_dt']?.toString() ?? '',
              qstatus: quotation['qre_quotation_status']?.toString() ?? '',
            ),
          ),
        );
      },
    );
  }
}
