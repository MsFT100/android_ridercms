double numOrZero(dynamic value, [double fallback = 0]) {
  if (value == null) return fallback;
  if (value is num) return value.toDouble();
  if (value is String) return double.tryParse(value) ?? fallback;
  return fallback;
}

int intOrZero(dynamic value, [int fallback = 0]) {
  if (value == null) return fallback;
  if (value is int) return value;
  if (value is num) return value.toInt();
  if (value is String) return int.tryParse(value) ?? fallback;
  return fallback;
}

String stringOrEmpty(dynamic value) {
  if (value == null) return '';
  return value.toString();
}

bool asBool(dynamic value, [bool fallback = false]) {
  if (value == null) return fallback;
  if (value is bool) return value;
  if (value is num) return value != 0;
  if (value is String) return value.toLowerCase() == 'true';
  return fallback;
}

/// Rider-facing rental rules (`GET /api/booths/rentals/status`).
class RentalFeatureStatus {
  final bool enabled;
  final bool requireBoothScanBeforeIssue;
  final bool requireReturnScan;
  final bool allowRentalWhileOwnBatteryCharging;
  final int maxRentalBatteriesPerUser;
  final int minimumSocPercent;

  RentalFeatureStatus({
    this.enabled = false,
    this.requireBoothScanBeforeIssue = false,
    this.requireReturnScan = false,
    this.allowRentalWhileOwnBatteryCharging = true,
    this.maxRentalBatteriesPerUser = 1,
    this.minimumSocPercent = 50,
  });

  factory RentalFeatureStatus.fromJson(Map<String, dynamic> json) {
    return RentalFeatureStatus(
      enabled: asBool(json['enabled']),
      requireBoothScanBeforeIssue: asBool(json['requireBoothScanBeforeIssue']),
      requireReturnScan: asBool(json['requireReturnScan']),
      allowRentalWhileOwnBatteryCharging:
          asBool(json['allowRentalWhileOwnBatteryCharging'], true),
      maxRentalBatteriesPerUser: intOrZero(json['maxRentalBatteriesPerUser'], 1),
      minimumSocPercent: intOrZero(json['minimumSocPercent'], 50),
    );
  }
}

/// A borrowable (unowned) battery sitting in a booth slot.
class RentalBatteryOption {
  final int slotId;
  final String slotIdentifier;
  final int batteryId;
  final String batteryUid;
  final int chargeLevel;

  RentalBatteryOption({
    required this.slotId,
    required this.slotIdentifier,
    required this.batteryId,
    required this.batteryUid,
    required this.chargeLevel,
  });

  factory RentalBatteryOption.fromJson(Map<String, dynamic> json) {
    return RentalBatteryOption(
      slotId: intOrZero(json['slotId']),
      slotIdentifier: stringOrEmpty(json['slotIdentifier']),
      batteryId: intOrZero(json['batteryId']),
      batteryUid: stringOrEmpty(json['batteryUid']),
      chargeLevel: intOrZero(json['chargeLevel']),
    );
  }
}

/// Response of `GET /api/booths/rentals/available?boothUid=`.
class AvailableRentalBatteries {
  final String boothUid;
  final List<RentalBatteryOption> rentals;
  final bool hasPendingRental;
  final int rentalLimit;
  final int activeRentalCount;

  AvailableRentalBatteries({
    required this.boothUid,
    required this.rentals,
    this.hasPendingRental = false,
    this.rentalLimit = 1,
    this.activeRentalCount = 0,
  });

  bool get canRent => activeRentalCount < rentalLimit;

  /// The rider never chooses a battery — the highest-SOC option is used.
  RentalBatteryOption? get best {
    if (rentals.isEmpty) return null;
    final sorted = List<RentalBatteryOption>.from(rentals)
      ..sort((a, b) => b.chargeLevel.compareTo(a.chargeLevel));
    return sorted.first;
  }

  factory AvailableRentalBatteries.fromJson(Map<String, dynamic> json) {
    final dynamic raw = json['rentals'];
    final list = raw is List
        ? raw
            .whereType<Map>()
            .map((e) => RentalBatteryOption.fromJson(Map<String, dynamic>.from(e)))
            .toList()
        : <RentalBatteryOption>[];
    return AvailableRentalBatteries(
      boothUid: stringOrEmpty(json['boothUid']),
      rentals: list,
      hasPendingRental: asBool(json['hasPendingRental']),
      rentalLimit: intOrZero(json['rentalLimit'], 1),
      activeRentalCount: intOrZero(json['activeRentalCount']),
    );
  }
}

