import 'dart:math' as math;

/// Thrown for mathematically undefined results (division by zero,
/// sqrt of a negative number, out-of-domain trig inverses, etc.)
/// as opposed to plain syntax errors which throw [FormatException].
class EvaluationException implements Exception {
  final String message;
  const EvaluationException(this.message);
  @override
  String toString() => message;
}

enum _TokType {
  number,
  ident,
  lparen,
  rparen,
  plus,
  minus,
  mul,
  div,
  mod,
  pow,
  fact,
  end,
}

class _Token {
  final _TokType type;
  final String text;
  final double? value;
  _Token(this.type, this.text, [this.value]);
}

/// A self-contained recursive-descent math expression evaluator.
///
/// Supports: + - * / % ^ (power), ! (factorial), parentheses,
/// implicit multiplication (e.g. "2(3+4)", "2pi", "3sin(30)"),
/// the constants pi & e, the bound variable x, the functions
/// sin cos tan asin acos atan log ln sqrt exp abs, and the calculus
/// helpers deriv(expr, x0) and integral(expr, a, b).
///
/// Trigonometric functions operate in radians.
class MathEvaluator {
  static const Set<String> _functionNames = {
    'sin', 'cos', 'tan', 'asin', 'acos', 'atan',
    'log', 'ln', 'sqrt', 'exp', 'abs',
  };
  static const Set<String> _constantNames = {'pi', 'e'};

  /// Evaluates a full math expression string and returns the numeric result.
  /// [xValue] binds the free variable `x`, used internally when evaluating
  /// derivative/integral sub-expressions.
  static double evaluate(String input, {double xValue = 0}) {
    String expr = input.trim();
    if (expr.isEmpty) {
      throw const FormatException('Empty expression');
    }
    expr = expr.replaceAll(' ', '').replaceAll('×', '*').replaceAll('÷', '/');
    expr = expr.replaceAll('π', 'pi');
    expr = _preprocessCalculus(expr);
    final tokens = _tokenize(expr);
    final withImplicitMul = _insertImplicitMultiplication(tokens);
    final parser = _Parser(withImplicitMul, xValue);
    final result = parser.parseExpression();
    parser._expectEnd();
    if (result.isNaN || result.isInfinite) {
      throw const EvaluationException('Undefined');
    }
    return result;
  }

  // ---------------------------------------------------------------------
  // Calculus preprocessing: deriv(expr, x0) and integral(expr, a, b) are
  // evaluated numerically first and substituted with their result so the
  // main tokenizer/parser never has to know about them.
  // ---------------------------------------------------------------------
  static String _preprocessCalculus(String expr) {
    for (final fname in ['deriv', 'integral']) {
      final start = expr.indexOf('$fname(');
      if (start != -1) {
        final openParen = start + fname.length;
        final closeParen = _matchingParenIndex(expr, openParen);
        if (closeParen == -1) {
          throw FormatException('Mismatched parentheses in $fname()');
        }
        final argsStr = expr.substring(openParen + 1, closeParen);
        final args = _splitTopLevel(argsStr);
        double value;
        if (fname == 'deriv') {
          if (args.length != 2) {
            throw const FormatException(
                'deriv requires 2 arguments: deriv(expr, x0)');
          }
          final x0 = evaluate(args[1]);
          value = _numericDerivative(args[0], x0);
        } else {
          if (args.length != 3) {
            throw const FormatException(
                'integral requires 3 arguments: integral(expr, a, b)');
          }
          final a = evaluate(args[1]);
          final b = evaluate(args[2]);
          value = _numericIntegral(args[0], a, b);
        }
        if (value.isNaN || value.isInfinite) {
          throw const EvaluationException('Undefined');
        }
        final replacement = '(${value.toStringAsFixed(10)})';
        final newExpr = expr.substring(0, start) +
            replacement +
            expr.substring(closeParen + 1);
        return _preprocessCalculus(newExpr);
      }
    }
    return expr;
  }

  static int _matchingParenIndex(String s, int openIdx) {
    int depth = 0;
    for (int i = openIdx; i < s.length; i++) {
      if (s[i] == '(') depth++;
      if (s[i] == ')') {
        depth--;
        if (depth == 0) return i;
      }
    }
    return -1;
  }

  static List<String> _splitTopLevel(String s) {
    final parts = <String>[];
    int depth = 0;
    final buffer = StringBuffer();
    for (int i = 0; i < s.length; i++) {
      final c = s[i];
      if (c == '(') depth++;
      if (c == ')') depth--;
      if (c == ',' && depth == 0) {
        parts.add(buffer.toString());
        buffer.clear();
      } else {
        buffer.write(c);
      }
    }
    parts.add(buffer.toString());
    return parts;
  }

