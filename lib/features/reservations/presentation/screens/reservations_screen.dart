
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/medicine_model.dart';
import '../providers/medicines_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(medicineFilterProvider);
    final medicinesAsync = ref.watch(medicinesListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        toolbarHeight: 76,
        titleSpacing: 20,
        title: Image.asset(
          'FARCLIK_logo.png',
          width: 148,
          height: 52,
          fit: BoxFit.contain,
          errorBuilder: (context, error, stackTrace) {
            return const Text(
              'FARCLIK',
              style: TextStyle(
                fontSize: 23,
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
                letterSpacing: 0.5,
              ),
            );
          },
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 22, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'A sua saúde, mais perto.',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF173B57),
                      height: 1.2,
                    ),
                  )
                      .animate()
                      .fadeIn(duration: 400.ms)
                      .slideY(begin: 0.08, end: 0),
                  const SizedBox(height: 9),
                  Text(
                    'Encontre medicamentos e consulte '
                    'a disponibilidade nas farmácias.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.6,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),
                  const SizedBox(height: 22),

                  _RegisterPharmacyCard(
                    onTap: () {
                      context.push('/pharmacy-application');
                    },
                  )
                      .animate()
                      .fadeIn(delay: 100.ms, duration: 450.ms)
                      .slideY(begin: 0.06, end: 0),

                  const SizedBox(height: 28),

                  const Text(
                    'Encontre o seu medicamento',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF173B57),
                    ),
                  ),
                  const SizedBox(height: 13),

                  SearchBar(
                    hintText: 'Pesquisar por nome do medicamento...',
                    hintStyle: WidgetStatePropertyAll(
                      TextStyle(
                        fontSize: 12,
                        color: Colors.blueGrey.shade400,
                      ),
                    ),
                    leading: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: 24,
                    ),
                    onChanged: (value) {
                      ref
                          .read(medicineFilterProvider.notifier)
                          .setQuery(value);
                    },
                    elevation: const WidgetStatePropertyAll(0),
                    backgroundColor: const WidgetStatePropertyAll(
                      Colors.white,
                    ),
                    side: const WidgetStatePropertyAll(
                      BorderSide(color: AppColors.borderLight),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(17),
                      ),
                    ),
                  ),

                  const SizedBox(height: 13),

                  Container(
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7F2),
                      borderRadius: BorderRadius.circular(17),
                      border: Border.all(
                        color: const Color(0xFFE1EEE4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          width: 36,
                          height: 36,
                          decoration: BoxDecoration(
                            color: AppColors.primaryLight,
                            borderRadius: BorderRadius.circular(11),
                          ),
                          child: const Icon(
                            Icons.location_on_rounded,
                            color: AppColors.primary,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 11),
                        Expanded(
                          child: Text(
                            'A pesquisa por farmácias próximas '
                            'será disponibilizada após a configuração '
                            'dos respectivos endereços.',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.55,
                              color: Colors.blueGrey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 27),

                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Medicamentos',
                          style: TextStyle(
                            fontSize: 19,
                            fontWeight: FontWeight.w900,
                            color: Color(0xFF173B57),
                          ),
                        ),
                      ),
                      FilterChip(
                        avatar: Icon(
                          Icons.inventory_2_outlined,
                          size: 16,
                          color: filterState.onlyInStock
                              ? Colors.white
                              : AppColors.primary,
                        ),
                        label: const Text(
                          'Em stock',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                          ),
                        ),
                        selected: filterState.onlyInStock,
                        showCheckmark: false,
                        selectedColor: AppColors.primary,
                        backgroundColor: const Color(0xFFEAF5ED),
                        side: BorderSide.none,
                        labelStyle: TextStyle(
                          color: filterState.onlyInStock
                              ? Colors.white
                              : AppColors.primary,
                        ),
                        onSelected: (value) {
                          ref
                              .read(medicineFilterProvider.notifier)
                              .toggleOnlyInStock(value);
                        },
                      ),
                    ],
                  ),
                  const SizedBox(height: 5),
                  Text(
                    'Preços e disponibilidade nas farmácias.',
                    style: TextStyle(
                      fontSize: 11,
                      color: Colors.blueGrey.shade500,
                    ),
                  ),
                  const SizedBox(height: 15),
                ],
              ),
            ),
          ),

          medicinesAsync.when(
            data: (medicines) {
              if (medicines.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: _EmptyMedicines(),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 25),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final medicine = medicines[index];
                      final available =
                          medicine.inStock && medicine.stockQuantity > 0;

                      return _MedicineCard(
                        medicine: medicine,
                        available: available,
                        onTap: () {
                          context.push('/medicine/${medicine.id}');
                        },
                      )
                          .animate(delay: (index * 65).ms)
                          .fadeIn(duration: 350.ms)
                          .slideY(begin: 0.05, end: 0);
                    },
                    childCount: medicines.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
            ),
            error: (error, stack) => SliverFillRemaining(
              hasScrollBody: false,
              child: _MedicineError(
                error: error,
                onRetry: () {
                  ref.invalidate(medicinesListProvider);
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _RegisterPharmacyCard extends StatelessWidget {
  final VoidCallback onTap;

  const _RegisterPharmacyCard({
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: AppColors.primary,
      borderRadius: BorderRadius.circular(22),
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Ink(
          padding: const EdgeInsets.all(18),
          decoration: const BoxDecoration(
            gradient: LinearGradient(
              colors: [
                Color(0xFF15803D),
                Color(0xFF16A34A),
              ],
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
            ),
          ),
          child: Row(
            children: [
              Container(
                width: 50,
                height: 50,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.17),
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(
                    color: Colors.white.withValues(alpha: 0.18),
                  ),
                ),
                child: const Icon(
                  Icons.add_business_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 14),
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'É responsável por uma farmácia?',
                      style: TextStyle(
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                      ),
                    ),
                    SizedBox(height: 6),
                    Text(
                      'Registe a sua farmácia na FARCLIK.',
                      style: TextStyle(
                        fontSize: 11,
                        height: 1.4,
                        color: Colors.white,
                      ),
                    ),
                  ],
                ),
              ),
              const Icon(
                Icons.arrow_forward_ios_rounded,
                size: 17,
                color: Colors.white,
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _EmptyMedicines extends StatelessWidget {
  const _EmptyMedicines();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(30),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(21),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.medication_rounded,
                size: 43,
                color: AppColors.primary,
              ),
            )
                .animate()
                .fadeIn(duration: 450.ms)
                .scale(begin: const Offset(0.85, 0.85)),
            const SizedBox(height: 20),
            const Text(
              'Nenhum medicamento encontrado',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: Color(0xFF173B57),
              ),
            ),
            const SizedBox(height: 9),
            Text(
              'Ainda não existem medicamentos registados '
              'para esta pesquisa. Volte a consultar quando '
              'as farmácias começarem a publicar os seus catálogos.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.6,
                color: Colors.blueGrey.shade500,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _MedicineCard extends StatelessWidget {
  final MedicineModel medicine;
  final bool available;
  final VoidCallback onTap;

  const _MedicineCard({
    required this.medicine,
    required this.available,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.only(bottom: 14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(21),
        border: Border.all(
          color: AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173B57).withValues(alpha: 0.04),
            blurRadius: 17,
            offset: const Offset(0, 6),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(21),
        clipBehavior: Clip.antiAlias,
        child: InkWell(
          onTap: onTap,
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
                    const SizedBox(width: 14),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            medicine.name,
                            style: const TextStyle(
                              fontSize: 14,
                              height: 1.35,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF173B57),
                            ),
                          ),
                          if (medicine.activeIngredient.isNotEmpty) ...[
                            const SizedBox(height: 5),
                            Text(
                              medicine.activeIngredient,
                              style: TextStyle(
                                fontSize: 11,
                                color: Colors.blueGrey.shade600,
                              ),
                            ),
                          ],
                          const SizedBox(height: 9),
                          Text(
                            '${medicine.priceKz.toInt()} Kz',
                            style: const TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                    ),
                    const Icon(
                      Icons.arrow_forward_ios_rounded,
                      size: 14,
                      color: Color(0xFF9AA9A0),
                    ),
                  ],
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 14),
                  child: Divider(
                    height: 1,
                    color: Color(0xFFEDF0EE),
                  ),
                ),
                Row(
                  children: [
                    const Icon(
                      Icons.storefront_outlined,
                      size: 16,
                      color: AppColors.secondary,
                    ),
                    const SizedBox(width: 7),
                    Expanded(
                      child: Text(
                        medicine.pharmacyName,
                        maxLines: 1,
                        overflow: TextOverflow.ellipsis,
                        style: TextStyle(
                          fontSize: 11,
                          color: Colors.blueGrey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                    const SizedBox(width: 7),
                    _StockBadge(
                      available: available,
                      quantity: medicine.stockQuantity,
                    ),
                  ],
                ),
                if (medicine.requiresPrescription) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        Icons.receipt_long_outlined,
                        size: 15,
                        color: Colors.deepOrange.shade700,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        'Sujeito a receita médica',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w700,
                          color: Colors.deepOrange.shade700,
                        ),
                      ),
                    ],
                  ),
                ],
                if (medicine.isGeneric) ...[
                  const SizedBox(height: 10),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 9,
                      vertical: 5,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.secondaryLight,
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: const Text(
                      'Medicamento genérico',
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w700,
                        color: AppColors.secondary,
                      ),
                    ),
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _StockBadge extends StatelessWidget {
  final bool available;
  final int quantity;

  const _StockBadge({
    required this.available,
    required this.quantity,
  });

  @override
  Widget build(BuildContext context) {
    final color = available ? AppColors.success : AppColors.danger;

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(20),
      ),
      child: Text(
        available ? 'Em stock: $quantity' : 'Sem stock',
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.w800,
          color: color,
        ),
      ),
    );
  }
}

class _MedicineImage extends StatelessWidget {
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
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(16),
        child: Image.network(
          url,
          width: 78,
          height: 78,
          fit: BoxFit.cover,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;

            return const Center(
              child: SizedBox(
                width: 22,
                height: 22,
                child: CircularProgressIndicator(
                  strokeWidth: 2,
                  color: AppColors.primary,
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
      width: 78,
      height: 78,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Center(
        child: Icon(
          Icons.medication_rounded,
          color: AppColors.primary,
          size: 34,
        ),
      ),
    );
  }
}

class _MedicineError extends StatelessWidget {
  final Object error;
  final VoidCallback onRetry;

  const _MedicineError({
    required this.error,
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(25),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(23),
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                size: 37,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Não foi possível carregar o catálogo.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 15,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 9),
            Text(
              '$error',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 11,
                height: 1.5,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
            ),
          ],
        ),
      ),
    );
  }
}
