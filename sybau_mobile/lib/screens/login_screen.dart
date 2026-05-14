import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'app_shell_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

enum AuthState { landing, login, register }

class _LoginScreenState extends State<LoginScreen> {
  AuthState _authState = AuthState.landing;
  bool _showPassword = false;
  bool _isLoading = false;

  final _usernameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> _handleSubmit() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final username = _usernameController.text.trim();

    if (email.isEmpty || password.isEmpty) return;
    if (_authState == AuthState.register && username.isEmpty) return;

    setState(() => _isLoading = true);
    try {
      if (_authState == AuthState.login) {
        await ApiService.login(email, password);
      } else if (_authState == AuthState.register) {
        await ApiService.register(username, email, password);
        await ApiService.login(email, password);
      }

      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(builder: (_) => const AppShellScreen()),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Error: ${e.toString()}')));
      }
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final bgBase = const Color(0xFF050714);
    final bgTopGrad = const Color(0xFF1a237e);
    final bgBotGrad = const Color(0xFF311b92);

    final inputBgColor = const Color(0xFF161A30);
    final placeholderColor = const Color(0xFF8B92A5);

    final btnGradientPrimary = const Color(0xFFFF2D75);
    final btnGradientSecondary = const Color(0xFFFF5E9A);

    final textColor = Colors.white;

    final isLanding = _authState == AuthState.landing;

    return Scaffold(
      backgroundColor: bgBase,
      body: Container(
        decoration: BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [
              bgTopGrad.withOpacity(0.6),
              bgBase,
              bgBotGrad.withOpacity(0.6),
            ],
            stops: const [0.0, 0.5, 1.0],
          ),
        ),
        child: SafeArea(
          child: Column(
            children: [
              const SizedBox(height: 48),
              const SizedBox(height: 16),
              Image.asset(
                'assets/Sybau_logo_short.png',
                height: 90,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.fitness_center,
                    size: 90,
                    color: Colors.white,
                  );
                },
              ),
              const SizedBox(height: 8),
              Text(
                'SYBAU',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.bold,
                  letterSpacing: 2,
                  color: textColor,
                ),
              ),

