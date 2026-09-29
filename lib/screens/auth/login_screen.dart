import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _formKey = GlobalKey<FormState>();

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String? _validateEmail(String? value) {
    final v = value?.trim() ?? '';
    if (v.isEmpty) return 'Please enter your email address';
    if (!v.contains('@'))
      return 'Please enter a valid email address (e.g., name@example.com)';
    if (!v.contains('.'))
      return 'Please enter a valid email address with a domain (e.g., name@example.com)';
    return null;
  }

  String? _validatePassword(String? value) {
    final v = value ?? '';
    if (v.isEmpty) return 'Please enter your password';
    if (v.length < 6) return 'Password must be at least 6 characters long';
    return null;
  }

  String _getUserFriendlyErrorMessage(dynamic error) {
    final errorStr = error.toString().toLowerCase();
    if (errorStr.contains('user-not-found') ||
        errorStr.contains('invalid-email')) {
      return 'No account found with this email address. Please check your email or register a new account.';
    }
    if (errorStr.contains('wrong-password') ||
        errorStr.contains('invalid-credential')) {
      return 'Incorrect password. Please try again or use "Forgot password" to reset it.';
    }
    if (errorStr.contains('network')) {
      return 'Network error. Please check your internet connection and try again.';
    }
    if (errorStr.contains('too-many-requests')) {
      return 'Too many login attempts. Please wait a moment and try again.';
    }
    if (errorStr.contains('user-disabled')) {
      return 'This account has been disabled. Please contact support for assistance.';
    }
    if (errorStr.contains('permission-denied') ||
        errorStr.contains('firebase_firestore')) {
      return 'Signed in, but unable to load your profile. Please contact support if this continues.';
    }
    if (errorStr.contains('app check')) {
      return 'App Check blocked the request. Please verify Firebase App Check configuration.';
    }
    return 'Login failed: ${error.toString()}';
  }

  Future<void> _submit() async {
    final auth = context.read<AuthProvider>();
    final messenger = ScaffoldMessenger.of(context);

    if (!(_formKey.currentState?.validate() ?? false)) return;

    try {
      await auth.signInWithEmailPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );

      if (auth.role == null) {
        messenger.showSnackBar(
          const SnackBar(
              content: Text('Role not found. Defaulting to customer access.')),
        );
      }

      final effectiveRole = auth.role ?? UserRole.customer;

      final nextRoute = switch (effectiveRole) {
        UserRole.admin => AppRouter.adminDashboardRoute,
        UserRole.customer => AppRouter.customerDashboardRoute,
        UserRole.staff => AppRouter.staffDashboardRoute,
        UserRole.veterinarian => AppRouter.veterinarianDashboardRoute,
      };

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed(nextRoute);
    } on Exception catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_getUserFriendlyErrorMessage(e)),
        ),
      );
    } catch (e) {
      messenger.showSnackBar(
        SnackBar(
          content: Text(_getUserFriendlyErrorMessage(e)),
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final auth = context.watch<AuthProvider>();

    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    TweenAnimationBuilder<double>(
                      tween: Tween(begin: 0.0, end: 1.0),
                      duration: const Duration(milliseconds: 700),
                      curve: Curves.easeOutBack,
                      builder: (context, value, child) {
                        return Transform.scale(
                          scale: 0.85 + (0.15 * value),
                          child: Opacity(opacity: value, child: child),
                        );
                      },
                      child: Image.asset(
                        'assets/logo.png',
                        height: 110,
                        fit: BoxFit.contain,
                      ),
                    ),
                    const SizedBox(height: 28),
                    _AnimatedField(
                      delay: const Duration(milliseconds: 100),
                      child: TextFormField(
                        controller: _emailController,
                        keyboardType: TextInputType.emailAddress,
                        autofillHints: const [AutofillHints.email],
                        decoration: const InputDecoration(
                          labelText: 'Email',
                          prefixIcon: Icon(Icons.email_outlined),
                        ),
                        validator: _validateEmail,
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AnimatedField(
                      delay: const Duration(milliseconds: 200),
                      child: TextFormField(
                        controller: _passwordController,
                        obscureText: _obscure,
                        autofillHints: const [AutofillHints.password],
                        decoration: InputDecoration(
                          labelText: 'Password',
                          prefixIcon: const Icon(Icons.lock_outline),
                          suffixIcon: IconButton(
                            onPressed: () =>
                                setState(() => _obscure = !_obscure),
                            icon: Icon(_obscure
                                ? Icons.visibility_off
                                : Icons.visibility),
                          ),
                        ),
                        validator: _validatePassword,
                      ),
                    ),
                    const SizedBox(height: 20),
                    _AnimatedField(
                      delay: const Duration(milliseconds: 300),
                      child: FilledButton(
                        onPressed: auth.isLoading ? null : _submit,
                        style: FilledButton.styleFrom(
                          padding: const EdgeInsets.symmetric(vertical: 14),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12),
                          ),
                        ),
                        child: auth.isLoading
                            ? const Row(
                                mainAxisAlignment: MainAxisAlignment.center,
                                children: [
                                  SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2.2,
                                      valueColor: AlwaysStoppedAnimation<Color>(
                                          Colors.white),
                                    ),
                                  ),
                                  SizedBox(width: 12),
                                  Text('Signing in...'),
                                ],
                              )
                            : const Text('Sign in',
                                style: TextStyle(fontSize: 16)),
                      ),
                    ),
                    const SizedBox(height: 14),
                    _AnimatedField(
                      delay: const Duration(milliseconds: 400),
                      child: TextButton(
                        onPressed: auth.isLoading
                            ? null
                            : () => Navigator.of(context)
                                .pushNamed(AppRouter.forgotPasswordRoute),
                        child: const Text('Forgot password?'),
                      ),
                    ),
                    const SizedBox(height: 6),
                    _AnimatedField(
                      delay: const Duration(milliseconds: 500),
                      child: TextButton(
                        onPressed: auth.isLoading
                            ? null
                            : () => Navigator.of(context)
                                .pushNamed(AppRouter.registerRoute),
                        child: const Text("Don't have an account? Register"),
                      ),
                    ),
                    if (auth.errorMessage != null) ...[
                      const SizedBox(height: 14),
                      _AnimatedField(
                        delay: const Duration(milliseconds: 50),
                        child: Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Theme.of(context).colorScheme.errorContainer,
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: Row(
                            children: [
                              Icon(Icons.error_outline_rounded,
                                  color: Theme.of(context).colorScheme.error),
                              const SizedBox(width: 10),
                              Expanded(
                                child: Text(
                                  auth.errorMessage!,
                                  style: TextStyle(
                                      color:
                                          Theme.of(context).colorScheme.error),
                                ),
                              ),
                            ],
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
      ),
    );
  }
}

class _AnimatedField extends StatelessWidget {
  final Duration delay;
  final Widget child;

  const _AnimatedField({required this.delay, required this.child});

  @override
  Widget build(BuildContext context) {
    return TweenAnimationBuilder<double>(
      tween: Tween(begin: 0.0, end: 1.0),
      duration: const Duration(milliseconds: 650),
      curve: Curves.easeOutCubic,
      builder: (context, value, child) {
        return Opacity(
          opacity: value,
          child: Transform.translate(
            offset: Offset(0, 18 * (1 - value)),
            child: child,
          ),
        );
      },
      child: child,
    );
  }
}
