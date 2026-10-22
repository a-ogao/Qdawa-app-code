import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/active_patient_service.dart';

/// Builds API request bodies with optional delegated patient access.
class PatientApiContext {
  PatientApiContext._();

  static Future<Map<String, String>> body([
    Map<String, String>? extra,
  ]) async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');
    if (userDataString == null) {
      return {...?extra};
    }

    final userData = json.decode(userDataString) as Map<String, dynamic>;
    final actorId = userData['id']?.toString() ?? '';

    final service = ActivePatientService.instance;
    if (!service.initialized) {
      await service.initialize();
    }

    final effectiveId = service.effectiveUserId.toString();
    final map = <String, String>{
      'usr_id': effectiveId,
      ...?extra,
    };

    if (actorId.isNotEmpty && effectiveId != actorId) {
      map['actor_usr_id'] = actorId;
    }

    return map;
  }

  static Future<int?> actorId() async {
    final prefs = await SharedPreferences.getInstance();
    final userDataString = prefs.getString('userData');
    if (userDataString == null) return null;
    final userData = json.decode(userDataString) as Map<String, dynamic>;
    return int.tryParse(userData['id']?.toString() ?? '');
  }
}
