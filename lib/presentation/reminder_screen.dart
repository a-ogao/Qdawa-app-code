import 'package:flutter/material.dart';
import '../../../core/app_export.dart';
import '../../../core/config/app_config.dart';
import 'dart:convert';
import 'package:http/http.dart' as http;
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_text_form_field.dart';
import 'order_list_screen/order_list_screen.dart';
import 'package:device_calendar/device_calendar.dart';
import 'package:timezone/data/latest.dart' as tz;
import 'package:timezone/timezone.dart' as tz;

class ReminderScreen extends StatefulWidget {
  final String orderId;

  ReminderScreen({required this.orderId});

  @override
  _ReminderScreenState createState() => _ReminderScreenState();
}

class _ReminderScreenState extends State<ReminderScreen> {
  List<dynamic> medicines = [];
  List<DateTime?> selectedDates = [];
  List<TimeOfDay?> selectedTimes = [];
  bool isLoading = true;
  TextEditingController toponeController = TextEditingController();
  String pharmacy = "Malibu Pharmacy Limited"; // Default pharmacy name
// Define constants for times based on dose type
  final Map<String, List<TimeOfDay>> doseTimeRanges = {
    'B': [TimeOfDay(hour: 5, minute: 0), TimeOfDay(hour: 7, minute: 0)],
    'M': [TimeOfDay(hour: 8, minute: 0), TimeOfDay(hour: 10, minute: 0)],
    'A': [TimeOfDay(hour: 13, minute: 0), TimeOfDay(hour: 15, minute: 0)],
    'E': [TimeOfDay(hour: 17, minute: 0), TimeOfDay(hour: 20, minute: 0)],
  };

// Track selected doses and days for each medicine
  List<Map<String, bool>> selectedDoses = [];
  List<Map<String, bool>> selectedDays = [];
  @override
  void initState() {
    super.initState();
    tz.initializeTimeZones();

    fetchMedicines();
    //addManualMedicineEvent(context);
  }

  Future<void> fetchMedicines() async {
    final url = Uri.parse(AppConfig.buildApiUrl('order_view'));
    try {
      final response = await http.post(
        url,
        body: {'order_id': widget.orderId.toString()},
      );
      if (response.statusCode == 200) {
        final data = json.decode(response.body);

        final items = List<Map<String, dynamic>>.from(data['items'] ?? []);
        setState(() {
          pharmacy = data['order']['pha_first_name'] ?? '';
          // print(pharmacy);
          medicines = items;
          selectedDates = List<DateTime?>.filled(medicines.length, null);
          selectedTimes = List<TimeOfDay?>.filled(medicines.length, null);
          selectedDoses = List.generate(medicines.length, (_) => {});
          selectedDays = List.generate(
            medicines.length,
            (_) => {
              'M': false,
              'T': false,
              'W': false,
              'Th': false,
              'F': false,
              'Sa': false,
              'Su': false,
            },
          );
          isLoading = false;
        });
      } else {
        throw Exception('Failed to load medicines');
      }
    } catch (e) {
      print(e);
      setState(() => isLoading = false);
    }
  }

  Future<void> _pickDate(int index) async {
    DateTime? picked = await showDatePicker(
      context: context,
      initialDate: selectedDates[index] ?? DateTime.now(),
      firstDate: DateTime.now(),
      lastDate: DateTime(2100),
    );
    if (picked != null) {
      setState(() => selectedDates[index] = picked);
    }
  }

  Future<void> _pickTime(int index) async {
    TimeOfDay? picked = await showTimePicker(
      context: context,
      initialTime: selectedTimes[index] ?? TimeOfDay.now(),
    );
    if (picked != null) {
      setState(() => selectedTimes[index] = picked);
    }
  }

