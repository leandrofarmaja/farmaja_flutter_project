import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../reviews/presentation/widgets/pharmacy_reviews_list_widget.dart';
import '../domain/pharmacy_model.dart';
import '../providers/pharmacies_provider.dart';

class PharmaciesScreen extends ConsumerWidget {
  const PharmaciesScreen({super.key});

  void _showPharmacyReviewsModal(BuildContext context, PharmacyModel pharm) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20.0),
          child: ListView(
            controller: scrollController,
            children: [
              Center(
                child: Container(
                  width: 40,
                  height: 4,
                  margin: const EdgeInsets.only(bottom: 16),
                  decoration: BoxDecoration(
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(2),
                  ),
                ),
              ),
              Row(
                children: [
                  const Icon(Icons.local_pharmacy_rounded, color: AppColors.primary, size: 28),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      pharm.name,
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 4),
              Text(
                '📍 ${pharm.address}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 16),
              PharmacyReviewsListWidget(
                pharmacyId: pharm.id,
                pharmacyName: pharm.name,
              ),
            ],
          ),
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final pharmaciesAsync = ref.watch(pharmaciesListProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmácias Parceiras em Angola'),
      ),
      body: pharmaciesAsync.when(
        data: (pharmacies) {
          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: pharmacies.length,
            itemBuilder: (context, index) {
              final pharm = pharmacies[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        children: [
                          Expanded(
                            child: Text(
                              pharm.name,
                              style: const TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                              ),
                            ),
                          ),
                          InkWell(
                            onTap: () => _showPharmacyReviewsModal(context, pharm),
                            child: Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.amber.shade50,
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(color: Colors.amber.shade300),
                              ),
                              child: Row(
                                children: [
                                  const Icon(Icons.star, color: Colors.amber, size: 16),
                                  const SizedBox(width: 4),
                                  Text(
                                    '${pharm.rating.toStringAsFixed(1)} ★',
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                  ),
                                ],
                              ),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 6),
                      Text(
                        '📍 ${pharm.address}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        '📞 ${pharm.phone}',
                        style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          Chip(
                            avatar: const Icon(Icons.access_time, size: 14),
                            label: Text(pharm.openingHours, style: const TextStyle(fontSize: 11)),
                          ),
                          const SizedBox(width: 8),
                          if (pharm.isOpen24h)
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.green.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Text(
                                'Aberto 24H',
                                style: TextStyle(
                                  fontSize: 11,
                                  color: AppColors.primary,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          const Spacer(),
                          TextButton.icon(
                            icon: const Icon(Icons.reviews_outlined, size: 16),
                            label: const Text('Ver Avaliações', style: TextStyle(fontSize: 12)),
                            onPressed: () => _showPharmacyReviewsModal(context, pharm),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
        loading: () => const Center(child: CircularProgressIndicator()),
        error: (err, stack) => Center(child: Text('Erro: $err')),
      ),
    );
  }
}