/// A booth + slot reference used by several rental payloads.
class RentalSlotRef {
  final String boothUid;
  final String slotIdentifier;

  const RentalSlotRef({this.boothUid = '', this.slotIdentifier = ''});

  bool get isValid => boothUid.isNotEmpty && slotIdentifier.isNotEmpty;

  factory RentalSlotRef.fromJson(dynamic json) {
    if (json is! Map) return RentalSlotRef();
    return RentalSlotRef(
      boothUid: stringOrEmpty(json['boothUid']),
      slotIdentifier: stringOrEmpty(json['slotIdentifier']),
    );
  }
}

/// The rider's own deposited battery, consumed as rental credit.
class OwnDepositInfo {
  final int depositId;
  final String boothUid;
  final String slotIdentifier;
  final int? initialSoc;
  final int? currentSoc;

  const OwnDepositInfo({
    this.depositId = 0,
    this.boothUid = '',
    this.slotIdentifier = '',
    this.initialSoc,
    this.currentSoc,
  });

  factory OwnDepositInfo.fromJson(dynamic json) {
    if (json is! Map) return OwnDepositInfo();
    return OwnDepositInfo(
      depositId: intOrZero(json['depositId']),
      boothUid: stringOrEmpty(json['boothUid']),
      slotIdentifier: stringOrEmpty(json['slotIdentifier']),
      initialSoc: json['initialSoc'] == null
          ? null
          : numOrZero(json['initialSoc']).round(),
      currentSoc: json['currentSoc'] == null
          ? null
          : numOrZero(json['currentSoc']).round(),
    );
  }
}

/// Locally-carried rental assignment (booth QR scan already done).
class AssignedRental {
  final String boothUid;
  final String boothName;
  final String slotIdentifier;
  final String batteryUid;
  final int chargeLevel;

  AssignedRental({
    required this.boothUid,
    required this.boothName,
    required this.slotIdentifier,
    required this.batteryUid,
    required this.chargeLevel,
  });

  factory AssignedRental.fromOption(
    RentalBatteryOption option, {
    required String boothUid,
    required String boothName,
  }) {
    return AssignedRental(
      boothUid: boothUid,
      boothName: boothName,
      slotIdentifier: option.slotIdentifier,
      batteryUid: option.batteryUid,
      chargeLevel: option.chargeLevel,
    );
  }
}

/// Response of `POST /api/booths/rentals/issue`.
class IssueRentalResult {
  final int sessionId;
  final String batteryUid;
  final int chargeLevel;
  final String status;
  final OwnDepositInfo? ownDeposit;

  IssueRentalResult({
    required this.sessionId,
    required this.batteryUid,
    required this.chargeLevel,
    required this.status,
    this.ownDeposit,
  });

  factory IssueRentalResult.fromJson(Map<String, dynamic> json) {
    return IssueRentalResult(
      sessionId: intOrZero(json['sessionId']),
      batteryUid: stringOrEmpty(json['batteryUid']),
      chargeLevel: intOrZero(json['chargeLevel']),
      status: stringOrEmpty(json['status']),
      ownDeposit: json['ownDeposit'] == null
          ? null
          : OwnDepositInfo.fromJson(json['ownDeposit']),
    );
  }
}

/// Response of `GET /api/booths/rentals/active` (204 → null).
class ActiveRental {
  final int sessionId;
  final String status;
  final String? issuedAt;
  final String? startedAt;
  final int? issueSoc;
  final double? amount;
  final String? checkoutRequestId;
  final String batteryUid;
  final RentalSlotRef sourceSlot;
  final bool returned;
  final bool returnCompleted;
  final int? returnSoc;
  final RentalSlotRef? returnSlot;
  final OwnDepositInfo ownDeposit;

  ActiveRental({
    required this.sessionId,
    required this.status,
    this.issuedAt,
    this.startedAt,
    this.issueSoc,
    this.amount,
    this.checkoutRequestId,
    this.batteryUid = '',
    this.sourceSlot = const RentalSlotRef(),
    this.returned = false,
    this.returnCompleted = false,
    this.returnSoc,
    this.returnSlot,
    this.ownDeposit = const OwnDepositInfo(),
  });

  bool get isPending => status.toLowerCase() == 'pending';
  bool get isActive => status.toLowerCase() == 'in_progress';

