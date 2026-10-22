import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';

class ManagedPatientProfile {
  final int id;
  final String displayName;
  final String? username;
  final String? email;
  final String? mobile;

  ManagedPatientProfile({
    required this.id,
    required this.displayName,
    this.username,
    this.email,
    this.mobile,
  });

  factory ManagedPatientProfile.fromJson(Map<String, dynamic> json) {
    return ManagedPatientProfile(
      id: int.tryParse(json['id']?.toString() ?? '') ?? 0,
      displayName: (json['display_name'] ?? json['usr_username'] ?? 'Patient')
          .toString(),
      username: json['usr_username']?.toString(),
      email: json['usr_email']?.toString(),
      mobile: json['usr_mobile_number']?.toString(),
    );
  }

  String get initials {
    final parts = displayName.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }
}

/// Tracks the logged-in patient (actor) and the active profile (self or linked).
class ActivePatientService extends ChangeNotifier {
  ActivePatientService._();
  static final ActivePatientService instance = ActivePatientService._();

  int? _actorUserId;
  String _actorDisplayName = 'Me';
  int? _activePatientId;
  String _activeDisplayName = 'Me';
  List<ManagedPatientProfile> _managedPatients = [];
  bool _initialized = false;

  int? get actorUserId => _actorUserId;
  String get actorDisplayName => _actorDisplayName;
  int? get activePatientId => _activePatientId;
  String get activeDisplayName => _activeDisplayName;
  List<ManagedPatientProfile> get managedPatients =>
      List.unmodifiable(_managedPatients);
  bool get isManagingOther =>
      _actorUserId != null &&
      _activePatientId != null &&
      _actorUserId != _activePatientId;
  bool get hasManagedPatients => _managedPatients.isNotEmpty;
  bool get initialized => _initialized;

  int get effectiveUserId => _activePatientId ?? _actorUserId ?? 0;

  Future<void> initialize() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');
    if (userDataString == null) return;

    final userData = json.decode(userDataString) as Map<String, dynamic>;
    _actorUserId = int.tryParse(userData['id']?.toString() ?? '');
    _actorDisplayName = (userData['usr_first_name'] ??
            userData['usr_username'] ??
            'Me')
        .toString();

    final savedActive = prefs.getInt('active_patient_id');
    _activePatientId = savedActive ?? _actorUserId;
    _activeDisplayName = _actorDisplayName;
    _initialized = true;

    await refreshManagedPatients();
    _syncActiveDisplayName();
    notifyListeners();
  }

  Future<void> refreshManagedPatients() async {
    if (_actorUserId == null) return;

    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('patient_access_managed')),
        body: {'usr_id': _actorUserId.toString()},
      );

      if (response.statusCode == 200) {
        final data = json.decode(response.body) as Map<String, dynamic>;
        if (data['success'] == true && data['data'] is List) {
          _managedPatients = (data['data'] as List)
              .map((e) =>
                  ManagedPatientProfile.fromJson(e as Map<String, dynamic>))
              .where((p) => p.id > 0)
              .toList();
        }
      }
    } catch (e) {
      debugPrint('refreshManagedPatients error: $e');
    }

    await _validateActivePatient();
    _syncActiveDisplayName();
    notifyListeners();
  }

  Future<void> switchTo(int patientId, {String? displayName}) async {
    if (_actorUserId == null) return;

    if (patientId == _actorUserId) {
      await switchToSelf();
      return;
    }

    final allowed = _managedPatients.any((p) => p.id == patientId);
    if (!allowed) return;

    _activePatientId = patientId;
    _activeDisplayName = displayName ??
        _managedPatients.firstWhere((p) => p.id == patientId).displayName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_patient_id', patientId);
    notifyListeners();
  }

  Future<void> switchToSelf() async {
    if (_actorUserId == null) return;
    _activePatientId = _actorUserId;
    _activeDisplayName = _actorDisplayName;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt('active_patient_id', _actorUserId!);
    notifyListeners();
  }

  Future<void> clear() async {
    _actorUserId = null;
    _activePatientId = null;
    _managedPatients = [];
    _initialized = false;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('active_patient_id');
    notifyListeners();
  }

  Future<void> _validateActivePatient() async {
    if (_actorUserId == null || _activePatientId == null) return;
    if (_activePatientId == _actorUserId) return;

    final stillAllowed =
        _managedPatients.any((p) => p.id == _activePatientId);
    if (!stillAllowed) {
      _activePatientId = _actorUserId;
      final prefs = await SharedPreferences.getInstance();
      await prefs.setInt('active_patient_id', _actorUserId!);
    }
  }

  void _syncActiveDisplayName() {
    if (_actorUserId == null || _activePatientId == null) return;
    if (_activePatientId == _actorUserId) {
      _activeDisplayName = _actorDisplayName;
      return;
    }
    final match =
        _managedPatients.where((p) => p.id == _activePatientId).toList();
    if (match.isNotEmpty) {
      _activeDisplayName = match.first.displayName;
    }
  }
}
