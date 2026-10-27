import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart' as http;
import '../config/app_config.dart';
import '../models/booth_models.dart';
import '../models/rental_models.dart';

/// Error surfaced by any booth/rental endpoint.
///
/// The backend replies with `{ error, message? }` where `error` is a short
/// human label ("Rental limit reached") and `message` is the rider-facing copy.
/// Both are kept so callers can branch on [code] and still show [message].
class BoothApiException implements Exception {
  final String message;
  final String code;
  final int statusCode;

  BoothApiException(this.message, {this.code = '', this.statusCode = 0});

  bool get isAuthError => statusCode == 401 || statusCode == 403;

  bool get isRentalLimit {
    final haystack = '$code $message'.toLowerCase();
    return haystack.contains('rental limit') ||
        haystack.contains('maximum number of concurrent rentals');
  }

  bool get isActiveRental => code.toLowerCase().contains('active_rental');

  bool get isNoDepositedBattery =>
      code.toLowerCase().contains('no_deposited_battery') ||
      message.toLowerCase().contains('deposit your own battery first');

  @override
  String toString() => message;
}

class BoothService {
  final String _baseUrl = AppConfig.baseUrl;
  final Duration _timeout = const Duration(seconds: 15);

  // `/my-battery-status` is ETag-cached. These are static so the tag survives
  // the short-lived controller/service instances used across screens.
  static String? _statusEtag;
  static String? _statusCacheToken;
  static List<MyBatteryStatus> _statusCache = const [];

  Map<String, String> _headers(String token, {bool json = false}) {
    return {
      'Authorization': 'Bearer $token',
      if (json) 'Content-Type': 'application/json',
    };
  }

  dynamic _decode(http.Response response) {
    if (response.body.trim().isEmpty) return null;
    try {
      return json.decode(response.body);
    } catch (_) {
      return null;
    }
  }

  /// Builds a typed error from a non-success response.
  BoothApiException _errorFrom(http.Response response, String fallback) {
    final data = _decode(response);
    String code = '';
    String message = fallback;
    if (data is Map) {
      code = data['error']?.toString() ?? '';
      final serverMessage = data['message']?.toString();
      if (serverMessage != null && serverMessage.isNotEmpty) {
        message = serverMessage;
      } else if (code.isNotEmpty) {
        message = code;
      }
    }
    return BoothApiException(
      message,
      code: code,
      statusCode: response.statusCode,
    );
  }

  void _ensureSuccess(http.Response response, String fallback) {
    if (response.statusCode >= 200 && response.statusCode < 300) return;
    throw _errorFrom(response, fallback);
  }

  /// Fetches a list of all public, online booths.
  Future<List<PublicBooth>> getBooths(String token) async {
    try {
      final response = await http
          .get(Uri.parse('$_baseUrl/booths'), headers: _headers(token))
          .timeout(_timeout);

      if (response.statusCode == 200) {
        final data = _decode(response);
        if (data is List) {
          return data
              .whereType<Map>()
              .map((json) => PublicBooth.fromJson(Map<String, dynamic>.from(json)))
              .toList();
        }
      }
      return [];
    } catch (e) {
      debugPrint('Failed to fetch public booths: $e');
      rethrow;
    }
  }

  /// Initiates a battery deposit session.
  ///
  /// Returns `{ slot: { identifier, status }, sessionId }`.
  Future<Map<String, dynamic>> initiateDeposit(
    String token,
    String boothUid,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/booths/initiate-deposit'),
            headers: _headers(token, json: true),
            body: json.encode({'boothUid': boothUid}),
          )
          .timeout(_timeout);

