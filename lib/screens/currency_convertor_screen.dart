import 'package:flutter/material.dart';
import '../services/currency_service.dart';
import '../widgets/calc_button.dart';
import '../theme.dart';

class CurrencyConverterScreen extends StatefulWidget {
  const CurrencyConverterScreen({super.key});

  @override
  State<CurrencyConverterScreen> createState() =>
      _CurrencyConverterScreenState();
}

class _CurrencyConverterScreenState extends State<CurrencyConverterScreen>
    with SingleTickerProviderStateMixin {
  String _fromCurrency = 'USD';
  String _toCurrency = 'INR';
  String _amount = '1';
  Map<String, double> _rates = {};
  bool _loading = true;
  bool _isOffline = false;
  late final AnimationController _swapController;

  final List<String> _currencies = CurrencyService.supportedCurrencies;

  @override
  void initState() {
    super.initState();
    _swapController = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 300),
    );
    _loadRates();
  }

  @override
  void dispose() {
    _swapController.dispose();
    super.dispose();
  }

  Future<void> _loadRates() async {
    setState(() => _loading = true);
    final result = await CurrencyService.fetchRates(_fromCurrency);
    if (!mounted) return;
    setState(() {
      _rates = result.rates;
      _isOffline = result.isFallback;
      _loading = false;
    });
  }

  void _swapCurrencies() {
    _swapController.forward(from: 0);
    setState(() {
      final temp = _fromCurrency;
      _fromCurrency = _toCurrency;
      _toCurrency = temp;
    });
    _loadRates();
  }

  double get _convertedValue {
    final amount = double.tryParse(_amount) ?? 0;
    final rate = _rates[_toCurrency] ?? 0;
    return amount * rate;
  }

  void _onKey(String value) {
    setState(() {
      switch (value) {
        case 'AC':
          _amount = '0';
          break;
        case '⌫':
          _amount = _amount.length > 1
              ? _amount.substring(0, _amount.length - 1)
              : '0';
          break;
        case '.':
          if (!_amount.contains('.')) _amount += '.';
          break;
        default:
          if (_amount == '0') {
            _amount = value;
          } else {
            _amount += value;
          }
      }
    });
  }

  String _formatAmount(double value) {
    if (value == value.roundToDouble()) return value.toStringAsFixed(2);
    return value.toStringAsFixed(4);
  }

  Widget _currencyDropdown(String value, ValueChanged<String> onChanged) {
    return DropdownButton<String>(
      value: value,
      underline: const SizedBox(),
      borderRadius: BorderRadius.circular(16),
      items: _currencies
          .map((c) => DropdownMenuItem(
        value: c,
        child: Text(c,
            style: const TextStyle(fontWeight: FontWeight.bold)),
      ))
          .toList(),
      onChanged: (v) {
        if (v != null) onChanged(v);
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                Text('Currency Converter',
                    style: theme.textTheme.titleLarge
                        ?.copyWith(fontWeight: FontWeight.bold)),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.refresh),
                  onPressed: _loadRates,
                  tooltip: 'Refresh rates',
                ),
              ],
            ),
            if (_isOffline)
              Padding(
                padding: const EdgeInsets.only(bottom: 8),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(Icons.cloud_off,
                        size: 16, color: theme.colorScheme.error),
                    const SizedBox(width: 6),
                    Text('Offline — showing cached rates',
                        style: TextStyle(
                            color: theme.colorScheme.error, fontSize: 12)),
                  ],
                ),
              ),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              padding: const EdgeInsets.all(20),
              decoration: AppTheme.glassDecoration(context),
              child: _loading
                  ? const Padding(
                padding: EdgeInsets.symmetric(vertical: 24),
                child: Center(child: CircularProgressIndicator()),
              )
                  : Column(
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text('From', style: theme.textTheme.bodySmall),
                          _currencyDropdown(_fromCurrency, (v) {
                            setState(() => _fromCurrency = v);
                            _loadRates();
                          }),
                        ],
                      ),
                      RotationTransition(
                        turns: Tween(begin: 0.0, end: 1.0)
                            .animate(_swapController),
                        child: IconButton(
                          icon: const Icon(Icons.swap_horiz_rounded),
                          onPressed: _swapCurrencies,
                          tooltip: 'Swap currencies',
                        ),
                      ),
                      Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text('To', style: theme.textTheme.bodySmall),
                          _currencyDropdown(_toCurrency, (v) {
                            setState(() => _toCurrency = v);
                          }),
                        ],
                      ),
                    ],
                  ),
                  const Divider(height: 32),
                  Align(
                    alignment: Alignment.centerRight,
                    child: FittedBox(
                      fit: BoxFit.scaleDown,
                      child: Text(
                        _amount,
                        style: theme.textTheme.headlineMedium
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  AnimatedSwitcher(
                    duration: const Duration(milliseconds: 250),
                    child: Align(
                      key: ValueKey(_convertedValue),
                      alignment: Alignment.centerRight,
                      child: FittedBox(
                        fit: BoxFit.scaleDown,
                        child: Text(
                          '${_formatAmount(_convertedValue)} $_toCurrency',
                          style: theme.textTheme.displaySmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: theme.colorScheme.primary,
                          ),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                childAspectRatio: 1.3,
                children: [
                  _numKey('7'),
                  _numKey('8'),
                  _numKey('9'),
                  _iconKey('⌫'),
                  _numKey('4'),
                  _numKey('5'),
                  _numKey('6'),
                  _actionKey('AC'),
                  _numKey('1'),
                  _numKey('2'),
                  _numKey('3'),
                  _numKey('.'),
                  _numKey('0'),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _numKey(String label) => CalcButton(
      label: label, type: CalcButtonType.digit, onTap: () => _onKey(label));
  Widget _iconKey(String label) => CalcButton(
      label: label,
      type: CalcButtonType.function,
      onTap: () => _onKey(label));
  Widget _actionKey(String label) => CalcButton(
      label: label, type: CalcButtonType.action, onTap: () => _onKey(label));
}
