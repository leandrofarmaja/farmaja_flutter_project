
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/medicines_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  static const Color _green = Color(0xFF16A34A);
  static const Color _darkGreen = Color(0xFF15803D);
  static const Color _teal = Color(0xFF0F766E);
  static const Color _navy = Color(0xFF173B57);
  static const Color _blue = Color(0xFF0284C7);
  static const Color _muted = Color(0xFF687984);
  static const Color _surface = Color(0xFFF8FBF9);

  static const String _pharmacistImage =
      'assets/images/Esmy foto.jpg';
  static const String _pharmacyImage =
      'assets/images/farmacia_destaquec.jpg';
  static const String _healthImage =
      'assets/images/Ilustração_3d_saude.jpg';

  TextStyle _textStyle({
    double size = 14,
    FontWeight weight = FontWeight.w500,
    Color color = _navy,
    double height = 1.4,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(medicineFilterProvider);
    final medicinesAsync = ref.watch(medicinesListProvider);

    final theme = Theme.of(context);

    return Theme(
      data: theme.copyWith(
        useMaterial3: true,
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
        appBar: AppBar(
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.white,
          elevation: 0,
          toolbarHeight: 76,
          titleSpacing: 20,
          title: Image.asset(
            'FARCLIK_logo.png',
            width: 148,
            height: 52,
            fit: BoxFit.contain,
            errorBuilder: (context, error, stackTrace) {
              return const SizedBox.shrink();
            },
          ),
        ),
        body: CustomScrollView(
          physics: const BouncingScrollPhysics(),
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(20, 18, 20, 20),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildWelcomeHeader()
                        .animate()
                        .fadeIn(duration: 400.ms)
                        .slideY(begin: 0.08, end: 0),

                    const SizedBox(height: 22),

                    _buildRegisterPharmacyCard(
                      onTap: () {
                        context.push('/pharmacy-application');
                      },
                    )
                        .animate()
                        .fadeIn(delay: 100.ms)
                        .slideY(begin: 0.08, end: 0),

                    const SizedBox(height: 25),

                    _buildSectionHeading(
                      'Encontre o seu medicamento',
                      'Pesquise por nome e consulte a disponibilidade.',
                    ),

                    const SizedBox(height: 13),

                    SearchBar(
                      hintText: 'Pesquisar medicamentos...',
                      hintStyle: WidgetStatePropertyAll(
                        _textStyle(
                          size: 12,
                          color: const Color(0xFF9AA8A0),
                        ),
                      ),
                      leading: const Icon(
                        LucideIcons.search,
                        color: _green,
                        size: 21,
                      ),
                      onChanged: (value) {
                        ref
                            .read(medicineFilterProvider.notifier)
                            .setQuery(value);
                      },
                      elevation: const WidgetStatePropertyAll(0),
                      backgroundColor: const WidgetStatePropertyAll(
                        _surface,
                      ),
                      side: const WidgetStatePropertyAll(
                        BorderSide(color: Color(0xFFE4ECE7)),
                      ),
                      shape: WidgetStatePropertyAll(
                        RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(17),
                        ),
                      ),
                    )
                        .animate()
                        .fadeIn(delay: 150.ms)
                        .slideY(begin: 0.06, end: 0),

                    const SizedBox(height: 13),

                    _buildLocationNotice()
                        .animate()
                        .fadeIn(delay: 200.ms),

                    const SizedBox(height: 26),

                    _buildSectionHeading(
                      'Medicamentos',
                      'Preços e disponibilidade nas farmácias.',
                      trailing: FilterChip(
                        avatar: Icon(
                          Iconsax.box,
                          size: 16,
                          color: filterState.onlyInStock
                              ? Colors.white
                              : _green,
                        ),
                        label: Text(
                          'Em stock',
                          style: _textStyle(
                            size: 10,
                            weight: FontWeight.w800,
                            color: filterState.onlyInStock
                                ? Colors.white
                                : _green,
                          ),
                        ),
                        selected: filterState.onlyInStock,
                        showCheckmark: false,
                        selectedColor: _green,
                        backgroundColor: const Color(0xFFEAF5ED),
                        side: BorderSide.none,
                        onSelected: (value) {
                          ref
                              .read(medicineFilterProvider.notifier)
                              .toggleOnlyInStock(value);
                        },
                      ),
                    ),

                    const SizedBox(height: 16),
                  ],
                ),
              ),
            ),

            medicinesAsync.when(
              data: (medicines) {
                if (medicines.isEmpty) {
                  return SliverFillRemaining(
                    hasScrollBody: false,
                    child: _buildEmptyState(),
                  );
                }

                return SliverPadding(
                  padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
                  sliver: SliverList(
                    delegate: SliverChildBuilderDelegate(
                      (context, index) {
                        final med = medicines[index];
                        final available =
                            med.inStock && med.stockQuantity > 0;

                        return _MedicineCard(
                          medicine: med,
                          available: available,
                          onTap: () {
                            context.push('/medicine/${med.id}');
                          },
                        )
                            .animate()
                            .fadeIn(
                              delay: Duration(
                                milliseconds: 50 * (index.clamp(0, 6)),
                              ),
                              duration: 350.ms,
                            )
                            .slideY(
                              begin: 0.06,
                              end: 0,
                              duration: 350.ms,
                            );
                      },
                      childCount: medicines.length,
                    ),
                  ),
                );
              },
              loading: () => const SliverFillRemaining(
                child: Center(
                  child: CircularProgressIndicator(
                    color: _green,
                  ),
                ),
              ),
              error: (error, stack) => SliverFillRemaining(
                hasScrollBody: false,
                child: _buildErrorState(error),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildWelcomeHeader() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          'A sua saúde, mais perto.',
          style: _textStyle(
            size: 25,
            weight: FontWeight.w900,
            height: 1.2,
          ),
        ),
        const SizedBox(height: 8),
        Text(
          'Encontre medicamentos e consulte a disponibilidade '
          'nas farmácias.',
          style: _textStyle(
            size: 12,
            color: _muted,
            height: 1.6,
          ),
        ),
        const SizedBox(height: 17),
        ClipRRect(
          borderRadius: BorderRadius.circular(19),
          child: SizedBox(
            width: double.infinity,
            height: 145,
            child: Stack(
              fit: StackFit.expand,
              children: [
                Image.asset(
                  _pharmacistImage,
                  fit: BoxFit.cover,
                  alignment: Alignment.topCenter,
                  errorBuilder: (_, __, ___) {
                    return Container(
                      color: const Color(0xFFEAF5ED),
                      alignment: Alignment.centerRight,
                      child: const Icon(
                        Icons.health_and_safety_outlined,
                        color: _green,
                        size: 65,
                      ),
                    );
                  },
                ),
                DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      colors: [
                        Colors.white.withValues(alpha: 0.96),
                        Colors.white.withValues(alpha: 0.65),
                        Colors.transparent,
                      ],
                      begin: Alignment.centerLeft,
                      end: Alignment.centerRight,
                      stops: const [0, 0.58, 1],
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(17),
                  child: Align(
                    alignment: Alignment.centerLeft,
                    child: SizedBox(
                      width: 185,
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Cuidamos de si.',
                            style: _textStyle(
                              size: 18,
                              weight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 6),
                          Text(
                            'Saúde e confiança ao seu alcance.',
                            style: _textStyle(
                              size: 11,
                              color: _muted,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildSectionHeading(
    String title,
    String subtitle, {
    Widget? trailing,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                title,
                style: _textStyle(
                  size: 17,
                  weight: FontWeight.w900,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                subtitle,
                style: _textStyle(
                  size: 10,
                  color: _muted,
                ),
              ),
            ],
          ),
        ),
        if (trailing != null) trailing,
      ],
    );
  }

  Widget _buildRegisterPharmacyCard({
    required VoidCallback onTap,
  }) {
    return Material(
      color: _green,
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
              colors: [_darkGreen, _green],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 48,
                height: 48,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.17),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Iconsax.shop,
                  color: Colors.white,
                  size: 25,
                ),
              ),
              const SizedBox(width: 13),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'É responsável por uma farmácia?',
                      style: _textStyle(
                        size: 12,
                        weight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    const SizedBox(height: 5),
                    Text(
                      'Registe a sua farmácia na FARCLIK.',
                      style: _textStyle(
                        size: 10,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 16,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildLocationNotice() {
    return Container(
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F7F2),
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE1EEE4),
        ),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Icon(
            Iconsax.location,
            color: _green,
            size: 20,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'A pesquisa por farmácias próximas será disponibilizada '
              'após a configuração dos respectivos endereços.',
              style: _textStyle(
                size: 10,
                color: _muted,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.all(30),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Container(
            width: 82,
            height: 82,
            decoration: const BoxDecoration(
              color: Color(0xFFEAF5ED),
              shape: BoxShape.circle,
            ),
            child: const Icon(
              LucideIcons.pill,
              size: 38,
              color: _blue,
            ),
          ),
          const SizedBox(height: 18),
          Text(
            'Nenhum medicamento encontrado',
            textAlign: TextAlign.center,
            style: _textStyle(
              size: 15,
              weight: FontWeight.w800,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ainda não existem medicamentos registados para esta '
            'pesquisa. Volte a consultar quando as farmácias '
            'começarem a publicar os seus catálogos.',
            textAlign: TextAlign.center,
            style: _textStyle(
              size: 11,
              color: _muted,
            ),
          ),
          const SizedBox(height: 22),
          ClipRRect(
            borderRadius: BorderRadius.circular(15),
            child: Image.asset(
              _healthImage,
              height: 115,
              width: 155,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) {
                return const SizedBox.shrink();
              },
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildErrorState(Object error) {
    return Padding(
      padding: const EdgeInsets.all(20),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          const Icon(
            Icons.cloud_off_rounded,
            size: 42,
            color: Colors.redAccent,
          ),
          const SizedBox(height: 12),
          Text(
            'Não foi possível carregar o catálogo.',
            textAlign: TextAlign.center,
            style: _textStyle(
              size: 14,
              weight: FontWeight.w700,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            '$error',
            textAlign: TextAlign.center,
            style: _textStyle(
              size: 10,
              color: _muted,
            ),
          ),
        ],
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  final dynamic medicine;
  final bool available;
  final VoidCallback onTap;

  const _MedicineCard({
    required this.medicine,
    required this.available,
    required this.onTap,
  });

  static const Color _navy = Color(0xFF173B57);
  static const Color _green = Color(0xFF16A34A);
  static const Color _blue = Color(0xFF0284C7);
  static const Color _muted = Color(0xFF687984);

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFE9EFEB),
        ),
        boxShadow: [
          BoxShadow(
            color: _navy.withValues(alpha: 0.035),
            blurRadius: 14,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(19),
        child: Padding(
          padding: const EdgeInsets.all(14),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  _MedicineImage(
                    imageUrl: medicine.imageUrl,
                  ),
                  const SizedBox(width: 13),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          medicine.name,
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                            color: _navy,
                          ),
                        ),
                        if (medicine.activeIngredient.isNotEmpty) ...[
                          const SizedBox(height: 5),
                          Text(
                            medicine.activeIngredient,
                            style: GoogleFonts.plusJakartaSans(
                              fontSize: 10,
                              color: _muted,
                            ),
                          ),
                        ],
                        const SizedBox(height: 9),
                        Text(
                          '${medicine.priceKz.toInt()} Kz',
                          style: GoogleFonts.plusJakartaSans(
                            fontSize: 17,
                            fontWeight: FontWeight.w900,
                            color: _green,
                          ),
                        ),
                      ],
                    ),
                  ),
                  const Icon(
                    Icons.arrow_forward_ios_rounded,
                    size: 13,
                    color: Color(0xFF9AA9A0),
                  ),
                ],
              ),
              const Padding(
                padding: EdgeInsets.symmetric(vertical: 13),
                child: Divider(
                  height: 1,
                  color: Color(0xFFEDF0EE),
                ),
              ),
              Row(
                children: [
                  const Icon(
                    Iconsax.shop,
                    size: 15,
                    color: _green,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      medicine.pharmacyName.isNotEmpty
                          ? medicine.pharmacyName
                          : 'Farmácia por identificar',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        color: _muted,
                      ),
                    ),
                  ),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 6,
                    ),
                    decoration: BoxDecoration(
                      color: available
                          ? const Color(0xFFE9F7EF)
                          : const Color(0xFFFFEEEE),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      available
                          ? 'Em stock: ${medicine.stockQuantity}'
                          : 'Sem stock',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 9,
                        fontWeight: FontWeight.w800,
                        color: available
                            ? _green
                            : Colors.red.shade700,
                      ),
                    ),
                  ),
                ],
              ),
              if (medicine.requiresPrescription) ...[
                const SizedBox(height: 11),
                Row(
                  children: [
                    Icon(
                      Iconsax.document_text,
                      size: 15,
                      color: Colors.deepOrange.shade700,
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Sujeito a receita médica',
                      style: GoogleFonts.plusJakartaSans(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: Colors.deepOrange.shade700,
                      ),
                    ),
                  ],
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

class _MedicineImage extends StatelessWidget {
  static const Color _green = Color(0xFF16A34A);

  final String? imageUrl;

  const _MedicineImage({
    required this.imageUrl,
  });

  @override
  Widget build(BuildContext context) {
    final url = imageUrl?.trim();

    if (url == null || url.isEmpty) {
      return const _MedicineImageFallback();
    }

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5ED),
        borderRadius: BorderRadius.circular(14),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(14),
        child: Image.network(
          url,
          width: 76,
          height: 76,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;

            return const Center(
              child: SizedBox(
                width: 21,
                height: 21,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: _green,
                ),
              ),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return const _MedicineImageFallback();
          },
        ),
      ),
    );
  }
}

class _MedicineImageFallback extends StatelessWidget {
  const _MedicineImageFallback();

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: const Color(0xFFEAF5ED),
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Icon(
          LucideIcons.pill,
          color: Color(0xFF0284C7),
          size: 32,
        ),
      ),
    );
  }
}

