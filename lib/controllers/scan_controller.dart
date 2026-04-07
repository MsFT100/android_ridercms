import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:provider/provider.dart';
import '../providers/user_provider.dart';
import '../services/booth_service.dart';
import '../widgets/custom_snackbar.dart';
import '../utils/themes/app_theme.dart';

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

      // We need to determine if this is a DEPOSIT scan or a RELEASE scan.
      // We can check if the user came from the PaymentSuccessScreen or has a pending withdrawal.
      // For now, let's try 'releaseBattery' first if they have a paid session, 
      // otherwise fallback to 'initiateDeposit'.
      
      // Attempt to release battery first (for paid withdrawals)
      final releaseResult = await _boothService.releaseBattery(token, code);

      if (releaseResult['success'] == true) {
        if (context.mounted) {
          CustomSnackBar.show(context, releaseResult['message']);
          // Redirect to a specific collection/success screen or dashboard
          Get.offAllNamed('/dashboard'); 
        }
        return;
      }

      // If release fails with 404 (No paid session), then it might be a normal DEPOSIT scan.
      if (releaseResult['message'].toString().contains('No paid withdrawal session')) {
         final depositResult = await _boothService.initiateDeposit(token, code);

         if (depositResult.containsKey('error')) {
           throw depositResult['error'];
         }

         if (context.mounted) {
           CustomSnackBar.show(context, 'Deposit initiated! Proceed to slot ${depositResult['slotIdentifier']}');
           Get.offNamed('/slot-assigned', arguments: depositResult);
         }
      } else {
        // Some other error from releaseBattery
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
            const Text(
              'Enter Booth ID',
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 20,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Enter the unique ID found below the QR code on the station.',
              style: TextStyle(color: kTextSecondary, fontSize: 14),
            ),
            const SizedBox(height: 24),
            TextField(
              controller: manualIdController,
              autofocus: true,
              style: const TextStyle(color: kTextPrimary),
              decoration: const InputDecoration(
                hintText: 'e.g. BOOTH-1234',
              ),
            ),
            const SizedBox(height: 24),
            Obx(() => ElevatedButton(
              onPressed: isProcessing.value 
                ? null 
                : () {
                    final id = manualIdController.text.trim();
                    if (id.isNotEmpty) {
                      handleQrCode(context, id);
                    }
                  },
              child: isProcessing.value 
                ? const SizedBox(
                    height: 20, 
                    width: 20, 
                    child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2)
                  )
                : const Text('Connect to Station'),
            )),
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
