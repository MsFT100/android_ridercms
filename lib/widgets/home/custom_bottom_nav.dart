import 'package:flutter/material.dart';
import 'package:ridercms/utils/themes/app_theme.dart';

class CustomBottomNav extends StatelessWidget {
  final int currentIndex;
  final Function(int) onTap;

  const CustomBottomNav({
    super.key,
    required this.currentIndex,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned(
      bottom: 24,
      left: 24,
      right: 24,
      child: Container(
        height: 72,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        decoration: BoxDecoration(
          color: kBgCard.withValues(alpha: 0.95),
          borderRadius: BorderRadius.circular(24),
          border: Border.all(color: Colors.white.withValues(alpha: 0.05)),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.4),
              blurRadius: 20,
              offset: const Offset(0, 10),
            )
          ],
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: [
            _navIcon(Icons.grid_view_rounded, 0),
            _navIcon(Icons.map_outlined, 1),
            _navIcon(Icons.history_rounded, 2),
            _navIcon(Icons.person_outline_rounded, 3),
          ],
        ),
      ),
    );
  }

  Widget _navIcon(IconData icon, int index) {
    final bool active = currentIndex == index;
    return GestureDetector(
      onTap: () => onTap(index),
      child: Icon(
        icon,
        color: active ? kPrimary : kTextSecondary,
        size: 26,
      ),
    );
  }
}