import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
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
  @override
  void initState() {
    super.initState();
    Get.put(PermissionController());
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    // 1. Minimum splash time
    await Future.delayed(const Duration(seconds: 2));
    
    if (!mounted) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    // 2. Wait for UserProvider to finish its initialization (Firebase check)
    // If it's still uninitialized, wait a bit longer
    int timeout = 0;
    while (userProvider.status == Status.uninitialized && timeout < 10) {
      await Future.delayed(const Duration(milliseconds: 500));
      timeout++;
    }

    final prefs = await SharedPreferences.getInstance();
    final bool onboardingDone = prefs.getBool('onboarding_done') ?? false;

    if (kDebugMode) {
      print("ONBOARDING_DONE: $onboardingDone");
    }
    // 3. Navigation Logic
    if (userProvider.status == Status.authenticated) {
      Get.offAllNamed('/dashboard');
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
