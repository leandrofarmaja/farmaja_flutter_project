
import 'dart:async';
import 'dart:ui' show FontFeature;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/qr_code_widget.dart';
import '../../domain/reservation_model.dart';
import '../../../reviews/presentation/widgets/rate_experience_dialog.dart';
import '../providers/reservations_provider.dart';

class ReservationsScreen extends ConsumerWidget {
  const ReservationsScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservations = ref.watch(reservationsProvider);

    return Scaffold(
      backgroundColor: const Color(0xFFF7FBF8),
      appBar: AppBar(
        title: const Text('Minhas Reservas'),
        backgroundColor: Colors.white,
        foregroundColor: AppColors.textPrimaryLight,
        elevation: 0,
        scrolledUnderElevation: 0,
        actions: [
          IconButton(
            tooltip: 'Actualizar reservas',
            onPressed: () {
              ref.read(reservationsProvider.notifier).fetchReservations();
            },
            icon: const Icon(Icons.refresh_rounded),
          ),
          const SizedBox(width: 6),
        ],
      ),
      body: reservations.isEmpty
          ? const _EmptyReservations()
          : RefreshIndicator(
              color: AppColors.primary,
              backgroundColor: Colors.white,
              onRefresh: () async {
                await ref
                    .read(reservationsProvider.notifier)
                    .fetchReservations();
              },
              child: ListView.builder(
                physics: const AlwaysScrollableScrollPhysics(),
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 28),
                itemCount: reservations.length,
                itemBuilder: (context, index) {
                  final reservation = reservations[index];

                  return _ReservationCard(
                    key: ValueKey(reservation.id),
                    reservation: reservation,
                    onRating: () {
                      _showRatingDialog(context, ref, reservation);
                    },
                  )
                      .animate(delay: (index * 70).ms)
                      .fadeIn(duration: 350.ms)
                      .slideY(begin: 0.06, end: 0);
                },
              ),
            ),
    );
  }

  void _showRatingDialog(
    BuildContext context,
    WidgetRef ref,
    ReservationModel reservation,
  ) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) {
        return RateExperienceDialog(
          reservation: reservation,
          onSubmitted: () {
            ref
                .read(reservationsProvider.notifier)
                .fetchReservations();
          },
        );
      },
    );
  }
}

class _EmptyReservations extends StatelessWidget {
  const _EmptyReservations();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        physics: const AlwaysScrollableScrollPhysics(),
        padding: const EdgeInsets.all(28),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 112,
              height: 112,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(34),
              ),
              child: const Icon(
                Icons.receipt_long_rounded,
                size: 52,
                color: AppColors.primary,
              ),
            )
                .animate()
                .fadeIn(duration: 500.ms)
                .scale(begin: const Offset(0.85, 0.85)),
            const SizedBox(height: 24),
            const Text(
              'Ainda não possui reservas',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: AppColors.textPrimaryLight,
              ),
            ),
            const SizedBox(height: 10),
            const Text(
              'Quando reservar medicamentos numa farmácia, '
              'poderá acompanhar aqui o estado e o prazo da sua reserva.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                height: 1.6,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationCard extends ConsumerStatefulWidget {
  final ReservationModel reservation;
  final VoidCallback onRating;

  const _ReservationCard({
    super.key,
    required this.reservation,
    required this.onRating,
  });

  @override
  ConsumerState<_ReservationCard> createState() =>
      _ReservationCardState();
}

class _ReservationCardState extends ConsumerState<_ReservationCard> {
  Timer? _timer;
  DateTime _now = DateTime.now();

  ReservationModel get reservation => widget.reservation;

  String get _normalizedStatus =>
      reservation.status.trim().toLowerCase();

  bool get _isAwaitingPayment =>
      _normalizedStatus == 'aguardando confirmação' ||
      _normalizedStatus == 'aguardando confirmacao' ||
      _normalizedStatus == 'pending';

  bool get _isPaid => _normalizedStatus == 'pago';

  bool get _isExpired =>
      _normalizedStatus == 'expirada' ||
      _normalizedStatus == 'expired';

  bool get _isCompleted =>
      _normalizedStatus == 'levantada' ||
      _normalizedStatus == 'completed' ||
      _normalizedStatus == 'entregue' ||
      _normalizedStatus == 'resgatado';

