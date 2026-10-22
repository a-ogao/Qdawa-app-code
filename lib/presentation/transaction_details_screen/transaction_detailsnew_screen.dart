import 'dart:async';
import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import '../../widgets/custom_icon_button.dart';
import '../order_list_screen/order_list_screen.dart';
import '../quotation_list_screen/quotationrequest_patient_screen.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../doctor/quotation_list_screen/quotationrequest_patient_screen.dart';

class TransactionDetailsnewScreen extends StatefulWidget {
  final String trid;
  final String transaction_id; // Can't be modified

  const TransactionDetailsnewScreen({
    Key? key,
    required this.trid,
    required this.transaction_id,
  }) : super(key: key);

  @override
  _TransactionDetailsScreenState createState() =>
      _TransactionDetailsScreenState();
}

class _TransactionDetailsScreenState
    extends State<TransactionDetailsnewScreen> {
  Map<String, dynamic>? transactionData;
  bool isLoading = true;
  String paymentStatus = "Initiated";
  Timer? _timer;

  /// UI only; does not change stored status or API behavior.
  String _paymentStatusDisplayLabel(String status) {
    final key = status.trim().toLowerCase();
    if (key == 'initiated' || key == 'inititated') return 'initiated';
    return status.trim();
  }
  String userType = "";
  @override
  void initState() {
    super.initState();
    _startPolling(); // Start polling every minute
  }

  void _startPolling() {
    _timer = Timer.periodic(const Duration(seconds: 10), (timer) {
      checkTransactionStatus();
    });
  }

  void _logPaymentPoll(String message) {
    final ts = DateTime.now().toIso8601String();
    debugPrint('[payment_poll $ts] $message');
  }

  Future<void> checkTransactionStatus() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();

    String? userDataString = prefs.getString('userData');
    if (userDataString != null) {
      final Map<String, dynamic> userData = json.decode(userDataString);
      String userId = userData['id'].toString() ?? '';
      userType = userData['usr_user_type'].toString() ?? '';

      if (userId.isEmpty) {
        setState(() {
          print("User ID not found. Please log in again.");
        });
        return;
      }
    }
    final url = AppConfig.buildApiUrl('place_order');
    final body = {
      "quo_id": widget.trid,
      "transaction_id": widget.transaction_id,
    };
    try {
      _logPaymentPoll('POST $url body=$body');
      final response = await http.post(
        Uri.parse(url),
        body: body,
      );
      _logPaymentPoll(
        'response status=${response.statusCode} body=${response.body}',
      );
      if (response.statusCode == 200) {
        final jsonResponse = json.decode(response.body) as Map<String, dynamic>;

        if (jsonResponse.containsKey("data")) {
          final data = jsonResponse["data"];
          final rawCharge = data is Map<String, dynamic>
              ? data['chargeStatus']
              : null;
          _logPaymentPoll(
            'parsed data.chargeStatus=$rawCharge (app stops polling on success/failed)',
          );
          setState(() {
            transactionData = data is Map<String, dynamic>
                ? Map<String, dynamic>.from(data)
                : null;
            paymentStatus = transactionData?['chargeStatus']?.toString() ??
                "pending";
          });

          if (paymentStatus.toLowerCase() == "successful" ||
              paymentStatus.toLowerCase() == "success") {
            _timer?.cancel(); // Stop polling
            if (!mounted) return;
            Navigator.pushReplacementNamed(
              context,
              '/transaction_details_screen',
              arguments: {
                'trid': widget.trid,
              },
            );
          } else if (paymentStatus.toLowerCase() == "failed") {
            _timer?.cancel(); // Stop polling
            if (!mounted) return;
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(content: Text('Payment Failed. Redirecting...')),
            );
            Future.delayed(Duration(seconds: 2), () {
              if (!mounted) return;
              if (userType == 'healthcare_provider') {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => DQuotationRequestScreen()),
                );
              } else {
                Navigator.pushReplacement(
                  context,
                  MaterialPageRoute(
                      builder: (context) => QuotationRequestScreen()),
                );
              }
            });
          }
        } else {
          final topStatus =
              jsonResponse['status']?.toString().toLowerCase() ?? '';
          if (topStatus == 'success') {
            _logPaymentPoll(
              'top-level status=success (order placed/synced); order_id=${jsonResponse['order_id']} — navigating',
            );
            _timer?.cancel();
            if (!mounted) return;
            setState(() {
              paymentStatus = 'success';
            });
            Navigator.pushReplacementNamed(
              context,
              '/transaction_details_screen',
              arguments: {
                'trid': widget.trid,
              },
            );
          } else {
            _logPaymentPoll(
              'response has no "data" key; keys=${jsonResponse.keys.toList()}',
            );
          }
        }
      } else {
        _logPaymentPoll('non-200, treating as error');
        throw Exception('Failed to load transaction status');
      }
    } catch (e, st) {
      _logPaymentPoll('error: $e');
      if (kDebugMode) {
        _logPaymentPoll('stack: $st');
      }
    }
  }

  @override
  void dispose() {
    _timer?.cancel(); // Clean up timer when screen is disposed
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        backgroundColor: theme.colorScheme.primary,
        title:
            Text("Transaction Status", style: TextStyle(color: Colors.white)),
        centerTitle: true,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              paymentStatus.toLowerCase() == "success"
                  ? Icons.check_circle
                  : Icons.info,
              color: paymentStatus.toLowerCase() == "success"
                  ? Colors.green
                  : Colors.orange,
              size: 80,
            ),
            SizedBox(height: 20),
            Text(
              "Your payment is ${_paymentStatusDisplayLabel(paymentStatus)}",
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
            ),
            SizedBox(height: 10),
            if ({'initiated', 'inititated', 'pending'}
                .contains(paymentStatus.toLowerCase()))
              Text(
                "Please check your phone for payment confirmation.",
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 16),
              ),
            SizedBox(height: 30),
            CircularProgressIndicator(),
          ],
        ),
      ),
    );
  }
}
