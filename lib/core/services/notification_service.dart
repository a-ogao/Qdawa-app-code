import 'package:onesignal_flutter/onesignal_flutter.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'dart:io';
import 'package:device_info_plus/device_info_plus.dart';
import '../config/app_config.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:flutter/material.dart';

class NotificationService {
  static bool _isInitialized = false;
  static String? _currentAuthToken;

  /// Initialize OneSignal SDK
  static Future<void> initialize() async {
    if (_isInitialized) {
      print('OneSignal already initialized');
      return;
    }

    try {
      // Initialize OneSignal
      OneSignal.Debug.setLogLevel(OSLogLevel.verbose);
      OneSignal.initialize(AppConfig.oneSignalAppId);

      // Set up notification click handler
      OneSignal.Notifications.addClickListener((event) {
        _handleNotificationClick(event.notification);
      });

      _isInitialized = true;
      print('✅ OneSignal initialized successfully');
    } catch (e) {
      print('❌ Error initializing OneSignal: $e');
    }
  }

  /// Request notification permission and register device after login
  static Future<void> requestPermissionAndRegister(String authToken, {BuildContext? context}) async {
    _currentAuthToken = authToken;

    try {
      print('🔔 Requesting notification permission...');
      
      // Request permission for notifications
      final permission = await OneSignal.Notifications.requestPermission(true);

      if (permission) {
        print('✅ Notification permission granted');
        
        // Show loading dialog after permission is granted
        if (context != null && context.mounted) {
          showDialog(
            context: context,
            barrierDismissible: false,
            builder: (BuildContext dialogContext) {
              return Dialog(
                backgroundColor: Colors.transparent,
                elevation: 0,
                child: Container(
                  padding: EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(16),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withOpacity(0.1),
                        blurRadius: 20,
                        offset: Offset(0, 10),
                      ),
                    ],
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      CircularProgressIndicator(
                        valueColor: AlwaysStoppedAnimation<Color>(Color(0XFF4675C0)),
                        strokeWidth: 3,
                      ),
                      SizedBox(height: 20),
                      Text(
                        'Setting up notifications...',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                          color: Colors.black87,
                        ),
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Please wait',
                        style: TextStyle(
                          fontSize: 14,
                          color: Colors.grey[600],
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        }
        
        // Set up observer AFTER we have auth token
        OneSignal.User.pushSubscription.addObserver((state) {
          print('📱 Push subscription changed: ${state.current.id}');
          if (state.current.id != null && _currentAuthToken != null) {
            print('🔄 Observer triggered - registering device...');
            registerDevice(state.current.id!, _currentAuthToken!);
          }
        });
        
        try {
          // Wait longer for Player ID to be available (OneSignal needs time)
          print('⏳ Waiting for Player ID...');
          await Future.delayed(Duration(seconds: 2));
          
          // Get the Player ID
          final playerId = OneSignal.User.pushSubscription.id;
          
          print('📱 Player ID check: $playerId');
          
          if (playerId != null && playerId.isNotEmpty) {
            print('✅ Player ID obtained: $playerId');
            await registerDevice(playerId, authToken);
          } else {
            print('⚠️ Player ID not available yet, waiting for observer...');
            
            // Retry mechanism - check again after another delay
            await Future.delayed(Duration(seconds: 2));
            final retryPlayerId = OneSignal.User.pushSubscription.id;
            
            if (retryPlayerId != null && retryPlayerId.isNotEmpty) {
              print('✅ Player ID obtained on retry: $retryPlayerId');
              await registerDevice(retryPlayerId, authToken);
            } else {
              print('⚠️ Player ID still not available. Observer will handle registration when available.');
              // The observer will handle registration when Player ID becomes available
            }
          }
        } finally {
          // Close loading dialog
          if (context != null && context.mounted) {
            Navigator.of(context, rootNavigator: true).pop();
          }
        }
      } else {
        print('❌ Notification permission denied');
      }
    } catch (e) {
      print('❌ Error requesting notification permission: $e');
      // Close loading dialog if still open
      if (context != null && context.mounted) {
        Navigator.of(context, rootNavigator: true).pop();
      }
    }
  }

  /// Register device with backend API
  static Future<bool> registerDevice(String playerId, String authToken) async {
    try {
      print('📱 ===== REGISTERING DEVICE WITH BACKEND =====');
      print('Player ID: $playerId');
      print('Auth Token length: ${authToken.length}');
      print('Auth Token preview: ${authToken.substring(0, authToken.length > 20 ? 20 : authToken.length)}...');
      
      // Get user ID from SharedPreferences
      final prefs = await SharedPreferences.getInstance();
      final String? userDataString = prefs.getString('userData');
      
      if (userDataString == null) {
        print('❌ User data not found in SharedPreferences');
        return false;
      }
      
      final Map<String, dynamic> userData = jsonDecode(userDataString);
      final int? userId = userData['id'];
      
      if (userId == null) {
        print('❌ User ID not found in userData');
        return false;
      }
      
      print('User ID: $userId');
      
      final deviceName = await _getDeviceName();
      final deviceType = Platform.isAndroid ? 'android' : (Platform.isIOS ? 'ios' : 'web');

      print('Device Type: $deviceType');
      print('Device Name: $deviceName');
      
      // The register_device endpoint requires /api/ prefix
      final apiUrl = '${AppConfig.baseApiUrl}/api/register_device';
      print('API URL: $apiUrl');
      
      final requestBody = {
        'player_id': playerId,
        'usr_id': userId,
        'device_type': deviceType,
        'device_name': deviceName,
      };
      
      print('Request Body: ${jsonEncode(requestBody)}');
      print('Request Headers: Authorization: Bearer [token], Content-Type: application/json');

      print('🚀 Sending HTTP POST request...');
      final response = await http.post(
        Uri.parse(apiUrl),
        headers: {
          'Authorization': 'Bearer $authToken',
          'Content-Type': 'application/json',
          'Accept': 'application/json',
        },
        body: jsonEncode(requestBody),
      ).timeout(
        Duration(seconds: 30),
        onTimeout: () {
          throw Exception('Request timeout after 30 seconds');
        },
      );

      print('📱 Register device response received!');
      print('Status Code: ${response.statusCode}');
      print('Response Headers: ${response.headers}');
      print('Response body: ${response.body}');

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        if (data['success'] == true) {
          print('✅ Device registered successfully: ${data['message']}');
          print('Device ID: ${data['device_id']}');
          
          // Save registration status (prefs already obtained earlier)
          await prefs.setString('onesignal_player_id', playerId);
          await prefs.setBool('device_registered', true);
          
          return true;
        } else {
          print('❌ Device registration failed: ${data['message']}');
          return false;
        }
      } else if (response.statusCode == 401) {
        print('❌ Unauthorized: Invalid auth token');
        return false;
      } else {
        print('❌ Failed to register device: ${response.statusCode}');
        print('Response: ${response.body}');
        return false;
      }
    } catch (e) {
      print('❌ Error registering device: $e');
      print('Stack trace: ${StackTrace.current}');
      return false;
    }
  }

  /// Get device name/model
  static Future<String> _getDeviceName() async {
    try {
      final deviceInfo = DeviceInfoPlugin();
      if (Platform.isAndroid) {
        final androidInfo = await deviceInfo.androidInfo;
        return '${androidInfo.manufacturer} ${androidInfo.model}';
      } else if (Platform.isIOS) {
        final iosInfo = await deviceInfo.iosInfo;
        return '${iosInfo.name} ${iosInfo.model}';
      }
    } catch (e) {
      print('Error getting device name: $e');
    }
    return Platform.isAndroid ? 'Android Device' : (Platform.isIOS ? 'iOS Device' : 'Web Device');
  }

  /// Handle notification click events
  static void _handleNotificationClick(OSNotification notification) {
    final data = notification.additionalData;
    
    print('🔔 Notification clicked');
    print('Title: ${notification.title}');
    print('Body: ${notification.body}');
    print('Additional Data: $data');

    if (data != null) {
      final type = data['type'];
      final orderId = data['order_id'];
      final quotationId = data['quotation_id'];
      
      print('Notification type: $type');
      print('Order ID: $orderId');
      print('Quotation ID: $quotationId');
      
      // Store notification data for navigation
      // Navigation will be handled by the app's navigation system
      // You can use a global navigator key or event bus here
      _storeNotificationData(data);
    }
  }

  /// Store notification data for later navigation
  static Future<void> _storeNotificationData(Map<String, dynamic> data) async {
    try {
      final prefs = await SharedPreferences.getInstance();
      await prefs.setString('pending_notification', jsonEncode(data));
    } catch (e) {
      print('Error storing notification data: $e');
    }
  }

  /// Get pending notification data and clear it
  static Future<Map<String, dynamic>?> getPendingNotification() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final dataString = prefs.getString('pending_notification');
      if (dataString != null) {
        await prefs.remove('pending_notification');
        return jsonDecode(dataString) as Map<String, dynamic>;
      }
      return null;
    } catch (e) {
      print('Error getting pending notification: $e');
      return null;
    }
  }

  /// Re-register device when token is refreshed
  static Future<void> reRegisterDevice(String newAuthToken) async {
    _currentAuthToken = newAuthToken;
    
    final prefs = await SharedPreferences.getInstance();
    final playerId = prefs.getString('onesignal_player_id');
    
    if (playerId != null && playerId.isNotEmpty) {
      await registerDevice(playerId, newAuthToken);
    } else {
      // Wait for Player ID if not available
      await Future.delayed(Duration(seconds: 2));
      final currentPlayerId = OneSignal.User.pushSubscription.id;
      if (currentPlayerId != null && currentPlayerId.isNotEmpty) {
        await registerDevice(currentPlayerId, newAuthToken);
      }
    }
  }

  /// Check if device is already registered
  static Future<bool> isDeviceRegistered() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      return prefs.getBool('device_registered') ?? false;
    } catch (e) {
      return false;
    }
  }

  /// Get current Player ID
  static String? getPlayerId() {
    return OneSignal.User.pushSubscription.id;
  }
}

