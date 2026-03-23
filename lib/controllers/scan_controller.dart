import 'package:flutter/foundation.dart';
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

  // test booth 672a4e90-146b-4fbb-a48d-ec768f28dd70
  Future<void> handleQrCode(BuildContext context, String code) async {
    if (isProcessing.value) return;

    isProcessing.value = true;

    try {
      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = await userProvider.getFreshToken();

      if (kDebugMode) {
        print("QR TOKEN USED: $token ");
      }

      if (token == null) {
        throw 'Authentication token not found. Please log in again.';
      }

      final result = await _boothService.initiateDeposit(token, code);

      // Check for backend error response
      if (result.containsKey('error')) {
        throw result['error'];
      }

      if (context.mounted) {
        CustomSnackBar.show(context, 'Deposit initiated! Proceed to slot ${result['slotIdentifier']}');
        Get.offNamed('/slot-assigned', arguments: result);
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
