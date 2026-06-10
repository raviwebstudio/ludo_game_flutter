import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:ludo_game/injection.dart';
import 'package:ludo_game/core/services/firebase_service.dart';
import 'package:ludo_game/core/services/auth_health_check.dart';
import 'package:ludo_game/core/services/auth_error_handler.dart';
import 'package:ludo_game/core/constants/colors.dart';
import 'package:ludo_game/core/constants/dimensions.dart';
import 'package:ludo_game/core/constants/text_styles.dart';
import 'package:ludo_game/shared/widgets/gradient_button.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _obscurePassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    // Validate service availability before email login
    if (!AuthHealthCheck.isFirebaseCoreReady ||
        !AuthHealthCheck.isFirebaseAuthReady ||
        !AuthHealthCheck.isFirestoreReady) {
      debugPrint('[Email Login Screen] Login aborted: Firebase services are not initialized.');
      _showErrorSnackBar('Firebase services are not initialized. Please try again.');
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('[Email Login Screen] Starting email login flow for ${_emailController.text.trim()}');

    try {
      final firebaseService = getIt<FirebaseService>();
      await firebaseService.signIn(
        _emailController.text.trim(),
        _passwordController.text,
      );
      debugPrint('[Navigation] Email login complete. AuthGate will transition to HomeScreen.');
    } catch (e) {
      debugPrint('[Email Login Screen] Email login FAILED: $e');
      if (mounted) {
        final friendlyMsg = AuthErrorHandler.getFriendlyErrorMessage(e);
        _showErrorSnackBar(friendlyMsg);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  Future<void> _signInWithGoogle() async {
    // Validate service availability before Google sign-in
    if (!AuthHealthCheck.isFirebaseCoreReady ||
        !AuthHealthCheck.isFirebaseAuthReady ||
        !AuthHealthCheck.isFirestoreReady) {
      debugPrint('[Google Sign-In Screen] Sign-In aborted: Firebase services are not initialized.');
      _showErrorSnackBar('Firebase services are not initialized. Please try again.');
      return;
    }
    if (!AuthHealthCheck.isGoogleSignInReady) {
      debugPrint('[Google Sign-In Screen] Sign-In aborted: Google Sign-In service check is not ready.');
      _showErrorSnackBar('Google Sign-In is not configured correctly.');
      return;
    }

    setState(() => _isLoading = true);
    debugPrint('[Google Sign-In Screen] Starting Google Sign-In flow');
    try {
      final firebaseService = getIt<FirebaseService>();
      final cred = await firebaseService.signInWithGoogle();
      if (cred == null) {
        debugPrint('[Google Sign-In Screen] Google Sign-In credential returned null (cancelled).');
        if (mounted) setState(() => _isLoading = false);
        return;
      }
      debugPrint('[Navigation] Google Sign-In complete. AuthGate will transition to HomeScreen.');
    } catch (e) {
      debugPrint('[Google Sign-In Screen] Google Sign-In FAILED: $e');
      if (mounted) {
        final friendlyMsg = AuthErrorHandler.getFriendlyErrorMessage(e);
        _showErrorSnackBar(friendlyMsg);
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  void _showErrorSnackBar(String message) {
    // Strip Firebase-specific prefix if present
    String cleanMessage = message;
    if (message.contains(']')) {
      cleanMessage = message.split(']').last.trim();
    }

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Row(
          children: [
            const Icon(Icons.error_outline, color: Colors.white),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                cleanMessage,
                style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
              ),
            ),
          ],
        ),
        backgroundColor: LudoColors.redToken,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        margin: const EdgeInsets.all(16),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        width: double.infinity,
        height: double.infinity,
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [LudoColors.darkNavyDark, LudoColors.darkNavy],
          ),
        ),
        child: SafeArea(
          child: Center(
            child: SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: LudoDimensions.spacing24),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    const SizedBox(height: 20),
                    // Game Logo
                    Container(
                      width: 100,
                      height: 100,
                      decoration: BoxDecoration(
                        color: LudoColors.mintGreen.withValues(alpha: 0.15),
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: LudoColors.mintGreen.withValues(alpha: 0.25),
                            blurRadius: 24,
                            spreadRadius: 4,
                          ),
                        ],
                      ),
                      child: const Icon(
                        Icons.casino,
                        color: LudoColors.mintGreen,
                        size: 50,
                      ),
                    ).animate().scale(duration: 600.ms, curve: Curves.elasticOut),

                    const SizedBox(height: 24),

                    Text(
                      'LUDO ELITE',
                      style: LudoTextStyles.displayMedium.copyWith(
                        fontSize: 32,
                        letterSpacing: 2,
                      ),
                    ).animate().fadeIn(delay: 200.ms),

                    Text(
                      'Sign in to challenge players worldwide',
                      style: LudoTextStyles.bodyMedium.copyWith(
                        color: LudoColors.textMedium,
                      ),
                    ).animate().fadeIn(delay: 300.ms),

                    const SizedBox(height: 40),

                    // Email Field
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      style: const TextStyle(color: LudoColors.textLight),
                      decoration: InputDecoration(
                        labelText: 'Email Address',
                        labelStyle: const TextStyle(color: LudoColors.textMedium),
                        prefixIcon: const Icon(Icons.email_outlined, color: LudoColors.textMedium),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: LudoColors.brightBlue, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: LudoColors.redToken),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: LudoColors.redToken, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                      ),
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Please enter your email';
                        }
                        if (!RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$').hasMatch(value.trim())) {
                          return 'Please enter a valid email address';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 400.ms).slideY(begin: 0.1),

                    const SizedBox(height: 20),

                    // Password Field
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscurePassword,
                      style: const TextStyle(color: LudoColors.textLight),
                      decoration: InputDecoration(
                        labelText: 'Password',
                        labelStyle: const TextStyle(color: LudoColors.textMedium),
                        prefixIcon: const Icon(Icons.lock_outlined, color: LudoColors.textMedium),
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                            color: LudoColors.textMedium,
                          ),
                          onPressed: () => setState(() => _obscurePassword = !_obscurePassword),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: BorderSide(color: Colors.white.withValues(alpha: 0.1)),
                        ),
                        focusedBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: LudoColors.brightBlue, width: 2),
                        ),
                        errorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: LudoColors.redToken),
                        ),
                        focusedErrorBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(16),
                          borderSide: const BorderSide(color: LudoColors.redToken, width: 2),
                        ),
                        filled: true,
                        fillColor: Colors.white.withValues(alpha: 0.05),
                      ),
                      validator: (value) {
                        if (value == null || value.isEmpty) {
                          return 'Please enter your password';
                        }
                        if (value.length < 6) {
                          return 'Password must be at least 6 characters';
                        }
                        return null;
                      },
                    ).animate().fadeIn(delay: 500.ms).slideY(begin: 0.1),

                    const SizedBox(height: 32),

                    // Submit Button
                    GradientButton(
                      label: 'SIGN IN',
                      isLoading: _isLoading,
                      onPressed: _submit,
                      colors: const [LudoColors.brightBlue, LudoColors.purple],
                    ).animate().fadeIn(delay: 600.ms),

                    const SizedBox(height: 16),

                    // Google Sign-In Button
                    OutlinedButton(
                      onPressed: _isLoading ? null : _signInWithGoogle,
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
                        minimumSize: const Size(double.infinity, 50),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        side: BorderSide(color: Colors.white.withValues(alpha: 0.2)),
                      ),
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Container(
                            width: 20,
                            height: 20,
                            margin: const EdgeInsets.only(right: 12),
                            child: CustomPaint(
                              painter: GoogleGLogoPainter(),
                            ),
                          ),
                          Text(
                            'Sign In with Google',
                            style: LudoTextStyles.bodyLarge.copyWith(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                            ),
                          ),
                        ],
                      ),
                    ).animate().fadeIn(delay: 650.ms),

                    const SizedBox(height: 24),

                    // Sign Up transition link
                    Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        const Text(
                          "Don't have an account? ",
                          style: TextStyle(color: LudoColors.textMedium),
                        ),
                        GestureDetector(
                          onTap: () {
                            Navigator.pushNamed(context, '/auth/signup');
                          },
                          child: const Text(
                            'Sign Up',
                            style: TextStyle(
                              color: LudoColors.mintGreen,
                              fontWeight: FontWeight.bold,
                              decoration: TextDecoration.underline,
                            ),
                          ),
                        ),
                      ],
                    ).animate().fadeIn(delay: 700.ms),
                    const SizedBox(height: 20),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class GoogleGLogoPainter extends CustomPainter {
  @override
  void paint(Canvas canvas, Size size) {
    final double w = size.width;
    final double r = w / 2;
    final center = Offset(r, r);
    final double strokeWidth = w * 0.22;

    final paint = Paint()
      ..style = PaintingStyle.stroke
      ..strokeWidth = strokeWidth
      ..strokeCap = StrokeCap.square;

    final double arcRadius = r - strokeWidth / 2;

    // Red arc (top)
    paint.color = const Color(0xFFEA4335);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcRadius),
      -1.65 * 3.14159 / 2,
      -0.95 * 3.14159 / 2,
      false,
      paint,
    );

    // Yellow arc (left)
    paint.color = const Color(0xFFFBBC05);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcRadius),
      1.75 * 3.14159 / 2,
      -0.75 * 3.14159 / 2,
      false,
      paint,
    );

    // Green arc (bottom)
    paint.color = const Color(0xFF34A853);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcRadius),
      0.25 * 3.14159 / 2,
      -1.0 * 3.14159 / 2,
      false,
      paint,
    );

    // Blue arc (right)
    paint.color = const Color(0xFF4285F4);
    canvas.drawArc(
      Rect.fromCircle(center: center, radius: arcRadius),
      -0.75 * 3.14159 / 2,
      0.75 * 3.14159 / 2,
      false,
      paint,
    );

    // Draw horizontal bar of the 'G'
    final barPaint = Paint()
      ..color = const Color(0xFF4285F4)
      ..style = PaintingStyle.fill;
    canvas.drawRect(
      Rect.fromLTWH(r, r - strokeWidth / 2, r, strokeWidth),
      barPaint,
    );
  }

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}

