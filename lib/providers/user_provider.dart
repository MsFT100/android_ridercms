import 'dart:async';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';
import 'package:ridercms/models/user_model.dart';
import 'package:ridercms/services/auth_service.dart';
import 'package:ridercms/services/notification_service.dart';
import 'package:ridercms/utils/enums/enums.dart';

class UserProvider extends ChangeNotifier {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final GoogleSignIn _googleSignIn = GoogleSignIn.instance;
  final AuthService _apiService = AuthService();
  final NotificationService _notificationService = NotificationService();

  User? _firebaseUser;
  UserModel? _userModel;
  Status _status = Status.uninitialized;
  StreamSubscription<User?>? _authStateSubscription;

  User? get firebaseUser => _firebaseUser;
  UserModel? get userModel => _userModel;
  Status get status => _status;

  UserProvider() {
    _initialize();
  }

  Future<void> _initialize() async {
    await _googleSignIn.initialize();
    _authStateSubscription = _auth.authStateChanges().listen(_onAuthStateChanged);
  }

  Future<void> _onAuthStateChanged(User? firebaseUser) async {
    if (firebaseUser == null) {
      _status = Status.unauthenticated;
      _firebaseUser = null;
      _userModel = null;
    } else {
      _firebaseUser = firebaseUser;
      _status = Status.authenticating;
      notifyListeners();

      try {
        final profile = await _apiService.getUserProfile();
        if (profile != null) {
          _userModel = profile;
          _status = Status.authenticated;
          await _notificationService.syncToken();
        } else {
          await Future.delayed(const Duration(seconds: 2));
          final retryProfile = await _apiService.getUserProfile();
          if (retryProfile != null) {
            _userModel = retryProfile;
            _status = Status.authenticated;
            await _notificationService.syncToken();
          } else {
            _status = Status.authenticated;
          }
        }
      } catch (e) {
        debugPrint('Profile fetch error: $e');
        _status = Status.authenticated;
      }
    }
    notifyListeners();
  }

  Future<bool> signInWithEmail(String email, String password) async {
    try {
      _status = Status.authenticating;
      notifyListeners();
      await _auth.signInWithEmailAndPassword(email: email, password: password);
      return true;
    } on FirebaseAuthException catch (e) {
      _status = Status.unauthenticated;
      notifyListeners();
      debugPrint('Login Error: ${e.message}');
      return false;
    } catch (e) {
      _status = Status.unauthenticated;
      notifyListeners();
      return false;
    }
  }

  Future<Map<String, dynamic>> signUp({
    required String email,
    required String password,
    required String name,
    required String phoneNumber,
    required String recaptchaToken,
  }) async {
    try {
      _status = Status.authenticating;
      notifyListeners();

      final response = await _apiService.registerUser(
        email: email,
        password: password,
        name: name,
        phoneNumber: phoneNumber,
        recaptchaToken: recaptchaToken,
      );

      if (response.containsKey('error')) {
        _status = Status.unauthenticated;
        notifyListeners();
        return {'success': false, 'message': response['error']};
      }

      _status = Status.unauthenticated;
      notifyListeners();
      return {'success': true, 'message': response['message']};
    } catch (e) {
      _status = Status.unauthenticated;
      notifyListeners();
      return {'success': false, 'message': e.toString()};
    }
  }

  Future<bool> signInWithGoogle() async {
    try {
      _status = Status.authenticating;
      notifyListeners();

      final GoogleSignInAccount googleUser = await _googleSignIn.authenticate();
      final GoogleSignInAuthentication googleAuth = googleUser.authentication;
      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      await _auth.signInWithCredential(credential);
      return true;
    } catch (e) {
      _status = Status.unauthenticated;
      notifyListeners();
      debugPrint('Google Sign In Error: $e');
      return false;
    }
  }

  Future<void> signOut() async {
    await _notificationService.clearToken();
    await _auth.signOut();
    await _googleSignIn.signOut();
    _status = Status.unauthenticated;
    _firebaseUser = null;
    _userModel = null;
    notifyListeners();
  }

  Future<bool> sendPasswordResetEmail(String email) async {
    try {
      await _auth.sendPasswordResetEmail(email: email);
      return true;
    } catch (e) {
      debugPrint('Password Reset Error: $e');
      return false;
    }
  }

  // FIX: Added forceRefresh parameter, default to false to avoid "Too many attempts"
  Future<String?> getFreshToken({bool forceRefresh = false}) async {
    return await FirebaseAuth.instance.currentUser?.getIdToken(forceRefresh);
  }

  @override
  void dispose() {
    _authStateSubscription?.cancel();
    super.dispose();
  }
}
