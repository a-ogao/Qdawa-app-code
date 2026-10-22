import 'package:flutter/material.dart';
import '../../../core/config/app_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;

class PharmacyCouponFormScreen extends StatefulWidget {
  final Map<String, dynamic>? coupon;

  const PharmacyCouponFormScreen({Key? key, this.coupon}) : super(key: key);

  @override
  State<PharmacyCouponFormScreen> createState() =>
      _PharmacyCouponFormScreenState();
}

class _PharmacyCouponFormScreenState extends State<PharmacyCouponFormScreen> {
  final _formKey = GlobalKey<FormState>();
  final _codeController = TextEditingController();
  final _discountValueController = TextEditingController();
  final _minOrderController = TextEditingController(text: '0');
  final _maxUsesController = TextEditingController(text: '0');
  final _perUserController = TextEditingController(text: '1');

  String _discountType = 'percentage';
  String _status = 'active';
  DateTime? _expiryDate;
  bool _isSaving = false;
  int? _pharmacyId;

  bool get isEditing => widget.coupon != null;

  @override
  void initState() {
    super.initState();
    _initUser();
    if (widget.coupon != null) {
      final c = widget.coupon!;
      _codeController.text = c['cpn_code']?.toString() ?? '';
      _discountType = c['cpn_discount_type']?.toString() ?? 'percentage';
      _discountValueController.text =
          c['cpn_discount_value']?.toString() ?? '';
      _minOrderController.text = c['cpn_min_order_value']?.toString() ?? '0';
      _maxUsesController.text = c['cpn_max_uses']?.toString() ?? '0';
      _perUserController.text = c['cpn_per_user_limit']?.toString() ?? '1';
      _status = c['cpn_status']?.toString() ?? 'active';
      final expiry = c['cpn_expiry_date']?.toString();
      if (expiry != null && expiry.isNotEmpty) {
        _expiryDate = DateTime.tryParse(expiry);
      }
    }
  }

  Future<void> _initUser() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');
    if (userDataString != null) {
      final userData = json.decode(userDataString);
      _pharmacyId = userData['id'];
    }
  }

  @override
  void dispose() {
    _codeController.dispose();
    _discountValueController.dispose();
    _minOrderController.dispose();
    _maxUsesController.dispose();
    _perUserController.dispose();
    super.dispose();
  }

  Future<void> _pickExpiryDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _expiryDate ?? DateTime.now().add(const Duration(days: 30)),
      firstDate: DateTime.now(),
      lastDate: DateTime.now().add(const Duration(days: 365 * 5)),
    );
    if (picked != null) {
      setState(() => _expiryDate = picked);
    }
  }

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    if (_pharmacyId == null) return;

    setState(() => _isSaving = true);

    final body = {
      'pharmacy_id': _pharmacyId.toString(),
      'cpn_code': _codeController.text.trim().toUpperCase(),
      'cpn_discount_type': _discountType,
      'cpn_discount_value': _discountValueController.text.trim(),
      'cpn_min_order_value': _minOrderController.text.trim(),
      'cpn_max_uses': _maxUsesController.text.trim(),
      'cpn_per_user_limit': _perUserController.text.trim(),
      'cpn_status': _status,
      if (_expiryDate != null)
        'cpn_expiry_date':
            '${_expiryDate!.year}-${_expiryDate!.month.toString().padLeft(2, '0')}-${_expiryDate!.day.toString().padLeft(2, '0')} 23:59:59',
    };

    final url = isEditing
        ? AppConfig.buildApiUrl('update_pharmacy_coupon')
        : AppConfig.buildApiUrl('create_pharmacy_coupon');

    if (isEditing) {
      body['coupon_id'] = widget.coupon!['id'].toString();
    }

    try {
      final response = await http.post(Uri.parse(url), body: body);
      final data = json.decode(response.body);

      if (data['success'] == true) {
        if (!mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data['message'] ?? 'Saved')),
        );
        Navigator.pop(context, true);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(data['message'] ?? 'Failed to save coupon')),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $e')),
      );
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          isEditing ? 'Edit Coupon' : 'Create Coupon',
          style: const TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0XFF4675C0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16),
          children: [
            TextFormField(
              controller: _codeController,
              decoration: const InputDecoration(
                labelText: 'Coupon Code *',
                border: OutlineInputBorder(),
              ),
              textCapitalization: TextCapitalization.characters,
              validator: (v) =>
                  (v == null || v.trim().isEmpty) ? 'Required' : null,
            ),
            const SizedBox(height: 16),
            DropdownButtonFormField<String>(
              value: _discountType,
              decoration: const InputDecoration(
                labelText: 'Discount Type *',
                border: OutlineInputBorder(),
              ),
              items: const [
                DropdownMenuItem(
                    value: 'percentage', child: Text('Percentage (%)')),
                DropdownMenuItem(
                    value: 'amount', child: Text('Fixed Amount (KES)')),
              ],
              onChanged: (v) => setState(() => _discountType = v!),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _discountValueController,
              decoration: InputDecoration(
                labelText: _discountType == 'percentage'
                    ? 'Discount Percentage *'
                    : 'Discount Amount (KES) *',
                border: const OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              validator: (v) {
                if (v == null || v.trim().isEmpty) return 'Required';
                final n = double.tryParse(v);
                if (n == null || n <= 0) return 'Enter a valid value';
                if (_discountType == 'percentage' && n > 100) {
                  return 'Max 100%';
                }
                return null;
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _minOrderController,
              decoration: const InputDecoration(
                labelText: 'Minimum Order Value (0 = any)',
                border: OutlineInputBorder(),
              ),
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _maxUsesController,
              decoration: const InputDecoration(
                labelText: 'Total Uses (0 = unlimited)',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _perUserController,
              decoration: const InputDecoration(
                labelText: 'Uses Per User',
                border: OutlineInputBorder(),
              ),
              keyboardType: TextInputType.number,
              validator: (v) {
                final n = int.tryParse(v ?? '');
                if (n == null || n < 1) return 'Min 1';
                return null;
              },
            ),
            const SizedBox(height: 16),
            ListTile(
              contentPadding: EdgeInsets.zero,
              title: const Text('Expiry Date (optional)'),
              subtitle: Text(_expiryDate == null
                  ? 'No expiry'
                  : '${_expiryDate!.day}/${_expiryDate!.month}/${_expiryDate!.year}'),
              trailing: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  if (_expiryDate != null)
                    IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _expiryDate = null),
                    ),
                  IconButton(
                    icon: const Icon(Icons.calendar_today),
                    onPressed: _pickExpiryDate,
                  ),
                ],
              ),
            ),
            const SizedBox(height: 8),
            SwitchListTile(
              title: const Text('Active'),
              value: _status == 'active',
              onChanged: (v) =>
                  setState(() => _status = v ? 'active' : 'inactive'),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              onPressed: _isSaving ? null : _save,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0XFF4675C0),
                padding: const EdgeInsets.symmetric(vertical: 14),
              ),
              child: _isSaving
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                          strokeWidth: 2, color: Colors.white),
                    )
                  : Text(isEditing ? 'Update Coupon' : 'Create Coupon',
                      style: const TextStyle(color: Colors.white)),
            ),
          ],
        ),
      ),
    );
  }
}
