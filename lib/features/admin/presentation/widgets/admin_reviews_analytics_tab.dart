import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/admin_reviews_provider.dart';

class AdminReviewsAnalyticsTab extends ConsumerWidget {
  const AdminReviewsAnalyticsTab({super.key});

  Widget _buildStarBar(int star, int count, int total) {
    final pct = total > 0 ? count / total : 0.0;

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 3.0),
      child: Row(
        children: [
          SizedBox(
            width: 30,
            child: Text('$star★', style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12)),
          ),
          const SizedBox(width: 8),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 10,
                backgroundColor: Colors.grey.shade200,
                color: star >= 4 ? Colors.green : (star == 3 ? Colors.amber : Colors.red),
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

    final totalReviews = state.reviews.length;
    final totalAppStars = state.appStarDistribution.values.fold(0, (s, c) => s + c);
    final totalPharmStars = state.pharmacyStarDistribution.values.fold(0, (s, c) => s + c);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header
          const Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                'Relatório & Analytics de Avaliações 📊',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              Text(
                'Desempenho da aplicação FarmaJá e reputação das farmácias parceiras em Angola.',
                style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Top Metric Cards
          Row(
            children: [
              // App Rating Card
              Expanded(
                child: Container(
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: AppColors.primaryLight,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: AppColors.primary.withOpacity(0.3)),
                  ),
                  child: Column(
                    children: [
                      const Icon(Icons.smartphone_rounded, color: AppColors.primaryDark, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        state.averageAppRating.toStringAsFixed(1),
                        style: const TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: AppColors.primaryDark),
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text('Média App FarmaJá', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
              const SizedBox(width: 12),

              // Pharmacy Average Card
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
                      Icon(Icons.storefront_rounded, color: Colors.amber.shade900, size: 28),
                      const SizedBox(height: 6),
                      Text(
                        state.averagePharmacyRating.toStringAsFixed(1),
                        style: TextStyle(fontSize: 32, fontWeight: FontWeight.w900, color: Colors.amber.shade900),
                      ),
                      const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.star_rounded, color: Colors.amber, size: 16),
                          SizedBox(width: 4),
                          Text('Média Farmácias', style: TextStyle(fontSize: 11, fontWeight: FontWeight.bold)),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 20),

          // Star Distribution Analytics
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
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
                  const Text('⭐ Avaliações da Aplicação FarmaJá:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: AppColors.primaryDark)),
                  const SizedBox(height: 6),
                  for (int s = 5; s >= 1; s--)
                    _buildStarBar(s, state.appStarDistribution[s] ?? 0, totalAppStars),

                  const SizedBox(height: 16),
                  const Divider(),
                  const SizedBox(height: 8),

                  const Text('🏥 Avaliações de Serviço das Farmácias:', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.amber)),
                  const SizedBox(height: 6),
                  for (int s = 5; s >= 1; s--)
                    _buildStarBar(s, state.pharmacyStarDistribution[s] ?? 0, totalPharmStars),
                ],
              ),
            ),
          ),
          const SizedBox(height: 20),

          // Best Rated Pharmacies Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Icon(Icons.emoji_events_rounded, color: Colors.amber, size: 24),
                      const SizedBox(width: 8),
                      const Text(
                        'Farmácias Mais Bem Avaliadas 🥇',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (state.bestPharmacies.isEmpty)
                    const Text('Sem dados suficientes de avaliação.', style: TextStyle(color: Colors.grey, fontSize: 12))
                  else
                    ...state.bestPharmacies.map((stat) {
                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: Colors.green.shade100,
                          child: Icon(Icons.verified, color: Colors.green.shade800, size: 20),
                        ),
                        title: Text(stat.pharmacyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${stat.totalReviews} avaliações de utentes'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: Colors.green.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: Colors.green.shade300),
                          ),
                          child: Text(
                            '${stat.averageRating}★',
                            style: TextStyle(fontWeight: FontWeight.w900, color: Colors.green.shade900),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 16),

          // Lowest Rated Pharmacies Section
          Card(
            shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Row(
                    children: [
                      Icon(Icons.report_problem_rounded, color: Colors.red, size: 24),
                      SizedBox(width: 8),
                      Text(
                        'Farmácias Com Menor Avaliação (Atenção Operacional) ⚠️',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15, color: Colors.red),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12),
                  if (state.lowestPharmacies.isEmpty)
                    const Text('Nenhuma farmácia com nota baixa registrada.', style: TextStyle(color: Colors.grey, fontSize: 12))
                  else
                    ...state.lowestPharmacies.map((stat) {
                      final isVeryLow = stat.averageRating <= 2.5;

                      return ListTile(
                        dense: true,
                        contentPadding: EdgeInsets.zero,
                        leading: CircleAvatar(
                          backgroundColor: isVeryLow ? Colors.red.shade100 : Colors.orange.shade100,
                          child: Icon(
                            isVeryLow ? Icons.error_outline_rounded : Icons.warning_rounded,
                            color: isVeryLow ? Colors.red.shade900 : Colors.orange.shade900,
                            size: 20,
                          ),
                        ),
                        title: Text(stat.pharmacyName, style: const TextStyle(fontWeight: FontWeight.bold)),
                        subtitle: Text('${stat.totalReviews} avaliações totais'),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: isVeryLow ? Colors.red.shade50 : Colors.orange.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(color: isVeryLow ? Colors.red.shade300 : Colors.orange.shade300),
                          ),
                          child: Text(
                            '${stat.averageRating}★',
                            style: TextStyle(
                              fontWeight: FontWeight.w900,
                              color: isVeryLow ? Colors.red.shade900 : Colors.orange.shade900,
                            ),
                          ),
                        ),
                      );
                    }),
                ],
              ),
            ),
          ),
          const SizedBox(height: 24),
        ],
      ),
    );
  }
}
