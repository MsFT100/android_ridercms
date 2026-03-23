import 'package:flutter/material.dart';
import 'package:ridercms/utils/constants/app_constants.dart';
import 'package:ridercms/utils/themes/app_theme.dart';

class SocialBtn extends StatelessWidget {
  final String label;
  final String icon;
  final VoidCallback onTap;

  const SocialBtn({
    super.key,
    required this.label,
    required this.icon,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final bool isAsset = icon.contains('/');

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 14, horizontal: 12), // Added horizontal padding
        decoration: BoxDecoration(
          color: kBgCard,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(color: Colors.white.withValues(alpha: 0.1)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          mainAxisSize: MainAxisSize.min, // Allows the row to be as small as its children
          children: [
            if (isAsset)
              Image.asset(
                icon,
                width: AppConstants.iconSizeNormal,
                height: AppConstants.iconSizeNormal,
                // Adding an errorBuilder helps catch missing assets without crashing
                errorBuilder: (context, error, stackTrace) => const Icon(Icons.error, color: Colors.red, size: 20),
              )
            else
              Text(
                icon,
                style: const TextStyle(fontSize: AppConstants.iconSizeNormal),
              ),
            const SizedBox(width: 8),
            Flexible( // <--- THIS FIXES THE OVERFLOW
              child: Text(
                label,
                overflow: TextOverflow.ellipsis, // Adds "..." if the text is too long
                maxLines: 1,
                style: const TextStyle(
                  color: kTextPrimary,
                  fontSize: 14,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}