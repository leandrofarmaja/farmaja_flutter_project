
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class ForgotPasswordScreen extends ConsumerStatefulWidget {
  const ForgotPasswordScreen({super.key});

  @override
  ConsumerState<ForgotPasswordScreen> createState() =>
      _ForgotPasswordScreenState();
}

class _ForgotPasswordScreenState
    extends ConsumerState<ForgotPasswordScreen> {
  final _emailController = TextEditingController();

  bool _isLoading = false;
  String? _message;
  String? _error;

  @override
  void dispose() {
    _emailController.dispose();
    super.dispose();
  }

  bool _isValidEmail(String email) {
    return RegExp(
      r'^[A-Z0-9._%+-]+@[A-Z0-9.-]+\.[A-Z]{2,}$',
      caseSensitive: false,
    ).hasMatch(email);
  }

  Future<void> _handleResetPassword() async {
    if (_isLoading) return;

    final email = _emailController.text.trim();

    if (!_isValidEmail(email)) {
      setState(() {
        _error = 'Introduza um endereço de e-mail válido.';
        _message = null;
      });
      return;
    }

    FocusScope.of(context).unfocus();

    setState(() {
      _isLoading = true;
      _error = null;
      _message = null;
    });

    try {
      final success = await ref
          .read(authProvider.notifier)
          .resetPassword(email);

      if (!mounted) return;

      if (success) {
        setState(() {
          _message =
              'Pedido processado. Se existir uma conta associada '
              'a este endereço, receberá instruções por e-mail. '
              'Verifique também a pasta de spam. '
              'Não feche esta página antes de confirmar a mensagem.';
          _error = null;
        });
      } else {
        final errorMessage = ref.read(authProvider).error;

        setState(() {
          _error = errorMessage ??
              'Não foi possível processar o pedido. '
                  'Tente novamente mais tarde.';
          _message = null;
        });
      }
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _error =
            'Ocorreu um erro ao solicitar a recuperação. '
            'Verifique a ligação à Internet e tente novamente.';
        _message = null;
      });
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recuperar palavra-passe'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const Icon(
                Icons.lock_reset,
                size: 64,
                color: AppColors.primary,
              ),
              const SizedBox(height: 16),
              const Text(
                'Esqueceu a palavra-passe?',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Introduza o endereço de e-mail associado '
                'à sua conta para solicitar a recuperação '
                'da palavra-passe.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 14,
                ),
              ),
              const SizedBox(height: 32),
              if (_message != null)
                Container(
                  padding: const EdgeInsets.all(16),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight.withOpacity(0.15),
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: AppColors.primary,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: AppColors.primary,
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Text(
                          _message!,
                          style: const TextStyle(
                            color: AppColors.primaryDark,
                            fontSize: 13,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              if (_error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(
                      color: Colors.red.shade200,
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Icon(
                        Icons.error_outline,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: Text(
                          _error!,
                          style: TextStyle(
                            color: Colors.red.shade700,
                            fontSize: 13,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                textInputAction: TextInputAction.done,
                autocorrect: false,
                enableSuggestions: false,
                onChanged: (_) {
                  if (_error != null || _message != null) {
                    setState(() {
                      _error = null;
                      _message = null;
                    });
                  }
                },
                onSubmitted: (_) {
                  if (!_isLoading) {
                    _handleResetPassword();
                  }
                },
                decoration: const InputDecoration(
                  labelText: 'Endereço de e-mail',
                  hintText: 'exemplo@email.com',
                  prefixIcon: Icon(Icons.email_outlined),
                  border: OutlineInputBorder(),
                ),
              ),
              const SizedBox(height: 24),
              FilledButton(
                onPressed:
                    _isLoading ? null : _handleResetPassword,
                child: _isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : const Text('Solicitar recuperação'),
              ),
              const SizedBox(height: 16),
              TextButton(
                onPressed: _isLoading
                    ? null
                    : () => context.go('/login'),
                child: const Text('Voltar ao início de sessão'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
