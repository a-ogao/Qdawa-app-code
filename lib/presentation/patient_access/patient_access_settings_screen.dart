import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:http/http.dart' as http;
import '../../core/app_export.dart';
import '../../core/config/app_config.dart';
import '../../core/services/active_patient_service.dart';
import '../../core/utils/patient_api_context.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';

class PatientAccessSettingsScreen extends StatefulWidget {
  const PatientAccessSettingsScreen({Key? key}) : super(key: key);

  @override
  State<PatientAccessSettingsScreen> createState() =>
      _PatientAccessSettingsScreenState();
}

class _PatientAccessSettingsScreenState
    extends State<PatientAccessSettingsScreen> {
  final _identifierController = TextEditingController();
  final _codeController = TextEditingController();
  bool _loading = false;
  String? _generatedCode;
  String? _codeExpires;
  List<dynamic> _grantees = [];
  List<dynamic> _managed = [];
  List<dynamic> _history = [];

  static const Color _primaryColor = Color(0xFF4675C0);

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  @override
  void dispose() {
    _identifierController.dispose();
    _codeController.dispose();
    super.dispose();
  }

  Future<int?> _actorId() => PatientApiContext.actorId();

  InputDecoration _fieldDecoration(String label) {
    return InputDecoration(
      labelText: label,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.h),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.h),
        borderSide: BorderSide(color: Colors.grey.shade300),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16.h),
        borderSide: const BorderSide(color: _primaryColor, width: 1.5),
      ),
      filled: true,
      fillColor: Colors.white,
      contentPadding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 14.h),
    );
  }

  Future<void> _loadData() async {
    final actorId = await _actorId();
    if (actorId == null) return;

    setState(() => _loading = true);
    try {
      final granteesRes = await http.post(
        Uri.parse(AppConfig.buildApiUrl('patient_access_grantees')),
        body: {'usr_id': actorId.toString()},
      );
      final managedRes = await http.post(
        Uri.parse(AppConfig.buildApiUrl('patient_access_managed')),
        body: {'usr_id': actorId.toString()},
      );
      final historyRes = await http.post(
        Uri.parse(AppConfig.buildApiUrl('patient_access_history')),
        body: {'usr_id': actorId.toString()},
      );

      if (mounted) {
        setState(() {
          if (granteesRes.statusCode == 200) {
            final d = json.decode(granteesRes.body);
            _grantees = d['data'] ?? [];
          }
          if (managedRes.statusCode == 200) {
            final d = json.decode(managedRes.body);
            _managed = d['data'] ?? [];
          }
          if (historyRes.statusCode == 200) {
            final d = json.decode(historyRes.body);
            _history = d['data'] ?? [];
          }
          _loading = false;
        });
      }
      await ActivePatientService.instance.refreshManagedPatients();
    } catch (e) {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _generateCode() async {
    final actorId = await _actorId();
    if (actorId == null) return;

    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('patient_access_generate_code')),
        body: {'usr_id': actorId.toString()},
      );
      if (!mounted) return;
      if (response.statusCode != 200 ||
          !(response.body.trim().startsWith('{') ||
              response.body.trim().startsWith('['))) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'Server error (${response.statusCode}). Please try again.',
            ),
            backgroundColor: Colors.red,
          ),
        );
        return;
      }
      final data = json.decode(response.body);
      if (data['success'] == true) {
        setState(() {
          _generatedCode = data['code']?.toString();
          _codeExpires = data['expires_at']?.toString();
        });
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: const Text(
              'Approval code generated. Share it securely.',
            ),
            backgroundColor: _primaryColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              data['message']?.toString() ?? 'Failed to generate code',
            ),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _linkPatient() async {
    final actorId = await _actorId();
    if (actorId == null) return;

    if (_identifierController.text.trim().isEmpty ||
        _codeController.text.trim().isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Enter patient identifier and approval code'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('patient_access_link')),
        body: {
          'usr_id': actorId.toString(),
          'identifier': _identifierController.text.trim(),
          'approval_code': _codeController.text.trim(),
        },
      );
      final data = json.decode(response.body);
      if (!mounted) return;
      if (data['success'] == true) {
        _identifierController.clear();
        _codeController.clear();
        await _loadData();
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']?.toString() ?? 'Linked successfully'),
            backgroundColor: _primaryColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']?.toString() ?? 'Link failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Error: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _revoke(int otherId, String mode) async {
    final actorId = await _actorId();
    if (actorId == null) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        title: const Text('Remove access?'),
        content: const Text('This will revoke delegated access immediately.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: Text('Cancel', style: TextStyle(color: Colors.grey[700])),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text(
              'Remove',
              style: TextStyle(
                color: Colors.red,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
    if (confirmed != true) return;

    setState(() => _loading = true);
    try {
      final response = await http.post(
        Uri.parse(AppConfig.buildApiUrl('patient_access_revoke')),
        body: {
          'usr_id': actorId.toString(),
          'other_usr_id': otherId.toString(),
          'mode': mode,
        },
      );
      final data = json.decode(response.body);
      if (!mounted) return;
      if (data['success'] == true) {
        await _loadData();
        if (ActivePatientService.instance.activePatientId == otherId) {
          await ActivePatientService.instance.switchToSelf();
        }
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Access removed'),
            backgroundColor: _primaryColor,
          ),
        );
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(data['message']?.toString() ?? 'Failed'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey[50],
      appBar: AppBar(
        elevation: 0,
        backgroundColor: _primaryColor,
        foregroundColor: Colors.white,
        title: const Text(
          'Patient Access',
          style: TextStyle(
            fontSize: 22,
            fontWeight: FontWeight.w700,
          ),
        ),
        shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(bottom: Radius.circular(20)),
        ),
      ),
      body: Stack(
        children: [
          RefreshIndicator(
            color: _primaryColor,
            onRefresh: _loadData,
            child: ListView(
              padding: EdgeInsets.fromLTRB(16.h, 20.h, 16.h, 24.h),
              children: [
                _buildSectionCard(
                  title: 'Share access',
                  subtitle:
                      'Generate a code and share it with someone who should manage your profile.',
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      CustomElevatedButton(
                        height: 50.h,
                        text: 'Generate approval code',
                        buttonStyle: CustomButtonStyles.fillPrimary,
                        isDisabled: _loading,
                        leftIcon: Padding(
                          padding: EdgeInsets.only(right: 8.h),
                          child: Icon(
                            Icons.vpn_key_outlined,
                            color: Colors.white,
                            size: 20.h,
                          ),
                        ),
                        onPressed: _generateCode,
                      ),
                      if (_generatedCode != null) ...[
                        SizedBox(height: 16.h),
                        Container(
                          padding: EdgeInsets.all(16.h),
                          decoration: BoxDecoration(
                            color: _primaryColor.withValues(alpha: 0.08),
                            borderRadius: BorderRadius.circular(16.h),
                            border: Border.all(
                              color: _primaryColor.withValues(alpha: 0.2),
                            ),
                          ),
                          child: Row(
                            children: [
                              Expanded(
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    Text(
                                      _generatedCode!,
                                      style: TextStyle(
                                        fontSize: 28.h,
                                        fontWeight: FontWeight.bold,
                                        letterSpacing: 4,
                                        color: _primaryColor,
                                      ),
                                    ),
                                    SizedBox(height: 4.h),
                                    Text(
                                      'Expires: ${_codeExpires ?? '30 min'}',
                                      style: TextStyle(
                                        fontSize: 12.h,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  Clipboard.setData(
                                    ClipboardData(text: _generatedCode!),
                                  );
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: const Text('Code copied'),
                                      backgroundColor: _primaryColor,
                                    ),
                                  );
                                },
                                icon: Icon(Icons.copy, color: _primaryColor),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                _buildSectionCard(
                  title: 'Add patient to manage',
                  subtitle:
                      'Enter another patient\'s username, email, or phone and their approval code.',
                  child: Column(
                    children: [
                      TextField(
                        controller: _identifierController,
                        decoration: _fieldDecoration(
                          'Username / email / phone',
                        ),
                      ),
                      SizedBox(height: 12.h),
                      TextField(
                        controller: _codeController,
                        keyboardType: TextInputType.number,
                        decoration: _fieldDecoration('Approval code'),
                      ),
                      SizedBox(height: 16.h),
                      CustomElevatedButton(
                        height: 50.h,
                        text: 'Link patient profile',
                        buttonStyle: CustomButtonStyles.fillPrimary,
                        isDisabled: _loading,
                        onPressed: _linkPatient,
                      ),
                    ],
                  ),
                ),
                SizedBox(height: 16.h),
                _buildSectionCard(
                  title: 'Who can manage me',
                  child: _grantees.isEmpty
                      ? _emptyHint('No one has access to your profile.')
                      : Column(
                          children: _grantees
                              .map((g) => _personTile(
                                    name: g['display_name']?.toString() ??
                                        'Patient',
                                    subtitle:
                                        g['usr_mobile_number']?.toString() ??
                                            '',
                                    onRemove: () => _revoke(
                                      int.parse(g['id'].toString()),
                                      'grantor_revokes',
                                    ),
                                  ))
                              .toList(),
                        ),
                ),
                SizedBox(height: 16.h),
                _buildSectionCard(
                  title: 'Patients I manage',
                  child: _managed.isEmpty
                      ? _emptyHint(
                          'You are not managing any other patient yet.',
                        )
                      : Column(
                          children: _managed
                              .map((g) => _personTile(
                                    name: g['display_name']?.toString() ??
                                        'Patient',
                                    subtitle:
                                        g['usr_mobile_number']?.toString() ??
                                            '',
                                    onRemove: () => _revoke(
                                      int.parse(g['id'].toString()),
                                      'grantee_revokes',
                                    ),
                                  ))
                              .toList(),
                        ),
                ),
                SizedBox(height: 16.h),
                _buildSectionCard(
                  title: 'Access history',
                  child: _history.isEmpty
                      ? _emptyHint('No history yet.')
                      : Column(
                          children: _history
                              .take(20)
                              .map((h) => ListTile(
                                    contentPadding: EdgeInsets.zero,
                                    dense: true,
                                    title: Text(
                                      h['display_name']?.toString() ?? '',
                                      style: TextStyle(
                                        fontSize: 14.h,
                                        fontWeight: FontWeight.w500,
                                      ),
                                    ),
                                    subtitle: Text(
                                      '${h['direction'] ?? ''} • ${h['pal_status'] ?? ''} • ${h['pal_granted_at'] ?? ''}',
                                      style: TextStyle(
                                        fontSize: 11.h,
                                        color: Colors.grey[600],
                                      ),
                                    ),
                                  ))
                              .toList(),
                        ),
                ),
              ],
            ),
          ),
          if (_loading)
            Container(
              color: Colors.black.withValues(alpha: 0.08),
              child: const Center(
                child: CircularProgressIndicator(
                  valueColor: AlwaysStoppedAnimation<Color>(_primaryColor),
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildSectionCard({
    required String title,
    String? subtitle,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Container(
            width: double.infinity,
            padding: EdgeInsets.symmetric(horizontal: 16.h, vertical: 14.h),
            decoration: const BoxDecoration(
              color: _primaryColor,
              borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
            ),
            child: Text(
              title,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: Colors.white,
                fontSize: 16.h,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
          Padding(
            padding: EdgeInsets.all(16.h),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (subtitle != null) ...[
                  Text(
                    subtitle,
                    style: TextStyle(
                      color: Colors.grey[600],
                      fontSize: 13.h,
                      height: 1.4,
                    ),
                  ),
                  SizedBox(height: 16.h),
                ],
                child,
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _emptyHint(String text) {
    return Padding(
      padding: EdgeInsets.symmetric(vertical: 8.h),
      child: Text(
        text,
        style: TextStyle(color: Colors.grey[600], fontSize: 14.h),
      ),
    );
  }

  Widget _personTile({
    required String name,
    required String subtitle,
    required VoidCallback onRemove,
  }) {
    return Container(
      margin: EdgeInsets.only(bottom: 8.h),
      padding: EdgeInsets.symmetric(horizontal: 12.h, vertical: 8.h),
      decoration: BoxDecoration(
        color: Colors.grey[50],
        borderRadius: BorderRadius.circular(12.h),
      ),
      child: Row(
        children: [
          CircleAvatar(
            radius: 20.h,
            backgroundColor: _primaryColor.withValues(alpha: 0.12),
            child: Text(
              name.isNotEmpty ? name[0].toUpperCase() : '?',
              style: TextStyle(
                color: _primaryColor,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          SizedBox(width: 12.h),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  name,
                  style: TextStyle(
                    fontSize: 15.h,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                if (subtitle.isNotEmpty)
                  Text(
                    subtitle,
                    style: TextStyle(fontSize: 12.h, color: Colors.grey[600]),
                  ),
              ],
            ),
          ),
          IconButton(
            onPressed: _loading ? null : onRemove,
            icon: Icon(Icons.remove_circle_outline, color: Colors.red[400]),
          ),
        ],
      ),
    );
  }
}
