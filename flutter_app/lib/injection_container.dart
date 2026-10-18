import 'package:get_it/get_it.dart';
import 'package:http/http.dart' as http;

// ── Encoding feature ──────────────────────────────────────────────────
import 'features/encoding/data/datasources/candle_local_data_source.dart';
import 'features/encoding/data/datasources/candle_remote_data_source.dart';
import 'features/encoding/data/repositories/encoding_repository_impl.dart';
import 'features/encoding/domain/repositories/encoding_repository.dart';
import 'features/encoding/domain/usecases/encode_candles.dart';
import 'features/encoding/domain/usecases/fetch_candle_data.dart';
import 'features/encoding/presentation/bloc/encoding_bloc.dart';

// ── Automaton feature ─────────────────────────────────────────────────
import 'features/automaton/data/repositories/automaton_repository_impl.dart';
import 'features/automaton/domain/repositories/automaton_repository.dart';
import 'features/automaton/domain/usecases/inspect_automaton.dart';
import 'features/automaton/presentation/bloc/automaton_bloc.dart';

// ── Pattern detection feature ─────────────────────────────────────────
import 'features/pattern_detection/data/repositories/pattern_repository_impl.dart';
import 'features/pattern_detection/domain/repositories/pattern_repository.dart';
import 'features/pattern_detection/domain/usecases/detect_all_patterns.dart';

// ── ML scoring feature ────────────────────────────────────────────────
import 'features/ml_scoring/data/repositories/ml_repository_impl.dart';
import 'features/ml_scoring/domain/repositories/ml_repository.dart';
import 'features/ml_scoring/domain/usecases/score_matches.dart';

// ── Visualization feature ─────────────────────────────────────────────
import 'features/visualization/data/repositories/analysis_repository_impl.dart';
import 'features/visualization/domain/repositories/analysis_repository.dart';
import 'features/visualization/domain/usecases/run_full_analysis.dart';
import 'features/visualization/presentation/bloc/analysis_bloc.dart';

/// Global service locator instance.
final sl = GetIt.instance;

/// Registers all dependencies.
///
/// Call this once from `main()` before `runApp()`.
/// Registration order follows Clean Architecture layers:
///   External → Data Sources → Repositories → Use Cases → BLoCs
Future<void> init() async {
  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  EXTERNAL                                                       ║
  // ╚══════════════════════════════════════════════════════════════════╝
  sl.registerLazySingleton(() => http.Client());

  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  DATA SOURCES                                                   ║
  // ╚══════════════════════════════════════════════════════════════════╝
  sl.registerLazySingleton<CandleRemoteDataSource>(
    () => CandleRemoteDataSourceImpl(client: sl()),
  );
  sl.registerLazySingleton<CandleLocalDataSource>(
    () => CandleLocalDataSourceImpl(),
  );

  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  REPOSITORIES                                                   ║
  // ╚══════════════════════════════════════════════════════════════════╝

  // Encoding
  sl.registerLazySingleton<EncodingRepository>(
    () => EncodingRepositoryImpl(
      remoteDataSource: sl(),
      localDataSource: sl(),
    ),
  );

  // Automaton — pure algorithmic, no external deps
  sl.registerLazySingleton<AutomatonRepository>(
    () => AutomatonRepositoryImpl(),
  );

  // Pattern detection — depends on automaton
  sl.registerLazySingleton<PatternRepository>(
    () => PatternRepositoryImpl(automatonRepository: sl()),
  );

  // ML scoring — pure inference, no external deps
  sl.registerLazySingleton<MlRepository>(
    () => MlRepositoryImpl(),
  );

  // Visualization — orchestrates encoding, pattern, and ML
  sl.registerLazySingleton<AnalysisRepository>(
    () => AnalysisRepositoryImpl(
      encodingRepository: sl(),
      patternRepository: sl(),
      mlRepository: sl(),
    ),
  );

  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  USE CASES                                                      ║
  // ╚══════════════════════════════════════════════════════════════════╝
  sl.registerLazySingleton(() => FetchCandleData(sl()));
  sl.registerLazySingleton(() => EncodeCandles(sl()));
  sl.registerLazySingleton(() => DetectAllPatterns(sl()));
  sl.registerLazySingleton(() => ScoreMatches(sl()));
  sl.registerLazySingleton(() => RunFullAnalysis(sl()));
  sl.registerLazySingleton(() => InspectAutomaton(sl()));

  // ╔══════════════════════════════════════════════════════════════════╗
  // ║  BLoCs  (registered as factory — new instance per screen)       ║
  // ╚══════════════════════════════════════════════════════════════════╝
  sl.registerFactory(
    () => EncodingBloc(
      fetchCandleData: sl(),
      encodeCandles: sl(),
    ),
  );

  sl.registerFactory(
    () => AnalysisBloc(runFullAnalysis: sl()),
  );

  sl.registerFactory(
    () => AutomatonBloc(inspectAutomaton: sl()),
  );
}
