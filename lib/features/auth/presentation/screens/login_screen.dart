import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/auth_provider.dart';

class LoginScreen extends ConsumerStatefulWidget {
  const LoginScreen({super.key});

  @override
  ConsumerState<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends ConsumerState<LoginScreen> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  bool _isPharmacyAccount = false;
  bool _obscurePassword = true;

  static const Color _green = Color(0xFF16A34A);
  static const Color _darkGreen = Color(0xFF15803D);
  static const Color _teal = Color(0xFF0F766E);
  static const Color _navy = Color(0xFF173B57);
  static const Color _background = Color(0xFFF8FBF9);

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  String _friendlyError(String? error) {
    if (error == null || error.trim().isEmpty) {
      return 'Não foi possível iniciar sessão. Tente novamente.';
    }

    final message = error.toLowerCase();

    if (message.contains('socketexception') ||
        message.contains('failed host lookup') ||
        message.contains('network') ||
        message.contains('connection')) {
      return 'Não foi possível estabelecer ligação. '
          'Verifique a sua internet e tente novamente.';
    }

    if (message.contains('invalid login credentials') ||
        message.contains('invalid_credentials')) {
      return 'E-mail ou palavra-passe incorrectos.';
    }

    if (message.contains('email not confirmed')) {
      return 'Confirme o seu e-mail antes de iniciar sessão.';
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

    final success =
        await ref.read(authProvider.notifier).login(email, password);

    if (!mounted) return;

    if (success) {
      final user = ref.read(authProvider).user;

      if (user?.role == 'pharmacy') {
        context.go('/pharmacy-dashboard');
      } else {
        context.go('/home');
      }
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
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 18,
        vertical: 18,
      ),
      labelStyle: const TextStyle(
        color: Color(0xFF667781),
        fontSize: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE0EAE4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Color(0xFFE0EAE4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _green, width: 1.7),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(24, 12, 24, 28),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // Navegação superior
              Align(
                alignment: Alignment.centerLeft,
                child: IconButton(
                  onPressed: () => context.go('/welcome'),
                  icon: const Icon(Icons.arrow_back_rounded),
                  color: _navy,
                  style: IconButton.styleFrom(
                    backgroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 12),

              // Logótipo oficial
              Center(
                child: Container(
                  width: 116,
                  height: 116,
                  padding: const EdgeInsets.all(10),
                  decoration: BoxDecoration(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(30),
                    boxShadow: [
                      BoxShadow(
                        color: _green.withValues(alpha: 0.09),
                        blurRadius: 26,
                        offset: const Offset(0, 10),
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
                        size: 64,
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 22),

              Text(
                _isPharmacyAccount
                    ? 'Bem-vindo à FARCLIK!'
                    : 'Seja bem-vindo!',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 29,
                  fontWeight: FontWeight.w800,
                  letterSpacing: -0.7,
                ),
              ),

              const SizedBox(height: 10),

              Text(
                _isPharmacyAccount
                    ? 'Aceda à gestão da sua farmácia, '
                        'ao stock e às reservas.'
                    : 'Encontre medicamentos nas farmácias '
                        'perto de si, de forma simples e rápida.',
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Color(0xFF687984),
                  fontSize: 14,
                  height: 1.65,
                ),
              ),

              const SizedBox(height: 26),

              // Selecção do tipo de conta
              Container(
                padding: const EdgeInsets.all(5),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF2ED),
                  borderRadius: BorderRadius.circular(17),
                ),
                child: Row(
                  children: [
                    Expanded(
                      child: _AccountTypeButton(
                        label: 'Cliente',
                        icon: Icons.person_outline_rounded,
                        selected: !_isPharmacyAccount,
                        onTap: () {
                          setState(() => _isPharmacyAccount = false);
                        },
                      ),
                    ),
                    Expanded(
                      child: _AccountTypeButton(
                        label: 'Farmácia',
                        icon: Icons.storefront_outlined,
                        selected: _isPharmacyAccount,
                        onTap: () {
                          setState(() => _isPharmacyAccount = true);
                        },
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 25),

              const Text(
                'E-mail',
                style: TextStyle(
                  color: _navy,
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
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
                  fontWeight: FontWeight.w700,
                  fontSize: 14,
                ),
              ),

              const SizedBox(height: 9),

              TextField(
                controller: _passwordController,
                obscureText: _obscurePassword,
                textInputAction: TextInputAction.done,
                onSubmitted: (_) {
                  if (!authState.isLoading) _handleLogin();
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
                      color: const Color(0xFF7A8C95),
                    ),
                  ),
                ),
              ),

              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/forgot-password'),
                  child: const Text(
                    'Esqueceu a palavra-passe?',
                    style: TextStyle(
                      color: _darkGreen,
                      fontWeight: FontWeight.w700,
                      fontSize: 13,
                    ),
                  ),
                ),
              ),

              // Erros apresentados sem expor detalhes técnicos internos
              if (authState.error != null) ...[
                const SizedBox(height: 5),
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF1F0),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: const Color(0xFFF4C7C3),
                    ),
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
                            fontSize: 13,
                            height: 1.4,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              ],

              const SizedBox(height: 15),

              SizedBox(
                height: 56,
                child: FilledButton(
                  onPressed:
                      authState.isLoading ? null : _handleLogin,
                  style: FilledButton.styleFrom(
                    backgroundColor: _green,
                    disabledBackgroundColor: const Color(0xFF9BCBA9),
                    foregroundColor: Colors.white,
                    elevation: 0,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(17),
                    ),
                  ),
                  child: authState.isLoading
                      ? const SizedBox(
                          width: 23,
                          height: 23,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2.3,
                          ),
                        )
                      : const Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Text(
                              'Iniciar sessão',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            SizedBox(width: 9),
                            Icon(Icons.arrow_forward_rounded, size: 20),
                          ],
                        ),
                ),
              ),

