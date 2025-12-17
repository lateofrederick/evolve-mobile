import 'package:evolve/features/auth/presentation/auth_notifier.dart';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:lucide_icons/lucide_icons.dart';
import '../../../../core/theme/app_theme.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  // For demo convenience, pre-fill
  @override
  void initState() {
    super.initState();
    _emailController.text = "sarah.j@careflow.com";
    _passwordController.text = "password123";
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Please enter credentials")),
      );
      return;
    }

    // Call the Provider
    final success = await ref.read(authProvider.notifier).login(email, password);

    if (success) {
      if (mounted) context.go('/home');
    } else {
      final error = ref.read(authProvider).error;
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(error ?? "Login failed"), backgroundColor: Colors.red),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      body: SafeArea(
        child: SingleChildScrollView( // Added for keyboard handling
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 40),
              const Icon(LucideIcons.heartHandshake, size: 64, color: AppTheme.primary),
              const SizedBox(height: 24),
              Text(
                "Welcome to CareFlow",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 28, fontWeight: FontWeight.bold, color: AppTheme.textMain),
              ),
              const SizedBox(height: 8),
              Text(
                "Your AI-powered care companion.",
                textAlign: TextAlign.center,
                style: GoogleFonts.inter(fontSize: 16, color: AppTheme.textSub),
              ),
              const SizedBox(height: 48),
              const TextField(
                decoration: InputDecoration(labelText: "Company ID", prefixIcon: Icon(LucideIcons.building)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _emailController,
                decoration: const InputDecoration(labelText: "Email / Staff ID", prefixIcon: Icon(LucideIcons.user)),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                decoration: const InputDecoration(labelText: "Password", prefixIcon: Icon(LucideIcons.lock)),
                obscureText: true,
              ),
              const SizedBox(height: 32),

              ElevatedButton(
                onPressed: authState.isLoading ? null : _handleLogin,
                child: authState.isLoading
                    ? const SizedBox(
                        height: 20, width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white)
                      )
                    : const Text("Secure Login"),
              ),
            ],
          ),
        ),
      ),
    );
  }
}