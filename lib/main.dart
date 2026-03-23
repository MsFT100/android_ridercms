import 'package:firebase_core/firebase_core.dart';
import 'package:firebase_messaging/firebase_messaging.dart';
import 'package:flutter/material.dart';
import 'package:flutter_local_notifications/flutter_local_notifications.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:ridercms/providers/notification_provider.dart';
import 'package:ridercms/screens/auth/reset_password_screen.dart';
import 'package:ridercms/screens/home/history_screen.dart';
import 'package:ridercms/screens/legal/privacy_policy.dart';
import 'package:ridercms/screens/legal/terms_of_service.dart';
import 'package:ridercms/providers/app_provider.dart';
import 'package:ridercms/providers/location_provider.dart';
import 'package:ridercms/providers/user_provider.dart';
import 'package:ridercms/screens/splash.dart';
import 'package:ridercms/screens/onboarding/onboarding_screen.dart';
import 'package:ridercms/screens/auth/login_screen.dart';
import 'package:ridercms/screens/home/main_screen.dart';
import 'package:ridercms/screens/home/map_screen.dart';
import 'package:ridercms/screens/home/charging_screen.dart';
import 'package:ridercms/screens/home/session_complete_screen.dart';
import 'package:ridercms/screens/home/slot_assigned_screen.dart';
import 'package:ridercms/services/notification_service.dart';
import 'package:ridercms/utils/constants/app_constants.dart';
import 'package:ridercms/utils/themes/app_theme.dart';


final FlutterLocalNotificationsPlugin _localNotifications = FlutterLocalNotificationsPlugin();

@pragma('vm:entry-point')
Future<void> _firebaseMessagingBackgroundHandler(RemoteMessage message) async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  const AndroidInitializationSettings androidSettings =
  AndroidInitializationSettings('@mipmap/ic_launcher');

  const InitializationSettings initSettings =
  InitializationSettings(android: androidSettings);

  await _localNotifications.initialize(initSettings);

  if (message.notification != null) {
    await _localNotifications.show(
      message.hashCode,
      message.notification!.title,
      message.notification!.body,
      const NotificationDetails(
        android: AndroidNotificationDetails(
          'payment_channel',
          'Payment Confirmations',
          channelDescription: 'Notifications for payment status updates.',
          importance: Importance.max,
          priority: Priority.high,
        ),
      ),
      payload: message.data['type'],
    );
  }
}

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Firebase.initializeApp();

  const AndroidInitializationSettings androidSettings = AndroidInitializationSettings('@mipmap/ic_launcher');
  const InitializationSettings initSettings = InitializationSettings(android: androidSettings);
  await _localNotifications.initialize(initSettings);



  FirebaseMessaging.onBackgroundMessage(_firebaseMessagingBackgroundHandler);

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiProvider(
      providers: [
        ChangeNotifierProvider(create: (_) => AppProvider()),
        ChangeNotifierProvider(create: (_) => LocationProvider()),
        ChangeNotifierProvider(create: (_) => UserProvider()),
        ChangeNotifierProvider(create: (_) => NotificationProvider()),
      ],
      child: GetMaterialApp(
        navigatorKey: NotificationService.navigatorKey,
        debugShowCheckedModeBanner: false,
        title: AppConstants.appName,
        theme: buildAppTheme(),
        themeMode: ThemeMode.system,
        initialRoute: '/',
        getPages: [
          GetPage(name: '/', page: () => const SplashScreen()),
          GetPage(name: '/onboarding', page: () => const OnboardingScreen()),
          GetPage(name: '/login', page: () => const LoginScreen()),
          GetPage(name: '/dashboard', page: () => const MainScreen()),
          GetPage(name: '/map', page: () => const MapScreen()),
          GetPage(name: '/slot-assigned', page: () => const SlotAssignedScreen()),
          GetPage(name: '/charging', page: () => const ChargingScreen()),
          GetPage(name: '/session-complete', page: () => const SessionCompleteScreen()),
          GetPage(name: '/reset-password', page: () => const ResetPasswordScreen()),
          GetPage(name: '/history', page: () => const HistoryScreen()),
          GetPage(name: '/privacy-policy', page: () => const PrivacyPolicyScreen()),
          GetPage(name: '/terms-of-service', page: () => const TermsOfServiceScreen()),
        ],
      ),
    );
  }
}
