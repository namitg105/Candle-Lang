# CandleLang (Flutter app)

Pure-Dart Clean Architecture implementation of the CandleLang pipeline — see the
[project README](../README.md) at the repository root for the full write-up
(architecture, patterns implemented, and how the regex → NFA → DFA →
minimized-DFA engine works).

## Run the app

```bash
flutter pub get
flutter test
flutter run -d chrome
```

The API key is already configured inside the Flutter source. The app fetches
the latest 120 one-minute AAPL candles directly from Twelve Data. If the live
request fails, it falls back to the bundled CSV data so the demonstration can
still run.

Use `flutter run -d windows` instead of the final command if you want a
Windows desktop app instead of the browser.