  bool get _qrWasValidated =>
      reservation.qrValidadoEm != null;

  bool get _canRate =>
      _isCompleted && !reservation.isReviewed;

  DateTime? get _expiryDate {
    final value = DateTime.tryParse(reservation.expiryDate);
    return value?.toLocal();
  }

  Duration? get _remainingTime {
    final expiry = _expiryDate;
    if (expiry == null) return null;

    final difference = expiry.difference(_now);
    return difference.isNegative ? Duration.zero : difference;
  }

  bool get _deadlineReached {
    final remaining = _remainingTime;
    return remaining != null && remaining == Duration.zero;
  }

  bool get _hasValidExpiry => _expiryDate != null;

  bool get _canShowQr =>
      reservation.pickupCode.isNotEmpty &&
      !_isExpired &&
      !_isCompleted &&
      !_deadlineReached;

  bool get _canConfirmPurchase =>
      _isAwaitingPayment &&
      _qrWasValidated &&
      !_isExpired &&
      !_deadlineReached;

  Color get _statusColor {
    if (_isCompleted || _isPaid) return AppColors.success;
    if (_isExpired || _deadlineReached) return AppColors.danger;
    if (_isAwaitingPayment) return AppColors.warning;
    return AppColors.info;
  }

  String get _statusText {
    if (_isCompleted) return 'Levantada';
    if (_isExpired || _deadlineReached) return 'Expirada';
    if (_isPaid) return 'Pago';
    if (_isAwaitingPayment) return 'Aguardando confirmação';
    return reservation.status;
  }

  IconData get _statusIcon {
    if (_isCompleted) return Icons.check_circle_rounded;
    if (_isExpired || _deadlineReached) {
      return Icons.timer_off_rounded;
    }
    if (_isPaid) return Icons.verified_rounded;
    if (_isAwaitingPayment) return Icons.schedule_rounded;
    return Icons.info_outline_rounded;
  }

  @override
  void initState() {
    super.initState();
    _startCountdown();
  }

  @override
  void didUpdateWidget(covariant _ReservationCard oldWidget) {
    super.didUpdateWidget(oldWidget);

    if (oldWidget.reservation.expiryDate !=
        widget.reservation.expiryDate) {
      _now = DateTime.now();
      _startCountdown();
    }
  }

  void _startCountdown() {
    _timer?.cancel();

    if (_expiryDate == null || _isExpired || _isCompleted) {
      return;
    }

    _timer = Timer.periodic(
      const Duration(seconds: 1),
      (_) {
        if (!mounted) return;

        setState(() {
          _now = DateTime.now();
        });

        if (_deadlineReached) {
          _timer?.cancel();
        }
      },
    );
  }

  @override
  void dispose() {
    _timer?.cancel();
    super.dispose();
  }

  String _formatDuration(Duration duration) {
    final hours = duration.inHours;
    final minutes = duration.inMinutes.remainder(60);
    final seconds = duration.inSeconds.remainder(60);

    return '${hours.toString().padLeft(2, '0')}:'
        '${minutes.toString().padLeft(2, '0')}:'
        '${seconds.toString().padLeft(2, '0')}';
  }

