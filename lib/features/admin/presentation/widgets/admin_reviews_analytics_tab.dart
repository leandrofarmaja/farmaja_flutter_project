import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/admin_reviews_provider.dart';

class AdminReviewsAnalyticsTab extends ConsumerWidget {
  const AdminReviewsAnalyticsTab({super.key});

  Widget _buildStarBar(int star, int count, int total) {
    final pct = total > 0 ? count / total : 0.0;

    final Color accent = star >= 4
        ? AppColors.primary
        : (star == 3 ? Colors.amber.shade700 : Colors.red.shade600);

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 5),
      child: Row(
        children: [
          SizedBox(
            width: 34,
            child: Text(
              '$star★',
              style: const TextStyle(
                fontWeight: FontWeight.w800,
                fontSize: 12,
                color: Color(0xFF173B57),
              ),
            ),
          ),
          const SizedBox(width: 9),
          Expanded(
            child: ClipRRect(
              borderRadius: BorderRadius.circular(20),
              child: LinearProgressIndicator(
                value: pct,
                minHeight: 9,
                backgroundColor: const Color(0xFFE8EEF2),
                color: accent,
              ),
            ),
          ),
          const SizedBox(width: 10),
          SizedBox(
            width: 58,
            child: Text(
              '$count (${(pct * 100).toStringAsFixed(0)}%)',
              textAlign: TextAlign.end,
              style: const TextStyle(
                fontSize: 11,
                fontWeight: FontWeight.w600,
                color: Colors.black54,
              ),
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
      return const Center(
        child: CircularProgressIndicator(),
      );
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
          const Text(
            'Relatório e análise de avaliações',
            style: TextStyle(
              fontSize: 19,
              fontWeight: FontWeight.w900,
              color: Color(0xFF173B57),
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Desempenho da aplicação FARCLIK e reputação das farmácias parceiras em Angola.',
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondaryLight,
            ),
          ),

          const SizedBox(height: 20),

          Row(
            children: [
              Expanded(
                child: _buildAverageCard(
                  icon: Icons.smartphone_rounded,
                  average: state.averageAppRating,
                  label: 'Média da aplicação',
                  background: const Color(0xFFEAF5EF),
                  accent: AppColors.primary,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _buildAverageCard(
                  icon: Icons.storefront_rounded,
                  average: state.averagePharmacyRating,
                  label: 'Média das farmácias',
                  background: const Color(0xFFFFF7E8),
                  accent: Colors.amber.shade800,
                ),
              ),
            ],
          ),

          const SizedBox(height: 20),

          _buildDistributionCard(
            title: 'Distribuição de estrelas',
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _buildDistributionSection(
                  title: 'Avaliações da aplicação FARCLIK',
                  icon: Icons.smartphone_rounded,
                  color: AppColors.primary,
                  distribution: state.appStarDistribution,
                  total: totalAppStars,
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(vertical: 18),
                  child: Divider(height: 1),
                ),
                _buildDistributionSection(
                  title: 'Avaliações das farmácias',
                  icon: Icons.storefront_rounded,
                  color: Colors.amber.shade800,
                  distribution: state.pharmacyStarDistribution,
                  total: totalPharmStars,
                ),
              ],
            ),
          ),

          const SizedBox(height: 20),

          _buildPharmacyRankingCard(
            title: 'Farmácias mais bem avaliadas',
            pharmacies: state.bestPharmacies,
            isBest: true,
          ),

          const SizedBox(height: 16),

          _buildPharmacyRankingCard(
            title: 'Farmácias com menor avaliação',
            pharmacies: state.lowestPharmacies,
            isBest: false,
          ),

          const SizedBox(height: 24),
        ],
      ),
    );
  }

  Widget _buildAverageCard({
    required IconData icon,
    required double average,
    required String label,
    required Color background,
    required Color accent,
  }) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 10,
        vertical: 18,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: accent.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        children: [
          Icon(
            icon,
            color: accent,
            size: 27,
          ),
          const SizedBox(height: 9),
          Text(
            average.toStringAsFixed(1),
            style: TextStyle(
              fontSize: 31,
              fontWeight: FontWeight.w900,
              color: accent,
            ),
          ),
          const SizedBox(height: 5),
          const Icon(
            Icons.star_rounded,
            color: Colors.amber,
            size: 17,
          ),
          const SizedBox(height: 5),
          Text(
            label,
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: Color(0xFF173B57),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildDistributionCard({
    required String title,
    required Widget child,
  }) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5ECF0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: const TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF173B57),
            ),
          ),
          const SizedBox(height: 18),
          child,
        ],
      ),
    );
  }

  Widget _buildDistributionSection({
    required String title,
    required IconData icon,
    required Color color,
    required Map<int, int> distribution,
    required int total,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Icon(
              icon,
              color: color,
              size: 19,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF173B57),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        for (int star = 5; star >= 1; star--)
          _buildStarBar(
            star,
            distribution[star] ?? 0,
            total,
          ),
      ],
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

    final accent = isBest ? AppColors.primary : Colors.red.shade700;

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: const Color(0xFFE5ECF0),
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.025),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                isBest
                    ? Icons.emoji_events_rounded
                    : Icons.warning_amber_rounded,
                color: accent,
                size: 21,
              ),
              const SizedBox(width: 9),
              Expanded(
                child: Text(
                  title,
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: isBest
                        ? const Color(0xFF173B57)
                        : accent,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),

          if (pharmacies.isEmpty)
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 12,
                vertical: 18,
              ),
              decoration: BoxDecoration(
                color: const Color(0xFFF8FAFC),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                emptyMessage,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: Colors.black54,
                  fontSize: 12,
                ),
              ),
            )
          else
            ...pharmacies.map((stat) {
              final isVeryLow = stat.averageRating <= 2.5;

              final Color itemAccent = isBest
                  ? AppColors.primary
                  : (isVeryLow
                      ? Colors.red.shade700
                      : Colors.orange.shade800);

              return Container(
                margin: const EdgeInsets.only(bottom: 9),
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 9,
                ),
                decoration: BoxDecoration(
                  color: const Color(0xFFF8FAFC),
                  borderRadius: BorderRadius.circular(13),
                ),
                child: Row(
                  children: [
                    CircleAvatar(
                      radius: 19,
                      backgroundColor:
                          itemAccent.withValues(alpha: 0.10),
                      child: Icon(
                        isBest
                            ? Icons.verified_rounded
                            : (isVeryLow
                                ? Icons.error_outline_rounded
                                : Icons.warning_rounded),
                        color: itemAccent,
                        size: 20,
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            stat.pharmacyName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w800,
                              fontSize: 12,
                              color: Color(0xFF173B57),
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            '${stat.totalReviews} avaliações',
                            style: const TextStyle(
                              fontSize: 11,
                              color: Colors.black54,
                            ),
                          ),
                        ],
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: itemAccent.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(10),
                        border: Border.all(
                          color: itemAccent.withValues(alpha: 0.22),
                        ),
                      ),
                      child: Text(
                        '${stat.averageRating}★',
                        style: TextStyle(
                          fontWeight: FontWeight.w900,
                          color: itemAccent,
                          fontSize: 13,
                        ),
                      ),
                    ),
                  ],
                ),
              );
            }),
        ],
      ),
    );
  }
}
