import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class ProfileScreen extends ConsumerWidget {
  const ProfileScreen({super.key});

  static const Color _muted = Color(0xFF64748B);
  static const Color _line = Color(0xFFE8F0EB);

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final authState = ref.watch(authProvider);
    final user = authState.user;

    if (user == null) {
      return Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(title: const Text('O meu perfil')),
        body: Center(
          child: Padding(
            padding: const EdgeInsets.all(28),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 88,
                  height: 88,
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(28),
                  ),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    size: 43,
                    color: AppColors.primaryDark,
                  ),
                ),
                const SizedBox(height: 22),
                Text(
                  'Sessão não iniciada',
                  style: Theme.of(context).textTheme.titleLarge,
                ),
                const SizedBox(height: 9),
                const Text(
                  'Inicie sessão para consultar o seu perfil e as suas reservas.',
                  textAlign: TextAlign.center,
                  style: TextStyle(color: _muted, height: 1.55),
                ),
                const SizedBox(height: 26),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    onPressed: () => context.go('/login'),
                    icon: const Icon(Icons.login_rounded),
                    label: const Text('Iniciar sessão'),
                  ),
                ),
              ],
            ),
          ),
        ),
      );
    }

    final isPharmacy = user.role == 'pharmacy';
    final isAdmin = user.role == 'admin';
    final isCustomer = !isPharmacy && !isAdmin;

    final fullName = user.fullName.trim().isNotEmpty
        ? user.fullName.trim()
        : 'Utilizador FARCLIK';

    final initials = fullName
        .split(RegExp(r'\s+'))
        .where((part) => part.isNotEmpty)
        .take(2)
        .map((part) => part[0])
        .join()
        .toUpperCase();

    final roleColor = isPharmacy
        ? AppColors.secondary
        : isAdmin
            ? const Color(0xFF1D4ED8)
            : AppColors.primaryDark;

    final roleBackground = isPharmacy
        ? AppColors.secondaryLight
        : isAdmin
            ? const Color(0xFFEFF6FF)
            : AppColors.primaryLight;

    final roleLabel = isPharmacy
        ? 'Conta de Farmácia'
        : isAdmin
            ? 'Conta de Administrador'
            : 'Conta de Cliente';

    final location = [
      user.province.trim(),
      user.district.trim(),
    ].where((part) => part.isNotEmpty).join(', ');

    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        title: const Text('O meu perfil'),
        actions: [
          Padding(
            padding: const EdgeInsets.only(right: 18),
            child: Image.asset(
              'FARCLIK_logo.png',
              height: 34,
              fit: BoxFit.contain,
            ),
          ),
        ],
      ),
      body: SingleChildScrollView(
        physics: const BouncingScrollPhysics(),
        padding: const EdgeInsets.fromLTRB(20, 18, 20, 34),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            _ProfileHero(
              fullName: fullName,
              email: user.email,
              initials: initials.isEmpty ? 'F' : initials,
              roleLabel: roleLabel,
              roleColor: roleColor,
              roleBackground: roleBackground,
            ).animate().fadeIn(duration: 450.ms).slideY(
                  begin: 0.08,
                  end: 0,
                  curve: Curves.easeOutCubic,
                ),
            const SizedBox(height: 28),
            const _SectionHeading(
              title: 'Os meus dados',
              subtitle: 'Informações associadas à sua conta',
            ),
            const SizedBox(height: 14),
            _InfoCard(
              children: [
                _ProfileInfoTile(
                  icon: Icons.email_outlined,
                  title: 'E-mail',
                  value: user.email,
                ),
                const _InfoDivider(),
                _ProfileInfoTile(
                  icon: Icons.phone_outlined,
                  title: 'Telefone',
                  value: user.phone.trim().isNotEmpty
                      ? user.phone
                      : 'Não indicado',
                ),
                const _InfoDivider(),
                _ProfileInfoTile(
                  icon: Icons.location_on_outlined,
                  title: 'Localização',
                  value: location.isNotEmpty ? location : 'Não indicada',
                ),
                if (isCustomer &&
                    user.insuranceProvider != null &&
                    user.insuranceProvider!.trim().isNotEmpty) ...[
                  const _InfoDivider(),
                  _ProfileInfoTile(
                    icon: Icons.health_and_safety_outlined,
                    title: 'Seguro de saúde',
                    value: user.insuranceProvider!,
                  ),
                ],
                if (isPharmacy &&
                    (user.pharmacyName?.trim().isNotEmpty ?? false)) ...[
                  const _InfoDivider(),
                  _ProfileInfoTile(
                    icon: Icons.storefront_outlined,
                    title: 'Farmácia',
                    value: user.pharmacyName!,
                  ),
                ],
              ],
            ).animate().fadeIn(delay: 100.ms, duration: 450.ms).slideY(
                  begin: 0.06,
                  end: 0,
                ),
            if (isPharmacy) ...[
              const SizedBox(height: 26),
              _AccessCard(
                icon: Icons.storefront_rounded,
                title: 'Painel da minha farmácia',
                description:
                    'Gerir medicamentos, preços, stock e reservas autorizadas.',
                color: AppColors.secondary,
                background: const Color(0xFFEAF8F5),
                onTap: () => context.push('/pharmacy-dashboard'),
              ).animate().fadeIn(delay: 180.ms, duration: 450.ms),
            ],
            if (isAdmin) ...[
              const SizedBox(height: 26),
              _AccessCard(
                icon: Icons.admin_panel_settings_rounded,
                title: 'Gestão de subscrições',
                description:
                    'Aceder às ferramentas administrativas autorizadas.',
                color: const Color(0xFF1D4ED8),
                background: const Color(0xFFEFF6FF),
                onTap: () => context.push('/admin/subscriptions'),
              ).animate().fadeIn(delay: 180.ms, duration: 450.ms),
            ],
            const SizedBox(height: 30),
            OutlinedButton.icon(
              style: OutlinedButton.styleFrom(
                foregroundColor: AppColors.danger,
                backgroundColor: Colors.white,
                side: const BorderSide(color: Color(0xFFF3D5D5)),
                minimumSize: const Size.fromHeight(54),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
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
            const SizedBox(height: 22),
            const Center(
              child: Text(
                'FARCLIK  •  A SUA SAÚDE A UM CLIK',
                style: TextStyle(
                  fontSize: 10,
                  letterSpacing: 1.1,
                  color: _muted,
                  fontWeight: FontWeight.w700,
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ProfileHero extends StatelessWidget {
  final String fullName;
  final String email;
  final String initials;
  final String roleLabel;
  final Color roleColor;
  final Color roleBackground;

  const _ProfileHero({
    required this.fullName,
    required this.email,
    required this.initials,
    required this.roleLabel,
    required this.roleColor,
    required this.roleBackground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(22, 26, 22, 24),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF168B48), Color(0xFF0F766E)],
        ),
        borderRadius: BorderRadius.circular(28),
        boxShadow: [
          BoxShadow(
            color: AppColors.primary.withValues(alpha: 0.17),
            blurRadius: 24,
            offset: const Offset(0, 11),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(4),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.65),
              ),
            ),
            child: CircleAvatar(
              radius: 39,
              backgroundColor: Colors.white,
              child: Text(
                initials,
                style: const TextStyle(
                  color: AppColors.primaryDark,
                  fontSize: 25,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ),
          ),
          const SizedBox(height: 16),
          Text(
            fullName,
            textAlign: TextAlign.center,
            style: const TextStyle(
              color: Colors.white,
              fontSize: 21,
              fontWeight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 6),
          Text(
            email,
            textAlign: TextAlign.center,
            style: TextStyle(
              color: Colors.white.withValues(alpha: 0.88),
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 17),
          Container(
            padding: const EdgeInsets.symmetric(
              horizontal: 14,
              vertical: 8,
            ),
            decoration: BoxDecoration(
              color: Colors.white.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(30),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.25),
              ),
            ),
            child: Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                Icon(
                  roleLabel == 'Conta de Farmácia'
                      ? Icons.storefront_rounded
                      : roleLabel == 'Conta de Administrador'
                          ? Icons.shield_rounded
                          : Icons.person_rounded,
                  size: 16,
                  color: Colors.white,
                ),
                const SizedBox(width: 8),
                Text(
                  roleLabel,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _SectionHeading extends StatelessWidget {
  final String title;
  final String subtitle;

  const _SectionHeading({
    required this.title,
    required this.subtitle,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          title,
          style: const TextStyle(
            color: Color(0xFF173B57),
            fontSize: 18,
            fontWeight: FontWeight.w800,
          ),
        ),
        const SizedBox(height: 4),
        Text(
          subtitle,
          style: const TextStyle(
            color: Color(0xFF64748B),
            fontSize: 12,
          ),
        ),
      ],
    );
  }
}

class _InfoCard extends StatelessWidget {
  final List<Widget> children;

  const _InfoCard({required this.children});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(color: _line),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173B57).withValues(alpha: 0.035),
            blurRadius: 18,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(children: children),
    );
  }
}

class _InfoDivider extends StatelessWidget {
  const _InfoDivider();

  @override
  Widget build(BuildContext context) {
    return const Divider(
      height: 1,
      thickness: 1,
      indent: 70,
      endIndent: 18,
      color: _line,
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
        horizontal: 17,
        vertical: 7,
      ),
      leading: Container(
        width: 43,
        height: 43,
        decoration: BoxDecoration(
          gradient: const LinearGradient(
            colors: [Color(0xFFE8F8ED), Color(0xFFF3FBF5)],
          ),
          borderRadius: BorderRadius.circular(14),
        ),
        child: Icon(
          icon,
          color: AppColors.primaryDark,
          size: 21,
        ),
      ),
      title: Text(
        title,
        style: const TextStyle(
          fontSize: 11,
          color: _muted,
          fontWeight: FontWeight.w600,
        ),
      ),
      subtitle: Padding(
        padding: const EdgeInsets.only(top: 4),
        child: Text(
          value,
          style: const TextStyle(
            fontSize: 14,
            color: Color(0xFF173B57),
            fontWeight: FontWeight.w700,
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
      borderRadius: BorderRadius.circular(22),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(22),
        child: Container(
          padding: const EdgeInsets.all(19),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(22),
            border: Border.all(
              color: color.withValues(alpha: 0.12),
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.8),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: Icon(icon, size: 25, color: color),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                        color: color,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      description,
                      style: const TextStyle(
                        fontSize: 12,
                        height: 1.45,
                        color: Color(0xFF465467),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              Icon(
                Icons.arrow_forward_ios_rounded,
                size: 15,
                color: color,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
