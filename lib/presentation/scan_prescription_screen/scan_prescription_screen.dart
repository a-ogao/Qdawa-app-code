import 'package:flutter/material.dart';
import 'package:camera/camera.dart';
import '../../core/config/app_config.dart';
import 'dart:convert';
import 'dart:io';
import 'package:image_cropper/image_cropper.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../scanned_prescription_screen/scanned_prescription_screen.dart';
import '../../core/app_export.dart';

class ScanPrescriptionScreen extends StatefulWidget {
  const ScanPrescriptionScreen({Key? key}) : super(key: key);

  @override
  _ScanPrescriptionScreenState createState() => _ScanPrescriptionScreenState();
}

class _ScanPrescriptionScreenState extends State<ScanPrescriptionScreen> {
  late CameraController _controller;
  Future<void>? _initializeControllerFuture;
  bool _isCameraInitialized = false;
  XFile? _capturedImage;
  CroppedFile? _croppedImage; // Store the cropped image
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _initializeCamera();
  }

  Future<void> _initializeCamera() async {
    try {
      final cameras = await availableCameras();
      if (cameras.isEmpty) throw Exception("No cameras available");

      final firstCamera = cameras.first;

      _controller = CameraController(
        firstCamera,
        ResolutionPreset.high,
        enableAudio: false,
      );

      _initializeControllerFuture = _controller.initialize();
      await _initializeControllerFuture;

      if (mounted) {
        setState(() {
          _isCameraInitialized = true;
        });
      }
    } on CameraException catch (e) {
      print("Error initializing camera: $e");
      setState(() {
        _isCameraInitialized = false;
      });
    }
  }

  // Capture the image
  Future<void> _captureImage() async {
    try {
      await _initializeControllerFuture;
      final image = await _controller.takePicture();
      setState(() {
        _capturedImage = image;
      });

      // Call cropping function
      _cropImage(File(image.path));
    } catch (e) {
      print("Error capturing image: $e");
    }
  }

// Crop the captured image
  Future<void> _cropImage(File imageFile) async {
    final croppedFile = await ImageCropper().cropImage(
      sourcePath: imageFile.path,
      aspectRatio:
          const CropAspectRatio(ratioX: 4, ratioY: 3), // ✅ use this instead
      uiSettings: [
        AndroidUiSettings(
          toolbarTitle: 'Crop Image',
          toolbarColor: Colors.blue,
          toolbarWidgetColor: Colors.white,
          lockAspectRatio: false,
        ),
        IOSUiSettings(
          title: 'Crop Image',
          aspectRatioLockEnabled: false,
        ),
      ],
    );

    if (croppedFile != null) {
      setState(() {
        _croppedImage = croppedFile; // ✅ CroppedFile directly
      });
    }
  }

  // Submit the cropped image to the API
  Future<void> _submitImage() async {
    if (_croppedImage == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('No image to submit')),
      );
      return;
    }
    setState(() {
      _isLoading = true;
    });

    try {
      File originalFile = File(_capturedImage!.path);
      List<int> originalBytes = await originalFile.readAsBytes();
      String base64Original = base64Encode(originalBytes);

      // File names
      //String originalFileName = _capturedImage!.path.split('/').last;
      //String croppedFileName = _croppedImage!.path.split('/').last;

      File imageFile = File(_croppedImage!.path);
      List<int> imageBytes = await imageFile.readAsBytes();
      String base64Image = base64Encode(imageBytes);
      const String apiUrl = AppConfig.aipProcessUrl;

      var response = await http.post(
        Uri.parse(apiUrl),
        headers: {'Content-Type': 'application/x-www-form-urlencoded'},
        body: {'base64': base64Image, 'base64Original': base64Original},
      );

      if (response.statusCode == 200) {
        var responseData = jsonDecode(response.body);
        var result = responseData['result'];
        var filepath = responseData['filePath'];
        var orignalfilepath = responseData['orignalfilePath'];
        SharedPreferences prefs = await SharedPreferences.getInstance();
        await prefs.setString('prescription', jsonEncode(result));
        await prefs.setString('filepath', jsonEncode(filepath));
        await prefs.setString('orignalfilepath', jsonEncode(orignalfilepath));

        await prefs.setString('mtype', '2');

        Navigator.push(
          context,
          MaterialPageRoute(builder: (context) => ScannedPrescriptionScreen()),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Failed to upload image')),
        );
      }
    } catch (e) {
      print("Error sending image to API: $e");
    } finally {
      setState(() {
        _isLoading = false;
      });
    }
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Scan Prescription',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: theme.colorScheme.primary,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back, color: Colors.white),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: _isCameraInitialized
          ? Stack(
              children: [
                if (_capturedImage == null && _croppedImage == null)
                  Positioned.fill(
                    child: AspectRatio(
                      aspectRatio: _controller.value.aspectRatio,
                      child: CameraPreview(_controller),
                    ),
                  )
                else if (_croppedImage != null)
                  Positioned.fill(
                    child: Image.file(
                      File(_croppedImage!.path),
                      fit: BoxFit.cover,
                    ),
                  )
                else if (_capturedImage != null)
                  Positioned.fill(
                    child: Image.file(
                      File(_capturedImage!.path),
                      fit: BoxFit.cover,
                    ),
                  ),

                // Buttons Section
                Align(
                  alignment: Alignment.bottomCenter,
                  child: Padding(
                    padding: const EdgeInsets.all(20.0),
                    child: _capturedImage == null && _croppedImage == null
                        ? ElevatedButton(
                            onPressed: _captureImage,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: theme.colorScheme.primary,
                              padding: const EdgeInsets.all(16),
                              shape: const CircleBorder(),
                            ),
                            child: Image.asset(
                              'assets/images/img_qd_scan_1.png',
                              height: 72,
                              width: 72,
                            ),
                          )
                        : Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              if (_isLoading)
                                const CircularProgressIndicator()
                              else
                                Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    ElevatedButton(
                                      onPressed:
                                          _isLoading ? null : _submitImage,
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.green,
                                        padding: const EdgeInsets.all(16),
                                        shape: const CircleBorder(),
                                      ),
                                      child: Image.asset(
                                        'assets/images/img_qd_correct_2.png',
                                        height: 72,
                                        width: 72,
                                      ),
                                    ),
                                    const SizedBox(width: 20),
                                    ElevatedButton(
                                      onPressed: _isLoading
                                          ? null
                                          : () {
                                              setState(() {
                                                _capturedImage = null;
                                                _croppedImage = null;
                                              });
                                            },
                                      style: ElevatedButton.styleFrom(
                                        backgroundColor: Colors.red,
                                        padding: const EdgeInsets.all(16),
                                        shape: const CircleBorder(),
                                      ),
                                      child: Image.asset(
                                        'assets/images/img_qd_rescan_1.png',
                                        height: 72,
                                        width: 72,
                                      ),
                                    ),
                                  ],
                                ),
                            ],
                          ),
                  ),
                ),
              ],
            )
          : const Center(child: CircularProgressIndicator()),
    );
  }
}
