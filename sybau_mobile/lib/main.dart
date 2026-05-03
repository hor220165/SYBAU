import 'dart:async';

import 'package:flutter/material.dart';
import 'screens/login_screen.dart';
import 'screens/app_shell_screen.dart';
import 'services/api_service.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();
  unawaited(ApiService.initialize());
  runApp(const SybauApp());
}

class SybauApp extends StatelessWidget {
  const SybauApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Sybau',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.dark,
        textTheme: ThemeData.dark().textTheme,
        primaryTextTheme: ThemeData.dark().primaryTextTheme,
        scaffoldBackgroundColor: const Color(0xFF0f0c29),
        colorScheme: ColorScheme.fromSeed(
          brightness: Brightness.dark,
          seedColor: const Color(0xFF00ffff),
          background: const Color(0xFF0f0c29),
        ),
        useMaterial3: true,
      ),
      home: const AuthCheck(),
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
