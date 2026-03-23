import 'package:flutter/material.dart';
import '../../utils/themes/app_theme.dart';

class NavIcon extends StatelessWidget {
  final IconData icon;
  final bool active;
  const NavIcon({super.key, required this.icon, this.active = false});

  @override
  Widget build(BuildContext context) {
    return Icon(
      icon,
      color: active ? kPrimary : kTextSecondary,
      size: 26,
    );
  }
}
