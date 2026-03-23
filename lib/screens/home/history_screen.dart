import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridercms/providers/user_provider.dart';
import 'package:ridercms/services/booth_service.dart';
import 'package:ridercms/models/booth_models.dart';
import 'package:ridercms/utils/themes/app_theme.dart';
import '../../widgets/common_widgets.dart';

class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final BoothService _boothService = BoothService();
  List<UserTransaction> _transactions = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _fetchHistory();
  }

  Future<void> _fetchHistory() async {
    final userProvider = Provider.of<UserProvider>(context, listen: false);
    final token = userProvider.getFreshToken();

    try {
      final history = await _boothService.getHistory(token as String);
      if (mounted) {
        setState(() {
          _transactions = history;
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() => _isLoading = false);
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Error loading history: $e')),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      color: kBgDark,
      child: Column(
        children: [
          // Header
          Container(
            padding: const EdgeInsets.fromLTRB(24, 64, 24, 24),
            width: double.infinity,
            decoration: const BoxDecoration(
              gradient: LinearGradient(
                begin: Alignment.topCenter,
                end: Alignment.bottomCenter,
                colors: [kBgDark2, kBgDark],
              ),
            ),
            child: const Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Activity History',
                  style: TextStyle(
                    color: kTextPrimary,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Your recent battery swaps and sessions',
                  style: TextStyle(color: kTextSecondary, fontSize: 14),
                ),
              ],
            ),
          ),

          // List
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator(color: kPrimary))
                : _transactions.isEmpty
                    ? _buildEmptyState()
                    : RefreshIndicator(
                        onRefresh: _fetchHistory,
                        color: kPrimary,
                        child: ListView.builder(
                          padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                          itemCount: _transactions.length,
                          itemBuilder: (context, index) {
                            final tx = _transactions[index];
                            return _TransactionTile(transaction: tx);
                          },
                        ),
                      ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            padding: const EdgeInsets.all(24),
            decoration: BoxDecoration(
              color: kBgCard,
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.history, size: 48, color: kTextSecondary),
          ),
          const SizedBox(height: 24),
          const Text(
            'No transactions yet',
            style: TextStyle(color: kTextPrimary, fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Your charging history will appear here.',
            style: TextStyle(color: kTextSecondary, fontSize: 14),
          ),
        ],
      ),
    );
  }
}

class _TransactionTile extends StatelessWidget {
  final UserTransaction transaction;
  const _TransactionTile({required this.transaction});

  @override
  Widget build(BuildContext context) {
    final bool isSuccess = transaction.status.toUpperCase() == 'COMPLETED';

    return Padding(
      padding: const EdgeInsets.only(bottom: 12),
      child: AppCard(
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: (isSuccess ? kPrimary : kWarning).withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                transaction.type.toUpperCase() == 'DEPOSIT' ? Icons.south_west : Icons.bolt,
                color: isSuccess ? kPrimary : kWarning,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    transaction.type,
                    style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    transaction.date,
                    style: const TextStyle(color: kTextSecondary, fontSize: 12),
                  ),
                ],
              ),
            ),
            Column(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: [
                Text(
                  'KSh ${transaction.amount}',
                  style: const TextStyle(color: kTextPrimary, fontWeight: FontWeight.bold, fontSize: 15),
                ),
                const SizedBox(height: 4),
                Text(
                  transaction.status,
                  style: TextStyle(
                    color: isSuccess ? kPrimary : kWarning,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}
