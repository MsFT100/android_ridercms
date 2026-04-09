import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import 'package:ridercms/widgets/common_widgets.dart';
import '../providers/user_provider.dart';
import '../services/booth_service.dart';
import '../widgets/custom_snackbar.dart';
import '../utils/themes/app_theme.dart';
import 'charging_controller.dart';

class ScanController extends GetxController {
  final BoothService _boothService = BoothService();
  final MobileScannerController cameraController = MobileScannerController();
  
  var isProcessing = false.obs;
  var isTorchOn = false.obs;

  final TextEditingController manualIdController = TextEditingController();

  Future<void> handleQrCode(BuildContext context, String code) async {
    if (isProcessing.value) return;

    isProcessing.value = true;

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = await userProvider.getFreshToken();

      if (token == null) {
        throw 'Authentication token not found. Please log in again.';
      }

      // Attempt to release battery first (for paid withdrawals)
      final releaseResult = await _boothService.releaseBattery(token, code);

      if (releaseResult['success'] == true) {
        if (context.mounted) {
          CustomSnackBar.show(context, releaseResult['message']);
          Get.offAllNamed('/dashboard'); 
        }
        return;
      }

      // Fallback to deposit if no paid session exists
      if (releaseResult['message'].toString().contains('No paid withdrawal session')) {
         final depositResult = await _boothService.initiateDeposit(token, code);

         if (depositResult.containsKey('error')) {
           throw depositResult['error'];
         }

         if (context.mounted) {
           CustomSnackBar.show(context, 'Deposit initiated! Proceed to slot ${depositResult['slotIdentifier']}');
           // Ensure we pass boothUid explicitly for the Firebase listener
           Get.offNamed('/slot-assigned', arguments: {
             ...depositResult,
             'boothUid': code,
           });
         }
      } else {
        throw releaseResult['message'];
      }

    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(context, '$e', isError: true);
      }
    } finally {
      isProcessing.value = false;
    }
  }

  void toggleTorch() {
    cameraController.toggleTorch();
    isTorchOn.value = !isTorchOn.value;
  }

  void showManualEntryDialog(BuildContext context) {
    final chargingController = Get.find<ChargingController>();

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) => Container(
        padding: EdgeInsets.only(
          bottom: MediaQuery.of(context).viewInsets.bottom + 24,
          left: 24,
          right: 24,
          top: 24,
        ),
        decoration: const BoxDecoration(
          color: kBgDark,
          borderRadius: BorderRadius.vertical(top: Radius.circular(32)),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Obx(() {
              final bool isReleasing = chargingController.sessionType.value == ActiveSessionType.payment;
              return Text(
                isReleasing ? 'Verify Station' : 'Enter Booth ID',
                style: const TextStyle(color: kTextPrimary, fontSize: 20, fontWeight: FontWeight.bold),
              );
            }),
            const SizedBox(height: 8),
            Obx(() {
              final bool isReleasing = chargingController.sessionType.value == ActiveSessionType.payment;
              return Text(
                isReleasing 
                  ? 'Enter the Station ID to confirm your location and release the battery.'
                  : 'Enter the unique ID found below the QR code on the station.',
                style: const TextStyle(color: kTextSecondary, fontSize: 14),
              );
            }),
            const SizedBox(height: 24),
            TextField(
              controller: manualIdController,
              autofocus: true,
              textCapitalization: TextCapitalization.characters,
              style: const TextStyle(color: kTextPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g. BOOTH-1234',
              ),
            ),
            const SizedBox(height: 24),
            Obx(() {
              final bool isReleasing = chargingController.sessionType.value == ActiveSessionType.payment;
              final String label = isReleasing ? 'Verify & Release Battery' : 'Connect to Station';
              
              return PrimaryButton(
                label: isProcessing.value ? 'Processing...' : label,
                onPressed: isProcessing.value 
                  ? null 
                  : () {
                      final id = manualIdController.text.trim();
                      if (id.isNotEmpty) {
                        handleQrCode(context, id);
                      }
                    },
              );
            }),
          ],
        ),
      ),
    );
  }

  @override
  void onClose() {
    cameraController.dispose();
    manualIdController.dispose();
    super.onClose();
  }
}
