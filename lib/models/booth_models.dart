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

/// Safely reads a number from JSON that may arrive as `int`, `double` or
/// `String` (the hardware bridge is not consistent about this).
double _asDouble(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int _asInt(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

bool _asBool(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

/// Live telemetry reported by the slot controller through Firebase.
///
/// Field names mirror the device payload. Temperature in particular arrives
/// under either `temperature` or `temperatureC` depending on firmware, so the
/// accessor always prefers `temperature` and falls back to `temperatureC`.
class BatteryTelemetry {
  final bool batteryInserted;
  final bool devicePresent;
  final bool doorClosed;
  final bool doorLocked;
  final bool plugConnected;
  final bool relayOn;
  final double soc;
  final double? temperature;
  final double? voltage;
  final double? restVoltage;
  final int? timestamp;
  final String? status;
  final String? qr;
  final Map<String, dynamic> raw;

  BatteryTelemetry({
    this.batteryInserted = false,
    this.devicePresent = false,
    this.doorClosed = false,
    this.doorLocked = false,
    this.plugConnected = false,
    this.relayOn = false,
    this.soc = 0,
    this.temperature,
    this.voltage,
    this.restVoltage,
    this.timestamp,
    this.status,
    this.qr,
    this.raw = const {},
  });

  /// Whether the device actually reported `batteryInserted`. A partial payload
  /// parses to `batteryInserted == false`, which must not be read as "removed".
  bool get reportsInsertion => raw.containsKey('batteryInserted');

  /// Preferred temperature, tolerating both firmware field names.
  double? get temperatureC => temperature;

  factory BatteryTelemetry.fromJson(Map<String, dynamic> json) {
    return BatteryTelemetry(
      batteryInserted: _asBool(json['batteryInserted']),
      devicePresent: _asBool(json['devicePresent']),
      doorClosed: _asBool(json['doorClosed']),
      doorLocked: _asBool(json['doorLocked']),
      plugConnected: _asBool(json['plugConnected']),
      relayOn: _asBool(json['relayOn']),
      soc: _asDouble(json['soc']),
      temperature: json['temperature'] != null
          ? _asDouble(json['temperature'])
          : (json['temperatureC'] != null ? _asDouble(json['temperatureC']) : null),
      voltage: json['voltage'] != null ? _asDouble(json['voltage']) : null,
      restVoltage:
          json['restVoltage'] != null ? _asDouble(json['restVoltage']) : null,
      timestamp: json['timestamp'] != null ? _asInt(json['timestamp']) : null,
      status: json['status']?.toString(),
      qr: json['qr']?.toString(),
      raw: json,
    );
  }
}

/// One of the rider's own batteries, as returned (in an **array**) by
/// `GET /api/booths/my-battery-status`.
class MyBatteryStatus {
  final int sessionId;
  final String boothUid;
  final String slotIdentifier;
  final int chargeLevel;
  final int lastChargeLevel;
  final String sessionStatus;
  final BatteryTelemetry? telemetry;

  MyBatteryStatus({
    required this.sessionId,
    required this.boothUid,
    required this.slotIdentifier,
    required this.chargeLevel,
    this.lastChargeLevel = 0,
    required this.sessionStatus,
    this.telemetry,
  });

  /// Stable identity for list diffing. `sessionId` is unique per deposit, the
  /// slot pair is used as a fallback for payloads without an id.
  String get key => sessionId > 0 ? 'session-$sessionId' : '$boothUid/$slotIdentifier';

  /// Best-known SOC: live telemetry first, then the polled charge level.
  int get soc => telemetry != null && telemetry!.soc > 0
      ? telemetry!.soc.round()
      : chargeLevel;

  /// `true` while the deposit is still being confirmed by the hardware.
  bool get isPending => sessionStatus.toLowerCase() == 'pending';

  /// `true` when the backend has put the deposit in a terminal state.
  bool get isTerminal {
    switch (sessionStatus.toLowerCase()) {
      case 'cancelled':
      case 'failed':
      case 'collected':
        return true;
      default:
        return false;
    }
  }

  /// `true` when a physical battery is still inside the slot.
  bool get hasBattery => telemetry?.batteryInserted ?? chargeLevel > 0;

  MyBatteryStatus copyWith({
    int? chargeLevel,
    int? lastChargeLevel,
    String? sessionStatus,
    BatteryTelemetry? telemetry,
  }) {
    return MyBatteryStatus(
      sessionId: sessionId,
      boothUid: boothUid,
      slotIdentifier: slotIdentifier,
      chargeLevel: chargeLevel ?? this.chargeLevel,
      lastChargeLevel: lastChargeLevel ?? this.lastChargeLevel,
      sessionStatus: sessionStatus ?? this.sessionStatus,
      telemetry: telemetry ?? this.telemetry,
    );
  }

  factory MyBatteryStatus.fromJson(Map<String, dynamic> json) {
    final dynamic rawTelemetry = json['telemetry'];
    return MyBatteryStatus(
      sessionId: _asInt(json['sessionId']),
      boothUid: json['boothUid']?.toString() ?? '',
      slotIdentifier: json['slotIdentifier']?.toString() ?? '',
      chargeLevel: _asInt(json['chargeLevel']),
      lastChargeLevel: _asInt(json['lastChargeLevel']),
      sessionStatus: json['sessionStatus']?.toString() ?? '',
      telemetry: rawTelemetry is Map
          ? BatteryTelemetry.fromJson(Map<String, dynamic>.from(rawTelemetry))
          : null,
    );
  }

  /// Parses the array payload of `GET /api/booths/my-battery-status`.
  /// A `null` body (no batteries) yields an empty list.
  static List<MyBatteryStatus> listFromJson(dynamic data) {
    if (data == null) return [];
    final List<dynamic> items = data is List ? data : [data];
    return items
        .whereType<Map>()
        .map((item) => MyBatteryStatus.fromJson(Map<String, dynamic>.from(item)))
        .toList();
  }
}

/// Lifecycle status of a single deposit session
/// (`GET /api/booths/deposit-sessions/:sessionId/status`).
class DepositSessionStatus {
  final int sessionId;
  final String sessionType;
  final String sessionStatus;
  final String boothUid;
  final String slotIdentifier;

  DepositSessionStatus({
    required this.sessionId,
    required this.sessionType,
    required this.sessionStatus,
    required this.boothUid,
    required this.slotIdentifier,
  });

  bool get isTerminal {
    switch (sessionStatus.toLowerCase()) {
      case 'cancelled':
      case 'failed':
      case 'collected':
        return true;
      default:
        return false;
    }
  }

  factory DepositSessionStatus.fromJson(Map<String, dynamic> json) {
    return DepositSessionStatus(
      sessionId: _asInt(json['sessionId']),
      sessionType: json['sessionType']?.toString() ?? '',
      sessionStatus: json['sessionStatus']?.toString() ?? '',
      boothUid: json['boothUid']?.toString() ?? '',
      slotIdentifier: json['slotIdentifier']?.toString() ?? '',
    );
  }
}

class WithdrawalSession {
  final int sessionId;
  final double amount;
  final int durationMinutes;
  final int soc;
  final int initialCharge;
  final double socAtWithdrawal;
  final String boothUid;
  final String slotIdentifier;
  final String depositCompletedAt;

  WithdrawalSession({
    required this.sessionId,
    required this.amount,
    required this.durationMinutes,
    required this.soc,
    this.initialCharge = 0,
    this.socAtWithdrawal = 0,
    this.boothUid = '',
    this.slotIdentifier = '',
    this.depositCompletedAt = '',
  });

  factory WithdrawalSession.fromJson(Map<String, dynamic> json) {
    return WithdrawalSession(
      sessionId: _asInt(json['sessionId']),
      amount: _asDouble(json['amount']),
      durationMinutes: _asInt(json['durationMinutes']),
      soc: _asDouble(json['soc']).round(),
      initialCharge: _asDouble(json['initialCharge']).round(),
      socAtWithdrawal: _asDouble(json['socAtWithdrawal']),
      boothUid: json['boothUid']?.toString() ?? '',
      slotIdentifier: json['slotIdentifier']?.toString() ?? '',
      depositCompletedAt: json['depositCompletedAt']?.toString() ?? '',
    );
  }
}

/// One row of `GET /booths/history` (latest 50 sessions, newest first).
///
/// The endpoint returns `sessionType`, `status`, `startedAt`, `completedAt`,
/// `boothUid`, `slotIdentifier` and `batteryUid`; `amount` is only read when
/// present.
class UserTransaction {
  final String sessionType;
  final String status;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String boothUid;
  final String slotIdentifier;
  final String? batteryUid;
  final double? amount;

  UserTransaction({
    required this.sessionType,
    required this.status,
    this.startedAt,
    this.completedAt,
    this.boothUid = '',
    this.slotIdentifier = '',
    this.batteryUid,
    this.amount,
  });

  /// Most relevant timestamp for display.
  DateTime? get date => completedAt ?? startedAt;

  factory UserTransaction.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) =>
        value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

    final dynamic rawAmount = json['amount'];
    return UserTransaction(
      sessionType: (json['sessionType'] ?? json['type'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      startedAt: parseDate(json['startedAt'] ?? json['date']),
      completedAt: parseDate(json['completedAt']),
      boothUid: json['boothUid']?.toString() ?? '',
      slotIdentifier: json['slotIdentifier']?.toString() ?? '',
      batteryUid: json['batteryUid']?.toString(),
      amount: rawAmount is num
          ? rawAmount.toDouble()
          : double.tryParse(rawAmount?.toString() ?? ''),
    );
  }
}

/// A rider's M-Pesa payment from `GET /booths/payments`.
class UserPayment {
  final String sessionType;
  final String status;
  final double amount;
  final DateTime? startedAt;
  final DateTime? completedAt;
  final String boothName;
  final String? receiptNumber;
  final int? resultCode;

  UserPayment({
    required this.sessionType,
    required this.status,
    required this.amount,
    this.startedAt,
    this.completedAt,
    this.boothName = '',
    this.receiptNumber,
    this.resultCode,
  });

  /// Most relevant timestamp for display.
  DateTime? get date => completedAt ?? startedAt;

  /// M-Pesa reports ResultCode 0 for a successful charge.
  bool get isPaid => resultCode == 0;

  /// The STK push failed or was cancelled by the rider.
  bool get isFailed => resultCode != null && resultCode != 0;

  factory UserPayment.fromJson(Map<String, dynamic> json) {
    DateTime? parseDate(dynamic value) =>
        value == null ? null : DateTime.tryParse(value.toString())?.toLocal();

    final dynamic rawAmount = json['amount'];
    return UserPayment(
      sessionType: (json['sessionType'] ?? '').toString(),
      status: (json['status'] ?? '').toString(),
      amount: rawAmount is num
          ? rawAmount.toDouble()
          : double.tryParse(rawAmount?.toString() ?? '') ?? 0,
      startedAt: parseDate(json['startedAt']),
      completedAt: parseDate(json['completedAt']),
      boothName: (json['boothName'] ?? json['boothUid'] ?? '').toString(),
      receiptNumber: json['receiptNumber']?.toString(),
      resultCode: int.tryParse(json['resultCode']?.toString() ?? ''),
    );
  }
}
