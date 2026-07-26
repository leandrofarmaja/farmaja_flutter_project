import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
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
              child: const Icon(Icons.local_pharmacy_rounded, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 8),
            const Text(
              'FarmaJá',
              style: TextStyle(fontWeight: FontWeight.w900, color: AppColors.primary),
            ),
          ],
        ),
        actions: [
          DropdownButton<String>(
            value: filterState.selectedProvince,
            underline: const SizedBox(),
            icon: const Icon(Icons.arrow_drop_down, color: AppColors.primary),
            items: AppConstants.angolaProvinces.map((prov) {
              return DropdownMenuItem(
                value: prov,
                child: Text(
                  '📍 $prov',
                  style: const TextStyle(fontSize: 13, fontWeight: FontWeight.bold),
                ),
              );
            }).toList(),
            onChanged: (val) {
              if (val != null) {
                ref.read(medicineFilterProvider.notifier).setProvince(val);
              }
            },
          ),
          const SizedBox(width: 12),
        ],
      ),
      body: CustomScrollView(
        slivers: [
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Search Field
                  SearchBar(
                    hintText: 'Pesquise medicamento ou princípio ativo (ex: Coartem)...',
                    leading: const Icon(Icons.search, color: AppColors.primary),
                    onChanged: (val) {
                      ref.read(medicineFilterProvider.notifier).setQuery(val);
                    },
                    elevation: const WidgetStatePropertyAll(0),
                    side: const WidgetStatePropertyAll(
                      BorderSide(color: AppColors.borderLight),
                    ),
                    shape: WidgetStatePropertyAll(
                      RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Province and Municipality Filter Row
                  Row(
                    children: [
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: filterState.selectedProvince,
                          decoration: InputDecoration(
                            labelText: 'Província',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: AppConstants.angolaProvinces.map((prov) {
                            return DropdownMenuItem(
                              value: prov,
                              child: Text('📍 $prov', style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(medicineFilterProvider.notifier).setProvince(val);
                            }
                          },
                        ),
                      ),
                      const SizedBox(width: 8),
                      Expanded(
                        child: DropdownButtonFormField<String>(
                          value: AppConstants.angolaMunicipalities[filterState.selectedProvince]?.contains(filterState.selectedDistrict) == true
                              ? filterState.selectedDistrict
                              : 'Todos os Municípios',
                          decoration: InputDecoration(
                            labelText: 'Município',
                            contentPadding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6),
                            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
                          ),
                          items: (AppConstants.angolaMunicipalities[filterState.selectedProvince] ?? ['Todos os Municípios']).map((muni) {
                            return DropdownMenuItem(
                              value: muni,
                              child: Text(muni, style: const TextStyle(fontSize: 11)),
                            );
                          }).toList(),
                          onChanged: (val) {
                            if (val != null) {
                              ref.read(medicineFilterProvider.notifier).setDistrict(val);
                            }
                          },
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Emergency 24h Banner
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      gradient: const LinearGradient(
                        colors: [Color(0xFFDC2626), Color(0xFFEA580C)],
                      ),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.emergency, color: Colors.white, size: 32),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Precisa de Farmácia 24H urgente?',
                                style: TextStyle(
                                  color: Colors.white,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              Text(
                                'Ver farmácias abertas em ${filterState.selectedProvince} agora.',
                                style: const TextStyle(color: Colors.white70, fontSize: 12),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          onPressed: () {
                            ref.read(medicineFilterProvider.notifier).toggleOnly24h(true);
                            context.go('/pharmacies');
                          },
                          style: FilledButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: const Color(0xFFDC2626),
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                          ),
                          child: const Text('Ver 24h', style: TextStyle(fontSize: 12)),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 16),

                  // Filter Chips
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: Row(
                      children: [
                        FilterChip(
                          label: const Text('Em Stock'),
                          selected: filterState.onlyInStock,
                          onSelected: (val) {
                            ref.read(medicineFilterProvider.notifier).toggleOnlyInStock(val);
                          },
                        ),
                        const SizedBox(width: 8),
                        FilterChip(
                          label: const Text('Apenas Genéricos'),
                          selected: filterState.genericsOnly,
                          onSelected: (val) {
                            ref.read(medicineFilterProvider.notifier).toggleGenericsOnly(val);
                          },
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 20),

                  const Text(
                    'Medicamentos Disponíveis',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w800),
                  ),
                ],
              ),
            ),
          ),

          medicinesAsync.when(
            data: (medicines) {
              if (medicines.isEmpty) {
                return const SliverFillRemaining(
                  child: Center(
                    child: Text('Nenhum medicamento encontrado para esta pesquisa.'),
                  ),
                );
              }

              return SliverPadding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                sliver: SliverList(
                  delegate: SliverChildBuilderDelegate(
                    (context, index) {
                      final med = medicines[index];
                      final distance = med.calculateDistanceFrom(filterState.userLat, filterState.userLng).toStringAsFixed(1);

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        child: ListTile(
                          contentPadding: const EdgeInsets.all(16),
                          title: Row(
                            children: [
                              Expanded(
                                child: Text(
                                  med.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                                ),
                              ),
                              if (med.requiresPrescription)
                                Container(
                                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                  decoration: BoxDecoration(
                                    color: Colors.amber.shade100,
                                    borderRadius: BorderRadius.circular(6),
                                  ),
                                  child: const Text(
                                    'Receita Obr.',
                                    style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
                                  ),
                                ),
                            ],
                          ),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const SizedBox(height: 4),
                              Text(med.activeIngredient, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500)),
                              const SizedBox(height: 2),
                              Row(
                                children: [
                                  Text(
                                    '🏥 ${med.pharmacyName} (${med.district})',
                                    style: const TextStyle(fontSize: 11, color: Colors.grey),
                                  ),
                                  const SizedBox(width: 8),
                                  Text(
                                    '📍 $distance km',
                                    style: const TextStyle(fontSize: 11, color: AppColors.primary, fontWeight: FontWeight.bold),
                                  ),
                                ],
                              ),
                            ],
                          ),
                          trailing: Column(
                            mainAxisAlignment: MainAxisAlignment.center,
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${med.priceKz.toInt()} Kz',
                                style: const TextStyle(
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primary,
                                  fontSize: 15,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: med.inStock ? AppColors.primaryLight : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  med.inStock ? 'Stock: ${med.stockQuantity}' : 'Esgotado',
                                  style: TextStyle(
                                    fontSize: 10,
                                    color: med.inStock ? AppColors.primary : Colors.red,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
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
            error: (err, stack) => SliverFillRemaining(
              child: Center(child: Text('Erro ao carregar dados: $err')),
            ),
          ),
        ],
      ),
    );
  }
}
