import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'dart:convert';
import '../../../core/app_export.dart';
import 'delivery_details/delivery_details.dart';
import '../../../widgets/custom_elevated_button.dart';
import '../widgets/medicine_autocomplete.dart';

class MedicineRequestScreen extends StatefulWidget {
  @override
  _MedicineRequestScreenState createState() => _MedicineRequestScreenState();
}

class _MedicineRequestScreenState extends State<MedicineRequestScreen> {
  final _formKey = GlobalKey<FormState>();
  bool _isChecked = false; // Add this at the top of the class
  bool _isExpanded = false; // Track if full text should be shown
  TextEditingController _phoneController = TextEditingController();
  TextEditingController _addressController = TextEditingController();
  final List<TextEditingController> _medicineNameControllers = [];
  final List<TextEditingController> _medicineQtyControllers = [];
  bool _controllersInitialized = false;

  String name = '';
  String phone = '';
  String address = '';
  String year = '';
  String gender = 'M';
  String knowsMedicine = 'Y';
  List<Map<String, dynamic>> medicines = [
    {'medicine_name': '', 'medicine_id': '', 'quantity': '1'}
  ];
  String symptoms = '';
  String duration = '';
  String triggers = '';
  int severity = 1;
  String medicalHistory = '';
  String currentMedications = '';
  String pregnancyStatus = '';
  String previousRemedies = '';
  String lifestyleFactors = 'N';
  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _phoneController.dispose();
    _addressController.dispose();
    _disposeMedicineControllers();
    super.dispose();
  }

  void _disposeMedicineControllers() {
    for (final c in _medicineNameControllers) {
      c.dispose();
    }
    for (final c in _medicineQtyControllers) {
      c.dispose();
    }
    _medicineNameControllers.clear();
    _medicineQtyControllers.clear();
    _controllersInitialized = false;
  }

  void _initMedicineControllersFromState() {
    _disposeMedicineControllers();
    for (int i = 0; i < medicines.length; i++) {
      final nameController = TextEditingController(
        text: (medicines[i]['medicine_name'] ?? '').toString(),
      );
      final qtyController = TextEditingController(
        text: (medicines[i]['quantity'] ?? '1').toString(),
      );

      nameController.addListener(() {
        if (!mounted) return;
        final currentText = nameController.text.trim();
        final selectedName =
            (medicines[i]['selected_name'] ?? medicines[i]['medicine_name'] ?? '')
                .toString()
                .trim();
        final selectedId = (medicines[i]['medicine_id'] ?? '').toString().trim();

        // If user edits text after selecting a suggestion, invalidate selection.
        if (selectedId.isNotEmpty && currentText != selectedName) {
          medicines[i]['medicine_id'] = '';
          medicines[i]['selected_name'] = '';
        }

        medicines[i]['medicine_name'] = currentText;
      });

      qtyController.addListener(() {
        if (!mounted) return;
        medicines[i]['quantity'] = qtyController.text.trim();
      });

      _medicineNameControllers.add(nameController);
      _medicineQtyControllers.add(qtyController);
    }
    _controllersInitialized = true;
  }

  Future<void> _loadData() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    // final SharedPreferences prefs = await SharedPreferences.getInstance();
    final String? userDataString = prefs.getString('userData');

    if (userDataString == null) {
      throw Exception("User data is missing.");
    }

    final Map<String, dynamic> userData = json.decode(userDataString);
    final String usr_username = (userData['usr_username'] ?? '').toString();
    final String userAddress = 'Argwings Kodhek Road';
    final String usr_mobile_number = (userData['usr_mobile_number'] ?? '').toString();

    if (usr_username.trim().isEmpty) {
      throw Exception("User ID is missing.");
    }
    //print(usr_mobile_number);
    setState(() {
      name = usr_username;
      phone = usr_mobile_number;
      address = userAddress;
      gender = prefs.getString('gender') ?? 'M';
      year = prefs.getString('year') ?? '';
      knowsMedicine = prefs.getString('knowsMedicine') ?? 'Y';
      final savedMedicinesRaw =
          prefs.getString('medicines') ?? '[{"medicine_name": "", "quantity": "1"}]';
      final decoded = jsonDecode(savedMedicinesRaw);
      if (decoded is List) {
        medicines = decoded.map<Map<String, dynamic>>((e) {
          final map = (e is Map) ? Map<String, dynamic>.from(e) : <String, dynamic>{};
          final name = (map['medicine_name'] ?? map['name'] ?? '').toString();
          final qty = (map['quantity'] ?? map['qty'] ?? '1').toString();
          final id = (map['medicine_id'] ?? map['id'] ?? '').toString();
          return {
            'medicine_name': name,
            'selected_name': map['selected_name']?.toString() ?? name,
            'medicine_id': id,
            'quantity': qty,
          };
        }).toList();
      } else {
        medicines = [
          {'medicine_name': '', 'selected_name': '', 'medicine_id': '', 'quantity': '1'}
        ];
      }
      symptoms = prefs.getString('symptoms') ?? '';
      duration = prefs.getString('duration') ?? '';
      triggers = prefs.getString('triggers') ?? '';
      severity = prefs.getInt('severity') ?? 1;
      medicalHistory = prefs.getString('medicalHistory') ?? '';
      currentMedications = prefs.getString('currentMedications') ?? '';
      pregnancyStatus = prefs.getString('pregnancyStatus') ?? '';
      previousRemedies = prefs.getString('previousRemedies') ?? '';
      lifestyleFactors = prefs.getString('lifestyleFactors') ?? 'N';
      _phoneController.text = phone;
      _addressController.text = address;
      //print(phone);
    });

    if (!_controllersInitialized) {
      _initMedicineControllersFromState();
    }
  }

  Future<void> _saveMedicineData() async {
    // print('enter in this ');
    if (gender.isEmpty ||
        medicines.isEmpty ||
        knowsMedicine.isEmpty ||
        year.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all required fields.")),
      );
      return; // Stop the function if validation fails
    }

    // Enforce "must select from suggestions" when knowsMedicine == Y
    for (int i = 0; i < medicines.length; i++) {
      final medName = (medicines[i]['medicine_name'] ?? '').toString().trim();
      final medId = (medicines[i]['medicine_id'] ?? '').toString().trim();
      final qty = (medicines[i]['quantity'] ?? '').toString().trim();

      if (medName.isEmpty || qty.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text("Please fill in medicine name and quantity.")),
        );
        return;
      }

      if (medId.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              "Please type the medicine name and select it from the suggestions.",
            ),
          ),
        );
        return;
      }
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('medicines', jsonEncode(medicines));
    prefs.setString('knowsMedicine', knowsMedicine);
    prefs.setString('name', name);
    prefs.setString('phone', _phoneController.text);
    prefs.setString('address', _addressController.text);
    prefs.setString('address', address);
    prefs.setString('gender', gender);
    prefs.setString('mtype', '0');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryScreen(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Medicine data saved!")),
    );
  }

  Future<void> _saveData() async {
    if (year.isEmpty ||
        gender.isEmpty ||
        symptoms.isEmpty ||
        duration.isEmpty ||
        triggers.isEmpty ||
        severity == 0 || // Assuming 0 is an invalid/default severity
        medicalHistory.isEmpty ||
        currentMedications.isEmpty ||
        pregnancyStatus.isEmpty ||
        previousRemedies.isEmpty ||
        lifestyleFactors.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Please fill in all required fields.")),
      );
      return; // Stop the function if any field is missing
    }
    SharedPreferences prefs = await SharedPreferences.getInstance();
    prefs.setString('name', name);
    prefs.setString('phone', _phoneController.text);
    prefs.setString('address', _addressController.text);
    prefs.setString('year', year);

    prefs.setString('gender', gender);
    prefs.setString('symptoms', symptoms);
    prefs.setString('duration', duration);
    prefs.setString('triggers', triggers);
    prefs.setInt('severity', severity);
    prefs.setString('medicalHistory', medicalHistory);
    prefs.setString('currentMedications', currentMedications);
    prefs.setString('pregnancyStatus', pregnancyStatus);
    prefs.setString('previousRemedies', previousRemedies);
    prefs.setString('lifestyleFactors', lifestyleFactors);
    prefs.setString('mtype', '1');
    Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => DeliveryScreen(),
      ),
    );
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("symptoms data saved!")),
    );
  }

  void _addMedicine() {
    setState(() {
      medicines.add(
        {'medicine_name': '', 'selected_name': '', 'medicine_id': '', 'quantity': '1'},
      );
    });
    _initMedicineControllersFromState();
  }

  void _removeMedicine(int index) {
    setState(() {
      medicines.removeAt(index);
    });
    _initMedicineControllersFromState();
  }

  @override
  Widget build(BuildContext context) {
    if (knowsMedicine == 'Y' && !_controllersInitialized) {
      _initMedicineControllersFromState();
    }

    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      appBar: AppBar(
        title: Text(
          "OTC Medication", // ✅ Title in center
          style: TextStyle(color: Colors.white, fontSize: 20),
        ),
        centerTitle: true, // ✅ Ensures title is centered
        backgroundColor: theme.colorScheme.primary, // ✅ Customize as needed
        leading: IconButton(
          icon: Icon(Icons.arrow_back, color: Colors.white), // ✅ Back arrow
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Form(
          key: _formKey,
          child: SingleChildScrollView(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                TextFormField(
                  initialValue: year,
                  onChanged: (value) => year = value,
                  decoration: InputDecoration(labelText: 'Year of Birth'),
                  keyboardType: TextInputType.number,
                ),
                SizedBox(height: 8),
                Text("Gender: "),
                SizedBox(height: 1),

                /// Adds spacing between the text and radio buttons

                Row(
                  children: [
                    Radio(
                      value: 'M',
                      groupValue: gender,
                      onChanged: (value) =>
                          setState(() => gender = value.toString()),
                    ),
                    Text("M"),
                    Radio(
                      value: 'F',
                      groupValue: gender,
                      onChanged: (value) =>
                          setState(() => gender = value.toString()),
                    ),
                    Text("F"),
                  ],
                ),

                Text("Do you know the medicine?"),
                Row(
                  children: [
                    Radio(
                      value: 'Y',
                      groupValue: knowsMedicine,
                      onChanged: (value) =>
                          setState(() => knowsMedicine = value.toString()),
                    ),
                    Text("Yes"),
                    Radio(
                      value: 'N',
                      groupValue: knowsMedicine,
                      onChanged: (value) =>
                          setState(() => knowsMedicine = value.toString()),
                    ),
                    Text("No"),
                  ],
                ),
                if (knowsMedicine == 'Y') ...[
                  Column(
                    children: [
                      for (int i = 0; i < medicines.length; i++)
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            Expanded(
                              child: MedicineAutocomplete(
                                controller: _medicineNameControllers[i],
                                hintText: "Medicine Name",
                                fontSize: 13.0,
                                onMedicineSelected: (medicine) {
                                  setState(() {
                                    final selectedName =
                                        (medicine['name'] ?? medicine['medicine_name'] ?? '')
                                            .toString();
                                    medicines[i]['medicine_name'] = selectedName;
                                    medicines[i]['selected_name'] = selectedName;
                                    medicines[i]['medicine_id'] =
                                        (medicine['id'] ?? '').toString();
                                    _medicineNameControllers[i].text = selectedName;
                                  });
                                },
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: TextFormField(
                                controller: _medicineQtyControllers[i],
                                decoration: InputDecoration(labelText: 'Qty'),
                                keyboardType: TextInputType.number,
                              ),
                            ),
                            SizedBox(width: 10),
                            if (i >
                                0) // Ensure delete button is not in the first row
                              IconButton(
                                icon: Icon(Icons.delete, color: Colors.red),
                                onPressed: () => _removeMedicine(i),
                              ),
                            if (i ==
                                0) // Maintain spacing consistency for the first row
                              SizedBox(
                                  width:
                                      48), // Width equal to delete button to align properly
                          ],
                        ),
                      TextButton(
                          onPressed: _addMedicine, child: Text("Add More")),
                    ],
                  ),
                ] else ...[
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(bottom: 8.0),
                        child: Text(
                          'Please describe how you are feeling?',
                        ),
                      ),
                      TextFormField(
                        // Allows for multiline input
                        initialValue: symptoms,
                        onChanged: (value) => symptoms = value,
                        style: TextStyle(
                          fontSize: 13, // Decreased font size
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type your answer here...',
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: Text(
                          'How long have you had these symptoms?',
                        ),
                      ),
                      TextFormField(
                        style: TextStyle(
                          fontSize: 13, // Decreased font size
                        ),
                        decoration: InputDecoration(
                          hintText: 'Enter your answer here...',
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                        initialValue: duration,
                        onChanged: (value) => duration = value,
                      ),
                    ],
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: Text(
                          'Do you know what might have caused the issue, like stress, a cold, or an injury?',
                        ),
                      ),
                      TextFormField(
                        initialValue: triggers,
                        onChanged: (value) => triggers = value,
                        style: TextStyle(
                          fontSize: 13, // Decreased font size
                        ),
                        decoration: InputDecoration(
                          hintText: 'Describe possible causes here...',
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Text("Severity (1-10)"),
                  Slider(
                    value: severity.toDouble(),
                    min: 1,
                    max: 10,
                    divisions: 9,
                    label: severity.toString(),
                    onChanged: (value) =>
                        setState(() => severity = value.toInt()),
                  ),
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Question 1
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: Text(
                          'Do you have any underlying health conditions, like allergies, asthma, or chronic diseases?',
                        ),
                      ),
                      TextFormField(
                        initialValue: medicalHistory,
                        onChanged: (value) => medicalHistory = value,
                        style: TextStyle(
                          fontSize: 13, // Decreased font size
                        ),
                        decoration: InputDecoration(
                          hintText: 'Type your answer here...',
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      // Question 2
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: Text(
                          'Are you taking any prescriptions, OTC drugs, or supplements?',
                        ),
                      ),
                      TextFormField(
                        initialValue: currentMedications,
                        onChanged: (value) => currentMedications = value,
                        style: TextStyle(
                          fontSize: 13, // Decreased font size
                        ),
                        decoration: InputDecoration(
                          hintText: 'List your current medications...',
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      // Question 3
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: Text(
                          'If applicable, they may ask about this to ensure the safety of the medication.',
                        ),
                      ),
                      TextFormField(
                        initialValue: pregnancyStatus,
                        onChanged: (value) => pregnancyStatus = value,
                        style: TextStyle(
                          fontSize: 13, // Decreased font size
                        ),
                        decoration: InputDecoration(
                          hintText: 'Write your answer (if applicable)...',
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),

                      // Question 4
                      Padding(
                        padding: const EdgeInsets.only(top: 16.0, bottom: 8.0),
                        child: Text(
                          'Have you tried anything for this condition before? If so, did it help?',
                        ),
                      ),
                      TextFormField(
                        initialValue: previousRemedies,
                        onChanged: (value) => previousRemedies = value,
                        style: TextStyle(
                          fontSize: 13, // Decreased font size
                        ),
                        decoration: InputDecoration(
                          hintText:
                              'Describe any remedies or treatments you tried...',
                          contentPadding: EdgeInsets.symmetric(
                              vertical: 15, horizontal: 10),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                          ),
                        ),
                      ),
                    ],
                  ),
                  Padding(
                    padding: const EdgeInsets.only(
                        top: 16.0), // Adds space above the text
                    child: Text(
                      "Do you have any preferences or restrictions, such as avoiding drowsy medications if you need to drive or work?",
                    ),
                  ),
                  Row(children: [
                    Radio(
                      value: 'Y',
                      groupValue: lifestyleFactors,
                      onChanged: (value) =>
                          setState(() => lifestyleFactors = value.toString()),
                    ),
                    Text("Yes"),
                    Radio(
                      value: 'N',
                      groupValue: lifestyleFactors,
                      onChanged: (value) =>
                          setState(() => lifestyleFactors = value.toString()),
                    ),
                    Text("No"),
                  ])
                ], // Note Section with Checkbox
                SizedBox(height: 10),
                Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start, // Align checkbox at top
                      children: [
                        Checkbox(
                          value: _isChecked,
                          onChanged: (value) {
                            setState(() {
                              _isChecked = value!;
                            });
                          },
                        ),
                        SizedBox(
                            width:
                                5), // Small spacing between checkbox and text
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              RichText(
                                text: TextSpan(
                                  style: TextStyle(
                                      fontSize: 12, color: Colors.black),
                                  children: [
                                    TextSpan(
                                      text: _isExpanded
                                          ? "Note: Ordering over-the-counter (OTC) medication through QuikDawa does not guarantee the sale of the product. Our partners who are licensed pharmacists reserve the right to decline the sale if they have any concerns regarding the safety, suitability, or compliance of the order. Your health and well-being are our top priorities."
                                          : "Note: Ordering over-the-counter (OTC) medication through QuikDawa does not guarantee the sale...",
                                    ),
                                    if (!_isExpanded)
                                      WidgetSpan(
                                        child: InkWell(
                                          onTap: () {
                                            setState(() {
                                              _isExpanded = true;
                                            });
                                          },
                                          child: Text(
                                            " Read More",
                                            style:
                                                TextStyle(color: Colors.blue),
                                          ),
                                        ),
                                      ),
                                  ],
                                ),
                                maxLines: _isExpanded ? 8 : 2,
                                overflow: TextOverflow.ellipsis,
                              ),
                              if (_isExpanded)
                                Align(
                                  alignment: Alignment.centerLeft,
                                  child: InkWell(
                                    onTap: () {
                                      setState(() {
                                        _isExpanded = false;
                                      });
                                    },
                                    child: Text(
                                      "Read Less",
                                      style: TextStyle(color: Colors.blue),
                                    ),
                                  ),
                                ),
                            ],
                          ),
                        ),
                      ],
                    ),
                    SizedBox(height: 10),
                  ],
                ),
                // Next Button
                SizedBox(height: 10),

                CustomElevatedButton(
                  text: "Next",
                  margin: EdgeInsets.only(left: 16.h, right: 14.h),
                  rightIcon: Container(
                    margin: EdgeInsets.only(left: 15.h),
                    child: CustomImageView(
                      imagePath: ImageConstant.imgArrowrightGray5003,
                      height: 24.h,
                      width: 24.h,
                      fit: BoxFit.contain,
                    ),
                  ),
                  onPressed: () {
                    if (!_isChecked) {
                      // Show error if checkbox is not checked
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(
                            content: Text(
                                "Please check the note before proceeding.")),
                      );
                      return;
                    }

                    // Proceed based on knowsMedicine value
                    if (knowsMedicine == 'Y') {
                      _saveMedicineData();
                    } else {
                      _saveData();
                    }
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

void main() {
  runApp(MaterialApp(home: MedicineRequestScreen()));
}
