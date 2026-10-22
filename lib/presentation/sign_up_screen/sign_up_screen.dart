import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_form_field.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../sign_in_screen/sign_in_screen.dart';
import '../terms_conditions.dart';
import '../user_verification_screen/user_verification_screen.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http_parser/http_parser.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SignUpScreen extends StatefulWidget {
  const SignUpScreen({Key? key}) : super(key: key);

  @override
  _SignUpScreenState createState() => _SignUpScreenState();
}

class _SignUpScreenState extends State<SignUpScreen> {
  TextEditingController firstNameInputController = TextEditingController();
  TextEditingController lastNameInputController = TextEditingController();
  TextEditingController phoneNumberInputController = TextEditingController();
  TextEditingController addressInputController = TextEditingController();
  TextEditingController emailInputController = TextEditingController();
  TextEditingController usernameInputController = TextEditingController();
  TextEditingController passwordInputController = TextEditingController();
  TextEditingController confirmPasswordInputController =
      TextEditingController();

  GlobalKey<FormState> _formKey = GlobalKey<FormState>();

  String? selectedUserType;
  String? selectedHealthcareProfession;
  bool _termsAccepted = false;

  static const Map<String, String> healthcareProfessions = {
    "medical_doctor": "Medical Doctor",
    "nurse": "Nurse",
    "clinical_officer": "Clinical Officer",
    "laboratory_diagnostic": "Laboratory & Diagnostic Professional",
    "dentist": "Dentist",
  };
  PlatformFile? licenseFile;
  PlatformFile? certificateFile;
  PlatformFile? idProofFile;
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;

  final String apiUrl = AppConfig.buildApiUrl('insert_user');

  Future<void> submitSignUpForm(BuildContext context) async {
    if (_formKey.currentState?.validate() ?? false) {
      if (passwordInputController.text != confirmPasswordInputController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Passwords do not match!"),
              backgroundColor: Colors.red),
        );
        return;
      }

      String localNumber = phoneNumberInputController.text.trim();
      String myphone = "254$localNumber";

