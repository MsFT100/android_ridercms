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

  @override
  void onInit() {
    super.onInit();
    fetchWithdrawalSession();
  }

  Future<void> fetchWithdrawalSession() async {
    isLoading.value = true;
    errorMessage.value = null;
    
    final BuildContext? context = Get.context;
    if (context == null) return;

    final userProvider = Provider.of<UserProvider>(context, listen: false);
    
    try {
      final token = await userProvider.getFreshToken();
      
      if (token == null) {
        isLoading.value = false;
        errorMessage.value = "Authentication session expired.";
        return;
      }

      // 1. MATCH WEB APP: Check for pending withdrawal first (Resumption)
      var session = await _boothService.getPendingWithdrawal(token);
      
      // 2. Fallback to initiation only if no pending session was found
      session ??= await _boothService.initiateWithdrawal(token);

      withdrawalSession.value = session;
      
      if (session != null) {
        final phoneNumber = userProvider.userModel?.phoneNumber;
        if (phoneNumber != null && phoneController.text.isEmpty) {
          phoneController.text = phoneNumber;
        }
      }
    } catch (e) {
      // Capture the specific error from the backend
      errorMessage.value = e.toString().replaceFirst('Exception: ', '');
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
        CustomSnackBar.show(context, 'Authentication failed. Please log in.', isError: true);
        return;
      }

      final checkoutRequestId = await _boothService.payForWithdrawal(
        token, 
        withdrawalSession.value!.sessionId
      );

      if (checkoutRequestId != null) {
        Get.toNamed('/payment-processing', arguments: {
          'checkoutRequestId': checkoutRequestId,
          'session': withdrawalSession.value,
          'token': token
        });
      } else {
        isProcessing.value = false;
        CustomSnackBar.show(context, 'Failed to initiate M-Pesa payment', isError: true);
      }
    } catch (e) {
      isProcessing.value = false;
      CustomSnackBar.show(context, 'Payment error: $e', isError: true);
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
