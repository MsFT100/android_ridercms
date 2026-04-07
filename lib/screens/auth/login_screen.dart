import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:ridercms/controllers/login_controller.dart';
import 'package:ridercms/utils/constants/app_constants.dart';
import '../../providers/user_provider.dart';
import '../../utils/enums/enums.dart';
import '../../utils/themes/app_theme.dart';
import '../../widgets/common_widgets.dart';
import '../../widgets/buttons/social_btn.dart';
import '../../widgets/buttons/toggle_btn.dart';
import '../../widgets/labels/field_label.dart';

class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  @override
  Widget build(BuildContext context) {
    // Inject the controller
    final controller = Get.put(LoginController());
    final status = context.watch<UserProvider>().status;

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
          child: Column(
            children: [
              // Header
              Padding(
                padding: const EdgeInsets.fromLTRB(24, 8, 24, 24),
                child: Row(
                  children: [
                    const SizedBox(width: 12),
                    const Text(
                      AppConstants.appName,
                      style: TextStyle(
                        color: kPrimary,
                        fontSize: 20,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),

              // Scrollable form
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Toggle
                      Container(
                        padding: const EdgeInsets.all(4),
                        decoration: BoxDecoration(
                          color: kBgCard,
                          borderRadius: BorderRadius.circular(16),
                        ),
                        child: Row(
                          children: [
                            Obx(() => ToggleBtn(
                              label: 'Log In',
                              active: controller.isLogin.value,
                              onTap: () => controller.isLogin.value = true,
                            )),
                            Obx(() => ToggleBtn(
                              label: 'Sign Up',
                              active: !controller.isLogin.value,
                              onTap: () => controller.isLogin.value = false,
                            )),
                          ],
                        ),
                      ),
                      const SizedBox(height: 24),

                      // Title
                      Obx(() => Text(
                        controller.isLogin.value ? 'Welcome back!' : 'Create account',
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 24,
                          fontWeight: FontWeight.w700,
                        ),
                      )),
                      const SizedBox(height: 4),
                      Obx(() => Text(
                        controller.isLogin.value
                            ? 'Sign in to continue charging'
                            : 'Join Ridercms and start charging',
                        style: const TextStyle(color: kTextSecondary, fontSize: 14),
                      )),
                      const SizedBox(height: 24),

                      // Form Fields
                      Obx(() => Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          if (!controller.isLogin.value) ...[
                            const FieldLabel('Full Name'),
                            TextField(
                              controller: controller.nameCtrl,
                              style: const TextStyle(color: kTextPrimary),
                              decoration: const InputDecoration(hintText: 'John Doe'),
                            ),
                            const SizedBox(height: 16),
                          ],

                          const FieldLabel('Email Address'),
                          TextField(
                            controller: controller.emailCtrl,
                            keyboardType: TextInputType.emailAddress,
                            style: const TextStyle(color: kTextPrimary),
                            decoration: const InputDecoration(hintText: 'you@example.com'),
                          ),
                          const SizedBox(height: 16),

                          if (!controller.isLogin.value) ...[
                            const FieldLabel('Phone Number'),
                            TextField(
                              controller: controller.phoneCtrl,
                              keyboardType: TextInputType.phone,
                              style: const TextStyle(color: kTextPrimary),
                              decoration: const InputDecoration(hintText: '+254 700 000 000'),
                            ),
                            const SizedBox(height: 16),
                          ],

                          const FieldLabel('Password'),
                          TextField(
                            controller: controller.passwordCtrl,
                            obscureText: controller.obscurePassword.value,
                            style: const TextStyle(color: kTextPrimary),
                            decoration: InputDecoration(
                              hintText: '••••••••',
                              suffixIcon: IconButton(
                                icon: Icon(
                                  controller.obscurePassword.value
                                      ? Icons.visibility_off
                                      : Icons.visibility,
                                  color: kTextSecondary,
                                  size: 20,
                                ),
                                onPressed: () => controller.togglePasswordVisibility(),
                              ),
                            ),
                          ),
                        ],
                      )),

                      Obx(() => controller.isLogin.value ? Column(
                        children: [
                          const SizedBox(height: 8),
                          Align(
                            alignment: Alignment.centerRight,
                            child: GestureDetector(
                              onTap: () => Get.toNamed('/reset-password'),
                              child: const Text(
                                'Forgot password?',
                                style: TextStyle(
                                  color: kPrimary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500,
                                ),
                              ),
                            ),
                          ),
                        ],
                      ) : const SizedBox.shrink()),

                      const SizedBox(height: 24),
                      status == Status.authenticating
                          ? const Center(child: CircularProgressIndicator(color: kPrimary))
                          : Obx(() => PrimaryButton(
                              label: controller.isLogin.value ? 'Log In' : 'Create Account',
                              onPressed: () => controller.submit(context),
                            )),

                      // Divider
                      Padding(
                        padding: const EdgeInsets.symmetric(vertical: 24),
                        child: Row(
                          children: [
                            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                            const Padding(
                              padding: EdgeInsets.symmetric(horizontal: 12),
                              child: Text('or continue with', style: TextStyle(color: kTextSecondary, fontSize: 13)),
                            ),
                            Expanded(child: Divider(color: Colors.white.withValues(alpha: 0.1))),
                          ],
                        ),
                      ),

                      // Social buttons
                      Row(
                        children: [
                          Expanded(
                            child: status == Status.authenticating
                                ? const Center(child: CircularProgressIndicator(color: kPrimary))
                                : SocialBtn(
                                    label: 'Google',
                                    icon: AppConstants.googleImage,
                                    onTap: () => controller.signInWithGoogle(context),
                                  ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      // Legal Links
                      Center(
                        child: RichText(
                          textAlign: TextAlign.center,
                          text: TextSpan(
                            style: const TextStyle(color: kTextSecondary, fontSize: 12),
                            children: [
                              const TextSpan(text: 'By continuing, you agree to our '),
                              TextSpan(
                                text: 'Terms of Service',
                                style: const TextStyle(color: kPrimary),
                                recognizer: TapGestureRecognizer()..onTap = () => Get.toNamed('/terms-of-service'),
                              ),
                              const TextSpan(text: ' and '),
                              TextSpan(
                                text: 'Privacy Policy',
                                style: const TextStyle(color: kPrimary),
                                recognizer: TapGestureRecognizer()..onTap = () => Get.toNamed('/privacy-policy'),
                              ),
                            ],
                          ),
                        ),
                      ),
                      const SizedBox(height: 32),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
