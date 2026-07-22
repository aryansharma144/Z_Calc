import 'dart:convert';
import 'package:http/http.dart' as http;

/// Wraps a rates lookup result together with whether it came from the
/// offline fallback table (so the UI can show an "offline" indicator).
class RatesResult {
  final Map<String, double> rates;
  final bool isFallback;
  const RatesResult(this.rates, this.isFallback);
}

/// Fetches live currency conversion rates from the free frankfurter.app
/// API, with a static offline fallback table used whenever the network
/// call fails or times out.
class CurrencyService {
  static const String _baseUrl = 'https://api.frankfurter.app';

  /// Static fallback rates (relative to USD), used only when offline.
  static const Map<String, double> _fallbackUsdRates = {
    'USD': 1.0,
    'EUR': 0.92,
    'GBP': 0.78,
    'INR': 83.30,
    'JPY': 156.50,
    'CAD': 1.36,
    'AUD': 1.51,
    'CNY': 7.24,
    'CHF': 0.90,
    'SGD': 1.34,
  };

  static List<String> get supportedCurrencies =>
      _fallbackUsdRates.keys.toList()..sort();

  /// Fetches live rates for [base] currency. Falls back to the static
  /// table (converted relative to [base]) if the request fails.
  static Future<RatesResult> fetchRates(String base) async {
    try {
      final uri = Uri.parse('$_baseUrl/latest?from=$base');
      final response =
      await http.get(uri).timeout(const Duration(seconds: 8));
      if (response.statusCode == 200) {
        final data = jsonDecode(response.body) as Map<String, dynamic>;
        final ratesJson = data['rates'] as Map<String, dynamic>;
        final rates = ratesJson.map<String, double>(
              (key, value) => MapEntry(key, (value as num).toDouble()),
        );
        rates[base] = 1.0;
        return RatesResult(rates, false);
      }
      throw Exception('Bad response: ${response.statusCode}');
    } catch (_) {
      return RatesResult(_fallbackRatesRelativeTo(base), true);
    }
  }

  static Map<String, double> _fallbackRatesRelativeTo(String base) {
    final baseUsdRate = _fallbackUsdRates[base] ?? 1.0;
    return _fallbackUsdRates.map(
          (key, usdRate) => MapEntry(key, usdRate / baseUsdRate),
    );
  }
}
