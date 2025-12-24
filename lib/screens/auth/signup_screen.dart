import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:datingapp/core/utils/validators.dart';
import 'package:datingapp/providers/auth_provider.dart';
import 'package:datingapp/widgets/common/custom_button.dart';
import 'package:datingapp/widgets/common/custom_text_field.dart';
import 'package:datingapp/core/theme/app_theme.dart';

class SignupScreen extends ConsumerStatefulWidget {
  const SignupScreen({super.key});

  @override
  ConsumerState<SignupScreen> createState() => _SignupScreenState();
}

class _SignupScreenState extends ConsumerState<SignupScreen> {
  final _formKey = GlobalKey<FormState>();
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _isLoading = false;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Please confirm your password';
    }
    if (value != _passwordController.text) {
      return 'Passwords do not match';
    }
    return null;
  }

  Future<void> _handleSignup() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isLoading = true);

    try {
      final authService = ref.read(authServiceProvider);
      await authService.signUpWithEmail(
        email: _emailController.text.trim(),
        password: _passwordController.text,
      );
      
      if (mounted) {
        context.go('/profile-setup');
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(e.toString()),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isLoading = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                const SizedBox(height: 20),
                
                Text(
                  'Create Account',
                  style: Theme.of(context).textTheme.displayMedium,
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 8),
                
                Text(
                  'Join the party and start mixing!',
                  style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                    color: AppTheme.textSecondary,
                  ),
                  textAlign: TextAlign.center,
                ),
                const SizedBox(height: 40),
                
                // Email Field
                CustomTextField(
                  controller: _emailController,
                  hintText: 'Email',
                  prefixIcon: Icons.email_outlined,
                  keyboardType: TextInputType.emailAddress,
                  validator: Validators.validateEmail,
                ),
                const SizedBox(height: 16),
                
                // Password Field
                CustomTextField(
                  controller: _passwordController,
                  hintText: 'Password',
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: _obscurePassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  onSuffixIconTap: () => setState(() => _obscurePassword = !_obscurePassword),
                  obscureText: _obscurePassword,
                  validator: Validators.validatePassword,
                ),
                const SizedBox(height: 16),
                
                // Confirm Password Field
                CustomTextField(
                  controller: _confirmPasswordController,
                  hintText: 'Confirm Password',
                  prefixIcon: Icons.lock_outline,
                  suffixIcon: _obscureConfirmPassword ? Icons.visibility_outlined : Icons.visibility_off_outlined,
                  onSuffixIconTap: () => setState(() => _obscureConfirmPassword = !_obscureConfirmPassword),
                  obscureText: _obscureConfirmPassword,
                  validator: _validateConfirmPassword,
                ),
                const SizedBox(height: 24),
                
                // Sign Up Button
                CustomButton(
                  text: 'Sign Up',
                  onPressed: _handleSignup,
                  isLoading: _isLoading,
                ),
                const SizedBox(height: 16),
                
                // Login Link
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Text(
                      'Already have an account? ',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    TextButton(
                      onPressed: () => context.go('/login'),
                      child: const Text('Login'),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
