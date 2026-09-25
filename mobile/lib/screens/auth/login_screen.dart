import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import '../../core/services/auth_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isLoading = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _handleLogin() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signInWithEmailAndPassword(
        _emailController.text.trim(),
        _passwordController.text,
      );

      final prefs = await SharedPreferences.getInstance();
      final hasOnboarded = prefs.getBool('has_onboarded') ?? false;

      if (!mounted) return;
      if (hasOnboarded) {
        context.go('/dashboard');
      } else {
        context.go('/onboarding');
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString().replaceAll('Exception: ', '');
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: const Color(0xFFFAF7F2), // Warm cream
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Text(
                  'FurrMind',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.fraunces(
                    fontSize: 40,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF3D3229),
                  ),
                ),
                const SizedBox(height: 8),
                Text(
                  'Welcome back to your safe space',
                  textAlign: TextAlign.center,
                  style: GoogleFonts.nunito(
                    fontSize: 16,
                    color: const Color(0xFF6B5D4F),
                  ),
                ),
                const SizedBox(height: 48),
                if (_errorMessage != null)
                  Container(
                    padding: const EdgeInsets.all(12),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.red.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _errorMessage!,
                      style: GoogleFonts.nunito(color: Colors.red.shade800),
                    ),
                  ),
                TextField(
                  controller: _emailController,
                  keyboardType: TextInputType.emailAddress,
                  style: GoogleFonts.nunito(color: const Color(0xFF3D3229)),
                  decoration: InputDecoration(
                    hintText: 'Email address',
                    hintStyle: GoogleFonts.nunito(color: const Color(0xFF9B8B7A)),
                    filled: true,
                    fillColor: const Color(0xFFF2EDE4),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 16),
                TextField(
                  controller: _passwordController,
                  obscureText: true,
                  style: GoogleFonts.nunito(color: const Color(0xFF3D3229)),
                  decoration: InputDecoration(
                    hintText: 'Password',
                    hintStyle: GoogleFonts.nunito(color: const Color(0xFF9B8B7A)),
                    filled: true,
                    fillColor: const Color(0xFFF2EDE4),
                    contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(12),
                      borderSide: BorderSide.none,
                    ),
                  ),
                ),
                const SizedBox(height: 32),
                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: _isLoading ? null : _handleLogin,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: const Color(0xFF7C9A7E),
                      foregroundColor: const Color(0xFFFAF7F2),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                      textStyle: GoogleFonts.nunito(
                        fontSize: 16,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    child: _isLoading
                        ? const SizedBox(
                            width: 24,
                            height: 24,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Text('Log In'),
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  height: 52,
                  child: OutlinedButton.icon(
                    onPressed: _isLoading ? null : () async {
                      setState(() {
                        _isLoading = true;
                        _errorMessage = null;
                      });
                      try {
                        final authService = ref.read(authServiceProvider);
                        final user = await authService.signInWithGoogle();
                        if (user != null) {
                          final prefs = await SharedPreferences.getInstance();
                          final hasOnboarded = prefs.getBool('has_onboarded') ?? false;
                          if (!context.mounted) return;
                          if (hasOnboarded) {
                            context.go('/dashboard');
                          } else {
                            context.go('/onboarding');
                          }
                        }
                      } catch (e) {
                        if (context.mounted) {
                          setState(() {
                            _errorMessage = e.toString().replaceAll('Exception: ', '');
                          });
                        }
                      } finally {
                        if (mounted) {
                          setState(() {
                            _isLoading = false;
                          });
                        }
                      }
                    },
                    icon: Image.asset('assets/images/google_logo.png', width: 24, height: 24),
                    label: Text('Sign in with Google', style: GoogleFonts.nunito(fontSize: 16, fontWeight: FontWeight.bold, color: const Color(0xFF3D3229))),
                    style: OutlinedButton.styleFrom(
                      backgroundColor: Colors.white,
                      side: const BorderSide(color: Color(0xFFD4C8B8)),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      "Don't have an account? ",
                      style: GoogleFonts.nunito(color: const Color(0xFF6B5D4F)),
                    ),
                    GestureDetector(
                      onTap: () => context.push('/register'),
                      child: Text(
                        "Sign Up",
                        style: GoogleFonts.nunito(
                          color: const Color(0xFF7C9A7E),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                )
              ],
            ),
          ),
        ),
      ),
    );
  }
}
