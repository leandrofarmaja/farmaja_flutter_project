
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.white,
        elevation: 0,
        toolbarHeight: 72,
        titleSpacing: 20,
        title: Row(
          children: [
            Container(
              width: 42,
              height: 42,
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(13),
              ),
              child: const Icon(
                Icons.local_pharmacy_rounded,
                color: Colors.white,
                size: 25,
              ),
            ),
            const SizedBox(width: 11),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'FARCLIK',
                  style: TextStyle(
                    fontSize: 21,
                    fontWeight: FontWeight.w900,
                    letterSpacing: 0.5,
                    color: AppColors.primary,
                  ),
                ),
                Text(
                  'A SUA SAÚDE A UM CLIK',
                  style: TextStyle(
                    fontSize: 9,
                    fontWeight: FontWeight.w600,
                    letterSpacing: 1,
                    color: Colors.blueGrey.shade400,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        physics: const BouncingScrollPhysics(),
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(20, 12, 20, 20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cuide da sua saúde.',
                    style: TextStyle(
                      fontSize: 25,
                      fontWeight: FontWeight.w900,
                      color: Color(0xFF173B57),
                      height: 1.2,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    'Encontre medicamentos e farmácias '
                    'de forma simples e rápida.',
                    style: TextStyle(
                      fontSize: 13,
                      height: 1.5,
                      color: Colors.blueGrey.shade600,
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Registo de farmácias.
                  Material(
                    color: Colors.white,
                    borderRadius: BorderRadius.circular(18),
                    child: InkWell(
                      borderRadius: BorderRadius.circular(18),
                      onTap: () {
                        context.push('/pharmacy-application');
                      },
                      child: Container(
                        padding: const EdgeInsets.all(16),
                        decoration: BoxDecoration(
                          borderRadius: BorderRadius.circular(18),
                          border: Border.all(
                            color: AppColors.primary.withValues(alpha: 0.2),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.035),
                              blurRadius: 14,
                              offset: const Offset(0, 5),
                            ),
                          ],
                        ),
                        child: Row(
                          children: [
                            Container(
                              width: 52,
                              height: 52,
                              decoration: BoxDecoration(
                                color: AppColors.primaryLight,
                                borderRadius: BorderRadius.circular(15),
                              ),
                              child: const Icon(
                                Icons.add_business_rounded,
                                color: AppColors.primary,
                                size: 27,
                              ),
                            ),
                            const SizedBox(width: 14),
                            const Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Registar a minha farmácia',
                                    style: TextStyle(
                                      fontSize: 14,
                                      fontWeight: FontWeight.w800,
                                      color: Color(0xFF173B57),
                                    ),
                                  ),
                                  SizedBox(height: 5),
                                  Text(
                                    'Submeta os dados e a licença '
                                    'para análise da equipa FARCLIK.',
                                    style: TextStyle(
                                      fontSize: 11,
                                      height: 1.4,
                                      color: Colors.black54,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                            const SizedBox(width: 6),
                            const Icon(
                              Icons.arrow_forward_ios_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                          ],
                        ),
                      ),
                    ),
                  ),

                  const SizedBox(height: 25),

                  // Pesquisa.
                  const Text(
                    'O que procura hoje?',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w800,
                      color: Color(0xFF173B57),
                    ),
                  ),
                  const SizedBox(height: 11),

                  SearchBar(
                    hintText: 'Nome do medicamento...',
                    hintStyle: WidgetStatePropertyAll(
                      TextStyle(
                        fontSize: 13,
                        color: Colors.blueGrey.shade400,
                      ),
                    ),
                    leading: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                      size: 23,
                    ),
                    onChanged: (value) {
                      ref
                          .read(medicineFilterProvider.notifier)
                          .setQuery(value);
                    },
                    elevation: const WidgetStatePropertyAll(0),
                    backgroundColor: const WidgetStatePropertyAll(
                      Color(0xFFF7FAF8),
                    ),
                    side: const WidgetStatePropertyAll(
                      BorderSide(color: Color(0xFFE6ECE8)),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(15),
                      ),
                    ),
                  ),

                  const SizedBox(height: 13),

                  // Informação sobre localização.
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF1F8F4),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: Row(
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
                              height: 1.4,
                              color: Colors.blueGrey.shade700,
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 23),

                  // Filtro de stock.
                  Row(
                    children: [
                      const Expanded(
                        child: Text(
                          'Medicamentos disponíveis',
                          style: TextStyle(
                            fontSize: 17,
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
                        backgroundColor: const Color(0xFFF1F8F4),
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
                    'Consulte os preços e a disponibilidade.',
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

          // Lista de medicamentos.
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
                            decoration: BoxDecoration(
                              color: AppColors.primaryLight,
                              shape: BoxShape.circle,
                            ),
                            child: const Icon(
                              Icons.medication_outlined,
                              size: 38,
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
                padding: const EdgeInsets.fromLTRB(20, 0, 20, 24),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final med = medicines[index];
                      final available =
                          med.inStock && med.stockQuantity > 0;

                      return Container(
                        margin: const EdgeInsets.only(bottom: 13),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(17),
                          border: Border.all(
                            color: const Color(0xFFEDF0EE),
                          ),
                          boxShadow: [
                            BoxShadow(
                              color: Colors.black.withValues(alpha: 0.025),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: InkWell(
                          borderRadius: BorderRadius.circular(17),
                          onTap: () {
                            context.push('/medicine/${med.id}');
                          },
                          child: Padding(
                            padding: const EdgeInsets.all(15),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  crossAxisAlignment:
                                      CrossAxisAlignment.start,
                                  children: [
                                    Container(
                                      width: 45,
                                      height: 45,
                                      decoration: BoxDecoration(
                                        color: AppColors.primaryLight,
                                        borderRadius:
                                            BorderRadius.circular(13),
                                      ),
                                      child: const Icon(
                                        Icons.medication_rounded,
                                        color: AppColors.primary,
                                        size: 24,
                                      ),
                                    ),
                                    const SizedBox(width: 12),
                                    Expanded(
                                      child: Column(
                                        crossAxisAlignment:
                                            CrossAxisAlignment.start,
                                        children: [
                                          Text(
                                            med.name,
                                            style: const TextStyle(
                                              fontSize: 14,
                                              fontWeight: FontWeight.w800,
                                              color: Color(0xFF173B57),
                                            ),
                                          ),
                                          if (med.activeIngredient
                                              .isNotEmpty) ...[
                                            const SizedBox(height: 4),
                                            Text(
                                              med.activeIngredient,
                                              style: TextStyle(
                                                fontSize: 11,
                                                color: Colors
                                                    .blueGrey.shade600,
                                              ),
                                            ),
                                          ],
                                        ],
                                      ),
                                    ),
                                    const SizedBox(width: 8),
                                    Text(
                                      '${med.priceKz.toInt()} Kz',
                                      style: const TextStyle(
                                        fontSize: 14,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),

                                const Padding(
                                  padding: EdgeInsets.symmetric(
                                    vertical: 12,
                                  ),
                                  child: Divider(
                                    height: 1,
                                    color: Color(0xFFEDF0EE),
                                  ),
                                ),

                                Row(
                                  children: [
                                    const Icon(
                                      Icons.storefront_outlined,
                                      size: 15,
                                      color: Colors.blueGrey,
                                    ),
                                    const SizedBox(width: 6),
                                    Expanded(
                                      child: Text(
                                        med.pharmacyName.isNotEmpty
                                            ? med.pharmacyName
                                            : 'Farmácia por identificar',
                                        style: TextStyle(
                                          fontSize: 11,
                                          color: Colors.blueGrey.shade600,
                                        ),
                                      ),
                                    ),
                                    Container(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 9,
                                        vertical: 5,
                                      ),
                                      decoration: BoxDecoration(
                                        color: available
                                            ? const Color(0xFFE9F7EF)
                                            : const Color(0xFFFFEEEE),
                                        borderRadius:
                                            BorderRadius.circular(20),
                                      ),
                                      child: Text(
                                        available
                                            ? 'Em stock: ${med.stockQuantity}'
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

                                if (med.requiresPrescription) ...[
                                  const SizedBox(height: 10),
                                  Row(
                                    children: [
                                      Icon(
                                        Icons.receipt_long_outlined,
                                        size: 14,
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
