import 'dart:convert';
import 'dart:io';
import 'package:flutter/material.dart';
import 'package:file_picker/file_picker.dart';
import 'package:http/http.dart' as http;
import 'package:path/path.dart' as path;
import 'package:shared_preferences/shared_preferences.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_outlined_button.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import 'delivery_details/delivery_details.dart';

class PReportsPage extends StatefulWidget {
  @override
  _PReportsPageState createState() => _PReportsPageState();
}

class _PReportsPageState extends State<PReportsPage> {
  File? selectedFile;

  Future<void> pickLabReport() async {
    FilePickerResult? result = await FilePicker.platform.pickFiles(
      type: FileType.custom,
      allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
    );

    if (result != null && result.files.single.path != null) {
      setState(() {
        selectedFile = File(result.files.single.path!);
      });
    }
  }

  Future<void> uploadLabReport() async {
    if (selectedFile == null) return;

    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? userDataString = prefs.getString('userData');

    if (userDataString == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("User session not found. Please log in again.")),
      );
      return;
    }

    final Map<String, dynamic> userData = json.decode(userDataString);
    String userId = userData['id'].toString();

    var uri = Uri.parse(AppConfig.buildApiUrl('uploadlab_report'));

    var request = http.MultipartRequest('POST', uri);
    request.files.add(await http.MultipartFile.fromPath(
      'lab_report',
      selectedFile!.path,
      filename: path.basename(selectedFile!.path),
    ));
    request.fields['user_id'] = userId;

    var response = await request.send();

    if (response.statusCode == 200) {
      final responseBody = await response.stream.bytesToString();
      final data = json.decode(responseBody);

      String? filePath = data['path'];
      if (filePath != null) {
        await prefs.setString('lab_report_file_path', filePath);
        await prefs.setString('mtype', '3');

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => DeliveryScreen()),
        );

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Lab report uploaded successfully")),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
              content: Text("Upload succeeded, but no file path returned.")),
        );
      }
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Failed to upload lab report")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          "Upload Lab Report",
          style: TextStyle(color: Colors.white, fontSize: 16),
        ),
        backgroundColor: Theme.of(context).primaryColor,
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CustomElevatedButton(
              text: "Browse Lab Report",
              onPressed: pickLabReport,
            ),
            if (selectedFile != null) ...[
              SizedBox(height: 20),
              Text(
                "Selected: ${path.basename(selectedFile!.path)}",
                style: TextStyle(fontSize: 16),
              ),
              SizedBox(height: 30),
              CustomElevatedButton(
                text: "Upload Report",
                onPressed: uploadLabReport,
              ),
            ]
          ],
        ),
      ),
    );
  }
}