      _ensureSuccess(response, 'Failed to initiate deposit');
      final data = _decode(response);
      if (data is Map) return Map<String, dynamic>.from(data);
      throw BoothApiException(
        'Unexpected deposit response',
        statusCode: response.statusCode,
      );
    } catch (e) {
      debugPrint('Failed to initiate deposit: $e');
      rethrow;
    }
  }

  /// Returns **all** of the rider's deposited batteries.
  ///
  /// The endpoint replies with an array (or `null` when there are none) and may
  /// answer `304 Not Modified` for an unchanged ETag. A `304` therefore returns
  /// the cached list instead of an empty result.
  Future<List<MyBatteryStatus>> getMyBatteryStatuses(
    String token, {
    bool forceRefresh = false,
  }) async {
    try {
      final headers = _headers(token);
      // Ask the backend to skip its non-essential DB sync while polling.
      headers['x-purpose'] = 'poll';
      if (!forceRefresh &&
          _statusCacheToken == token &&
          _statusEtag != null) {
        headers['If-None-Match'] = _statusEtag!;
      }

      final response = await http
          .get(
            Uri.parse('$_baseUrl/booths/my-battery-status'),
            headers: headers,
          )
          .timeout(_timeout);

      if (response.statusCode == 304) {
        return List<MyBatteryStatus>.from(_statusCache);
      }
      if (response.statusCode == 204) {
        _rememberStatuses(token, const [], null);
        return [];
      }
      if (response.statusCode == 401 || response.statusCode == 403) {
        // An auth failure is not "nothing changed": drop the cache and let the
        // caller refresh the token or sign the rider out.
        _rememberStatuses(token, const [], null);
        throw _errorFrom(response, 'Session expired');
      }
      if (response.statusCode != 200) {
        debugPrint(
          'Status polling failed: ${response.statusCode} - ${response.body}',
        );
        return List<MyBatteryStatus>.from(_statusCache);
      }

      final list = MyBatteryStatus.listFromJson(_decode(response));
      _rememberStatuses(token, list, response.headers['etag']);
      return List<MyBatteryStatus>.from(list);
    } on BoothApiException {
      rethrow;
    } catch (e) {
      debugPrint('Polling error in service: $e');
      // Keep polling: fall back to the last known good payload.
      return List<MyBatteryStatus>.from(_statusCache);
    }
  }

  void _rememberStatuses(
    String token,
    List<MyBatteryStatus> list,
    String? etag,
  ) {
    _statusCache = List<MyBatteryStatus>.from(list);
    _statusCacheToken = token;
    _statusEtag = etag;
  }

  /// Single-battery convenience wrapper over [getMyBatteryStatuses].
  Future<MyBatteryStatus?> getMyBatteryStatus(String token) async {
    final statuses = await getMyBatteryStatuses(token);
    return statuses.isEmpty ? null : statuses.first;
  }

  /// Fetches the rider's pending withdrawal sessions (array, `204` when none).
  Future<List<WithdrawalSession>> getPendingWithdrawals(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/booths/sessions/pending-withdrawal'),
            headers: _headers(token),
          )
          .timeout(_timeout);

      if (response.statusCode == 204) return [];
      // Any other failure must not read as "no pending payment".
      _ensureSuccess(response, 'Failed to fetch pending withdrawals');

      final data = _decode(response);
      if (data is List) {
        return data
            .whereType<Map>()
            .map((e) => WithdrawalSession.fromJson(Map<String, dynamic>.from(e)))
            .toList();
      }
      if (data is Map && data.isNotEmpty) {
        return [WithdrawalSession.fromJson(Map<String, dynamic>.from(data))];
      }
      return [];
    } catch (e) {
      debugPrint('Error fetching pending withdrawal: $e');
      rethrow;
    }
  }

  /// First pending withdrawal, if any (kept for single-battery call sites).
  Future<WithdrawalSession?> getPendingWithdrawal(String token) async {
    final sessions = await getPendingWithdrawals(token);
    return sessions.isEmpty ? null : sessions.first;
  }

  /// Stops charging for one specific deposit session.
  Future<Map<String, dynamic>> stopCharging(
    String token,
    int sessionId,
  ) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/booths/stop-charging'),
          headers: _headers(token, json: true),
          body: json.encode({'sessionId': sessionId}),
        )
        .timeout(_timeout);

    final data = _decode(response);
    // 409 is a valid "already stopped" answer and carries the same payload.
    if (response.statusCode == 200 || response.statusCode == 409) {
      return data is Map ? Map<String, dynamic>.from(data) : {};
    }
    throw _errorFrom(response, 'Failed to stop charging');
  }

  /// Creates the withdrawal session for one deposited battery.
  Future<WithdrawalSession> initiateWithdrawal(
    String token,
    int sessionId,
  ) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/booths/initiate-withdrawal'),
          headers: _headers(token, json: true),
          body: json.encode({'sessionId': sessionId}),
        )
        .timeout(_timeout);

    _ensureSuccess(response, 'Failed to initiate withdrawal');
    final data = _decode(response);
    if (data is Map) {
      return WithdrawalSession.fromJson(Map<String, dynamic>.from(data));
    }
    throw BoothApiException(
      'Unexpected withdrawal response',
      statusCode: response.statusCode,
    );
  }

  /// Triggers M-Pesa STK push for a session.
  Future<String> payForWithdrawal(String token, int sessionId) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/booths/sessions/$sessionId/pay'),
          headers: _headers(token),
        )
        .timeout(_timeout);

    _ensureSuccess(response, 'Failed to initiate M-Pesa payment');
    final data = _decode(response);
    final checkoutRequestId =
        data is Map ? data['checkoutRequestId']?.toString() : null;
    if (checkoutRequestId == null || checkoutRequestId.isEmpty) {
      throw BoothApiException(
        'M-Pesa did not return a checkout id',
        statusCode: response.statusCode,
      );
    }
    return checkoutRequestId;
  }

  /// Polls for withdrawal payment status.
  Future<String> getWithdrawalStatus(
    String token,
    String checkoutRequestId,
  ) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/booths/withdrawal-status/$checkoutRequestId'),
          headers: _headers(token),
        )
        .timeout(_timeout);

    _ensureSuccess(response, 'Failed to check payment status');
    final data = _decode(response);
    return data is Map ? (data['paymentStatus']?.toString() ?? 'pending') : 'pending';
  }

  /// Opens the slot for collection after payment.
  Future<void> openForCollection(
    String token,
    String checkoutRequestId,
  ) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/booths/open-for-collection'),
          headers: _headers(token, json: true),
          body: json.encode({'checkoutRequestId': checkoutRequestId}),
        )
        .timeout(_timeout);

    _ensureSuccess(response, 'Failed to open slot for collection');
  }

  /// Releases a paid battery after scanning the booth QR.
  Future<Map<String, dynamic>> releaseBattery(
    String token,
    String boothUid,
  ) async {
    try {
      final response = await http
          .post(
            Uri.parse('$_baseUrl/booths/release-battery'),
            headers: _headers(token, json: true),
            body: json.encode({'boothUid': boothUid}),
          )
          .timeout(_timeout);

      final data = _decode(response);
      if (response.statusCode == 200) {
        return {
          'success': true,
          'message': data is Map ? data['message'] : null,
          'slotIdentifier': data is Map ? data['slotIdentifier'] : null,
        };
      }
      final error = _errorFrom(response, 'Failed to release battery');
      return {
        'success': false,
        'message': error.message,
        'statusCode': error.statusCode,
      };
    } catch (e) {
      return {'success': false, 'message': e.toString(), 'statusCode': 0};
    }
  }

  /// Fetches transaction history.
  Future<List<UserTransaction>> getHistory(String token) async {
    try {
      final response = await http
          .get(
            Uri.parse('$_baseUrl/booths/history'),
            headers: _headers(token),
          )
          .timeout(_timeout);

      _ensureSuccess(response, 'Failed to load history');
      final data = _decode(response);
      if (data is List) {
        return data
            .whereType<Map>()
            .map((json) => UserTransaction.fromJson(Map<String, dynamic>.from(json)))
            .toList();
      }
      return [];
    } catch (e) {
      rethrow;
    }
  }

  /// Cancels the rider's oldest active session (`POST /booths/cancel-session`).
  ///
  /// The endpoint is account-scoped, not session-scoped.
  Future<void> cancelActiveSession(String token) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/booths/cancel-session'),
          headers: _headers(token),
        )
        .timeout(_timeout);

    _ensureSuccess(response, 'Failed to cancel session');
  }

  /// Lifecycle status of one deposit session, including terminal states that
  /// `/my-battery-status` hides.
  Future<DepositSessionStatus> getDepositSessionStatus(
    String token,
    int sessionId,
  ) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/booths/deposit-sessions/$sessionId/status'),
          headers: _headers(token),
        )
        .timeout(_timeout);

    _ensureSuccess(response, 'Failed to fetch deposit status');
    final data = _decode(response);
    if (data is Map) {
      return DepositSessionStatus.fromJson(Map<String, dynamic>.from(data));
    }
    throw BoothApiException(
      'Unexpected deposit status response',
      statusCode: response.statusCode,
    );
  }

  // ====================================================================
  // RENTAL BATTERIES
  // ====================================================================

  /// Rider-facing rental rules and gates.
  Future<RentalFeatureStatus> getRentalFeatureStatus(String token) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/booths/rentals/status'),
          headers: _headers(token),
        )
        .timeout(_timeout);

    _ensureSuccess(response, 'Failed to fetch rental status');
    final data = _decode(response);
    if (data is Map) {
      return RentalFeatureStatus.fromJson(Map<String, dynamic>.from(data));
    }
    throw BoothApiException(
      'Unexpected rental status response',
      statusCode: response.statusCode,
    );
  }

  /// Lists borrowable pool batteries at a booth.
  Future<AvailableRentalBatteries> getAvailableRentalBatteries(
    String token,
    String boothUid,
  ) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/booths/rentals/available?boothUid=$boothUid'),
          headers: _headers(token),
        )
        .timeout(_timeout);

    _ensureSuccess(response, 'Failed to fetch available rental batteries');
    final data = _decode(response);
    if (data is Map) {
      return AvailableRentalBatteries.fromJson(Map<String, dynamic>.from(data));
    }
    throw BoothApiException(
      'Unexpected rental availability response',
      statusCode: response.statusCode,
    );
  }

  /// Issues (reserves) a rental battery and opens its slot.
  Future<IssueRentalResult> issueRental(
    String token, {
    required String boothUid,
    required String slotIdentifier,
  }) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/booths/rentals/issue'),
          headers: _headers(token, json: true),
          body: json.encode({
            'boothUid': boothUid,
            'slotIdentifier': slotIdentifier,
          }),
        )
        .timeout(_timeout);

    _ensureSuccess(response, 'Failed to issue rental battery');
    final data = _decode(response);
    if (data is Map) {
      return IssueRentalResult.fromJson(Map<String, dynamic>.from(data));
    }
    throw BoothApiException(
      'Unexpected rental issue response',
      statusCode: response.statusCode,
    );
  }

  /// The rider's current rental, or `null` when there is none (`204`).
  Future<ActiveRental?> getActiveRental(String token) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/booths/rentals/active'),
          headers: _headers(token),
        )
        .timeout(_timeout);

    if (response.statusCode == 204) return null;
    _ensureSuccess(response, 'Failed to fetch active rental');
    final data = _decode(response);
    if (data is Map) return ActiveRental.fromJson(Map<String, dynamic>.from(data));
    return null;
  }

  /// Reserves a return slot at [boothUid] and opens it.
  Future<ReturnRentalResult> returnRental(
    String token,
    int sessionId,
    String boothUid,
  ) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/booths/rentals/$sessionId/return'),
          headers: _headers(token, json: true),
          body: json.encode({'boothUid': boothUid}),
        )
        .timeout(_timeout);

    _ensureSuccess(response, 'Failed to start the rental return');
    final data = _decode(response);
    if (data is Map) {
      return ReturnRentalResult.fromJson(Map<String, dynamic>.from(data));
    }
    throw BoothApiException(
      'Unexpected rental return response',
      statusCode: response.statusCode,
    );
  }

  /// Consolidated bill preview (own charging + rental energy + rental time).
  Future<RentalBill> getRentalBill(String token, int sessionId) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/booths/rentals/$sessionId/bill'),
          headers: _headers(token),
        )
        .timeout(_timeout);

    _ensureSuccess(response, 'Failed to compute the rental bill');
    final data = _decode(response);
    if (data is Map) {
      return RentalBill.fromJson(Map<String, dynamic>.from(data));
    }
    throw BoothApiException(
      'Unexpected rental bill response',
      statusCode: response.statusCode,
    );
  }

  /// Pays the consolidated bill (STK push, auto-approved on dev booths).
  Future<PayRentalResult> payRental(String token, int sessionId) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/booths/rentals/$sessionId/pay'),
          headers: _headers(token),
        )
        .timeout(_timeout);

    _ensureSuccess(response, 'Failed to pay the rental bill');
    final data = _decode(response);
    if (data is Map) {
      return PayRentalResult.fromJson(Map<String, dynamic>.from(data));
    }
    throw BoothApiException(
      'Unexpected rental payment response',
      statusCode: response.statusCode,
    );
  }

  /// Polls the rental payment status.
  Future<String> getRentalPaymentStatus(
    String token,
    String checkoutRequestId,
  ) async {
    final response = await http
        .get(
          Uri.parse('$_baseUrl/booths/rentals/status/$checkoutRequestId'),
          headers: _headers(token),
        )
        .timeout(_timeout);

    _ensureSuccess(response, 'Failed to check rental payment status');
    final data = _decode(response);
    return data is Map ? (data['paymentStatus']?.toString() ?? 'pending') : 'pending';
  }

  /// Opens the slot holding the rider's own charged battery (after payment).
  Future<UnlockOwnResult> unlockOwnBattery(String token, int sessionId) async {
    final response = await http
        .post(
          Uri.parse('$_baseUrl/booths/rentals/$sessionId/unlock-own'),
          headers: _headers(token),
        )
        .timeout(_timeout);

    _ensureSuccess(response, 'Failed to unlock your own battery');
    final data = _decode(response);
    if (data is Map) {
      return UnlockOwnResult.fromJson(Map<String, dynamic>.from(data));
    }
    throw BoothApiException(
      'Unexpected unlock response',
      statusCode: response.statusCode,
    );
  }
}
