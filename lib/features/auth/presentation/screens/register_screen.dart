
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
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
  static const Color _background = Colors.white;
  static const Color _muted = Color(0xFF687984);

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

    if (!RegExp(r'^[^@\s]+@[^@\s]+\.[^@\s]+$')
        .hasMatch(email)) {
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
        vertical: 17,
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
        borderSide:
            const BorderSide(color: Color(0xFFE0EAE4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide:
            const BorderSide(color: Color(0xFFE0EAE4)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide:
            const BorderSide(color: _green, width: 1.6),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide:
            const BorderSide(color: Color(0xFFDC2626)),
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
            'Leia e confirme a informação de privacidade '
            'para continuar.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    setState(() => _submitted = true);

    try {
      final success =
          await ref.read(authProvider.notifier).register(
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
                  'Não foi possível criar a conta. '
                      'Tente novamente.',
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

      // O Supabase pode exigir confirmação do email
      // antes de permitir o início de sessão.
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
                onPressed: () =>
                    Navigator.of(dialogContext).pop(),
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
  }) {
    return Column(
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
    );
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);
    final isLoading = _submitted || authState.isLoading;

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior:
              ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
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
                      backgroundColor: const Color(0xFFF5F9F6),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(14),
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 10),
                Center(
                  child: Container(
                    width: 94,
                    height: 94,
                    padding: const EdgeInsets.all(9),
                    decoration: BoxDecoration(
                      color: Colors.white,
                      borderRadius: BorderRadius.circular(26),
                      boxShadow: [
                        BoxShadow(
                          color: _green.withOpacity(0.09),
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
                          size: 53,
                        );
                      },
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Crie a sua conta',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _navy,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),
                const SizedBox(height: 9),
                const Text(
                  'Encontre farmácias, compare preços, '
                  'consulte medicamentos e faça reservas '
                  'de forma simples.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: _muted,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),
                const SizedBox(height: 28),
                _sectionTitle(
                  'Os seus dados',
                  subtitle:
                      'Preencha os campos para criar a sua conta.',
                ),
                const SizedBox(height: 14),
                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  enabled: !isLoading,
                  decoration: _decoration(
                    label: 'Nome completo *',
                    icon: Icons.person_outline_rounded,
                  ),
                  validator: (value) =>
                      _requiredValidator(value, 'o nome completo'),
                ),
                const SizedBox(height: 16),
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
                const SizedBox(height: 16),
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
                const SizedBox(height: 24),
                _sectionTitle(
                  'Segurança da conta',
                  subtitle:
                      'Utilize pelo menos 6 caracteres e '
                      'repita a palavra-passe para confirmar.',
                ),
                const SizedBox(height: 14),
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
                const SizedBox(height: 16),
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
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF6EF),
                    borderRadius: BorderRadius.circular(15),
                    border: Border.all(
                      color: const Color(0xFFD6EBDD),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.shield_outlined,
                        color: _teal,
                        size: 23,
                      ),
                      const SizedBox(width: 11),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Privacidade e proteção de dados',
                              style: TextStyle(
                                color: _navy,
                                fontSize: 13,
                                fontWeight: FontWeight.w800,
                              ),
                            ),
                            const SizedBox(height: 5),
                            const Text(
                              'Utilizamos os dados fornecidos para '
                              'gerir a sua conta e disponibilizar '
                              'as funcionalidades autorizadas. '
                              'A localização será tratada separadamente '
                              'e dependerá das suas escolhas.',
                              style: TextStyle(
                                color: Color(0xFF58716A),
                                fontSize: 12,
                                height: 1.5,
                              ),
                            ),
                            const SizedBox(height: 8),
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity:
                                  ListTileControlAffinity.leading,
                              dense: true,
                              visualDensity:
                                  VisualDensity.compact,
                              activeColor: _green,
                              value: _acceptedPrivacy,
                              onChanged: isLoading
                                  ? null
                                  : (value) {
                                      setState(() {
                                        _acceptedPrivacy =
                                            value ?? false;
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
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 22),
                SizedBox(
                  height: 55,
                  child: FilledButton(
                    onPressed:
                        isLoading ? null : _handleRegister,
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      disabledBackgroundColor:
                          const Color(0xFF9BCBA9),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                    child: isLoading
                        ? const SizedBox(
                            width: 23,
                            height: 23,
                            child: CircularProgressIndicator(
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
                                  overflow: TextOverflow.ellipsis,
                                  style: TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
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
                const SizedBox(height: 15),
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
  }
}
