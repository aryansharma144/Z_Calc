import 'package:flutter/material.dart';
import '../utils/math_evaluator.dart';
import '../widgets/calc_button.dart';
import '../widgets/expression_display.dart';
import '../widgets/scientific_sheet.dart';
import '../theme.dart';

class CalculatorScreen extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const CalculatorScreen({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  State<CalculatorScreen> createState() => _CalculatorScreenState();
}

class _CalculatorScreenState extends State<CalculatorScreen> {
  String _expression = '';
  String _result = '0';
  bool _isError = false;
  bool _justEvaluated = false;

  static const Set<String> _binOps = {'+', '-', '×', '÷', '%', '^'};

  bool _isDigit(String c) => c.codeUnitAt(0) >= 48 && c.codeUnitAt(0) <= 57;

  void _onKey(String value) {
    setState(() {
      switch (value) {
        case 'AC':
          _expression = '';
          _result = '0';
          _isError = false;
          _justEvaluated = false;
          return;
        case '⌫':
          if (_justEvaluated) {
            _expression = '';
            _justEvaluated = false;
          } else if (_expression.isNotEmpty) {
            _expression = _expression.substring(0, _expression.length - 1);
          }
          break;
        case '=':
          _evaluate();
          return;
        case '.':
          if (_justEvaluated) {
            _expression = '';
            _justEvaluated = false;
          }
          if (_canAppendDot()) _expression += '.';
          break;
        case '(':
        case ')':
          if (_justEvaluated) {
            _expression = '';
            _justEvaluated = false;
          }
          _expression += value;
          break;
        default:
          if (_binOps.contains(value)) {
            _appendOperator(value);
          } else {
            if (_justEvaluated) {
              _expression = '';
              _justEvaluated = false;
            }
            _expression += value;
          }
      }
      _liveEvaluate();
    });
  }

  bool _canAppendDot() {
    for (int i = _expression.length - 1; i >= 0; i--) {
      final c = _expression[i];
      if (c == '.') return false;
      if (!_isDigit(c)) return true;
    }
    return true;
  }

  void _appendOperator(String op) {
    if (_justEvaluated) {
      _expression = _isError ? '' : _result;
      _justEvaluated = false;
    }
    if (_expression.isEmpty) {
      if (op == '-') _expression += op;
      return;
    }
    final last = _expression[_expression.length - 1];
    if (last == '(') {
      if (op == '-') _expression += op;
      return;
    }
    if (_binOps.contains(last)) {
      if (op == '-' && last != '-') {
        _expression += op;
      } else {
        _expression = _expression.substring(0, _expression.length - 1) + op;
      }
      return;
    }
    _expression += op;
  }

  void _liveEvaluate() {
    if (_expression.isEmpty) {
      _result = '0';
      _isError = false;
      return;
    }
    try {
      final value = MathEvaluator.evaluate(_expression);
      _result = _formatNumber(value);
      _isError = false;
    } catch (_) {
      // Keep the last valid preview visible while the expression is
      // still incomplete (e.g. mid-way through typing "sin(").
    }
  }

  void _evaluate() {
    if (_expression.isEmpty) return;
    setState(() {
      try {
        final value = MathEvaluator.evaluate(_expression);
        _result = _formatNumber(value);
        _isError = false;
      } catch (e) {
        _result = e is EvaluationException ? e.message : 'Error';
        _isError = true;
      }
      _justEvaluated = true;
    });
  }

  String _formatNumber(double value) {
    if (value.isNaN || value.isInfinite) return 'Undefined';
    if (value == value.roundToDouble() && value.abs() < 1e15) {
      return value.toStringAsFixed(0);
    }
    String s = value.toStringAsFixed(10);
    s = s.replaceAll(RegExp(r'0+$'), '');
    s = s.replaceAll(RegExp(r'\.$'), '');
    return s;
  }

  void _openScientificSheet() {
    ScientificSheet.show(context, _onKey);
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            Row(
              children: [
                IconButton(
                  icon: Icon(isDark ? Icons.light_mode : Icons.dark_mode),
                  onPressed: widget.onToggleTheme,
                  tooltip: 'Toggle theme',
                ),
                const Spacer(),
                Text(
                  'Calculator',
                  style: theme.textTheme.titleLarge
                      ?.copyWith(fontWeight: FontWeight.bold),
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.backspace_outlined),
                  onPressed: () => _onKey('⌫'),
                  tooltip: 'Backspace',
                ),
                Container(
                  margin: const EdgeInsets.only(left: 4),
                  decoration: BoxDecoration(
                    color: theme.colorScheme.primary,
                    shape: BoxShape.circle,
                  ),
                  child: IconButton(
                    icon: Icon(Icons.functions_rounded,
                        color: theme.colorScheme.onPrimary),
                    onPressed: _openScientificSheet,
                    tooltip: 'Advanced Scientific Calculator',
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),
            AnimatedContainer(
              duration: const Duration(milliseconds: 250),
              width: double.infinity,
              decoration: AppTheme.glassDecoration(context),
              child: ExpressionDisplay(
                expression: _expression,
                result: _result,
                isError: _isError,
              ),
            ),
            const SizedBox(height: 16),
            Expanded(
              child: GridView.count(
                crossAxisCount: 4,
                childAspectRatio: 1.05,
                children: [
                  _btn('AC', CalcButtonType.action),
                  _btn('(', CalcButtonType.function),
                  _btn(')', CalcButtonType.function),
                  _btn('÷', CalcButtonType.operatorBtn),
                  _btn('7', CalcButtonType.digit),
                  _btn('8', CalcButtonType.digit),
                  _btn('9', CalcButtonType.digit),
                  _btn('×', CalcButtonType.operatorBtn),
                  _btn('4', CalcButtonType.digit),
                  _btn('5', CalcButtonType.digit),
                  _btn('6', CalcButtonType.digit),
                  _btn('-', CalcButtonType.operatorBtn),
                  _btn('1', CalcButtonType.digit),
                  _btn('2', CalcButtonType.digit),
                  _btn('3', CalcButtonType.digit),
                  _btn('+', CalcButtonType.operatorBtn),
                  _btn('mod', CalcButtonType.function),
                  _btn('0', CalcButtonType.digit),
                  _btn('.', CalcButtonType.digit),
                  _btn('=', CalcButtonType.equals),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _btn(String label, CalcButtonType type) {
    return CalcButton(
      label: label,
      type: type,
      onTap: () => _onKey(label),
    );
  }
}
