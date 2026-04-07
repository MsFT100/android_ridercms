import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:ridercms/controllers/charging_controller.dart';
import 'package:ridercms/controllers/permission_controller.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../utils/enums/enums.dart';
import '../utils/themes/app_theme.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({super.key});

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {
  // Use Get.find since it's now in InitialBinding
  late final ChargingController chargingController;

  @override
  void initState() {
    super.initState();
    Get.put(PermissionController());
    // Get the controller from InitialBinding instead of putting it here
    chargingController = Get.find<ChargingController>();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // Minimum splash duration for branding
    await Future.delayed(const Duration(seconds: 2));

    if (!mounted) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    // Wait while Firebase is still working — covers both uninitialized AND authenticating
    int timeout = 0;
    while (
    (userProvider.status == Status.uninitialized ||
        userProvider.status == Status.authenticating) &&
        timeout < 20 // 10 seconds max
    ) {
      await Future.delayed(const Duration(milliseconds: 500));
      timeout++;
    }

    if (!mounted) return;

    final prefs = await SharedPreferences.getInstance();
    final bool onboardingDone = prefs.getBool('onboarding_done') ?? false;

    if (userProvider.status == Status.authenticated) {
      // PROMPT FIX: Check for active session BEFORE navigating to dashboard
      // to avoid flickering from Dashboard to Charging screen.
      final ActiveSessionType sessionType = await chargingController.checkSessionStatus();
      
      if (sessionType == ActiveSessionType.payment) {
        Get.offAllNamed('/payment');
      } else if (sessionType == ActiveSessionType.charging) {
        Get.offAllNamed('/charging');
      } else {
        Get.offAllNamed('/dashboard');
      }
    } else {
      if (onboardingDone) {
        Get.offAllNamed('/login');
      } else {
        Get.offAllNamed('/onboarding');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBgDark, kBgDark2],
          ),
        ),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: kPrimary.withValues(alpha: 0.1),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bolt,
                  size: 80,
                  color: kPrimary,
                ),
              ),
              const SizedBox(height: 24),
              const Text(
                'RIDERCMS',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 32,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 4,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Powering your journey',
                style: TextStyle(
                  color: kTextSecondary,
                  fontSize: 14,
                  letterSpacing: 1.2,
                ),
              ),
              const SizedBox(height: 48),
              const CircularProgressIndicator(
                valueColor: AlwaysStoppedAnimation<Color>(kPrimary),
                strokeWidth: 3,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
