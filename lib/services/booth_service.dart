import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/booth_models.dart';

class BoothService {
  final String _baseUrl = AppConfig.baseUrl;

  /// Fetches a list of all public, online booths.
  Future<List<PublicBooth>> getBooths(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/booths'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      );
      if (kDebugMode) {
        print('Booths RAW Response: ${response.body}');
      }
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => PublicBooth.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      if (kDebugMode) {
        print('Failed to fetch public booths: $e');
      }
      rethrow;
    }
  }

  /// Initiates a battery deposit session.
  Future<Map<String, dynamic>> initiateDeposit(String token, String boothUid) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/booths/initiate-deposit'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'boothUid': boothUid}),
      );
      
      final data = json.decode(response.body);
      if (kDebugMode) {
        print('Initiate Deposit RAW Response: ${response.body}');
      }
      return data;
    } catch (e) {
      if (kDebugMode) {
        print('Failed to initiate deposit: $e');
      }
      rethrow;
    }
  }

  /// Check the status of the currently deposited battery.
  Future<MyBatteryStatus?> getMyBatteryStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/booths/my-battery-status'),
        headers: {'Authorization': 'Bearer $token'},
      );
      
      if (kDebugMode) {
        print('My Battery Status RAW Response: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null) return null;
        return MyBatteryStatus.fromJson(data);
      } else {
        if (kDebugMode) {
          print('Status Polling Failed: ${response.statusCode} - ${response.body}');
        }
        return null;
      }
    } catch (e) {
      if (kDebugMode) {
        print('Polling error in service: $e');
      }
      rethrow;
    }
  }

  /// Initiates the withdrawal process.
  Future<WithdrawalSession?> initiateWithdrawal(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/booths/initiate-withdrawal'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return WithdrawalSession.fromJson(json.decode(response.body));
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Triggers M-Pesa STK push for a session.
  Future<String?> payForWithdrawal(String token, int sessionId) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/booths/sessions/$sessionId/pay'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['checkoutRequestId'];
      }
      return null;
    } catch (e) {
      rethrow;
    }
  }

  /// Polls for withdrawal status.
  Future<String> getWithdrawalStatus(String token, String checkoutRequestId) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/booths/withdrawal-status/$checkoutRequestId'),
        headers: {'Authorization': 'Bearer $token'},
      );
      return json.decode(response.body)['paymentStatus'];
    } catch (e) {
      rethrow;
    }
  }

  /// Open slot for collection.
  Future<void> openForCollection(String token, String checkoutRequestId) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/booths/open-for-collection'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'checkoutRequestId': checkoutRequestId}),
      );
    } catch (e) {
      rethrow;
    }
  }

  /// Fetches transaction history.
  Future<List<UserTransaction>> getHistory(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/booths/history'),
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => UserTransaction.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Cancel active session.
  Future<void> cancelActiveSession(String token) async {
    try {
      await http.post(
        Uri.parse('$_baseUrl/booths/cancel-session'),
        headers: {'Authorization': 'Bearer $token'},
      );
    } catch (e) {
      rethrow;
    }
  }
}
