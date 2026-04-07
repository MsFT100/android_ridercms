import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:get/get.dart';
import 'package:ridercms/controllers/scan_controller.dart';
import '../../utils/themes/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ScanScreen extends StatefulWidget {
  const ScanScreen({super.key});

  @override
  State<ScanScreen> createState() => _ScanScreenState();
}

class _ScanScreenState extends State<ScanScreen> {

  @override
  Widget build(BuildContext context) {
    final controller = Get.put(ScanController());
    return Scaffold(
      backgroundColor: Colors.black,
      body: Stack(
        children: [
          // 1. Camera Viewfinder
          MobileScanner(
            controller: controller.cameraController,
            onDetect: (capture) {
              final List<Barcode> barcodes = capture.barcodes;
              for (final barcode in barcodes) {
                if (barcode.rawValue != null) {
                  controller.handleQrCode(context, barcode.rawValue!);
                }
              }
            },
          ),

          // 2. UI Overlay
          SafeArea(
            child: SingleChildScrollView( // Add scroll to prevent overflow
              child: SizedBox(
                height: MediaQuery.of(context).size.height - MediaQuery.of(context).padding.top,
                child: Column(
                  children: [
                    Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          const BackBtn(),
                          const Text(
                            'Scan Station QR',
                            style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                          ),
                          IconButton(
                            color: Colors.white,
                            icon: Obx(() => Icon(
                              controller.isTorchOn.value
                                  ? Icons.flash_on
                                  : Icons.flash_off,
                              color: controller.isTorchOn.value ? kPrimary : Colors.grey,
                            )),
                            onPressed: () => controller.toggleTorch(),
                          ),
                        ],
                      ),
                    ),
                    const Spacer(),
                    
                    // Scan Frame
                    Container(
                      width: 250,
                      height: 250,
                      decoration: BoxDecoration(
                        border: Border.all(color: kPrimary, width: 2),
                        borderRadius: BorderRadius.circular(20),
                      ),
                      child: Obx(() => controller.isProcessing.value
                        ? const Center(child: CircularProgressIndicator(color: kPrimary))
                        : const SizedBox.shrink()),
                    ),
                    
                    const Spacer(),
                    
                    Container(
                      padding: const EdgeInsets.all(24),
                      decoration: BoxDecoration(
                        color: kBgDark.withValues(alpha: 0.8),
                        borderRadius: const BorderRadius.vertical(top: Radius.circular(32)),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min, // Fix potential overflow
                        children: [
                          const Text(
                            'Align the QR code within the frame to confirm station and release battery',
                            textAlign: TextAlign.center,
                            style: TextStyle(color: kTextSecondary),
                          ),
                          const SizedBox(height: 24),
                          PrimaryButton(
                            label: 'Enter ID Manually',
                            onPressed: () {
                              controller.showManualEntryDialog(context);
                            },
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}
