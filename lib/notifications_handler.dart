import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';

/// Callback to handle navigation based on a route name and full payload.
typedef NavigationHandler = void Function(
    String route, Map<String, dynamic> data);

/// Reads the current authentication token (e.g., from secure storage).
typedef TokenStorage = Future<String?> Function();

/// Persists the device token for push notifications.
typedef DeviceTokenStorage = Future<void> Function(String token);

/// Configuration for NotificationService:
///
/// - [onNavigate] is called when navigation should occur; it receives a route and full payload.
/// - [loginRoute] the route name to navigate to for authentication
/// - [rootRoute] the default route after login or when no deep link is provided
/// - [readAuthToken] should return the current auth token or null.
/// - [saveDeviceToken] persists the FCM device token.
class NotificationServiceConfig {
  final NavigationHandler onNavigate;
  final String loginRoute;
  final String rootRoute;
  final TokenStorage readAuthToken;
  final DeviceTokenStorage saveDeviceToken;

  NotificationServiceConfig({
    required this.onNavigate,
    required this.loginRoute,
    required this.rootRoute,
    required this.readAuthToken,
    required this.saveDeviceToken,
  });
}

/// A reusable Firebase + local-notifications service for Flutter apps.
class NotificationService {
  final FirebaseMessaging _fbm;
  final FlutterLocalNotificationsPlugin _localNotifications;
  final NotificationServiceConfig _config;

  /// Creates a NotificationService. You can inject [firebaseMessaging] and
  /// [localNotifications] for testing; otherwise defaults to production instances.
  NotificationService(
    this._config, {
    FirebaseMessaging? firebaseMessaging,
    FlutterLocalNotificationsPlugin? localNotifications,
  })  : _fbm = firebaseMessaging ?? FirebaseMessaging.instance,
        _localNotifications =
            localNotifications ?? FlutterLocalNotificationsPlugin();

  /// Public method to handle a raw JSON payload string.
  Future<void> handlePayload(String payloadStr) async {
    await _handleNotificationClick(payloadStr);
  }

  /// Initialize the notification service:
  /// 1. Request FCM permissions
  /// 2. Set up local notifications
  /// 3. Listen for messages
  /// 4. Save device token
  /// 5. Handle initial message
  Future<void> initialize() async {
    WidgetsFlutterBinding.ensureInitialized();
    await _requestPermissions();
    await _initLocalNotifications();
    _setupFirebaseHandlers();
    await _saveDeviceToken();
    await _checkInitialMessage();
  }

  Future<void> _requestPermissions() async {
    final settings = await _fbm.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );
    debugPrint('FCM permission: ${settings.authorizationStatus}');
  }

  Future<void> _initLocalNotifications() async {
    const androidSettings =
        AndroidInitializationSettings('@mipmap/ic_launcher');
    const iosSettings = DarwinInitializationSettings();
    const initSettings = InitializationSettings(
      android: androidSettings,
      iOS: iosSettings,
    );
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (resp) {
        if (resp.payload != null) {
          _handleNotificationClick(resp.payload!);
        }
      },
    );
  }

  void _setupFirebaseHandlers() {
    FirebaseMessaging.onMessage.listen((msg) {
      if (msg.notification != null) {
        _showLocalNotification(msg);
      }
    });
    FirebaseMessaging.onMessageOpenedApp.listen((msg) {
      if (msg.data.isNotEmpty) {
        _handleNotificationClick(json.encode(msg.data));
      }
    });
  }

  Future<void> _checkInitialMessage() async {
    final initial = await _fbm.getInitialMessage();
    if (initial?.data.isNotEmpty == true) {
      _handleNotificationClick(json.encode(initial!.data));
    }
  }

  Future<void> _saveDeviceToken() async {
    try {
      final token = await _fbm.getToken();
      if (token != null) {
        await _config.saveDeviceToken(token);
        debugPrint('New FCM token saved: $token');
      }
    } catch (e) {
      debugPrint('Error saving token: $e');
    }
  }

  Future<void> _showLocalNotification(RemoteMessage message) async {
    const androidDetails = AndroidNotificationDetails(
      'high_importance',
      'High Importance Notifications',
      channelDescription: 'Important notifications',
      importance: Importance.max,
      priority: Priority.high,
    );
    const details = NotificationDetails(android: androidDetails);
    await _localNotifications.show(
      message.hashCode,
      message.notification?.title,
      message.notification?.body,
      details,
      payload: json.encode(message.data),
    );
  }

  /// Parses payload and routes accordingly.
  Future<void> _handleNotificationClick(String payloadStr) async {
    final Map<String, dynamic> payload = json.decode(payloadStr);

    // Check authentication
    final authToken = await _config.readAuthToken();
    final bool isAuthenticated = authToken != null && authToken.isNotEmpty;

    if (!isAuthenticated) {
      _config.onNavigate(_config.loginRoute, payload);
      return;
    }

    // Determine target route: deep link or default root
    final String target = (payload['screen'] as String?) ?? _config.rootRoute;

    // Navigate
    _config.onNavigate(target, payload);
  }
}
