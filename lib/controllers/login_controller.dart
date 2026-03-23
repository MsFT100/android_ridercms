import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_snackbar.dart';

class LoginController extends GetxController {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  var isLogin = true.obs;

  void toggleMode() {
    isLogin.value = !isLogin.value;
  }

  Future<void> submit(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    if (isLogin.value) {
      bool success = await userProvider.signInWithEmail(
        emailCtrl.text.trim(),
        passwordCtrl.text.trim(),
      );
      
      if (!context.mounted) return;

      if (success) {
        Get.offAllNamed('/dashboard');
        CustomSnackBar.show(context, 'Welcome', isError: false);
      } else {
        CustomSnackBar.show(context, 'Login failed. Please check your credentials.', isError: true);
      }
    } else {
      // Sign Up
      final result = await userProvider.signUp(
        email: emailCtrl.text.trim(),
        password: passwordCtrl.text.trim(),
        name: nameCtrl.text.trim(),
        phoneNumber: phoneCtrl.text.trim(),
        recaptchaToken: "dummy_token", // Replace with real token logic if needed
      );

      if (!context.mounted) return;

      CustomSnackBar.show(context, result['message'], isError: !result['success']);

      if (result['success']) {
        isLogin.value = true;
      }
    }
  }

  Future<void> signInWithGoogle(BuildContext context) async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    bool success = await userProvider.signInWithGoogle();
    
    if (!context.mounted) return;

    if (success) {
      Get.offAllNamed('/dashboard');
    }
  }

  @override
  void onClose() {
    emailCtrl.dispose();
    passwordCtrl.dispose();
    nameCtrl.dispose();
    phoneCtrl.dispose();
    super.onClose();
  }
}
