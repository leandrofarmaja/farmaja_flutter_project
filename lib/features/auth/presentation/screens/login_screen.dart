
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _obscurePassword = true;

  static const Color _green = Color(0xFF16A34A);
  static const Color _darkGreen = Color(0xFF15803D);
  static const Color _teal = Color(0xFF0F766E);
  static const Color _navy = Color(0xFF173B57);
  static const Color _background = Color(0xFFF7FAF8);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _friendlyError(String? error) {
    if (error == null || error.trim().isEmpty) {
      return 'Não foi possível iniciar sessão. '
          'Verifique os seus dados e tente novamente.';
    }

    final message = error.toLowerCase();

    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network') ||
        message.contains('connection') ||
        message.contains('timeout') ||
        message.contains('timed out')) {
      return 'Não foi possível estabelecer ligação. '
          'Verifique a sua ligação à Internet e tente novamente.';
    }

    if (message.contains('invalid login credentials') ||
        message.contains('invalid_credentials') ||
        message.contains('user not found') ||
        message.contains('invalid email or password')) {
      return 'O e-mail ou a palavra-passe estão incorrectos. '
          'Verifique os seus dados e tente novamente.';
    }

    if (message.contains('email not confirmed')) {
      return 'Confirme o seu endereço de e-mail antes de iniciar sessão.';
    }

    if (message.contains('too many requests') ||
        message.contains('rate limit')) {
      return 'Foram realizadas demasiadas tentativas. '
          'Aguarde alguns instantes e tente novamente.';
    }

    if (message.contains('perfil') ||
        message.contains('role') ||
        message.contains('função') ||
        message.contains('funcao')) {
      return 'As credenciais foram aceites, mas não foi possível '
          'carregar o perfil da conta. Contacte o suporte FARCLIK.';
    }

    return 'Não foi possível iniciar sessão. '
        'Verifique os seus dados e tente novamente.';
  }

  Future<void> _handleLogin() async {
    FocusScope.of(context).unfocus();

    final email = _emailController.text.trim();
    final password = _passwordController.text;

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduza o e-mail e a palavra-passe.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await ref
        .read(authProvider.notifier)
        .login(email, password);

    if (!mounted) return;

    if (!success) return;

    final authState = ref.read(authProvider);
    final user = authState.user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'As credenciais foram aceites, mas não foi possível '
            'carregar o perfil da conta. Contacte o suporte FARCLIK.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    switch (user.role.trim().toLowerCase()) {
      case 'customer':
        context.go('/home');
        break;
      case 'pharmacy':
        context.go('/pharmacy-dashboard');
        break;
      case 'admin':
        context.go('/admin/subscriptions');
        break;
      default:
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'As credenciais foram aceites, mas esta conta '
              'não possui uma função válida. Contacte o suporte FARCLIK.',
            ),
            behavior: SnackBarBehavior.floating,
          ),
        );
    }
  }

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, color: _teal, size: 21),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: const Color(0xFFFAFCFB),
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 19,
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF718096),
        fontSize: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE5ECE8)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE5ECE8)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: _green,
          width: 1.6,
        ),
      ),
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 112,
      height: 112,
      padding: const EdgeInsets.all(9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(28),
        border: Border.all(color: const Color(0xFFE8F1EB)),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.07),
            blurRadius: 28,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Image.asset(
        'FARCLIK_logo.png',
        fit: BoxFit.contain,
        errorBuilder: (context, error, stackTrace) {
          return const Icon(
            Icons.local_pharmacy_rounded,
            color: _green,
            size: 58,
          );
        },
      ),
    );
  }

  Widget _buildHeader() {
    return Column(
      children: [
        _buildLogo(),
        const SizedBox(height: 22),
        const Text(
          'Bem-vindo ao FARCLIK',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: _navy,
            fontSize: 27,
            fontWeight: FontWeight.w900,
            letterSpacing: -0.8,
          ),
        ),
        const SizedBox(height: 9),
        const Text(
          'A sua saúde, mais perto de si.',
          textAlign: TextAlign.center,
          style: TextStyle(
            color: Color(0xFF718096),
            fontSize: 14,
            height: 1.5,
          ),
        ),
      ],
    );
  }

  Widget _buildLoginForm(dynamic authState) {
    return Container(
      padding: const EdgeInsets.fromLTRB(21, 24, 21, 22),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: const Color(0xFFEAF0EC)),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.045),
            blurRadius: 30,
            offset: const Offset(0, 12),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          const Text(
            'Iniciar sessão',
            style: TextStyle(
              color: _navy,
              fontSize: 19,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Introduza os seus dados para continuar.',
            style: TextStyle(
              color: Color(0xFF829099),
              fontSize: 12.5,
            ),
          ),
          const SizedBox(height: 23),

          const Text(
            'Endereço de e-mail',
            style: TextStyle(
              color: _navy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          TextField(
            controller: _emailController,
            keyboardType: TextInputType.emailAddress,
            textInputAction: TextInputAction.next,
            autocorrect: false,
            enableSuggestions: false,
            decoration: _inputDecoration(
              label: 'Introduza o seu e-mail',
              icon: Icons.mail_outline_rounded,
            ),
          ),

          const SizedBox(height: 19),

          const Text(
            'Palavra-passe',
            style: TextStyle(
              color: _navy,
              fontSize: 13,
              fontWeight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 9),
          TextField(
            controller: _passwordController,
            obscureText: _obscurePassword,
            textInputAction: TextInputAction.done,
            onSubmitted: (_) {
              if (!authState.isLoading) {
                _handleLogin();
              }
            },
            decoration: _inputDecoration(
              label: 'Introduza a sua palavra-passe',
              icon: Icons.lock_outline_rounded,
              suffixIcon: IconButton(
                tooltip: _obscurePassword
                    ? 'Mostrar palavra-passe'
                    : 'Ocultar palavra-passe',
                onPressed: () {
                  setState(() {
                    _obscurePassword = !_obscurePassword;
                  });
                },
                icon: Icon(
                  _obscurePassword
                      ? Icons.visibility_outlined
                      : Icons.visibility_off_outlined,
                  color: const Color(0xFF84939A),
                  size: 21,
                ),
              ),
            ),
          ),

          Align(
            alignment: Alignment.centerRight,
            child: TextButton(
              onPressed: () => context.go('/forgot-password'),
              child: const Text(
                'Esqueceu-se da palavra-passe?',
                style: TextStyle(
                  color: _darkGreen,
                  fontWeight: FontWeight.w700,
                  fontSize: 12.5,
                ),
              ),
            ),
          ),

          if (authState.error != null) ...[
            const SizedBox(height: 5),
            Container(
              padding: const EdgeInsets.all(13),
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F0),
                borderRadius: BorderRadius.circular(13),
                border: Border.all(color: const Color(0xFFF4C7C3)),
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Icon(
                    Icons.error_outline_rounded,
                    color: Color(0xFFB42318),
                    size: 20,
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      _friendlyError(authState.error),
                      style: const TextStyle(
                        color: Color(0xFFB42318),
                        fontSize: 12.5,
                        height: 1.4,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 16),

          SizedBox(
            height: 55,
            child: FilledButton(
              onPressed: authState.isLoading ? null : _handleLogin,
              style: FilledButton.styleFrom(
                backgroundColor: _green,
                disabledBackgroundColor: const Color(0xFF9BCBA9),
                foregroundColor: Colors.white,
                elevation: 0,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(15),
                ),
              ),
              child: authState.isLoading
                  ? const SizedBox(
                      width: 22,
                      height: 22,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2.2,
                      ),
                    )
                  : const Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(
                          'Entrar na minha conta',
                          style: TextStyle(
                            fontSize: 14,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        SizedBox(width: 10),
                        Icon(Icons.arrow_forward_rounded, size: 19),
                      ],
                    ),
            ),
          ),

          const SizedBox(height: 20),

          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              const Flexible(
                child: Text(
                  'Ainda não tem uma conta?',
                  style: TextStyle(
                    color: Color(0xFF718096),
                    fontSize: 12.5,
                  ),
                ),
              ),
              TextButton(
                onPressed: () => context.go('/register'),
                child: const Text(
                  'Criar conta',
                  style: TextStyle(
                    color: _darkGreen,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildSecurityNotice() {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 15,
        vertical: 15,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5EE),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFDCECE1)),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.shield_outlined,
            color: _teal,
            size: 24,
          ),
          SizedBox(width: 11),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'A sua privacidade é importante',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 12.5,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                SizedBox(height: 5),
                Text(
                  'Os seus dados são tratados com confidencialidade '
                  'e utilizados apenas para finalidades autorizadas.',
                  style: TextStyle(
                    color: Color(0xFF58716A),
                    fontSize: 11.5,
                    height: 1.5,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(22, 12, 22, 25),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 460),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      Align(
                        alignment: Alignment.centerLeft,
                        child: IconButton(
                          onPressed: () => context.go('/welcome'),
                          icon: const Icon(Icons.arrow_back_rounded),
                          color: _navy,
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(13),
                            ),
                          ),
                        ),
                      ),

                      SizedBox(
                        height: constraints.maxHeight < 700 ? 12 : 23,
                      ),

                      _buildHeader(),

                      const SizedBox(height: 30),

                      _buildLoginForm(authState),

                      const SizedBox(height: 19),

                      _buildSecurityNotice(),

                      const SizedBox(height: 23),

                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.verified_user_outlined,
                            color: _teal,
                            size: 15,
                          ),
                          SizedBox(width: 7),
                          Flexible(
                            child: Text(
                              'FARCLIK · Farmácias e Medicamentos em Angola',
                              textAlign: TextAlign.center,
                              style: TextStyle(
                                color: Color(0xFF819099),
                                fontSize: 10.5,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