              SizedBox(height: isLanding ? 56 : 32),

              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    padding: const EdgeInsets.symmetric(horizontal: 24.0),
                    child: AnimatedSwitcher(
                      duration: const Duration(milliseconds: 250),
                      reverseDuration: Duration.zero,
                      switchInCurve: Curves.easeOut,
                      switchOutCurve: Curves.easeIn,
                      layoutBuilder: (currentChild, previousChildren) {
                        return Stack(
                          alignment: Alignment.center,
                          children: <Widget>[
                            ...previousChildren,
                            if (currentChild != null) currentChild,
                          ],
                        );
                      },
                      transitionBuilder: (child, animation) {
                        return FadeTransition(
                          opacity: animation,
                          child: SlideTransition(
                            position: Tween<Offset>(
                              begin: const Offset(0.0, 0.03),
                              end: Offset.zero,
                            ).animate(animation),
                            child: child,
                          ),
                        );
                      },
                      child: Column(
                        key: ValueKey<AuthState>(_authState),
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          if (isLanding) ...[
                            Text(
                              'Welcome Back',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                fontSize: 28,
                                fontWeight: FontWeight.w600,
                                color: textColor,
                              ),
                            ),
                            const SizedBox(height: 40),

                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                border: Border.all(
                                  color: btnGradientPrimary,
                                  width: 1.5,
                                ),
                              ),
                              child: ElevatedButton(
                                onPressed: () => setState(
                                  () => _authState = AuthState.login,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'SIGN IN',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: LinearGradient(
                                  colors: [
                                    btnGradientPrimary,
                                    btnGradientSecondary,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: btnGradientPrimary.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: () => setState(
                                  () => _authState = AuthState.register,
                                ),
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: const Text(
                                  'SIGN UP',
                                  style: TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                    color: Colors.white,
                                    letterSpacing: 1,
                                  ),
                                ),
                              ),
                            ),
                          ] else ...[
                            if (_authState == AuthState.register) ...[
                              _buildLabeledInput(
                                label: 'Username',
                                textColor: textColor,
                                child: Container(
                                  decoration: _inputShadowDecoration(),
                                  child: TextField(
                                    controller: _usernameController,
                                    style: TextStyle(
                                      color: textColor,
                                      fontSize: 16,
                                    ),
                                    decoration: _inputDecoration(
                                      'johndoe',
                                      inputBgColor,
                                      placeholderColor,
                                    ),
                                  ),
                                ),
                              ),
                              const SizedBox(height: 16),
                            ],

                            _buildLabeledInput(
                              label: 'Email',
                              textColor: textColor,
                              child: Container(
                                decoration: _inputShadowDecoration(),
                                child: TextField(
                                  controller: _emailController,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                  ),
                                  keyboardType: TextInputType.emailAddress,
                                  decoration: _inputDecoration(
                                    'example01@gmail.com',
                                    inputBgColor,
                                    placeholderColor,
                                  ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 16),

                            _buildLabeledInput(
                              label: 'Password',
                              textColor: textColor,
                              child: Container(
                                decoration: _inputShadowDecoration(),
                                child: TextField(
                                  controller: _passwordController,
                                  style: TextStyle(
                                    color: textColor,
                                    fontSize: 16,
                                  ),
                                  obscureText: !_showPassword,
                                  decoration:
                                      _inputDecoration(
                                        'strongpassword123',
                                        inputBgColor,
                                        placeholderColor,
                                      ).copyWith(
                                        suffixIcon: IconButton(
                                          icon: Icon(
                                            _showPassword
                                                ? Icons.visibility_off
                                                : Icons.visibility,
                                            color: Colors.white54,
                                            size: 20,
                                          ),
                                          onPressed: () => setState(
                                            () =>
                                                _showPassword = !_showPassword,
                                          ),
                                        ),
                                      ),
                                ),
                              ),
                            ),
                            const SizedBox(height: 32),

                            Container(
                              decoration: BoxDecoration(
                                borderRadius: BorderRadius.circular(30),
                                gradient: LinearGradient(
                                  colors: [
                                    btnGradientPrimary,
                                    btnGradientSecondary,
                                  ],
                                ),
                                boxShadow: [
                                  BoxShadow(
                                    color: btnGradientPrimary.withOpacity(0.3),
                                    blurRadius: 15,
                                    offset: const Offset(0, 8),
                                  ),
                                ],
                              ),
                              child: ElevatedButton(
                                onPressed: _isLoading ? null : _handleSubmit,
                                style: ElevatedButton.styleFrom(
                                  backgroundColor: Colors.transparent,
                                  shadowColor: Colors.transparent,
                                  padding: const EdgeInsets.symmetric(
                                    vertical: 18,
                                  ),
                                  shape: RoundedRectangleBorder(
                                    borderRadius: BorderRadius.circular(30),
                                  ),
                                ),
                                child: _isLoading
                                    ? const SizedBox(
                                        height: 24,
                                        width: 24,
                                        child: CircularProgressIndicator(
                                          color: Colors.white,
                                          strokeWidth: 2.5,
                                        ),
                                      )
                                    : Text(
                                        _authState == AuthState.login
                                            ? 'SIGN IN'
                                            : 'CREATE ACCOUNT',
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                          color: Colors.white,
                                          letterSpacing: 1,
                                        ),
                                      ),
                              ),
                            ),
                            const SizedBox(height: 24),
                            TextButton(
                              onPressed: () {
                                setState(() {
                                  _authState = AuthState.landing;
                                  _usernameController.clear();
                                  _emailController.clear();
                                  _passwordController.clear();
                                });
                              },
                              style: TextButton.styleFrom(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 16,
                                ),
                              ),
                              child: const Text(
                                'BACK TO START',
                                style: TextStyle(
                                  color: Colors.white70,
                                  fontSize: 14,
                                  fontWeight: FontWeight.w600,
                                  letterSpacing: 1,
                                ),
                              ),
                            ),
                          ],
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  BoxDecoration _inputShadowDecoration() {
    return BoxDecoration(
      borderRadius: BorderRadius.circular(16),
      boxShadow: [
        BoxShadow(
          color: Colors.black.withOpacity(0.25),
          blurRadius: 10,
          offset: const Offset(0, 4),
        ),
      ],
    );
  }

  Widget _buildLabeledInput({
    required String label,
    required Color textColor,
    required Widget child,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 6, bottom: 8),
          child: Text(
            label,
            style: TextStyle(
              color: textColor.withOpacity(0.82),
              fontSize: 13,
              fontWeight: FontWeight.w600,
              letterSpacing: 0.4,
            ),
          ),
        ),
        child,
      ],
    );
  }

  InputDecoration _inputDecoration(
    String hint,
    Color bgColor,
    Color hintColor,
  ) {
    final focusColor = const Color(0xFFFF2D75);
    return InputDecoration(
      hintText: hint,
      hintStyle: TextStyle(color: hintColor, fontSize: 16),
      filled: true,
      fillColor: bgColor,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.transparent, width: 0),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.transparent, width: 0),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: BorderSide(color: focusColor.withOpacity(0.8), width: 1.5),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 20),
    );
  }
}
