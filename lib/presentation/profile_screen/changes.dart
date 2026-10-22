import 'package:flutter/material.dart';
import '../../core/config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;

class ChangePhoneNumberScreen extends StatefulWidget {
  @override
  _ChangePhoneNumberScreenState createState() =>
      _ChangePhoneNumberScreenState();
}

class _ChangePhoneNumberScreenState extends State<ChangePhoneNumberScreen> {
  final GlobalKey<ScaffoldState> _scaffoldKey = GlobalKey<ScaffoldState>();
  TextEditingController phoneController = TextEditingController();
  final _formKey = GlobalKey<FormState>();
  String previousPhoneNumber = "";

  @override
  void initState() {
    super.initState();
    _fetchUserData();
  }

  Future<void> _fetchUserData() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('userData');

    if (userDataString == null) {
      print("User data is missing.");
      return;
    }

    final Map<String, dynamic> userData = json.decode(userDataString);
    final int? userId = userData['id'];

    if (userId == null) {
      print("User ID is missing.");
      return;
    }

    var response = await http.post(
      Uri.parse(AppConfig.buildApiUrl('get_user')),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {"usr_id": userId.toString()},
    );
    // print(response.body);
    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['success']) {
        var user = data['data'][0];

        setState(() {
          previousPhoneNumber = user['usr_mobile_number'].toString();
          phoneController.text = previousPhoneNumber;
        });

        prefs.setString('phone_number', previousPhoneNumber);
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('userData');

      if (userDataString == null) {
        print("User data is missing.");
        return;
      }

      final Map<String, dynamic> userData = json.decode(userDataString);
      final int? userId = userData['id'];

      if (userId == null) {
        print("User ID is missing.");
        return;
      }
      var response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('update_mobile')),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          "usr_id": userId.toString(),
          "phone_number": phoneController.text.trim(),
        },
      );

      var responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        prefs.setString("phone_number", phoneController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(responseBody['message']),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(responseBody['message']),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      key: _scaffoldKey,
      appBar: AppBar(
        title:
            Text("Change Phone Number", style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey, // ✅ Fixed missing key
          child: Column(
            children: [
              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(labelText: "Phone Number"),
                validator: (value) =>
                    value!.isEmpty ? "Enter a valid phone number" : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChangeEmailScreen extends StatefulWidget {
  @override
  _ChangeEmailScreenState createState() => _ChangeEmailScreenState();
}

class _ChangeEmailScreenState extends State<ChangeEmailScreen> {
  TextEditingController emailController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  @override
  void initState() {
    super.initState();
    _fetchUserEmail();
  }

  Future<void> _fetchUserEmail() async {
    final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('userData');

    if (userDataString == null) {
      print("User data is missing.");
      return;
    }

    final Map<String, dynamic> userData = json.decode(userDataString);
    final int? userId = userData['id'];

    if (userId == null) {
      print("User ID is missing.");
      return;
    }

    var response = await http.post(
      Uri.parse(AppConfig.buildApiUrl('get_user')),
      headers: {'Content-Type': 'application/x-www-form-urlencoded'},
      body: {"usr_id": userId.toString()},
    );

    if (response.statusCode == 200) {
      var data = json.decode(response.body);
      if (data['success']) {
        var user = data['data'][0];

        setState(() {
          emailController.text = user['usr_email'].toString();
        });

        prefs.setString('email', emailController.text);
      }
    }
  }

  Future<void> _submit() async {
    if (_formKey.currentState!.validate()) {
      final SharedPreferences prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('userData');

      if (userDataString == null) {
        print("User data is missing.");
        return;
      }

      final Map<String, dynamic> userData = json.decode(userDataString);
      final int? userId = userData['id'];

      if (userId == null) {
        print("User ID is missing.");
        return;
      }
      var response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('update_email')),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {
          "usr_id": userId.toString(),
          "email": emailController.text.trim(),
        },
      );

      var responseBody = json.decode(response.body);

      if (response.statusCode == 200) {
        prefs.setString("email", emailController.text.trim());
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(responseBody['message']),
              backgroundColor: Colors.green),
        );
        Navigator.pop(context);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text(responseBody['message']),
              backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title:
            Text("Change Email Address", style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(labelText: "New Email"),
                validator: (value) =>
                    value!.isEmpty ? "Enter a valid email" : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text("Save"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ChangePasswordScreen extends StatefulWidget {
  @override
  _ChangePasswordScreenState createState() => _ChangePasswordScreenState();
}

class _ChangePasswordScreenState extends State<ChangePasswordScreen> {
  TextEditingController currentPasswordController = TextEditingController();
  TextEditingController newPasswordController = TextEditingController();
  TextEditingController confirmPasswordController = TextEditingController();
  final _formKey = GlobalKey<FormState>();

  void _submit() {
    if (_formKey.currentState!.validate()) {
      if (newPasswordController.text != confirmPasswordController.text) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Passwords do not match!"),
              backgroundColor: Colors.red),
        );
        return;
      }
      // Handle password change logic
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text("Change Password", style: TextStyle(color: Colors.white)),
        backgroundColor: Theme.of(context).colorScheme.primary,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      body: Padding(
        padding: EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: Column(
            children: [
              TextFormField(
                controller: currentPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Current Password"),
                validator: (value) =>
                    value!.isEmpty ? "Enter current password" : null,
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: newPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "New Password"),
                validator: (value) => value!.length < 6
                    ? "Password must be at least 6 characters"
                    : null,
              ),
              SizedBox(height: 14),
              TextFormField(
                controller: confirmPasswordController,
                obscureText: true,
                decoration: InputDecoration(labelText: "Confirm Password"),
                validator: (value) =>
                    value!.isEmpty ? "Confirm your password" : null,
              ),
              SizedBox(height: 20),
              ElevatedButton(
                onPressed: _submit,
                style: ElevatedButton.styleFrom(
                  minimumSize: Size(double.infinity, 50),
                  backgroundColor: Theme.of(context).colorScheme.primary,
                  foregroundColor: Colors.white,
                ),
                child: Text("Change Password"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
