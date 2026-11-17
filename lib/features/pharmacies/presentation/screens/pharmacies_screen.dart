
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../domain/pharmacy_model.dart';
import '../../../reviews/presentation/widgets/pharmacy_reviews_list_widget.dart';
import '../providers/pharmacies_provider.dart';

class PharmaciesScreen extends ConsumerWidget {
  const PharmaciesScreen({super.key});

  Widget _pharmacyImage(String imagePath, {double size = 76}) {
    return _PharmacyImage(imagePath: imagePath, size: size);
  }

  void _showPharmacyReviewsModal(
    BuildContext context,
    PharmacyModel pharm,
  ) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.white,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(28)),
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
                    color: Colors.grey.shade300,
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
              ),
              Row(
                children: [
                  _pharmacyImage(pharm.logoUrl),
                  const SizedBox(width: 14),
                  Expanded(
                    child: Text(
                      pharm.name,
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF173B57),
                      ),
                    ),
                  ),
                ],
              ),
              if (pharm.address.trim().isNotEmpty) ...[
                const SizedBox(height: 10),
                Text(
                  pharm.address,
                  style: const TextStyle(
                    fontSize: 13,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
              const SizedBox(height: 20),
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        backgroundColor: Colors.white,
        elevation: 0,
        scrolledUnderElevation: 0,
        centerTitle: false,
        title: const Text(
          'Farmácias',
          style: TextStyle(
            color: Color(0xFF173B57),
            fontSize: 21,
            fontWeight: FontWeight.w800,
          ),
        ),
      ),
      body: Column(
        children: [
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 8, 16, 14),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Encontre uma farmácia',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF173B57),
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Pesquise por nome, município ou bairro.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
                const SizedBox(height: 14),
                TextField(
                  onChanged: (value) {
                    ref
                        .read(pharmaciesSearchQueryProvider.notifier)
                        .state = value;
                  },
                  decoration: InputDecoration(
                    hintText: 'Pesquisar farmácia...',
                    hintStyle: TextStyle(
                      color: Colors.grey.shade500,
                      fontSize: 13,
                    ),
                    prefixIcon: const Icon(
                      Icons.search_rounded,
                      color: AppColors.primary,
                    ),
                    suffixIcon: searchQuery.isEmpty
                        ? null
                        : IconButton(
                            tooltip: 'Limpar pesquisa',
                            icon: const Icon(Icons.close_rounded),
                            onPressed: () {
                              ref
                                  .read(
                                    pharmaciesSearchQueryProvider.notifier,
                                  )
                                  .state = '';
                            },
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
                      borderSide: BorderSide(
                        color: Colors.grey.shade200,
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
          ),
          Expanded(
            child: pharmaciesAsync.when(
              data: (pharmacies) {
                if (pharmacies.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(28),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Container(
                            width: 82,
                            height: 82,
                            decoration: BoxDecoration(
                              color: const Color(0xFFDCFCE7),
                              borderRadius: BorderRadius.circular(24),
                            ),
                            child: const Icon(
                              Icons.local_pharmacy_rounded,
                              size: 42,
                              color: AppColors.primary,
                            ),
                          ),
                          const SizedBox(height: 20),
                          Text(
                            searchQuery.trim().isNotEmpty
                                ? 'Nenhuma farmácia encontrada.'
                                : 'Ainda não existem farmácias registadas.',
                            textAlign: TextAlign.center,
                            style: const TextStyle(
                              fontSize: 17,
                              fontWeight: FontWeight.w800,
                              color: Color(0xFF173B57),
                            ),
                          ),
                          const SizedBox(height: 9),
                          Text(
                            searchQuery.trim().isNotEmpty
                                ? 'Experimenta outro nome, município ou bairro.'
                                : 'A lista será actualizada quando as farmácias parceiras forem registadas e os seus dados estiverem disponíveis.',
                            textAlign: TextAlign.center,
                            style: TextStyle(
                              fontSize: 13,
                              height: 1.5,
                              color: Colors.grey.shade600,
                            ),
                          ),
                          if (searchQuery.trim().isNotEmpty) ...[
                            const SizedBox(height: 14),
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
                  padding: const EdgeInsets.fromLTRB(16, 2, 16, 24),
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

                    return Container(
                      margin: const EdgeInsets.only(bottom: 14),
                      decoration: BoxDecoration(
                        color: Colors.white,
                        borderRadius: BorderRadius.circular(20),
                        border: Border.all(
                          color: const Color(0xFFE9EFEC),
                        ),
                        boxShadow: [
                          BoxShadow(
                            color: Colors.black.withValues(alpha: 0.035),
                            blurRadius: 14,
                            offset: const Offset(0, 5),
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
                                _pharmacyImage(pharm.logoUrl),
                                const SizedBox(width: 14),
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        pharm.name,
                                        style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.w800,
                                          color: Color(0xFF173B57),
                                        ),
                                      ),
                                      if (locationParts.isNotEmpty) ...[
                                        const SizedBox(height: 7),
                                        Row(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
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
                                                style: TextStyle(
                                                  fontSize: 12,
                                                  height: 1.4,
                                                  color: Colors.grey.shade600,
                                                ),
                                              ),
                                            ),
                                          ],
                                        ),
                                      ],
                                      if (pharm.rating > 0) ...[
                                        const SizedBox(height: 8),
                                        InkWell(
                                          onTap: () =>
                                              _showPharmacyReviewsModal(
                                            context,
                                            pharm,
                                          ),
                                          borderRadius:
                                              BorderRadius.circular(8),
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
                                                pharm.rating.toStringAsFixed(1),
                                                style: const TextStyle(
                                                  fontSize: 13,
                                                  fontWeight: FontWeight.w800,
                                                  color: Color(0xFF173B57),
                                                ),
                                              ),
                                              const SizedBox(width: 5),
                                              Text(
                                                'Ver avaliações',
                                                style: TextStyle(
                                                  fontSize: 11,
                                                  color: Colors.grey.shade600,
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
                            if (hasAddress || hasPhone) ...[
                              const SizedBox(height: 14),
                              const Divider(height: 1),
                              const SizedBox(height: 12),
                            ],
                            if (hasAddress)
                              _InfoRow(
                                icon: Icons.place_outlined,
                                text: pharm.address,
                              ),
                            if (hasPhone) ...[
                              if (hasAddress) const SizedBox(height: 8),
                              _InfoRow(
                                icon: Icons.phone_outlined,
                                text: pharm.phone,
                              ),
                            ],
                            if (hasHours || pharm.isOpen24h) ...[
                              const SizedBox(height: 14),
                              Wrap(
                                spacing: 8,
                                runSpacing: 8,
                                children: [
                                  if (hasHours)
                                    _InfoBadge(
                                      icon: Icons.access_time_rounded,
                                      label: pharm.openingHours,
                                    ),
                                  if (pharm.isOpen24h)
                                    const _InfoBadge(
                                      icon: Icons.check_circle_outline,
                                      label: '24 horas',
                                      green: true,
                                    ),
                                      
                                      
                                      
                                    
                                ],
                              ),
                            ],
                            const SizedBox(height: 10),
                            Align(
                              alignment: Alignment.centerRight,
                              child: TextButton.icon(
                                onPressed: () =>
                                    _showPharmacyReviewsModal(context, pharm),
                                icon: const Icon(
                                  Icons.reviews_outlined,
                                  size: 17,
                                ),
                                label: const Text('Avaliações'),
                                style: TextButton.styleFrom(
                                  foregroundColor: AppColors.primary,
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
                  },
                );
              },
              loading: () => const Center(
                child: CircularProgressIndicator(
                  color: AppColors.primary,
                ),
              ),
              error: (err, stack) => Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.cloud_off_outlined,
                        size: 44,
                        color: Colors.grey.shade400,
                      ),
                      const SizedBox(height: 14),
                      const Text(
                        'Não foi possível carregar as farmácias.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontWeight: FontWeight.w700,
                          color: Color(0xFF173B57),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        'Verifica a ligação e tenta novamente.',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.grey.shade600,
                        ),
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
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: TextStyle(
              fontSize: 12,
              height: 1.4,
              color: Colors.grey.shade700,
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

  const _InfoBadge({
    required this.icon,
    required this.label,
    this.green = false,
  });

  @override
  Widget build(BuildContext context) {
    final foreground =
        green ? const Color(0xFF15803D) : const Color(0xFF526477);
    final background =
        green ? const Color(0xFFDCFCE7) : const Color(0xFFF2F6F4);

    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 7,
      ),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 14, color: foreground),
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

class _PharmacyImage extends StatefulWidget {
  final String imagePath;
  final double size;

  const _PharmacyImage({
    required this.imagePath,
    required this.size,
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
        borderRadius: BorderRadius.circular(15),
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
              borderRadius: BorderRadius.circular(15),
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
          borderRadius: BorderRadius.circular(15),
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
