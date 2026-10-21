import 'dart:convert';

import 'package:http/http.dart' as http;

import '../../../../core/error/exceptions.dart';
import '../models/candle_model.dart';

/// Contract for fetching OHLC candle data from a remote source.
abstract class CandleRemoteDataSource {
  /// Fetches the latest one-minute OHLC candles for [symbol] (e.g.
  /// 'AAPL', 'MSFT') from Twelve Data.
  ///
  /// Throws [ServerException] on HTTP error or network failure.
  Future<List<CandleModel>> fetchCandles({required String symbol});
}

class CandleRemoteDataSourceImpl implements CandleRemoteDataSource {
  final http.Client client;

  // Twelve Data free-tier API key, kept in source at the project owner's
  // explicit request (this repo is public, and the owner accepted that
  // tradeoff rather than wiring up --dart-define for a course project).
  // Rotate this key if the project is ever reused beyond coursework.
  static const _apiKey = 'eda7a0c493564cf8bf76fba729b99b62';

  CandleRemoteDataSourceImpl({required this.client});

  @override
  Future<List<CandleModel>> fetchCandles({required String symbol}) async {
    try {
      final requestUri = Uri.https('api.twelvedata.com', '/time_series', {
        'symbol': symbol,
        'interval': '1min',
        'outputsize': '120',
        'apikey': _apiKey,
      });
      final response = await client.get(requestUri);

      if (response.statusCode != 200) {
        throw ServerException(
          'Live market request for $symbol failed with status ${response.statusCode}',
        );
      }

      final payload = jsonDecode(response.body) as Map<String, dynamic>;
      if (payload['status'] == 'error') {
        throw ServerException(
          payload['message'] as String? ?? 'Live market API returned an error.',
        );
      }
      final values = payload['values'];
      if (values is! List || values.isEmpty) {
        throw ServerException('Live market API returned no candles for $symbol.');
      }

      final candles = values
          .map(
            (value) => CandleModel.fromTwelveDataJson(
              value as Map<String, dynamic>,
            ),
          )
          .toList();
      // API data arrives newest first. The chart needs oldest first.
      candles.sort((a, b) => a.date.compareTo(b.date));
      return candles;
    } on ServerException {
      rethrow;
    } catch (e) {
      throw ServerException('Network error fetching candle data: $e');
    }
  }
}
