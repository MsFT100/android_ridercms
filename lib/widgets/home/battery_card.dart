import 'package:flutter/material.dart';
import '../../models/booth_models.dart';
import '../../utils/themes/app_theme.dart';
import '../common_widgets.dart';

/// One live card for a deposited battery — SOC ring, station/slot, door state,
/// temperature/voltage and a per-battery "Collect & Pay" action.
///
/// Shared by the dashboard (inline section) and the expanded
/// `MultiBatteryStatusScreen` so both surfaces stay identical.
class BatteryCard extends StatelessWidget {
  final MyBatteryStatus status;
  final VoidCallback onCollect;

  /// Section-level gate: when a payment is pending nothing may be collected.
  final bool collectEnabled;

  const BatteryCard({
    super.key,
    required this.status,
    required this.onCollect,
    this.collectEnabled = true,
  });

  @override
  Widget build(BuildContext context) {
    final soc = status.soc;
    final canCollect = collectEnabled && soc >= 20 && !status.isPending;
    final telemetry = status.telemetry;
    final doorKnown = telemetry != null;
    final locked = telemetry?.doorLocked ?? false;
    final doorColor = !doorKnown ? kTextSecondary : (locked ? kPrimary : kDanger);
    final temperature = telemetry?.temperature;
    final voltage = telemetry?.voltage;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: kBgCard,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: Colors.white.withValues(alpha: 0.08)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              _SocRing(level: soc),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: Text(
                            status.boothUid.isEmpty ? 'Station' : status.boothUid,
                            style: const TextStyle(
                              color: kTextPrimary,
                              fontSize: 16,
                              fontWeight: FontWeight.w700,
                              fontFamily: 'monospace',
                            ),
                            overflow: TextOverflow.ellipsis,
                          ),
                        ),
                        _StatusBadge(status: status),
                      ],
                    ),
                    const SizedBox(height: 4),
                    Text(
                      'Slot ${status.slotIdentifier}',
                      style: const TextStyle(color: kTextSecondary, fontSize: 13),
                    ),
                    const SizedBox(height: 8),
                    Row(
                      children: [
                        Icon(
                          locked ? Icons.lock : Icons.lock_open,
                          size: 14,
                          color: doorColor,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          !doorKnown
                              ? 'Door status unknown'
                              : (locked ? 'Door locked' : 'Door open'),
                          style: TextStyle(
                            color: doorColor,
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          const Divider(color: Color(0x0FFFFFFF), height: 1),
          const SizedBox(height: 16),
          Row(
            children: [
              _Metric(
                icon: Icons.thermostat,
                label: 'TEMP',
                value: temperature == null
                    ? '---'
                    : '${temperature.toStringAsFixed(1)}°C',
              ),
              const SizedBox(width: 12),
              _Metric(
                icon: Icons.bolt,
                label: 'VOLTAGE',
                value: voltage == null ? '---' : '${voltage.toStringAsFixed(1)}V',
              ),
            ],
          ),
          const SizedBox(height: 16),
          PrimaryButton(
            label: status.isPending
                ? 'Confirming deposit...'
                : !collectEnabled
                    ? 'Complete payment first'
                    : canCollect
                        ? 'Collect Battery & Pay'
                        : 'Charging to 20% ($soc%)',
            onPressed: canCollect ? onCollect : null,
          ),
        ],
      ),
    );
  }
}

class _SocRing extends StatelessWidget {
  final int level;

  const _SocRing({required this.level});

  Color get _color {
    if (level < 20) return kDanger;
    if (level < 60) return kWarning;
    return kPrimary;
  }

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      width: 72,
      height: 72,
      child: Stack(
        alignment: Alignment.center,
        children: [
          CircularProgressIndicator(
            value: (level.clamp(0, 100)) / 100,
            strokeWidth: 6,
            backgroundColor: kBgCard2,
            valueColor: AlwaysStoppedAnimation<Color>(_color),
          ),
          Text(
            '$level%',
            style: TextStyle(
              color: _color,
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ),
        ],
      ),
    );
  }
}

class _StatusBadge extends StatelessWidget {
  final MyBatteryStatus status;

  const _StatusBadge({required this.status});

  @override
  Widget build(BuildContext context) {
    final charging = status.telemetry?.relayOn ?? true;
    final label = status.isPending
        ? 'PENDING'
        : charging
            ? 'CHARGING'
            : 'STANDBY';
    final color = status.isPending
        ? kWarning
        : charging
            ? kPrimary
            : kTextSecondary;

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          color: color,
          fontSize: 10,
          fontWeight: FontWeight.w800,
          letterSpacing: 0.5,
        ),
      ),
    );
  }
}

class _Metric extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _Metric({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: kBgCard2,
          borderRadius: BorderRadius.circular(12),
        ),
        child: Row(
          children: [
            Icon(icon, size: 16, color: kTextSecondary),
            const SizedBox(width: 8),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: const TextStyle(
                    color: kTextSecondary,
                    fontSize: 9,
                    fontWeight: FontWeight.w700,
                    letterSpacing: 0.5,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  value,
                  style: const TextStyle(
                    color: kTextPrimary,
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
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
