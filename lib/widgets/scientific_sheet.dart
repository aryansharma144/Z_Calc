import 'package:flutter/material.dart';
import 'calc_button.dart';

class _SciKey {
  final String label;
  final String value;
  const _SciKey(this.label, this.value);
}

/// Modal bottom sheet that slides up to reveal the advanced scientific
/// keypad (trig, inverses, constants, powers, factorial, derivative and
/// integral helpers).
class ScientificSheet extends StatelessWidget {
  final void Function(String) onKey;

  const ScientificSheet({super.key, required this.onKey});

  static Future<void> show(BuildContext context, void Function(String) onKey) {
    return showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (_) => ScientificSheet(onKey: onKey),
    );
  }

  static const List<_SciKey> _keys = [
    _SciKey('sin', 'sin('),
    _SciKey('cos', 'cos('),
    _SciKey('tan', 'tan('),
    _SciKey('asin', 'asin('),
    _SciKey('acos', 'acos('),
    _SciKey('atan', 'atan('),
    _SciKey('π', 'pi'),
    _SciKey('e', 'e'),
    _SciKey('log', 'log('),
    _SciKey('ln', 'ln('),
    _SciKey('√', 'sqrt('),
    _SciKey('xʸ', '^'),
    _SciKey('x!', '!'),
    _SciKey('d/dx', 'deriv('),
    _SciKey('∫dx', 'integral('),
    _SciKey('x', 'x'),
    _SciKey(',', ','),
    _SciKey('(', '('),
    _SciKey(')', ')'),
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return DraggableScrollableSheet(
      initialChildSize: 0.62,
      minChildSize: 0.4,
      maxChildSize: 0.92,
      builder: (context, scrollController) {
        return Container(
          decoration: BoxDecoration(
            color: theme.colorScheme.surface,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(28)),
            boxShadow: [
              BoxShadow(
                color: Colors.black.withOpacity(0.15),
                blurRadius: 24,
                offset: const Offset(0, -4),
              ),
            ],
          ),
          child: Column(
            children: [
              const SizedBox(height: 12),
              Container(
                width: 44,
                height: 5,
                decoration: BoxDecoration(
                  color: theme.colorScheme.onSurface.withOpacity(0.2),
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 16, 20, 8),
                child: Row(
                  children: [
                    Icon(Icons.functions, color: theme.colorScheme.primary),
                    const SizedBox(width: 8),
                    Text(
                      'Scientific Functions',
                      style: theme.textTheme.titleMedium
                          ?.copyWith(fontWeight: FontWeight.bold),
                    ),
                    const Spacer(),
                    IconButton(
                      icon: const Icon(Icons.close),
                      onPressed: () => Navigator.of(context).pop(),
                    ),
                  ],
                ),
              ),
              Expanded(
                child: GridView.builder(
                  controller: scrollController,
                  padding:
                  const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                  gridDelegate:
                  const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 4,
                    childAspectRatio: 1.3,
                  ),
                  itemCount: _keys.length,
                  itemBuilder: (context, index) {
                    final key = _keys[index];
                    return CalcButton(
                      label: key.label,
                      fontSize: 18,
                      type: CalcButtonType.function,
                      onTap: () => onKey(key.value),
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
    );
  }
}