  Future<void> _submitAllReminders() async {
    final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
    await _deviceCalendarPlugin.requestPermissions();

    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    final calendar = calendarsResult.data!.firstWhere(
      (cal) => cal.isDefault ?? false,
      orElse: () => calendarsResult.data!.first,
    );

    for (int i = 0; i < medicines.length; i++) {
      String name = medicines[i]['oit_item_name'] ?? 'Unknown';
      int maxDoses =
          int.tryParse(medicines[i]['oit_item_dosage'].toString()) ?? 1;
      int quantity = int.tryParse(medicines[i]['oit_qty'].toString()) ?? 1;
      int totalDoses = quantity;
      int totalDaysNeeded = (totalDoses / maxDoses).ceil();

      Set<String> doses = selectedDoses[i].keys.toSet();
      Map<String, bool> days = selectedDays[i];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
            content:
                Text('qty: $totalDoses  needdays: $totalDaysNeeded doses.')),
      );
      if (doses.length > maxDoses) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name allows only $maxDoses doses.')),
        );
        continue;
      }

      // Calculate valid weekdays
      List<int> validWeekdays = [];
      List<String> dayKeys = days.keys.toList();
      for (int j = 0; j < dayKeys.length; j++) {
        if (days[dayKeys[j]] == true) {
          validWeekdays.add(j + 1); // DateTime weekday (Mon = 1)
        }
      }

      if (validWeekdays.isEmpty) continue;

      // Generate valid date range
      DateTime now = DateTime.now();
      DateTime currentDate = DateTime(now.year, now.month, now.day);
      List<DateTime> validDates = [];

      while (validDates.length < totalDaysNeeded) {
        if (validWeekdays.contains(currentDate.weekday)) {
          validDates.add(currentDate);
        }
        currentDate = currentDate.add(Duration(days: 1));
      }

      DateTime firstDay = validDates.first;
      DateTime lastDay = validDates.last;

      for (DateTime date = firstDay;
          !date.isAfter(lastDay);
          date = date.add(Duration(days: 1))) {
        if (!validWeekdays.contains(date.weekday)) continue;

        for (var dose in doses) {
          var times = doseTimeRanges[dose]!;
          DateTime reminderTime = DateTime(
            date.year,
            date.month,
            date.day,
            times[0].hour + (times[1].hour - times[0].hour) ~/ 2,
          );

          final event = Event(
            calendar.id,
            title: '💊 Take $name',
            description: 'Take $name - $dose dose',
            start: tz.TZDateTime.from(reminderTime, tz.local),
            end: tz.TZDateTime.from(
                reminderTime.add(Duration(minutes: 30)), tz.local),
          );

          await _deviceCalendarPlugin.createOrUpdateEvent(event);
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
          content: Text("All reminders saved to calendar!"),
          backgroundColor: Colors.green),
    );

    Navigator.pushReplacement(
      context,
      MaterialPageRoute(
        builder: (context) => OrderListScreen(),
      ),
    );
  }

  Future<void> _ssubmitAllReminders() async {
    final DeviceCalendarPlugin _deviceCalendarPlugin = DeviceCalendarPlugin();
    await _deviceCalendarPlugin.requestPermissions();

    final calendarsResult = await _deviceCalendarPlugin.retrieveCalendars();
    final calendar = calendarsResult.data!.firstWhere(
      (cal) => cal.isDefault ?? false,
      orElse: () => calendarsResult.data!.first,
    );

    DateTime now = DateTime.now();
    DateTime firstDay = DateTime(now.year, now.month, now.day);
    DateTime lastDay = DateTime(now.year, now.month + 1, now.day);

    for (int i = 0; i < medicines.length; i++) {
      String name = medicines[i]['oit_item_name'] ?? 'Unknown';
      int maxDoses =
          int.tryParse(medicines[i]['oit_item_dosage'].toString()) ?? 1;
      Set<String> doses = selectedDoses[i].keys.toSet();
      Map<String, bool> days = selectedDays[i];
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Doses $doses maxdose $maxDoses calendar.')),
      );
      if (doses.length > maxDoses) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('$name allows only $maxDoses doses.')),
        );
        continue;
      }

      for (DateTime date = firstDay;
          date.isBefore(lastDay);
          date = date.add(Duration(days: 1))) {
        if (!days.values.toList()[date.weekday - 1]) continue;

        for (var dose in doses) {
          var times = doseTimeRanges[dose]!;
          DateTime reminderTime = DateTime(
            date.year,
            date.month,
            date.day,
            times[0].hour + (times[1].hour - times[0].hour) ~/ 2,
          );

          final event = Event(
            calendar.id,
            title: '💊 Take $name',
            description: 'Take $name - $dose dose',
            start: tz.TZDateTime.from(reminderTime, tz.local),
            end: tz.TZDateTime.from(
                reminderTime.add(Duration(minutes: 30)), tz.local),
          );

          await _deviceCalendarPlugin.createOrUpdateEvent(event);
        }
      }
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text('All reminders saved to calendar.')),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text("Set Medicine Reminder"),
        backgroundColor: Theme.of(context).primaryColor,
        foregroundColor: Colors.white,
      ),
      body: isLoading
          ? Center(child: CircularProgressIndicator())
          : Padding(
              padding: EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: EdgeInsets.only(right: 6.h),
                    child: CustomTextFormField(
                      controller: toponeController,
                      hintText: pharmacy.isNotEmpty
                          ? pharmacy
                          : 'Malibu Pharmacy Limited',
                      textInputAction: TextInputAction.done,
                      contentPadding: EdgeInsets.symmetric(
                        horizontal: 20.h,
                        vertical: 14.h,
                      ),
                      hintStyle: TextStyle(
                        color: Colors.white,
                        fontSize: 16.0,
                      ),
                      borderDecoration: TextFormFieldStyleHelper.fillPrimary,
                      fillColor: theme.colorScheme.primary,
                    ),
                  ),
                  SizedBox(height: 20.h),
                  Expanded(child: _buildReminderList()),
                ],
              ),
            ),
    );
  }

  Widget _buildReminderList() {
    return medicines.isEmpty
        ? const Center(child: Text("No medicines found."))
        : Container(
            width: double.infinity,
            margin: EdgeInsets.only(right: 6.h),
            padding: EdgeInsets.symmetric(vertical: 6.h),
            decoration: AppDecoration.fFFFFFDropShadow.copyWith(
              borderRadius: BorderRadiusStyle.roundedBorder5,
            ),
            child: SingleChildScrollView(
              child: Column(
                children: [
                  const Divider(height: 1, thickness: 1),
                  ListView.separated(
                    shrinkWrap: true,
                    physics: const NeverScrollableScrollPhysics(),
                    itemCount: medicines.length,
                    separatorBuilder: (context, index) => Divider(
                      height: 1,
                      color: Colors.grey[300],
                    ),
                    itemBuilder: (context, index) {
                      final medicine = medicines[index];

                      return Padding(
                        padding: EdgeInsets.symmetric(
                            horizontal: 10.h, vertical: 4.h),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text.rich(
                              TextSpan(
                                children: [
                                  const TextSpan(
                                    text: "Name: ",
                                    style: TextStyle(
                                        fontWeight: FontWeight.normal),
                                  ),
                                  TextSpan(
                                    text:
                                        medicine['oit_item_name'] ?? 'Unknown',
                                    style: const TextStyle(
                                        fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                              style: TextStyle(
                                fontSize: 13,
                                color: Colors.black,
                              ),
                            ),
                            SizedBox(height: 4),

                            // Time Slots (compact)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2.0),
                              child:
                                  Text("Time:", style: TextStyle(fontSize: 12)),
                            ),
                            Wrap(
                              spacing: 2,
                              runSpacing: 2,
                              children: ['B', 'M', 'A', 'E'].map((dose) {
                                selectedDoses[index] ??= {};
                                final selectedCount = selectedDoses[index]
                                    .values
                                    .where((v) => v)
                                    .length;
                                final maxAllowed = int.tryParse(
                                        medicine['oit_item_dosage']
                                            .toString()) ??
                                    0;
                                final isSelected =
                                    selectedDoses[index][dose] ?? false;

                                return ChoiceChip(
                                  label: Text(dose,
                                      style: TextStyle(fontSize: 10)),
                                  padding: EdgeInsets.zero,
                                  visualDensity: VisualDensity(
                                      horizontal: -4, vertical: -4),
                                  selected: isSelected,
                                  selectedColor:
                                      const Color.fromARGB(255, 111, 169, 45),
                                  onSelected: (selected) {
                                    setState(() {
                                      if (selected) {
                                        if (selectedCount < maxAllowed) {
                                          selectedDoses[index][dose] = true;
                                        } else {
                                          // Show error message if limit exceeded
                                          ScaffoldMessenger.of(context)
                                              .showSnackBar(
                                            SnackBar(
                                              content: Text(
                                                  "Only $maxAllowed dose(s) allowed."),
                                              duration: Duration(seconds: 2),
                                            ),
                                          );
                                        }
                                      } else {
                                        selectedDoses[index][dose] = false;
                                      }
                                    });
                                  },
                                  showCheckmark: false,
                                );
                              }).toList(),
                            ),

                            SizedBox(height: 6),

                            // Days (compact)
                            Padding(
                              padding: const EdgeInsets.only(bottom: 2.0),
                              child:
                                  Text("Days:", style: TextStyle(fontSize: 12)),
                            ),
                            Wrap(
                              spacing: 2,
                              runSpacing: 2,
                              children: selectedDays[index].keys.map((day) {
                                return FilterChip(
                                  label:
                                      Text(day, style: TextStyle(fontSize: 10)),
                                  padding: EdgeInsets.symmetric(
                                      horizontal: 4, vertical: 0),
                                  visualDensity: VisualDensity(
                                      horizontal: -4, vertical: -4),
                                  selected: selectedDays[index][day] ?? false,
                                  selectedColor:
                                      const Color.fromARGB(255, 111, 169, 45),
                                  onSelected: (val) {
                                    setState(() {
                                      selectedDays[index][day] = val;
                                    });
                                  },
                                  showCheckmark: false,
                                );
                              }).toList(),
                            ),
                          ],
                        ),
                      );
                    },
                  ),
                  SizedBox(height: 14.h),
                  CustomElevatedButton(
                    text: "Set Reminder",
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
                    onPressed: _submitAllReminders,
                  ),
                ],
              ),
            ),
          );
  }
}
