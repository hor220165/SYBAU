import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'screens/login_screen.dart';
import 'screens/app_shell_screen.dart';
import 'services/api_service.dart';
import 'services/notification_service.dart';
import 'theme_controller.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await SybauThemeController.initialize();
  unawaited(ApiService.initialize());
  unawaited(NotificationService.initialize());
  unawaited(NotificationService.syncScheduledReminder());
  runApp(const SybauApp());
}

class SybauApp extends StatelessWidget {
  const SybauApp({super.key});

  @override
  Widget build(BuildContext context) {
    return ValueListenableBuilder<SybauThemeMode>(
      valueListenable: SybauThemeController.mode,
      builder: (context, mode, _) {
        final isLight = mode == SybauThemeMode.light;
        return MaterialApp(
          title: 'Sybau',
          debugShowCheckedModeBanner: false,
          locale: const Locale('de'),
          supportedLocales: const [Locale('de')],
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
          ],
          theme: ThemeData(
            brightness: isLight ? Brightness.light : Brightness.dark,
            textTheme: isLight
                ? ThemeData.light().textTheme
                : ThemeData.dark().textTheme,
            primaryTextTheme: isLight
                ? ThemeData.light().primaryTextTheme
                : ThemeData.dark().primaryTextTheme,
            scaffoldBackgroundColor: isLight
                ? const Color(0xFFF8FAFC)
                : const Color(0xFF0f0c29),
            colorScheme: ColorScheme.fromSeed(
              brightness: isLight ? Brightness.light : Brightness.dark,
              seedColor: const Color(0xFFEC4899),
              surface: isLight
                  ? const Color(0xFFFFFFFF)
                  : const Color(0xFF0f0c29),
            ),
            useMaterial3: true,
          ),
          home: const AuthCheck(),
        );
      },
    );
  }
}

class AuthCheck extends StatefulWidget {
  const AuthCheck({super.key});

  @override
  State<AuthCheck> createState() => _AuthCheckState();
}

class _AuthCheckState extends State<AuthCheck> {
  bool _isLoading = true;
  bool _isLoggedIn = false;

  @override
  void initState() {
    super.initState();
    _checkAuth();
  }

  Future<void> _checkAuth() async {
    final loggedIn = await ApiService.isLoggedIn();
    setState(() {
      _isLoggedIn = loggedIn;
      _isLoading = false;
    });
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }

    return _isLoggedIn ? const AppShellScreen() : const LoginScreen();
  }
}
