import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import '../models/booth_models.dart';
import '../services/booth_service.dart';
import '../providers/user_provider.dart';

class BoothController extends GetxController {
  final BoothService _service = BoothService();

  var booths = <PublicBooth>[].obs;
  var isLoading = true.obs;

  @override
  void onInit() {
    fetchBooths();
    super.onInit();
  }

  void fetchBooths() async {
    try {
      final BuildContext? context = Get.context;
      if (context == null) return;

      final userProvider = Provider.of<UserProvider>(context, listen: false);
      final token = await userProvider.getFreshToken();

      if (token == null) return;

      isLoading(true);
      var fetchedBooths = await _service.getBooths(token);
      if (fetchedBooths.isNotEmpty) {
        booths.assignAll(fetchedBooths);
      }
    } catch (e) {
      debugPrint('Error fetching booths in BoothController: $e');
    } finally {
      isLoading(false);
    }
  }
}
