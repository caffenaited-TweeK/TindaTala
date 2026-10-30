import 'package:flutter/material.dart';

import 'app.dart';
import 'theme.dart';
import 'widgets/common_widgets.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const TindaTalaApp());
}

class TindaTalaApp extends StatefulWidget {
  const TindaTalaApp({super.key, this.store});

  final AppStore? store;

  @override
  State<TindaTalaApp> createState() => _TindaTalaAppState();
}

class _TindaTalaAppState extends State<TindaTalaApp> {
  late final AppStore _store = widget.store ?? AppStore();

  @override
  void initState() {
    super.initState();
    _store.initialize();
  }

  @override
  void dispose() {
    if (widget.store == null) _store.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'TindaTala',
      debugShowCheckedModeBanner: false,
      theme: buildTindaTheme(),
      home: AnimatedBuilder(
        animation: _store,
        builder: (context, _) {
          if (_store.startupError case final error?) {
            return _StartupErrorScreen(
              message: error.toString(),
              onRetry: _store.initialize,
            );
          }
          if (!_store.isReady) return const SplashScreen();
          if (_store.isAuthenticated) {
            return AppShell(store: _store);
          }
          return LoginScreen(store: _store);
        },
      ),
    );
  }
}

class _StartupErrorScreen extends StatelessWidget {
  const _StartupErrorScreen({required this.message, required this.onRetry});

  final String message;
  final Future<void> Function() onRetry;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                const TindaLogo(size: 112),
                const SizedBox(height: 18),
                Text(
                  'Your saved store data needs attention',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 10),
                Text(message, textAlign: TextAlign.center),
                const SizedBox(height: 18),
                FilledButton.icon(
                  onPressed: onRetry,
                  icon: const Icon(Icons.refresh),
                  label: const Text('Try again'),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