      try {
        showDialog(
          context: context,
          barrierDismissible: false,
          builder: (BuildContext context) =>
              const Center(child: CircularProgressIndicator()),
        );

        var uri = Uri.parse(apiUrl);
        var request = http.MultipartRequest('POST', uri);

        request.fields.addAll({
          "first_name": firstNameInputController.text.trim(),
          "phone_number": myphone,
          "pha_address": addressInputController.text.trim(),
          "email": emailInputController.text.trim(),
          "username": usernameInputController.text.trim(),
          "password": passwordInputController.text.trim(),
          "user_type": selectedUserType ?? "",
        });

        if (selectedUserType == 'healthcare_provider' &&
            selectedHealthcareProfession != null) {
          request.fields['provider_profession'] = selectedHealthcareProfession!;
        }

        if (licenseFile != null && licenseFile!.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'license',
              licenseFile!.bytes!,
              filename: licenseFile!.name,
              contentType: MediaType('application', 'octet-stream'),
            ),
          );
        }

        if (certificateFile != null && certificateFile!.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'certificate',
              certificateFile!.bytes!,
              filename: certificateFile!.name,
              contentType: MediaType('application', 'octet-stream'),
            ),
          );
        }

        if (idProofFile != null && idProofFile!.bytes != null) {
          request.files.add(
            http.MultipartFile.fromBytes(
              'id_proof',
              idProofFile!.bytes!,
              filename: idProofFile!.name,
              contentType: MediaType('application', 'octet-stream'),
            ),
          );
        }

        var streamedResponse = await request.send();
        var response = await http.Response.fromStream(streamedResponse);
        Navigator.pop(context);

        var responseBody = json.decode(response.body);
        // print(response.body);
        if (response.statusCode == 200) {
          // Check if registration was successful
          if (responseBody['success'] == true || responseBody['status'] == 'success') {
            // Store user data if provided (for OTP verification)
            if (responseBody['data'] != null && responseBody['data']['id'] != null) {
              SharedPreferences prefs = await SharedPreferences.getInstance();
              await prefs.setString('userData', json.encode(responseBody['data']));
            }
            
            // Show success message
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseBody['message'] ?? 'Registration successful! OTP sent to your mobile number.'),
                backgroundColor: Colors.green,
              ),
            );
            
            // Navigate to OTP verification screen
            Navigator.pushReplacement(
              context,
              MaterialPageRoute(builder: (context) => UserVerificationScreen()),
            );
          } else {
            // Registration failed
            ScaffoldMessenger.of(context).showSnackBar(
              SnackBar(
                content: Text(responseBody['message'] ?? 'Registration failed. Please try again.'),
                backgroundColor: Colors.red,
              ),
            );
          }
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

  Future<void> pickFile(Function(PlatformFile?) onFilePicked) async {
    FilePickerResult? result =
        await FilePicker.platform.pickFiles(withData: true);
    if (result != null) {
      onFilePicked(result.files.first);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0XFF4675C0),
        centerTitle: true,
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Text(
          "Register",
          style: TextStyle(
            color: Colors.white,
            fontSize: 20,
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [
              Color(0XFF4675C0).withValues(alpha: 0.05),
              Colors.grey[50]!,
            ],
          ),
        ),
        child: SafeArea(
          child: Form(
            key: _formKey,
            child: SingleChildScrollView(
              child: Padding(
                padding: EdgeInsets.only(
                    bottom: MediaQuery.of(context).viewInsets.bottom),
                child: Column(
                  children: [
                    SizedBox(height: 20.h),
                    _buildEnhancedHeader(),
                    SizedBox(height: 18.h),
                    _buildWelcomeSection(),
                    SizedBox(height: 32.h),
                    _buildFormCard(),
                    SizedBox(height: 26.h),
                    GestureDetector(
                      onTap: () => Navigator.push(
                          context,
                          MaterialPageRoute(
                              builder: (context) => SignInScreen())),
                      child: RichText(
                        text: TextSpan(
                          children: [
                            TextSpan(
                                text: "Already have an account? ",
                                style: theme.textTheme.bodyLarge),
                            TextSpan(
                                text: "Sign In!",
                                style: CustomTextStyles.titleMediumPrimary),
                          ],
                        ),
                      ),
                    ),
                    SizedBox(height: 64.h),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildEnhancedHeader() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          CustomImageView(
            imagePath: ImageConstant.imgRectangle159,
            height: 120.h,
            width: 120.h,
          ),
        ],
      ),
    );
  }

  Widget _buildWelcomeSection() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      child: Column(
        children: [
          Text(
            "Let's Sign up",
            style: TextStyle(
              fontSize: 28,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),
          SizedBox(height: 8),
          Text(
            "Create your account to get started",
            style: TextStyle(
              fontSize: 16,
              color: Colors.grey[600],
            ),
            textAlign: TextAlign.center,
          ),
        ],
      ),
    );
  }

  Widget _buildFormCard() {
    return Container(
      margin: EdgeInsets.symmetric(horizontal: 16),
      padding: EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 20,
            offset: Offset(0, 8),
            spreadRadius: 0,
          ),
        ],
      ),
      child: Column(
        children: [
          _buildFirstNameInput(),
          SizedBox(height: 14.h),
          _buildPhoneNumberInput(),
          SizedBox(height: 14.h),
          _buildAddressInput(),
          SizedBox(height: 14.h),
          _buildEmailInput(),
          SizedBox(height: 14.h),
          _buildUserTypeDropdown(),
          if (selectedUserType == 'healthcare_provider') ...[
            SizedBox(height: 14.h),
            _buildHealthcareProfessionDropdown(),
          ],
          if (selectedUserType == 'pharmacist') ...[
            _buildDocumentUploadField("Upload License", licenseFile, (file) {
              setState(() {
                licenseFile = file;
              });
            }),
            SizedBox(height: 10),
            _buildDocumentUploadField(
                "Upload Company Registration Certificate", certificateFile,
                (file) {
              setState(() {
                certificateFile = file;
              });
            }),
            SizedBox(height: 10),
            _buildDocumentUploadField("Upload National ID", idProofFile,
                (file) {
              setState(() {
                idProofFile = file;
              });
            }),
            SizedBox(height: 20),
          ],
          SizedBox(height: 16.h),
          _buildUsernameInput(),
          SizedBox(height: 16.h),
          _buildPasswordInput(),
          SizedBox(height: 12.h),
          _buildConfirmPasswordInput(),
          SizedBox(height: 22.h),
          _buildTermsAndConditionsCheckbox(),
          SizedBox(height: 5.h),
          _buildSignUpButton(),
        ],
      ),
    );
  }

  Widget _buildTopHeader() {
    return Container(
      width: double.maxFinite,
      padding: EdgeInsets.symmetric(vertical: 18.h),
      decoration: AppDecoration.fillPrimary,
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Text("Register", style: CustomTextStyles.titleMediumWhiteA700Bold),
      ]),
    );
  }

  Widget _buildDocumentUploadField(
      String label, PlatformFile? file, Function(PlatformFile?) onFilePicked) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: TextStyle(fontWeight: FontWeight.bold)),
          SizedBox(height: 6),
          GestureDetector(
            onTap: () => pickFile(onFilePicked),
            child: Container(
              padding: EdgeInsets.all(14),
              decoration: BoxDecoration(
                border: Border.all(color: Colors.grey.shade400),
                borderRadius: BorderRadius.circular(10),
              ),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(file?.name ?? "No file selected",
                      style: TextStyle(color: Colors.black)),
                  Icon(Icons.upload_file, color: Colors.grey),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInputField(
    TextEditingController controller,
    String hintText, [
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
    String? prefixText, // Add optional prefix text
  ]) {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        validator: validator,
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: hintText,
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.blue.shade300),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          prefixText: prefixText, // Display the prefix text (+254)
          prefixStyle:
              TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
        ),
        onChanged: (value) {
          // Ensure country code remains fixed
          if (prefixText != null && !value.startsWith(prefixText)) {
            controller.text =
                prefixText + value.replaceAll(prefixText, "").trim();
            controller.selection = TextSelection.fromPosition(
              TextPosition(offset: controller.text.length),
            );
          }
        },
      ),
    );
  }

  Widget _buildLastNameInput() {
    return _buildInputField(lastNameInputController, "Last Name");
  }

  Widget _buildAddressInput() {
    return _buildInputField(addressInputController, "Address");
  }

  Widget _buildUsernameInput() {
    return _buildInputField(usernameInputController, "Username");
  }

  Widget _buildFirstNameInput() {
    return _buildInputField(
        firstNameInputController,
        "Name",
        TextInputType.text,
        (value) => value!.isEmpty ? "Name is required" : null);
  }

  Widget _buildPhoneNumberInput() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: TextFormField(
        controller: phoneNumberInputController,
        keyboardType: TextInputType.phone,
        textInputAction: TextInputAction.next,
        validator: (value) {
          if (value == null || value.isEmpty || value.length < 9) {
            return "Enter a valid phone number";
          }
          return null;
        },
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: "Phone Number",
          hintStyle: TextStyle(color: Colors.grey),
          prefixText: '+254 ',
          prefixStyle:
              TextStyle(color: Colors.black, fontWeight: FontWeight.bold),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.blue.shade300),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        ),
      ),
    );
  }

  Widget _buildEmailInput() {
    return _buildInputField(
        emailInputController,
        "Email",
        TextInputType.emailAddress,
        (value) => value!.isEmpty ||
                !RegExp(r'^[a-zA-Z0-9._%+-]+@[a-zA-Z0-9.-]+\.[a-zA-Z]{2,4}$')
                    .hasMatch(value)
            ? "Enter a valid email"
            : null);
  }

  Widget _buildPasswordInput() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: TextFormField(
        controller: passwordInputController,
        keyboardType: TextInputType.visiblePassword,
        obscureText: _obscurePassword,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Password is required";
          }
          if (value.length < 8) {
            return "Password must be at least 8 characters";
          }
          if (!RegExp(r'^(?=.*[!@#$%^&*(),.?":{}|<>])').hasMatch(value)) {
            return "Password must contain at least one special character";
          }
          if (!RegExp(r'^(?=.*\d)').hasMatch(value)) {
            return "Password must contain at least one number";
          }
          return null;
        },
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: "Password",
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.blue.shade300),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: IconButton(
            icon: Icon(
              _obscurePassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _obscurePassword = !_obscurePassword;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildConfirmPasswordInput() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: TextFormField(
        controller: confirmPasswordInputController,
        keyboardType: TextInputType.visiblePassword,
        obscureText: _obscureConfirmPassword,
        validator: (value) {
          if (value == null || value.isEmpty) {
            return "Confirm Password is required";
          }
          if (value != passwordInputController.text) {
            return "Passwords do not match";
          }
          return null;
        },
        style: TextStyle(color: Colors.black),
        decoration: InputDecoration(
          hintText: "Confirm Password",
          hintStyle: TextStyle(color: Colors.grey),
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.grey.shade300),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12.0),
            borderSide: BorderSide(color: Colors.blue.shade300),
          ),
          contentPadding: EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          suffixIcon: IconButton(
            icon: Icon(
              _obscureConfirmPassword ? Icons.visibility_off : Icons.visibility,
              color: Colors.grey[600],
            ),
            onPressed: () {
              setState(() {
                _obscureConfirmPassword = !_obscureConfirmPassword;
              });
            },
          ),
        ),
      ),
    );
  }

  Widget _buildTermsAndConditionsCheckbox() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18),
      child: Row(
        children: [
          Checkbox(
            value: _termsAccepted,
            onChanged: (bool? value) {
              setState(() {
                _termsAccepted = value ?? false;
              });
            },
          ),
          Expanded(
            child: GestureDetector(
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                      builder: (context) => TermsConditionsScreen()),
                );
              },
              child: RichText(
                text: TextSpan(
                  text: "I accept the ",
                  style: TextStyle(
                      color: Colors.black, fontSize: 16), // Default text style
                  children: [
                    TextSpan(
                      text: "Terms and Conditions",
                      style: CustomTextStyles
                          .titleMediumPrimary, // Apply custom style
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildUserTypeDropdown() {
    Map<String, String> userTypes = {
      "patient": "Patient",
      "pharmacist": "Pharmacist",
      "rider": "Rider",
      "healthcare_provider": "Healthcare Provider",
    };

    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.h),
      child: DropdownButtonFormField<String>(
        value: selectedUserType,
        decoration: InputDecoration(
          hintText: "Select User Type",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18.0), // Rounded edges
            borderSide: BorderSide(
                color: const Color.fromARGB(
                    255, 233, 233, 233)), // Light border color
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide:
                BorderSide(color: const Color.fromARGB(255, 235, 235, 235)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: BorderSide(
                color: Colors.blue.shade300), // Light blue when focused
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.h, vertical: 14.h),
        ),
        hint: Text("Select User Type"),
        items: userTypes.entries
            .map((entry) => DropdownMenuItem(
                  value: entry.key, // Post this value
                  child: Text(entry.value), // Show this name
                ))
            .toList(),
        validator: (value) => value == null ? "User type is required" : null,
        onChanged: (newValue) => setState(() {
          selectedUserType = newValue;
          if (newValue != 'healthcare_provider') {
            selectedHealthcareProfession = null;
          }
        }),
      ),
    );
  }

  Widget _buildHealthcareProfessionDropdown() {
    return Padding(
      padding: EdgeInsets.symmetric(horizontal: 18.h),
      child: DropdownButtonFormField<String>(
        value: selectedHealthcareProfession,
        decoration: InputDecoration(
          hintText: "Select Profession",
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(18.0),
            borderSide: BorderSide(
                color: const Color.fromARGB(255, 233, 233, 233)),
          ),
          enabledBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide:
                BorderSide(color: const Color.fromARGB(255, 235, 235, 235)),
          ),
          focusedBorder: OutlineInputBorder(
            borderRadius: BorderRadius.circular(20.0),
            borderSide: BorderSide(color: Colors.blue.shade300),
          ),
          contentPadding:
              EdgeInsets.symmetric(horizontal: 16.h, vertical: 14.h),
        ),
        hint: Text("Select Profession"),
        items: healthcareProfessions.entries
            .map((entry) => DropdownMenuItem(
                  value: entry.key,
                  child: Text(entry.value),
                ))
            .toList(),
        validator: (value) {
          if (selectedUserType == 'healthcare_provider' && value == null) {
            return "Profession is required";
          }
          return null;
        },
        onChanged: (newValue) =>
            setState(() => selectedHealthcareProfession = newValue),
      ),
    );
  }

  Widget _buildSignUpButton() {
    return CustomElevatedButton(
      height: 50.h,
      text: "Sign up",
      margin: EdgeInsets.symmetric(horizontal: 18.h),
      buttonStyle: CustomButtonStyles.fillPrimary,
      onPressed: () {
        if (!_termsAccepted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("You must accept the Terms and Conditions"),
              backgroundColor: Colors.red,
            ),
          );
          return;
        }
        submitSignUpForm(context);
      },
    );
  }
}
