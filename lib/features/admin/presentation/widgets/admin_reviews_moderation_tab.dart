import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../reviews/domain/review_model.dart';
import '../providers/admin_reviews_provider.dart';

class AdminReviewsModerationTab extends ConsumerWidget {
  const AdminReviewsModerationTab({super.key});

  void _showModerationNoteDialog(BuildContext context, WidgetRef ref, ReviewModel rev, String newStatus) {
    final noteController = TextEditingController();
    final isApprove = newStatus == 'approved';

    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text(
          isApprove ? 'Aprovar Avaliação ⭐' : 'Rejeitar / Ocultar Avaliação 🚫',
          style: const TextStyle(fontWeight: FontWeight.bold),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Avaliação de ${rev.userName} sobre ${rev.pharmacyName}:',
              style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
            ),
            const SizedBox(height: 6),
            Text(
              '• Farmácia: ${rev.pharmacyRating}★ ${rev.pharmacyComment != null ? "(\"${rev.pharmacyComment}\")" : ""}',
              style: const TextStyle(fontSize: 12),
            ),
            Text(
              '• App: ${rev.appRating}★ ${rev.appComment != null ? "(\"${rev.appComment}\")" : ""}',
              style: const TextStyle(fontSize: 12),
            ),
            const SizedBox(height: 16),
            TextField(
              controller: noteController,
              maxLines: 2,
              decoration: InputDecoration(
                labelText: isApprove ? 'Nota de Aprovação (Opcional)' : 'Motivo da Rejeição / Ocultação',
                hintText: isApprove
                    ? 'Ex: Verificado com a farmácia, crítica legítima.'
                    : 'Ex: Linguagem inadequada ou informação falsa.',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: isApprove ? Colors.green : Colors.red,
            ),
            onPressed: () async {
              await ref.read(adminReviewsProvider.notifier).moderateReview(
                    rev.id,
                    newStatus,
                    note: noteController.text.trim().isNotEmpty ? noteController.text.trim() : null,
                  );
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text(
                      isApprove ? 'Avaliação aprovada e publicada!' : 'Avaliação rejeitada.',
                    ),
                  ),
                );
              }
            },
            child: Text(isApprove ? 'Aprovar e Publicar' : 'Confirmar Rejeição'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminReviewsProvider);
    final pendingList = state.pendingModerationReviews;

    if (state.isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Notifications / Low Rating Alert Banner
          if (state.notifications.isNotEmpty) ...[
            Card(
              color: Colors.red.shade50,
              margin: const EdgeInsets.only(bottom: 20),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
                side: BorderSide(color: Colors.red.shade200),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16.0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        const Icon(Icons.warning_amber_rounded, color: Colors.red, size: 28),
                        const SizedBox(width: 8),
                        const Text(
                          'Alertas do Administrador FarmaJá',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.red),
                        ),
                        const Spacer(),
                        Badge(
                          label: Text('${state.unreadNotificationsCount} novos'),
                          backgroundColor: Colors.red,
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                    ...state.notifications.take(3).map((notif) {
                      return Container(
                        margin: const EdgeInsets.only(bottom: 8),
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(10),
                          border: Border.all(color: Colors.red.shade100),
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    notif.title,
                                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.red),
                                  ),
                                  const SizedBox(height: 2),
                                  Text(notif.message, style: const TextStyle(fontSize: 12)),
                                ],
                              ),
                            ),
                            if (!notif.isRead)
                              IconButton(
                                icon: const Icon(Icons.check_circle_outline, color: Colors.green, size: 20),
                                tooltip: 'Marcar como Lido',
                                onPressed: () {
                                  ref.read(adminReviewsProvider.notifier).markNotificationRead(notif.id);
                                },
                              ),
                          ],
                        ),
                      );
                    }),
                  ],
                ),
              ),
            ),
          ],

          // Pending Moderation Section Header
          Row(
            mainAxisAlignment: MainAxisAlignment.between,
            children: [
              const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Avaliações a Aguardar Moderação',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  Text(
                    'Críticas com 1 ou 2 estrelas submetidas por utentes',
                    style: TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                  ),
                ],
              ),
              Chip(
                avatar: const Icon(Icons.hourglass_top_rounded, size: 16, color: Colors.amber),
                label: Text(
                  '${pendingList.length} Pendente(s)',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12),
                ),
                backgroundColor: Colors.amber.shade50,
              ),
            ],
          ),
          const SizedBox(height: 16),

          if (pendingList.isEmpty)
            Container(
              padding: const EdgeInsets.all(32),
              width: double.infinity,
              decoration: BoxDecoration(
                color: Colors.green.shade50,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(color: Colors.green.shade200),
              ),
              child: Column(
                children: [
                  Icon(Icons.verified_user_rounded, size: 48, color: Colors.green.shade700),
                  const SizedBox(height: 8),
                  Text(
                    'Nenhuma avaliação pendente de moderação!',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green.shade900),
                  ),
                  const SizedBox(height: 4),
                  const Text(
                    'Todas as críticas baixas foram analisadas e decididas.',
                    style: TextStyle(fontSize: 12, color: Colors.grey),
                  ),
                ],
              ),
            )
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingList.length,
              itemBuilder: (context, index) {
                final rev = pendingList[index];

                return Card(
                  margin: const EdgeInsets.only(bottom: 16),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(16),
                    side: BorderSide(color: Colors.amber.shade400, width: 1.5),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          mainAxisAlignment: MainAxisAlignment.between,
                          children: [
                            Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  rev.userName,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  'Reserva #${rev.reservationId} • Utente ${rev.userPhone}',
                                  style: const TextStyle(fontSize: 11, color: Colors.grey),
                                ),
                              ],
                            ),
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                              decoration: BoxDecoration(
                                color: Colors.red.shade100,
                                borderRadius: BorderRadius.circular(12),
                              ),
                              child: const Row(
                                children: [
                                  Icon(Icons.shield_outlined, size: 14, color: Colors.red),
                                  SizedBox(width: 4),
                                  Text(
                                    '1-2★ Baixa',
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: Colors.red,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),

                        // Pharmacy Rating Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.storefront_rounded, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  Expanded(
                                    child: Text(
                                      'Farmácia: ${rev.pharmacyName}',
                                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    '${rev.pharmacyRating}★',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.red),
                                  ),
                                ],
                              ),
                              if (rev.pharmacyComment != null && rev.pharmacyComment!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '"${rev.pharmacyComment}"',
                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 8),

                        // App Rating Box
                        Container(
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: AppColors.surfaceLight,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                children: [
                                  const Icon(Icons.smartphone_rounded, size: 18, color: AppColors.primary),
                                  const SizedBox(width: 6),
                                  const Expanded(
                                    child: Text(
                                      'Aplicação FarmaJá:',
                                      style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13),
                                    ),
                                  ),
                                  Text(
                                    '${rev.appRating}★',
                                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primary),
                                  ),
                                ],
                              ),
                              if (rev.appComment != null && rev.appComment!.isNotEmpty) ...[
                                const SizedBox(height: 4),
                                Text(
                                  '"${rev.appComment}"',
                                  style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic),
                                ),
                              ],
                            ],
                          ),
                        ),
                        const SizedBox(height: 16),

                        // Actions
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                style: OutlinedButton.styleFrom(
                                  foregroundColor: Colors.red,
                                  side: const BorderSide(color: Colors.red),
                                ),
                                icon: const Icon(Icons.block_rounded, size: 18),
                                label: const Text('Rejeitar / Ocultar'),
                                onPressed: () => _showModerationNoteDialog(context, ref, rev, 'rejected'),
                              ),
                            ),
                            const SizedBox(width: 12),
                            Expanded(
                              child: FilledButton.icon(
                                style: FilledButton.styleFrom(backgroundColor: Colors.green),
                                icon: const Icon(Icons.check_circle_rounded, size: 18),
                                label: const Text('Aprovar e Publicar'),
                                onPressed: () => _showModerationNoteDialog(context, ref, rev, 'approved'),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                );
              },
            ),

          const SizedBox(height: 24),
          const Divider(),
          const SizedBox(height: 12),

          // Approved Reviews Archive
          const Text(
            'Histórico de Avaliações Aprovadas & Públicas',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 12),
          ...state.reviews.where((r) => r.status == 'approved').map((rev) {
            return Card(
              margin: const EdgeInsets.only(bottom: 8),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: AppColors.primaryLight,
                  child: Text(
                    '${rev.pharmacyRating.toInt()}★',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: AppColors.primaryDark),
                  ),
                ),
                title: Text('${rev.userName} • ${rev.pharmacyName}'),
                subtitle: Text(
                  'Farmácia: ${rev.pharmacyComment ?? "Sem comentário"} | App: ${rev.appRating}★',
                  style: const TextStyle(fontSize: 12),
                ),
                trailing: const Icon(Icons.verified_rounded, color: Colors.green, size: 20),
              ),
            );
          }),
        ],
      ),
    );
  }
}