  static double _numericDerivative(String exprStr, double x0) {
    const h = 1e-5;
    final fPlus = evaluate(exprStr, xValue: x0 + h);
    final fMinus = evaluate(exprStr, xValue: x0 - h);
    return (fPlus - fMinus) / (2 * h);
  }

  static double _numericIntegral(String exprStr, double a, double b) {
    const n = 1000; // even, for Simpson's rule
    final h = (b - a) / n;
    double sum = evaluate(exprStr, xValue: a) + evaluate(exprStr, xValue: b);
    for (int i = 1; i < n; i++) {
      final x = a + i * h;
      final coeff = (i % 2 == 0) ? 2.0 : 4.0;
      sum += coeff * evaluate(exprStr, xValue: x);
    }
    return sum * h / 3;
  }

  // ---------------------------------------------------------------------
  // Tokenizer
  // ---------------------------------------------------------------------
  static List<_Token> _tokenize(String expr) {
    final tokens = <_Token>[];
    int i = 0;
    while (i < expr.length) {
      final c = expr[i];
      if (c == '.' || _isDigitChar(c)) {
        final start = i;
        bool seenDot = false;
        while (i < expr.length && (_isDigitChar(expr[i]) || expr[i] == '.')) {
          if (expr[i] == '.') {
            if (seenDot) break;
            seenDot = true;
          }
          i++;
        }
        final numStr = expr.substring(start, i);
        final val = double.tryParse(numStr);
        if (val == null) {
          throw FormatException('Invalid number "$numStr"');
        }
        tokens.add(_Token(_TokType.number, numStr, val));
        continue;
      }
      if (_isAlpha(c)) {
        final start = i;
        while (i < expr.length && _isAlpha(expr[i])) {
          i++;
        }
        tokens.add(_Token(_TokType.ident, expr.substring(start, i)));
        continue;
      }
      switch (c) {
        case '(':
          tokens.add(_Token(_TokType.lparen, c));
          break;
        case ')':
          tokens.add(_Token(_TokType.rparen, c));
          break;
        case '+':
          tokens.add(_Token(_TokType.plus, c));
          break;
        case '-':
          tokens.add(_Token(_TokType.minus, c));
          break;
        case '*':
          tokens.add(_Token(_TokType.mul, c));
          break;
        case '/':
          tokens.add(_Token(_TokType.div, c));
          break;
        case '%':
          tokens.add(_Token(_TokType.mod, c));
          break;
        case '^':
          tokens.add(_Token(_TokType.pow, c));
          break;
        case '!':
          tokens.add(_Token(_TokType.fact, c));
          break;
        default:
          throw FormatException('Unexpected character "$c"');
      }
      i++;
    }
    tokens.add(_Token(_TokType.end, ''));
    return tokens;
  }

  static bool _isDigitChar(String c) {
    final code = c.codeUnitAt(0);
    return code >= 48 && code <= 57;
  }

  static bool _isAlpha(String c) {
    final code = c.codeUnitAt(0);
    return (code >= 65 && code <= 90) || (code >= 97 && code <= 122);
  }

  // ---------------------------------------------------------------------
  // Implicit multiplication pass: "2(3+4)" -> "2*(3+4)", "2pi" -> "2*pi",
  // "3sin(30)" -> "3*sin(30)".
  // ---------------------------------------------------------------------
  static List<_Token> _insertImplicitMultiplication(List<_Token> tokens) {
    final result = <_Token>[];
    for (int i = 0; i < tokens.length; i++) {
      final cur = tokens[i];
      result.add(cur);
      if (i == tokens.length - 1) continue;
      final next = tokens[i + 1];
      final curEndsValue = cur.type == _TokType.number ||
          cur.type == _TokType.rparen ||
          cur.type == _TokType.fact ||
          (cur.type == _TokType.ident &&
              (_constantNames.contains(cur.text) || cur.text == 'x'));
      final nextStartsValue = next.type == _TokType.number ||
          next.type == _TokType.lparen ||
          next.type == _TokType.ident;
      if (curEndsValue && nextStartsValue) {
        result.add(_Token(_TokType.mul, '*'));
      }
    }
    return result;
  }

  static bool isFunctionName(String s) => _functionNames.contains(s);
  static bool isConstantName(String s) => _constantNames.contains(s);
}

class _Parser {
  final List<_Token> tokens;
  final double xValue;
  int pos = 0;
  _Parser(this.tokens, this.xValue);

