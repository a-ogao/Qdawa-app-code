import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../../core/app_export.dart';
import '../../../core/config/app_config.dart';
import '../order_list_screen/order_list_screen.dart';
import '../../delivery/delivered_orders/delivered_order_list_screen.dart';
import 'dart:convert';

class OtpInputScreen extends StatefulWidget {
  final int orderidd;
  final String ordertypee;

  OtpInputScreen({
    required this.orderidd,
    required this.ordertypee,
  });

  @override
  _OtpInputScreenState createState() => _OtpInputScreenState();
}

class _OtpInputScreenState extends State<OtpInputScreen> {
  final TextEditingController otpController = TextEditingController();
  bool _isResending = false;

  @override
  Widget build(BuildContext context) {
    String lastFourDigits = "1855";
    String mOtpview = "";
    String MOtphead = "";

    if (widget.ordertypee == 'delivery_person') {
      String lastFourDigits = '1855'; // Placeholder
      mOtpview = "Enter OTP shared by the rider. OTP sent to (+xxx) xxx xx";
      MOtphead = "🚚 Confirm Delivery";
    } else {
      String lastFourDigits = '1855'; // Placeholder
      mOtpview =
          "Enter OTP provided by the pharmacy staff. OTP sent to (+xxx) xxx xx";
      MOtphead = "🚚 Pickup Verification";
    }

    return Scaffold(
      resizeToAvoidBottomInset: true,
      backgroundColor: appTheme.whiteA700,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: EdgeInsets.only(
                bottom: MediaQuery.of(context)
                    .viewInsets
                    .bottom, // push above keyboard
              ),
              child: ConstrainedBox(
                constraints: BoxConstraints(minHeight: constraints.maxHeight),
                child: IntrinsicHeight(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      _buildTopHeader(),
                      Expanded(
                        child: Padding(
                          padding: EdgeInsets.symmetric(horizontal: 20),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.center,
                            children: [
                              SizedBox(height: 40),
                              CustomImageView(
                                imagePath: ImageConstant.imgRectangle159,
                                height: 178,
                                width: 194,
                              ),
                              SizedBox(height: 30),
                              Text(
                                MOtphead,
                                style: CustomTextStyles.headlineSmallSemiBold,
                              ),
                              SizedBox(height: 20),
                              Text(
                                '$mOtpview $lastFourDigits',
                                maxLines: 3,
                                overflow: TextOverflow.ellipsis,
                                textAlign: TextAlign.center,
                                style: Theme.of(context)
                                    .textTheme
                                    .bodyLarge!
                                    .copyWith(
                                      height: 1.75,
                                    ),
                              ),
                              SizedBox(height: 20),
                              _buildOtpFields(),
                              SizedBox(height: 24),
                              _buildResendOtpButton(),
                              SizedBox(height: 24),
                              _buildSubmitButton(),
                            ],
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  Widget _buildResendOtpButton() {
    return TextButton(
      onPressed: _isResending ? null : _resendOTP,
      child: _isResending
          ? CircularProgressIndicator()
          : Text("Resend OTP", style: TextStyle(color: Colors.blue)),
    );
  }

  Future<void> _resendOTP() async {
    setState(() {
      _isResending = true;
    });

    try {
      final response = await http.post(
          Uri.parse(AppConfig.buildApiUrl('orderresend_otp')),
          body: {
            'order_id': widget.orderidd.toString(),
            'order_type': widget.ordertypee.toString(),
          });

      setState(() {
        _isResending = false;
      });
      // print(response.body);
      if (response.statusCode == 200) {
        _showMessage("OTP resent successfully!", Colors.green);
      } else {
        _showMessage("Failed to resend OTP.", Colors.red);
      }
    } catch (e) {
      setState(() {
        _isResending = false;
      });
      _showMessage("Error resending OTP: $e", Colors.red);
    }
  }

  void _showMessage(String message, Color color) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: color),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      color: theme.colorScheme.primary,
      height: 60,
      child: Row(
        children: [
          IconButton(
            icon: Icon(Icons.arrow_back, color: Colors.white),
            onPressed: () => Navigator.pop(context),
          ),
          Text(
            "Enter Otp",
            style: TextStyle(color: Colors.white, fontSize: 18),
          ),
        ],
      ),
    );
  }

  List<TextEditingController> otpControllers =
      List.generate(6, (index) => TextEditingController());

  Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 40,
          height: 50,
          child: TextField(
            controller: otpControllers[index], // Assign controller
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              counterText: "",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                FocusScope.of(context).nextFocus();
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).previousFocus();
              }
            },
          ),
        );
      }),
    );
  }

  /* Widget _buildOtpFields() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: List.generate(6, (index) {
        return SizedBox(
          width: 40,
          height: 50,
          child: TextField(
            textAlign: TextAlign.center,
            keyboardType: TextInputType.number,
            maxLength: 1,
            style: TextStyle(
              fontSize: 18.0,
              fontWeight: FontWeight.bold,
            ),
            decoration: InputDecoration(
              counterText: "",
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(8.0),
              ),
            ),
            controller: otpController,
            onChanged: (value) {
              if (value.isNotEmpty && index < 5) {
                FocusScope.of(context).nextFocus();
              } else if (value.isEmpty && index > 0) {
                FocusScope.of(context).previousFocus();
              }
            },
          ),
        );
      }),
    );
  }*/

  Future<bool> _verifyOTP(String otp) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('verify_statusotp')),
        body: {
          'order_id': widget.orderidd.toString(),
          'otp': otp,
        },
      );
      //print(response.body);
      if (response.statusCode == 200) {
        final responseData = json.decode(response.body);
        return true;
        //return responseData['dstatus'] == "SUCCESS";
      } else {
        return false;
      }
    } catch (e) {
      _showError("Error verifying OTP: $e");
      return false;
    }
  }

  Widget _buildSubmitButton() {
    return ElevatedButton(
      onPressed: () async {
        String otp = otpControllers.map((controller) => controller.text).join();
        print(otp);
        if (otp.isEmpty || otp.length != 6) {
          _showError("Please enter a valid 6-digit OTP.");
          return;
        }

        bool isOtpValid = await _verifyOTP(otp); // Call OTP verification
        print(isOtpValid);
        if (isOtpValid) {
          if (widget.ordertypee == 'pickup') {
            _updateOrderStatus('pickedup');
          } else if (widget.ordertypee == 'delivery') {
            _updateOrderStatus('dispatched');
          } else if (widget.ordertypee == 'delivery_person') {
            _updatedeliveryStatus('delivered');
          }
        } else {
          _showError("Invalid OTP. Please try again.");
        }
      },
      style: ElevatedButton.styleFrom(
        minimumSize: Size(double.infinity, 50.0),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(8.0),
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
      ),
      child: Text(
        "Verify",
        style: TextStyle(
          fontSize: 16.0,
          fontWeight: FontWeight.bold,
          color: Colors.white,
        ),
      ),
    );
  }

  Future<void> _updatedeliveryStatus(String status) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('delivery_dstatus')),
        body: {
          'order_id': widget.orderidd.toString(),
          'del_delivery_status': status.toString(),
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Order Delivered successfully!"),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => DeliveredOrdersItem()),
          );
        }
      } else {
        _showError("Failed to update order status.");
      }
    } catch (e) {
      _showError("Error updating order status: $e");
    }
  }

  Future<void> _updateOrderStatus(String status) async {
    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('update_ostatus')),
        body: {
          'order_id': widget.orderidd.toString(),
          'ord_order_status': status.toString(),
        },
      );

      if (response.statusCode == 200) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Order Picked up successfully!"),
              backgroundColor: Colors.green,
            ),
          );

          Navigator.pushReplacement(
            context,
            MaterialPageRoute(builder: (context) => PharmacyOrderListScreen()),
          );
        }
      } else {
        _showError("Failed to update order status.");
      }
    } catch (e) {
      _showError("Error updating order status: $e");
    }
  }

  void _showError(String message) {
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor: Colors.red,
        ),
      );
    }
  }
}
