import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:provider/provider.dart';
import 'package:ridercms/controllers/charging_controller.dart';
import 'package:ridercms/providers/app_provider.dart';
import 'package:ridercms/providers/notification_provider.dart';
import 'package:ridercms/providers/user_provider.dart';
import 'package:ridercms/screens/home/scan_screen.dart';
import 'package:ridercms/screens/home/notifications_screen.dart';
import 'package:ridercms/utils/themes/app_theme.dart';

import '../../widgets/home/quick_action.dart';

class DashboardScreen extends StatelessWidget {
  const DashboardScreen({super.key});

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
  Widget build(BuildContext context) {
    // 1. Watch the UserProvider for changes
    final userProvider = context.watch<UserProvider>();
    final appProvider = context.read<AppProvider>();
    final notificationProvider = context.watch<NotificationProvider>();
    final chargingController = Get.find<ChargingController>();

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

                          Obx(() {
                            final bool hasSession = chargingController.hasActiveSession();
                            return QuickAction(
                              icon: Icons.qr_code_scanner,
                              title: "Scan Battery",
                              subtitle: hasSession ? "Session active" : "Start charging now",
                              gradient: const [Color(0xFF1a2a1a), Color(0xFF1e4a2a)],
                              opacity: hasSession ? 0.5 : 1.0,
                              onTap: hasSession 
                                ? () => Get.snackbar('Action Disabled', 'You already have an active session.') 
                                : () => Get.to(ScanScreen()),
                            );
                          }),

                          QuickAction(
                            icon: Icons.bolt,
                            title: "Active Session",
                            subtitle: "View charging",
                            gradient: const [Color(0xFF2a1a1a), Color(0xFF4a2a1e)],
                            onTap: () => Get.toNamed('/charging'),
                          ),

                          QuickAction(
                            icon: Icons.card_giftcard,
                            title: "Rewards",
                            subtitle: "240 points earned",
                            gradient: const [Color(0xFF1a1a2a), Color(0xFF2a1e4a)],
                            onTap: () {},
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
