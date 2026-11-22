
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';

import '../providers/auth_provider.dart';

class RegisterScreen extends ConsumerStatefulWidget {
  const RegisterScreen({super.key});

  @override
  ConsumerState<RegisterScreen> createState() => _RegisterScreenState();
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

  static const String _pharmacistImage =
      'assets/images/Esmy foto.jpg';
  static const String _pharmacyImage =
      'assets/images/farmacia_destaquec.jpg';
  static const String _healthImage =
      'assets/images/Ilustração_3d_saude.jpg';

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _confirmPasswordController.dispose();
    super.dispose();
  }

  String? _requiredValidator(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório';
    }
    return null;
  }

  String? _validateEmail(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Introduza o seu email';
    }

    final emailRegex = RegExp(
      r'^[\w\.\-]+@([\w\-]+\.)+[a-zA-Z]{2,}$',
    );

    if (!emailRegex.hasMatch(value.trim())) {
      return 'Introduza um email válido';
    }

    return null;
  }

  String? _validatePhone(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Introduza o seu número de telefone';
    }

    final digits = value.replaceAll(RegExp(r'\D'), '');

    if (digits.length < 9 || digits.length > 15) {
      return 'Introduza um número válido';
    }

    return null;
  }

  String? _validatePassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Introduza uma palavra-passe';
    }

    if (value.length < 6) {
      return 'A palavra-passe deve ter pelo menos 6 caracteres';
    }

    return null;
  }

  String? _validateConfirmPassword(String? value) {
    if (value == null || value.isEmpty) {
      return 'Confirme a sua palavra-passe';
    }

    if (value != _passwordController.text) {
      return 'As palavras-passe não coincidem';
    }

    return null;
  }

  InputDecoration _decoration({
    required String label,
    required IconData icon,
    String? hint,
    Widget? suffix,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: _teal, size: 21),
      suffixIcon: suffix,
      filled: true,
      fillColor: _surface,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 18,
      ),
      labelStyle: const TextStyle(
        color: _muted,
        fontSize: 13,
        fontWeight: FontWeight.w600,
      ),
      hintStyle: const TextStyle(
        color: Color(0xFF9AA8A0),
        fontSize: 13,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: _border),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: _green,
          width: 1.6,
        ),
      ),
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(16),
        borderSide: const BorderSide(
          color: Colors.redAccent,
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
            'Deve aceitar a política de privacidade para continuar.',
          ),
          backgroundColor: Colors.redAccent,
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

      final authState = ref.read(authProvider);

      if (!success) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              authState.error ?? 'Não foi possível criar a conta.',
            ),
            backgroundColor: Colors.redAccent,
          ),
        );
        return;
      }

      if (authState.user != null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Conta criada com sucesso!'),
            backgroundColor: _green,
          ),
        );

        context.go('/home');
      } else {
        await showDialog<void>(
          context: context,
          barrierDismissible: false,
          builder: (dialogContext) {
            return AlertDialog(
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(22),
              ),
              icon: const Icon(
                Icons.mark_email_read_rounded,
                color: _green,
                size: 48,
              ),
              title: const Text('Confirme o seu email'),
              content: const Text(
                'Enviámos uma mensagem para o seu endereço de email. '
                'Confirme o endereço para activar a sua conta.',
                textAlign: TextAlign.center,
              ),
              actions: [
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      foregroundColor: Colors.white,
                    ),
                    onPressed: () {
                      Navigator.of(dialogContext).pop();
                    },
                    child: const Text('Compreendi'),
                  ),
                ),
              ],
            );
          },
        );

        if (!mounted) return;
        context.go('/login');
      }
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Erro ao criar conta: $e'),
          backgroundColor: Colors.redAccent,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _submitted = false);
      }
    }
  }

  Widget _buildLogo() {
    return Image.asset(
      'FARCLIK_logo.png',
      height: 66,
      fit: BoxFit.contain,
      errorBuilder: (_, __, ___) => const SizedBox.shrink(),
    );
  }

  Widget _buildSectionTitle(String title, String subtitle) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: _navy,
          ),
        ),
        const SizedBox(height: 5),
        Text(
          subtitle,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            color: _muted,
          ),
        ),
      ],
    );
  }

  Widget _buildPasswordField({
    required String label,
    required TextEditingController controller,
    required bool obscure,
    required VoidCallback onToggle,
    required String? Function(String?) validator,
    required bool isLoading,
  }) {
    return TextFormField(
      controller: controller,
      obscureText: obscure,
      enabled: !isLoading,
      validator: validator,
      decoration: _decoration(
        label: label,
        icon: Icons.lock_outline_rounded,
        suffix: IconButton(
          onPressed: isLoading ? null : onToggle,
          icon: Icon(
            obscure
                ? Icons.visibility_off_outlined
                : Icons.visibility_outlined,
            color: _muted,
            size: 20,
          ),
        ),
      ),
    );
  }

  Widget _buildImageFeature({
    required String image,
    required String title,
    required String description,
    required IconData fallbackIcon,
  }) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          ClipRRect(
            borderRadius: BorderRadius.circular(13),
            child: Image.asset(
              image,
              width: 62,
              height: 62,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => Container(
                width: 62,
                height: 62,
                color: const Color(0xFFEAF5EE),
                child: Icon(
                  fallbackIcon,
                  color: _green,
                  size: 27,
                ),
              ),
            ),
          ),
          const SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: GoogleFonts.plusJakartaSans(
                    color: _navy,
                    fontSize: 12,
                    fontWeight: FontWeight.w800,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  description,
                  style: GoogleFonts.plusJakartaSans(
                    color: _muted,
                    fontSize: 10,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVisualBenefits() {
    return Column(
      children: [
        _buildImageFeature(
          image: _pharmacyImage,
          title: 'Farmácias de confiança',
          description: 'Encontre farmácias e consulte informações.',
          fallbackIcon: Icons.local_pharmacy_outlined,
        ),
        const SizedBox(height: 10),
        _buildImageFeature(
          image: _healthImage,
          title: 'Cuidados de saúde',
          description: 'Aceda a medicamentos e serviços de saúde.',
          fallbackIcon: Icons.health_and_safety_outlined,
        ),
      ],
    );
  }

  Widget _buildPrivacyNotice() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9F2),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: _green.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Icons.verified_user_outlined,
            color: _darkGreen,
            size: 21,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Os seus dados pessoais são tratados com confidencialidade '
              'e utilizados para gerir a sua conta FARCLIK.',
              style: GoogleFonts.plusJakartaSans(
                fontSize: 11,
                height: 1.5,
                color: _navy,
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
    final isLoading = authState.isLoading || _submitted;

    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        textTheme: GoogleFonts.plusJakartaSansTextTheme(
          theme.textTheme,
        ),
        colorScheme: theme.colorScheme.copyWith(
          primary: _green,
          secondary: _teal,
        ),
      ),
      child: Scaffold(
        backgroundColor: Colors.white,
        body: SafeArea(
          child: SingleChildScrollView(
            padding: const EdgeInsets.fromLTRB(22, 18, 22, 30),
            child: Form(
              key: _formKey,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Center(child: _buildLogo()),
                  const SizedBox(height: 22),

                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(20),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [
                          Color(0xFFF0FAF3),
                          Color(0xFFEAF8F5),
                        ],
                        begin: Alignment.topLeft,
                        end: Alignment.bottomRight,
                      ),
                      borderRadius: BorderRadius.circular(24),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 11,
                            vertical: 6,
                          ),
                          decoration: BoxDecoration(
                            color: Colors.white,
                            borderRadius: BorderRadius.circular(30),
                          ),
                          child: Text(
                            'JUNTE-SE À FARCLIK',
                            style: GoogleFonts.plusJakartaSans(
                              color: _darkGreen,
                              fontSize: 9,
                              fontWeight: FontWeight.w800,
                              letterSpacing: 1,
                            ),
                          ),
                        ),
                        const SizedBox(height: 13),
                        Text(
                          'Crie a sua conta',
                          style: GoogleFonts.plusJakartaSans(
                            color: _navy,
                            fontSize: 25,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          'Aceda a farmácias e medicamentos de forma '
                          'simples e conveniente.',
                          style: GoogleFonts.plusJakartaSans(
                            color: _muted,
                            fontSize: 12,
                            height: 1.5,
                          ),
                        ),
                      ],
                    ),
                  ).animate().fadeIn(
                        duration: 450.ms,
                      ).slideY(
                        begin: 0.08,
                        end: 0,
                      ),

                  const SizedBox(height: 20),

                  _buildImageFeature(
                    image: _pharmacistImage,
                    title: 'Saúde mais próxima de si',
                    description:
                        'Uma experiência digital para facilitar '
                        'o acesso aos serviços farmacêuticos.',
                    fallbackIcon: Icons.person_outline_rounded,
                  ).animate().fadeIn(
                        delay: 100.ms,
                      ).slideX(
                        begin: 0.05,
                        end: 0,
                      ),

                  const SizedBox(height: 26),

                  _buildSectionTitle(
                    'Dados pessoais',
                    'Preencha os seus dados para criar a sua conta.',
                  ),

                  const SizedBox(height: 16),

                  TextFormField(
                    controller: _fullNameController,
                    enabled: !isLoading,
                    textCapitalization: TextCapitalization.words,
                    textInputAction: TextInputAction.next,
                    validator: _requiredValidator,
                    decoration: _decoration(
                      label: 'Nome completo',
                      hint: 'Introduza o seu nome completo',
                      icon: Icons.person_outline_rounded,
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _emailController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.emailAddress,
                    textInputAction: TextInputAction.next,
                    validator: _validateEmail,
                    decoration: _decoration(
                      label: 'Endereço de email',
                      hint: 'exemplo@email.com',
                      icon: Icons.email_outlined,
                    ),
                  ),

                  const SizedBox(height: 14),

                  TextFormField(
                    controller: _phoneController,
                    enabled: !isLoading,
                    keyboardType: TextInputType.phone,
                    textInputAction: TextInputAction.next,
                    validator: _validatePhone,
                    decoration: _decoration(
                      label: 'Número de telefone',
                      hint: 'Ex.: 923 000 000',
                      icon: Icons.phone_outlined,
                    ),
                  ),

                  const SizedBox(height: 14),

                  _buildPasswordField(
                    label: 'Palavra-passe',
                    controller: _passwordController,
                    obscure: _obscurePassword,
                    onToggle: () {
                      setState(() {
                        _obscurePassword = !_obscurePassword;
                      });
                    },
                    validator: _validatePassword,
                    isLoading: isLoading,
                  ),

                  const SizedBox(height: 14),

                  _buildPasswordField(
                    label: 'Confirmar palavra-passe',
                    controller: _confirmPasswordController,
                    obscure: _obscureConfirmPassword,
                    onToggle: () {
                      setState(() {
                        _obscureConfirmPassword =
                            !_obscureConfirmPassword;
                      });
                    },
                    validator: _validateConfirmPassword,
                    isLoading: isLoading,
                  ),

                  const SizedBox(height: 18),

                  CheckboxListTile(
                    value: _acceptedPrivacy,
                    onChanged: isLoading
                        ? null
                        : (value) {
                            setState(() {
                              _acceptedPrivacy = value ?? false;
                            });
                          },
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: _green,
                    title: RichText(
                      text: const TextSpan(
                        style: TextStyle(
                          color: _muted,
                          fontSize: 11,
                          height: 1.5,
                        ),
                        children: [
                          TextSpan(
                            text: 'Li e aceito a ',
                          ),
                          TextSpan(
                            text: 'Política de Privacidade',
                            style: TextStyle(
                              color: _darkGreen,
                              fontWeight: FontWeight.w800,
                            ),
                          ),
                          TextSpan(
                            text: ' e os termos de utilização.',
                          ),
                        ],
                      ),
                    ),
                  ),

                  const SizedBox(height: 8),

                  _buildPrivacyNotice(),

                  const SizedBox(height: 22),

                  SizedBox(
                    width: double.infinity,
                    height: 55,
                    child: FilledButton(
                      onPressed: isLoading ? null : _handleRegister,
                      style: FilledButton.styleFrom(
                        backgroundColor: _green,
                        foregroundColor: Colors.white,
                        disabledBackgroundColor:
                            _green.withValues(alpha: 0.55),
                        elevation: 0,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                      ),
                      child: isLoading
                          ? const SizedBox(
                              width: 22,
                              height: 22,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2.2,
                              ),
                            )
                          : Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  'Criar conta',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 14,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                                const SizedBox(width: 9),
                                const Icon(
                                  Icons.arrow_forward_rounded,
                                  size: 19,
                                ),
                              ],
                            ),
                    ),
                  ).animate().fadeIn(
                        delay: 200.ms,
                      ).slideY(
                        begin: 0.08,
                        end: 0,
                      ),

                  const SizedBox(height: 22),

                  Center(
                    child: Wrap(
                      alignment: WrapAlignment.center,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      children: [
                        Text(
                          'Já tem uma conta? ',
                          style: GoogleFonts.plusJakartaSans(
                            color: _muted,
                            fontSize: 12,
                          ),
                        ),
                        TextButton(
                          onPressed: isLoading
                              ? null
                              : () => context.go('/login'),
                          child: Text(
                            'Iniciar sessão',
                            style: GoogleFonts.plusJakartaSans(
                              color: _darkGreen,
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 12),

                  _buildVisualBenefits(),

                  const SizedBox(height: 24),

                  Center(
                    child: Text(
                      'FARCLIK · A SUA SAÚDE A UM CLIK',
                      textAlign: TextAlign.center,
                      style: GoogleFonts.plusJakartaSans(
                        color: _muted,
                        fontSize: 9,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.6,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
