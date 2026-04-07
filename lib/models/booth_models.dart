class PublicBooth {
  final String boothUid;
  final String name;
  final String locationAddress;
  final double latitude;
  final double longitude;
  final int availableSlots;
  final String status;

  PublicBooth({
    required this.boothUid,
    required this.name,
    required this.locationAddress,
    required this.latitude,
    required this.longitude,
    required this.availableSlots,
    required this.status,
  });

  factory PublicBooth.fromJson(Map<String, dynamic> json) {
    // Safely parse latitude
    double lat = 0.0;
    if (json['latitude'] != null) {
      if (json['latitude'] is String) {
        lat = double.tryParse(json['latitude']) ?? 0.0;
      } else if (json['latitude'] is num) {
        lat = (json['latitude'] as num).toDouble();
      }
    }

    // Safely parse longitude
    double lng = 0.0;
    if (json['longitude'] != null) {
      if (json['longitude'] is String) {
        lng = double.tryParse(json['longitude']) ?? 0.0;
      } else if (json['longitude'] is num) {
        lng = (json['longitude'] as num).toDouble();
      }
    }

    // Safely parse availableSlots
    int slots = 0;
    if (json['availableSlots'] != null) {
      if (json['availableSlots'] is String) {
        slots = int.tryParse(json['availableSlots']) ?? 0;
      } else if (json['availableSlots'] is num) {
        slots = (json['availableSlots'] as num).toInt();
      }
    }

    return PublicBooth(
      boothUid: json['booth_uid'] ?? '',
      name: json['name'] ?? '',
      locationAddress: json['location_address'] ?? '',
      latitude: lat,
      longitude: lng,
      availableSlots: slots,
      status: json['status'] ?? '',
    );
  }
}

class MyBatteryStatus {
  final String batteryUid;
  final int chargeLevel;
  final String boothUid;
  final String slotIdentifier;
  final String sessionStatus;
  final Map<String, dynamic>? telemetry;

  MyBatteryStatus({
    required this.batteryUid,
    required this.chargeLevel,
    required this.boothUid,
    required this.slotIdentifier,
    required this.sessionStatus,
    this.telemetry,
  });

  factory MyBatteryStatus.fromJson(Map<String, dynamic> json) {
    return MyBatteryStatus(
      batteryUid: json['batteryUid'] ?? '',
      chargeLevel: json['chargeLevel'] ?? 0,
      boothUid: json['boothUid'] ?? '',
      slotIdentifier: json['slotIdentifier'] ?? '',
      sessionStatus: json['sessionStatus'] ?? '',
      telemetry: json['telemetry'],
    );
  }
}

class WithdrawalSession {
  final int sessionId;
  final double amount;
  final int durationMinutes;
  final int soc;
  final int initialCharge;
  final double baseSwapFee;
  final double costPerChargePercent;
  final String depositCompletedAt;
  final Map<String, dynamic> pricingRules;

  WithdrawalSession({
    required this.sessionId,
    required this.amount,
    required this.durationMinutes,
    required this.soc,
    required this.initialCharge,
    required this.baseSwapFee,
    required this.costPerChargePercent,
    required this.depositCompletedAt,
    required this.pricingRules,
  });

  factory WithdrawalSession.fromJson(Map<String, dynamic> json) {
    return WithdrawalSession(
      sessionId: json['sessionId'] ?? 0,
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      durationMinutes: json['durationMinutes'] ?? 0,
      soc: json['soc'] ?? 0,
      initialCharge: json['initialCharge'] ?? 0,
      baseSwapFee: (json['baseSwapFee'] as num?)?.toDouble() ?? 0.0,
      costPerChargePercent: (json['costPerChargePercent'] as num?)?.toDouble() ?? 0.0,
      depositCompletedAt: json['depositCompletedAt'] ?? '',
      pricingRules: json['pricingRules'] ?? {},
    );
  }
}

class UserTransaction {
  final String id;
  final String type;
  final double amount;
  final String date;
  final String status;

  UserTransaction({
    required this.id,
    required this.type,
    required this.amount,
    required this.date,
    required this.status,
  });

  factory UserTransaction.fromJson(Map<String, dynamic> json) {
    return UserTransaction(
      id: json['id'] ?? '',
      type: json['type'] ?? '',
      amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
      date: json['date'] ?? '',
      status: json['status'] ?? '',
    );
  }
}
