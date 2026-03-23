import 'dart:convert';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:provider/provider.dart';
import '../providers/notification_provider.dart';
import 'auth_service.dart';

class NotificationService {
  // A GlobalKey for navigation from anywhere.
  static final GlobalKey<NavigatorState> navigatorKey = GlobalKey<NavigatorState>();

  final FirebaseMessaging _firebaseMessaging = FirebaseMessaging.instance;
  final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();
  final AuthService _authService = AuthService();

  Future<void> initialize() async {
    // 1. Request Permissions
    await _firebaseMessaging.requestPermission(
      alert: true,
      badge: true,
      sound: true,
    );

    // 2. Get FCM Token and sync with backend if user is logged in
    final String? fcmToken = await _firebaseMessaging.getToken();
    if (kDebugMode) {
      print("FCM Token: $fcmToken");
    }
    
    if (fcmToken != null) {
      await _authService.updateFcmToken(fcmToken);
    }

    // 3. Initialize Local Notifications
    const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
    const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
    await _localNotifications.initialize(
      initSettings,
      onDidReceiveNotificationResponse: (response) {
        if (response.payload != null && response.payload!.isNotEmpty) {
          final Map<String, dynamic> data = jsonDecode(response.payload!);
          _handleNotificationAction(data, null);
        }
      },
    );

    // 4. Set up listeners
    _setupListeners();

    // 5. Handle initial message if app was opened from a terminated state
    RemoteMessage? initialMessage = await _firebaseMessaging.getInitialMessage();
    if (initialMessage != null) {
      _handleNotificationAction(initialMessage.data, initialMessage);
    }
  }

  void _setupListeners() {
    // Listen for token refreshes
    _firebaseMessaging.onTokenRefresh.listen((newToken) {
      _authService.updateFcmToken(newToken);
    });

    // --- Handles messages when the app is in the FOREGROUND ---
    FirebaseMessaging.onMessage.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Foreground message received: ${message.notification?.title}');
      }

      _saveNotificationToProvider(message);
      _handleNotificationAction(message.data, message);

      if (message.notification != null) {
        _showLocalNotification(message);
      }
    });

    // --- Handles when a user TAPS a notification and the app opens from the BACKGROUND ---
    FirebaseMessaging.onMessageOpenedApp.listen((RemoteMessage message) {
      if (kDebugMode) {
        print('Message opened from background');
      }
      _saveNotificationToProvider(message);
      _handleNotificationAction(message.data, message);
    });
  }

  void _saveNotificationToProvider(RemoteMessage message) {
    final context = navigatorKey.currentContext;
    if (context == null) return;

    final notificationProvider = Provider.of<NotificationProvider>(context, listen: false);
    
    notificationProvider.addNotification(
      NotificationModel(
        id: message.messageId ?? DateTime.now().millisecondsSinceEpoch.toString(),
        title: message.notification?.title ?? 'Notification',
        body: message.notification?.body ?? '',
        timestamp: DateTime.now(),
        type: message.data['type'] ?? 'DEFAULT',
        isRead: false,
      ),
    );
  }

  void _showLocalNotification(RemoteMessage message) {
    const AndroidNotificationDetails androidDetails = AndroidNotificationDetails(
      'payment_channel',
      'Payment Confirmations',
      channelDescription: 'Notifications for payment status updates.',
      importance: Importance.max,
      priority: Priority.high,
    );
    const NotificationDetails notificationDetails = NotificationDetails(android: androidDetails);

    Map<String, dynamic> payloadData = {
      'type': message.data['type'],
      'body': message.notification?.body,
    };

    _localNotifications.show(
      message.hashCode,
      message.notification!.title,
      message.notification!.body,
      notificationDetails,
      payload: jsonEncode(payloadData),
    );
  }

  void _handleNotificationAction(Map<String, dynamic> data, RemoteMessage? remoteMessage) {
    final String? type = data['type'];
    final context = navigatorKey.currentContext;

    if (context == null) return;

    switch (type) {
      case 'payment_success':
        // Navigate to session complete or refresh data
        break;
      default:
        if (kDebugMode) {
          print('Received unhandled notification type: $type');
        }
    }
  }

  /// Manually sync token (useful after login)
  Future<void> syncToken() async {
    final String? token = await _firebaseMessaging.getToken();
    if (token != null) {
      await _authService.updateFcmToken(token);
    }
  }

  /// Clear token on logout
  Future<void> clearToken() async {
    await _authService.updateFcmToken(null);
  }
}
