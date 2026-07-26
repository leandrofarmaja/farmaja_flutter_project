import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/qr_code_widget.dart';
import '../../reviews/presentation/widgets/rate_experience_dialog.dart';
import '../domain/reservation_model.dart';
import '../providers/reservations_provider.dart';

class ReservationsScreen extends ConsumerWidget {
  const ReservationsScreen({super.key});

  void _showQrCodeModal(BuildContext context, String medicineName, String pickupCode) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      builder: (context) => Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisSize: MyAxisSize.min,
          children: [
            Container(
              width: 40,
              height: 4,
              decoration: BoxDecoration(
                color: Colors.grey.shade300,
                borderRadius: BorderRadius.circular(2),
              ),
            ),
            const SizedBox(height: 16),
            const Text(
              'Apresente o QR Code na Farmácia',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
            ),
            const SizedBox(height: 4),
            Text(
              medicineName,
              style: const TextStyle(fontSize: 14, color: AppColors.textSecondaryLight),
            ),
            const SizedBox(height: 20),
            QrCodeWidget(
              data: pickupCode,
              size: 200,
            ),
            const SizedBox(height: 16),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Código: $pickupCode',
                style: const TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w900,
                  color: AppColors.primaryDark,
                  letterSpacing: 1.2,
                ),
              ),
            ),
            const SizedBox(height: 12),
            const Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer_outlined, size: 16, color: Colors.orange),
                SizedBox(width: 6),
                Text(
                  'Reserva válida por 2 horas a contar da criação',
                  style: TextStyle(fontSize: 12, color: Colors.orange, fontWeight: FontWeight.bold),
                ),
              ],
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: FilledButton(
                onPressed: () => Navigator.pop(context),
                child: const Text('Fechar'),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showRatingDialog(BuildContext context, WidgetRef ref, ReservationModel res) {
    showDialog(
      context: context,
      builder: (context) => RateExperienceDialog(
        reservation: res,
        onSubmitted: () {
          ref.read(reservationsProvider.notifier).markReservationReviewed(res.id, 5.0);
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final reservations = ref.watch(reservationsProvider);
    final unreviewedCompleted = reservations.where((r) => r.status == 'completed' && !r.isReviewed).toList();

    return Scaffold(
      appBar: AppBar(
        title: const Text('As Minhas Reservas'),
      ),
      body: reservations.isEmpty
          ? Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.bookmark_border_rounded, size: 64, color: Colors.grey.shade400),
                  const SizedBox(height: 12),
                  const Text(
                    'Nenhuma reserva ativa.',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.grey),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Pesquise medicamentos e reserve na farmácia mais próxima.',
                    style: TextStyle(fontSize: 13, color: Colors.grey),
                  ),
                ],
              ),
            )
          : ListView(
              padding: const EdgeInsets.all(16),
              children: [
                if (unreviewedCompleted.isNotEmpty) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    margin: const EdgeInsets.only(bottom: 16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Row(
                      children: [
                        const Icon(Icons.star_rounded, color: Colors.amber, size: 36),
                        const SizedBox(width: 12),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text(
                                'Avalie a sua experiência!',
                                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                              ),
                              Text(
                                'Possui ${unreviewedCompleted.length} reserva(s) concluída(s) para avaliar a farmácia e o app.',
                                style: const TextStyle(fontSize: 12, color: Colors.black87),
                              ),
                            ],
                          ),
                        ),
                        FilledButton(
                          style: FilledButton.styleFrom(backgroundColor: Colors.amber.shade800),
                          onPressed: () => _showRatingDialog(context, ref, unreviewedCompleted.first),
                          child: const Text('Avaliar Já'),
                        ),
                      ],
                    ),
                  ),
                ],

                ...reservations.map((res) {
                  final isCompleted = res.status == 'completed';

                  return Card(
                    margin: const EdgeInsets.only(bottom: 12),
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Row(
                            mainAxisAlignment: MainAxisAlignment.between,
                            children: [
                              Expanded(
                                child: Text(
                                  res.medicineName,
                                  style: const TextStyle(
                                    fontSize: 16,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                                decoration: BoxDecoration(
                                  color: isCompleted ? Colors.green.shade50 : AppColors.primaryLight,
                                  borderRadius: BorderRadius.circular(12),
                                  border: Border.all(
                                    color: isCompleted ? Colors.green.shade300 : AppColors.primaryDark,
                                  ),
                                ),
                                child: Text(
                                  isCompleted ? '✓ Concluída e Entregue' : 'Ativa (Validade 2h)',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: isCompleted ? Colors.green.shade800 : AppColors.primaryDark,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 6),
                          Text('🏥 ${res.pharmacyName}'),
                          const SizedBox(height: 4),
                          Row(
                            children: [
                              Icon(
                                isCompleted ? Icons.check_circle_outline : Icons.access_time_filled,
                                size: 14,
                                color: isCompleted ? Colors.green : Colors.orange,
                              ),
                              const SizedBox(width: 4),
                              Expanded(
                                child: Text(
                                  isCompleted ? 'Levantamento confirmado na farmácia' : res.expiryDate,
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: isCompleted ? Colors.green.shade800 : Colors.orange,
                                    fontWeight: FontWeight.bold,
                                  ),
                                ),
                              ),
                            ],
                          ),
                          const SizedBox(height: 12),

                          // Pickup info
                          Container(
                            padding: const EdgeInsets.all(12),
                            decoration: BoxDecoration(
                              color: AppColors.surfaceLight,
                              borderRadius: BorderRadius.circular(12),
                              border: Border.all(color: AppColors.borderLight),
                            ),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.between,
                              children: [
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    const Text('Código de Levantamento:', style: TextStyle(fontSize: 11, color: Colors.grey)),
                                    Text(
                                      res.pickupCode,
                                      style: const TextStyle(
                                        fontSize: 18,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primary,
                                      ),
                                    ),
                                  ],
                                ),
                                OutlinedButton.icon(
                                  icon: const Icon(Icons.qr_code_2_rounded, size: 18),
                                  label: const Text('QR Code', style: TextStyle(fontSize: 12)),
                                  onPressed: () => _showQrCodeModal(context, res.medicineName, res.pickupCode),
                                ),
                              ],
                            ),
                          ),

                          const SizedBox(height: 12),

                          // Rating trigger button / Status
                          if (isCompleted) ...[
                            if (res.isReviewed) ...[
                              Container(
                                width: double.infinity,
                                padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 12),
                                decoration: BoxDecoration(
                                  color: Colors.green.shade50,
                                  borderRadius: BorderRadius.circular(10),
                                ),
                                child: Row(
                                  mainAxisAlignment: MainAxisAlignment.center,
                                  children: [
                                    const Icon(Icons.star_rounded, color: Colors.amber, size: 18),
                                    const SizedBox(width: 6),
                                    Text(
                                      'Avaliação Submetida (${res.reviewRating?.toStringAsFixed(1) ?? '5.0'}★)',
                                      style: TextStyle(
                                        color: Colors.green.shade900,
                                        fontWeight: FontWeight.bold,
                                        fontSize: 12,
                                      ),
                                    ),
                                  ],
                                ),
                              ),
                            ] else ...[
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  style: FilledButton.styleFrom(
                                    backgroundColor: Colors.amber.shade800,
                                    padding: const EdgeInsets.symmetric(vertical: 10),
                                  ),
                                  icon: const Icon(Icons.rate_review_rounded, size: 18),
                                  label: const Text(
                                    'Avaliar Experiência (Farmácia & App)',
                                    style: TextStyle(fontWeight: FontWeight.bold),
                                  ),
                                  onPressed: () => _showRatingDialog(context, ref, res),
                                ),
                              ),
                            ],
                          ] else ...[
                            // Allow test completion
                            TextButton.icon(
                              icon: const Icon(Icons.check_circle_outline, size: 16),
                              label: const Text('Simular Conclusão de Levantamento', style: TextStyle(fontSize: 11)),
                              onPressed: () {
                                ref.read(reservationsProvider.notifier).fetchReservations();
                                // Toggle status to completed for demo
                                final updatedState = ref.read(reservationsProvider).map((r) {
                                  if (r.id == res.id) return r.copyWith(status: 'completed');
                                  return r;
                                }).toList();
                                ref.read(reservationsProvider.notifier).state = updatedState;
                                ScaffoldMessenger.of(context).showSnackBar(
                                  const SnackBar(content: Text('Reserva marcada como concluída! Agora pode avaliá-la.')),
                                );
                              },
                            ),
                          ],
                        ],
                      ),
                    ),
                  );
                }),
              ],
            ),
    );
  }
}
