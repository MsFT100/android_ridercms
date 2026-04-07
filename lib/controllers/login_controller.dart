import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:ridercms/utils/enums/enums.dart';
import '../providers/user_provider.dart';
import '../widgets/custom_snackbar.dart';

class LoginController extends GetxController {
  final emailCtrl = TextEditingController();
  final passwordCtrl = TextEditingController();
  final nameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();

  var isLogin = true.obs;
  var obscurePassword = true.obs; // Add this for password visibility

  void toggleMode() {
    isLogin.value = !isLogin.value;
  }

  void togglePasswordVisibility() {
    obscurePassword.value = !obscurePassword.value;
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
        CustomSnackBar.show(context, 'Welcome back!', isError: false);
        Get.offAllNamed('/dashboard');
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
      CustomSnackBar.show(context, 'Signed in with Google', isError: false);
      Get.offAllNamed('/dashboard');
    } else {
      if (userProvider.status == Status.unauthenticated) {
         CustomSnackBar.show(context, 'Google sign-in failed or cancelled.', isError: true);
      }
    }
  }

  Future<void> forgotPassword(BuildContext context) async {
    final email = emailCtrl.text.trim();
    if (email.isEmpty || !GetUtils.isEmail(email)) {
      CustomSnackBar.show(context, 'Please enter a valid email address first.', isError: true);
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    bool success = await userProvider.sendPasswordResetEmail(email);

    if (!context.mounted) return;

    if (success) {
      CustomSnackBar.show(
        context, 
        'Password reset email sent. Please check your inbox.', 
        isError: false
      );
    } else {
      CustomSnackBar.show(
        context, 
        'Failed to send reset email. Make sure the email is registered.', 
        isError: true
      );
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
