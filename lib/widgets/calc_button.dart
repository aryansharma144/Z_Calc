import 'package:flutter/material.dart';

enum CalcButtonType { digit, operatorBtn, action, equals, function }

/// A single calculator key with a satisfying scale + shadow press animation.
class CalcButton extends StatefulWidget {
  final String label;
  final VoidCallback onTap;
  final CalcButtonType type;
  final double fontSize;

  const CalcButton({
    super.key,
    required this.label,
    required this.onTap,
    this.type = CalcButtonType.digit,
    this.fontSize = 24,
  });

  @override
  State<CalcButton> createState() => _CalcButtonState();
}

class _CalcButtonState extends State<CalcButton> {
  bool _pressed = false;

  Color _bgColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (widget.type) {
      case CalcButtonType.digit:
        return scheme.surfaceContainerHighest;
      case CalcButtonType.operatorBtn:
        return scheme.primaryContainer;
      case CalcButtonType.action:
        return scheme.errorContainer;
      case CalcButtonType.equals:
        return scheme.primary;
      case CalcButtonType.function:
        return scheme.secondaryContainer;
    }
  }

  Color _fgColor(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    switch (widget.type) {
      case CalcButtonType.digit:
        return scheme.onSurface;
      case CalcButtonType.operatorBtn:
        return scheme.onPrimaryContainer;
      case CalcButtonType.action:
        return scheme.onErrorContainer;
      case CalcButtonType.equals:
        return scheme.onPrimary;
      case CalcButtonType.function:
        return scheme.onSecondaryContainer;
    }
  }

  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTapDown: (_) => setState(() => _pressed = true),
      onTapUp: (_) {
        setState(() => _pressed = false);
        widget.onTap();
      },
      onTapCancel: () => setState(() => _pressed = false),
      child: AnimatedScale(
        scale: _pressed ? 0.88 : 1.0,
        duration: const Duration(milliseconds: 100),
        curve: Curves.easeOut,
        child: AnimatedContainer(
          duration: const Duration(milliseconds: 150),
          curve: Curves.easeOut,
          margin: const EdgeInsets.all(6),
          decoration: BoxDecoration(
            color: _bgColor(context),
            borderRadius: BorderRadius.circular(20),
            boxShadow: _pressed
                ? const []
                : [
              BoxShadow(
                color: Colors.black.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 4),
              ),
            ],
          ),
          alignment: Alignment.center,
          child: Text(
            widget.label,
            style: TextStyle(
              fontSize: widget.fontSize,
              fontWeight: FontWeight.w600,
              color: _fgColor(context),
            ),
          ),
        ),
      ),
    );
  }
}
