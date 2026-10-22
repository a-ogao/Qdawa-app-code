import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../core/config/app_config.dart';
import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/app_export.dart';
import '../../core/utils/patient_api_context.dart';
import '../../core/services/biometric_auth_service.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_image_view.dart';

class PaymentOptionsScreen extends StatefulWidget {
  final String qid;
  final double payableAmount;
  final String? couponCode;
  final double? originalAmount;
  final double? discountAmount;

  const PaymentOptionsScreen({
    Key? key,
    required this.qid,
    required this.payableAmount,
    this.couponCode,
    this.originalAmount,
    this.discountAmount,
  }) : super(key: key);

  @override
  _PaymentOptionsScreenState createState() => _PaymentOptionsScreenState();
}

class _PaymentOptionsScreenState extends State<PaymentOptionsScreen> {
  List<Map<String, dynamic>> paymentOptions = [
    {"id": 2, "name": "M-Pesa", "icon": Icons.account_balance_wallet, "enabled": true},
  ];

  String? selectedPaymentMethod;
  bool isLoading = false;

  void _togglePaymentSelection(String methodName) {
    setState(() {
      selectedPaymentMethod = methodName;
    });
  }

  Future<void> _placeOrder(String qid, String paymentMethod) async {
    final authenticated = await BiometricAuthService.authenticateIfEnabled(
      reason: 'Verify your identity to complete payment',
    );
    if (!authenticated) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Biometric authentication required to process payment.'),
        ),
      );
      return;
    }

    try {
      setState(() {
        isLoading = true;
      });

      final apiCtx = await PatientApiContext.body();
      final body = <String, String>{
        "quo_id": qid,
        "payment_method": paymentMethod,
      };
      if (apiCtx.containsKey('actor_usr_id')) {
        body['actor_usr_id'] = apiCtx['actor_usr_id']!;
      }
      if (widget.couponCode != null && widget.couponCode!.isNotEmpty) {
        body["coupon_code"] = widget.couponCode!;
      }

      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('pay_orderpayment')),
        headers: {"Content-Type": "application/json"},
        body: jsonEncode(body),
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);

        if (responseData['success'] == false) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(responseData['message'] ??
                    'Failed to place the order. Please try again.')),
          );
          return;
        }

        if (responseData.containsKey("data") &&
            responseData["data"].containsKey("transactionId")) {
          String transactionId = responseData["data"]["transactionId"];
          Navigator.pushNamed(
            context,
            '/transaction_detailsnew_screen',
            arguments: {
              'trid': qid,
              'transaction_id': transactionId,
            },
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text('Transaction ID not found in response.')),
          );
        }
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text('Failed to place the order. Please try again.')),
        );
      }
    } catch (error) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Error: $error')),
      );
    } finally {
      setState(() {
        isLoading = false;
      });
    }
  }

  Widget _buildPayableSummary() {
    final hasDiscount = widget.discountAmount != null && widget.discountAmount! > 0;

    return Card(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 8),
      color: const Color(0XFF4675C0).withOpacity(0.08),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            if (hasDiscount && widget.originalAmount != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text('Subtotal'),
                  Text('KES ${widget.originalAmount!.toStringAsFixed(2)}'),
                ],
              ),
              const SizedBox(height: 6),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Coupon (${widget.couponCode ?? ''})',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                  Text(
                    '- KES ${widget.discountAmount!.toStringAsFixed(2)}',
                    style: TextStyle(color: Colors.green.shade700),
                  ),
                ],
              ),
              const Divider(height: 20),
            ],
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Payable',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                Text(
                  'KES ${widget.payableAmount.toStringAsFixed(2)}',
                  style: const TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                    color: Color(0XFF4675C0),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        backgroundColor: AppDecoration.fillPrimary.color,
        title: const Text(
          "Checkout",
          style: TextStyle(color: Colors.white),
        ),
        centerTitle: true,
        elevation: 0,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () {
            Navigator.pop(context);
          },
        ),
      ),
      body: Column(
        children: [
          _buildPayableSummary(),
          Expanded(
            child: ListView.builder(
              itemCount: paymentOptions.length,
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
              itemBuilder: (context, index) {
                final option = paymentOptions[index];
                final enabled = option["enabled"] == true;
                final isSelected =
                    enabled && selectedPaymentMethod == option["name"];

                return Card(
                  margin: const EdgeInsets.only(bottom: 12),
                  elevation: enabled ? 2 : 0,
                  color: enabled
                      ? (isSelected ? Colors.blue[100] : Colors.white)
                      : Colors.grey.shade200,
                  child: ListTile(
                    enabled: enabled,
                    onTap: enabled
                        ? () => _togglePaymentSelection(option["name"] as String)
                        : null,
                    leading: Icon(
                      option["icon"] as IconData,
                      size: 30,
                      color: enabled ? Colors.blue : null,
                    ),
                    title: Text(
                      option["name"] as String,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    trailing: Icon(
                      isSelected ? Icons.check_circle : Icons.circle_outlined,
                      color: isSelected ? Colors.blue : Colors.grey,
                    ),
                  ),
                );
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Padding(
        padding: EdgeInsets.only(
          top: 16.0,
          bottom: 16.0 + MediaQuery.of(context).viewPadding.bottom,
        ),
        child: CustomElevatedButton(
          text: isLoading
              ? "Processing..."
              : "Pay KES ${widget.payableAmount.toStringAsFixed(2)}",
          margin: const EdgeInsets.symmetric(horizontal: 16),
          rightIcon: Container(
            margin: const EdgeInsets.only(left: 2),
            child: CustomImageView(
              imagePath: ImageConstant.imgArrowrightGray5003,
              height: 24,
              width: 24,
              fit: BoxFit.contain,
            ),
          ),
          onPressed: selectedPaymentMethod == null || isLoading
              ? null
              : () {
                  if (selectedPaymentMethod == "M-Pesa") {
                    _placeOrder(widget.qid, selectedPaymentMethod!);
                  }
                },
        ),
      ),
    );
  }
}
