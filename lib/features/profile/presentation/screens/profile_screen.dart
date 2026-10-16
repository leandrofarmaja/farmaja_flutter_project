
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const Color _background = Color(0xFFF8FAF9);
  static const Color _text = Color(0xFF17212B);
  static const Color _muted = Color(0xFF748091);
  static const Color _border = Color(0xFFE7ECE9);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          title: const Text('O meu perfil'),
          backgroundColor: Colors.white,
        ),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                const Icon(
                  Icons.account_circle_outlined,
                  size: 76,
                  color: _muted,
                ),
                const SizedBox(height: 16),
                const Text(
                  'Sessão não iniciada',
                  style: TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.w700,
                    color: _text,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Inicie sessão para consultar o seu perfil e as suas reservas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, height: 1.5),
                ),
                const SizedBox(height: 24),
                FilledButton.icon(
                  onPressed: () => context.go('/login'),
                  icon: const Icon(Icons.login_rounded),
                  label: const Text('Iniciar sessão'),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final bool isPharmacy = user.role == 'pharmacy';
    final bool isAdmin = user.role == 'admin';
    final bool isCustomer = !isPharmacy && !isAdmin;

    final String fullName = user.fullName.trim().isNotEmpty
        ? user.fullName.trim()
        : 'Utilizador FARCLIK';

    final String initials = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();

    final Color roleColor = isPharmacy
        ? const Color(0xFF0F766E)
        : isAdmin
            ? const Color(0xFF1D4ED8)
            : AppColors.primaryDark;

    final Color roleBackground = isPharmacy
        ? const Color(0xFFE6F5F2)
        : isAdmin
            ? const Color(0xFFEFF6FF)
            : AppColors.primaryLight;

    final String roleLabel = isPharmacy
        ? 'Conta de Farmácia'
        : isAdmin
            ? 'Conta de Administrador'
            : 'Conta de Cliente';

    return Scaffold(
      backgroundColor: _background,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        title: const Text(
          'O meu perfil',
          style: TextStyle(
            color: _text,
            fontWeight: FontWeight.w700,
            fontSize: 21,
          ),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(20, 24, 20, 28),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Identificação do utilizador
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 20,
                vertical: 26,
              ),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(24),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 42,
                    backgroundColor: roleBackground,
                    child: Text(
                      initials.isEmpty ? 'F' : initials,
                      style: TextStyle(
                        color: roleColor,
                        fontSize: 25,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    fullName,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 22,
                      fontWeight: FontWeight.w800,
                      color: _text,
                    ),
                  ),
                  const SizedBox(height: 6),
                  Text(
                    user.email,
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      color: _muted,
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 9,
                    ),
                    decoration: BoxDecoration(
                      color: roleBackground,
                      borderRadius: BorderRadius.circular(30),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          isPharmacy
                              ? Icons.storefront_rounded
                              : isAdmin
                                  ? Icons.shield_rounded
                                  : Icons.person_rounded,
                          size: 17,
                          color: roleColor,
                        ),
                        const SizedBox(width: 8),
                        Flexible(
                          child: Text(
                            roleLabel,
                            style: TextStyle(
                              color: roleColor,
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            const SizedBox(height: 24),

            const Text(
              'Os meus dados',
              style: TextStyle(
                color: _text,
                fontSize: 17,
                fontWeight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 12),

            Container(
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: _border),
              ),
              child: Column(
                children: [
                  _ProfileInfoTile(
                    icon: Icons.email_outlined,
                    title: 'E-mail',
                    value: user.email,
                  ),
                  const Divider(height: 1, indent: 60),
                  _ProfileInfoTile(
                    icon: Icons.phone_outlined,
                    title: 'Telefone',
                    value: user.phone.trim().isNotEmpty
                        ? user.phone
                        : 'Não indicado',
                  ),
                  const Divider(height: 1, indent: 60),
                  _ProfileInfoTile(
                    icon: Icons.location_on_outlined,
                    title: 'Localização',
                    value: [
                      user.province.trim(),
                      user.district.trim(),
                    ].where((part) => part.isNotEmpty).join(', ').isNotEmpty
                        ? [
                            user.province.trim(),
                            user.district.trim(),
                          ].where((part) => part.isNotEmpty).join(', ')
                        : 'Não indicada',
                  ),
                  if (isCustomer &&
                      user.insuranceProvider != null &&
                      user.insuranceProvider!.trim().isNotEmpty) ...[
                    const Divider(height: 1, indent: 60),
                    _ProfileInfoTile(
                      icon: Icons.health_and_safety_outlined,
                      title: 'Seguro de saúde',
                      value: user.insuranceProvider!,
                    ),
                  ],
                  if (isPharmacy &&
                      (user.pharmacyName?.trim().isNotEmpty ?? false)) ...[
                    const Divider(height: 1, indent: 60),
                    _ProfileInfoTile(
                      icon: Icons.storefront_outlined,
                      title: 'Farmácia',
                      value: user.pharmacyName!,
                    ),
                  ],
                ],
              ),
            ),

            // Acesso exclusivo da farmácia
            if (isPharmacy) ...[
              const SizedBox(height: 24),
              _AccessCard(
                icon: Icons.storefront_rounded,
                title: 'Painel da minha farmácia',
                description:
                    'Gerir medicamentos, preços, stock e reservas autorizadas.',
                color: const Color(0xFF0F766E),
                background: const Color(0xFFE6F5F2),
                onTap: () => context.push('/pharmacy-dashboard'),
              ),
            ],

            // Acesso exclusivo do administrador
            if (isAdmin) ...[
              const SizedBox(height: 24),
              _AccessCard(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Gestão de subscrições',
                description:
                    'Aceder às ferramentas administrativas autorizadas.',
                color: const Color(0xFF1D4ED8),
                background: const Color(0xFFEFF6FF),
                onTap: () => context.push('/admin/subscriptions'),
              ),
            ],

            const SizedBox(height: 28),

            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: const Color(0xFFDC2626),
                side: const BorderSide(color: Color(0xFFF2CACA)),
                backgroundColor: Colors.white,
                minimumSize: const Size.fromHeight(52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
              ),
              icon: const Icon(Icons.logout_rounded),
              label: const Text(
                'Terminar sessão',
                style: TextStyle(fontWeight: FontWeight.w700),
              ),
              onPressed: () async {
                try {
                  await ref.read(authProvider.notifier).logout();

                  if (context.mounted) {
                    context.go('/login');
                  }
                } catch (_) {
                  if (context.mounted) {
                    ScaffoldMessenger.of(context).showSnackBar(
                      const SnackBar(
                        content: Text(
                          'Não foi possível terminar a sessão. Tente novamente.',
                        ),
                      ),
                    );
                  }
                }
              },
            ),
            const SizedBox(height: 16),
            const Center(
              child: Text(
                'FARCLIK • A sua saúde a um clik',
                style: TextStyle(
                  fontSize: 12,
                  color: _muted,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileInfoTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String value;

  const _ProfileInfoTile({
    required this.icon,
    required this.title,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 5,
      ),
      leading: Container(
        width: 40,
        height: 40,
        decoration: BoxDecoration(
          color: const Color(0xFFE8F7ED),
          borderRadius: BorderRadius.circular(12),
        ),
        child: Icon(
          icon,
          color: const Color(0xFF15803D),
          size: 21,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 13,
          color: Color(0xFF748091),
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 3),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 15,
            color: Color(0xFF17212B),
            fontWeight: FontWeight.w600,
          ),
        ),
      ),
    );
  }
}

class _AccessCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final String description;
  final Color color;
  final Color background;
  final VoidCallback onTap;

  const _AccessCard({
    required this.icon,
    required this.title,
    required this.description,
    required this.color,
    required this.background,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: background,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Padding(
          padding: const EdgeInsets.all(18),
          child: Row(
            children: [
              Icon(icon, size: 30, color: color),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 13,
                        height: 1.4,
                        color: Color(0xFF465467),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(Icons.chevron_right_rounded, color: color),
            ],
          ),
        ),
      ),
    );
  }
}
