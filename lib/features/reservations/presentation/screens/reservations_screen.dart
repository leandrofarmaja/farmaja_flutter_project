
import 'package:flutter/material.dart';
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
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: const Text(
          'Minhas Reservas',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        backgroundColor: Colors.white,
        foregroundColor: Colors.black87,
        elevation: 0,
      ),
      body: reservations.isEmpty
          ? const _EmptyReservations()
          : RefreshIndicator(
              onRefresh: () async {
                await ref
                    .read(reservationsProvider.notifier)
                    .fetchReservations();
              },
              child: ListView.builder(
                padding: const EdgeInsets.all(16),
                itemCount: reservations.length,
                itemBuilder: (context, index) {
                  final reservation = reservations[index];

                  return _ReservationCard(
                    reservation: reservation,
                    onRating: () {
                      _showRatingDialog(context, ref, reservation);
                    },
                  );
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
    return const Center(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.receipt_long_outlined,
              size: 64,
              color: Colors.grey,
            ),
            SizedBox(height: 16),
            Text(
              'Ainda não possui reservas.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
            SizedBox(height: 8),
            Text(
              'As suas reservas de medicamentos aparecerão aqui.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 14,
                color: Colors.grey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _ReservationCard extends ConsumerWidget {
  final ReservationModel reservation;
  final VoidCallback onRating;

  const _ReservationCard({
    required this.reservation,
    required this.onRating,
  });

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

  bool get _canShowQr =>
      reservation.pickupCode.isNotEmpty &&
      !_isExpired &&
      !_isCompleted;

  Color get _statusColor {
    if (_isCompleted || _isPaid) return Colors.green;
    if (_isExpired) return Colors.red;
    if (_isAwaitingPayment) return Colors.orange;
    return Colors.blue;
  }

  String get _statusText {
    if (_isCompleted) return 'Levantada';
    if (_isExpired) return 'Expirada';
    if (_isPaid) return 'Pago';
    if (_isAwaitingPayment) return 'Aguardando confirmação';
    return reservation.status;
  }

  Future<void> _confirmPurchase(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (!_isAwaitingPayment || !_qrWasValidated || _isExpired) {
      return;
    }

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar compra'),
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

    if (confirmed != true || !context.mounted) return;

    try {
      await ref
          .read(reservationsProvider.notifier)
          .confirmarPagamentoComoCliente(
            reservationId: reservation.id,
          );

      await ref
          .read(reservationsProvider.notifier)
          .fetchReservations();

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Pagamento confirmado com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível confirmar a compra: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  Widget _buildMedicineImage() {
    final imageUrl = reservation.medicineImageUrl?.trim();

    return Container(
      width: 88,
      height: 88,
      decoration: BoxDecoration(
        color: const Color(0xFFF4F7F5),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: Colors.grey.shade200,
        ),
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(12),
        child: imageUrl == null || imageUrl.isEmpty
            ? const Icon(
                Icons.medication_outlined,
                size: 38,
                color: AppColors.primary,
              )
            : Image.network(
                imageUrl,
                width: 88,
                height: 88,
                fit: BoxFit.cover,
                errorBuilder: (context, error, stackTrace) {
                  return const Icon(
                    Icons.medication_outlined,
                    size: 38,
                    color: AppColors.primary,
                  );
                },
              ),
      ),
    );
  }

  Widget _buildMedicineDetails() {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        _buildMedicineImage(),
        const SizedBox(width: 14),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                reservation.medicineName,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.bold,
                  color: Colors.black87,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                '${reservation.totalPriceKz.toStringAsFixed(2)} Kz',
                style: const TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.bold,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final canConfirmPurchase =
        _isAwaitingPayment &&
        _qrWasValidated &&
        !_isExpired;

    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 1,
      color: Colors.white,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: Colors.grey.shade200),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Expanded(
                  child: Text(
                    reservation.pharmacyName,
                    style: const TextStyle(
                      fontSize: 17,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 10,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: _statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusText,
                    style: TextStyle(
                      color: _statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),

            const SizedBox(height: 16),

            _buildMedicineDetails(),

            if (_canShowQr) ...[
              const SizedBox(height: 20),
              Center(
                child: QrCodeWidget(
                  data: reservation.pickupCode,
                ),
              ),
            ],

            if (_isAwaitingPayment && !_qrWasValidated) ...[
              const SizedBox(height: 12),
              const Text(
                'A confirmação da compra ficará disponível após '
                'a leitura válida deste código pela farmácia.',
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                ),
              ),
            ],

            if (canConfirmPurchase) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () {
                    _confirmPurchase(context, ref);
                  },
                  icon: const Icon(Icons.shopping_bag_outlined),
                  label: const Text('Confirmar compra'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],

            if (_isPaid) ...[
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Pagamento confirmado. Aguarde a entrega do medicamento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 13,
                  ),
                ),
              ),
            ],

            if (_isCompleted) ...[
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Muito obrigado. Volte sempre!',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.green,
                    fontWeight: FontWeight.bold,
                    fontSize: 16,
                  ),
                ),
              ),
            ],

            if (_isExpired) ...[
              const SizedBox(height: 12),
              const Center(
                child: Text(
                  'Esta reserva expirou. O código QR já não pode ser utilizado.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.red,
                    fontWeight: FontWeight.bold,
                    fontSize: 12,
                  ),
                ),
              ),
            ],

            if (_canRate) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: OutlinedButton.icon(
                  onPressed: onRating,
                  icon: const Icon(Icons.star_rate_rounded),
                  label: const Text('Avaliar experiência'),
                ),
              ),
            ],

            if (reservation.isReviewed) ...[
              const SizedBox(height: 12),
              Container(
                width: double.infinity,
                padding: const EdgeInsets.all(10),
                decoration: BoxDecoration(
                  color: Colors.green.withOpacity(0.08),
                  borderRadius: BorderRadius.circular(10),
                ),
                child: const Row(
                  children: [
                    Icon(
                      Icons.check_circle_outline_rounded,
                      size: 18,
                      color: Colors.green,
                    ),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Esta reserva já foi avaliada.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.green,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