  Widget _buildCountdown() {
    if (!_hasValidExpiry || _isExpired || _isCompleted) {
      return const SizedBox.shrink();
    }

    if (_deadlineReached) {
      return _CountdownMessage(
        color: AppColors.danger,
        icon: Icons.timer_off_rounded,
        message: 'O prazo desta reserva terminou. '
            'O código QR já não pode ser utilizado.',
      );
    }

    final remaining = _remainingTime;
    if (remaining == null) return const SizedBox.shrink();

    final isUrgent = remaining.inMinutes < 15;
    final color = isUrgent ? AppColors.danger : AppColors.warning;

    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: color.withValues(alpha: 0.18),
        ),
      ),
      child: Row(
        children: [
          Container(
            width: 44,
            height: 44,
            decoration: BoxDecoration(
              color: color.withValues(alpha: 0.12),
              borderRadius: BorderRadius.circular(14),
            ),
            child: Icon(
              Icons.timer_outlined,
              color: color,
              size: 23,
            ),
          ),
          const SizedBox(width: 13),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  isUrgent
                      ? 'A reserva está quase a expirar'
                      : 'Tempo restante da reserva',
                  style: TextStyle(
                    color: color,
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  _formatDuration(remaining),
                  style: TextStyle(
                    color: color,
                    fontSize: 23,
                    fontWeight: FontWeight.w800,
                    fontFeatures: const [
                      FontFeature.tabularFigures(),
                    ],
                  ),
                ),
              ],
            ),
          ),
          Icon(
            Icons.access_time_filled_rounded,
            color: color.withValues(alpha: 0.65),
            size: 20,
          ),
        ],
      ),
    );
  }

  Future<void> _confirmPurchase() async {
    if (!_canConfirmPurchase) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(24),
          ),
          title: const Text(
            'Confirmar compra',
            style: TextStyle(fontWeight: FontWeight.w800),
          ),
          content: const Text(
            'Confirme apenas depois de verificar o medicamento '
            'e efectuar o pagamento presencialmente na farmácia.\n\n'
            'Já verificou o medicamento e efectuou o pagamento?',
          ),
          actions: [
            TextButton(
              onPressed: () {
                Navigator.pop(dialogContext, false);
              },
              child: const Text('Ainda não'),
            ),
            FilledButton(
              onPressed: () {
                Navigator.pop(dialogContext, true);
              },
              child: const Text('Confirmar compra'),
            ),
          ],
        );
      },
    );

    if (confirmed != true || !mounted) return;

    try {
      await ref
          .read(reservationsProvider.notifier)
          .confirmarPagamentoComoCliente(
            reservationId: reservation.id,
          );

      await ref
          .read(reservationsProvider.notifier)
          .fetchReservations();

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pagamento confirmado com sucesso.'),
          backgroundColor: AppColors.success,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível confirmar a compra: $e'),
          backgroundColor: AppColors.danger,
        ),
      );
    }
  }

  Widget _buildMedicineImage() {
    final imageUrl = reservation.medicineImageUrl?.trim();

    return Container(
      width: 76,
      height: 76,
      decoration: BoxDecoration(
        color: AppColors.primaryLight.withValues(alpha: 0.55),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.10),
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(17),
        child: imageUrl == null || imageUrl.isEmpty
            ? const Icon(
                Icons.medication_rounded,
                size: 36,
                color: AppColors.primary,
              )
            : Image.network(
                imageUrl,
                width: 76,
                height: 76,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.medication_rounded,
                    size: 36,
                    color: AppColors.primary,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildMedicineDetails() {
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: const Color(0xFFF8FBF9),
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: AppColors.borderLight,
        ),
      ),
      child: Row(
        children: [
          _buildMedicineImage(),
          const SizedBox(width: 14),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'MEDICAMENTO',
                  style: TextStyle(
                    fontSize: 10,
                    letterSpacing: 1.1,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textSecondaryLight,
                  ),
                ),
                const SizedBox(height: 5),
                Text(
                  reservation.medicineName,
                  style: const TextStyle(
                    fontSize: 15,
                    height: 1.3,
                    fontWeight: FontWeight.w800,
                    color: AppColors.textPrimaryLight,
                  ),
                ),
                const SizedBox(height: 7),
                Text(
                  '${reservation.totalPriceKz.toStringAsFixed(2)} Kz',
                  style: const TextStyle(
                    fontSize: 17,
                    fontWeight: FontWeight.w800,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusBadge() {
    return Container(
      constraints: const BoxConstraints(maxWidth: 155),
      padding: const EdgeInsets.symmetric(
        horizontal: 11,
        vertical: 8,
      ),
      decoration: BoxDecoration(
        color: _statusColor.withValues(alpha: 0.09),
        borderRadius: BorderRadius.circular(30),
        border: Border.all(
          color: _statusColor.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            _statusIcon,
            size: 15,
            color: _statusColor,
          ),
          const SizedBox(width: 5),
          Flexible(
            child: Text(
              _statusText,
              overflow: TextOverflow.ellipsis,
              style: TextStyle(
                color: _statusColor,
                fontSize: 11,
                fontWeight: FontWeight.w800,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildQrSection() {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        gradient: const LinearGradient(
          colors: [
            Color(0xFFF0FDF4),
            Color(0xFFEFF8FF),
          ],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(22),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.13),
        ),
      ),
      child: Column(
        children: [
          const Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Icon(
                Icons.qr_code_2_rounded,
                color: AppColors.primary,
                size: 21,
              ),
              SizedBox(width: 8),
              Text(
                'Código de levantamento',
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w800,
                  color: AppColors.textPrimaryLight,
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: AppColors.primary.withValues(alpha: 0.07),
                  blurRadius: 18,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: QrCodeWidget(
              data: reservation.pickupCode,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Apresente este código na farmácia para validar '
            'a sua reserva.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              height: 1.5,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildInformationMessage({
    required String message,
    required Color color,
    required IconData icon,
  }) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 14),
      padding: const EdgeInsets.all(13),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 20),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final canConfirmPurchase = _canConfirmPurchase;

    return Container(
      margin: const EdgeInsets.only(bottom: 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(25),
        border: Border.all(
          color: AppColors.borderLight,
        ),
        boxShadow: [
          BoxShadow(
            color: const Color(0xFF173B57).withValues(alpha: 0.045),
            blurRadius: 22,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(17),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: BoxDecoration(
                    color: AppColors.secondaryLight,
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: const Icon(
                    Icons.local_pharmacy_rounded,
                    color: AppColors.secondary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 11),
                Expanded(
                  child: Text(
                    reservation.pharmacyName,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                    style: const TextStyle(
                      fontSize: 15,
                      height: 1.3,
                      fontWeight: FontWeight.w800,
                      color: AppColors.textPrimaryLight,
                    ),
                  ),
                ),
                const SizedBox(width: 8),
                _buildStatusBadge(),
              ],
            ),
            const SizedBox(height: 18),
            _buildMedicineDetails(),
            _buildCountdown(),
            if (_canShowQr) _buildQrSection(),
            if (_isAwaitingPayment &&
                !_qrWasValidated &&
                !_deadlineReached &&
                !_isExpired)
              _buildInformationMessage(
                message: 'A confirmação da compra ficará disponível '
                    'após a leitura válida deste código pela farmácia.',
                color: AppColors.warning,
                icon: Icons.qr_code_scanner_rounded,
              ),
            if (canConfirmPurchase) ...[
              const SizedBox(height: 17),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: _confirmPurchase,
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Confirmar compra'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 16),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
            if (_isPaid)
              _buildInformationMessage(
                message: 'Pagamento confirmado. Aguarde a entrega '
                    'do medicamento.',
                color: AppColors.success,
                icon: Icons.verified_rounded,
              ),
            if (_isCompleted)
              _buildInformationMessage(
                message: 'Muito obrigado. Volte sempre!',
                color: AppColors.success,
                icon: Icons.check_circle_rounded,
              ),
            if (_isExpired)
              _buildInformationMessage(
                message: 'Esta reserva expirou. O código QR já não '
                    'pode ser utilizado.',
                color: AppColors.danger,
                icon: Icons.timer_off_rounded,
              ),
            if (_canRate) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: widget.onRating,
                  icon: const Icon(Icons.star_rate_rounded),
                  label: const Text('Avaliar experiência'),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: AppColors.primary,
                    side: const BorderSide(
                      color: AppColors.primary,
                    ),
                    padding: const EdgeInsets.symmetric(vertical: 15),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(16),
                    ),
                  ),
                ),
              ),
            ],
            if (reservation.isReviewed)
              _buildInformationMessage(
                message: 'Esta reserva já foi avaliada.',
                color: AppColors.success,
                icon: Icons.check_circle_outline_rounded,
              ),
          ],
        ),
      ),
    );
  }
}

class _CountdownMessage extends StatelessWidget {
  final Color color;
  final IconData icon;
  final String message;

  const _CountdownMessage({
    required this.color,
    required this.icon,
    required this.message,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(top: 18),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.07),
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.16),
        ),
      ),
      child: Row(
        children: [
          Icon(icon, color: color, size: 21),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              message,
              style: TextStyle(
                color: color,
                fontSize: 12,
                height: 1.45,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
