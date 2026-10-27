import 'package:get/get.dart';

class SessionCompleteController extends GetxController {
  var rating = 0.obs;
  
  // Data to be populated from arguments
  late String sessionId;
  late String boothName;
  late double totalAmount;
  late double energyDelivered;
  late int durationMinutes;
  late List<dynamic> batteries;
  late String transactionId;

  @override
  void onInit() {
    super.onInit();
    // Extract arguments passed during navigation
    final dynamic args = Get.arguments;
    
    sessionId = args?['sessionId']?.toString() ?? '---';
    boothName = args?['boothName']?.toString() ?? 'Station';
    totalAmount = (args?['totalAmount'] as num?)?.toDouble() ?? 0.0;
    energyDelivered = (args?['energyDelivered'] as num?)?.toDouble() ?? 0.0;
    durationMinutes = (args?['durationMinutes'] as num?)?.toInt() ?? 0;
    transactionId = args?['transactionId']?.toString() ?? '---';
    
    // Fallback to empty list if no batteries provided
    final dynamic rawBatteries = args?['batteries'];
    batteries = rawBatteries is List ? rawBatteries : [];
  }

  void setRating(int value) {
    rating.value = value;
  }

  String formatDuration(int mins) {
    final h = mins ~/ 60;
    final m = mins % 60;
    if (h > 0) return '${h}h ${m}m';
    return '${m}m';
  }
}
