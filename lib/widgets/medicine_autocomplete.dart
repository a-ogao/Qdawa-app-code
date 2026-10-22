import 'package:flutter/material.dart';
import 'dart:async';
import '../core/api_service.dart';

class MedicineAutocomplete extends StatefulWidget {
  final TextEditingController controller;
  final Function(Map<String, dynamic>) onMedicineSelected;
  final String hintText;
  final double fontSize;

  const MedicineAutocomplete({
    Key? key,
    required this.controller,
    required this.onMedicineSelected,
    this.hintText = "Enter medicine name",
    this.fontSize = 11.0,
  }) : super(key: key);

  @override
  _MedicineAutocompleteState createState() => _MedicineAutocompleteState();
}

class _MedicineAutocompleteState extends State<MedicineAutocomplete> {
  List<Map<String, dynamic>> _suggestions = [];
  bool _isLoading = false;
  String _lastQuery = '';
  Timer? _debounceTimer;
  OverlayEntry? _overlayEntry;
  final LayerLink _layerLink = LayerLink();
  final GlobalKey _textFieldKey = GlobalKey();

  @override
  void initState() {
    super.initState();
    widget.controller.addListener(_onTextChanged);
  }

  @override
  void dispose() {
    widget.controller.removeListener(_onTextChanged);
    _debounceTimer?.cancel();
    _removeOverlay();
    super.dispose();
  }

  void _removeOverlay() {
    _overlayEntry?.remove();
    _overlayEntry = null;
  }

  void _onTextChanged() {
    final query = widget.controller.text.trim();
    if (query.length < 3) {
      setState(() {
        _suggestions = [];
        _isLoading = false;
      });
      _removeOverlay();
      return;
    }

    if (query != _lastQuery) {
      _debounceTimer?.cancel();
      _debounceTimer = Timer(Duration(milliseconds: 500), () {
        _searchMedicines(query);
      });
      _lastQuery = query;
    }
  }

  Future<void> _searchMedicines(String query) async {
    if (query.length < 3) return;

    setState(() {
      _isLoading = true;
    });

    try {
      final results = await ApiService.searchMedicines(query);
      if (mounted) {
        setState(() {
          _suggestions = results;
          _isLoading = false;
        });
        _showOverlay();
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _suggestions = [];
          _isLoading = false;
        });
        _removeOverlay();
      }
    }
  }

  void _showOverlay() {
    _removeOverlay();

    if (_suggestions.isEmpty) return;

    // Use post-frame callback to avoid "Cannot get size during build" error
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;

      _overlayEntry = OverlayEntry(
        builder: (context) => Positioned(
          width: MediaQuery.of(context).size.width - 32,
          child: CompositedTransformFollower(
            link: _layerLink,
            showWhenUnlinked: false,
            offset: Offset(0.0, 45.0),
            child: Material(
              elevation: 4.0,
              borderRadius: BorderRadius.circular(8.0),
              child: Container(
                constraints: BoxConstraints(maxHeight: 200),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(8.0),
                  border: Border.all(color: Colors.grey.withOpacity(0.3)),
                ),
                child: ListView(
                  shrinkWrap: true,
                  children: _suggestions.take(5).map((medicine) {
                    return InkWell(
                      onTap: () => _selectMedicine(medicine),
                      child: Container(
                        padding: EdgeInsets.symmetric(
                            horizontal: 12.0, vertical: 8.0),
                        decoration: BoxDecoration(
                          border: Border(
                            bottom: BorderSide(
                              color: Colors.grey.withOpacity(0.2),
                              width: 0.5,
                            ),
                          ),
                        ),
                        child: Row(
                          children: [
                            Icon(
                              Icons.medication,
                              size: 16,
                              color: Color(0XFF4675C0),
                            ),
                            SizedBox(width: 8),
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    medicine['medicine_name'] ??
                                        medicine['name'] ??
                                        '',
                                    style: TextStyle(
                                      fontSize: 12,
                                      fontWeight: FontWeight.w600,
                                      color: Colors.black87,
                                    ),
                                  ),
                                  if (medicine['route_category'] != null)
                                    Text(
                                      'Route: ${medicine['route_category']}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.orange[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                  if (medicine['generic_name'] != null)
                                    Text(
                                      medicine['generic_name'],
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  if (medicine['strength'] != null)
                                    Text(
                                      '${medicine['strength']} ${medicine['unit'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue[700],
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                ],
                              ),
                            ),
                            Icon(
                              Icons.arrow_forward_ios,
                              size: 12,
                              color: Colors.grey[400],
                            ),
                          ],
                        ),
                      ),
                    );
                  }).toList(),
                ),
              ),
            ),
          ),
        ),
      );

      Overlay.of(context).insert(_overlayEntry!);
    });
  }

  void _selectMedicine(Map<String, dynamic> medicine) {
    // Handle both 'name' and 'medicine_name' fields
    String medicineName = medicine['medicine_name'] ?? medicine['name'] ?? '';
    widget.controller.text = medicineName;

    // Pass the medicine data with route_category
    Map<String, dynamic> medicineData = {
      'name': medicineName,
      'medicine_name': medicineName,
      'route_category': medicine['route_category'],
      'generic_name': medicine['generic_name'],
      'strength': medicine['strength'],
      'unit': medicine['unit'],
      'id': medicine['id'],
    };

    widget.onMedicineSelected(medicineData);
    setState(() {
      _suggestions = [];
    });
    _removeOverlay();
  }

  @override
  Widget build(BuildContext context) {
    return CompositedTransformTarget(
      link: _layerLink,
      child: TextField(
        key: _textFieldKey,
        controller: widget.controller,
        decoration: InputDecoration(
          hintText: widget.hintText,
          border: OutlineInputBorder(borderRadius: BorderRadius.circular(5.0)),
          contentPadding: EdgeInsets.symmetric(horizontal: 8.0, vertical: 4.0),
          suffixIcon: _isLoading
              ? SizedBox(
                  width: 16,
                  height: 16,
                  child: CircularProgressIndicator(strokeWidth: 2),
                )
              : widget.controller.text.isNotEmpty
                  ? IconButton(
                      icon: Icon(Icons.clear, size: 16),
                      onPressed: () {
                        widget.controller.clear();
                        setState(() {
                          _suggestions = [];
                        });
                        _removeOverlay();
                      },
                    )
                  : null,
        ),
        style: TextStyle(fontSize: widget.fontSize),
        onChanged: (value) {
          // Trigger search
        },
      ),
    );
  }
}
