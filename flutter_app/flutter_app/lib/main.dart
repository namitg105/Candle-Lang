import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/visualization/presentation/bloc/analysis_bloc.dart';
import 'features/visualization/presentation/pages/home_page.dart';
import 'injection_container.dart' as di;

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // Wire up all dependencies via GetIt.
  await di.init();

  runApp(const CandleLangApp());
}

/// Root widget for the CandleLang Flutter application.
///
/// Provides the [AnalysisBloc] at the top of the widget tree so every
/// child screen can read from and send events to it.
class CandleLangApp extends StatelessWidget {
  const CandleLangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return BlocProvider(
      create: (_) => di.sl<AnalysisBloc>(),
      child: MaterialApp(
        title: 'CandleLang',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const HomePage(),
      ),
    );
  }
}
