
import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../reservations/presentation/providers/reservations_provider.dart';
import '../../domain/medicine_model.dart';
import '../providers/medicines_provider.dart';

class MedicineDetailScreen extends ConsumerStatefulWidget {
  final String medicineId;

  const MedicineDetailScreen({
    super.key,
    required this.medicineId,
  });

  @override
  ConsumerState<MedicineDetailScreen> createState() =>
      _MedicineDetailScreenState();
}

class _MedicineDetailScreenState
    extends ConsumerState<MedicineDetailScreen> {
  bool _isCreatingReservation = false;
  late Future<MedicineModel?> _medicineFuture;

  @override
  void initState() {
    super.initState();
    _loadMedicine();
  }

  @override
  void didUpdateWidget(covariant MedicineDetailScreen oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.medicineId != widget.medicineId) {
      _loadMedicine();
    }
  }

  void _loadMedicine() {
    _medicineFuture = ref
        .read(medicinesRepositoryProvider)
        .getMedicineById(widget.medicineId);
  }

  void _retryLoading() {
    setState(_loadMedicine);
  }

  Future<void> _handleCreateReservation({
    required bool inStock,
    required String medicineId,
    required String pharmacyId,
  }) async {
    if (_isCreatingReservation) return;

    final user = ref.read(authProvider).user;

    if (user == null) {
      _showMessage(
        'Inicia sessão antes de efectuar a reserva.',
      );
      return;
    }

    if (!inStock) {
      _showMessage(
        'Este medicamento está sem stock e não pode ser reservado.',
      );
      return;
    }

    if (medicineId.trim().isEmpty ||
        pharmacyId.trim().isEmpty) {
      _showMessage(
        'Não foi possível identificar o medicamento ou a farmácia.',
      );
      return;
    }

    setState(() {
      _isCreatingReservation = true;
    });

    try {
      await ref.read(reservationsProvider.notifier).addReservation(
            medicineId: medicineId,
            pharmacyId: pharmacyId,
            prescriptionUploaded: false,
            prescriptionPath: null,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reserva criada com sucesso. Consulta os detalhes da reserva.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );

      context.go('/reservations');
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Não foi possível efectuar a reserva: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingReservation = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  Widget _buildMedicineImage(String? imageUrl) {
    final url = imageUrl?.trim() ?? '';

    return Container(
      height: 230,
      width: double.infinity,
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFDCFCE7),
            Color(0xFFCCFBF1),
            Color(0xFFEFF6FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      clipBehavior: Clip.antiAlias,
      child: url.isEmpty
          ? const Center(
              child: Icon(
                Icons.medication_rounded,
                size: 82,
                color: AppColors.primaryDark,
              ),
            )
          : Image.network(
              url,
              width: double.infinity,
              height: 230,
              fit: BoxFit.contain,
              loadingBuilder: (context, child, progress) {
                if (progress == null) return child;

                return const Center(
                  child: CircularProgressIndicator(
                    color: AppColors.primary,
                  ),
                );
              },
              errorBuilder: (context, error, stackTrace) {
                return const Center(
                  child: Icon(
                    Icons.medication_rounded,
                    size: 82,
                    color: AppColors.primaryDark,
                  ),
                );
              },
            ),
    );
  }

  Widget _buildLoading() {
    return const Center(
      child: CircularProgressIndicator(
        color: AppColors.primary,
      ),
    );
  }

  Widget _buildError(Object error) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              padding: const EdgeInsets.all(18),
              decoration: BoxDecoration(
                color: AppColors.danger.withValues(alpha: 0.08),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.cloud_off_rounded,
                color: AppColors.danger,
                size: 34,
              ),
            ),
            const SizedBox(height: 18),
            const Text(
              'Não foi possível carregar o medicamento',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 17,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Verifica a ligação à Internet e tenta novamente.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondaryLight,
                height: 1.4,
              ),
            ),
            const SizedBox(height: 22),
            FilledButton.icon(
              onPressed: _retryLoading,
              icon: const Icon(Icons.refresh_rounded),
              label: const Text('Tentar novamente'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNotFound() {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.medication_liquid_rounded,
              size: 58,
              color: AppColors.textSecondaryLight,
            ),
            const SizedBox(height: 16),
            const Text(
              'Medicamento não encontrado',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'Este medicamento não está disponível para consulta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                color: AppColors.textSecondaryLight,
              ),
            ),
            const SizedBox(height: 20),
            OutlinedButton.icon(
              onPressed: () => context.pop(),
              icon: const Icon(Icons.arrow_back_rounded),
              label: const Text('Voltar'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildSection({
    required String title,
    required String content,
    required IconData icon,
  }) {
    if (content.trim().isEmpty) {
      return const SizedBox.shrink();
    }

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 14),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 9),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 11),
          Text(
            content,
            style: const TextStyle(
              color: AppColors.textSecondaryLight,
              height: 1.55,
              fontSize: 14,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationValidity() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFEFF6FF),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFBFDBFE),
        ),
      ),
      child: const Row(
        children: [
          Icon(
            Icons.timer_outlined,
            color: AppColors.info,
            size: 27,
          ),
          SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Reserva válida por 2 horas',
                  style: TextStyle(
                    color: Color(0xFF1D4ED8),
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'A validade é definida pelo servidor quando a reserva é criada.',
                  style: TextStyle(
                    color: AppColors.textSecondaryLight,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionNotice() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(17),
      decoration: BoxDecoration(
        color: const Color(0xFFFFFBEB),
        borderRadius: BorderRadius.circular(19),
        border: Border.all(
          color: const Color(0xFFFDE68A),
        ),
      ),
      child: const Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            Icons.assignment_late_rounded,
            color: AppColors.warning,
            size: 25,
          ),
          SizedBox(width: 12),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Receita médica obrigatória',
                  style: TextStyle(
                    fontWeight: FontWeight.w800,
                    fontSize: 14,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                SizedBox(height: 8),
                Text(
                  'O envio de receitas ainda não está disponível. '
                  'Apresenta a receita médica directamente na farmácia '
                  'para verificação pelo farmacêutico.',
                  style: TextStyle(
                    fontSize: 12,
                    height: 1.5,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicineContent(
    MedicineModel med,
    MedicineFilterState filterState,
  ) {
    final hasPharmacyCoordinates =
        med.pharmacyLatitude != 0 &&
        med.pharmacyLongitude != 0;

    final hasPharmacyName = med.pharmacyName.trim().isNotEmpty;
    final hasDistrict = med.district.trim().isNotEmpty;

    final distance = hasPharmacyCoordinates
        ? med
            .calculateDistanceFrom(
              filterState.userLat,
              filterState.userLng,
            )
            .toStringAsFixed(1)
        : null;

    return SingleChildScrollView(
      physics: const BouncingScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 30),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          _buildMedicineImage(med.imageUrl)
              .animate()
              .fadeIn(duration: 350.ms)
              .slideY(begin: 0.04),
          const SizedBox(height: 19),

          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(23),
              border: Border.all(
                color: AppColors.borderLight,
              ),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primaryDark.withValues(alpha: 0.045),
                  blurRadius: 22,
                  offset: const Offset(0, 8),
                ),
              ],
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: Text(
                        med.name,
                        style: const TextStyle(
                          fontSize: 23,
                          height: 1.2,
                          fontWeight: FontWeight.w900,
                          color: AppColors.textPrimaryLight,
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      '${med.priceKz.toInt()} Kz',
                      style: const TextStyle(
                        fontSize: 19,
                        fontWeight: FontWeight.w900,
                        color: AppColors.primaryDark,
                      ),
                    ),
                  ],
                ),
                if (med.isGeneric) ...[
                  const SizedBox(height: 11),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 11,
                      vertical: 7,
                    ),
                    decoration: BoxDecoration(
                      color: AppColors.info.withValues(alpha: 0.08),
                      borderRadius: BorderRadius.circular(9),
                    ),
                    child: const Text(
                      'Medicamento genérico',
                      style: TextStyle(
                        color: AppColors.info,
                        fontWeight: FontWeight.w700,
                        fontSize: 11,
                      ),
                    ),
                  ),
                ],
                if (med.activeIngredient.trim().isNotEmpty) ...[
                  const SizedBox(height: 13),
                  Text(
                    'Princípio activo: ${med.activeIngredient}',
                    style: const TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondaryLight,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                ],
                const SizedBox(height: 18),
                Wrap(
                  spacing: 8,
                  runSpacing: 9,
                  children: [
                    if (hasPharmacyName)
                      _InfoChip(
                        icon: Icons.storefront_rounded,
                        label: hasDistrict
                            ? '${med.pharmacyName} (${med.district})'
                            : med.pharmacyName,
                        background: AppColors.primaryLight,
                        foreground: AppColors.primaryDark,
                      ),
                    if (distance != null)
                      _InfoChip(
                        icon: Icons.near_me_rounded,
                        label: '$distance km de distância',
                        background: AppColors.secondaryLight,
                        foreground: AppColors.secondary,
                      ),
                    _InfoChip(
                      icon: med.inStock
                          ? Icons.check_circle_rounded
                          : Icons.cancel_rounded,
                      label: med.inStock ? 'Disponível' : 'Sem stock',
                      background: med.inStock
                          ? AppColors.primaryLight
                          : AppColors.danger.withValues(alpha: 0.08),
                      foreground: med.inStock
                          ? AppColors.primaryDark
                          : AppColors.danger,
                    ),
                  ],
                ),
              ],
            ),
          )
              .animate()
              .fadeIn(duration: 400.ms, delay: 80.ms)
              .slideY(begin: 0.04),

          const SizedBox(height: 17),
          _buildReservationValidity(),

          if (med.description.trim().isNotEmpty) ...[
            const SizedBox(height: 20),
            _buildSection(
              title: 'Indicação e descrição',
              content: med.description,
              icon: Icons.info_outline_rounded,
            ),
          ],

          if (med.dosageInstructions.trim().isNotEmpty) ...[
            _buildSection(
              title: 'Posologia',
              content: med.dosageInstructions,
              icon: Icons.medical_information_outlined,
            ),
          ],

          if (med.requiresPrescription) ...[
            const SizedBox(height: 5),
            _buildPrescriptionNotice(),
          ],

          const SizedBox(height: 24),

          SizedBox(
            height: 56,
            child: FilledButton.icon(
              icon: _isCreatingReservation
                  ? const SizedBox(
                      width: 19,
                      height: 19,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        color: Colors.white,
                      ),
                    )
                  : const Icon(Icons.bookmark_add_rounded),
              label: Text(
                _isCreatingReservation
                    ? 'A criar reserva...'
                    : med.inStock
                        ? 'Confirmar reserva'
                        : 'Medicamento indisponível',
                style: const TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 15,
                ),
              ),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                disabledBackgroundColor:
                    AppColors.textSecondaryLight.withValues(alpha: 0.25),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(17),
                ),
              ),
              onPressed: _isCreatingReservation || !med.inStock
                  ? null
                  : () => _handleCreateReservation(
                        inStock: med.inStock,
                        medicineId: med.id,
                        pharmacyId: med.pharmacyId,
                      ),
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'A reserva fica sujeita à disponibilidade confirmada pela farmácia.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: AppColors.textSecondaryLight,
              fontSize: 11,
              height: 1.4,
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final filterState = ref.watch(medicineFilterProvider);

    return Scaffold(
      backgroundColor: AppColors.backgroundLight,
      appBar: AppBar(
        backgroundColor: Colors.white,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        centerTitle: false,
        leading: IconButton(
          onPressed: () => context.pop(),
          icon: const Icon(Icons.arrow_back_rounded),
          color: AppColors.textPrimaryLight,
        ),
        title: const Text(
          'Detalhes do medicamento',
          style: TextStyle(
            color: AppColors.textPrimaryLight,
            fontWeight: FontWeight.w800,
            fontSize: 18,
          ),
        ),
      ),
      body: FutureBuilder<MedicineModel?>(
        future: _medicineFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return _buildLoading();
          }

          if (snapshot.hasError) {
            return _buildError(snapshot.error!);
          }

          final med = snapshot.data;

          if (med == null) {
            return _buildNotFound();
          }

          return _buildMedicineContent(med, filterState);
        },
      ),
    );
  }
}

class _InfoChip extends StatelessWidget {
  final IconData icon;
  final String label;
  final Color background;
  final Color foreground;

  const _InfoChip({
    required this.icon,
    required this.label,
    required this.background,
    required this.foreground,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 9,
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
            size: 15,
            color: foreground,
          ),
          const SizedBox(width: 6),
          Flexible(
            child: Text(
              label,
              style: TextStyle(
                color: foreground,
                fontSize: 11,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
