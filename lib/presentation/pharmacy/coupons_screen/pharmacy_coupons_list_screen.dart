import 'package:flutter/material.dart';
import '../nav_bar/navbar_widget.dart';
import '../../../core/config/app_config.dart';
import 'pharmacy_coupon_form_screen.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class PharmacyCouponsListScreen extends StatefulWidget {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();

  @override
  State<PharmacyCouponsListScreen> createState() =>
      _PharmacyCouponsListScreenState();
}

class _PharmacyCouponsListScreenState extends State<PharmacyCouponsListScreen> {
  List<dynamic> coupons = [];
  bool isLoading = true;
  int? pharmacyId;

  @override
  void initState() {
    super.initState();
    _loadCoupons();
  }

  Future<void> _loadCoupons() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userDataString = prefs.getString('userData');
      if (userDataString == null) return;

      final userData = json.decode(userDataString);
      final userId = userData['id'];
      if (userId == null) return;

      pharmacyId = userId;

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('list_pharmacy_coupons')),
        body: {'pharmacy_id': userId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        setState(() {
          coupons = data['coupons'] ?? [];
          isLoading = false;
        });
      } else {
        setState(() => isLoading = false);
      }
    } catch (_) {
      setState(() => isLoading = false);
    }
  }

  Future<void> _toggleCoupon(int couponId) async {
    if (pharmacyId == null) return;

    final response = await http.post(
      Uri.parse(AppConfig.buildApiUrl('toggle_pharmacy_coupon')),
      body: {
        'pharmacy_id': pharmacyId.toString(),
        'coupon_id': couponId.toString(),
      },
    );

    if (response.statusCode == 200) {
      final data = json.decode(response.body);
      if (data['success'] == true) {
        _loadCoupons();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Status updated')),
        );
      }
    }
  }

  String _discountLabel(Map<String, dynamic> coupon) {
    final type = coupon['cpn_discount_type']?.toString() ?? '';
    final value = coupon['cpn_discount_value']?.toString() ?? '0';
    return type == 'percentage' ? '$value%' : 'KES $value';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: widget._scaffoldKey,
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        title: const Text(
          'Coupon Codes',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.w600),
        ),
        backgroundColor: const Color(0XFF4675C0),
        leading: IconButton(
          icon: const Icon(Icons.menu, color: Colors.white),
          onPressed: () => widget._scaffoldKey.currentState?.openDrawer(),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.add, color: Colors.white),
            onPressed: () async {
              final refreshed = await Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (_) => const PharmacyCouponFormScreen(),
                ),
              );
              if (refreshed == true) _loadCoupons();
            },
          ),
        ],
      ),
      drawer: Navbar(scaffoldKey: widget._scaffoldKey),
      floatingActionButton: FloatingActionButton(
        backgroundColor: const Color(0XFF4675C0),
        onPressed: () async {
          final refreshed = await Navigator.push(
            context,
            MaterialPageRoute(
              builder: (_) => const PharmacyCouponFormScreen(),
            ),
          );
          if (refreshed == true) _loadCoupons();
        },
        child: const Icon(Icons.add),
      ),
      body: isLoading
          ? const Center(child: CircularProgressIndicator())
          : coupons.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.confirmation_number_outlined,
                          size: 64, color: Colors.grey[400]),
                      const SizedBox(height: 16),
                      Text('No coupons yet',
                          style: TextStyle(
                              fontSize: 18, color: Colors.grey[600])),
                      const SizedBox(height: 8),
                      const Text('Tap + to create your first coupon'),
                    ],
                  ),
                )
              : RefreshIndicator(
                  onRefresh: _loadCoupons,
                  child: ListView.builder(
                    padding: const EdgeInsets.all(16),
                    itemCount: coupons.length,
                    itemBuilder: (context, index) {
                      final coupon = coupons[index] as Map<String, dynamic>;
                      final isActive =
                          coupon['cpn_status']?.toString() == 'active';
                      final maxUses = int.tryParse(
                              coupon['cpn_max_uses']?.toString() ?? '0') ??
                          0;
                      final usedCount = int.tryParse(
                              coupon['cpn_used_count']?.toString() ?? '0') ??
                          0;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  coupon['cpn_code']?.toString() ?? '',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(
                                    horizontal: 8, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isActive
                                      ? Colors.green.shade100
                                      : Colors.grey.shade200,
                                  borderRadius: BorderRadius.circular(12),
                                ),
                                child: Text(
                                  isActive ? 'Active' : 'Inactive',
                                  style: TextStyle(
                                    fontSize: 12,
                                    color: isActive
                                        ? Colors.green.shade800
                                        : Colors.grey.shade700,
                                    fontWeight: FontWeight.w600,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 8),
                              Text('Discount: ${_discountLabel(coupon)}'),
                              Text(
                                'Min order: KES ${coupon['cpn_min_order_value'] ?? 0}',
                              ),
                              Text(
                                'Uses: $usedCount${maxUses > 0 ? ' / $maxUses' : ' (unlimited)'}',
                              ),
                              Text(
                                'Per user: ${coupon['cpn_per_user_limit'] ?? 1}',
                              ),
                              if (coupon['cpn_expiry_date'] != null)
                                Text(
                                  'Expires: ${coupon['cpn_expiry_date']}',
                                  style: TextStyle(color: Colors.orange[800]),
                                ),
                            ],
                          ),
                          trailing: PopupMenuButton<String>(
                            onSelected: (value) async {
                              if (value == 'toggle') {
                                _toggleCoupon(
                                    int.parse(coupon['id'].toString()));
                              } else if (value == 'edit') {
                                final refreshed = await Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (_) => PharmacyCouponFormScreen(
                                      coupon: coupon,
                                    ),
                                  ),
                                );
                                if (refreshed == true) _loadCoupons();
                              }
                            },
                            itemBuilder: (_) => [
                              PopupMenuItem(
                                value: 'edit',
                                child: const Text('Edit'),
                              ),
                              PopupMenuItem(
                                value: 'toggle',
                                child: Text(
                                    isActive ? 'Deactivate' : 'Activate'),
                              ),
                            ],
                          ),
                        ),
                      );
                    },
                  ),
                ),
    );
  }
}
