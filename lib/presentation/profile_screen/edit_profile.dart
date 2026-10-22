import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_form_field.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../profile_screen/profile_screen.dart';

class EditProfileScreen extends StatefulWidget {
  const EditProfileScreen({Key? key}) : super(key: key);

  @override
  _EditProfileScreenState createState() => _EditProfileScreenState();
}

class _EditProfileScreenState extends State<EditProfileScreen> {
  TextEditingController firstNameController = TextEditingController();
  TextEditingController lastNameController = TextEditingController();
  TextEditingController phoneNumberController = TextEditingController();
  TextEditingController addressController = TextEditingController();
  TextEditingController usernameController = TextEditingController();

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();
  String? userType; // Store user type

  String? selectedUserType;
  final String apiUrl = AppConfig.buildApiUrl('update_user');

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('userData');

    if (userDataString == null) {
      throw Exception("User data is missing.");
    }

    final Map<String, dynamic> userData = json.decode(userDataString);
    final int? userId = userData['id'];

    if (userId == null) {
      throw Exception("User ID is missing.");
    }
    try {
      var response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('get_user')),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {"usr_id": userId.toString()}, // Pass user ID to fetch data
      );

      if (response.statusCode == 200) {
        var responseData = json.decode(response.body);
        List<dynamic> users = responseData['data'] ?? [];
        if (users.isEmpty) {
          throw Exception("No user data found");
        }
        Map<String, dynamic> userData =
            users.first; // Get first user from the list
        setState(() {
          firstNameController.text =
              userData["usr_first_name"]?.toString() ?? "";
          lastNameController.text = userData["usr_email"]?.toString() ?? "";
          phoneNumberController.text =
              userData["usr_mobile_number"]?.toString() ?? "";
          addressController.text = userData["pha_address"]?.toString() ?? "";
          usernameController.text = userData["usr_username"]?.toString() ?? "";
          userType = userData["usr_user_type"]?.toString(); // Store user type
        });
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to load user data"),
              backgroundColor: Colors.red),
        );
      }
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content: Text("Error fetching user data: $e"),
            backgroundColor: Colors.red),
      );
    }
  }

  Future<void> submitEditProfileForm(BuildContext context) async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('userData');

    if (userDataString == null) {
      throw Exception("User data is missing.");
    }

    final Map<String, dynamic> userData = json.decode(userDataString);
    final int? userId = userData['id'];

    if (userId == null) {
      throw Exception("User ID is missing.");
    }
    if (_formKey.currentState?.validate() ?? false) {
      Map<String, dynamic> formData = {
        "first_name": firstNameController.text.trim(),
        "email": lastNameController.text.trim(),
        "phone_number": phoneNumberController.text.trim(),
        "pha_address": addressController.text.trim(),
        "username": usernameController.text.trim(),
        'usr_id': userId.toString(),
      };

      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) =>
              const Center(child: CircularProgressIndicator()),
        );

        var response = await http.post(
          Uri.parse(apiUrl),
          headers: {'Content-Type': 'application/x-www-form-urlencoded'},
          body: formData,
        );

        Navigator.pop(context);

        var responseBody = json.decode(response.body);

        if (response.statusCode == 200) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(responseBody['message']),
                backgroundColor: Colors.green),
          );
          Navigator.pushReplacement(
            context,
            MaterialPageRoute(
                builder: (context) => ProfileScreen()), // Replace this
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text(responseBody['message']),
                backgroundColor: Colors.red),
          );
        }
      } catch (e) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text('An error occurred: $e'),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ), // Ensures back button is shown
        title: Text(
          "Edit Profile",
          style: TextStyle(color: Colors.white), // White title
        ),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Colors.white), // White back arrow
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            padding: EdgeInsets.all(16.0),
            child: Column(
              children: [
                _buildInputField(firstNameController, "First Name"),
                SizedBox(height: 14.h),
                _buildInputField(lastNameController, "Email"),
                SizedBox(height: 14.h),
                _buildInputField(
                    phoneNumberController, "Phone Number", TextInputType.phone),
                SizedBox(height: 14.h),
                if (userType ==
                    "pharmacist") // Show only if user type is pharmacist

                  _buildInputField(addressController, "Address"),
                SizedBox(height: 14.h),
                _buildInputField(usernameController, "Username"),
                SizedBox(height: 22.h),
                _buildSaveButton(),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInputField(TextEditingController controller, String hintText,
      [TextInputType keyboardType = TextInputType.text]) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      style: TextStyle(color: Colors.black),
      decoration: InputDecoration(
        hintText: hintText,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12.0),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        contentPadding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 14.h),
      ),
    );
  }

  Widget _buildSaveButton() {
    return CustomElevatedButton(
      height: 50.h,
      text: "Save Changes",
      buttonStyle: CustomButtonStyles.fillPrimary,
      onPressed: () => submitEditProfileForm(context),
    );
  }
}
