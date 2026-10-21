/// The fixed set of stock tickers the UI lets the user pick between.
///
/// Twelve Data's `time_series` endpoint will happily fetch any valid
/// ticker on the free tier -- this isn't a technical limit. It's a
/// deliberate, small whitelist (YAGNI) so the stock-picker chip row never
/// offers a symbol nobody asked for, and so [defaultSymbol] gives every
/// screen one single source of truth for "which stock did we start with".
class SupportedSymbols {
  SupportedSymbols._();

  static const String defaultSymbol = 'AAPL';

  static const List<String> all = [
    'AAPL',
    'MSFT',
    'GOOGL',
    'AMZN',
    'TSLA',
    'NVDA',
  ];
}
