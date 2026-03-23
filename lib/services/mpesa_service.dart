// lib/services/mpesa_service.dart

import 'dart:convert';

import 'package:flutter/cupertino.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/mpesa_config.dart';

class MpesaService {
  final MpesaConfig config = MpesaConfig.auto();

  String _formatPhoneNumber(String phone) {
    if (phone.startsWith('0')) {
      return '254${phone.substring(1)}';
    } else if (phone.startsWith('254')) {
      return phone;
    } else {
      throw Exception('Invalid phone format');
    }
  }

  Future<String> getMpesaAccessToken(BuildContext context) async {
    String authKey = base64Encode(utf8.encode("${config.consumerKey}:${config.consumerSecret}"));

    final response = await http.get(
      Uri.parse("${config.baseUrl}/oauth/v1/generate?grant_type=client_credentials"),
      headers: {"Authorization": "Basic $authKey"},
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body)["access_token"];
    } else {
      throw Exception("Access token error: ${response.body}");
    }
  }

  String _generateMpesaPassword() {
    final timestamp = DateTime.now()
        .toUtc()
        .toString()
        .replaceAll(RegExp(r'\D'), '')
        .substring(0, 14);
    final data = config.businessShortCode + config.passkey + timestamp;
    return base64Encode(utf8.encode(data));
  }

  Future<bool> initiateStkPushPayment({
    required BuildContext context,
    required double amount,
    required String phoneNumber,
    required String accountReference,
    String transactionDesc = "Payment",
  }) async {
    final accessToken = await getMpesaAccessToken(context);
    final formattedPhone = _formatPhoneNumber(phoneNumber);
    final password = _generateMpesaPassword();
    final timestamp = DateTime.now()
        .toUtc()
        .toString()
        .replaceAll(RegExp(r'\D'), '')
        .substring(0, 14);

    final response = await http.post(
      Uri.parse("${config.baseUrl}/mpesa/stkpush/v1/processrequest"),
      headers: {
        "Authorization": "Bearer $accessToken",
        "Content-Type": "application/json",
      },
      body: jsonEncode({
        "BusinessShortCode": config.businessShortCode,
        "Password": password,
        "Timestamp": timestamp,
        "TransactionType": "CustomerPayBillOnline",
        "Amount": amount.toInt().toString(),
        "PartyA": formattedPhone,
        "PartyB": config.businessShortCode,
        "PhoneNumber": formattedPhone,
        "CallBackURL": config.callBackURL,
        "AccountReference": accountReference,
        "TransactionDesc": transactionDesc,
      }),
    );

    if (response.statusCode == 200) {
      final data = jsonDecode(response.body);
      if (data["ResponseCode"] == "0") {
        return true;
      } else {
        throw Exception("STK Push failed: ${data['ResponseDescription']}");
      }
    } else {
      throw Exception("STK Push HTTP Error: ${response.body}");
    }
  }

  Future<bool> initiateB2CWithdrawal({
    required BuildContext context,
    required double amount,
    required String recipientPhoneNumber,
    required String securityCredential, // Pre-encrypted base64 string
    required String transactionReason,
    String remarks = "Withdrawal",
  }) async {
    try {
      final String accessToken = await getMpesaAccessToken(context);
      final String formattedPhone = _formatPhoneNumber(recipientPhoneNumber);

      final response = await http.post(
        Uri.parse("${config.baseUrl}/mpesa/b2c/v1/paymentrequest"),
        headers: {
          "Authorization": "Bearer $accessToken",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "InitiatorName": "BucorideDriverApp", // Replace with your real Initiator Name
          "SecurityCredential": securityCredential, // Base64-encoded credential from backend or encrypted locally
          "CommandID": "BusinessPayment", // Or SalaryPayment / PromotionPayment
          "Amount": amount.toInt().toString(),
          "PartyA": "3031707",
          "PartyB": formattedPhone,
          "Remarks": remarks,
          "QueueTimeOutURL": config.callBackURL,
          "ResultURL": config.callBackURL,
          "Occasion": transactionReason,
        }),
      );

      if (response.statusCode == 200) {
        final Map<String, dynamic> responseBody = jsonDecode(response.body);
        if (responseBody['ResponseCode'] == '0') {
          if (kDebugMode) {
            print("✅ B2C Withdrawal initiated: ${response.body}");
          }
          return true;
        } else {
          if (kDebugMode) {
            print("❌ B2C failed: ${response.body}");
          }
          throw Exception("B2C Withdrawal failed: ${responseBody['ResponseDescription'] ?? 'Unknown error'}");
        }
      } else {
        if (kDebugMode) {
          print("❌ B2C HTTP error: ${response.statusCode} - ${response.body}");
        }
        throw Exception("B2C Withdrawal failed: HTTP ${response.statusCode}");
      }
    } catch (e) {
      if (kDebugMode) {
        print("🚨 Error initiating B2C withdrawal: $e");
      }
      rethrow;
    }
  }

}
