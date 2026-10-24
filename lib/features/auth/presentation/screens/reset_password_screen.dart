import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/supabase_auth_service.dart';
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
  bool _passwordUpdated = false;
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
            'Tente novamente.';
      });
    }
  }

  Future<void> _updatePassword() async {
    if (_loading || _leaving || _passwordUpdated) return;

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
      final authService =
          ref.read(supabaseAuthServiceProvider);

      if (authService.currentSession == null) {
        throw Exception(
          'A sessão de recuperação não está activa. '
          'Solicite um novo e-mail de recuperação.',
        );
      }

      await authService.updatePassword(password);

      if (!mounted) return;

      setState(() {
        _loading = false;
        _passwordUpdated = true;
        _message =
            'Palavra-passe alterada com sucesso! '
            'Já pode regressar ao início de sessão '
            'e entrar com a nova palavra-passe.';
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _loading = false;
        _error =
            'Não foi possível actualizar a palavra-passe. '
            'Verifique a ligação e tente novamente. '
            'Detalhes: $e';
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    final busy = _loading || _leaving;
    final fieldsEnabled = !busy && !_passwordUpdated;

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
              Icon(
                _passwordUpdated
                    ? Icons.check_circle_outline
                    : Icons.lock_reset_rounded,
                size: 64,
                color: _passwordUpdated
                    ? AppColors.primary
                    : AppColors.primary,
              ),
              const SizedBox(height: 20),
              Text(
                _passwordUpdated
                    ? 'Palavra-passe actualizada'
                    : 'Defina uma nova palavra-passe',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w800,
                ),
              ),
              const SizedBox(height: 12),
              Text(
                _passwordUpdated
                    ? 'A sua palavra-passe foi actualizada. '
                        'Pode agora regressar ao início '
                        'de sessão.'
                    : 'Introduza a nova palavra-passe e '
                        'confirme-a para recuperar o acesso '
                        'à sua conta FARCLIK.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: AppColors.textSecondaryLight,
                  height: 1.5,
                ),
              ),
              const SizedBox(height: 32),
              if (!_passwordUpdated) ...[
                TextField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enabled: fieldsEnabled,
                  decoration: InputDecoration(
                    labelText: 'Nova palavra-passe',
                    prefixIcon:
                        const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: fieldsEnabled
                          ? () {
                              setState(() {
                                _obscurePassword =
                                    !_obscurePassword;
                              });
                            }
                          : null,
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
                  enabled: fieldsEnabled,
                  decoration: InputDecoration(
                    labelText: 'Confirmar palavra-passe',
                    prefixIcon:
                        const Icon(Icons.lock_outline),
                    suffixIcon: IconButton(
                      onPressed: fieldsEnabled
                          ? () {
                              setState(() {
                                _obscureConfirm =
                                    !_obscureConfirm;
                              });
                            }
                          : null,
                      icon: Icon(
                        _obscureConfirm
                            ? Icons.visibility_outlined
                            : Icons.visibility_off_outlined,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
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
                    style: const TextStyle(
                      color: Colors.red,
                    ),
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
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              FilledButton(
                onPressed: busy
                    ? null
                    : _passwordUpdated
                        ? _returnToLogin
                        : _updatePassword,
                child: busy
                    ? const SizedBox(
                        width: 22,
                        height: 22,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          color: Colors.white,
                        ),
                      )
                    : Text(
                        _passwordUpdated
                            ? 'Ir para início de sessão'
                            : 'Guardar nova palavra-passe',
                      ),
              ),
              const SizedBox(height: 12),
              if (!_passwordUpdated)
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
