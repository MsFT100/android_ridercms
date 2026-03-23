import 'package:flutter/foundation.dart';
import 'package:ridercms/utils/constants/app_constants.dart';

/// A configuration class to manage environment-specific variables.
class AppConfig {
  AppConfig._();


  static String get _devBaseUrl {
    if (kIsWeb) return 'http://localhost:3000/api';
    // if (Platform.isAndroid) return 'http://10.0.2.2:3001/api';
    return 'https://ridercmsv1-194585815067.europe-west1.run.app/api';
  }

  static String get baseUrl => kReleaseMode ? AppConstants.prodBaseUrl : _devBaseUrl;

  // reCAPTCHA Site Key (Get this from Google Cloud Console)
  static const String recaptchaSiteKey = 'YOUR_RECAPTCHA_SITE_KEY_HERE';
}
