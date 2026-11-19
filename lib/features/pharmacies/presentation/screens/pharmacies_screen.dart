
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/pharmacy_model.dart';
import '../../../reviews/presentation/widgets/pharmacy_reviews_list_widget.dart';
import '../providers/pharmacies_provider.dart';

class PharmaciesScreen extends ConsumerWidget {
  const PharmaciesScreen({super.key});

  void _showPharmacyReviewsModal(
    BuildContext context,
    PharmacyModel pharmacy,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(
          top: Radius.circular(28),
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
                  width: 42,
                  height: 5,
                  margin: const EdgeInsets.only(bottom: 22),
                  decoration: BoxDecoration(
                    color: AppColors.borderLight,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  _PharmacyImage(imagePath: pharmacy.logoUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      pharmacy.name,
                      style: const TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.w800,
                        color: AppColors.textPrimaryLight,
                      ),
                    ),
                  ),
                ],
              ),
              if (pharmacy.address.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  pharmacy.address,
                  style: const TextStyle(
                    fontSize: 13,
                    height: 1.5,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
              const SizedBox(height: 20),
              PharmacyReviewsListWidget(
                pharmacyId: pharmacy.id,
                pharmacyName: pharmacy.name,
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

    Future<void> refreshPharmacies() async {
      ref.invalidate(pharmaciesListProvider);

      try {
        await ref.read(pharmaciesListProvider.future);
      } catch (_) {
        // O estado de erro é apresentado pelo provider.
      }
    }

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farmácias',
              style: TextStyle(
                color: AppColors.textPrimaryLight,
                fontSize: 21,
                fontWeight: FontWeight.w800,
                letterSpacing: -0.5,
              ),
            ),
            SizedBox(height: 2),
            Text(
              'Encontre os seus pontos de saúde',
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 11,
                fontWeight: FontWeight.w500,
              ),
            ),
          ],
        ),
      ),
      body: Column(
        children: [
          _SearchHeader(
            searchQuery: searchQuery,
            onSearchChanged: (value) {
              ref.read(pharmaciesSearchQueryProvider.notifier).state =
                  value;
            },
            onClear: () {
              ref.read(pharmaciesSearchQueryProvider.notifier).state = '';
            },
          ),
          Expanded(
            child: pharmaciesAsync.when(
              data: (pharmacies) {
                if (pharmacies.isEmpty) {
                  return RefreshIndicator(
                    color: AppColors.primary,
                    onRefresh: refreshPharmacies,
                    child: _EmptyPharmacies(
                      hasSearch: searchQuery.trim().isNotEmpty,
                      onClearSearch: () {
                        ref
                            .read(pharmaciesSearchQueryProvider.notifier)
                            .state = '';
                      },
                    ),
                  );
                }

                return RefreshIndicator(
                  color: AppColors.primary,
                  onRefresh: refreshPharmacies,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 8, 18, 28),
                    itemCount: pharmacies.length,
                    itemBuilder: (context, index) {
                      final pharmacy = pharmacies[index];

                      return _PharmacyCard(
                        pharmacy: pharmacy,
                        onReviewsTap: () {
                          _showPharmacyReviewsModal(
                            context,
                            pharmacy,
                          );
                        },
                      )
                          .animate(
                            delay: Duration(
                              milliseconds: index < 6 ? index * 65 : 0,
                            ),
                          )
                          .fadeIn(
                            duration: 350.ms,
                          )
                          .slideY(
                            begin: 0.06,
                            end: 0,
                            duration: 350.ms,
                            curve: Curves.easeOutCubic,
                          );
                    },
                  ),
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                  strokeWidth: 2.5,
                ),
              ),
              error: (error, stack) => _PharmaciesError(
                onRetry: refreshPharmacies,
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _SearchHeader extends StatelessWidget {
  final String searchQuery;
  final ValueChanged<String> onSearchChanged;
  final VoidCallback onClear;

  const _SearchHeader({
    required this.searchQuery,
    required this.onSearchChanged,
    required this.onClear,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      color: Colors.white,
      padding: const EdgeInsets.fromLTRB(18, 8, 18, 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Encontre uma farmácia',
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: AppColors.textPrimaryLight,
            ),
          ),
          const SizedBox(height: 5),
          const Text(
            'Pesquise por nome, município ou bairro.',
            style: TextStyle(
              fontSize: 12,
              color: AppColors.textSecondaryLight,
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            decoration: InputDecoration(
              hintText: 'Pesquisar farmácia...',
              hintStyle: const TextStyle(
                color: AppColors.textSecondaryLight,
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                Icons.search_rounded,
                color: AppColors.primary,
                size: 21,
              ),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar pesquisa',
                      onPressed: onClear,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
              filled: true,
              fillColor: const Color(0xFFF7FAF8),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 15,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: BorderSide.none,
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.borderLight,
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(16),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.4,
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _PharmacyCard extends StatelessWidget {
  final PharmacyModel pharmacy;
  final VoidCallback onReviewsTap;

  const _PharmacyCard({
    required this.pharmacy,
    required this.onReviewsTap,
  });

  @override
  Widget build(BuildContext context) {
    final hasAddress = pharmacy.address.trim().isNotEmpty;
    final hasPhone = pharmacy.phone.trim().isNotEmpty;

    final openingHours = pharmacy.openingHours.trim();
    final hasHours = openingHours.isNotEmpty &&
        openingHours.toLowerCase() != 'desconhecido' &&
        openingHours.toLowerCase() != 'não informado';

    final locationParts = <String>[
      if (pharmacy.neighborhood.trim().isNotEmpty)
        pharmacy.neighborhood.trim(),
      if (pharmacy.district.trim().isNotEmpty)
        pharmacy.district.trim(),
      if (pharmacy.province.trim().isNotEmpty)
        pharmacy.province.trim(),
    ];

    return Container(
      margin: const EdgeInsets.only(bottom: 15),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.borderLight,
          width: 0.8,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173B57).withValues(alpha: 0.045),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                _PharmacyImage(imagePath: pharmacy.logoUrl),
                const SizedBox(width: 14),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        pharmacy.name,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          fontSize: 15,
                          height: 1.3,
                          fontWeight: FontWeight.w800,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                      if (locationParts.isNotEmpty) ...[
                        const SizedBox(height: 7),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Icons.location_on_outlined,
                              size: 15,
                              color: AppColors.primary,
                            ),
                            const SizedBox(width: 4),
                            Expanded(
                              child: Text(
                                locationParts.join(', '),
                                style: const TextStyle(
                                  fontSize: 11,
                                  height: 1.4,
                                  color: AppColors.textSecondaryLight,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                      if (pharmacy.rating > 0) ...[
                        const SizedBox(height: 9),
                        InkWell(
                          onTap: onReviewsTap,
                          borderRadius: BorderRadius.circular(8),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(
                              vertical: 2,
                            ),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Icons.star_rounded,
                                  color: Color(0xFFF5B400),
                                  size: 18,
                                ),
                                const SizedBox(width: 4),
                                Text(
                                  pharmacy.rating.toStringAsFixed(1),
                                  style: const TextStyle(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: AppColors.textPrimaryLight,
                                    fontFeatures: [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 6),
                                const Text(
                                  'Ver avaliações',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: AppColors.textSecondaryLight,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              ],
            ),
            if (hasAddress || hasPhone) ...[
              const SizedBox(height: 15),
              const Divider(
                height: 1,
                color: AppColors.borderLight,
              ),
              const SizedBox(height: 13),
            ],
            if (hasAddress)
              _InfoRow(
                icon: Icons.place_outlined,
                text: pharmacy.address,
              ),
            if (hasPhone) ...[
              if (hasAddress) const SizedBox(height: 9),
              _InfoRow(
                icon: Icons.phone_outlined,
                text: pharmacy.phone,
              ),
            ],
            if (hasHours || pharmacy.isOpen24h) ...[
              const SizedBox(height: 14),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (hasHours)
                    _InfoBadge(
                      icon: Icons.access_time_rounded,
                      label: openingHours,
                      green: openingHours.toLowerCase() == 'aberta',
                      red: openingHours.toLowerCase() == 'fechada',
                    ),
                  if (pharmacy.isOpen24h)
                    const _InfoBadge(
                      icon: Icons.check_circle_outline_rounded,
                      label: '24 horas',
                      green: true,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 12),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onReviewsTap,
                icon: const Icon(
                  Icons.reviews_outlined,
                  size: 17,
                ),
                label: const Text('Avaliações'),
                style: TextButton.styleFrom(
                  foregroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 7,
                  ),
                  textStyle: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String text;

  const _InfoRow({
    required this.icon,
    required this.text,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(
          icon,
          size: 16,
          color: AppColors.primary,
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(
              fontSize: 12,
              height: 1.45,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }
}

class _InfoBadge extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool green;
  final bool red;

  const _InfoBadge({
    required this.icon,
    required this.label,
    this.green = false,
    this.red = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground = green
        ? AppColors.primaryDark
        : red
            ? AppColors.danger
            : const Color(0xFF526477);

    final background = green
        ? AppColors.primaryLight
        : red
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFF2F6F4);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(11),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: 5),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              fontWeight: FontWeight.w700,
              color: foreground,
            ),
          ),
        ],
      ),
    );
  }
}

class _EmptyPharmacies extends StatelessWidget {
  final bool hasSearch;
  final VoidCallback onClearSearch;

  const _EmptyPharmacies({
    required this.hasSearch,
    required this.onClearSearch,
  });

  @override
  Widget build(BuildContext context) {
    return ListView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.all(28),
      children: [
        const SizedBox(height: 65),
        Center(
          child: Container(
            width: 88,
            height: 88,
            decoration: BoxDecoration(
              color: AppColors.primaryLight,
              borderRadius: BorderRadius.circular(27),
            ),
            child: const Icon(
              Icons.local_pharmacy_rounded,
              size: 43,
              color: AppColors.primary,
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 400.ms)
            .scale(begin: const Offset(0.9, 0.9)),
        const SizedBox(height: 22),
        Text(
          hasSearch
              ? 'Nenhuma farmácia encontrada.'
              : 'Ainda não existem farmácias registadas.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: AppColors.textPrimaryLight,
          ),
        ),
        const SizedBox(height: 9),
        Text(
          hasSearch
              ? 'Experimente outro nome, município ou bairro.'
              : 'A lista será actualizada quando as farmácias parceiras forem registadas e os seus dados estiverem disponíveis.',
          textAlign: TextAlign.center,
          style: const TextStyle(
            fontSize: 13,
            height: 1.55,
            color: AppColors.textSecondaryLight,
          ),
        ),
        if (hasSearch) ...[
          const SizedBox(height: 17),
          Center(
            child: TextButton(
              onPressed: onClearSearch,
              child: const Text('Limpar pesquisa'),
            ),
          ),
        ],
      ],
    );
  }
}

class _PharmaciesError extends StatelessWidget {
  final Future<void> Function() onRetry;

  const _PharmaciesError({
    required this.onRetry,
  });

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 76,
              height: 76,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(24),
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                size: 36,
                color: AppColors.danger,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Não foi possível carregar as farmácias.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 7),
            const Text(
              'Verifique a ligação à Internet e tente novamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 12,
                height: 1.5,
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 18),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 20,
                  vertical: 12,
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(14),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _PharmacyImage extends StatefulWidget {
  final String imagePath;
  final double size;

  const _PharmacyImage({
    required this.imagePath,
    this.size = 76,
  });

  @override
  State<_PharmacyImage> createState() => _PharmacyImageState();
}

class _PharmacyImageState extends State<_PharmacyImage> {
  Future<String?>? _imageUrlFuture;

  @override
  void initState() {
    super.initState();
    _loadImage();
  }

  @override
  void didUpdateWidget(covariant _PharmacyImage oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.imagePath != widget.imagePath) {
      _loadImage();
    }
  }

  void _loadImage() {
    final path = widget.imagePath.trim();

    if (path.isEmpty) {
      _imageUrlFuture = Future<String?>.value(null);
      return;
    }

    if (path.startsWith('https://') || path.startsWith('http://')) {
      _imageUrlFuture = Future<String?>.value(path);
      return;
    }

    _imageUrlFuture = Supabase.instance.client.storage
        .from('pharmacy-photos')
        .createSignedUrl(path, 3600);
  }

  Widget _fallback() {
    return Container(
      width: widget.size,
      height: widget.size,
      decoration: BoxDecoration(
        color: AppColors.primaryLight,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Icon(
        Icons.local_pharmacy_rounded,
        color: AppColors.primary,
        size: 34,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return FutureBuilder<String?>(
      future: _imageUrlFuture,
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return Container(
            width: widget.size,
            height: widget.size,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              color: const Color(0xFFF2F8F4),
              borderRadius: BorderRadius.circular(16),
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: AppColors.primary,
              ),
            ),
          );
        }

        final url = snapshot.data;

        if (snapshot.hasError || url == null || url.isEmpty) {
          return _fallback();
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(16),
          child: Image.network(
            url,
            width: widget.size,
            height: widget.size,
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) => _fallback(),
          ),
        );
      },
    );
  }
}
