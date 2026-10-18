import 'package:http/http.dart' as http;

import '../../../../core/error/exceptions.dart';
import '../models/candle_model.dart';

/// Contract for fetching OHLC candle data from a remote source.
abstract class CandleRemoteDataSource {
  /// Fetches AAPL historical data from the Plotly GitHub dataset.
  ///
  /// Throws [ServerException] on HTTP error or network failure.
  Future<List<CandleModel>> fetchCandles();
}

class CandleRemoteDataSourceImpl implements CandleRemoteDataSource {
  final http.Client client;

  static const _dataUrl =
      'https://raw.githubusercontent.com/plotly/datasets/master/'
      'finance-charts-apple.csv';

  CandleRemoteDataSourceImpl({required this.client});

  @override
  Future<List<CandleModel>> fetchCandles() async {
    try {
      final response = await client.get(Uri.parse(_dataUrl));

      if (response.statusCode != 200) {
        throw ServerException(
          'Remote CSV fetch failed with status ${response.statusCode}',
        );
      }

      return CandleModel.fromCsvString(response.body);
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Network error fetching candle data: $e');
    }
  }
}