              const SizedBox(height: 23),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Flexible(
                    child: Text(
                      'Ainda não tem uma conta?',
                      style: TextStyle(
                        color: Color(0xFF687984),
                        fontSize: 13,
                      ),
                    ),
                  ),
                  TextButton(
                    onPressed: () => context.go('/register'),
                    child: const Text(
                      'Criar conta',
                      style: TextStyle(
                        color: _darkGreen,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 19),

              // Informação de privacidade
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 15,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFEAF6EF),
                  borderRadius: BorderRadius.circular(17),
                  border: Border.all(
                    color: const Color(0xFFD6EBDD),
                  ),
                ),
                child: const Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Icon(
                      Icons.shield_outlined,
                      color: _teal,
                      size: 25,
                    ),
                    SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'A sua privacidade é importante',
                            style: TextStyle(
                              color: _navy,
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          SizedBox(height: 5),
                          Text(
                            'Os seus dados devem ser tratados com '
                            'confidencialidade e acedidos apenas '
                            'para finalidades autorizadas.',
                            style: TextStyle(
                              color: Color(0xFF58716A),
                              fontSize: 12,
                              height: 1.5,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 18),

              const Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.verified_user_outlined,
                    color: _teal,
                    size: 16,
                  ),
                  SizedBox(width: 7),
                  Flexible(
                    child: Text(
                      'FARCLIK · Farmácias e Medicamentos em Angola',
                      textAlign: TextAlign.center,
                      style: TextStyle(
                        color: Color(0xFF7A8C95),
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
  }
}

class _AccountTypeButton extends StatelessWidget {
  const _AccountTypeButton({
    required this.label,
    required this.icon,
    required this.selected,
    required this.onTap,
  });

  final String label;
  final IconData icon;
  final bool selected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16A34A);
    const navy = Color(0xFF173B57);

    return Material(
      color: selected ? Colors.white : Colors.transparent,
      borderRadius: BorderRadius.circular(13),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(13),
        child: Padding(
          padding: const EdgeInsets.symmetric(vertical: 13, horizontal: 5),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                icon,
                size: 19,
                color: selected ? green : const Color(0xFF687984),
              ),
              const SizedBox(width: 7),
              Flexible(
                child: Text(
                  label,
                  overflow: TextOverflow.ellipsis,
                  style: TextStyle(
                    color: selected ? navy : const Color(0xFF687984),
                    fontSize: 13,
                    fontWeight:
                        selected ? FontWeight.w800 : FontWeight.w600,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
