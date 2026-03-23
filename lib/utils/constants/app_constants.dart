import 'package:flutter/material.dart';

class AppConstants {
  static const String appName = 'RIDERCMS';
  static const String prodBaseUrl = 'https://ridercmsv1-194585815067.europe-west1.run.app/api';
  static const String googleMapsApiKey = 'AIzaSyCD1_cfwN7m0a5R_NxXclDNK-S1gw7NZgk';

  // Firebase/Google Config
  // Get this from Firebase Console > Auth > Google > Web Client ID
  static const String googleWebClientId = 'YOUR_WEB_CLIENT_ID_HERE.apps.googleusercontent.com';

  static const String appVersion = '1.0';
  static const String fontFamily = 'SFProText';

  //int
  static const int fontSizeNormal = 24;

  //doubles
  static const double iconSizeNormal = 24.0;
  static const FontWeight fontWeightNormal = FontWeight.w700;

  //Icons
  static const String googleIcon = 'assets/images/google_icon.png';
  static const String googleImage = 'assets/images/google.png';
}
