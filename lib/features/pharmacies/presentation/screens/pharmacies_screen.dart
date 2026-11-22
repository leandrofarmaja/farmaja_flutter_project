import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart' show Iconsax;
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/pharmacy_model.dart';
import '../../../reviews/presentation/widgets/pharmacy_reviews_list_widget.dart';
import '../providers/pharmacies_provider.dart';

class PharmaciesScreen extends ConsumerWidget {
  const PharmaciesScreen({super.key});

  static const Color _navy = Color(0xFF173B57);
  static const Color _green = Color(0xFF16A34A);
  static const Color _muted = Color(0xFF64748B);
  static const Color _border = Color(0xFFE5EEE8);

  TextStyle _textStyle({
    double size = 13,
    FontWeight weight = FontWeight.w500,
    Color color = _navy,
    double height = 1.4,
  }) {
    return GoogleFonts.plusJakartaSans(
      fontSize: size,
      fontWeight: weight,
      color: color,
      height: height,
    );
  }

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
                    color: const Color(0xFFE2E8F0),
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
                      style: _textStyle(
                        size: 17,
                        weight: FontWeight.w800,
                      ),
                    ),
                  ),
                ],
              ),
              if (pharmacy.address.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  pharmacy.address,
                  style: _textStyle(
                    size: 12,
                    color: _muted,
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        titleSpacing: 20,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Farmácias',
              style: _textStyle(
                size: 21,
                weight: FontWeight.w800,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              'Encontre os seus pontos de saúde',
              style: _textStyle(
                size: 11,
                color: _muted,
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
                    color: _green,
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
                  color: _green,
                  onRefresh: refreshPharmacies,
                  child: ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.fromLTRB(18, 12, 18, 28),
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
                          .fadeIn(duration: 350.ms)
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
                  color: _green,
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
          Text(
            'Encontre uma farmácia',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: const Color(0xFF173B57),
            ),
          ),
          const SizedBox(height: 5),
          Text(
            'Pesquise por nome, município ou bairro.',
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              color: const Color(0xFF64748B),
            ),
          ),
          const SizedBox(height: 14),
          TextField(
            onChanged: onSearchChanged,
            textInputAction: TextInputAction.search,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 13,
              color: const Color(0xFF173B57),
              fontWeight: FontWeight.w600,
            ),
            decoration: InputDecoration(
              hintText: 'Pesquisar farmácia...',
              hintStyle: GoogleFonts.plusJakartaSans(
                color: const Color(0xFF94A3B8),
                fontSize: 13,
              ),
              prefixIcon: const Icon(
                LucideIcons.search,
                color: Color(0xFF16A34A),
                size: 20,
              ),
              suffixIcon: searchQuery.isEmpty
                  ? null
                  : IconButton(
                      tooltip: 'Limpar pesquisa',
                      onPressed: onClear,
                      icon: const Icon(
                        Icons.close_rounded,
                        color: Color(0xFF64748B),
                      ),
                    ),
              filled: true,
              fillColor: const Color(0xFFF8FBF9),
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: const BorderSide(
                  color: Color(0xFFE5EEE8),
                ),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: const BorderSide(
                  color: Color(0xFFE5EEE8),
                ),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(17),
                borderSide: const BorderSide(
                  color: Color(0xFF16A34A),
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
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(23),
        border: Border.all(
          color: const Color(0xFFE5EEE8),
          width: 0.9,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173B57).withValues(alpha: 0.055),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
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
                        style: GoogleFonts.plusJakartaSans(
                          fontSize: 15,
                          height: 1.35,
                          fontWeight: FontWeight.w800,
                          color: const Color(0xFF173B57),
                        ),
                      ),
                      if (locationParts.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Icon(
                              Iconsax.location_bold,
                              size: 15,
                              color: Color(0xFF16A34A),
                            ),
                            const SizedBox(width: 5),
                            Expanded(
                              child: Text(
                                locationParts.join(', '),
                                style: GoogleFonts.plusJakartaSans(
                                  fontSize: 11,
                                  height: 1.45,
                                  color: const Color(0xFF64748B),
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
                            padding: const EdgeInsets.symmetric(vertical: 2),
                            child: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                const Icon(
                                  Iconsax.star_1_bold,
                                  color: Color(0xFFF59E0B),
                                  size: 16,
                                ),
                                const SizedBox(width: 5),
                                Text(
                                  pharmacy.rating.toStringAsFixed(1),
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 12,
                                    fontWeight: FontWeight.w800,
                                    color: const Color(0xFF173B57),
                                    fontFeatures: const [
                                      FontFeature.tabularFigures(),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 7),
                                Text(
                                  'Ver avaliações',
                                  style: GoogleFonts.plusJakartaSans(
                                    fontSize: 11,
                                    fontWeight: FontWeight.w600,
                                    color: const Color(0xFF64748B),
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
              const SizedBox(height: 16),
              const Divider(
                height: 1,
                color: Color(0xFFE5EEE8),
              ),
              const SizedBox(height: 14),
            ],
            if (hasAddress)
              _InfoRow(
                icon: Iconsax.location_bold,
                text: pharmacy.address,
              ),
            if (hasPhone) ...[
              if (hasAddress) const SizedBox(height: 10),
              _InfoRow(
                icon: Iconsax.call_bold,
                text: pharmacy.phone,
              ),
            ],
            if (hasHours || pharmacy.isOpen24h) ...[
              const SizedBox(height: 15),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  if (hasHours)
                    _InfoBadge(
                      icon: Iconsax.clock_bold,
                      label: openingHours,
                      green: openingHours.toLowerCase() == 'aberta',
                      red: openingHours.toLowerCase() == 'fechada',
                    ),
                  if (pharmacy.isOpen24h)
                    const _InfoBadge(
                      icon: Iconsax.tick_circle_bold,
                      label: '24 horas',
                      green: true,
                    ),
                ],
              ),
            ],
            const SizedBox(height: 13),
            Align(
              alignment: Alignment.centerRight,
              child: TextButton.icon(
                onPressed: onReviewsTap,
                icon: const Icon(
                  Iconsax.message_text_1_bold,
                  size: 16,
                ),
                label: Text(
                  'Avaliações',
                  style: GoogleFonts.plusJakartaSans(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                  ),
                ),
                style: TextButton.styleFrom(
                  foregroundColor: const Color(0xFF16A34A),
                  padding: const EdgeInsets.symmetric(
                    horizontal: 11,
                    vertical: 8,
                  ),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
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
          color: const Color(0xFF16A34A),
        ),
        const SizedBox(width: 9),
        Expanded(
          child: Text(
            text,
            style: GoogleFonts.plusJakartaSans(
              fontSize: 12,
              height: 1.5,
              color: const Color(0xFF64748B),
              fontWeight: FontWeight.w500,
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
        ? const Color(0xFF15803D)
        : red
            ? const Color(0xFFDC2626)
            : const Color(0xFF526477);

    final background = green
        ? const Color(0xFFDCFCE7)
        : red
            ? const Color(0xFFFEE2E2)
            : const Color(0xFFF2F7F4);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: foreground.withValues(alpha: 0.10),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: 14,
            color: foreground,
          ),
          const SizedBox(width: 6),
          Text(
            label,
            style: GoogleFonts.plusJakartaSans(
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
      padding: const EdgeInsets.all(26),
      children: [
        const SizedBox(height: 35),
        Center(
          child: Container(
            width: 190,
            height: 155,
            decoration: BoxDecoration(
              color: const Color(0xFFF3FAF5),
              borderRadius: BorderRadius.circular(28),
            ),
            padding: const EdgeInsets.all(12),
            child: Image.asset(
              'assets/images/Ilustração_3d_saude.jpg',
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                return const Icon(
                  Iconsax.shop_bold,
                  size: 54,
                  color: Color(0xFF16A34A),
                );
              },
            ),
          ),
        )
            .animate()
            .fadeIn(duration: 450.ms)
            .scale(
              begin: const Offset(0.92, 0.92),
              duration: 450.ms,
              curve: Curves.easeOutBack,
            ),
        const SizedBox(height: 25),
        Text(
          hasSearch
              ? 'Nenhuma farmácia encontrada.'
              : 'Ainda não existem farmácias registadas.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 17,
            fontWeight: FontWeight.w800,
            color: const Color(0xFF173B57),
          ),
        ),
        const SizedBox(height: 10),
        Text(
          hasSearch
              ? 'Experimente outro nome, município ou bairro.'
              : 'A lista será actualizada quando as farmácias parceiras forem registadas e os seus dados estiverem disponíveis.',
          textAlign: TextAlign.center,
          style: GoogleFonts.plusJakartaSans(
            fontSize: 12,
            height: 1.6,
            color: const Color(0xFF64748B),
          ),
        ),
        if (hasSearch) ...[
          const SizedBox(height: 18),
          Center(
            child: TextButton(
              onPressed: onClearSearch,
              child: Text(
                'Limpar pesquisa',
                style: GoogleFonts.plusJakartaSans(
                  color: const Color(0xFF16A34A),
                  fontWeight: FontWeight.w700,
                ),
              ),
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
              width: 78,
              height: 78,
              decoration: BoxDecoration(
                color: const Color(0xFFFFF1F2),
                borderRadius: BorderRadius.circular(25),
              ),
              child: const Icon(
                Icons.cloud_off_outlined,
                size: 36,
                color: Color(0xFFDC2626),
              ),
            ),
            const SizedBox(height: 19),
            Text(
              'Não foi possível carregar as farmácias.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 16,
                fontWeight: FontWeight.w800,
                color: const Color(0xFF173B57),
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verifique a ligação à Internet e tente novamente.',
              textAlign: TextAlign.center,
              style: GoogleFonts.plusJakartaSans(
                fontSize: 12,
                height: 1.55,
                color: const Color(0xFF64748B),
              ),
            ),
            const SizedBox(height: 19),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh_rounded),
              label: Text(
                'Tentar novamente',
                style: GoogleFonts.plusJakartaSans(
                  fontWeight: FontWeight.w700,
                  fontSize: 12,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: const Color(0xFF16A34A),
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(
                  horizontal: 21,
                  vertical: 13,
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
        color: const Color(0xFFDCFCE7),
        borderRadius: BorderRadius.circular(17),
      ),
      child: const Icon(
        Iconsax.shop_bold,
        color: Color(0xFF16A34A),
        size: 32,
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
              borderRadius: BorderRadius.circular(17),
            ),
            child: const SizedBox(
              width: 20,
              height: 20,
              child: CircularProgressIndicator(
                strokeWidth: 2,
                color: Color(0xFF16A34A),
              ),
            ),
          );
        }

        final url = snapshot.data;

        if (snapshot.hasError || url == null || url.isEmpty) {
          return _fallback();
        }

        return ClipRRect(
          borderRadius: BorderRadius.circular(17),
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
