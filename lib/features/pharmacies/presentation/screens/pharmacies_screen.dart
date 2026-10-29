import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/pharmacy_model.dart';
import '../../../reviews/presentation/widgets/pharmacy_reviews_list_widget.dart';
import '../providers/pharmacies_provider.dart';

class PharmaciesScreen extends ConsumerWidget {
  const PharmaciesScreen({super.key});

  Widget _pharmacyImage(
    String imageUrl, {
    double size = 64,
  }) {
    final url = imageUrl.trim();

    Widget fallback() {
      return Container(
        width: size,
        height: size,
        decoration: BoxDecoration(
          color: Colors.green.shade50,
          borderRadius: BorderRadius.circular(12),
        ),
        child: const Icon(
          Icons.local_pharmacy_rounded,
          color: AppColors.primary,
          size: 32,
        ),
      );
    }

    if (url.isEmpty) return fallback();

    return ClipRRect(
      borderRadius: BorderRadius.circular(12),
      child: Image.network(
        url,
        width: size,
        height: size,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) => fallback(),
      ),
    );
  }

  void _showPharmacyReviewsModal(
    BuildContext context,
    PharmacyModel pharm,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(24),
        ),
      ),
      builder: (context) => DraggableScrollableSheet(
        initialChildSize: 0.75,
        maxChildSize: 0.95,
        minChildSize: 0.5,
        expand: false,
        builder: (context, scrollController) => Padding(
          padding: const EdgeInsets.all(20),
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
                  _pharmacyImage(pharm.logoUrl),
                  const SizedBox(width: 12),
                  Expanded(
                    child: Text(
                      pharm.name,
                      style: const TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                ],
              ),
              if (pharm.address.trim().isNotEmpty) ...[
                const SizedBox(height: 8),
                Text(
                  pharm.address,
                  style: const TextStyle(
                    fontSize: 12,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
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
    final searchQuery = ref.watch(pharmaciesSearchQueryProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Farmácias FARCLIK'),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 16, 16, 8),
            child: TextField(
              onChanged: (value) {
                ref
                    .read(pharmaciesSearchQueryProvider.notifier)
                    .state = value;
              },
              decoration: InputDecoration(
                hintText: 'Pesquisar farmácia, município ou bairro',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: searchQuery.isEmpty
                    ? null
                    : IconButton(
                        tooltip: 'Limpar pesquisa',
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          ref
                              .read(
                                pharmaciesSearchQueryProvider.notifier,
                              )
                              .state = '';
                        },
                      ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: const BorderSide(
                    color: AppColors.primary,
                    width: 1.5,
                  ),
                ),
              ),
            ),
          ),
          Expanded(
            child: pharmaciesAsync.when(
              data: (pharmacies) {
                if (pharmacies.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(24),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          const Icon(
                            Icons.local_pharmacy_outlined,
                            size: 56,
                            color: AppColors.primary,
                          ),
                          const SizedBox(height: 16),
                          Text(
                            searchQuery.trim().isNotEmpty
                                ? 'Nenhuma farmácia encontrada.'
                                : 'Ainda não existem farmácias registadas.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            searchQuery.trim().isNotEmpty
                                ? 'Experimenta outro nome, município ou bairro.'
                                : 'A lista será actualizada quando as farmácias '
                                    'parceiras forem registadas e os seus dados '
                                    'estiverem disponíveis.',
                            textAlign: TextAlign.center,
                          ),
                          if (searchQuery.trim().isNotEmpty) ...[
                            const SizedBox(height: 12),
                            TextButton(
                              onPressed: () {
                                ref
                                    .read(
                                      pharmaciesSearchQueryProvider.notifier,
                                    )
                                    .state = '';
                              },
                              child: const Text('Limpar pesquisa'),
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }

                return ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                  itemCount: pharmacies.length,
                  itemBuilder: (context, index) {
                    final pharm = pharmacies[index];
                    final hasAddress = pharm.address.trim().isNotEmpty;
                    final hasPhone = pharm.phone.trim().isNotEmpty;
                    final hasHours =
                        pharm.openingHours.trim().isNotEmpty &&
                        pharm.openingHours.toLowerCase() != 'desconhecido' &&
                        pharm.openingHours.toLowerCase() != 'não informado';

                    final locationParts = <String>[
                      if (pharm.neighborhood.trim().isNotEmpty)
                        pharm.neighborhood.trim(),
                      if (pharm.district.trim().isNotEmpty)
                        pharm.district.trim(),
                      if (pharm.province.trim().isNotEmpty)
                        pharm.province.trim(),
                    ];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      clipBehavior: Clip.antiAlias,
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _pharmacyImage(pharm.logoUrl),
                                const SizedBox(width: 12),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pharm.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                      if (locationParts.isNotEmpty) ...[
                                        const SizedBox(height: 6),
                                        Text(
                                          locationParts.join(', '),
                                          style: const TextStyle(
                                            fontSize: 12,
                                            color:
                                                AppColors.textSecondaryLight,
                                          ),
                                        ),
                                      ],
                                      if (pharm.rating > 0) ...[
                                        const SizedBox(height: 6),
                                        InkWell(
                                          onTap: () =>
                                              _showPharmacyReviewsModal(
                                            context,
                                            pharm,
                                          ),
                                          child: Row(
                                            mainAxisSize: MainAxisSize.min,
                                            children: [
                                              const Icon(
                                                Icons.star,
                                                color: Colors.amber,
                                                size: 16,
                                              ),
                                              const SizedBox(width: 4),
                                              Text(
                                                pharm.rating
                                                    .toStringAsFixed(1),
                                                style: const TextStyle(
                                                  fontWeight: FontWeight.bold,
                                                  fontSize: 13,
                                                ),
                                              ),
                                            ],
                                          ),
                                        ),
                                      ],
                                    ],
                                  ),
                                ),
                              ],
                            ),
                            if (hasAddress) ...[
                              const SizedBox(height: 10),
                              Text(
                                pharm.address,
                                style: const TextStyle(fontSize: 12),
                              ),
                            ],
                            if (hasPhone) ...[
                              const SizedBox(height: 4),
                              Text(
                                'Telefone: ${pharm.phone}',
                                style: const TextStyle(
                                  fontSize: 12,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ],
                            const SizedBox(height: 10),
                            Wrap(
                              spacing: 8,
                              runSpacing: 8,
                              crossAxisAlignment: WrapCrossAlignment.center,
                              children: [
                                if (hasHours)
                                  Chip(
                                    avatar: const Icon(
                                      Icons.access_time,
                                      size: 14,
                                    ),
                                    label: Text(
                                      pharm.openingHours,
                                      style: const TextStyle(fontSize: 11),
                                    ),
                                  ),
                                if (pharm.isOpen24h)
                                  Container(
                                    padding: const EdgeInsets.symmetric(
                                      horizontal: 10,
                                      vertical: 5,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.green.shade100,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: const Text(
                                      '24 horas',
                                      style: TextStyle(
                                        fontSize: 11,
                                        color: AppColors.primary,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                                TextButton.icon(
                                  icon: const Icon(
                                    Icons.reviews_outlined,
                                    size: 16,
                                  ),
                                  label: const Text(
                                    'Avaliações',
                                    style: TextStyle(fontSize: 12),
                                  ),
                                  onPressed: () =>
                                      _showPharmacyReviewsModal(
                                    context,
                                    pharm,
                                  ),
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
              loading: () => const Center(
                child: CircularProgressIndicator(),
              ),
              error: (err, stack) => const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Não foi possível carregar as farmácias. '
                    'Verifica a ligação e tenta novamente.',
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
