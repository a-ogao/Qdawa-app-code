import 'dart:async';
import 'dart:io';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:in_app_update/in_app_update.dart';

const _installerChannel = MethodChannel('com.quikdawa/installer');

/// Google Play Store package that installs production and test-track builds.
const _playStoreInstaller = 'com.android.vending';

/// Runs immediate in-app update when the app was installed from Play and an
/// update is available. Skips when installed via APK/sideload (installer ≠ Play).
Future<void> schedulePlayStoreInAppUpdateIfNeeded() async {
  if (kIsWeb || !Platform.isAndroid) return;

  try {
    final installer = await _installerChannel
        .invokeMethod<String?>('getInstallerPackageName');
    if (installer != _playStoreInstaller) return;
  } on PlatformException catch (e, st) {
    debugPrint('Play update: installer channel failed: $e\n$st');
    return;
  } catch (e, st) {
    debugPrint('Play update: installer check failed: $e\n$st');
    return;
  }

  try {
    final info = await InAppUpdate.checkForUpdate();
    if (info.updateAvailability != UpdateAvailability.updateAvailable) {
      return;
    }
    if (!info.immediateUpdateAllowed) {
      if (info.flexibleUpdateAllowed) {
        await _runFlexibleUpdateToCompletion();
      }
      return;
    }
    final result = await InAppUpdate.performImmediateUpdate();
    if (result == AppUpdateResult.userDeniedUpdate && kDebugMode) {
      debugPrint('Play update: user denied immediate update');
    }
  } on PlatformException catch (e, st) {
    debugPrint('Play in-app update: $e\n$st');
  } catch (e, st) {
    debugPrint('Play in-app update failed: $e\n$st');
  }
}

Future<void> _runFlexibleUpdateToCompletion() async {
  final done = Completer<void>();
  late final StreamSubscription<InstallStatus> sub;
  sub = InAppUpdate.installUpdateListener.listen((status) async {
    if (status == InstallStatus.downloaded) {
      try {
        await InAppUpdate.completeFlexibleUpdate();
      } finally {
        await sub.cancel();
        if (!done.isCompleted) done.complete();
      }
    } else if (status == InstallStatus.failed ||
        status == InstallStatus.canceled) {
      await sub.cancel();
      if (!done.isCompleted) done.complete();
    }
  });

  try {
    final start = await InAppUpdate.startFlexibleUpdate();
    if (start != AppUpdateResult.success) {
      await sub.cancel();
      return;
    }
    await done.future.timeout(
      const Duration(minutes: 30),
      onTimeout: () async {
        await sub.cancel();
      },
    );
  } catch (_) {
    await sub.cancel();
  }
}
