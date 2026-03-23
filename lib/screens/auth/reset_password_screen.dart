import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ridercms/utils/themes/app_theme.dart';
import 'package:ridercms/widgets/common_widgets.dart';
import 'package:ridercms/widgets/custom_snackbar.dart';

class ResetPasswordScreen extends StatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  State<ResetPasswordScreen> createState() => _ResetPasswordScreenState();
}

class _ResetPasswordScreenState extends State<ResetPasswordScreen> {
  final _emailCtrl = TextEditingController();
  bool _isLoading = false;

  Future<void> _resetPassword() async {
    final email = _emailCtrl.text.trim();
    if (email.isEmpty) {
      CustomSnackBar.show(context, 'Please enter your email address.', isError: true);
      return;
    }

    setState(() => _isLoading = true);

    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        CustomSnackBar.show(context, 'Password reset email sent! Please check your inbox.');
        Get.back(); // Go back to login
      }
    } on FirebaseAuthException catch (e) {
      if (mounted) {
        CustomSnackBar.show(context, e.message ?? 'An error occurred.', isError: true);
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    super.dispose();
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
        child: SafeArea(
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Padding(
                  padding: EdgeInsets.only(top: 8, bottom: 24),
                  child: Row(
                    children: [
                      BackBtn(),
                      SizedBox(width: 12),
                      Text(
                        'Reset Password',
                        style: TextStyle(
                          color: kPrimary,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                        ),
                      ),
                    ],
                  ),
                ),
                const Text(
                  'Forgot your password?',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Enter your email address below and we will send you a link to reset your password.',
                  style: TextStyle(color: kTextSecondary, fontSize: 14),
                ),
                const SizedBox(height: 32),
                const Text(
                  'Email Address',
                  style: TextStyle(color: kTextSecondary, fontSize: 13, fontWeight: FontWeight.w500),
                ),
                const SizedBox(height: 8),
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  style: const TextStyle(color: kTextPrimary),
                  decoration: const InputDecoration(
                    hintText: 'you@example.com',
                  ),
                ),
                const SizedBox(height: 32),
                _isLoading
                    ? const Center(child: CircularProgressIndicator(color: kPrimary))
                    : PrimaryButton(
                        label: 'Send Reset Link',
                        onPressed: _resetPassword,
                      ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