  factory ActiveRental.fromJson(Map<String, dynamic> json) {
    final dynamic battery = json['rentalBattery'];
    return ActiveRental(
      sessionId: intOrZero(json['sessionId']),
      status: stringOrEmpty(json['status']),
      issuedAt: json['issuedAt']?.toString(),
      startedAt: json['startedAt']?.toString(),
      issueSoc: json['issueSoc'] == null ? null : intOrZero(json['issueSoc']),
      amount:
          json['amount'] == null ? null : numOrZero(json['amount']),
      checkoutRequestId: json['checkoutRequestId']?.toString(),
      batteryUid: battery is Map ? stringOrEmpty(battery['batteryUid']) : '',
      sourceSlot: RentalSlotRef.fromJson(json['sourceSlot']),
      returned: asBool(json['returned']),
      returnCompleted: asBool(json['returnCompleted']),
      returnSoc: json['returnSoc'] == null ? null : intOrZero(json['returnSoc']),
      returnSlot: json['returnSlot'] == null
          ? null
          : RentalSlotRef.fromJson(json['returnSlot']),
      ownDeposit: OwnDepositInfo.fromJson(json['ownDeposit']),
    );
  }
}

/// Bill breakdown shared by `GET /rentals/:id/bill` and `POST /rentals/:id/pay`.
class RentalBillConsolidation {
  final double ownCharging;
  final double rentalEnergy;
  final double rentalTime;
  final int durationMinutes;
  final double energyGone;
  final double ownGained;

  RentalBillConsolidation({
    this.ownCharging = 0,
    this.rentalEnergy = 0,
    this.rentalTime = 0,
    this.durationMinutes = 0,
    this.energyGone = 0,
    this.ownGained = 0,
  });

  factory RentalBillConsolidation.fromJson(dynamic json) {
    if (json is! Map) return RentalBillConsolidation();
    return RentalBillConsolidation(
      ownCharging: numOrZero(json['ownCharging']),
      rentalEnergy: numOrZero(json['rentalEnergy']),
      rentalTime: numOrZero(json['rentalTime']),
      durationMinutes: intOrZero(json['durationMinutes']),
      energyGone: numOrZero(json['energyGone']),
      ownGained: numOrZero(json['ownGained']),
    );
  }
}

/// Response of `GET /api/booths/rentals/:sessionId/bill`.
class RentalBill {
  final int sessionId;
  final double amount;
  final RentalBillConsolidation consolidation;

  RentalBill({
    required this.sessionId,
    required this.amount,
    required this.consolidation,
  });

  factory RentalBill.fromJson(Map<String, dynamic> json) {
    return RentalBill(
      sessionId: intOrZero(json['sessionId']),
      amount: numOrZero(json['amount']),
      consolidation: RentalBillConsolidation.fromJson(json['consolidation']),
    );
  }
}

/// Response of `POST /api/booths/rentals/:sessionId/pay`.
class PayRentalResult {
  final double amount;
  final RentalBillConsolidation consolidation;
  final String? checkoutRequestId;
  final String paymentStatus;

  PayRentalResult({
    required this.amount,
    required this.consolidation,
    this.checkoutRequestId,
    this.paymentStatus = 'pending',
  });

  bool get isPaid => paymentStatus.toLowerCase() == 'paid';

  factory PayRentalResult.fromJson(Map<String, dynamic> json) {
    return PayRentalResult(
      amount: numOrZero(json['amount']),
      consolidation: RentalBillConsolidation.fromJson(json['consolidation']),
      checkoutRequestId: json['checkoutRequestId']?.toString(),
      paymentStatus: stringOrEmpty(json['paymentStatus']),
    );
  }
}

/// Response of `POST /api/booths/rentals/:sessionId/return`.
class ReturnRentalResult {
  final String message;
  final RentalSlotRef returnSlot;
  final String batteryUid;
  final bool simulated;

  ReturnRentalResult({
    required this.message,
    required this.returnSlot,
    this.batteryUid = '',
    this.simulated = false,
  });

  factory ReturnRentalResult.fromJson(Map<String, dynamic> json) {
    return ReturnRentalResult(
      message: stringOrEmpty(json['message']),
      returnSlot: RentalSlotRef.fromJson(json['returnSlot']),
      batteryUid: stringOrEmpty(json['batteryUid']),
      simulated: asBool(json['simulated']),
    );
  }
}

/// Response of `POST /api/booths/rentals/:sessionId/unlock-own`.
class UnlockOwnResult {
  final String message;
  final RentalSlotRef ownSlot;

  UnlockOwnResult({required this.message, required this.ownSlot});

  factory UnlockOwnResult.fromJson(Map<String, dynamic> json) {
    return UnlockOwnResult(
      message: stringOrEmpty(json['message']),
      ownSlot: RentalSlotRef.fromJson(json['ownSlot']),
    );
  }
}
