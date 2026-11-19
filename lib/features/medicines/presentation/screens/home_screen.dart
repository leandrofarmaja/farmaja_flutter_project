
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/medicines_provider.dart';

class HomeScreen extends ConsumerWidget {
  const HomeScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final filterState = ref.watch(medicineFilterProvider);
    final medicinesAsync = ref.watch(medicinesListProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFFAFCFA),
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        toolbarHeight: 76,
        titleSpacing: 20,
        title: Row(
          children: [
            Image.asset(
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
          ],
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
                  const Text(
                    'A sua saúde, mais perto.',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF173B57),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Encontre medicamentos e consulte '
                    'a disponibilidade nas farmácias.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),

                  const SizedBox(height: 22),

                  _RegisterPharmacyCard(
                    onTap: () {
                      context.push('/pharmacy-application');
                    },
                  ),

                  const SizedBox(height: 27),

                  const Text(
                    'Encontre o seu medicamento',
                    style: TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF173B57),
                    ),
                  ),
                  const SizedBox(height: 12),

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
                      BorderSide(color: Color(0xFFE4EBE6)),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),

                  const SizedBox(height: 13),

                  Container(
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF0F7F2),
                      borderRadius: BorderRadius.circular(14),
                      border: Border.all(
                        color: const Color(0xFFE1EEE4),
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                          size: 21,
                        ),
                        const SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'A pesquisa por farmácias próximas '
                            'será disponibilizada após a configuração '
                            'dos respectivos endereços.',
                            style: TextStyle(
                              fontSize: 11,
                              height: 1.45,
                              color: Colors.blueGrey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 26),

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
                  const SizedBox(height: 4),
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
                return SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: const EdgeInsets.all(30),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            padding: const EdgeInsets.all(20),
                            decoration: const BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.medication_outlined,
                              size: 40,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 18),
                          const Text(
                            'Nenhum medicamento encontrado',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF173B57),
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            'Ainda não existem medicamentos registados '
                            'para esta pesquisa. Volte a consultar quando '
                            'as farmácias começarem a publicar os seus '
                            'catálogos.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 12,
                              height: 1.5,
                              color: Colors.blueGrey.shade500,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
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
                  color: AppColors.primary,
                ),
              ),
            ),
            error: (error, stack) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
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
                      const Text(
                        'Não foi possível carregar o catálogo.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 14,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        '$error',
                        textAlign: TextAlign.center,
                        style: const TextStyle(fontSize: 11),
                      ),
                    ],
                  ),
                ),
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
      borderRadius: BorderRadius.circular(20),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(17),
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(20),
            gradient: const LinearGradient(
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
                width: 49,
                height: 49,
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: 0.18),
                  borderRadius: BorderRadius.circular(15),
                ),
                child: const Icon(
                  Icons.add_business_rounded,
                  color: Colors.white,
                  size: 26,
                ),
              ),
              const SizedBox(width: 13),
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
                    SizedBox(height: 5),
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

class _MedicineCard extends StatelessWidget {
  final dynamic medicine;
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
      margin: const EdgeInsets.only(bottom: 13),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE9EFEB),
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173B57).withValues(alpha: 0.035),
            blurRadius: 13,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(18),
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
                          style: const TextStyle(
                            fontSize: 14,
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
                            fontSize: 17,
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
                padding: EdgeInsets.symmetric(vertical: 13),
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
                    color: Colors.blueGrey,
                  ),
                  const SizedBox(width: 7),
                  Expanded(
                    child: Text(
                      medicine.pharmacyName.isNotEmpty
                          ? medicine.pharmacyName
                          : 'Farmácia por identificar',
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.blueGrey.shade600,
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
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: FontWeight.w800,
                        color: available
                            ? AppColors.primary
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
            ],
          ),
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
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
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
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(14),
      ),
      child: const Center(
        child: Icon(
          Icons.medication_rounded,
          color: AppColors.primary,
          size: 32,
        ),
      ),
    );
  }
}
