import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../state/dashboard_state.dart';
import '../theme.dart';
import '../widgets/hover_lift.dart';
import '../widgets/nav_icons.dart';

class AdminLoginScreen extends StatefulWidget {
  const AdminLoginScreen({super.key});

  @override
  State<AdminLoginScreen> createState() => _AdminLoginScreenState();
}

class _AdminLoginScreenState extends State<AdminLoginScreen> {
  final _emailController = TextEditingController(text: 'admin@rotary.org');
  final _passwordController = TextEditingController();
  bool _obscure = true;

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _submit(DashboardState state) {
    state.login(_emailController.text, _passwordController.text);
  }

  @override
  Widget build(BuildContext context) {
    final state = context.watch<DashboardState>();
    return Scaffold(
      backgroundColor: AdminColors.pageBg,
      body: Center(
        child: Container(
          width: 380,
          padding: const EdgeInsets.all(32),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: AdminColors.borderLight),
            boxShadow: [
              BoxShadow(color: AdminColors.modalShadow2, blurRadius: 32, offset: const Offset(0, 12)),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    width: 32,
                    height: 32,
                    decoration: BoxDecoration(
                      color: AdminColors.accent,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    alignment: Alignment.center,
                    child: const TargetLogoIcon(size: 16),
                  ),
                  const SizedBox(width: 10),
                  const Text(
                    'Rotary Admin',
                    style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18, letterSpacing: -0.2),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              const Text(
                'Sign in to manage clubs, members, and billing',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 12.5, color: AdminColors.textMuted),
              ),
              const SizedBox(height: 28),
              const Text('Email', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: _emailController,
                onSubmitted: (_) => _submit(state),
                style: const TextStyle(fontSize: 13),
                decoration: _fieldDecoration('admin@rotary.org'),
              ),
              const SizedBox(height: 14),
              const Text('Password', style: TextStyle(fontSize: 12.5, fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              TextField(
                controller: _passwordController,
                obscureText: _obscure,
                onSubmitted: (_) => _submit(state),
                style: const TextStyle(fontSize: 13),
                decoration: _fieldDecoration('••••••••').copyWith(
                  suffixIcon: IconButton(
                    icon: Icon(_obscure ? Icons.visibility_off : Icons.visibility, size: 18),
                    color: AdminColors.textMuted,
                    onPressed: () => setState(() => _obscure = !_obscure),
                  ),
                ),
              ),
              if (state.loginError != null) ...[
                const SizedBox(height: 12),
                Text(
                  state.loginError!,
                  style: const TextStyle(fontSize: 12.5, fontWeight: FontWeight.w600, color: AdminColors.overdueColor),
                ),
              ],
              const SizedBox(height: 20),
              HoverLift(
                scale: 1.02,
                child: ElevatedButton(
                  onPressed: state.loginLoading ? null : () => _submit(state),
                  style: ElevatedButton.styleFrom(
                    backgroundColor: AdminColors.accent,
                    foregroundColor: Colors.white,
                    elevation: 0,
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                    textStyle: const TextStyle(fontSize: 13.5, fontWeight: FontWeight.w700),
                  ),
                  child: state.loginLoading
                      ? const SizedBox(
                          width: 18,
                          height: 18,
                          child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white),
                        )
                      : const Text('Sign In'),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  InputDecoration _fieldDecoration(String hint) {
    return InputDecoration(
      isDense: true,
      hintText: hint,
      hintStyle: const TextStyle(fontSize: 13, color: AdminColors.placeholder),
      contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 11),
      filled: true,
      fillColor: Colors.white,
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AdminColors.inputBorder),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AdminColors.inputBorder),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(8),
        borderSide: const BorderSide(color: AdminColors.accent),
      ),
    );
  }
}
