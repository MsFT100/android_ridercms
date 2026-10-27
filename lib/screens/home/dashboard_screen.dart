import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:ridercms/controllers/charging_controller.dart';
import 'package:ridercms/providers/app_provider.dart';
import 'package:ridercms/providers/notification_provider.dart';
import 'package:ridercms/providers/user_provider.dart';
import 'package:ridercms/screens/home/scan_screen.dart';
import 'package:ridercms/screens/home/notifications_screen.dart';
import 'package:ridercms/services/booth_service.dart';
import 'package:ridercms/utils/rental_launcher.dart';
import 'package:ridercms/utils/themes/app_theme.dart';
import 'package:ridercms/widgets/custom_snackbar.dart';

import '../../widgets/home/quick_action.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  late final ChargingController _chargingController;
  final BoothService _boothService = BoothService();

  /// Rentals are visible by default; the feature flag can hide the action.
  bool _rentalEnabled = true;
  bool _checkingRental = false;
  bool _rentalUnavailable = false;

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Good morning';
    } else if (hour < 17) {
      return 'Good afternoon';
    } else {
      return 'Good evening';
    }
  }

  @override
  void initState() {
    super.initState();
    _chargingController = Get.find<ChargingController>();
    _chargingController.startPolling(interval: const Duration(seconds: 5));
    _chargingController.refreshBatteries();
    _loadRentalFeature();
  }

  Future<String?> _token() async {
    try {
      return await context.read<UserProvider>().getFreshToken();
    } catch (_) {
      return null;
    }
  }

  Future<void> _loadRentalFeature() async {
    final token = await _token();
    if (token == null || !mounted) return;
    try {
      final status = await _boothService.getRentalFeatureStatus(token);
      if (!mounted) return;
      setState(() => _rentalEnabled = status.enabled);
    } catch (_) {
      // If the flag cannot be fetched, keep the rental action visible.
      if (!mounted) return;
      setState(() => _rentalEnabled = true);
    }
  }

  /// Delegates to the shared [openRental] launcher (resume, feature flag,
  /// limit check, highest-SOC auto-assignment).
  Future<void> _openRental() async {
    if (_checkingRental) return;

    if (!_rentalEnabled) {
      CustomSnackBar.show(
        context,
        'Battery rentals are currently disabled.',
        isError: true,
      );
      return;
    }

    setState(() {
      _checkingRental = true;
      _rentalUnavailable = false;
    });

    final result = await openRental(context);
    if (!mounted) return;

    setState(() {
      _checkingRental = false;
      _rentalUnavailable = result == RentalLaunchResult.unavailable;
      if (result == RentalLaunchResult.disabled) _rentalEnabled = false;
    });
  }

  @override
  void dispose() {
    _chargingController.stopPolling();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    // 1. Watch the UserProvider for changes
    final userProvider = context.watch<UserProvider>();
    final appProvider = context.read<AppProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final chargingController = _chargingController;

    final userName = userProvider.firebaseUser?.displayName ?? 'RiderCMS';
    final unreadCount = notificationProvider.unreadCount;

    return Scaffold(
      backgroundColor: kBgDark,
      body: Stack(
        children: [
          SingleChildScrollView(
            padding: const EdgeInsets.only(bottom: 100),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                /// HEADER
                Container(
                  padding: const EdgeInsets.fromLTRB(24, 56, 24, 24),
                  decoration: const BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      colors: [kBgDark2, kBgDark],
                    ),
                  ),
                  child: Column(
                    children: [

                      /// USER ROW
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(_getGreeting(), style: const TextStyle(color: kTextSecondary, fontSize: 13)),
                              const SizedBox(height: 4),
                              Text(
                                userName.toUpperCase(),
                                style: const TextStyle(
                                  color: kTextPrimary,
                                  fontSize: 22,
                                  fontWeight: FontWeight.w700,
                                ),
                              ),
                            ],
                          ),

                          /// NOTIFICATION
                          GestureDetector(
                            onTap: () => Get.to(() => const NotificationsScreen()),
                            child: Stack(
                              children: [
                                Container(
                                  width: 48,
                                  height: 48,
                                  decoration: BoxDecoration(
                                    color: kBgCard,
                                    borderRadius: BorderRadius.circular(16),
                                    border: Border.all(color: Colors.white.withValues(alpha: 0.15), width: 1),
                                  ),
                                  child: const Icon(Icons.notifications_none, color: kTextPrimary),
                                ),
                                if (unreadCount > 0)
                                  Positioned(
                                    right: 0,
                                    top: 0,
                                    child: Container(
                                      width: 18,
                                      height: 18,
                                      decoration: BoxDecoration(
                                        color: kDanger,
                                        borderRadius: BorderRadius.circular(9),
                                      ),
                                      child: Center(
                                        child: Text(
                                          unreadCount > 9 ? '9+' : unreadCount.toString(),
                                          style: const TextStyle(
                                            color: Colors.white,
                                            fontSize: 10,
                                            fontWeight: FontWeight.bold,
                                          ),
                                        ),
                                      ),
                                    ),
                                  )
                              ],
                            ),
                          )
                        ],
                      ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),

                /// QUICK ACTIONS
                Padding(
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [

                      const Text(
                        "Quick Actions",
                        style: TextStyle(
                          color: kTextPrimary,
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),

                      const SizedBox(height: 16),

                      GridView.count(
                        crossAxisCount: 2,
                        shrinkWrap: true,
                        physics: const NeverScrollableScrollPhysics(),
                        crossAxisSpacing: 12,
                        mainAxisSpacing: 12,
                        childAspectRatio: 1.2,
                        children: [

                          QuickAction(
                            icon: Icons.location_on,
                            title: "Find Booth",
                            subtitle: "Locate nearby stations",
                            gradient: const [Color(0xFF1a2744), Color(0xFF1e3a5f)],
                            onTap: () => appProvider.setIndex(1),
                          ),

                          // Depositing another battery is always allowed while
                          // others charge — only an unpaid session blocks it.
                          Obx(() {
                            final bool hasPending =
                                chargingController.hasPendingWithdrawal.value;
                            final int count = chargingController.batteryCount;
                            return QuickAction(
                              icon: Icons.qr_code_scanner,
                              title: count > 0 ? "Add Battery" : "Scan Battery",
                              subtitle: hasPending
                                  ? "Complete your payment first"
                                  : count > 0
                                      ? "$count charging · add another"
                                      : "Start charging now",
                              gradient: const [Color(0xFF1a2a1a), Color(0xFF1e4a2a)],
                              opacity: hasPending ? 0.5 : 1.0,
                              onTap: hasPending
                                  ? () => Get.toNamed('/payment')
                                  : () => Get.to(() => const ScanScreen()),
                            );
                          }),

                          Obx(() {
                            final bool hasPending =
                                chargingController.hasPendingWithdrawal.value;
                            final int count = chargingController.batteryCount;
                            return QuickAction(
                              icon: Icons.bolt,
                              title: "Active Session",
                              subtitle: hasPending
                                  ? "Payment pending"
                                  : count > 1
                                      ? "$count batteries"
                                      : "View charging",
                              gradient: const [Color(0xFF2a1a1a), Color(0xFF4a2a1e)],
                              onTap: () {
                                if (hasPending) {
                                  Get.toNamed('/payment');
                                } else if (count > 1) {
                                  Get.toNamed('/batteries');
                                } else {
                                  Get.toNamed('/charging');
                                }
                              },
                            );
                          }),

                          if (_rentalEnabled)
                            QuickAction(
                              icon: Icons.swap_horiz_rounded,
                              title: _rentalUnavailable
                                  ? "No Rentals"
                                  : _checkingRental
                                      ? "Checking…"
                                      : "Rent a Battery",
                              subtitle: _rentalUnavailable
                                  ? "None available right now"
                                  : _checkingRental
                                      ? "Finding the best battery"
                                      : "Swap while yours charges",
                              gradient: const [
                                Color(0xFF1a1a2e),
                                Color(0xFF3b2f63),
                              ],
                              opacity: _rentalUnavailable ? 0.6 : 1.0,
                              onTap: _openRental,
                            ),

                          QuickAction(
                            icon: Icons.history,
                            title: "History",
                            subtitle: "Your past sessions",
                            gradient: const [Color(0xFF1a1a2a), Color(0xFF2a1e4a)],
                            onTap: () => appProvider.setIndex(2),
                          ),
                        ],
                      )
                    ],
                  ),
                ),
              ],
            ),
          ),


        ],
      ),
    );
  }
}
