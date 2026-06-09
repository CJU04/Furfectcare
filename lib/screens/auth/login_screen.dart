import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../providers/auth_provider.dart';
import '../../routes/app_router.dart';
import '../../widgets/app_loading_indicator.dart';

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
    if (!v.contains('@')) return 'Please enter a valid email address (e.g., name@example.com)';
    if (!v.contains('.')) return 'Please enter a valid email address with a domain (e.g., name@example.com)';
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
    if (errorStr.contains('user-not-found') || errorStr.contains('invalid-email')) {
      return 'No account found with this email address. Please check your email or register a new account.';
    }
    if (errorStr.contains('wrong-password') || errorStr.contains('invalid-credential')) {
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
    return 'Login failed. Please check your email and password and try again.';
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
          const SnackBar(content: Text('Role not found. Please contact admin.')),
        );
        return;
      }

      // Redirect based on role.
      final nextRoute = switch (auth.role) {
        UserRole.admin => AppRouter.adminDashboardRoute,
        UserRole.customer => AppRouter.customerDashboardRoute,
        UserRole.staff => AppRouter.staffDashboardRoute,
        UserRole.veterinarian => AppRouter.veterinarianDashboardRoute,
        null => AppRouter.splashRoute,
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
            padding: const EdgeInsets.all(16),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 420),
              child: Form(

                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Image.asset(
                      'assets/logo.png',
                      height: 120,
                      fit: BoxFit.contain,
                    ),
                    const SizedBox(height: 24),
                    TextFormField(
                      controller: _emailController,
                      keyboardType: TextInputType.emailAddress,
                      autofillHints: const [AutofillHints.email],
                      decoration: const InputDecoration(
                        labelText: 'Email',
                        prefixIcon: Icon(Icons.email_outlined),
                      ),
                      validator: _validateEmail,
                    ),
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _passwordController,
                      obscureText: _obscure,
                      autofillHints: const [AutofillHints.password],
                      decoration: InputDecoration(
                        labelText: 'Password',
                        prefixIcon: const Icon(Icons.lock_outline),
                        suffixIcon: IconButton(
                          onPressed: () => setState(() => _obscure = !_obscure),
                          icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility),
                        ),
                      ),
                      validator: _validatePassword,
                    ),
                    const SizedBox(height: 16),
                    FilledButton(
                      onPressed: auth.isLoading ? null : _submit,
                      child: auth.isLoading
                          ? const Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                AppLoadingIndicator(),
                                SizedBox(width: 10),
                                Text('Signing in...'),
                              ],
                            )
                          : const Text('Sign in'),
                    ),
                    const SizedBox(height: 12),
                    TextButton(
                      onPressed: auth.isLoading
                          ? null
                          : () => Navigator.of(context).pushNamed(AppRouter.forgotPasswordRoute),
                      child: const Text('Forgot password?'),
                    ),

                    const SizedBox(height: 8),
                    TextButton(
                      onPressed: auth.isLoading
                          ? null
                          : () => Navigator.of(context).pushNamed(AppRouter.registerRoute),
                      child: const Text("Don't have an account? Register"),
                    ),

                    if (auth.errorMessage != null) ...[

                      const SizedBox(height: 12),
                      Text(
                        'Login failed. Please check your email and password.',
                        style: TextStyle(color: Theme.of(context).colorScheme.error),
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

