import 'dart:async';
import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:geolocator/geolocator.dart';
import 'package:http/http.dart' as http;

import '../../core/config/app_config.dart';
import '../../core/utils/patient_api_context.dart';
import '../payment_option/payment_option.dart';

class OtcOrderScreen extends StatefulWidget {
  const OtcOrderScreen({Key? key}) : super(key: key);

  @override
  State<OtcOrderScreen> createState() => _OtcOrderScreenState();
}

class _OtcOrderScreenState extends State<OtcOrderScreen> {
  final TextEditingController _searchController = TextEditingController();
  Timer? _debounce;
  List<Map<String, dynamic>> _suggestions = [];
  Map<String, dynamic>? _selected;
  bool _searching = false;
  bool _searched = false;
  bool _placing = false;
  int _quantity = 1;
  String? _statusMessage;

  @override
  void dispose() {
    _debounce?.cancel();
    _searchController.dispose();
    super.dispose();
  }

  void _onQueryChanged(String value) {
    final query = value.trim();
    if (_selected != null && query != _selected!['name'].toString()) {
      _selected = null;
      _quantity = 1;
    }
    _debounce?.cancel();
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _searching = false;
        _searched = false;
        _statusMessage = null;
      });
      return;
    }
    _debounce = Timer(const Duration(milliseconds: 400), () {
      _search(query);
    });
  }

  Future<void> _search(String query) async {
    setState(() {
      _searching = true;
      _statusMessage = null;
    });
    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('search_otc_medicines')),
        body: {'query': query},
      );
      if (!mounted || _searchController.text.trim() != query) return;
      final data = json.decode(response.body);
      final medicines = data is Map && data['medicines'] is List
          ? List<Map<String, dynamic>>.from(
              (data['medicines'] as List).map((item) => Map<String, dynamic>.from(item)),
            )
          : <Map<String, dynamic>>[];
      setState(() {
        _suggestions = medicines;
        _searching = false;
        _searched = true;
        _statusMessage = medicines.isEmpty ? 'Not available for quick order' : null;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _suggestions = [];
        _searching = false;
        _searched = true;
        _statusMessage = 'Could not search medicines. Try again.';
      });
    }
  }

  void _selectMedicine(Map<String, dynamic> medicine) {
    _searchController.text = medicine['name'].toString();
    setState(() {
      _selected = medicine;
      _suggestions = [];
      _statusMessage = null;
      _quantity = 1;
    });
  }

  double get _unitPrice => double.tryParse('${_selected?['price'] ?? 0}') ?? 0;

  double get _total => _unitPrice * _quantity;

  Future<void> _continueToPayment() async {
    final typed = _searchController.text.trim();
    if (_selected == null || typed != _selected!['name'].toString()) {
      setState(() {
        _statusMessage = 'Not available for quick order';
      });
      return;
    }

    setState(() => _placing = true);
    try {
      final position = await _currentPosition();
      if (position == null) {
        setState(() => _placing = false);
        return;
      }

      final body = await PatientApiContext.body({
        'medicine_id': _selected!['id'].toString(),
        'quantity': _quantity.toString(),
        'latitude': position.latitude.toString(),
        'longitude': position.longitude.toString(),
      });
      if (!body.containsKey('usr_id')) {
        _showMessage('Sign in as a patient to place this order.');
        setState(() => _placing = false);
        return;
      }

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('prepare_otc_order')),
        body: body,
      );
      final data = json.decode(response.body);
      if (!mounted) return;
      if (data is Map && data['success'] == true) {
        final quoId = data['quo_id']?.toString() ?? '';
        final payable = double.tryParse('${data['payable_amount'] ?? data['total'] ?? _total}') ??
            _total;
        if (quoId.isEmpty) {
          _showMessage('Could not start checkout. Try again.');
          return;
        }
        await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => PaymentOptionsScreen(
              qid: quoId,
              payableAmount: payable,
            ),
          ),
        );
      } else {
        _showMessage(
          data is Map
              ? (data['message']?.toString() ?? 'Could not start checkout.')
              : 'Could not start checkout.',
        );
      }
    } catch (e) {
      _showMessage('Could not start checkout. Try again.');
    } finally {
      if (mounted) setState(() => _placing = false);
    }
  }

  Future<Position?> _currentPosition() async {
    final enabled = await Geolocator.isLocationServiceEnabled();
    if (!enabled) {
      _showMessage('Turn on location so the order can go to the nearest pharmacy.');
      return null;
    }
    var permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
    }
    if (permission == LocationPermission.denied ||
        permission == LocationPermission.deniedForever) {
      _showMessage('Location permission is required to choose the nearest pharmacy.');
      return null;
    }
    return Geolocator.getCurrentPosition();
  }

  void _showMessage(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text(message)));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFF8FAFC),
      appBar: AppBar(
        title: const Text(
          'General medicine',
          style: TextStyle(color: Colors.white, fontSize: 18),
        ),
        backgroundColor: const Color(0xFF4675C0),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Text(
            'Place order for general medicine',
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.w700,
              color: Color(0xFF1E293B),
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Type a medicine name and choose one from the OTC list. Pay with M-Pesa, then the order goes to the nearest pharmacy.',
            style: TextStyle(fontSize: 14, color: Color(0xFF64748B)),
          ),
          const SizedBox(height: 20),
          TextField(
            controller: _searchController,
            onChanged: _onQueryChanged,
            decoration: InputDecoration(
              hintText: 'Medicine name',
              filled: true,
              fillColor: Colors.white,
              prefixIcon: const Icon(Icons.search),
              suffixIcon: _searching
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : null,
              border: OutlineInputBorder(borderRadius: BorderRadius.circular(14)),
            ),
          ),
          if (_statusMessage != null) ...[
            const SizedBox(height: 12),
            Text(
              _statusMessage!,
              style: const TextStyle(
                color: Color(0xFFB45309),
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
          if (_suggestions.isNotEmpty)
            Container(
              margin: const EdgeInsets.only(top: 8),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(14),
                border: Border.all(color: const Color(0xFFE2E8F0)),
              ),
              child: Column(
                children: _suggestions.map((medicine) {
                  final subtitle = medicine['medicine_name']?.toString() ?? '';
                  return ListTile(
                    title: Text(medicine['name'].toString()),
                    subtitle: Text(
                      subtitle.isEmpty
                          ? 'KSH ${medicine['price']}'
                          : '$subtitle\nKSH ${medicine['price']}',
                    ),
                    isThreeLine: subtitle.isNotEmpty,
                    onTap: () => _selectMedicine(medicine),
                  );
                }).toList(),
              ),
            ),
          if (_selected != null &&
              _searchController.text.trim() == _selected!['name'].toString()) ...[
            const SizedBox(height: 20),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(16),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    _selected!['name'].toString(),
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    'Price: KSH ${_unitPrice.toStringAsFixed(2)}',
                    style: const TextStyle(color: Color(0xFF4675C0), fontWeight: FontWeight.w600),
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      const Text('Quantity', style: TextStyle(fontWeight: FontWeight.w600)),
                      const Spacer(),
                      IconButton(
                        onPressed: _quantity > 1
                            ? () => setState(() => _quantity -= 1)
                            : null,
                        icon: const Icon(Icons.remove_circle_outline),
                      ),
                      Text('$_quantity', style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w700)),
                      IconButton(
                        onPressed: _quantity < 99
                            ? () => setState(() => _quantity += 1)
                            : null,
                        icon: const Icon(Icons.add_circle_outline),
                      ),
                    ],
                  ),
                  Text(
                    'Total: KSH ${_total.toStringAsFixed(2)}',
                    style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 48,
              child: ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF4675C0),
                  foregroundColor: Colors.white,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(14)),
                ),
                onPressed: _placing ? null : _continueToPayment,
                child: _placing
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                      )
                    : const Text('Continue to payment'),
              ),
            ),
          ] else if (_searched && _suggestions.isEmpty && _searchController.text.trim().length >= 3)
            const SizedBox.shrink(),
        ],
      ),
    );
  }
}
