import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../../../core/session/session_controller.dart';
import '../../../core/widgets/form_widgets.dart';
import '../application/auth_service.dart';
import '../domain/auth_models.dart';
import '../domain/auth_validation.dart';
import 'auth_page.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isSubmitting = true;
      _errorMessage = null;
    });
    final error = await ref
        .read(authServiceProvider)
        .signIn(
          Credentials(
            email: _emailController.text.trim().toLowerCase(),
            password: _passwordController.text,
          ),
        );
    // On success the session changes, the router replaces this screen and it
    // is no longer mounted.
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _errorMessage = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    final session = ref.watch(sessionControllerProvider);
    final sessionExpired = session is SignedOut && session.expired;

    return AuthPage(
      title: 'Sign in',
      children: [
        if (sessionExpired) ...[
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Theme.of(context).colorScheme.secondaryContainer,
              borderRadius: BorderRadius.circular(8),
            ),
            child: const Text(
              'Your session expired. Sign in again to continue.',
            ),
          ),
          const SizedBox(height: 16),
        ],
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('email-field'),
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                autofillHints: const [AutofillHints.email],
                decoration: const InputDecoration(
                  labelText: 'Email',
                  border: OutlineInputBorder(),
                ),
                validator: validateEmail,
              ),
              const SizedBox(height: 16),
              TextFormField(
                key: const Key('password-field'),
                controller: _passwordController,
                obscureText: true,
                autofillHints: const [AutofillHints.password],
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: validateLoginPassword,
              ),
            ],
          ),
        ),
        if (_errorMessage != null) ...[
          const SizedBox(height: 16),
          FormErrorText(_errorMessage!),
        ],
        const SizedBox(height: 24),
        SubmitButton(
          label: 'Sign in',
          isSubmitting: _isSubmitting,
          onPressed: _submit,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.go(AppRoutes.register),
          child: const Text('Create an account'),
        ),
      ],
    );
  }
}
