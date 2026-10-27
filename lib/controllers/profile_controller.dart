import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:image_picker/image_picker.dart';
import 'package:provider/provider.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../providers/user_provider.dart';
import '../utils/themes/app_theme.dart';

class ProfileController extends GetxController {
  final ImagePicker _picker = ImagePicker();
  var localProfileImagePath = ''.obs;

  @override
  void onInit() {
    super.onInit();
    _loadLocalImage();
  }

  Future<void> _loadLocalImage() async {
    try {
      final prefs = await SharedPreferences.getInstance();
      final userId = Provider.of<UserProvider>(Get.context!, listen: false).userModel?.id ?? 'default';
      final path = prefs.getString('local_profile_image_$userId') ?? '';
      if (path.isNotEmpty && File(path).existsSync()) {
        localProfileImagePath.value = path;
      }
    } catch (e) {
      debugPrint('Error loading local profile image: $e');
    }
  }

  Future<void> pickAndStoreProfileImage(BuildContext context) async {
    Get.bottomSheet(
      Container(
        padding: const EdgeInsets.all(24),
        decoration: const BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: Wrap(
          children: [
            const Text(
              'Change Profile Picture',
              style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            ListTile(
              leading: const Icon(Icons.camera_alt_rounded, color: kPrimary),
              title: const Text('Take a Photo', style: TextStyle(color: kTextPrimary)),
              onTap: () async {
                Get.back();
                await _pickImage(ImageSource.camera);
              },
            ),
            ListTile(
              leading: const Icon(Icons.photo_library_rounded, color: kPrimary),
              title: const Text('Choose from Gallery', style: TextStyle(color: kTextPrimary)),
              onTap: () async {
                Get.back();
                await _pickImage(ImageSource.gallery);
              },
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _pickImage(ImageSource source) async {
    try {
      final XFile? image = await _picker.pickImage(
        source: source,
        maxWidth: 512,
        maxHeight: 512,
        imageQuality: 85,
      );
      if (image != null) {
        final prefs = await SharedPreferences.getInstance();
        final userId = Provider.of<UserProvider>(Get.context!, listen: false).userModel?.id ?? 'default';
        await prefs.setString('local_profile_image_$userId', image.path);
        localProfileImagePath.value = image.path;
        Get.snackbar(
          'Success',
          'Profile picture updated and stored on your device',
          snackPosition: SnackPosition.BOTTOM,
          backgroundColor: kBgCard,
          colorText: kTextPrimary,
          margin: const EdgeInsets.all(16),
        );
      }
    } catch (e) {
      debugPrint('Error picking image: $e');
      Get.snackbar(
        'Error',
        'Could not pick image. Please check permissions.',
        snackPosition: SnackPosition.BOTTOM,
        backgroundColor: kBgCard,
        colorText: kDanger,
        margin: const EdgeInsets.all(16),
      );
    }
  }

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
