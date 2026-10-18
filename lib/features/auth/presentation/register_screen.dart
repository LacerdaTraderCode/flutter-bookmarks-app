import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../app/app_routes.dart';
import '../application/auth_service.dart';
import '../domain/auth_models.dart';
import '../domain/auth_validation.dart';
import 'auth_page.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  bool _isSubmitting = false;
  String? _errorMessage;

  @override
  void dispose() {
    _nameController.dispose();
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
        .register(
          Registration(
            fullName: _nameController.text.trim(),
            email: _emailController.text.trim().toLowerCase(),
            password: _passwordController.text,
          ),
        );
    if (!mounted) return;
    setState(() {
      _isSubmitting = false;
      _errorMessage = error;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AuthPage(
      title: 'Create account',
      children: [
        Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              TextFormField(
                key: const Key('name-field'),
                controller: _nameController,
                autofillHints: const [AutofillHints.name],
                decoration: const InputDecoration(
                  labelText: 'Full name',
                  border: OutlineInputBorder(),
                ),
                validator: validateFullName,
              ),
              const SizedBox(height: 16),
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
                autofillHints: const [AutofillHints.newPassword],
                decoration: const InputDecoration(
                  labelText: 'Password',
                  border: OutlineInputBorder(),
                ),
                validator: validateNewPassword,
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
          label: 'Create account',
          isSubmitting: _isSubmitting,
          onPressed: _submit,
        ),
        const SizedBox(height: 8),
        TextButton(
          onPressed: () => context.go(AppRoutes.login),
          child: const Text('I already have an account'),
        ),
      ],
    );
  }
}
