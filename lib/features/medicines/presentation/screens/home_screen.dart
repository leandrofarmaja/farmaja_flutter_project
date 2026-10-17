
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
      appBar: AppBar(
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(6),
              decoration: BoxDecoration(
                color: AppColors.primary,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Icon(
                Icons.local_pharmacy_rounded,
                color: Colors.white,
                size: 20,
              ),
            ),
            const SizedBox(width: 8),
            const Text(
              'FARCLIK',
              style: TextStyle(
                fontWeight: FontWeight.w900,
                color: AppColors.primary,
              ),
            ),
          ],
        ),
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  SearchBar(
                    hintText: 'Pesquisar medicamento pelo nome...',
                    leading: const Icon(
                      Icons.search,
                      color: AppColors.primary,
                    ),
                    onChanged: (value) {
                      ref
                          .read(medicineFilterProvider.notifier)
                          .setQuery(value);
                    },
                    elevation: const WidgetStatePropertyAll(0),
                    side: const WidgetStatePropertyAll(
                      BorderSide(color: AppColors.borderLight),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(16),
                      ),
                    ),
                  ),
                  const SizedBox(height: 16),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(14),
                    decoration: BoxDecoration(
                      color: AppColors.primaryLight,
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: const Row(
                      children: [
                        Icon(
                          Icons.location_on_outlined,
                          color: AppColors.primary,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'A pesquisa por localização será disponibilizada '
                            'quando os endereços das farmácias estiverem '
                            'configurados na plataforma.',
                            style: TextStyle(fontSize: 12),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),
                  FilterChip(
                    label: const Text('Apenas medicamentos em stock'),
                    selected: filterState.onlyInStock,
                    onSelected: (value) {
                      ref
                          .read(medicineFilterProvider.notifier)
                          .toggleOnlyInStock(value);
                    },
                  ),
                  const SizedBox(height: 16),
                  const Text(
                    'Medicamentos disponíveis',
                    style: TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.w800,
                    ),
                  ),
                ],
              ),
            ),
          ),
          medicinesAsync.when(
            data: (medicines) {
              if (medicines.isEmpty) {
                return const SliverFillRemaining(
                  hasScrollBody: false,
                  child: Center(
                    child: Padding(
                      padding: EdgeInsets.all(24),
                      child: Text(
                        'Ainda não existem medicamentos registados '
                        'para esta pesquisa. Volte a consultar quando '
                        'as farmácias começarem a publicar os seus catálogos.',
                        textAlign: TextAlign.center,
                      ),
                    ),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final med = medicines[index];

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Text(
                            med.name,
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 15,
                            ),
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              if (med.activeIngredient.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  med.activeIngredient,
                                  style: const TextStyle(fontSize: 12),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                med.pharmacyName.isNotEmpty
                                    ? 'Farmácia: ${med.pharmacyName}'
                                    : 'Farmácia por identificar',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: Colors.grey,
                                ),
                              ),
                              if (med.requiresPrescription) ...[
                                const SizedBox(height: 4),
                                const Text(
                                  'Sujeito a receita médica',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.deepOrange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ],
                              const SizedBox(height: 6),
                              Text(
                                med.inStock && med.stockQuantity > 0
                                    ? 'Em stock: ${med.stockQuantity}'
                                    : 'Sem stock disponível',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: med.inStock &&
                                          med.stockQuantity > 0
                                      ? AppColors.primary
                                      : Colors.red,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ],
                          ),
                          trailing: Text(
                            '${med.priceKz.toInt()} Kz',
                            style: const TextStyle(
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                              fontSize: 14,
                            ),
                          ),
                          onTap: () {
                            context.push('/medicine/${med.id}');
                          },
                        ),
                      );
                    },
                    childCount: medicines.length,
                  ),
                ),
              );
            },
            loading: () => const SliverFillRemaining(
              child: Center(child: CircularProgressIndicator()),
            ),
            error: (error, stack) => SliverFillRemaining(
              hasScrollBody: false,
              child: Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Text(
                    'Não foi possível carregar o catálogo.\n$error',
                    textAlign: TextAlign.center,
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
