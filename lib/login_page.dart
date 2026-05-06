import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_sign_in/google_sign_in.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({super.key});

  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isLogin = true; // toggle between Login and Sign Up
  bool _isLoading = false;
  bool _obscurePassword = true;
  String? _errorMessage;

  // ── Palette ───────────────────────────────────────────────────────────────
  static const Color kBg = Color(0xFFF0F6FF);
  static const Color kCard = Color(0xFFFFFFFF);
  static const Color kAccent = Color(0xFF7BB8F5);
  static const Color kAccentSoft = Color(0xFFB8D8FC);
  static const Color kAccentDark = Color(0xFF4A90D9);
  static const Color kStar = Color(0xFFFFD166);
  static const Color kText = Color(0xFF1E3A5F);
  static const Color kSubtext = Color(0xFF7A9CC0);
  static const Color kError = Color(0xFFFF8FAB);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  // ── Auth methods ──────────────────────────────────────────────────────────

  Future<void> _handleEmailAuth() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      setState(() => _errorMessage = 'Please fill in all fields');
      return;
    }

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      if (_isLogin) {
        await FirebaseAuth.instance.signInWithEmailAndPassword(
          email: email,
          password: password,
        );
      } else {
        await FirebaseAuth.instance.createUserWithEmailAndPassword(
          email: email,
          password: password,
        );
      }
      // Auth state stream in main.dart handles navigation automatically
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleGoogleSignIn() async {
    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    try {
      final googleUser = await GoogleSignIn().signIn();
      if (googleUser == null) {
        // User cancelled the sign-in
        setState(() => _isLoading = false);
        return;
      }
      final googleAuth = await googleUser.authentication;
      final credential = GoogleAuthProvider.credential(
        accessToken: googleAuth.accessToken,
        idToken: googleAuth.idToken,
      );
      await FirebaseAuth.instance.signInWithCredential(credential);
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    } catch (e) {
      setState(() => _errorMessage = 'Google sign-in failed. Try again.');
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _handleForgotPassword() async {
    final email = _emailController.text.trim();
    if (email.isEmpty) {
      setState(() => _errorMessage = 'Enter your email above first');
      return;
    }
    try {
      await FirebaseAuth.instance.sendPasswordResetEmail(email: email);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            backgroundColor: kCard,
            behavior: SnackBarBehavior.floating,
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(14),
            ),
            content: Text(
              'Reset link sent to $email',
              style: const TextStyle(color: kText),
            ),
          ),
        );
      }
    } on FirebaseAuthException catch (e) {
      setState(() => _errorMessage = _friendlyError(e.code));
    }
  }

  // Converts Firebase error codes to friendly messages
  String _friendlyError(String code) {
    switch (code) {
      case 'user-not-found':
        return 'No account found with this email';
      case 'wrong-password':
        return 'Incorrect password';
      case 'email-already-in-use':
        return 'An account already exists with this email';
      case 'weak-password':
        return 'Password must be at least 6 characters';
      case 'invalid-email':
        return 'Please enter a valid email address';
      case 'too-many-requests':
        return 'Too many attempts. Try again later';
      default:
        return 'Something went wrong. Try again';
    }
  }

  // ── Build ─────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kBg,
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const SizedBox(height: 20),

                // ── Logo ───────────────────────────────────────────────────
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: kAccentSoft,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: kAccent.withOpacity(0.3),
                        blurRadius: 20,
                        offset: const Offset(0, 8),
                      ),
                    ],
                  ),
                  child: const Icon(Icons.star_rounded, color: kStar, size: 44),
                ),
                const SizedBox(height: 24),

                // ── Title ──────────────────────────────────────────────────
                Text(
                  _isLogin ? 'Welcome back' : 'Create account',
                  style: const TextStyle(
                    fontSize: 28,
                    fontWeight: FontWeight.bold,
                    color: kText,
                    letterSpacing: -0.5,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  _isLogin
                      ? 'Sign in to see your tasks'
                      : 'Start organising your day',
                  style: const TextStyle(fontSize: 14, color: kSubtext),
                ),

                const SizedBox(height: 36),

                // ── Card ───────────────────────────────────────────────────
                Container(
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: kCard,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: kAccent.withOpacity(0.08),
                        blurRadius: 20,
                        offset: const Offset(0, 6),
                      ),
                    ],
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // Email field
                      _label('Email'),
                      const SizedBox(height: 8),
                      _textField(
                        controller: _emailController,
                        hint: 'you@example.com',
                        icon: Icons.email_outlined,
                        keyboardType: TextInputType.emailAddress,
                      ),
                      const SizedBox(height: 16),

                      // Password field
                      _label('Password'),
                      const SizedBox(height: 8),
                      _textField(
                        controller: _passwordController,
                        hint: '••••••••',
                        icon: Icons.lock_outline_rounded,
                        obscure: _obscurePassword,
                        suffixIcon: IconButton(
                          icon: Icon(
                            _obscurePassword
                                ? Icons.visibility_outlined
                                : Icons.visibility_off_outlined,
                            color: kSubtext,
                            size: 20,
                          ),
                          onPressed: () => setState(
                            () => _obscurePassword = !_obscurePassword,
                          ),
                        ),
                        onSubmitted: (_) => _handleEmailAuth(),
                      ),

                      // Forgot password
                      if (_isLogin)
                        Align(
                          alignment: Alignment.centerRight,
                          child: TextButton(
                            onPressed: _handleForgotPassword,
                            style: TextButton.styleFrom(
                              padding: EdgeInsets.zero,
                            ),
                            child: const Text(
                              'Forgot password?',
                              style: TextStyle(
                                fontSize: 12,
                                color: kAccentDark,
                              ),
                            ),
                          ),
                        ),

                      // Error message
                      if (_errorMessage != null) ...[
                        const SizedBox(height: 8),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.symmetric(
                            horizontal: 14,
                            vertical: 10,
                          ),
                          decoration: BoxDecoration(
                            color: kError.withOpacity(0.1),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Text(
                            _errorMessage!,
                            style: const TextStyle(color: kError, fontSize: 13),
                          ),
                        ),
                      ],

                      const SizedBox(height: 20),

                      // Email auth button
                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _handleEmailAuth,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: kAccent,
                            foregroundColor: Colors.white,
                            elevation: 0,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    color: Colors.white,
                                    strokeWidth: 2,
                                  ),
                                )
                              : Text(
                                  _isLogin ? 'Sign In' : 'Create Account',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 16,
                                  ),
                                ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(color: kAccentSoft, thickness: 1),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              'or',
                              style: TextStyle(color: kSubtext, fontSize: 13),
                            ),
                          ),
                          Expanded(
                            child: Divider(color: kAccentSoft, thickness: 1),
                          ),
                        ],
                      ),

                      const SizedBox(height: 16),

                      // Google Sign-In button
                      SizedBox(
                        width: double.infinity,
                        child: OutlinedButton.icon(
                          onPressed: _isLoading ? null : _handleGoogleSignIn,
                          icon: Image.network(
                            'https://www.google.com/favicon.ico',
                            height: 20,
                            width: 20,
                            errorBuilder: (_, __, ___) => const Icon(
                              Icons.g_mobiledata_rounded,
                              color: kAccentDark,
                            ),
                          ),
                          label: const Text(
                            'Continue with Google',
                            style: TextStyle(
                              color: kText,
                              fontWeight: FontWeight.w600,
                              fontSize: 15,
                            ),
                          ),
                          style: OutlinedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 14),
                            side: const BorderSide(
                              color: Color(0xFFDDEAF8),
                              width: 1.5,
                            ),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(14),
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 24),

                // Toggle login / signup
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      _isLogin
                          ? "Don't have an account? "
                          : 'Already have an account? ',
                      style: const TextStyle(color: kSubtext, fontSize: 14),
                    ),
                    GestureDetector(
                      onTap: () => setState(() {
                        _isLogin = !_isLogin;
                        _errorMessage = null;
                      }),
                      child: Text(
                        _isLogin ? 'Sign Up' : 'Sign In',
                        style: const TextStyle(
                          color: kAccentDark,
                          fontSize: 14,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 20),
              ],
            ),
          ),
        ),
      ),
    );
  }

  // ── Helpers ───────────────────────────────────────────────────────────────

  Widget _label(String text) => Text(
    text,
    style: const TextStyle(
      fontSize: 13,
      fontWeight: FontWeight.w600,
      color: kText,
    ),
  );

  Widget _textField({
    required TextEditingController controller,
    required String hint,
    required IconData icon,
    bool obscure = false,
    Widget? suffixIcon,
    TextInputType? keyboardType,
    void Function(String)? onSubmitted,
  }) => TextField(
    controller: controller,
    obscureText: obscure,
    keyboardType: keyboardType,
    onSubmitted: onSubmitted,
    style: const TextStyle(color: kText),
    cursorColor: kAccent,
    decoration: InputDecoration(
      hintText: hint,
      hintStyle: const TextStyle(color: kSubtext),
      prefixIcon: Icon(icon, color: kAccent, size: 20),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: kBg,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: BorderSide.none,
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: kAccent, width: 2),
      ),
      contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
    ),
  );
}
