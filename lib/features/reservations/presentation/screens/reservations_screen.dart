import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/qr_code_widget.dart';
import '../../domain/reservation_model.dart';
import '../../../reviews/presentation/widgets/rate_experience_dialog.dart';
import '../providers/reservation_provider.dart';

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

  Color _statusColor(String status) {
    switch (status.trim().toLowerCase()) {
      case 'active':
        return Colors.blue;
      case 'completed':
      case 'levantada':
      case 'entregue':
      case 'resgatado':
      case 'pago':
        return Colors.green;
      case 'expired':
      case 'expirada':
        return Colors.red;
      case 'pending':
      case 'aguardando confirmação':
      case 'aguardando confirmacao':
        return Colors.orange;
      default:
        return Colors.grey;
    }
  }

  String _statusText(String status) {
    switch (status.trim().toLowerCase()) {
      case 'active':
        return 'Ativa';
      case 'completed':
      case 'levantada':
      case 'entregue':
      case 'resgatado':
        return 'Levantada';
      case 'expired':
      case 'expirada':
        return 'Expirada';
      case 'pending':
        return 'Pendente';
      case 'aguardando confirmação':
      case 'aguardando confirmacao':
        return 'Aguardando confirmação';
      case 'pago':
        return 'Pago';
      default:
        return status;
    }
  }

  bool get _isAwaitingPayment =>
      reservation.status.trim().toLowerCase() ==
          'aguardando confirmação' ||
      reservation.status.trim().toLowerCase() ==
          'aguardando confirmacao';

  bool get _isExpired =>
      reservation.status.trim().toLowerCase() == 'expirada' ||
      reservation.status.trim().toLowerCase() == 'expired';

  bool get _canRate =>
      (reservation.status.trim().toLowerCase() == 'completed' ||
          reservation.status.trim().toLowerCase() == 'levantada') &&
      !reservation.isReviewed;

  Future<void> _confirmPayment(
    BuildContext context,
    WidgetRef ref,
  ) async {
    if (!_isAwaitingPayment) return;

    final selectedMethod = await showModalBottomSheet<String>(
      context: context,
      backgroundColor: Colors.white,
      builder: (sheetContext) {
        return SafeArea(
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  'Confirmar pagamento',
                  style: TextStyle(
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                const Text(
                  'Selecciona o método de pagamento utilizado na farmácia.',
                ),
                const SizedBox(height: 16),
                ...[
                  ('Dinheiro', 'dinheiro', Icons.money),
                  ('TPA', 'tpa', Icons.credit_card),
                  (
                    'Multicaixa Express',
                    'multicaixa_express',
                    Icons.phone_android,
                  ),
                  (
                    'Transferência bancária',
                    'transferencia',
                    Icons.account_balance,
                  ),
                  ('Outro', 'outro', Icons.more_horiz),
                ].map(
                  (method) => ListTile(
                    leading: Icon(method.$3),
                    title: Text(method.$1),
                    onTap: () {
                      Navigator.pop(sheetContext, method.$2);
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );

    if (selectedMethod == null || !context.mounted) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) {
        return AlertDialog(
          title: const Text('Confirmar pagamento'),
          content: const Text(
            'Confirma que já efectuaste o pagamento deste medicamento '
            'directamente na farmácia?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(dialogContext, false),
              child: const Text('Cancelar'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(dialogContext, true),
              child: const Text('Confirmar'),
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
            metodoPagamento: selectedMethod,
          );

      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'A tua confirmação foi registada. '
            'Aguarda a confirmação da farmácia.',
          ),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!context.mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível confirmar o pagamento: $e'),
          backgroundColor: Colors.red,
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final statusColor = _statusColor(reservation.status);

    final clientConfirmed =
        reservation.clienteConfirmouPagamentoEm != null;

    final pharmacyConfirmed =
        reservation.farmaciaConfirmouPagamentoEm != null;

    final canConfirmPayment =
        _isAwaitingPayment && !clientConfirmed && !_isExpired;

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
              crossAxisAlignment: CrossAxisAlignment.start,
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
                    color: statusColor.withOpacity(0.1),
                    borderRadius: BorderRadius.circular(20),
                  ),
                  child: Text(
                    _statusText(reservation.status),
                    style: TextStyle(
                      color: statusColor,
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            _InfoRow(
              icon: Icons.medication_outlined,
              label: 'Medicamento',
              value: reservation.medicineName,
            ),
            _InfoRow(
              icon: Icons.payments_outlined,
              label: 'Valor',
              value: '${reservation.totalPriceKz.toStringAsFixed(2)} Kz',
            ),
            _InfoRow(
              icon: Icons.calendar_today_outlined,
              label: 'Data da reserva',
              value: reservation.reservationDate,
            ),
            _InfoRow(
              icon: Icons.access_time_outlined,
              label: 'Expira em',
              value: reservation.expiryDate,
            ),
            _InfoRow(
              icon: Icons.qr_code_2_rounded,
              label: 'Código de levantamento',
              value: reservation.pickupCode,
            ),
            _InfoRow(
              icon: Icons.description_outlined,
              label: 'Receita',
              value:
                  'Apresentação presencial na farmácia, quando exigida',
            ),
            if (reservation.metodoPagamento != null)
              _InfoRow(
                icon: Icons.account_balance_wallet_outlined,
                label: 'Método de pagamento',
                value: reservation.metodoPagamento!,
              ),
            if (reservation.reviewRating != null)
              _InfoRow(
                icon: Icons.star_rounded,
                label: 'Sua avaliação',
                value: '${reservation.reviewRating!.toStringAsFixed(1)} / 5',
              ),
            if (reservation.pickupCode.isNotEmpty) ...[
              const SizedBox(height: 12),
              Center(
                child: QrCodeWidget(data: reservation.pickupCode),
              ),
            ],
            if (_isAwaitingPayment) ...[
              const SizedBox(height: 12),
              _PaymentConfirmationStatus(
                clientConfirmed: clientConfirmed,
                pharmacyConfirmed: pharmacyConfirmed,
              ),
            ],
            if (canConfirmPayment) ...[
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  onPressed: () => _confirmPayment(context, ref),
                  icon: const Icon(Icons.check_circle_outline),
                  label: const Text('Confirmar pagamento'),
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    padding: const EdgeInsets.symmetric(vertical: 14),
                  ),
                ),
              ),
            ],
            if (clientConfirmed && !pharmacyConfirmed) ...[
              const SizedBox(height: 10),
              const Text(
                'A tua confirmação foi registada. '
                'Aguarda a confirmação da farmácia.',
                style: TextStyle(
                  color: Colors.orange,
                  fontSize: 12,
                ),
              ),
            ],
            if (canConfirmPayment == false &&
                clientConfirmed &&
                pharmacyConfirmed) ...[
              const SizedBox(height: 10),
              const Text(
                'Pagamento confirmado por ambas as partes.',
                style: TextStyle(
                  color: Colors.green,
                  fontWeight: FontWeight.bold,
                  fontSize: 13,
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

class _PaymentConfirmationStatus extends StatelessWidget {
  final bool clientConfirmed;
  final bool pharmacyConfirmed;

  const _PaymentConfirmationStatus({
    required this.clientConfirmed,
    required this.pharmacyConfirmed,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.blue.withOpacity(0.05),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirmação bilateral do pagamento',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              fontSize: 13,
            ),
          ),
          const SizedBox(height: 8),
          _ConfirmationLine(
            label: 'Cliente',
            confirmed: clientConfirmed,
          ),
          const SizedBox(height: 5),
          _ConfirmationLine(
            label: 'Farmácia',
            confirmed: pharmacyConfirmed,
          ),
        ],
      ),
    );
  }
}

class _ConfirmationLine extends StatelessWidget {
  final String label;
  final bool confirmed;

  const _ConfirmationLine({
    required this.label,
    required this.confirmed,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          confirmed ? Icons.check_circle : Icons.hourglass_empty,
          size: 17,
          color: confirmed ? Colors.green : Colors.orange,
        ),
        const SizedBox(width: 7),
        Text(
          '$label: ${confirmed ? 'Confirmado' : 'Pendente'}',
          style: TextStyle(
            fontSize: 12,
            color: confirmed ? Colors.green : Colors.orange,
          ),
        ),
      ],
    );
  }
}

class _InfoRow extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _InfoRow({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 9),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(
            icon,
            size: 19,
            color: AppColors.primary,
          ),
          const SizedBox(width: 10),
          Text(
            '$label: ',
            style: const TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.bold,
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: const TextStyle(fontSize: 13),
            ),
          ),
        ],
      ),
    );
  }
}