  _Token get _current => tokens[pos];
  void _advance() => pos++;

  void _expectEnd() {
    if (_current.type != _TokType.end) {
      throw FormatException('Unexpected token "${_current.text}"');
    }
  }

  // expression := term (('+'|'-') term)*
  double parseExpression() {
    double value = _parseTerm();
    while (_current.type == _TokType.plus || _current.type == _TokType.minus) {
      final op = _current.type;
      _advance();
      final rhs = _parseTerm();
      value = op == _TokType.plus ? value + rhs : value - rhs;
    }
    return value;
  }

  // term := power (('*'|'/'|'%') power)*
  double _parseTerm() {
    double value = _parsePower();
    while (_current.type == _TokType.mul ||
        _current.type == _TokType.div ||
        _current.type == _TokType.mod) {
      final op = _current.type;
      _advance();
      final rhs = _parsePower();
      if (op == _TokType.mul) {
        value = value * rhs;
      } else if (op == _TokType.div) {
        if (rhs == 0) throw const EvaluationException('Undefined');
        value = value / rhs;
      } else {
        if (rhs == 0) throw const EvaluationException('Undefined');
        value = value % rhs;
      }
    }
    return value;
  }

  // power := unary ('^' power)?   (right associative)
  double _parsePower() {
    final base = _parseUnary();
    if (_current.type == _TokType.pow) {
      _advance();
      final exponent = _parsePower();
      return math.pow(base, exponent).toDouble();
    }
    return base;
  }

  // unary := ('-'|'+') unary | postfix
  double _parseUnary() {
    if (_current.type == _TokType.minus) {
      _advance();
      return -_parseUnary();
    }
    if (_current.type == _TokType.plus) {
      _advance();
      return _parseUnary();
    }
    return _parsePostfix();
  }

  // postfix := primary ('!')*
  double _parsePostfix() {
    double value = _parsePrimary();
    while (_current.type == _TokType.fact) {
      _advance();
      value = _factorial(value);
    }
    return value;
  }

  double _factorial(double n) {
    if (n < 0 || (n - n.roundToDouble()).abs() > 1e-9) {
      throw const EvaluationException('Undefined');
    }
    final intVal = n.round();
    if (intVal > 170) {
      throw const EvaluationException('Undefined');
    }
    double result = 1;
    for (int i = 2; i <= intVal; i++) {
      result *= i;
    }
    return result;
  }

  // primary := number | '(' expression ')' | identifier ['(' expression ')']
  double _parsePrimary() {
    final tok = _current;
    if (tok.type == _TokType.number) {
      _advance();
      return tok.value!;
    }
    if (tok.type == _TokType.lparen) {
      _advance();
      final value = parseExpression();
      if (_current.type != _TokType.rparen) {
        throw const FormatException('Missing closing parenthesis');
      }
      _advance();
      return value;
    }
    if (tok.type == _TokType.ident) {
      final name = tok.text;
      _advance();
      if (name == 'pi') return math.pi;
      if (name == 'e') return math.e;
      if (name == 'x') return xValue;
      if (MathEvaluator.isFunctionName(name)) {
        if (_current.type != _TokType.lparen) {
          throw FormatException('Expected "(" after "$name"');
        }
        _advance();
        final arg = parseExpression();
        if (_current.type != _TokType.rparen) {
          throw const FormatException('Missing closing parenthesis');
        }
        _advance();
        return _applyFunction(name, arg);
      }
      throw FormatException('Unknown identifier "$name"');
    }
    throw FormatException('Unexpected token "${tok.text}"');
  }

  double _applyFunction(String name, double arg) {
    switch (name) {
      case 'sin':
        return math.sin(arg);
      case 'cos':
        return math.cos(arg);
      case 'tan':
        return math.tan(arg);
      case 'asin':
        if (arg < -1 || arg > 1) throw const EvaluationException('Undefined');
        return math.asin(arg);
      case 'acos':
        if (arg < -1 || arg > 1) throw const EvaluationException('Undefined');
        return math.acos(arg);
      case 'atan':
        return math.atan(arg);
      case 'log':
        if (arg <= 0) throw const EvaluationException('Undefined');
        return math.log(arg) / math.ln10;
      case 'ln':
        if (arg <= 0) throw const EvaluationException('Undefined');
        return math.log(arg);
      case 'sqrt':
        if (arg < 0) throw const EvaluationException('Undefined');
        return math.sqrt(arg);
      case 'exp':
        return math.exp(arg);
      case 'abs':
        return arg.abs();
      default:
        throw FormatException('Unknown function "$name"');
    }
  }
}
