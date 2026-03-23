import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:get/get.dart';
import '../../providers/user_provider.dart';
import '../../utils/themes/app_theme.dart';
import '../../widgets/common_widgets.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final userProvider = context.watch<UserProvider>();
    final user = userProvider.userModel;

    return Container(
      color: kBgDark,
      child: SingleChildScrollView(
        child: Column(
          children: [
            // Header with Profile Picture
            Container(
              padding: const EdgeInsets.fromLTRB(24, 64, 24, 32),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topCenter,
                  end: Alignment.bottomCenter,
                  colors: [kBgDark2, kBgDark],
                ),
              ),
              child: Column(
                children: [
                  Stack(
                    children: [
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          shape: BoxShape.circle,
                          border: Border.all(color: kPrimary, width: 2),
                          image: user?.profileImageUrl != null
                              ? DecorationImage(
                                  image: NetworkImage(user!.profileImageUrl!),
                                  fit: BoxFit.cover,
                                )
                              : null,
                        ),
                        child: user?.profileImageUrl == null
                            ? const Icon(Icons.person, size: 50, color: kTextSecondary)
                            : null,
                      ),
                      Positioned(
                        bottom: 0,
                        right: 0,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: const BoxDecoration(
                            color: kPrimary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.edit, size: 16, color: Colors.white),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 16),
                  Text(
                    user?.name ?? 'User Name',
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? 'user@example.com',
                    style: const TextStyle(
                      color: kTextSecondary,
                      fontSize: 14,
                    ),
                  ),
                ],
              ),
            ),

            // Profile Options
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    "ACCOUNT",
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildOptionTile(
                    icon: Icons.person_outline,
                    label: "Personal Information",
                    onTap: () {},
                  ),
                  _buildOptionTile(
                    icon: Icons.account_balance_wallet_outlined,
                    label: "Payment Methods",
                    onTap: () {},
                  ),
                  _buildOptionTile(
                    icon: Icons.history,
                    label: "Transaction History",
                    onTap: () {},
                  ),
                  const SizedBox(height: 32),
                  const Text(
                    "SETTINGS",
                    style: TextStyle(
                      color: kTextSecondary,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                      letterSpacing: 1.2,
                    ),
                  ),
                  const SizedBox(height: 16),
                  _buildOptionTile(
                    icon: Icons.notifications_none,
                    label: "Notifications",
                    onTap: () {},
                  ),
                  _buildOptionTile(
                    icon: Icons.security,
                    label: "Security",
                    onTap: () {},
                  ),
                  _buildOptionTile(
                    icon: Icons.help_outline,
                    label: "Help & Support",
                    onTap: () {},
                  ),
                  const SizedBox(height: 32),
                  
                  // Logout Button
                  AppCard(
                    padding: EdgeInsets.zero,
                    child: ListTile(
                      onTap: () async {
                        await userProvider.signOut();
                        Get.offAllNamed('/login');
                      },
                      leading: const Icon(Icons.logout, color: kDanger),
                      title: const Text(
                        "Logout",
                        style: TextStyle(color: kDanger, fontWeight: FontWeight.w600),
                      ),
                      trailing: const Icon(Icons.chevron_right, color: kTextSecondary),
                    ),
                  ),
                  const SizedBox(height: 120), // Space for bottom nav
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildOptionTile({
    required IconData icon,
    required String label,
    required VoidCallback onTap,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        padding: EdgeInsets.zero,
        child: ListTile(
          onTap: onTap,
          leading: Icon(icon, color: kPrimary),
          title: Text(
            label,
            style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.w500),
          ),
          trailing: const Icon(Icons.chevron_right, color: kTextSecondary),
        ),
      ),
    );
  }
}
