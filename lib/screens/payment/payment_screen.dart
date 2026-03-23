import 'package:flutter/material.dart';
import 'package:ridercms/utils/themes/app_theme.dart';
import '../../widgets/common_widgets.dart';

class _BatteryItem {
  final String id;
  final String slot;
  final String chargeTime;
  final int fee;
  const _BatteryItem(
      {required this.id,
        required this.slot,
        required this.chargeTime,
        required this.fee});
}

class _PayMethod {
  final String id;
  final String label;
  final String description;
  const _PayMethod(
      {required this.id, required this.label, required this.description});
}

const _batteries = [
  _BatteryItem(id: 'BATT102', slot: 'A03', chargeTime: '1h 52m', fee: 112),
  _BatteryItem(id: 'BATT103', slot: 'A04', chargeTime: '2h 38m', fee: 158),
];

const _methods = [
  _PayMethod(
      id: 'mpesa',
      label: 'M-Pesa',
      description: 'Pay via M-Pesa mobile money'),
  _PayMethod(id: 'card', label: 'Card', description: 'Visa / Mastercard'),
  _PayMethod(
      id: 'wallet', label: 'Wallet', description: 'Balance: KSh 1,250'),
];

class PaymentScreen extends StatefulWidget {
  const PaymentScreen({super.key});

  @override
  State<PaymentScreen> createState() => _PaymentScreenState();
}

class _PaymentScreenState extends State<PaymentScreen> {
  String _selectedMethod = 'mpesa';
  final _phoneCtrl = TextEditingController(text: '+254 700 000 000');

  int get _subtotal => _batteries.fold(0, (sum, b) => sum + b.fee);
  int get _serviceFee => (_subtotal * 0.05).round();
  int get _grandTotal => _subtotal + _serviceFee;

  @override
  void dispose() {
    _phoneCtrl.dispose();
    super.dispose();
  }

