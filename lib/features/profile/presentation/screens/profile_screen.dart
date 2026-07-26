import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final user = ref.watch(authProvider).user;

    if (user == null) {
      return Scaffold(
        appBar: AppBar(title: const Text('Perfil do Utilizador')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(Icons.account_circle_outlined, size: 80, color: Colors.grey),
                const SizedBox(height: 16),
                const Text(
                  'Nenhum utilizador com sessão iniciada',
                  style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Inicie sessão com a sua conta Supabase para ver o seu perfil e gerir as suas reservas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: Colors.grey),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Iniciar Sessão'),
                  onPressed: () => context.go('/login'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isPharmacy = user.role == 'pharmacy';
    final initials = user.fullName.trim().isNotEmpty
        ? user.fullName.trim().split(' ').map((e) => e[0]).take(2).join().toUpperCase()
        : 'FJ';

    return Scaffold(
      appBar: AppBar(
        title: const Text('Perfil do Utilizador'),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20.0),
        child: Column(
          children: [
            CircleAvatar(
              radius: 40,
              backgroundColor: isPharmacy ? Colors.teal : AppColors.primary,
              child: Text(
                initials,
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 24,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
            const SizedBox(height: 12),
            Text(
              user.fullName,
              style: const TextStyle(fontSize: 22, fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 4),
            Text(
              user.email,
              style: const TextStyle(color: Colors.grey, fontSize: 14),
            ),
            const SizedBox(height: 8),
            Chip(
              avatar: Icon(
                isPharmacy ? Icons.storefront_rounded : Icons.person_rounded,
                size: 16,
                color: isPharmacy ? Colors.teal.shade800 : AppColors.primaryDark,
              ),
              label: Text(
                isPharmacy
                    ? 'Conta de Farmácia (${user.pharmacyName ?? 'Farmácia Registada'})'
                    : 'Conta de Utente / Cliente',
                style: TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: isPharmacy ? Colors.teal.shade900 : AppColors.primaryDark,
                ),
              ),
              backgroundColor: isPharmacy ? Colors.teal.shade50 : AppColors.primaryLight,
            ),
            const SizedBox(height: 20),

            Card(
              child: Column(
                children: [
                  ListTile(
                    leading: const Icon(Icons.email_outlined, color: AppColors.primary),
                    title: const Text('E-mail Supabase'),
                    subtitle: Text(user.email),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.phone_outlined, color: AppColors.primary),
                    title: const Text('Telefone (+244)'),
                    subtitle: Text(user.phone),
                  ),
                  const Divider(height: 1),
                  ListTile(
                    leading: const Icon(Icons.location_on_outlined, color: AppColors.primary),
                    title: const Text('Localização'),
                    subtitle: Text('${user.province}, ${user.district}'),
                  ),
                  if (user.insuranceProvider != null) ...[
                    const Divider(height: 1),
                    ListTile(
                      leading: const Icon(Icons.health_and_safety_outlined, color: AppColors.primary),
                      title: const Text('Seguro de Saúde'),
                      subtitle: Text(user.insuranceProvider!),
                    ),
                  ],
                ],
              ),
            ),
            const SizedBox(height: 16),

            // Pharmacy Manager Access Card
            Card(
              color: AppColors.primaryLight,
              child: ListTile(
                leading: const Icon(Icons.storefront_rounded, color: AppColors.primaryDark, size: 28),
                title: const Text(
                  'Painel de Gestão da Farmácia',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                ),
                subtitle: const Text(
                  'Gerir stock, alterar preços, aprovar receitas e validar QR Codes.',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryDark),
                onTap: () {
                  context.push('/pharmacy-dashboard');
                },
              ),
            ),
            const SizedBox(height: 12),

            // Admin Subscriptions Card
            Card(
              child: ListTile(
                leading: const Icon(Icons.admin_panel_settings_rounded, color: Colors.blue, size: 28),
                title: const Text(
                  'Gestão de Subscrições (Admin)',
                  style: TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                ),
                subtitle: const Text(
                  'Aprovar mensalidades de 15.000 Kz e gerir licenças de 3 meses.',
                  style: TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.chevron_right_rounded, color: AppColors.primaryDark),
                onTap: () {
                  context.push('/admin/subscriptions');
                },
              ),
            ),

            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                style: OutlinedButton.styleFrom(
                  side: const BorderSide(color: Colors.red),
                  padding: const EdgeInsets.symmetric(vertical: 14),
                ),
                icon: const Icon(Icons.logout, color: Colors.red),
                label: const Text(
                  'Sair da Conta (Logout)',
                  style: TextStyle(color: Colors.red, fontWeight: FontWeight.bold),
                ),
                onPressed: () async {
                  await ref.read(authProvider.notifier).logout();
                  if (context.mounted) {
                    context.go('/login');
                  }
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}
