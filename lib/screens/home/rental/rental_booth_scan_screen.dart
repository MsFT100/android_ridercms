import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

import '../../../controllers/rental_controller.dart';
import '../../../utils/themes/app_theme.dart';
import '../../../widgets/common_widgets.dart';

/// Booth QR gate shown before a rental battery is issued
/// (`require_booth_scan_before_issue`).
class RentalBoothScanScreen extends StatefulWidget {
  const RentalBoothScanScreen({super.key});

  @override
  State<RentalBoothScanScreen> createState() => _RentalBoothScanScreenState();
}

class _RentalBoothScanScreenState extends State<RentalBoothScanScreen> {
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
    if (_controller.matchesBooth(scanned)) {
      await _camera.stop();
      if (!mounted) return;
      setState(() {
        _scanning = false;
        _error = '';
      });
      _controller.onBoothScanned(scanned);
    } else {
      setState(() {
        _error = 'Wrong booth scanned. Expected '
            '${_controller.displayBoothName}, but scanned $scanned.';
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
        _error = 'Camera not available. Enter the booth code manually instead.';
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
          'Enter booth code',
          style: TextStyle(color: kTextPrimary),
        ),
        content: TextField(
          controller: textController,
          autofocus: true,
          style: const TextStyle(color: kTextPrimary),
          decoration: const InputDecoration(hintText: 'e.g. booth-001'),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: const Text('Cancel'),
          ),
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
    return SingleChildScrollView(
      padding: const EdgeInsets.fromLTRB(24, 12, 24, 32),
      child: Column(
        children: [
          Row(
            children: [
              BackBtn(onTap: _controller.finish),
              const SizedBox(width: 12),
              const Text(
                'Confirm Station',
                style: TextStyle(
                  color: kTextPrimary,
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                ),
              ),
              const Spacer(),
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
            ],
          ),
          const SizedBox(height: 28),
          Container(
            width: 76,
            height: 76,
            decoration: BoxDecoration(
              color: kPrimary.withValues(alpha: 0.1),
              shape: BoxShape.circle,
              border: Border.all(color: kPrimary.withValues(alpha: 0.25)),
            ),
            child: const Icon(Icons.location_on_outlined, color: kPrimary, size: 34),
          ),
          const SizedBox(height: 20),
          const Text(
            'SCAN THE BOOTH QR',
            style: TextStyle(
              color: kPrimary,
              fontSize: 11,
              fontWeight: FontWeight.w700,
              letterSpacing: 2,
            ),
          ),
          const SizedBox(height: 10),
          Text(
            'Scan the QR code on booth ${_controller.displayBoothName} '
            'to confirm you are at the station.',
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: kTextSecondary,
              fontSize: 13,
              height: 1.5,
            ),
          ),
          if (_controller.assignedSlotIdentifier.isNotEmpty) ...[
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
              decoration: BoxDecoration(
                color: kPrimary.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: kPrimary.withValues(alpha: 0.3)),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text(
                    'Your slot: ',
                    style: TextStyle(color: kPrimary, fontSize: 12),
                  ),
                  Text(
                    _controller.assignedSlotIdentifier,
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 12,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ],
              ),
            ),
          ],
          const SizedBox(height: 24),
          if (_scanning)
            ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: AspectRatio(
                aspectRatio: 1,
                child: MobileScanner(
                  controller: _camera,
                  onDetect: _onDetect,
                ),
              ),
            ),
          if (_scanning) ...[
            const SizedBox(height: 16),
            GhostButton(label: 'Stop Scanner', onPressed: _stopScanner),
          ] else
            PrimaryButton(label: 'Scan Booth QR', onPressed: _startScanner),
          const SizedBox(height: 12),
          TextButton(
            onPressed: _manualEntry,
            child: const Text(
              'Enter code manually',
              style: TextStyle(color: kTextSecondary),
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
        ],
      ),
    );
  }
}
