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
  final _fullNameController = TextEditingController();
  final _emailController = TextEditingController();
  final _phoneController = TextEditingController();
  final _passwordController = TextEditingController();
  final _pharmacyNameController = TextEditingController();
  String _selectedProvince = 'Luanda';
  final _districtController = TextEditingController(text: 'Talatona');
  bool _isPharmacyAccount = false;

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

  void _handleRegister() async {
    final fullName = _fullNameController.text.trim();
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();
    final phone = _phoneController.text.trim();
    final district = _districtController.text.trim();
    final pharmacyName = _pharmacyNameController.text.trim();

    if (fullName.isEmpty || email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, preencha o nome, e-mail e palavra-passe.')),
      );
      return;
    }

    if (_isPharmacyAccount && pharmacyName.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira o nome da farmácia.')),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).register(
          fullName: fullName,
          email: email,
          password: password,
          phone: phone.isEmpty ? '+244 923 000 000' : phone,
          province: _selectedProvince,
          district: district.isEmpty ? 'Talatona' : district,
          role: _isPharmacyAccount ? 'pharmacy' : 'customer',
          pharmacyName: _isPharmacyAccount ? pharmacyName : null,
        );

    if (success && mounted) {
      if (_isPharmacyAccount) {
        context.go('/pharmacy-dashboard');
      } else {
        context.go('/home');
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authState = ref.watch(authProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Criar Conta FarmaJá 🇦🇴'),
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/login'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isPharmacyAccount ? 'Registo de Farmácia 🏥' : 'Registo de Utente 👤',
                style: const TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                _isPharmacyAccount
                    ? 'Registe a sua farmácia para gerir stock, receber encomendas e validar receitas.'
                    : 'Crie a sua conta de cliente para reservar medicamentos em farmácias angolanas.',
                style: const TextStyle(color: AppColors.textSecondaryLight, fontSize: 13),
              ),
              const SizedBox(height: 20),

              // Account Type Selector
              SegmentedButton<bool>(
                segments: const [
                  ButtonSegment(
                    value: false,
                    label: Text('Cliente / Utente'),
                    icon: Icon(Icons.person_rounded),
                  ),
                  ButtonSegment(
                    value: true,
                    label: Text('Farmácia'),
                    icon: Icon(Icons.storefront_rounded),
                  ),
                ],
                selected: {_isPharmacyAccount},
                onSelectionChanged: (set) {
                  setState(() {
                    _isPharmacyAccount = set.first;
                  });
                },
              ),
              const SizedBox(height: 20),

              if (authState.error != null)
                Container(
                  padding: const EdgeInsets.all(12),
                  margin: const EdgeInsets.only(bottom: 20),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.red.shade200),
                  ),
                  child: Text(
                    authState.error!,
                    style: const TextStyle(color: Colors.red, fontSize: 13),
                  ),
                ),

              if (_isPharmacyAccount) ...[
                TextField(
                  controller: _pharmacyNameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome Oficial da Farmácia *',
                    hintText: 'Ex: Farmácia Sagrada Esperança',
                    prefixIcon: Icon(Icons.local_pharmacy_rounded),
                  ),
                ),
                const SizedBox(height: 16),
              ],

              TextField(
                controller: _fullNameController,
                decoration: InputDecoration(
                  labelText: _isPharmacyAccount ? 'Nome do Gestor / Responsável *' : 'Nome Completo *',
                  prefixIcon: const Icon(Icons.person_outline),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail *',
                  hintText: 'exemplo@farmaja.ao',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _phoneController,
                keyboardType: TextInputType.phone,
                decoration: const InputDecoration(
                  labelText: 'Nº Telefone / WhatsApp (+244) *',
                  hintText: '+244 923 123 456',
                  prefixIcon: Icon(Icons.phone_outlined),
                ),
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: DropdownButtonFormField<String>(
                      value: _selectedProvince,
                      decoration: const InputDecoration(
                        labelText: 'Província',
                        prefixIcon: Icon(Icons.location_on_outlined),
                      ),
                      items: AppConstants.angolaProvinces.map((prov) {
                        return DropdownMenuItem(value: prov, child: Text(prov));
                      }).toList(),
                      onChanged: (val) {
                        if (val != null) setState(() => _selectedProvince = val);
                      },
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextField(
                      controller: _districtController,
                      decoration: const InputDecoration(
                        labelText: 'Município',
                        hintText: 'Ex: Talatona',
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Palavra-passe (mínimo 6 caracteres) *',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              const SizedBox(height: 24),

              FilledButton(
                onPressed: authState.isLoading ? null : _handleRegister,
                child: authState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : Text(_isPharmacyAccount ? 'Registar Conta de Farmácia' : 'Registar Conta de Cliente'),
              ),
              const SizedBox(height: 16),

              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Já tem uma conta? '),
                  GestureDetector(
                    onTap: () => context.go('/login'),
                    child: const Text(
                      'Iniciar Sessão',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
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
