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

  @override
  void dispose() {
    _emailController.dispose();
    _passwordController.dispose();
    super.dispose();
  }

  void _handleLogin() async {
    final email = _emailController.text.trim();
    final password = _passwordController.text.trim();

    if (email.isEmpty || password.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Por favor, insira o e-mail e a palavra-passe.')),
      );
      return;
    }

    final success = await ref.read(authProvider.notifier).login(email, password);

    if (success && mounted) {
      final user = ref.read(authProvider).user;
      if (user?.role == 'pharmacy' || _isPharmacyAccount) {
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
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => context.go('/welcome'),
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                _isPharmacyAccount ? 'Acesso Farmacêutico 🏥' : 'Bem-vindo de volta 👋',
                style: const TextStyle(
                  fontSize: 28,
                  fontWeight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                _isPharmacyAccount
                    ? 'Aceda ao Painel de Gestão da sua Farmácia para gerir stock, reservas e receitas.'
                    : 'Insira as suas credenciais para aceder às suas reservas de medicamentos.',
                style: const TextStyle(
                  color: AppColors.textSecondaryLight,
                  fontSize: 14,
                ),
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
                    label: Text('Gestor de Farmácia'),
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
              const SizedBox(height: 24),
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
              TextField(
                controller: _emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: const InputDecoration(
                  labelText: 'E-mail',
                  prefixIcon: Icon(Icons.email_outlined),
                ),
              ),
              const SizedBox(height: 16),
              TextField(
                controller: _passwordController,
                obscureText: true,
                decoration: const InputDecoration(
                  labelText: 'Palavra-passe',
                  prefixIcon: Icon(Icons.lock_outline),
                ),
              ),
              Align(
                alignment: Alignment.centerRight,
                child: TextButton(
                  onPressed: () => context.go('/forgot-password'),
                  child: const Text(
                    'Esqueceu a palavra-passe?',
                    style: TextStyle(
                      color: AppColors.primary,
                      fontSize: 13,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ),
              ),
              const SizedBox(height: 16),
              FilledButton(
                onPressed: authState.isLoading ? null : _handleLogin,
                child: authState.isLoading
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Text('Entrar na Conta'),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  const Text('Não tem uma conta? '),
                  GestureDetector(
                    onTap: () => context.go('/register'),
                    child: const Text(
                      'Registar',
                      style: TextStyle(
                        color: AppColors.primary,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 24),
              const Divider(),
              const SizedBox(height: 12),
              Text(
                '🔒 Autenticação Real Supabase',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.bold,
                  color: Colors.grey.shade700,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                'Pode criar uma nova conta no botão "Registar" acima ou utilizar credenciais de teste para preenchimento rápido:',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 11,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                alignment: WrapAlignment.center,
                spacing: 8,
                runSpacing: 8,
                children: [
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.person_outline, size: 16),
                    label: const Text('Cliente Teste', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() {
                        _isPharmacyAccount = false;
                        _emailController.text = 'cliente.farmaja@gmail.com';
                        _passwordController.text = '123456';
                      });
                    },
                  ),
                  OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                    ),
                    icon: const Icon(Icons.storefront_outlined, size: 16),
                    label: const Text('Farmácia Teste', style: TextStyle(fontSize: 12)),
                    onPressed: () {
                      setState(() {
                        _isPharmacyAccount = true;
                        _emailController.text = 'farmacia.mecofarma@farmaja.ao';
                        _passwordController.text = '123456';
                      });
                    },
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
