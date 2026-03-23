import 'dart:convert';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import 'package:ridercms/models/user_model.dart';
import '../config/app_config.dart';

class AuthService {
  final String _baseUrl = AppConfig.baseUrl;

  // Always gets a fresh token — mirrors your web authService
  Future<String?> _getFreshToken() async {
    return await FirebaseAuth.instance.currentUser?.getIdToken(true);
  }

  Future<UserModel?> getUserProfile() async {
    try {
      final token = await _getFreshToken(); // ← no cached token
      if (token == null) return null;

      final response = await http.get(
        Uri.parse('$_baseUrl/auth/profile'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
      );

      if (response.statusCode == 200) {
        return UserModel.fromJson(json.decode(response.body));
      } else {
        // DEBUG THIS: See if it's a 401, 403, or 500
        debugPrint('Profile Fetch Failed: ${response.statusCode} - ${response.body}');
        return null;
      }
    } catch (e) {
      debugPrint('Error fetching profile: $e');
      return null;
    }
  }

  Future<Map<String, dynamic>> registerUser({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String recaptchaToken,
  }) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/register'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({
          'email': email,
          'password': password,
          'name': name,
          'phoneNumber': phoneNumber,
          'recaptchaToken': recaptchaToken,
        }),
      );
      return json.decode(response.body);
    } catch (e) {
      return {'error': e.toString()};
    }
  }

  Future<String?> getEmailByPhone(String phoneNumber) async {
    try {
      final response = await http.post(
        Uri.parse('$_baseUrl/auth/user-by-phone'),
        headers: {'Content-Type': 'application/json'},
        body: json.encode({'phoneNumber': phoneNumber}),
      );
      if (response.statusCode == 200) {
        return json.decode(response.body)['email'];
      }
      return null;
    } catch (e) {
      return null;
    }
  }

  /// Update the user's FCM token on the backend
  Future<bool> updateFcmToken(String? fcmToken) async {
    try {
      final token = await _getFreshToken();
      if (token == null) return false;

      final response = await http.post(
        Uri.parse('$_baseUrl/auth/fcm-token'),
        headers: {
          'Authorization': 'Bearer $token',
          'Content-Type': 'application/json',
        },
        body: json.encode({'token': fcmToken}),
      );

      if (response.statusCode == 200) {
        debugPrint('FCM Token updated successfully');
        return true;
      } else {
        debugPrint('Failed to update FCM token: ${response.statusCode} - ${response.body}');
        return false;
      }
    } catch (e) {
      debugPrint('Error updating FCM token: $e');
      return false;
    }
  }
}
