// lib/config/mpesa_config.dart

enum MpesaEnv { sandbox, production }

class MpesaConfig {
  final String baseUrl;
  final String consumerKey;
  final String consumerSecret;
  final String businessShortCode;
  final String passkey;
  final String callBackURL;

  MpesaConfig._({
    required this.baseUrl,
    required this.consumerKey,
    required this.consumerSecret,
    required this.businessShortCode,
    required this.passkey,
    required this.callBackURL,
  });

  /// Automatically choose based on `bool.fromEnvironment('dart.vm.product')`
  factory MpesaConfig.auto() {
    final isProduction = const bool.fromEnvironment('dart.vm.product');

    return isProduction ? MpesaConfig.production() : MpesaConfig.sandbox();
  }

  factory MpesaConfig.sandbox() {
    return MpesaConfig._(
      baseUrl: "https://sandbox.safaricom.co.ke",
      consumerKey: "yDDiiSxTAeqQaiWqFsH7DY9ETQav9pBWdkyFrymCQGvzLr97",
      consumerSecret: "0yIg2bIvTkWpJ2P4rnCu4VOFvXdWecrY5cyvg17aBIxxXxwPtNgj1WS6hVQkHhWQ",
      businessShortCode: "174379", // Mpesa sandbox shortcode
      passkey: "MTc0Mzc5YmZiMjc5ZjlhYTliZGJjZjE1OGU5N2RkNzFhNDY3Y2QyZTBjODkzMDU5YjEwZjc4ZTZiNzJhZGExZWQyYzkxOTIwMTYwMjE2MTY1NjI3",
      callBackURL: "https://us-central1-buricode-6e54c.cloudfunctions.net/handleMpesaCallback",
    );
  }

  factory MpesaConfig.production() {
    return MpesaConfig._(
      baseUrl: "https://api.safaricom.co.ke",
      consumerKey: "sWuAK847VPnXJLdxlyGuFzWlL1AIhoGW",
      consumerSecret: "0suB4AxiNV8hGVqX",
      businessShortCode: "4086809", // Your real shortcode
      passkey: "53beb23ef8b57ee44ef9b74349847a2909bbc169227e434067f36a711f2681a9",
      callBackURL: "https://us-central1-buricode-6e54c.cloudfunctions.net/handleMpesaCallback",
    );
  }
  factory MpesaConfig.productionB2c() {
    return MpesaConfig._(
      baseUrl: "https://api.safaricom.co.ke",
      consumerKey: "ufpmgp0hnaM4iwU7e9eitA2go8Z3KNRw",
      consumerSecret: "vXdfEAsbEFYEp7Ed",
      businessShortCode: "3031707", // Your real shortcode
      passkey: "53beb23ef8b57ee44ef9b74349847a2909bbc169227e434067f36a711f2681a9",
      callBackURL: "https://us-central1-buricode-6e54c.cloudfunctions.net/b2c/callback",
    );
  }
}