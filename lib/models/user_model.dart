class UserModel {
  final String id;
  final String email;
  final String name;
  final String? phoneNumber;
  final String? role;
  final String? status;
  final bool? phoneVerified;
  final double? balance;
  final String? profileImageUrl;
  final ActiveBatterySession? activeBatterySession;

  UserModel({
    required this.id,
    required this.email,
    required this.name,
    this.phoneNumber,
    this.role,
    this.status,
    this.phoneVerified,
    this.balance,
    this.profileImageUrl,
    this.activeBatterySession,
  });

  factory UserModel.fromJson(Map<String, dynamic> json) {
    // Safely handle balance which could be String, double, or null
    double? parsedBalance;
    if (json['balance'] != null) {
      if (json['balance'] is String) {
        parsedBalance = double.tryParse(json['balance']);
      } else if (json['balance'] is num) {
        parsedBalance = (json['balance'] as num).toDouble();
      }
    }

    return UserModel(
      id: json['id'] ?? json['user_id'] ?? '',
      email: json['email'] ?? '',
      name: json['name'] ?? '',
      phoneNumber: json['phoneNumber'] ?? json['phone'],
      role: json['role'],
      status: json['status'],
      phoneVerified: json['phoneVerified'] ?? json['phone_verified'],
      balance: parsedBalance,
      profileImageUrl: json['profileImageUrl'] ?? json['profile_image_url'],
      activeBatterySession: json['activeBatterySession'] != null
          ? ActiveBatterySession.fromJson(json['activeBatterySession'])
          : null,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'email': email,
      'name': name,
      'phoneNumber': phoneNumber,
      'role': role,
      'status': status,
      'phoneVerified': phoneVerified,
      'balance': balance,
      'profileImageUrl': profileImageUrl,
      'activeBatterySession': activeBatterySession?.toJson(),
    };
  }
}

class ActiveBatterySession {
  final String batteryUid;
  final int chargeLevel;
  final String boothUid;
  final String slotIdentifier;

  ActiveBatterySession({
    required this.batteryUid,
    required this.chargeLevel,
    required this.boothUid,
    required this.slotIdentifier,
  });

  factory ActiveBatterySession.fromJson(Map<String, dynamic> json) {
    return ActiveBatterySession(
      batteryUid: json['batteryUid'] ?? '',
      chargeLevel: json['chargeLevel'] ?? 0,
      boothUid: json['boothUid'] ?? '',
      slotIdentifier: json['slotIdentifier'] ?? '',
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'batteryUid': batteryUid,
      'chargeLevel': chargeLevel,
      'boothUid': boothUid,
      'slotIdentifier': slotIdentifier,
    };
  }
}
