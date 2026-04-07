import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../utils/themes/app_theme.dart';

class ProfileController extends GetxController {
  void showLogoutConfirmation(BuildContext context) {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    Get.dialog(
      AlertDialog(
        backgroundColor: kBgCard,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text(
          "Logout",
          style: TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold),
        ),
        content: const Text(
          "Are you sure you want to log out of your account?",
          style: TextStyle(color: kTextSecondary),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text("Cancel", style: TextStyle(color: kTextSecondary)),
          ),
          TextButton(
            onPressed: () async {
              Get.back(); // Close confirmation dialog
              
              // Show loading dialog to prevent flicker and interaction during logout
              Get.dialog(
                const Center(child: CircularProgressIndicator(color: kPrimary)),
                barrierDismissible: false,
              );

              await userProvider.signOut();
              
              // Navigation will clear the loading dialog as well
              Get.offAllNamed('/login');
            },
            child: const Text(
              "Logout",
              style: TextStyle(color: kDanger, fontWeight: FontWeight.bold),
            ),
          ),
        ],
      ),
    );
  }
}
