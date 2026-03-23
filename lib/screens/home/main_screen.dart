import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridercms/providers/app_provider.dart';
import 'package:ridercms/screens/home/dashboard_screen.dart';
import 'package:ridercms/screens/home/history_screen.dart';
import 'package:ridercms/screens/home/map_screen.dart';
import 'package:ridercms/screens/home/profile_screen.dart';
import 'package:ridercms/widgets/home/custom_bottom_nav.dart';


class MainScreen extends StatefulWidget {
  const MainScreen({super.key});

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  final List<Widget> _pages = [
    const DashboardScreen(),
    const MapScreen(),
    const HistoryScreen(),
    const ProfileScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final appProvider = context.watch<AppProvider>();
    
    return Scaffold(
      body: Stack(
        children: [
          IndexedStack(
            index: appProvider.currentIndex,
            children: _pages,
          ),

          CustomBottomNav(
            currentIndex: appProvider.currentIndex,
            onTap: (index) {
              appProvider.setIndex(index);
            },
          ),
        ],
      ),
    );
  }
}
