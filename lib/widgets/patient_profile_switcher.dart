import 'package:flutter/material.dart';
import '../../core/services/active_patient_service.dart';
import '../../presentation/patient_access/patient_access_settings_screen.dart';

class PatientProfileSwitcher extends StatelessWidget {
  final Color? foregroundColor;
  final VoidCallback? onSwitched;

  const PatientProfileSwitcher({
    Key? key,
    this.foregroundColor,
    this.onSwitched,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ActivePatientService.instance,
      builder: (context, _) {
        final service = ActivePatientService.instance;
        if (!service.initialized || service.actorUserId == null) {
          return const SizedBox.shrink();
        }

        final color = foregroundColor ?? Colors.white;
        final label = _initials(service.activeDisplayName);

        return Padding(
          padding: const EdgeInsets.only(right: 4),
          child: InkWell(
            onTap: () => _openSheet(context, service),
            borderRadius: BorderRadius.circular(20),
            child: Container(
              height: 40,
              padding: const EdgeInsets.symmetric(horizontal: 8),
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.2),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white.withOpacity(0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  CircleAvatar(
                    radius: 14,
                    backgroundColor: Colors.white,
                    child: Text(
                      label,
                      style: TextStyle(
                        color: const Color(0xFF4675C0),
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                  if (service.hasManagedPatients) ...[
                    const SizedBox(width: 2),
                    Icon(Icons.arrow_drop_down, color: color, size: 20),
                  ],
                ],
              ),
            ),
          ),
        );
      },
    );
  }

  String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.isEmpty || parts.first.isEmpty) return '?';
    if (parts.length == 1) return parts.first.substring(0, 1).toUpperCase();
    return '${parts.first.substring(0, 1)}${parts[1].substring(0, 1)}'
        .toUpperCase();
  }

  Future<void> _openSheet(
      BuildContext context, ActivePatientService service) async {
    if (!service.hasManagedPatients) {
      Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => const PatientAccessSettingsScreen(),
        ),
      );
      return;
    }

    await showModalBottomSheet<void>(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      builder: (ctx) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.fromLTRB(16, 12, 16, 16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Switch patient profile',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.w700),
                ),
                const SizedBox(height: 12),
                _profileTile(
                  ctx,
                  service,
                  id: service.actorUserId!,
                  name: '${service.actorDisplayName} (Me)',
                  subtitle: 'Your account',
                  selected: !service.isManagingOther,
                ),
                ...service.managedPatients.map(
                  (p) => _profileTile(
                    ctx,
                    service,
                    id: p.id,
                    name: p.displayName,
                    subtitle: p.mobile ?? p.email ?? p.username,
                    selected: service.activePatientId == p.id,
                  ),
                ),
                const Divider(height: 24),
                ListTile(
                  leading: const Icon(Icons.person_add_alt_1_outlined),
                  title: const Text('Manage patient access'),
                  onTap: () {
                    Navigator.pop(ctx);
                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        builder: (_) => const PatientAccessSettingsScreen(),
                      ),
                    );
                  },
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _profileTile(
    BuildContext context,
    ActivePatientService service, {
    required int id,
    required String name,
    String? subtitle,
    required bool selected,
  }) {
    return ListTile(
      contentPadding: EdgeInsets.zero,
      leading: CircleAvatar(
        backgroundColor: const Color(0xFF4675C0).withOpacity(0.15),
        child: Text(
          _initials(name),
          style: const TextStyle(
            color: Color(0xFF4675C0),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      title: Text(name),
      subtitle: subtitle != null && subtitle.isNotEmpty
          ? Text(subtitle, style: const TextStyle(fontSize: 12))
          : null,
      trailing: selected
          ? const Icon(Icons.check_circle, color: Color(0xFF4675C0))
          : null,
      onTap: () async {
        await service.switchTo(id, displayName: name.replaceAll(' (Me)', ''));
        if (context.mounted) Navigator.pop(context);
        onSwitched?.call();
      },
    );
  }
}

/// Banner shown under AppBar when managing another patient's profile.
class ManagingPatientBanner extends StatelessWidget {
  const ManagingPatientBanner({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return ListenableBuilder(
      listenable: ActivePatientService.instance,
      builder: (context, _) {
        final service = ActivePatientService.instance;
        if (!service.isManagingOther) return const SizedBox.shrink();

        return Container(
          width: double.infinity,
          color: const Color(0xFFFFF3E0),
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: Row(
            children: [
              const Icon(Icons.supervisor_account,
                  size: 18, color: Color(0xFFE65100)),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  'Managing: ${service.activeDisplayName}',
                  style: const TextStyle(
                    color: Color(0xFFE65100),
                    fontWeight: FontWeight.w600,
                    fontSize: 13,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => service.switchToSelf(),
                child: const Text('Switch to Me'),
              ),
            ],
          ),
        );
      },
    );
  }
}
