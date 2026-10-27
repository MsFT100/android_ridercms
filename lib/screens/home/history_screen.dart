import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:ridercms/models/booth_models.dart';
import 'package:ridercms/providers/user_provider.dart';
import 'package:ridercms/services/booth_service.dart';
import 'package:ridercms/utils/themes/app_theme.dart';

/// Rider session history from `GET /booths/history` (latest 50, newest first).
class HistoryScreen extends StatefulWidget {
  const HistoryScreen({super.key});

  @override
  State<HistoryScreen> createState() => _HistoryScreenState();
}

class _HistoryScreenState extends State<HistoryScreen> {
  final BoothService _boothService = BoothService();

  List<UserTransaction> _items = [];
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    setState(() {
      _loading = _items.isEmpty;
      _error = null;
    });

    try {
      final token = await context.read<UserProvider>().getFreshToken();
      if (token == null) {
        throw BoothApiException('Authentication session expired.');
      }
      final items = await _boothService.getHistory(token);
      if (!mounted) return;
      setState(() => _items = items);
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = e is BoothApiException
            ? e.message
            : 'Unable to load your history. Pull down to retry.';
      });
    } finally {
      if (mounted) setState(() => _loading = false);
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
          Expanded(child: _buildBody()),
        ],
      ),
    );
  }

  Widget _buildBody() {
    if (_loading) {
      return const Center(child: CircularProgressIndicator(color: kPrimary));
    }

    return RefreshIndicator(
      color: kPrimary,
      backgroundColor: kBgCard,
      onRefresh: _load,
      child: _error != null && _items.isEmpty
          ? _message(Icons.error_outline, kDanger, 'Something went wrong', _error!)
          : _items.isEmpty
              ? _message(
                  Icons.history_rounded,
                  kPrimary,
                  'No activity yet',
                  'Your deposits, collections and rentals will appear here.',
                )
              : ListView.separated(
                  physics: const AlwaysScrollableScrollPhysics(),
                  // Leave room for the floating bottom navigation bar.
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 120),
                  itemCount: _items.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 12),
                  itemBuilder: (_, index) => _HistoryTile(item: _items[index]),
                ),
    );
  }

  /// Scrollable so pull-to-refresh still works on the empty/error states.
  Widget _message(IconData icon, Color color, String title, String body) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(48, 80, 48, 120),
      children: [
        Center(
          child: Container(
            padding: const EdgeInsets.all(24),
            decoration: const BoxDecoration(
              color: kBgCard,
              shape: BoxShape.circle,
            ),
            child: Icon(icon, size: 56, color: color),
          ),
        ),
        const SizedBox(height: 24),
        Text(
          title,
          textAlign: TextAlign.center,
          style: const TextStyle(
            color: kTextPrimary,
            fontSize: 20,
            fontWeight: FontWeight.bold,
          ),
        ),
        const SizedBox(height: 12),
        Text(
          body,
          textAlign: TextAlign.center,
          style: TextStyle(
            color: kTextSecondary.withValues(alpha: 0.8),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }
}

class _HistoryTile extends StatelessWidget {
  final UserTransaction item;

  const _HistoryTile({required this.item});

  static const List<String> _months = [
    'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
    'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
  ];

  (String, IconData, Color) get _kind {
    switch (item.sessionType.toLowerCase()) {
      case 'deposit':
        return ('Battery Deposit', Icons.battery_charging_full_rounded, kPrimary);
      case 'withdrawal':
        return ('Battery Collection', Icons.battery_full_rounded, kAccent);
      case 'rental':
        return ('Battery Rental', Icons.swap_horiz_rounded, kWarning);
      default:
        return (
          item.sessionType.isEmpty ? 'Session' : item.sessionType,
          Icons.bolt_rounded,
          kTextSecondary,
        );
    }
  }

  Color get _statusColor {
    switch (item.status.toLowerCase()) {
      case 'completed':
      case 'paid':
        return kPrimary;
      case 'pending':
      case 'in_progress':
      case 'opening':
        return kWarning;
      case 'cancelled':
      case 'failed':
        return kDanger;
      default:
        return kTextSecondary;
    }
  }

  String _formatDate(DateTime? date) {
    if (date == null) return '—';
    final hh = date.hour.toString().padLeft(2, '0');
    final mm = date.minute.toString().padLeft(2, '0');
    return '${date.day} ${_months[date.month - 1]} ${date.year} · $hh:$mm';
  }

  @override
  Widget build(BuildContext context) {
    final (label, icon, color) = _kind;
    final statusColor = _statusColor;
    final status = item.status.replaceAll('_', ' ');

    final location = [
      if (item.boothUid.isNotEmpty) item.boothUid,
      if (item.slotIdentifier.isNotEmpty) 'Slot ${item.slotIdentifier}',
    ].join(' · ');

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: Colors.white.withValues(alpha: 0.06)),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(icon, color: color),
          ),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  _formatDate(item.date),
                  style: const TextStyle(color: kTextSecondary, fontSize: 12),
                ),
                if (location.isNotEmpty) ...[
                  const SizedBox(height: 2),
                  Text(
                    location,
                    style: const TextStyle(color: kTextSecondary, fontSize: 12),
                    overflow: TextOverflow.ellipsis,
                  ),
                ],
              ],
            ),
          ),
          const SizedBox(width: 8),
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            children: [
              if (item.amount != null && item.amount! > 0)
                Padding(
                  padding: const EdgeInsets.only(bottom: 6),
                  child: Text(
                    'KES ${item.amount!.toStringAsFixed(0)}',
                    style: const TextStyle(
                      color: kTextPrimary,
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                ),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                decoration: BoxDecoration(
                  color: statusColor.withValues(alpha: 0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  status.isEmpty
                      ? '—'
                      : status[0].toUpperCase() + status.substring(1),
                  style: TextStyle(
                    color: statusColor,
                    fontSize: 11,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}
