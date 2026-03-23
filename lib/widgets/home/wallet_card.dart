import 'package:flutter/material.dart';
import 'package:ridercms/utils/themes/app_theme.dart';

class WalletCard extends StatelessWidget {
  final String balance;
  final VoidCallback onTopUp;
  final VoidCallback onHistory;

  const WalletCard({
    super.key,
    required this.balance,
    required this.onTopUp,
    required this.onHistory,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [kPrimary, kPrimaryDark],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: kPrimary.withValues(alpha: 0.39),
            blurRadius: 30,
            offset: const Offset(0, 8),
          )
        ],
      ),
      child: Column(
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text("Wallet Balance", style: TextStyle(color: Colors.white70, fontSize: 13)),
                  const SizedBox(height: 6),
                  Text(
                    balance,
                    style: const TextStyle(color: Colors.white, fontSize: 30, fontWeight: FontWeight.bold),
                  ),
                ],
              ),
              _buildWalletIcon(),
            ],
          ),
          const SizedBox(height: 18),
          Row(
            children: [
              Expanded(child: _WalletActionBtn(label: "+ Top Up", onTap: onTopUp)),
              const SizedBox(width: 12),
              Expanded(child: _WalletActionBtn(label: "History", onTap: onHistory)),
            ],
          )
        ],
      ),
    );
  }

  Widget _buildWalletIcon() {
    return Container(
      width: 48,
      height: 48,
      decoration: BoxDecoration(
        color: Colors.white.withValues(alpha: 0.39),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Icon(Icons.account_balance_wallet, color: Colors.white),
    );
  }
}

class _WalletActionBtn extends StatelessWidget {
  final String label;
  final VoidCallback onTap;
  const _WalletActionBtn({required this.label, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 12),
        decoration: BoxDecoration(
          color: Colors.white.withValues(alpha: 0.15),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Text(
          label,
          textAlign: TextAlign.center,
          style: const TextStyle(color: Colors.white, fontSize: 14, fontWeight: FontWeight.w600),
        ),
      ),
    );
  }
}