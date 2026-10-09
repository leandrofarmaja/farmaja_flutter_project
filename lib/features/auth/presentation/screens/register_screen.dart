import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
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
  final _pharmacyNameController = TextEditingController();
  final _districtController = TextEditingController();

  String _selectedProvince = 'Luanda';

  bool _isPharmacyAccount = false;
  bool _obscurePassword = true;
  bool _acceptedPrivacy = false;

  static const Color _green = Color(0xFF16A34A);
  static const Color _darkGreen = Color(0xFF15803D);
  static const Color _teal = Color(0xFF0F766E);
  static const Color _navy = Color(0xFF173B57);
  static const Color _background = Color(0xFFF8FBF9);
  static const Color _muted = Color(0xFF687984);

  @override
  void dispose() {
    _fullNameController.dispose();
    _emailController.dispose();
    _phoneController.dispose();
    _passwordController.dispose();
    _pharmacyNameController.dispose();
    _districtController.dispose();
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
        borderSide: const BorderSide(color: Color(0xFFE0EAE4)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(15),
        borderSide: const BorderSide(color: Color(0xFFE0EAE4)),
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
    FocusScope.of(context).unfocus();

    if (!_formKey.currentState!.validate()) {
      return;
    }

    if (!_acceptedPrivacy) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Confirme que leu a informação de privacidade para continuar.',
          ),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text;
    final phone = _phoneController.text.trim();
    final district = _districtController.text.trim();
    final pharmacyName = _pharmacyNameController.text.trim();

    if (_isPharmacyAccount && pharmacyName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Introduza o nome oficial da farmácia.'),
          behavior: SnackBarBehavior.floating,
        ),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
          fullName: fullName,
          email: email,
          password: password,
          phone: phone,
          province: _selectedProvince,
          district: district,
          role: _isPharmacyAccount ? 'pharmacy' : 'customer',
          pharmacyName: _isPharmacyAccount ? pharmacyName : null,
        );

    if (!mounted) return;

    if (success) {
      if (_isPharmacyAccount) {
        // O backend deve controlar a aprovação e as permissões
        // da farmácia antes de autorizar o acesso ao painel.
        context.go('/login');
      } else {
        context.go('/home');
      }
    }
  }

  Widget _sectionTitle(String title, {String? subtitle}) {
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

    return Scaffold(
      backgroundColor: _background,
      body: SafeArea(
        child: SingleChildScrollView(
          keyboardDismissBehavior: ScrollViewKeyboardDismissBehavior.onDrag,
          padding: const EdgeInsets.fromLTRB(22, 12, 22, 30),
          child: Form(
            key: _formKey,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Align(
                  alignment: Alignment.centerLeft,
                  child: IconButton(
                    onPressed: () => context.go('/login'),
                    tooltip: 'Voltar ao início de sessão',
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

                Text(
                  _isPharmacyAccount
                      ? 'Registe a sua farmácia'
                      : 'Crie a sua conta',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _navy,
                    fontSize: 27,
                    fontWeight: FontWeight.w800,
                    letterSpacing: -0.6,
                  ),
                ),

                const SizedBox(height: 9),

                Text(
                  _isPharmacyAccount
                      ? 'Inicie o processo de adesão à FARCLIK. '
                          'O registo está sujeito à verificação da documentação.'
                      : 'Encontre farmácias, consulte medicamentos '
                          'e faça reservas de forma simples.',
                  textAlign: TextAlign.center,
                  style: const TextStyle(
                    color: _muted,
                    fontSize: 13,
                    height: 1.6,
                  ),
                ),

                const SizedBox(height: 24),

                Container(
                  padding: const EdgeInsets.all(5),
                  decoration: BoxDecoration(
                    color: const Color(0xFFEAF2ED),
                    borderRadius: BorderRadius.circular(16),
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

                const SizedBox(height: 26),

                if (_isPharmacyAccount) ...[
                  _sectionTitle(
                    'Dados da farmácia',
                    subtitle: 'Identificação inicial do estabelecimento.',
                  ),
                  const SizedBox(height: 14),
                  TextFormField(
                    controller: _pharmacyNameController,
                    textCapitalization: TextCapitalization.words,
                    decoration: _decoration(
                      label: 'Nome oficial da farmácia *',
                      hint: 'Nome registado do estabelecimento',
                      icon: Icons.local_pharmacy_outlined,
                    ),
                    validator: (value) {
                      if (!_isPharmacyAccount) return null;
                      return _requiredValidator(
                        value,
                        'o nome da farmácia',
                      );
                    },
                  ),
                  const SizedBox(height: 22),
                ],

                _sectionTitle(
                  _isPharmacyAccount
                      ? 'Dados do responsável'
                      : 'Os seus dados',
                  subtitle: 'Preencha os campos abaixo para continuar.',
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _fullNameController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: _decoration(
                    label: _isPharmacyAccount
                        ? 'Nome do responsável *'
                        : 'Nome completo *',
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
                  decoration: _decoration(
                    label: 'Telefone / WhatsApp *',
                    hint: '+244 923 123 456',
                    icon: Icons.phone_outlined,
                  ),
                  validator: _validatePhone,
                ),

                const SizedBox(height: 24),

                _sectionTitle(
                  'Localização',
                  subtitle: 'Indique a província e o município.',
                ),

                const SizedBox(height: 14),

                DropdownButtonFormField<String>(
                  value: _selectedProvince,
                  isExpanded: true,
                  decoration: _decoration(
                    label: 'Província *',
                    icon: Icons.location_on_outlined,
                  ),
                  items: AppConstants.angolaProvinces.map((province) {
                    return DropdownMenuItem<String>(
                      value: province,
                      child: Text(
                        province,
                        overflow: TextOverflow.ellipsis,
                      ),
                    );
                  }).toList(),
                  onChanged: (value) {
                    if (value != null) {
                      setState(() => _selectedProvince = value);
                    }
                  },
                  validator: (value) {
                    if (value == null || value.isEmpty) {
                      return 'Selecione a província.';
                    }
                    return null;
                  },
                ),

                const SizedBox(height: 16),

                TextFormField(
                  controller: _districtController,
                  textCapitalization: TextCapitalization.words,
                  textInputAction: TextInputAction.next,
                  decoration: _decoration(
                    label: 'Município *',
                    hint: 'Ex.: Talatona',
                    icon: Icons.location_city_outlined,
                  ),
                  validator: (value) =>
                      _requiredValidator(value, 'o município'),
                ),

                const SizedBox(height: 24),

                _sectionTitle(
                  'Segurança da conta',
                  subtitle: 'Escolha uma palavra-passe com pelo menos '
                      '6 caracteres.',
                ),

                const SizedBox(height: 14),

                TextFormField(
                  controller: _passwordController,
                  obscureText: _obscurePassword,
                  enableSuggestions: false,
                  autocorrect: false,
                  textInputAction: TextInputAction.done,
                  decoration: _decoration(
                    label: 'Palavra-passe *',
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
                        color: _muted,
                      ),
                    ),
                  ),
                  validator: _validatePassword,
                  onFieldSubmitted: (_) {
                    if (!authState.isLoading) {
                      _handleRegister();
                    }
                  },
                ),

                const SizedBox(height: 22),

                if (authState.error != null) ...[
                  Container(
                    padding: const EdgeInsets.all(13),
                    margin: const EdgeInsets.only(bottom: 17),
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
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            'Não foi possível concluir o registo. '
                            'Verifique os dados e tente novamente.',
                            style: const TextStyle(
                              color: Color(0xFFB42318),
                              fontSize: 13,
                              height: 1.45,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

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
                          crossAxisAlignment: CrossAxisAlignment.start,
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
                              'Utilize dados verdadeiros. As informações '
                              'da conta devem ser tratadas com '
                              'confidencialidade e utilizadas para '
                              'finalidades autorizadas.',
                              style: TextStyle(
                                color: Color(0xFF58716A),
                                fontSize: 12,
                                height: 1.5,
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
                              onChanged: (value) {
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
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 22),

                SizedBox(
                  height: 55,
                  child: FilledButton(
                    onPressed:
                        authState.isLoading ? null : _handleRegister,
                    style: FilledButton.styleFrom(
                      backgroundColor: _green,
                      disabledBackgroundColor: const Color(0xFF9BCBA9),
                      foregroundColor: Colors.white,
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
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
                        : Row(
                            mainAxisAlignment: MainAxisAlignment.center,
                            children: [
                              Flexible(
                                child: Text(
                                  _isPharmacyAccount
                                      ? 'Enviar pedido de adesão'
                                      : 'Criar conta FARCLIK',
                                  overflow: TextOverflow.ellipsis,
                                  style: const TextStyle(
                                    fontSize: 15,
                                    fontWeight: FontWeight.w800,
                                  ),
                                ),
                              ),
                              const SizedBox(width: 9),
                              const Icon(
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
                      onPressed: () => context.go('/login'),
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
          padding: const EdgeInsets.symmetric(
            vertical: 13,
            horizontal: 5,
          ),
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
