import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';

import 'core/theme/app_theme.dart';
import 'features/automaton/presentation/bloc/automaton_bloc.dart';
import 'features/encoding/presentation/bloc/encoding_bloc.dart';
import 'features/visualization/presentation/bloc/analysis_bloc.dart';
import 'injection_container.dart' as di;
import 'main_navigation_shell.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await di.init();
  runApp(const CandleLangApp());
}

/// Root widget for CandleLang application.
class CandleLangApp extends StatelessWidget {
  const CandleLangApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MultiBlocProvider(
      providers: [
        BlocProvider(create: (_) => di.sl<AnalysisBloc>()),
        BlocProvider(create: (_) => di.sl<AutomatonBloc>()),
        BlocProvider(create: (_) => di.sl<EncodingBloc>()),
      ],
      child: MaterialApp(
        title: 'CandleLang',
        theme: AppTheme.darkTheme,
        debugShowCheckedModeBanner: false,
        home: const MainNavigationShell(),
      ),
    );
  }
}
