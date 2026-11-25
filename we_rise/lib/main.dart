import 'dart:async';
import 'dart:ui';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'core/l10n/app_localizations.dart';
import 'core/router/app_router.dart';
import 'core/theme/app_theme.dart';
import 'features/complaints/data/providers.dart';

// ignore: avoid_void_async
void main() {
  // Catch all uncaught errors — both Flutter framework errors and Dart zone errors —
  // and show them on-screen so the user can read and copy them without ADB.
  runZonedGuarded(
    _startApp,
    (error, stack) => _showFallback(error, stack),
  );
}

Future<void> _startApp() async {
  // Must be first; required before any platform channel calls.
  WidgetsFlutterBinding.ensureInitialized();

  // Capture Flutter framework errors (widget build errors, etc.) and show fallback.
  FlutterError.onError = (details) {
    FlutterError.presentError(details);
    _showFallback(details.exception, details.stack ?? StackTrace.current);
  };

  // Capture platform dispatcher errors (async gaps not in a zone).
  PlatformDispatcher.instance.onError = (error, stack) {
    _showFallback(error, stack);
    return true; // mark as handled
  };

  // ── UI chrome ──────────────────────────────────────────────────────────────
  await SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp,
    DeviceOrientation.portraitDown,
  ]);
  SystemChrome.setSystemUIOverlayStyle(const SystemUiOverlayStyle(
    statusBarColor: Colors.transparent,
    statusBarIconBrightness: Brightness.dark,
  ));

  // ── Hive (offline queue — always needed, no network) ──────────────────────
  await Hive.initFlutter();

  // ── Supabase (ONLY when both keys are provided via --dart-define) ──────────
  // In demo mode (no keys) this block is completely skipped — no network call,
  // no Supabase.instance access at startup.
  if (kSupabaseUrl.isNotEmpty && kSupabaseAnonKey.isNotEmpty) {
    await Supabase.initialize(
      url: kSupabaseUrl,
      publishableKey: kSupabaseAnonKey, // named 'publishableKey' in supabase_flutter >=2.15
    );
  }

  runApp(
    const ProviderScope(
      child: WeRiseApp(),
    ),
  );
}

// ── Error Fallback ─────────────────────────────────────────────────────────
// If anything goes wrong before or during startup, show a minimal Material app
// that displays the full error message and stack trace on screen.
// No dependencies on any app code — this must always render.
void _showFallback(Object error, StackTrace stack) {
  final message = '$error\n\n$stack';
  // Avoid calling runApp twice if it already ran — only show fallback when
  // the main app hasn't launched yet.  We use a simple flag for that.
  _maybeRunFallback(message);
}

bool _fallbackLaunched = false;

void _maybeRunFallback(String message) {
  if (_fallbackLaunched) return;
  _fallbackLaunched = true;
  runApp(_ErrorApp(message: message));
}

class _ErrorApp extends StatelessWidget {
  const _ErrorApp({required this.message});
  final String message;

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'WE RISE — Startup Error',
      home: Scaffold(
        backgroundColor: const Color(0xFF1A1C1E),
        appBar: AppBar(
          backgroundColor: const Color(0xFFC62828),
          title: const Text(
            '⚠ WE RISE crashed at startup',
            style: TextStyle(color: Colors.white, fontSize: 16),
          ),
        ),
        body: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Text(
                'Copy this error and send it to the developer:',
                style: TextStyle(color: Colors.white70, fontSize: 13),
              ),
              const SizedBox(height: 8),
              Expanded(
                child: Container(
                  decoration: BoxDecoration(
                    color: const Color(0xFF2D2D2D),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: SingleChildScrollView(
                    child: SelectableText(
                      message,
                      style: const TextStyle(
                        color: Color(0xFFFF6B6B),
                        fontSize: 11,
                        fontFamily: 'monospace',
                        height: 1.4,
                      ),
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 12),
              ElevatedButton.icon(
                style: ElevatedButton.styleFrom(
                  backgroundColor: const Color(0xFF006D77),
                  foregroundColor: Colors.white,
                  minimumSize: const Size.fromHeight(48),
                ),
                onPressed: () async {
                  await Clipboard.setData(ClipboardData(text: message));
                },
                icon: const Icon(Icons.copy),
                label: const Text('Copy Error to Clipboard'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ── Main App ───────────────────────────────────────────────────────────────
class WeRiseApp extends ConsumerWidget {
  const WeRiseApp({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final router = ref.watch(appRouterProvider);
    final locale = ref.watch(localeProvider);

    return MaterialApp.router(
      title: 'WE RISE',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light(),
      darkTheme: AppTheme.dark(),
      themeMode: ThemeMode.system,
      routerConfig: router,
      locale: locale,
      localizationsDelegates: AppLocalizations.localizationsDelegates,
      supportedLocales: AppLocalizations.supportedLocales,
      builder: (context, child) {
        // Clamp font scaling so Tamil layout doesn't break on large-text accessibility sizes.
        return MediaQuery(
          data: MediaQuery.of(context).copyWith(
            textScaler: TextScaler.linear(
              MediaQuery.of(context).textScaler.scale(1.0).clamp(0.8, 1.3),
            ),
          ),
          child: child!,
        );
      },
    );
  }
}
