import 'package:flutter/services.dart' show rootBundle;

import '../../../../core/error/exceptions.dart';
import '../models/candle_model.dart';

/// Contract for loading OHLC candle data from a bundled asset.
abstract class CandleLocalDataSource {
  /// Loads AAPL data from the bundled `assets/aapl_data.csv`.
  ///
  /// Throws [CacheException] if the asset cannot be read or parsed.
  Future<List<CandleModel>> fetchCandles();
}

class CandleLocalDataSourceImpl implements CandleLocalDataSource {
  static const _assetPath = 'assets/aapl_data.csv';

  @override
  Future<List<CandleModel>> fetchCandles() async {
    try {
      final csvString = await rootBundle.loadString(_assetPath);
      return CandleModel.fromCsvString(csvString);
    } catch (e) {
      throw CacheException('Failed to load bundled CSV asset: $e');
    }
  }
}
