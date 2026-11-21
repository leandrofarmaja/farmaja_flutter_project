
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() =>
      _RegisterScreenState();
}

class _RegisterScreenState extends ConsumerState<RegisterScreen> {
  final _formKey = GlobalKey<FormState>();
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();

  bool _obscurePassword = true;
  bool _obscureConfirmPassword = true;
  bool _acceptedPrivacy = false;
  bool _submitted = false;

  static const Color _green = Color(0xFF16A34A);
  static const Color _darkGreen = Color(0xFF15803D);
  static const Color _teal = Color(0xFF0F766E);
  static const Color _navy = Color(0xFF173B57);
  static const Color _muted = Color(0xFF687984);
  static const Color _border = Color(0xFFE4ECE7);
  static const Color _surface = Color(0xFFF8FBF9);

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value, String field) {
    if (value == null || value.trim().isEmpty) {
      return 'Introduza $field.';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    final email = value?.trim() ?? '';

    if (email.isEmpty) {
      return 'Introduza o seu e-mail.';
    }

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$').hasMatch(email)) {
      return 'Introduza um endereço de e-mail válido.';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    final phone = value?.trim() ?? '';

    if (phone.isEmpty) {
      return 'Introduza o número de telefone.';
    }

    final digits = phone.replaceAll(RegExp(r'\D'), '');

    if (digits.length < 9 || digits.length > 15) {
      return 'Verifique o número de telefone.';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Introduza uma palavra-passe.';
    }

    if (value.length < 6) {
      return 'Utilize pelo menos 6 caracteres.';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Repita a palavra-passe.';
    }

    if (value != _passwordController.text) {
      return 'As palavras-passe não coincidem.';
    }

    return null;
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffixIcon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _teal, size: 21),
      suffixIcon: suffixIcon,
      filled: true,
      fillColor: Colors.white,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      labelStyle: const TextStyle(
        color: _muted,
        fontSize: 13,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFFA1ADB3),
        fontSize: 13,
      ),
      errorStyle: const TextStyle(fontSize: 11),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: _green, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFDC2626)),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(
          color: Color(0xFFDC2626),
          width: 1.4,
        ),
      ),
    );
  }

  Future<void> _handleRegister() async {
    if (_submitted) return;

    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) return;

    if (!_acceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Leia e confirme a informação de privacidade para continuar.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitted = true);

    try {
      final success = await ref.read(authProvider.notifier).register(
        fullName: _fullNameController.text.trim(),
        email: _emailController.text.trim(),
        password: _passwordController.text,
        phone: _phoneController.text.trim(),
        province: '',
        district: '',
        role: 'customer',
      );

      if (!mounted) return;

      setState(() => _submitted = false);

      final authState = ref.read(authProvider);

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authState.error ??
                  'Não foi possível criar a conta. Tente novamente.',
            ),
            behavior: SnackBarBehavior.floating,
            duration: const Duration(seconds: 6),
          ),
        );
        return;
      }

      if (authState.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada com sucesso!'),
            backgroundColor: _green,
            behavior: SnackBarBehavior.floating,
          ),
        );
        context.go('/home');
        return;
      }

      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          return AlertDialog(
            icon: const Icon(
              Icons.mark_email_read_outlined,
              color: _green,
              size: 42,
            ),
            title: const Text('Conta criada com sucesso!'),
            content: Text(
              'O registo foi aceite para ${_emailController.text.trim()}. '
              'Se a confirmação de email estiver activa, '
              'abra a mensagem recebida e confirme a conta '
              'antes de iniciar sessão. Verifique também '
              'a pasta de spam.',
            ),
            actions: [
              FilledButton(
                onPressed: () => Navigator.of(dialogContext).pop(),
                child: const Text('Ir para o início de sessão'),
              ),
            ],
          );
        },
      );

      if (!mounted) return;
      context.go('/login');
    } catch (e) {
      if (!mounted) return;

      setState(() => _submitted = false);

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar conta: $e'),
          behavior: SnackBarBehavior.floating,
          duration: const Duration(seconds: 6),
        ),
      );
    }
  }

  Widget _sectionTitle(
    String title, {
    String? subtitle,
    IconData? icon,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        if (icon != null) ...[
          Container(
            width: 36,
            height: 36,
            decoration: BoxDecoration(
              color: const Color(0xFFEAF6EF),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(icon, color: _green, size: 19),
          ),
          const SizedBox(width: 11),
        ],
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: const TextStyle(
                  color: _navy,
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
              if (subtitle != null) ...[
                const SizedBox(height: 4),
                Text(
                  subtitle,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 12,
                    height: 1.45,
                  ),
                ),
              ],
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildLogo() {
    return Container(
      width: 88,
      height: 88,
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(color: _border),
        boxShadow: [
          BoxShadow(
            color: _green.withValues(alpha: 0.09),
            blurRadius: 24,
            offset: const Offset(0, 8),
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
            size: 49,
          );
        },
      ),
    );
  }

  Widget _buildPrivacyNotice(bool isLoading) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F8F3),
        borderRadius: BorderRadius.circular(17),
        border: Border.all(color: const Color(0xFFD8EBDD)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Row(
            children: [
              Icon(
                Icons.shield_outlined,
                color: _teal,
                size: 22,
              ),
              SizedBox(width: 9),
              Expanded(
                child: Text(
                  'Privacidade e protecção de dados',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 13,
                    fontWeight: FontWeight.w800,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 9),
          const Text(
            'Utilizamos os dados fornecidos para gerir a sua conta '
            'e disponibilizar as funcionalidades autorizadas. '
            'A localização será tratada separadamente e dependerá '
            'das suas escolhas.',
            style: TextStyle(
              color: Color(0xFF58716A),
              fontSize: 12,
              height: 1.55,
            ),
          ),
          const SizedBox(height: 8),
          CheckboxListTile(
            contentPadding: EdgeInsets.zero,
            controlAffinity: ListTileControlAffinity.leading,
            dense: true,
            visualDensity: VisualDensity.compact,
            activeColor: _green,
            value: _acceptedPrivacy,
            onChanged: isLoading
                ? null
                : (value) {
                    setState(() {
                      _acceptedPrivacy = value ?? false;
                    });
                  },
            title: const Text(
              'Li e compreendi a informação acima.',
              style: TextStyle(
                color: _navy,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = _submitted || authState.isLoading;

    return Scaffold(
      backgroundColor: _surface,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              keyboardDismissBehavior:
                  ScrollViewKeyboardDismissBehavior.onDrag,
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 520),
                  child: Form(
                    key: _formKey,
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        Align(
                          alignment: Alignment.centerLeft,
                          child: IconButton(
                            onPressed: isLoading
                                ? null
                                : () => context.go('/login'),
                            tooltip: 'Voltar ao início de sessão',
                            icon: const Icon(Icons.arrow_back_rounded),
                            color: _navy,
                            style: IconButton.styleFrom(
                              backgroundColor: Colors.white,
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                                side: const BorderSide(color: _border),
                              ),
                            ),
                          ),
                        ),
                        const SizedBox(height: 12),
                        Center(child: _buildLogo()),
                        const SizedBox(height: 19),
                        const Text(
                          'Crie a sua conta',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _navy,
                            fontSize: 27,
                            fontWeight: FontWeight.w900,
                            letterSpacing: -0.7,
                          ),
                        ),
                        const SizedBox(height: 8),
                        const Text(
                          'Aceda às farmácias e medicamentos '
                          'de forma simples e segura.',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: _muted,
                            fontSize: 13,
                            height: 1.6,
                          ),
                        ),
                        const SizedBox(height: 25),
                        Container(
                          padding: const EdgeInsets.all(19),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(23),
                            border: Border.all(color: _border),
                            boxShadow: [
                              BoxShadow(
                                color: _navy.withValues(alpha: 0.035),
                                blurRadius: 25,
                                offset: const Offset(0, 9),
                              ),
                            ],
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.stretch,
                            children: [
                              _sectionTitle(
                                'Os seus dados',
                                subtitle:
                                    'Preencha os campos para criar a sua conta.',
                                icon: Icons.person_outline_rounded,
                              ),
                              const SizedBox(height: 17),
                              TextFormField(
                                controller: _fullNameController,
                                textCapitalization:
                                    TextCapitalization.words,
                                textInputAction: TextInputAction.next,
                                enabled: !isLoading,
                                decoration: _decoration(
                                  label: 'Nome completo *',
                                  icon: Icons.person_outline_rounded,
                                ),
                                validator: (value) =>
                                    _requiredValidator(
                                  value,
                                  'o nome completo',
                                ),
                              ),
                              const SizedBox(height: 15),
                              TextFormField(
                                controller: _emailController,
                                keyboardType: TextInputType.emailAddress,
                                textInputAction: TextInputAction.next,
                                autocorrect: false,
                                enableSuggestions: false,
                                enabled: !isLoading,
                                decoration: _decoration(
                                  label: 'E-mail *',
                                  hint: 'exemplo@email.com',
                                  icon: Icons.mail_outline_rounded,
                                ),
                                validator: _validateEmail,
                              ),
                              const SizedBox(height: 15),
                              TextFormField(
                                controller: _phoneController,
                                keyboardType: TextInputType.phone,
                                textInputAction: TextInputAction.next,
                                enabled: !isLoading,
                                decoration: _decoration(
                                  label: 'Telefone / WhatsApp *',
                                  hint: '+244 923 123 456',
                                  icon: Icons.phone_outlined,
                                ),
                                validator: _validatePhone,
                              ),
                              const SizedBox(height: 25),
                              const Divider(color: _border, height: 1),
                              const SizedBox(height: 22),
                              _sectionTitle(
                                'Segurança da conta',
                                subtitle:
                                    'Utilize pelo menos 6 caracteres e '
                                    'confirme a palavra-passe.',
                                icon: Icons.lock_outline_rounded,
                              ),
                              const SizedBox(height: 17),
                              TextFormField(
                                controller: _passwordController,
                                obscureText: _obscurePassword,
                                enableSuggestions: false,
                                autocorrect: false,
                                enabled: !isLoading,
                                textInputAction: TextInputAction.next,
                                decoration: _decoration(
                                  label: 'Palavra-passe *',
                                  icon: Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    tooltip: _obscurePassword
                                        ? 'Mostrar palavra-passe'
                                        : 'Ocultar palavra-passe',
                                    onPressed: isLoading
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
                                      color: _muted,
                                    ),
                                  ),
                                ),
                                validator: _validatePassword,
                              ),
                              const SizedBox(height: 15),
                              TextFormField(
                                controller: _confirmPasswordController,
                                obscureText: _obscureConfirmPassword,
                                enableSuggestions: false,
                                autocorrect: false,
                                enabled: !isLoading,
                                textInputAction: TextInputAction.done,
                                decoration: _decoration(
                                  label: 'Confirmar palavra-passe *',
                                  icon: Icons.lock_outline_rounded,
                                  suffixIcon: IconButton(
                                    tooltip: _obscureConfirmPassword
                                        ? 'Mostrar confirmação'
                                        : 'Ocultar confirmação',
                                    onPressed: isLoading
                                        ? null
                                        : () {
                                            setState(() {
                                              _obscureConfirmPassword =
                                                  !_obscureConfirmPassword;
                                            });
                                          },
                                    icon: Icon(
                                      _obscureConfirmPassword
                                          ? Icons.visibility_outlined
                                          : Icons.visibility_off_outlined,
                                      color: _muted,
                                    ),
                                  ),
                                ),
                                validator: _validateConfirmPassword,
                                onFieldSubmitted: (_) {
                                  if (!isLoading) _handleRegister();
                                },
                              ),
                              const SizedBox(height: 22),
                              _buildPrivacyNotice(isLoading),
                              const SizedBox(height: 22),
                              SizedBox(
                                height: 55,
                                child: FilledButton(
                                  onPressed: isLoading
                                      ? null
                                      : _handleRegister,
                                  style: FilledButton.styleFrom(
                                    backgroundColor: _green,
                                    disabledBackgroundColor:
                                        const Color(0xFF9BCBA9),
                                    foregroundColor: Colors.white,
                                    elevation: 0,
                                    shape: RoundedRectangleBorder(
                                      borderRadius:
                                          BorderRadius.circular(16),
                                    ),
                                  ),
                                  child: isLoading
                                      ? const SizedBox(
                                          width: 23,
                                          height: 23,
                                          child:
                                              CircularProgressIndicator(
                                            color: Colors.white,
                                            strokeWidth: 2.3,
                                          ),
                                        )
                                      : const Row(
                                          mainAxisAlignment:
                                              MainAxisAlignment.center,
                                          children: [
                                            Flexible(
                                              child: Text(
                                                'Criar conta FARCLIK',
                                                overflow:
                                                    TextOverflow.ellipsis,
                                                style: TextStyle(
                                                  fontSize: 15,
                                                  fontWeight:
                                                      FontWeight.w800,
                                                ),
                                              ),
                                            ),
                                            SizedBox(width: 9),
                                            Icon(
                                              Icons.arrow_forward_rounded,
                                              size: 20,
                                            ),
                                          ],
                                        ),
                                ),
                              ),
                            ],
                          ),
                        ),
                        const SizedBox(height: 19),
                        Row(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            const Flexible(
                              child: Text(
                                'Já tem uma conta?',
                                style: TextStyle(
                                  color: _muted,
                                  fontSize: 13,
                                ),
                              ),
                            ),
                            TextButton(
                              onPressed: isLoading
                                  ? null
                                  : () => context.go('/login'),
                              child: const Text(
                                'Iniciar sessão',
                                style: TextStyle(
                                  color: _darkGreen,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w800,
                                ),
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        const Text(
                          'FARCLIK · Farmácias e Medicamentos em Angola',
                          textAlign: TextAlign.center,
                          style: TextStyle(
                            color: Color(0xFF7A8C95),
                            fontSize: 10.5,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ],
                    ),
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
