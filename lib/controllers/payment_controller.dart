import 'dart:async';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../models/booth_models.dart';
import '../providers/user_provider.dart';
import '../services/booth_service.dart';
import '../widgets/custom_snackbar.dart';

class PaymentController extends GetxController {
  final BoothService _boothService = BoothService();

  var withdrawalSession = Rxn<WithdrawalSession>();
  var isLoading = true.obs;
  var isProcessing = false.obs;
  var errorMessage = RxnString(); // Track specific error message
  var phoneController = TextEditingController();

  /// The **deposit** session this payment belongs to (used to remove exactly
  /// that battery from the multi-battery list after a successful payment).
  int? depositSessionId;

  @override
  void onInit() {
    super.onInit();
    final dynamic args = Get.arguments;
    if (args is Map && args['sessionId'] != null) {
      depositSessionId = int.tryParse(args['sessionId'].toString());
    }
    fetchWithdrawalSession();
  }

  Future<void> fetchWithdrawalSession() async {
    isLoading.value = true;
    errorMessage.value = null;

    final BuildContext? context = Get.context;
    if (context == null) {
      isLoading.value = false;
      return;
    }

    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final token = await userProvider.getFreshToken();

      if (token == null) {
        isLoading.value = false;
        errorMessage.value = "Authentication session expired.";
        return;
      }

      final pending = await _boothService.getPendingWithdrawals(token);
      WithdrawalSession? session;

      if (depositSessionId != null) {
        // The withdrawal for this deposit is usually created by the
        // stop-charging screen. Withdrawal ids differ from deposit ids, so
        // match on the slot the deposit occupies.
        final statuses = await _boothService.getMyBatteryStatuses(token);
        MyBatteryStatus? deposit;
        for (final status in statuses) {
          if (status.sessionId == depositSessionId) {
            deposit = status;
            break;
          }
        }
        for (final candidate in pending) {
          if (deposit != null &&
              candidate.boothUid == deposit.boothUid &&
              candidate.slotIdentifier == deposit.slotIdentifier) {
            session = candidate;
            break;
          }
        }
        // Only when the deposit can't be located (already left the list) is an
        // unmatched pending withdrawal assumed to be ours. Otherwise it may
        // belong to another battery and must not be paid here.
        if (session == null && deposit == null && pending.isNotEmpty) {
          session = pending.first;
        }
        // Not created yet — create it for exactly this battery.
        session ??=
            await _boothService.initiateWithdrawal(token, depositSessionId!);
      } else if (pending.isNotEmpty) {
        session = pending.first;
        // Recover the deposit behind this withdrawal from its slot.
        final statuses = await _boothService.getMyBatteryStatuses(token);
        for (final status in statuses) {
          if (status.boothUid == session.boothUid &&
              status.slotIdentifier == session.slotIdentifier) {
            depositSessionId = status.sessionId;
            break;
          }
        }
      } else {
        // Legacy entry point: pay for the first deposited battery.
        final statuses = await _boothService.getMyBatteryStatuses(token);
        if (statuses.isNotEmpty) {
          depositSessionId = statuses.first.sessionId;
          session = await _boothService.initiateWithdrawal(
            token,
            statuses.first.sessionId,
          );
        }
      }

      withdrawalSession.value = session;

      if (session != null) {
        final phoneNumber = userProvider.userModel?.phoneNumber;
        if (phoneNumber != null && phoneController.text.isEmpty) {
          phoneController.text = phoneNumber;
        }
      }
    } catch (e) {
      // Capture the specific error from the backend
      errorMessage.value = e is BoothApiException
          ? e.message
          : e.toString().replaceFirst('Exception: ', '');
      debugPrint('Error fetching payment details: $e');
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> processPayment() async {
    if (withdrawalSession.value == null) return;

    final BuildContext? context = Get.context;
    if (context == null) return;

    isProcessing.value = true;
    final userProvider = Provider.of<UserProvider>(context, listen: false);

    try {
      final token = await userProvider.getFreshToken();

      if (token == null) {
        isProcessing.value = false;
        if (context.mounted) {
          CustomSnackBar.show(
            context,
            'Authentication failed. Please log in.',
            isError: true,
          );
        }
        return;
      }

      final checkoutRequestId = await _boothService.payForWithdrawal(
        token,
        withdrawalSession.value!.sessionId,
      );

      Get.toNamed('/payment-processing', arguments: {
        'checkoutRequestId': checkoutRequestId,
        'session': withdrawalSession.value,
        'depositSessionId': depositSessionId,
      });
    } catch (e) {
      if (context.mounted) {
        CustomSnackBar.show(context, 'Payment error: $e', isError: true);
      }
    } finally {
      isProcessing.value = false;
    }
  }

  @override
  void onClose() {
    phoneController.dispose();
    super.onClose();
  }
}
