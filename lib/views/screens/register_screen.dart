import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:vetcare_connect/providers/auth_provider.dart';
import 'package:cloud_functions/cloud_functions.dart';
import 'package:vetcare_connect/config/admin_config.dart';
import 'package:vetcare_connect/utils/app_validators.dart';

class RegisterScreen extends StatefulWidget {
  const RegisterScreen({super.key});

  @override
  State<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends State<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _passwordController = TextEditingController();
  final _fullnameController = TextEditingController();
  final _contactNumberController = TextEditingController();
  final _emailController = TextEditingController();
  final _addressController = TextEditingController();
  UserRole _selectedRole = UserRole.customer;
  bool _isPasswordVisible = false;
  final _adminCodeController = TextEditingController();
  final _staffVetAccessCodeController = TextEditingController();
  bool _acceptPrivacyPolicy = false;
  bool _isLoading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Register'),
      ),
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            double maxWidth =
                constraints.maxWidth > 600 ? 400 : double.infinity;
            return SingleChildScrollView(
              padding: const EdgeInsets.all(24.0),
              child: Center(
                child: SizedBox(
                  width: maxWidth,
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Text(
                          'Create Account',
                          style: Theme.of(context)
                              .textTheme
                              .headlineMedium
                              ?.copyWith(
                                color: Theme.of(context).colorScheme.primary,
                                fontWeight: FontWeight.bold,
                              ),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 32),
                        TextFormField(
                          controller: _passwordController,
                          decoration: InputDecoration(
                            labelText: 'Password',
                            hintText: 'Example: Abc@1234',
                            alignLabelWithHint: true,
                            prefixIcon: const Icon(Icons.lock),
                            suffixIcon: IconButton(
                              icon: Icon(
                                _isPasswordVisible
                                    ? Icons.visibility
                                    : Icons.visibility_off,
                              ),
                              onPressed: () {
                                setState(() {
                                  _isPasswordVisible = !_isPasswordVisible;
                                });
                              },
                            ),
                            border: const OutlineInputBorder(),
                          ),
                          obscureText: !_isPasswordVisible,
                          maxLength: 128,
                          // Removes the bottom-right length counter (e.g., 0/120)
                          buildCounter: (context,
                                  {required currentLength,
                                  required maxLength,
                                  required isFocused}) =>
                              null,
                          validator: (value) {
                            final v = value ?? '';
                            if (v.isEmpty) return 'Please enter a password';
                            if (v.length < 8) {
                              return 'Password must be at least 8 characters';
                            }
                            // Requirement: uppercase, lowercase, number, special character
                            final hasUpper = RegExp(r'[A-Z]').hasMatch(v);
                            final hasLower = RegExp(r'[a-z]').hasMatch(v);
                            final hasNumber = RegExp(r'\d').hasMatch(v);
                            final hasSpecial =
                                RegExp(r'[^A-Za-z0-9]').hasMatch(v);

                            if (!hasUpper ||
                                !hasLower ||
                                !hasNumber ||
                                !hasSpecial) {
                              return 'Password must include uppercase, lowercase, a number, and a special character';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _emailController,
                          decoration: const InputDecoration(
                            labelText: 'Email',
                            hintText: 'Example: name@gmail.com',
                            prefixIcon: Icon(Icons.email),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.emailAddress,
                          // Removes the bottom-right length counter (e.g., 0/254)
                          buildCounter: (context,
                                  {required currentLength,
                                  required maxLength,
                                  required isFocused}) =>
                              null,
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty) {
                              return 'Please enter your email';
                            }
                            // Email must be a Gmail address only.
                            // Example: name@gmail.com
                            final emailRegex =
                                RegExp(r'^[\w.%+-]+@gmail\.com$');
                            if (!emailRegex.hasMatch(v)) {
                              return 'Email must be a valid @gmail.com address';
                            }

                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _fullnameController,
                          decoration: const InputDecoration(
                            labelText: 'Full Name',
                            hintText: 'Example: Juan Dela Cruz',
                            prefixIcon: Icon(Icons.person_outline),
                            border: OutlineInputBorder(),
                          ),
                          maxLength: 100,
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty) {
                              return 'Please enter your full name';
                            }
                            if (v.length < 5) {
                              return 'Full name must be at least 5 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _contactNumberController,
                          decoration: const InputDecoration(
                            labelText: 'Contact Number (PH)',
                            hintText: 'Example: 09123456789',
                            prefixIcon: Icon(Icons.phone),
                            border: OutlineInputBorder(),
                          ),
                          keyboardType: TextInputType.phone,
                          // Removes the bottom-right length counter (e.g., 0/20)
                          buildCounter: (context,
                                  {required currentLength,
                                  required maxLength,
                                  required isFocused}) =>
                              null,
                          validator: AppValidators.phoneNumber,
                        ),
                        const SizedBox(height: 16),
                        TextFormField(
                          controller: _addressController,
                          decoration: const InputDecoration(
                            labelText: 'Address',
                            prefixIcon: Icon(Icons.home),
                            border: OutlineInputBorder(),
                          ),
                          maxLength: 200,
                          validator: (value) {
                            final v = value?.trim() ?? '';
                            if (v.isEmpty) {
                              return 'Please enter your address';
                            }
                            if (v.length < 5) {
                              return 'Address must be at least 5 characters';
                            }
                            return null;
                          },
                        ),
                        const SizedBox(height: 16),
                        DropdownButtonFormField<UserRole>(
                          initialValue: _selectedRole,
                          decoration: const InputDecoration(
                            labelText: 'Role',
                            prefixIcon: Icon(Icons.group),
                            border: OutlineInputBorder(),
                          ),
                          items: UserRole.values.map((role) {
                            return DropdownMenuItem(
                              value: role,
                              child: Text(role.value),
                            );
                          }).toList(),
                          onChanged: (value) {
                            setState(() {
                              _selectedRole = value!;
                            });
                          },
                        ),
                        const SizedBox(height: 16),
                        // Access code fields for privileged roles.
                        // Admin/staff/veterinarian must use different verification codes.

                        if (_selectedRole == UserRole.admin) ...[
                          TextFormField(
                            controller: _adminCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Admin access code',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                            buildCounter: (context,
                                    {required currentLength,
                                    required maxLength,
                                    required isFocused}) =>
                                null,
                            validator: (value) {
                              if (_selectedRole == UserRole.admin) {
                                if (value == null || value.isEmpty) {
                                  return 'Admin access code is required';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ] else if (_selectedRole == UserRole.staff ||
                            _selectedRole == UserRole.veterinarian) ...[
                          TextFormField(
                            controller: _staffVetAccessCodeController,
                            decoration: const InputDecoration(
                              labelText: 'Access code',
                              hintText: 'Example: STAFF123',
                              prefixIcon: Icon(Icons.lock),
                              border: OutlineInputBorder(),
                            ),
                            buildCounter: (context,
                                    {required currentLength,
                                    required maxLength,
                                    required isFocused}) =>
                                null,
                            validator: (value) {
                              if (_selectedRole == UserRole.staff ||
                                  _selectedRole == UserRole.veterinarian) {
                                if (value == null || value.isEmpty) {
                                  return 'Access code is required';
                                }
                              }
                              return null;
                            },
                          ),
                          const SizedBox(height: 16),
                        ],
                        const SizedBox(height: 16),
                        // Data Privacy Act checkbox
                        CheckboxListTile(
                          value: _acceptPrivacyPolicy,
                          onChanged: (value) {
                            setState(() {
                              _acceptPrivacyPolicy = value ?? false;
                            });
                          },
                          title: Text(
                            'I agree to the Data Privacy Act of the Philippines (Republic Act No. 10173) and consent to the collection and processing of my personal data.',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                          controlAffinity: ListTileControlAffinity.leading,
                          contentPadding: EdgeInsets.zero,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton(
                          onPressed: (_acceptPrivacyPolicy && !_isLoading)
                              ? _register
                              : null,
                          style: ElevatedButton.styleFrom(
                            padding: const EdgeInsets.symmetric(vertical: 16),
                          ),
                          child: _isLoading
                              ? const SizedBox(
                                  height: 20,
                                  width: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Register'),
                        ),
                        const SizedBox(height: 16),
                        TextButton(
                          onPressed: () {
                            Navigator.pushReplacementNamed(context, '/login');
                          },
                          child: const Text('Already have an account? Login'),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }

  void _register() async {
    if (_formKey.currentState!.validate()) {
      if (!_acceptPrivacyPolicy) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
              content: Text(
                  'Please accept the Data Privacy Act terms and conditions.')),
        );
        return;
      }
      setState(() {
        _isLoading = true;
      });
      final authProvider = Provider.of<AuthProvider>(context, listen: false);
      final messenger = ScaffoldMessenger.of(context);

      try {
        // Access codes for privileged roles.
        // - Admin, staff, and veterinarian use the same verification code.
        if (_selectedRole == UserRole.admin ||
            _selectedRole == UserRole.staff ||
            _selectedRole == UserRole.veterinarian) {
          final configured = switch (_selectedRole) {
            UserRole.admin => adminVerificationCode,
            UserRole.staff => staffVerificationCode,
            UserRole.veterinarian => veterinarianVerificationCode,
            _ => '',
          };

          // Fail closed: privileged registration is disabled when no secret is configured.
          if (configured.isEmpty) {
            messenger.showSnackBar(
              const SnackBar(
                  content: Text('Privileged registration is not available.')),
            );
            return;
          }

          final provided = (_selectedRole == UserRole.admin)
              ? _adminCodeController.text.trim()
              : _staffVetAccessCodeController.text.trim();

          if (provided.isEmpty || provided != configured) {
            messenger.showSnackBar(
              const SnackBar(content: Text('Invalid access code.')),
            );
            return;
          }
        }

        // When admin is requested, register the user with a safe default role
        // (customer) and then call a callable function to request promotion.
        final registerRole =
            _selectedRole == UserRole.admin ? UserRole.customer : _selectedRole;

        await authProvider.registerWithEmailPassword(
          email: _emailController.text.trim(),
          password: _passwordController.text,
          name: _fullnameController.text,
          role: registerRole,
          contactNumber: _contactNumberController.text.trim(),
          address: _addressController.text.trim(),
        );

        // If admin was selected, call Cloud Function to request promotion.
        if (_selectedRole == UserRole.admin) {
          final uid = authProvider.firebaseUser?.uid;
          if (uid == null)
            throw Exception('User created but UID not available');

          final functions = FirebaseFunctions.instance;
          final callable = functions.httpsCallable('requestAdmin');
          final resp = await callable.call(<String, dynamic>{
            'uid': uid,
            'code': _adminCodeController.text.trim()
          });
          final data = resp.data as Map<String, dynamic>?;
          if (data == null || data['success'] != true) {
            messenger.showSnackBar(
                const SnackBar(content: Text('Admin request failed.')));
          } else {
            messenger.showSnackBar(
                const SnackBar(content: Text('Admin access granted.')));
          }
        }

        // Auto-approve staff or veterinarian after successful registration.
        if (_selectedRole == UserRole.staff ||
            _selectedRole == UserRole.veterinarian) {
          final uid = authProvider.firebaseUser?.uid;
          if (uid == null)
            throw Exception('User created but UID not available');

          final functions = FirebaseFunctions.instance;
          final callable = functions.httpsCallable('approveStaffOrVet');

          final code = _staffVetAccessCodeController.text.trim();
          final resp =
              await callable.call(<String, dynamic>{'uid': uid, 'code': code});
          final data = resp.data as Map<String, dynamic>?;
          if (data == null || data['success'] != true) {
            messenger.showSnackBar(
                const SnackBar(content: Text('Auto-approval failed.')));
          } else {
            messenger.showSnackBar(
                const SnackBar(content: Text('Account approved.')));
          }
        }

        if (!mounted) return;

        messenger.showSnackBar(
          const SnackBar(
              content: Text('Registration successful! Please login.')),
        );
        Navigator.pushReplacementNamed(context, '/login');
      } catch (e) {
        // Show specific, user-friendly reasons when possible.
        final code = _extractFirebaseAuthCode(e);
        if (code != null) {
          messenger.showSnackBar(
            SnackBar(content: Text(_firebaseAuthCodeToMessage(code))),
          );
          return;
        }

        messenger.showSnackBar(
          const SnackBar(
              content: Text('Registration failed. Please try again.')),
        );
      } finally {
        if (mounted) {
          setState(() {
            _isLoading = false;
          });
        }
      }
    }
  }

  String? _extractFirebaseAuthCode(Object e) {
    // FirebaseAuthException has `code`, but we avoid importing extra types here.
    final s = e.toString();
    // Typical format: [firebase_auth/invalid-email] ... or FirebaseAuthException(code: 'invalid-email', ...)
    final match = RegExp(r"firebase_auth/([a-zA-Z0-9_-]+)").firstMatch(s) ??
        RegExp(r"code:\s*'([a-zA-Z0-9_-]+)'").firstMatch(s);
    return match?.group(1);
  }

  String _firebaseAuthCodeToMessage(String code) {
    switch (code) {
      case 'invalid-email':
        return 'Invalid email address. Check formatting and try again.';
      case 'email-already-in-use':
        return 'This email is already registered. Try logging in instead.';
      case 'weak-password':
        return 'Password is too weak. Use a stronger password.';
      case 'operation-not-allowed':
        return 'Email/password sign-in is disabled for this Firebase project.';
      case 'network-request-failed':
        return 'Network error. Check your internet connection and try again.';
      case 'too-many-requests':
        return 'Too many attempts. Please wait a moment and try again.';
      default:
        return 'Registration failed ($code). Please try again.';
    }
  }

  @override
  void dispose() {
    _passwordController.dispose();
    _fullnameController.dispose();
    _contactNumberController.dispose();
    _emailController.dispose();
    _addressController.dispose();
    _adminCodeController.dispose();
    _staffVetAccessCodeController.dispose();
    super.dispose();
  }
}
