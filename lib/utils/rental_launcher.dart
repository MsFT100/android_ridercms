import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';

import '../controllers/charging_controller.dart';
import '../models/rental_models.dart';
import '../providers/user_provider.dart';
import '../services/booth_service.dart';
import '../widgets/custom_snackbar.dart';

/// Outcome of [openRental], so callers can reflect it in their own UI.
enum RentalLaunchResult { opened, resumed, disabled, noBooth, unavailable, failed }

/// Mirrors the web `openRental`: resume an existing rental, otherwise pick the
/// booth of the rider's deposited battery and auto-assign the highest-SOC
/// rental battery. The rider never chooses a battery.
Future<RentalLaunchResult> openRental(
  BuildContext context, {
  String? boothUid,
  String? boothName,
}) async {
  final BoothService boothService = BoothService();

  void show(String message) {
    if (context.mounted) CustomSnackBar.show(context, message, isError: true);
  }

  String? token;
  try {
    token = await context.read<UserProvider>().getFreshToken();
  } catch (_) {
    token = null;
  }
  if (token == null) {
    show('Authentication failed. Please log in again.');
    return RentalLaunchResult.failed;
  }

  try {
    // A rider at the rental limit resumes the rental instead of hitting a 409.
    final active = await boothService.getActiveRental(token);
    if (active != null) {
      Get.toNamed('/rental', arguments: {'activeRental': active});
      return RentalLaunchResult.resumed;
    }

    final config = await boothService.getRentalFeatureStatus(token);
    if (!config.enabled) {
      show('Battery rentals are currently disabled.');
      return RentalLaunchResult.disabled;
    }

    final charging = Get.find<ChargingController>();
    final String targetBooth = (boothUid != null && boothUid.trim().isNotEmpty)
        ? boothUid.trim()
        : (charging.activeBattery?.boothUid ??
            (charging.batteries.isNotEmpty ? charging.batteries.first.boothUid : ''));

    if (targetBooth.isEmpty) {
      show('Deposit your own battery first before renting one.');
      return RentalLaunchResult.noBooth;
    }

    final available =
        await boothService.getAvailableRentalBatteries(token, targetBooth);

    if (!available.canRent || available.hasPendingRental) {
      show('You already have an active rental.');
      return RentalLaunchResult.unavailable;
    }

    final RentalBatteryOption? best = available.best;
    if (best == null) {
      show('No rental batteries are available right now.');
      return RentalLaunchResult.unavailable;
    }

    final String name =
        (boothName != null && boothName.trim().isNotEmpty) ? boothName.trim() : targetBooth;

    Get.toNamed('/rental', arguments: {
      'boothUid': targetBooth,
      'boothName': name,
      'config': config,
      'assigned': AssignedRental.fromOption(
        best,
        boothUid: targetBooth,
        boothName: name,
      ),
    });
    return RentalLaunchResult.opened;
  } catch (e) {
    show(e is BoothApiException
        ? e.message
        : 'Unable to check rental battery availability.');
    return RentalLaunchResult.failed;
  }
}
