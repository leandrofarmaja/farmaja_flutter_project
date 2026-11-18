import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/admin_reviews_provider.dart';

class AdminReviewsAnalyticsTab extends ConsumerWidget {
  const AdminReviewsAnalyticsTab({super.key});

  Widget _buildStarBar(int star, int count, int total) {
    final pct = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text(
              '$star★',
              style: const TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 12,
              ),
            ),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                color: star >= 4
                    ? Colors.green
                    : (star == 3 ? Colors.amber : Colors.red),
              ),
            ),
          ),
          const SizedBox(width: 8),
          SizedBox(
            width: 45,
            child: Text(
              '$count (${(pct * 100).toStringAsFixed(0)}%)',
              textAlign: TextAlign.end,
              style: const TextStyle(fontSize: 11, color: Colors.grey),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminReviewsProvider);

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final totalAppStars =
        state.appStarDistribution.values.fold(0, (sum, count) => sum + count);
    final totalPharmStars = state.pharmacyStarDistribution.values
        .fold(0, (sum, count) => sum + count);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Relatório & Analytics de Avaliações 📊',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              Text(
                'Desempenho da aplicação FarmaJá e reputação das farmácias parceiras em Angola.',
                style: TextStyle(
                  fontSize: 12,
                  color: AppColors.textSecondaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Row(
            children: [
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                    ),
                  ),
                  child: Column(
                    children: [
                      const Icon(
                        Icons.smartphone_rounded,
                        color: AppColors.primaryDark,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.averageAppRating.toStringAsFixed(1),
                        style: const TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: AppColors.primaryDark,
                        ),
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Média App FarmaJá',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.storefront_rounded,
                        color: Colors.amber.shade900,
                        size: 28,
                      ),
                      const SizedBox(height: 6),
                      Text(
                        state.averagePharmacyRating.toStringAsFixed(1),
                        style: TextStyle(
                          fontSize: 32,
                          fontWeight: FontWeight.w900,
                          color: Colors.amber.shade900,
                        ),
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text(
                            'Média Farmácias',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),
          Card(
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(16),
            ),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Distribuição de Estrelas (App vs Farmácias)',
                    style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    '⭐ Avaliações da Aplicação FarmaJá:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (int star = 5; star >= 1; star--)
                    _buildStarBar(
                      star,
                      state.appStarDistribution[star] ?? 0,
                      totalAppStars,
                    ),
                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),
                  const Text(
                    '🏥 Avaliações de Serviço das Farmácias:',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: Colors.amber,
                    ),
                  ),
                  const SizedBox(height: 6),
                  for (int star = 5; star >= 1; star--)
                    _buildStarBar(
                      star,
                      state.pharmacyStarDistribution[star] ?? 0,
                      totalPharmStars,
                    ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),
          _buildPharmacyRankingCard(
            title: 'Farmácias Mais Bem Avaliadas 🥇',
            pharmacies: state.bestPharmacies,
            isBest: true,
          ),
          const SizedBox(height: 16),
          _buildPharmacyRankingCard(
            title: 'Farmácias Com Menor Avaliação (Atenção Operacional) ⚠️',
            pharmacies: state.lowestPharmacies,
            isBest: false,
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildPharmacyRankingCard({
    required String title,
    required List<PharmacyRatingStat> pharmacies,
    required bool isBest,
  }) {
    final emptyMessage = isBest
        ? 'Sem dados suficientes de avaliação.'
        : 'Nenhuma farmácia com nota baixa registada.';

    return Card(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              title,
              style: TextStyle(
                fontWeight: FontWeight.bold,
                fontSize: 15,
                color: isBest ? null : Colors.red,
              ),
            ),
            const SizedBox(height: 12),
            if (pharmacies.isEmpty)
              Text(
                emptyMessage,
                style: const TextStyle(color: Colors.grey, fontSize: 12),
              )
            else
              ...pharmacies.map((stat) {
                final isVeryLow = stat.averageRating <= 2.5;
                final accent = isBest
                    ? Colors.green
                    : (isVeryLow ? Colors.red : Colors.orange);

                return ListTile(
                  dense: true,
                  contentPadding: EdgeInsets.zero,
                  leading: CircleAvatar(
                    backgroundColor: accent.shade100,
                    child: Icon(
                      isBest
                          ? Icons.verified
                          : (isVeryLow
                              ? Icons.error_outline_rounded
                              : Icons.warning_rounded),
                      color: accent.shade900,
                      size: 20,
                    ),
                  ),
                  title: Text(
                    stat.pharmacyName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('${stat.totalReviews} avaliações'),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 10,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: accent.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(color: accent.shade300),
                    ),
                    child: Text(
                      '${stat.averageRating}★',
                      style: TextStyle(
                        fontWeight: FontWeight.w900,
                        color: accent.shade900,
                      ),
                    ),
                  ),
                );
              }),
          ],
        ),
      ),
    );
  }
}
