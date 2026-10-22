import 'package:flutter/material.dart';
import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/services/biometric_auth_service.dart';
import '../../presentation/patient_access/patient_access_settings_screen.dart';

class ProfileScreen extends StatefulWidget {
  @override
  _ProfileScreenState createState() => _ProfileScreenState();
}

class _ProfileScreenState extends State<ProfileScreen> {
  String? userId;
  String? username;
  String? userType;
  bool isLoading = false;
  bool _biometricAvailable = false;
  bool _biometricEnabled = false;
  bool _biometricUpdating = false;

  Map<String, dynamic> counters = {"notification": 0}; // Default counter

  @override
  void initState() {
    super.initState();
    _fetchUserData();
    _loadBiometricState();
  }

  Future<void> _loadBiometricState() async {
    final available = await BiometricAuthService.canCheckBiometrics();
    final enabled = await BiometricAuthService.isBiometricEnabled();
    if (!mounted) return;
    setState(() {
      _biometricAvailable = available;
      _biometricEnabled = enabled;
    });
  }

  Future<void> _toggleBiometric(bool value) async {
    if (_biometricUpdating) return;

    setState(() => _biometricUpdating = true);

    bool success;
    if (value) {
      success = await BiometricAuthService.enableBiometric();
    } else {
      success = await BiometricAuthService.disableBiometric();
    }

    if (!mounted) return;

    if (success) {
      setState(() {
        _biometricEnabled = value;
        _biometricUpdating = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Biometric authentication enabled.'
                : 'Biometric authentication disabled.',
          ),
        ),
      );
    } else {
      setState(() => _biometricUpdating = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            value
                ? 'Could not enable biometric authentication. Ensure biometrics are set up on your device.'
                : 'Biometric verification failed. Setting remains unchanged.',
          ),
        ),
      );
    }
  }

  Future<void> _fetchUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('userData');

    if (userDataString == null) {
      print("User data is missing.");
      return;
    }

    final Map<String, dynamic> userData = json.decode(userDataString);

    setState(() {
      userId = userData['id'].toString();
      username = userData['usr_first_name'] ?? userData['usr_username'];
      userType = userData['usr_user_type'] ?? "User";
    });
  }

  bool _isReportCodeEligible() {
    const eligible = ['patient', 'pharmacist', 'healthcare_provider'];
    return eligible.contains(userType);
  }

  Future<void> _confirmDeleteProfile() async {
    return showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Confirm Deletion"),
          content: Text("Are you sure you want to delete your profile?"),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(), // Close dialog
              child: Text("Cancel"),
            ),
            TextButton(
              onPressed: () {
                Navigator.of(context).pop(); // Close dialog
                _deleteProfile();
              },
              child: Text("Delete", style: TextStyle(color: Colors.red)),
            ),
          ],
        );
      },
    );
  }

  Future<void> _deleteProfile() async {
    String apiUrl = ""; // Define apiUrl at function scope
    print(userType);

    if (userId == null) {
      print("User ID is missing.");
      return;
    }
    setState(() {
      isLoading = true; // Start loading
    });

    // Show a loading dialog
    showDialog(
      context: context,
      barrierDismissible: false, // Prevent closing manually
      builder: (BuildContext context) {
        return AlertDialog(
          content: Row(
            children: [
              CircularProgressIndicator(),
              SizedBox(width: 20),
              Text("Deleting..."),
            ],
          ),
        );
      },
    );
    try {
      if (userType == "pharmacist") {
        // print('enter');
        apiUrl = AppConfig.buildApiUrl('delete_pharmacist');
      } else {
        //  print('in');
        apiUrl = AppConfig.buildApiUrl('delete_user');
      }

      // print("Final API URL: $apiUrl");

      final response = await http.post(
        Uri.parse(apiUrl),
        body: {'usr_id': userId.toString()},
      );
      //print(response.body);
      Navigator.of(context).pop(); // Close the loading dialog

      if (response.statusCode == 200) {
        final SharedPreferences prefs = await SharedPreferences.getInstance();
        await BiometricAuthService.clearSessionPreservingPreferences();

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Profile deleted successfully.")),
        );

        // Navigate to the login screen or home page
        Navigator.pushReplacementNamed(context, '/sign_in_screen');
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Failed to delete profile. Please try again.")),
        );
      }
    } catch (e) {
      print("Error deleting profile: $e");
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("An error occurred. Please try again later.")),
      );
    } finally {
      setState(() {
        isLoading = false; // Stop loading
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        backgroundColor: Color(0XFF4675C0),
        automaticallyImplyLeading: false,
        elevation: 0,
        title: Row(
          children: [
            IconButton(
              icon: Icon(Icons.arrow_back, color: Colors.white),
              onPressed: () => Navigator.pop(context),
              padding: EdgeInsets.zero,
              constraints: BoxConstraints(),
            ),
            SizedBox(width: 8),
            Text(
              'Profile',
              style: TextStyle(
                color: Colors.white,
                fontSize: 20,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
        actions: [
          Stack(
            clipBehavior: Clip.none,
            children: [
              GestureDetector(
                onTap: () {
                  if (counters["notification"]?.toString() != "0" &&
                      counters["notification"]?.toString().isNotEmpty == true) {
                    Navigator.pushNamed(
                      context,
                      '/pharmacy_notification',
                    );
                  }
                },
                child: Container(
                  margin: EdgeInsets.only(right: 8.0),
                  height: 36.0,
                  width: 36.0,
                  decoration: BoxDecoration(
                    color: Colors.white.withValues(alpha: 0.2),
                    shape: BoxShape.circle,
                  ),
                  child: Icon(
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
                        padding: EdgeInsets.all(4.0),
                        decoration: BoxDecoration(
                          color: Colors.red,
                          shape: BoxShape.circle,
                          border: Border.all(color: Colors.white, width: 1.5),
                        ),
                        constraints: BoxConstraints(
                          minWidth: 18,
                          minHeight: 18,
                        ),
                        child: Text(
                          counters["notification"].toString(),
                          style: TextStyle(
                            color: Colors.white,
                            fontSize: 12.0,
                            fontWeight: FontWeight.bold,
                          ),
                          textAlign: TextAlign.center,
                        ),
                      ),
                    )
                  : SizedBox.shrink(),
            ],
          ),
        ],
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
        child: SingleChildScrollView(
          child: Column(
            children: [
              SizedBox(height: 32),
              _buildEnhancedProfileHeader(),
              SizedBox(height: 32),
              // Account Section (Full Width)
              buildFullWidthCard(context, 'Account Details', [
                buildListTile(
                    Icons.person, 'Edit Profile', context, '/edit_profile'),
                if (userType == 'patient')
                  buildListTile(
                    Icons.supervisor_account,
                    'Patient Access',
                    context,
                    '',
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => const PatientAccessSettingsScreen(),
                        ),
                      );
                    },
                  ),
                buildListTile(Icons.phone, 'Change Phone Number', context,
                    '/change_phoneno'),
                buildListTile(Icons.email, 'Change Email Address', context,
                    '/change_email'),
                if (_isReportCodeEligible())
                  buildListTile(Icons.lock_outline, 'Send / Resend Report Code',
                      context, '/report_code_screen'),
                /* buildListTile(
                  Icons.lock, 'Change Password', context, '/change_password'),*/
                buildListTile(
                  Icons.delete,
                  'Delete Profile/Account',
                  context,
                  '', // Keep route empty
                  onTap: _confirmDeleteProfile, // Call function directly
                ),
              ]),
              if (_biometricAvailable)
                buildFullWidthCard(context, 'Security', [
                  _buildBiometricToggle(),
                ]),
            ],
          ),
        ),
      ),
    );
  }

  Widget buildFullWidthCard(
      BuildContext context, String title, List<Widget> children) {
    return Container(
      width: MediaQuery.of(context).size.width, // Make it full width
      margin: EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            blurRadius: 16,
            offset: Offset(0, 4),
            spreadRadius: 0,
          ),
        ],
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Card Header
          Container(
            padding: EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: Color(0XFF4675C0),
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            width: double.infinity,
            alignment: Alignment.center,
            child: Text(
              title,
              style: TextStyle(
                color: Colors.white,
                fontWeight: FontWeight.bold,
                fontSize: 18,
              ),
              textAlign: TextAlign.center,
            ),
          ),
          // Card Content
          Padding(
            padding: EdgeInsets.symmetric(horizontal: 10),
            child: Column(children: children),
          ),
        ],
      ),
    );
  }

  Widget _buildEnhancedProfileHeader() {
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
          // Profile Avatar
          Container(
            padding: EdgeInsets.all(4),
            decoration: BoxDecoration(
              color: Color(0XFF4675C0).withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: CircleAvatar(
              radius: 40,
              backgroundColor: Color(0XFF4675C0).withValues(alpha: 0.1),
              child: Icon(
                Icons.person,
                size: 40,
                color: Color(0XFF4675C0),
              ),
            ),
          ),

          SizedBox(height: 16),

          // User Name
          Text(
            username ?? "Loading...",
            style: TextStyle(
              fontSize: 24,
              fontWeight: FontWeight.bold,
              color: Colors.black87,
            ),
          ),

          SizedBox(height: 8),

          // User Type Badge
          Container(
            padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
            decoration: BoxDecoration(
              color: Color(0XFF4675C0).withValues(alpha: 0.1),
              borderRadius: BorderRadius.circular(20),
            ),
            child: Text(
              userType?.toUpperCase() ?? "USER",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: Color(0XFF4675C0),
                letterSpacing: 1.2,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildBiometricToggle() {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: SwitchListTile(
        secondary: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0XFF4675C0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(Icons.fingerprint, color: Color(0XFF4675C0), size: 20),
        ),
        title: Text(
          'Biometric Authentication',
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        subtitle: Text(
          _biometricEnabled
              ? 'Required at login, order confirmation, and payment'
              : 'Use fingerprint or Face ID for secure access',
          style: TextStyle(fontSize: 13, color: Colors.grey[600]),
        ),
        value: _biometricEnabled,
        activeColor: Color(0XFF4675C0),
        onChanged: _biometricUpdating ? null : _toggleBiometric,
      ),
    );
  }

  Widget buildListTile(
      IconData icon, String title, BuildContext context, String routeName,
      {VoidCallback? onTap}) {
    return Container(
      margin: EdgeInsets.symmetric(vertical: 4),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12),
      ),
      child: ListTile(
        leading: Container(
          padding: EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: Color(0XFF4675C0).withValues(alpha: 0.1),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: Color(0XFF4675C0), size: 20),
        ),
        title: Text(
          title,
          style: TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            color: Colors.black87,
          ),
        ),
        trailing: Icon(
          Icons.arrow_forward_ios,
          size: 16,
          color: Colors.grey[600],
        ),
        onTap: onTap ??
            () {
              if (routeName.isNotEmpty) {
                Navigator.pushNamed(context, routeName);
              }
            },
      ),
    );
  }
}
