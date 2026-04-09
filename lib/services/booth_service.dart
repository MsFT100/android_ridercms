import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/booth_models.dart';

class BoothService {
  final String _baseUrl = AppConfig.baseUrl;
  final Duration _timeout = const Duration(seconds: 15);

  /// Fetches a list of all public, online booths.
  Future<List<PublicBooth>> getBooths(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/booths'),
        headers: {
          'Authorization': 'Bearer $token',
        },
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        List<dynamic> data = json.decode(response.body);
        return data.map((json) => PublicBooth.fromJson(json)).toList();
      }
      return [];
    } catch (e) {
      debugPrint('Failed to fetch public booths: $e');
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
      ).timeout(_timeout);
      
      return json.decode(response.body);
    } catch (e) {
      debugPrint('Failed to initiate deposit: $e');
      rethrow;
    }
  }

  /// Check the status of the currently deposited battery.
  Future<MyBatteryStatus?> getMyBatteryStatus(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/booths/my-battery-status'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(_timeout);
      
      if (kDebugMode) {
        print('My Battery Status RAW Response: ${response.body}');
      }

      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null) return null;
        return MyBatteryStatus.fromJson(data);
      } else {
        debugPrint('Status Polling Failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Polling error in service: $e');
      // Return null instead of rethrowing to allow the app to keep polling
      return null;
    }
  }

  /// Fetches details of a user's pending withdrawal session, if one exists.
  Future<WithdrawalSession?> getPendingWithdrawal(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/booths/sessions/pending-withdrawal'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        final data = json.decode(response.body);
        if (data == null || (data is Map && data.isEmpty)) return null;
        return WithdrawalSession.fromJson(data);
      }
      return null;
    } catch (e) {
      debugPrint('Error fetching pending withdrawal: $e');
      return null;
    }
  }

  /// Stop charging before withdrawal
  Future<Map<String, dynamic>> stopCharging(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/booths/stop-charging'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      ).timeout(_timeout);
      
      final data = json.decode(response.body);
      if (response.statusCode == 200 || response.statusCode == 409) {
        return data;
      } else {
        throw data['error'] ?? data['message'] ?? 'Failed to stop charging';
      }
    } catch (e) {
      rethrow;
    }
  }

  /// Initiates the withdrawal process.
  Future<WithdrawalSession?> initiateWithdrawal(String token) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/booths/initiate-withdrawal'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(_timeout);
      
      if (response.statusCode == 200) {
        return WithdrawalSession.fromJson(json.decode(response.body));
      } else {
        Map<String, dynamic> errorData = {};
        try {
          errorData = json.decode(response.body);
        } catch (_) {}
        final errorMessage = errorData['error'] ?? errorData['message'] ?? 'Failed to initiate withdrawal (Status: ${response.statusCode})';
        throw errorMessage;
      }
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
      ).timeout(_timeout);
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
      ).timeout(_timeout);
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
      ).timeout(_timeout);
    } catch (e) {
      rethrow;
    }
  }

  /// Release battery after scanning booth QR
  Future<Map<String, dynamic>> releaseBattery(String token, String boothUid) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/booths/release-battery'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'boothUid': boothUid}),
      ).timeout(_timeout);

      final data = json.decode(response.body);
      if (response.statusCode == 200) {
        return {'success': true, 'message': data['message'], 'slotIdentifier': data['slotIdentifier']};
      } else {
        return {'success': false, 'message': data['error'] ?? 'Failed to release battery'};
      }
    } catch (e) {
      return {'success': false, 'message': e.toString()};
    }
  }

  /// Fetches transaction history.
  Future<List<UserTransaction>> getHistory(String token) async {
    try {
      final response = await http.get(
        Uri.parse('$_baseUrl/booths/history'),
        headers: {'Authorization': 'Bearer $token'},
      ).timeout(_timeout);
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
      ).timeout(_timeout);
    } catch (e) {
      rethrow;
    }
  }
}
