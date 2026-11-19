import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../reviews/domain/review_model.dart';
import '../providers/admin_reviews_provider.dart';

class AdminReviewsModerationTab extends ConsumerWidget {
  const AdminReviewsModerationTab({super.key});

  Future<void> _showModerationNoteDialog(
    BuildContext context,
    WidgetRef ref,
    ReviewModel rev,
    String newStatus,
  ) async {
    final noteController = TextEditingController();
    final isApprove = newStatus == 'approved';

    try {
      await showDialog<void>(
        context: context,
        barrierDismissible: false,
        builder: (dialogContext) {
          bool isSubmitting = false;
          String? dialogError;

          return StatefulBuilder(
            builder: (context, setDialogState) {
              Future<void> submitModeration() async {
                if (isSubmitting) return;

                setDialogState(() {
                  isSubmitting = true;
                  dialogError = null;
                });

                try {
                  await ref
                      .read(adminReviewsProvider.notifier)
                      .moderateReview(
                        rev.id,
                        newStatus,
                        note: noteController.text.trim().isNotEmpty
                            ? noteController.text.trim()
                            : null,
                      );

                  if (!dialogContext.mounted) return;

                  final refreshError =
                      ref.read(adminReviewsProvider).error;

                  Navigator.of(dialogContext).pop();

                  if (context.mounted) {
                    final message = isApprove
                        ? 'Avaliação aprovada e publicada!'
                        : 'Avaliação rejeitada.';

                    ScaffoldMessenger.of(context).showSnackBar(
                      SnackBar(
                        content: Text(
                          refreshError == null
                              ? message
                              : '$message A lista não foi actualizada; '
                                  'recarregue os dados.',
                        ),
                        backgroundColor: refreshError == null
                            ? AppColors.primary
                            : Colors.orange.shade700,
                        behavior: SnackBarBehavior.floating,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    );
                  }
                } catch (error) {
                  if (!dialogContext.mounted) return;

                  setDialogState(() {
                    isSubmitting = false;
                    dialogError =
                        'Não foi possível concluir a moderação: $error';
                  });
                }
              }

              return AlertDialog(
                backgroundColor: Colors.white,
                surfaceTintColor: Colors.transparent,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(22),
                ),
                titlePadding: const EdgeInsets.fromLTRB(22, 22, 16, 8),
                contentPadding: const EdgeInsets.fromLTRB(22, 12, 22, 8),
                actionsPadding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                title: Row(
                  children: [
                    Container(
                      width: 42,
                      height: 42,
                      decoration: BoxDecoration(
                        color: isApprove
                            ? AppColors.primary.withValues(alpha: 0.10)
                            : Colors.red.withValues(alpha: 0.08),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Icon(
                        isApprove
                            ? Icons.verified_rounded
                            : Icons.block_rounded,
                        color: isApprove
                            ? AppColors.primary
                            : Colors.red.shade700,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Text(
                        isApprove
                            ? 'Aprovar avaliação'
                            : 'Rejeitar avaliação',
                        style: const TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w800,
                          color: Color(0xFF173B57),
                        ),
                      ),
                    ),
                  ],
                ),
                content: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Avaliação de ${rev.userName} sobre ${rev.pharmacyName}:',
                        style: const TextStyle(
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                          color: Color(0xFF173B57),
                        ),
                      ),
                      const SizedBox(height: 12),
                      _ModerationRatingRow(
                        label: 'Farmácia',
                        rating: rev.pharmacyRating,
                        comment: rev.pharmacyComment,
                      ),
                      const SizedBox(height: 8),
                      _ModerationRatingRow(
                        label: 'Aplicação',
                        rating: rev.appRating,
                        comment: rev.appComment,
                      ),
                      const SizedBox(height: 18),
                      TextField(
                        controller: noteController,
                        enabled: !isSubmitting,
                        maxLines: 3,
                        decoration: InputDecoration(
                          labelText: isApprove
                              ? 'Nota de aprovação (opcional)'
                              : 'Motivo da rejeição / ocultação',
                          hintText: isApprove
                              ? 'Ex.: Verificado com a farmácia, crítica legítima.'
                              : 'Ex.: Linguagem inadequada ou informação falsa.',
                          alignLabelWithHint: true,
                          filled: true,
                          fillColor: const Color(0xFFF8FAFC),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(14),
                            borderSide: const BorderSide(
                              color: Color(0xFFE2E8F0),
                            ),
                          ),
                        ),
                      ),
                      if (dialogError != null) ...[
                        const SizedBox(height: 12),
                        Container(
                          width: double.infinity,
                          padding: const EdgeInsets.all(12),
                          decoration: BoxDecoration(
                            color: Colors.red.shade50,
                            borderRadius: BorderRadius.circular(12),
                            border: Border.all(
                              color: Colors.red.shade200,
                            ),
                          ),
                          child: Text(
                            dialogError!,
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontSize: 12,
                            ),
                          ),
                        ),
                      ],
                      if (isSubmitting) ...[
                        const SizedBox(height: 16),
                        const Row(
                          children: [
                            SizedBox(
                              width: 18,
                              height: 18,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                              ),
                            ),
                            SizedBox(width: 10),
                            Expanded(
                              child: Text(
                                'A processar a decisão...',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],
                    ],
                  ),
                ),
                actions: [
                  TextButton(
                    onPressed: isSubmitting
                        ? null
                        : () => Navigator.of(dialogContext).pop(),
                    child: const Text('Cancelar'),
                  ),
                  FilledButton(
                    style: FilledButton.styleFrom(
                      backgroundColor:
                          isApprove ? AppColors.primary : Colors.red.shade700,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: isSubmitting ? null : submitModeration,
                    child: isSubmitting
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : Text(
                            isApprove
                                ? 'Aprovar e publicar'
                                : 'Confirmar rejeição',
                          ),
                  ),
                ],
              );
            },
          );
        },
      );
    } finally {
      noteController.dispose();
    }
  }

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(adminReviewsProvider);
    final pendingList = state.pendingModerationReviews;

    if (state.isLoading) {
      return const Center(
        child: CircularProgressIndicator(),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (state.notifications.isNotEmpty) ...[
            _buildNotifications(context, ref, state),
            const SizedBox(height: 20),
          ],

          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              const Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Avaliações a aguardar moderação',
                      style: TextStyle(
                        fontSize: 17,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF173B57),
                      ),
                    ),
                    SizedBox(height: 5),
                    Text(
                      'Críticas com 1 ou 2 estrelas submetidas por utentes',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondaryLight,
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 10),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 11,
                  vertical: 8,
                ),
                decoration: BoxDecoration(
                  color: Colors.amber.shade50,
                  borderRadius: BorderRadius.circular(12),
                  border: Border.all(
                    color: Colors.amber.shade200,
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.hourglass_top_rounded,
                      size: 16,
                      color: Colors.amber.shade800,
                    ),
                    const SizedBox(width: 5),
                    Text(
                      '${pendingList.length} pendente(s)',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w800,
                        color: Colors.amber.shade900,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),

          const SizedBox(height: 16),

          if (pendingList.isEmpty)
            _buildEmptyState()
          else
            ListView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              itemCount: pendingList.length,
              itemBuilder: (context, index) {
                final rev = pendingList[index];

                return _buildPendingReviewCard(
                  context,
                  ref,
                  rev,
                );
              },
            ),

          const SizedBox(height: 24),

          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.history_rounded,
                  color: AppColors.primary,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Histórico de avaliações aprovadas',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF173B57),
                  ),
                ),
              ),
            ],
          ),

          const SizedBox(height: 12),

          ...state.reviews
              .where((r) => r.status == 'approved')
              .map(_buildApprovedReviewCard),
        ],
      ),
    );
  }

  Widget _buildNotifications(
    BuildContext context,
    WidgetRef ref,
    dynamic state,
  ) {
    return Container(
      padding: const EdgeInsets.all(15),
      decoration: BoxDecoration(
        color: const Color(0xFFFFF6F5),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.red.shade100,
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 38,
                height: 38,
                decoration: BoxDecoration(
                  color: Colors.red.withValues(alpha: 0.09),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.red.shade700,
                ),
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Alertas do administrador FARCLIK',
                  style: TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w800,
                    color: Color(0xFF173B57),
                  ),
                ),
              ),
              Badge(
                label: Text('${state.unreadNotificationsCount} novos'),
                backgroundColor: Colors.red.shade700,
              ),
            ],
          ),
          const SizedBox(height: 14),
          ...state.notifications.take(3).map((notif) {
            return Container(
              margin: const EdgeInsets.only(bottom: 8),
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: Colors.white,
                borderRadius: BorderRadius.circular(12),
                border: Border.all(
                  color: Colors.red.shade100,
                ),
              ),
              child: Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          notif.title,
                          style: TextStyle(
                            fontWeight: FontWeight.w800,
                            fontSize: 13,
                            color: Colors.red.shade800,
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          notif.message,
                          style: const TextStyle(
                            fontSize: 12,
                            color: Color(0xFF475569),
                          ),
                        ),
                      ],
                    ),
                  ),
                  if (!notif.isRead)
                    IconButton(
                      icon: const Icon(
                        Icons.check_circle_outline_rounded,
                        color: AppColors.primary,
                        size: 21,
                      ),
                      tooltip: 'Marcar como lido',
                      onPressed: () {
                        ref
                            .read(adminReviewsProvider.notifier)
                            .markNotificationRead(notif.id);
                      },
                    ),
                ],
              ),
            );
          }),
        ],
      ),
    );
  }

  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(
        horizontal: 22,
        vertical: 30,
      ),
      decoration: BoxDecoration(
        color: const Color(0xFFF0F9F3),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: AppColors.primary.withValues(alpha: 0.20),
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.10),
              borderRadius: BorderRadius.circular(18),
            ),
            child: const Icon(
              Icons.verified_user_rounded,
              size: 32,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Nenhuma avaliação pendente de moderação!',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 15,
              fontWeight: FontWeight.w800,
              color: Color(0xFF173B57),
            ),
          ),
          const SizedBox(height: 6),
          const Text(
            'Todas as críticas baixas foram analisadas e decididas.',
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 12,
              color: Colors.black54,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildPendingReviewCard(
    BuildContext context,
    WidgetRef ref,
    ReviewModel rev,
  ) {
    return Container(
      margin: const EdgeInsets.only(bottom: 16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.amber.shade300,
        ),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.035),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(15),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                CircleAvatar(
                  radius: 21,
                  backgroundColor: AppColors.primary.withValues(alpha: 0.10),
                  child: const Icon(
                    Icons.person_outline_rounded,
                    color: AppColors.primary,
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        rev.userName,
                        style: const TextStyle(
                          fontWeight: FontWeight.w800,
                          fontSize: 14,
                          color: Color(0xFF173B57),
                        ),
                      ),
                      const SizedBox(height: 3),
                      Text(
                        'Reserva #${rev.reservationId} • Utente ${rev.userPhone}',
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
                    horizontal: 9,
                    vertical: 6,
                  ),
                  decoration: BoxDecoration(
                    color: Colors.red.shade50,
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.shield_outlined,
                        size: 14,
                        color: Colors.red.shade700,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '1-2★ Baixa',
                        style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w800,
                          color: Colors.red.shade700,
                        ),
                      ),
                    ],
                  ),
                ),
              ],
            ),

            const SizedBox(height: 14),

            _ReviewRatingCard(
              icon: Icons.storefront_rounded,
              title: 'Farmácia: ${rev.pharmacyName}',
              rating: rev.pharmacyRating,
              comment: rev.pharmacyComment,
              ratingColor: Colors.red.shade700,
            ),

            const SizedBox(height: 9),

            _ReviewRatingCard(
              icon: Icons.smartphone_rounded,
              title: 'Aplicação FARCLIK',
              rating: rev.appRating,
              comment: rev.appComment,
              ratingColor: AppColors.primary,
            ),

            const SizedBox(height: 16),

            Row(
              children: [
                Expanded(
                  child: OutlinedButton.icon(
                    style: OutlinedButton.styleFrom(
                      foregroundColor: Colors.red.shade700,
                      side: BorderSide(
                        color: Colors.red.shade300,
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.block_rounded,
                      size: 17,
                    ),
                    label: const Text(
                      'Rejeitar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _showModerationNoteDialog(
                      context,
                      ref,
                      rev,
                      'rejected',
                    ),
                  ),
                ),
                const SizedBox(width: 10),
                Expanded(
                  child: FilledButton.icon(
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 12),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    icon: const Icon(
                      Icons.check_circle_rounded,
                      size: 17,
                    ),
                    label: const Text(
                      'Aprovar',
                      style: TextStyle(fontWeight: FontWeight.w700),
                    ),
                    onPressed: () => _showModerationNoteDialog(
                      context,
                      ref,
                      rev,
                      'approved',
                    ),
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildApprovedReviewCard(ReviewModel rev) {
    return Container(
      margin: const EdgeInsets.only(bottom: 9),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(15),
        border: Border.all(
          color: const Color(0xFFE8EEF2),
        ),
      ),
      child: ListTile(
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 13,
          vertical: 7,
        ),
        leading: CircleAvatar(
          backgroundColor: AppColors.primaryLight,
          child: Text(
            '${rev.pharmacyRating.toInt()}★',
            style: const TextStyle(
              fontWeight: FontWeight.w800,
              color: AppColors.primaryDark,
            ),
          ),
        ),
        title: Text(
          '${rev.userName} • ${rev.pharmacyName}',
          style: const TextStyle(
            fontSize: 13,
            fontWeight: FontWeight.w700,
            color: Color(0xFF173B57),
          ),
        ),
        subtitle: Text(
          'Farmácia: ${rev.pharmacyComment ?? "Sem comentário"} '
          '| App: ${rev.appRating}★',
          style: const TextStyle(
            fontSize: 11,
            color: Colors.black54,
          ),
        ),
        trailing: const Icon(
          Icons.verified_rounded,
          color: AppColors.primary,
          size: 21,
        ),
      ),
    );
  }
}

class _ModerationRatingRow extends StatelessWidget {
  final String label;
  final num rating;
  final String? comment;

  const _ModerationRatingRow({
    required this.label,
    required this.rating,
    this.comment,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(11),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FA),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Expanded(
                child: Text(
                  label,
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w700,
                    color: Color(0xFF173B57),
                  ),
                ),
              ),
              Text(
                '$rating★',
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.w800,
                  color: AppColors.primary,
                ),
              ),
            ],
          ),
          if (comment != null && comment!.isNotEmpty) ...[
            const SizedBox(height: 5),
            Text(
              '“$comment”',
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontStyle: FontStyle.italic,
              ),
            ),
          ],
        ],
      ),
    );
  }
}

class _ReviewRatingCard extends StatelessWidget {
  final IconData icon;
  final String title;
  final num rating;
  final String? comment;
  final Color ratingColor;

  const _ReviewRatingCard({
    required this.icon,
    required this.title,
    required this.rating,
    required this.comment,
    required this.ratingColor,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: const Color(0xFFF5F8FA),
        borderRadius: BorderRadius.circular(13),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                icon,
                size: 18,
                color: AppColors.primary,
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Text(
                  title,
                  style: const TextStyle(
                    fontWeight: FontWeight.w700,
                    fontSize: 12,
                    color: Color(0xFF173B57),
                  ),
                ),
              ),
              Text(
                '$rating★',
                style: TextStyle(
                  fontWeight: FontWeight.w800,
                  fontSize: 13,
                  color: ratingColor,
                ),
              ),
            ],
          ),
          if (comment != null && comment!.isNotEmpty) ...[
            const SizedBox(height: 7),
            Text(
              '“$comment”',
              style: const TextStyle(
                fontSize: 12,
                fontStyle: FontStyle.italic,
                color: Color(0xFF475569),
              ),
            ),
          ],
        ],
      ),
    );
  }
}
