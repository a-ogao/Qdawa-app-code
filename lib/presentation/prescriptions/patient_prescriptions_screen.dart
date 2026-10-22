import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

import '../../core/config/app_config.dart';
import '../../core/utils/patient_api_context.dart';
import '../../widgets/patient_profile_switcher.dart';
import '../nav_bar/navbar_widget.dart';

class PatientPrescriptionsScreen extends StatefulWidget {
  PatientPrescriptionsScreen({super.key});

  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  State<PatientPrescriptionsScreen> createState() =>
      _PatientPrescriptionsScreenState();
}

class _PatientPrescriptionsScreenState
    extends State<PatientPrescriptionsScreen> {
  static const Set<String> _orderStatuses = {
    'ready',
    'dispatched',
    'delivered',
    'order placed',
    'completed',
  };

  final TextEditingController searchController = TextEditingController();

  List<Map<String, dynamic>> prescriptions = [];
  List<Map<String, dynamic>> filteredPrescriptions = [];

  bool isLoading = true;
  String? errorMessage;
  final Map<String, String> _requestToOrderMap = {};
  Future<void>? _orderIndexFuture;

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
    _fetchPrescriptions();
    searchController.addListener(_filterPrescriptions);
  }

  @override
  void dispose() {
    searchController.removeListener(_filterPrescriptions);
    searchController.dispose();
    super.dispose();
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
      debugPrint("Error fetching counters: $e");
    }
  }

  Future<void> _fetchPrescriptions({bool showLoader = true}) async {
    if (showLoader) {
      setState(() {
        isLoading = true;
        errorMessage = null;
      });
    }

    try {
      final apiBody = await PatientApiContext.body({'per_page': '50'});
      if (!apiBody.containsKey('usr_id')) {
        setState(() {
          errorMessage = "User not found. Please sign in again.";
          prescriptions = [];
          filteredPrescriptions = [];
          isLoading = false;
        });
        return;
      }

      final requestPayload = <String, dynamic>{
        'usr_id': int.parse(apiBody['usr_id']!),
        'per_page': 50,
      };
      if (apiBody.containsKey('actor_usr_id')) {
        requestPayload['actor_usr_id'] = int.parse(apiBody['actor_usr_id']!);
      }

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('api/patient_prescriptions')),
        headers: {
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: json.encode(requestPayload),
      );
      debugPrint(
          "📡 patient_prescriptions request: ${json.encode(requestPayload)}");
      debugPrint(
          "📨 patient_prescriptions response [${response.statusCode}]: ${response.body}");

      if (response.statusCode == 200) {
        final Map<String, dynamic> body = json.decode(response.body);

        if (body['success'] == true) {
          final List<dynamic> data = body['data'] ?? [];
          final prescriptionsList = data
              .map((item) => Map<String, dynamic>.from(item))
              .toList(growable: false);

          setState(() {
            prescriptions = prescriptionsList;
            filteredPrescriptions = _applyLocalFilter(prescriptionsList);
            isLoading = false;
            errorMessage = null;
          });
        } else {
          setState(() {
            errorMessage =
                body['message']?.toString() ?? "Unable to load prescriptions.";
            prescriptions = [];
            filteredPrescriptions = [];
            isLoading = false;
          });
        }
      } else {
        setState(() {
          errorMessage =
              "Server error (${response.statusCode}). Please try again.";
          prescriptions = [];
          filteredPrescriptions = [];
          isLoading = false;
        });
      }
    } catch (e) {
      setState(() {
        errorMessage = "Something went wrong. Please try again.";
        prescriptions = [];
        filteredPrescriptions = [];
        isLoading = false;
      });
      debugPrint("Error fetching prescriptions: $e");
    }
  }

  List<Map<String, dynamic>> _applyLocalFilter(
      List<Map<String, dynamic>> source) {
    final query = searchController.text.trim().toLowerCase();
    if (query.isEmpty) {
      return source;
    }

    return source.where((item) {
      final requestId = (item['request_id']?.toString() ?? '').toLowerCase();
      final quotationRequestId =
          (item['quotation_request_id']?.toString() ?? '').toLowerCase();
      final pharmacy = _pharmacyDisplayName(item).toLowerCase();
      return requestId.contains(query) ||
          quotationRequestId.contains(query) ||
          pharmacy.contains(query);
    }).toList();
  }

  void _filterPrescriptions() {
    setState(() {
      filteredPrescriptions = _applyLocalFilter(prescriptions);
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: widget._scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          "Prescriptions",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
        backgroundColor: const Color(0XFF4675C0),
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => widget._scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  if (counters["notification"]?.toString() != "0" &&
                      counters["notification"]?.toString().isNotEmpty == true) {
                    Navigator.pushNamed(context, '/notification');
                  }
                },
                child: Container(
                  margin: const EdgeInsets.only(right: 8.0),
                  height: 36.0,
                  width: 36.0,
                  decoration: BoxDecoration(
                    color: Theme.of(context).colorScheme.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
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
                        padding: const EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(
                            color: Colors.white,
                            width: 1.5,
                          ),
                        ),
                        constraints: const BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          counters["notification"].toString(),
                          style: const TextStyle(
                            color: Colors.white,
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : const SizedBox.shrink(),
            ],
          ),
        ],
      ),
      drawer: Navbar(scaffoldKey: widget._scaffoldKey),
      body: SafeArea(
        child: Column(
          children: [
            const SizedBox(height: 16),
            _buildSearchBar(),
            const SizedBox(height: 20),
            Expanded(
              child: isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : errorMessage != null
                      ? _buildErrorState()
                      : filteredPrescriptions.isEmpty
                          ? _buildEmptyState()
                          : _buildPrescriptionList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSearchBar() {
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 4),
        child: Row(
          children: [
            Icon(Icons.search, color: Colors.grey[600], size: 24),
            const SizedBox(width: 12),
            Expanded(
              child: TextField(
                controller: searchController,
                decoration: InputDecoration(
                  hintText: 'Search by Request ID or pharmacy',
                  hintStyle: TextStyle(
                    color: Colors.grey[400],
                    fontSize: 14,
                  ),
                  border: InputBorder.none,
                  contentPadding:
                      const EdgeInsets.symmetric(vertical: 14, horizontal: 4),
                ),
                style: TextStyle(
                  fontSize: 14,
                  color: Colors.grey[800],
                ),
              ),
            ),
            if (searchController.text.isNotEmpty)
              IconButton(
                icon: Icon(Icons.clear, color: Colors.grey[600], size: 20),
                onPressed: () {
                  searchController.clear();
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildPrescriptionList() {
    return RefreshIndicator(
      color: const Color(0XFF4675C0),
      onRefresh: () => _fetchPrescriptions(showLoader: false),
      child: ListView.separated(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        itemCount: filteredPrescriptions.length,
        separatorBuilder: (_, __) => const SizedBox(height: 12),
        itemBuilder: (context, index) {
          final prescription = filteredPrescriptions[index];
          final requestId = _displayRequestId(prescription);

          return _PrescriptionCard(
            requestId: requestId,
            pharmacyName: _pharmacyDisplayName(prescription),
            dateLabel: prescription['requested_at_iso']?.toString() ??
                prescription['requested_at']?.toString() ??
                '',
            statusLabel: prescription['status_label']?.toString() ??
                (prescription['status']?.toString() ?? '').toUpperCase(),
            rawStatus: prescription['status']?.toString() ??
                prescription['status_label']?.toString() ??
                '',
            onTap: () => _handlePrescriptionTap(context, prescription),
          );
        },
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.description_outlined,
              size: 48, color: Colors.grey.withOpacity(0.5)),
          const SizedBox(height: 12),
          const Text(
            "No prescriptions found",
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            "New prescriptions will appear here.",
            style: TextStyle(
              fontSize: 13,
              color: Colors.grey[600],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 32.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(Icons.wifi_off, size: 48, color: Colors.red.withOpacity(0.6)),
            const SizedBox(height: 12),
            Text(
              errorMessage ?? "Unable to load prescriptions.",
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 16),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0XFF4675C0),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
              ),
              onPressed: () => _fetchPrescriptions(),
              child: const Text("Retry"),
            ),
          ],
        ),
      ),
    );
  }

  String _pharmacyDisplayName(Map<String, dynamic> prescription) {
    const keys = [
      'pharmacy_name',
      'organization_name',
      'pha_first_name',
      'pha_name',
    ];
    for (final key in keys) {
      final raw = prescription[key]?.toString().trim() ?? '';
      if (raw.isNotEmpty && raw.toLowerCase() != 'null') {
        return raw;
      }
    }
    return '';
  }

  Future<void> _handlePrescriptionTap(
      BuildContext context, Map<String, dynamic> prescription) async {
    final requestId = _navigationRequestId(prescription);
    if (requestId.isEmpty) {
      _showSnack("Request ID not available");
      return;
    }

    final statusValue =
        (prescription['status'] ?? prescription['status_label'] ?? '')
            .toString()
            .trim()
            .toLowerCase();
    final orderStatus =
        prescription['order_status']?.toString().trim().toLowerCase() ?? '';

    final bool isOrder = (orderStatus.isNotEmpty && orderStatus != 'null') ||
        _orderStatuses.contains(statusValue);

    if (isOrder) {
      _showLoadingDialog();
      final orderId = await _ensureOrderId(requestId);
      Navigator.of(context, rootNavigator: true).pop();

      if (orderId != null && orderId.isNotEmpty) {
        Navigator.pushNamed(
          context,
          '/order_track_status_screen',
          arguments: {'orderId': orderId},
        );
      } else {
        _showSnack("Order not found");
      }
      return;
    }

    Navigator.pushNamed(
      context,
      '/quotation_list_screen',
      arguments: {'Requestid': requestId},
    );
  }

  String _displayRequestId(Map<String, dynamic> prescription) {
    final raw = _rawRequestId(prescription);
    if (raw.isEmpty) return '';
    return raw.startsWith('#') ? raw : '#$raw';
  }

  String _navigationRequestId(Map<String, dynamic> prescription) {
    final raw = _rawRequestId(prescription);
    return _normalizeRequestId(raw);
  }

  String _rawRequestId(Map<String, dynamic> prescription) {
    return prescription['quotation_request_id']?.toString().trim() ??
        prescription['request_id']?.toString().trim() ??
        '';
  }

  String _normalizeRequestId(String raw) =>
      raw.replaceAll('#', '').trim().toUpperCase();

  Future<String?> _ensureOrderId(String requestId) async {
    final key = _normalizeRequestId(requestId);
    if (_requestToOrderMap.containsKey(key)) {
      return _requestToOrderMap[key];
    }
    await _loadOrderIndex();
    return _requestToOrderMap[key];
  }

  Future<void> _loadOrderIndex() async {
    if (_orderIndexFuture != null) {
      await _orderIndexFuture;
      return;
    }
    _orderIndexFuture = _fetchAndIndexOrders();
    await _orderIndexFuture;
    _orderIndexFuture = null;
  }

  Future<void> _fetchAndIndexOrders() async {
    try {
      final body = await PatientApiContext.body();
      if (!body.containsKey('usr_id')) return;
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('get_myorders')),
        body: body,
      );
      debugPrint("📡 get_myorders request: $body");
      debugPrint(
          "📨 get_myorders response [${response.statusCode}]: ${response.body}");
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        final List<dynamic> orders = data['orders'] ?? [];
        final Map<String, String> mapping = {};
        for (final order in orders) {
          final reqId = order['qre_request_id']?.toString() ?? '';
          final orderId = order['id']?.toString() ?? '';
          final normalized = _normalizeRequestId(reqId);
          if (normalized.isNotEmpty && orderId.isNotEmpty) {
            mapping[normalized] = orderId;
          }
        }
        if (mapping.isNotEmpty) {
          setState(() {
            _requestToOrderMap.addAll(mapping);
          });
        }
      } else {
        debugPrint(
            "Failed to load order index: HTTP ${response.statusCode} ${response.body}");
      }
    } catch (e) {
      debugPrint("Error loading order index: $e");
    }
  }

  void _showLoadingDialog() {
    showDialog(
      context: context,
      barrierDismissible: false,
      barrierColor: Colors.black26,
      builder: (_) => const Center(child: CircularProgressIndicator()),
    );
  }

  void _showSnack(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

class _PrescriptionCard extends StatelessWidget {
  final String requestId;
  final String pharmacyName;
  final String dateLabel;
  final String statusLabel;
  final String rawStatus;
  final VoidCallback? onTap;

  const _PrescriptionCard({
    required this.requestId,
    required this.pharmacyName,
    required this.dateLabel,
    required this.statusLabel,
    required this.rawStatus,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(16),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.05),
              blurRadius: 24,
              offset: const Offset(0, 12),
              spreadRadius: 0,
            ),
          ],
        ),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              flex: 3,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: const Color(0XFF4675C0).withOpacity(0.1),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          requestId,
                          style: const TextStyle(
                            color: Color(0XFF4675C0),
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  if (pharmacyName.isNotEmpty)
                    Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.local_pharmacy_outlined,
                          size: 20,
                          color: const Color(0XFF4675C0),
                        ),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            pharmacyName,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Color(0XFF4675C0),
                            ),
                            maxLines: 2,
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                      ],
                    ),
                  if (pharmacyName.isNotEmpty) const SizedBox(height: 12),
                  if (dateLabel.isNotEmpty)
                    Row(
                      children: [
                        Icon(Icons.calendar_today_outlined,
                            size: 16, color: Colors.grey[600]),
                        const SizedBox(width: 8),
                        Text(
                          _formatDate(dateLabel),
                          style: TextStyle(
                            fontSize: 14,
                            color: Colors.grey[700],
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              flex: 2,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  _buildStatusBadge(statusLabel, rawStatus),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildStatusBadge(String label, String status) {
    final statusConfig = _statusStyle(status);
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      decoration: BoxDecoration(
        color: statusConfig.color.withOpacity(0.1),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: statusConfig.color.withOpacity(0.3),
          width: 1,
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            statusConfig.icon,
            size: 16,
            color: statusConfig.color,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w600,
              color: statusConfig.color,
            ),
          ),
        ],
      ),
    );
  }

  _StatusConfig _statusStyle(String rawStatus) {
    final normalized = rawStatus.toLowerCase();
    if (normalized.contains("completed")) {
      return _StatusConfig(Colors.green, Icons.check_circle);
    }
    if (normalized.contains("accepted")) {
      return _StatusConfig(Colors.blue, Icons.mail_outline);
    }
    if (normalized.contains("order")) {
      return _StatusConfig(Colors.orange, Icons.task_alt);
    }
    if (normalized.contains("received")) {
      return _StatusConfig(Colors.indigo, Icons.inbox);
    }
    if (normalized.contains("cancel")) {
      return _StatusConfig(Colors.red, Icons.cancel_outlined);
    }
    return _StatusConfig(Colors.grey, Icons.help_outline);
  }

  static String _formatDate(String dateString) {
    try {
      DateTime dateTime;
      if (dateString.contains('T')) {
        dateTime = DateTime.parse(dateString);
      } else {
        dateTime = DateTime.parse(dateString.replaceAll(' ', 'T'));
      }
      return "${dateTime.day.toString().padLeft(2, '0')}/"
          "${dateTime.month.toString().padLeft(2, '0')}/"
          "${dateTime.year}";
    } catch (_) {
      return dateString;
    }
  }
}

class _StatusConfig {
  final Color color;
  final IconData icon;

  const _StatusConfig(this.color, this.icon);
}
