
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class ResetPasswordScreen extends ConsumerStatefulWidget {
  const ResetPasswordScreen({super.key});

  @override
  ConsumerState<ResetPasswordScreen> createState() =>
      _ResetPasswordScreenState();
}

class _ResetPasswordScreenState
    extends ConsumerState<ResetPasswordScreen> {
  final _passwordController = TextEditingController();
  final _confirmController = TextEditingController();

  bool _loading = false;
  bool _leaving = false;
  bool _obscurePassword = true;
  bool _obscureConfirm = true;

  String? _error;
  String? _message;

  @override
  void dispose() {
    _passwordController.dispose();
    _confirmController.dispose();
    super.dispose();
  }

  Future<void> _returnToLogin() async {
    if (_loading || _leaving) return;

    setState(() {
      _leaving = true;
      _error = null;
      _message = null;
    });

    try {
      await ref
          .read(authProvider.notifier)
          .leavePasswordRecovery();

      if (!mounted) return;

      context.go('/login');
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _leaving = false;
        _error =
            'Não foi possível voltar ao início de sessão. '
            'Verifique a ligação e tente novamente.';
      });
    }
  }

  Future<void> _updatePassword() async {
    final password = _passwordController.text;
    final confirm = _confirmController.text;

    if (password.length < 8) {
      setState(() {
        _error =
            'A palavra-passe deve ter pelo menos 8 caracteres.';
        _message = null;
      });
      return;
    }

    if (password != confirm) {
      setState(() {
        _error = 'As palavras-passe não coincidem.';
        _message = null;
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
      _message = null;
    });

    try {
      final client = Supabase.instance.client;

      if (client.auth.currentSession == null) {
        throw const AuthException(
          'A sessão de recuperação não está ativa. '
          'Solicite um novo e-mail de recuperação.',
        );
      }

      await client.auth.updateUser(
        UserAttributes(password: password),
      );

      await ref
          .read(authProvider.notifier)
          .logout();

      if (!mounted) return;

      setState(() {
        _loading = false;
        _message =
            'Palavra-passe atualizada. Já pode entrar '
            'com a nova palavra-passe.';
      });

      await Future<void>.delayed(
        const Duration(milliseconds: 1200),
      );

      if (mounted) {
        context.go('/login');
      }
    } on AuthException catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error = e.message;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
            'Não foi possível atualizar a palavra-passe: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _leaving;

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text('Nova palavra-passe'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: busy ? null : _returnToLogin,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 24),
              const Icon(
                Icons.lock_reset_rounded,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 20),
              const Text(
                'Defina uma nova palavra-passe',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              const Text(
                'Introduza a nova palavra-passe e confirme-a '
                'para recuperar o acesso à sua conta FARCLIK.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondaryLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                enabled: !busy,
                decoration: InputDecoration(
                  labelText: 'Nova palavra-passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: busy
                        ? null
                        : () {
                            setState(() {
                              _obscurePassword =
                                  !_obscurePassword;
                            });
                          },
                    icon: Icon(
                      _obscurePassword
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _confirmController,
                obscureText: _obscureConfirm,
                enabled: !busy,
                decoration: InputDecoration(
                  labelText: 'Confirmar palavra-passe',
                  prefixIcon: const Icon(Icons.lock_outline),
                  suffixIcon: IconButton(
                    onPressed: busy
                        ? null
                        : () {
                            setState(() {
                              _obscureConfirm =
                                  !_obscureConfirm;
                            });
                          },
                    icon: Icon(
                      _obscureConfirm
                          ? Icons.visibility_outlined
                          : Icons.visibility_off_outlined,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 24),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _error!,
                    style: const TextStyle(color: Colors.red),
                  ),
                ),
              if (_message != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight
                        .withOpacity(0.2),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Text(
                    _message!,
                    style: const TextStyle(
                      color: AppColors.primaryDark,
                    ),
                  ),
                ),
              FilledButton(
                onPressed: busy ? null : _updatePassword,
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : const Text(
                        'Guardar nova palavra-passe',
                      ),
              ),
              const SizedBox(height: 12),
              TextButton(
                onPressed: busy ? null : _returnToLogin,
                child: const Text(
                  'Voltar ao início de sessão',
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