  Icon _getMethodIcon(String id) {
    switch (id) {
      case 'mpesa':
        return const Icon(Icons.phone_android, color: kPrimary, size: 24);
      case 'card':
        return const Icon(Icons.credit_card, color: kPrimary, size: 24);
      case 'wallet':
        return const Icon(Icons.account_balance_wallet,
            color: kPrimary, size: 24);
      default:
        return const Icon(Icons.payment, color: kPrimary, size: 24);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBgDark,
      body: Stack(
        children: [
          SafeArea(
            child: SingleChildScrollView(
              padding: const EdgeInsets.only(bottom: 120),
              child: Column(
                children: [
                  // Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
                    child: Row(
                      children: [
                        const BackBtn(),
                        const SizedBox(width: 12),
                        const Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Payment',
                                style: TextStyle(
                                    color: kTextPrimary,
                                    fontSize: 20,
                                    fontWeight: FontWeight.w700)),
                            Text('Session #S004',
                                style: TextStyle(
                                    color: kTextSecondary, fontSize: 12)),
                          ],
                        ),
                      ],
                    ),
                  ),

                  // Charging summary
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('CHARGING SUMMARY',
                            style: TextStyle(
                                color: kTextSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        AppCard(
                          child: Column(
                            children: [
                              ..._batteries.asMap().entries.map((entry) {
                                final i = entry.key;
                                final b = entry.value;
                                return Column(
                                  children: [
                                    Row(
                                      children: [
                                        const Icon(Icons.battery_full,
                                            color: kPrimary),
                                        const SizedBox(width: 12),
                                        Expanded(
                                          child: Column(
                                            crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                            children: [
                                              Text(b.id,
                                                  style: const TextStyle(
                                                      color: kTextPrimary,
                                                      fontSize: 13,
                                                      fontWeight:
                                                      FontWeight.w600,
                                                      fontFamily: 'monospace')),
                                              Text(
                                                  'Slot ${b.slot} · ${b.chargeTime}',
                                                  style: const TextStyle(
                                                      color: kTextSecondary,
                                                      fontSize: 11)),
                                            ],
                                          ),
                                        ),
                                        Text('KSh ${b.fee}',
                                            style: const TextStyle(
                                                color: kTextPrimary,
                                                fontWeight: FontWeight.w700)),
                                      ],
                                    ),
                                    if (i < _batteries.length - 1) ...[
                                      const SizedBox(height: 12),
                                      Divider(
                                          color:
                                          Colors.white.withValues(alpha: 0.06),
                                          height: 1),
                                      const SizedBox(height: 12),
                                    ],
                                  ],
                                );
                              }),
                              const SizedBox(height: 12),
                              Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                              const SizedBox(height: 12),
                              _SummaryRow(label: 'Subtotal', value: 'KSh $_subtotal'),
                              const SizedBox(height: 8),
                              _SummaryRow(
                                  label: 'Service Fee (5%)', value: 'KSh $_serviceFee'),
                              const SizedBox(height: 12),
                              Divider(color: Colors.white.withValues(alpha: 0.06), height: 1),
                              const SizedBox(height: 12),
                              Row(
                                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                                children: [
                                  const Text('Total',
                                      style: TextStyle(
                                          color: kTextPrimary,
                                          fontWeight: FontWeight.w700)),
                                  Text('KSh $_grandTotal',
                                      style: const TextStyle(
                                          color: kPrimary,
                                          fontSize: 20,
                                          fontWeight: FontWeight.w700)),
                                ],
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  // Payment methods
                  Padding(
                    padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text('PAYMENT METHOD',
                            style: TextStyle(
                                color: kTextSecondary,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
                                letterSpacing: 0.5)),
                        const SizedBox(height: 12),
                        ..._methods.map((method) => Padding(
                          padding: const EdgeInsets.only(bottom: 12),
                          child: GestureDetector(
                            onTap: () =>
                                setState(() => _selectedMethod = method.id),
                            child: AppCard(
                              borderColor: _selectedMethod == method.id
                                  ? kPrimary
                                  : null,
                              child: Row(
                                children: [
                                  Container(
                                    width: 48,
                                    height: 48,
                                    decoration: BoxDecoration(
                                      color: _selectedMethod == method.id
                                          ? kPrimary.withValues(alpha: 0.15)
                                          : kBgCard2,
                                      borderRadius:
                                      BorderRadius.circular(12),
                                    ),
                                    child: Center(
                                        child:
                                        _getMethodIcon(method.id)),
                                  ),
                                  const SizedBox(width: 12),
                                  Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                      children: [
                                        Text(method.label,
                                            style: const TextStyle(
                                                color: kTextPrimary,
                                                fontWeight:
                                                FontWeight.w600)),
                                        Text(method.description,
                                            style: const TextStyle(
                                                color: kTextSecondary,
                                                fontSize: 12)),
                                      ],
                                    ),
                                  ),
                                  AnimatedContainer(
                                    duration:
                                    const Duration(milliseconds: 200),
                                    width: 20,
                                    height: 20,
                                    decoration: BoxDecoration(
                                      shape: BoxShape.circle,
                                      color: _selectedMethod == method.id
                                          ? kPrimary
                                          : Colors.transparent,
                                      border: Border.all(
                                        color: _selectedMethod == method.id
                                            ? kPrimary
                                            : Colors.white
                                            .withValues(alpha: 0.2),
                                        width: 2,
                                      ),
                                    ),
                                    child: _selectedMethod == method.id
                                        ? const Center(
                                        child: Icon(Icons.check,
                                            color: Colors.white,
                                            size: 12))
                                        : null,
                                  ),
                                ],
                              ),
                            ),
                          ),
                        )),
                      ],
                    ),
                  ),

                  // M-Pesa phone input
                  if (_selectedMethod == 'mpesa')
                    Padding(
                      padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text('M-Pesa Phone Number',
                              style: TextStyle(
                                  color: kTextSecondary,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w500)),
                          const SizedBox(height: 8),
                          TextField(
                            controller: _phoneCtrl,
                            keyboardType: TextInputType.phone,
                            style: const TextStyle(color: kTextPrimary),
                          ),
                          const SizedBox(height: 8),
                          const Text(
                              'You will receive an M-Pesa prompt on this number',
                              style: TextStyle(
                                  color: kTextSecondary, fontSize: 12)),
                        ],
                      ),
                    ),
                ],
              ),
            ),
          ),

          // Fixed bottom pay button
          Positioned(
            bottom: 0,
            left: 0,
            right: 0,
            child: Container(
              padding: const EdgeInsets.fromLTRB(24, 12, 24, 24),
              decoration: BoxDecoration(
                color: kBgCard,
                border: Border(top: BorderSide(color: Colors.white.withValues(alpha: 0.06))),
              ),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text('Total to Pay',
                          style: TextStyle(color: kTextSecondary, fontSize: 13)),
                      Text('KSh $_grandTotal',
                          style: const TextStyle(
                              color: kPrimary,
                              fontSize: 20,
                              fontWeight: FontWeight.w700)),
                    ],
                  ),
                  const SizedBox(height: 12),
                  PrimaryButton(
                    label:
                    'Pay KSh $_grandTotal via ${_methods.firstWhere((m) => m.id == _selectedMethod).label}',
                    onPressed: () =>
                        Navigator.pushNamed(context, '/payment-processing'),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SummaryRow extends StatelessWidget {
  final String label;
  final String value;
  const _SummaryRow({required this.label, required this.value});

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(label, style: const TextStyle(color: kTextSecondary, fontSize: 13)),
        Text(value, style: const TextStyle(color: kTextPrimary, fontSize: 13)),
      ],
    );
  }
}
