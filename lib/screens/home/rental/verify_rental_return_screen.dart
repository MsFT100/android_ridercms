import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../controllers/rental_controller.dart';
import '../../../utils/themes/app_theme.dart';
import '../../../widgets/common_widgets.dart';

/// `verify_return` step — the rider scans the returned battery
/// (`require_return_scan`).
class VerifyRentalReturnScreen extends StatefulWidget {
  const VerifyRentalReturnScreen({super.key});

  @override
  State<VerifyRentalReturnScreen> createState() =>
      _VerifyRentalReturnScreenState();
}

class _VerifyRentalReturnScreenState extends State<VerifyRentalReturnScreen> {
  final RentalController _controller = Get.find<RentalController>();
  final MobileScannerController _camera = MobileScannerController();

  bool _scanning = false;
  bool _torchOn = false;
  String _error = '';

  @override
  void dispose() {
    _camera.dispose();
    super.dispose();
  }

  void _onDetect(BarcodeCapture capture) {
    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue;
      if (value == null || value.isEmpty) continue;
      _verify(value);
    }
  }

  Future<void> _verify(String code) async {
    if (!_scanning) return;

    final scanned = code.trim();
    final expected = _controller.rentalBatteryId;

    if (_controller.onReturnBatteryScanned(scanned)) {
      await _camera.stop();
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _error = '';
      });
    } else {
      setState(() {
        _error =
            'Wrong battery scanned. Expected $expected, but scanned $scanned.';
      });
    }
  }

  Future<void> _startScanner() async {
    setState(() {
      _error = '';
      _scanning = true;
    });
    try {
      await _camera.start();
    } catch (_) {
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _error = 'Camera not available. Enter the battery code manually.';
      });
    }
  }

  Future<void> _stopScanner() async {
    setState(() => _scanning = false);
    try {
      await _camera.stop();
    } catch (_) {
      // Already stopped.
    }
  }

  Future<void> _manualEntry() async {
    final textController = TextEditingController();
    final result = await Get.dialog<String>(
      AlertDialog(
        backgroundColor: kBgCard,
        title: const Text(
          'Battery ID',
          style: TextStyle(color: kTextPrimary),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: kTextPrimary),
          decoration: InputDecoration(hintText: _controller.rentalBatteryId),
        ),
        actions: [
          TextButton(onPressed: () => Get.back(), child: const Text('Cancel')),
          TextButton(
            onPressed: () => Get.back(result: textController.text.trim()),
            child: const Text('Confirm'),
          ),
        ],
      ),
    );
    if (result != null && result.isNotEmpty) {
      _verify(result);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Obx(() {
      final slot =
          _controller.returnSlot.value ?? _controller.active.value?.returnSlot;

      return SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
        child: Column(
          children: [
            Row(
              children: [
                BackBtn(onTap: () => _controller.goTo(RentalStep.returning)),
                const SizedBox(width: 12),
                const Text(
                  'Verify Return',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 18,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.1),
                shape: BoxShape.circle,
                border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
              ),
              child: const Icon(Icons.qr_code_scanner, color: kPrimary, size: 32),
            ),
            const SizedBox(height: 20),
            const Text(
              'Scan the returned battery',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kTextPrimary,
                fontSize: 24,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'You must scan and verify the returned rental battery before '
              'continuing.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: kTextSecondary,
                fontSize: 14,
                height: 1.5,
              ),
            ),
            const SizedBox(height: 20),
            AppCard(
              child: Column(
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'BATTERY',
                          style: TextStyle(
                            color: kTextSecondary.withValues(alpha: 0.9),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Text(
                        _controller.rentalBatteryId,
                        style: const TextStyle(
                          color: kTextPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                          fontFamily: 'monospace',
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          'RETURN SLOT',
                          style: TextStyle(
                            color: kTextSecondary.withValues(alpha: 0.9),
                            fontSize: 10,
                            fontWeight: FontWeight.w700,
                            letterSpacing: 0.8,
                          ),
                        ),
                      ),
                      Text(
                        slot != null && slot.isValid
                            ? slot.slotIdentifier
                            : 'Assigning…',
                        style: const TextStyle(
                          color: kPrimary,
                          fontSize: 13,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
            const SizedBox(height: 20),
            if (_scanning)
              ClipRRect(
                borderRadius: BorderRadius.circular(20),
                child: AspectRatio(
                  aspectRatio: 1,
                  child: MobileScanner(controller: _camera, onDetect: _onDetect),
                ),
              ),
            if (_scanning) ...[
              const SizedBox(height: 16),
              GhostButton(label: 'Stop Scanner', onPressed: _stopScanner),
            ] else
              PrimaryButton(label: 'Scan Battery QR', onPressed: _startScanner),
            const SizedBox(height: 12),
            TextButton(
              onPressed: _manualEntry,
              child: const Text(
                'Enter battery ID manually',
                style: TextStyle(color: kTextSecondary),
              ),
            ),
            if (_scanning)
              IconButton(
                onPressed: () async {
                  await _camera.toggleTorch();
                  if (!mounted) return;
                  setState(() => _torchOn = !_torchOn);
                },
                icon: Icon(
                  _torchOn ? Icons.flash_on : Icons.flash_off,
                  color: _torchOn ? kPrimary : kTextSecondary,
                ),
              ),
            if (_error.isNotEmpty) ...[
              const SizedBox(height: 8),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(14),
                decoration: BoxDecoration(
                  color: kDanger.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(14),
                  border: Border.all(color: kDanger.withValues(alpha: 0.3)),
                ),
                child: Text(
                  _error,
                  textAlign: TextAlign.center,
                  style: const TextStyle(color: kDanger, fontSize: 13),
                ),
              ),
            ],
            const SizedBox(height: 16),
            TextButton(
              onPressed: () => _controller.goTo(RentalStep.returning),
              child: const Text(
                'Choose a different return slot',
                style: TextStyle(color: kTextSecondary, fontSize: 12),
              ),
            ),
          ],
        ),
      );
    });
  }
}
