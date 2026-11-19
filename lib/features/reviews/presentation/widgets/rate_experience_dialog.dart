import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/supabase_database_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../reservations/domain/reservation_model.dart';
import '../../domain/review_model.dart';
import 'star_rating_input.dart';

class RateExperienceDialog extends ConsumerStatefulWidget {
  final ReservationModel reservation;
  final VoidCallback onSubmitted;

  const RateExperienceDialog({
    super.key,
    required this.reservation,
    required this.onSubmitted,
  });

  @override
  ConsumerState<RateExperienceDialog> createState() =>
      _RateExperienceDialogState();
}

class _RateExperienceDialogState
    extends ConsumerState<RateExperienceDialog> {
  double _pharmacyRating = 5.0;
  final _pharmacyCommentController = TextEditingController();

  double _appRating = 5.0;
  final _appCommentController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _pharmacyCommentController.dispose();
    _appCommentController.dispose();
    super.dispose();
  }

  Future<void> _handleSubmit() async {
    if (_isSubmitting) return;

    final user = ref.read(authProvider).user;

    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Inicie sessão para enviar a sua avaliação.'),
        ),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    try {
      final review = ReviewModel(
        id: 'pending',
        reservationId: widget.reservation.id,
        userId: user.id,
        userName: user.fullName,
        userPhone: user.phone,
        pharmacyId: widget.reservation.pharmacyId,
        pharmacyName: widget.reservation.pharmacyName,
        pharmacyRating: _pharmacyRating,
        pharmacyComment:
            _pharmacyCommentController.text.trim().isNotEmpty
                ? _pharmacyCommentController.text.trim()
                : null,
        appRating: _appRating,
        appComment: _appCommentController.text.trim().isNotEmpty
            ? _appCommentController.text.trim()
            : null,
        createdAt: DateTime.now(),
      );

      await SupabaseDatabaseService().submitReview(review);

      if (!mounted) return;

      final messenger = ScaffoldMessenger.of(context);
      final navigator = Navigator.of(context);

      navigator.pop();
      widget.onSubmitted();

      messenger.showSnackBar(
        const SnackBar(
          content: Text('Avaliação submetida com sucesso.'),
          backgroundColor: Colors.green,
        ),
      );
    } catch (e) {
      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Não foi possível enviar a avaliação: $e'),
          backgroundColor: Colors.red,
        ),
      );
    } finally {
      if (mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  InputDecoration _commentDecoration({
    required String label,
    required String hint,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      hintText: hint,
      prefixIcon: Icon(icon, color: AppColors.primary),
      filled: true,
      fillColor: const Color(0xFFF8FBF9),
      alignLabelWithHint: true,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 14,
      ),
      border: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE3EBE5)),
      ),
      enabledBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(color: Color(0xFFE3EBE5)),
      ),
      focusedBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(14),
        borderSide: const BorderSide(
          color: AppColors.primary,
          width: 1.5,
        ),
      ),
    );
  }

  Widget _buildSectionHeader({
    required IconData icon,
    required String title,
    required String description,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Container(
              width: 36,
              height: 36,
              decoration: BoxDecoration(
                color: AppColors.primaryLight,
                borderRadius: BorderRadius.circular(11),
              ),
              child: Icon(
                icon,
                color: AppColors.primary,
                size: 19,
              ),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(
                title,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                  color: Color(0xFF173B57),
                ),
              ),
            ),
          ],
        ),
        const SizedBox(height: 7),
        Padding(
          padding: const EdgeInsets.only(left: 46),
          child: Text(
            description,
            style: const TextStyle(
              fontSize: 12,
              height: 1.4,
              color: AppColors.textSecondaryLight,
            ),
          ),
        ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    final isLowRating =
        _pharmacyRating <= 2 || _appRating <= 2;

    return Dialog(
      backgroundColor: Colors.white,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 16,
        vertical: 24,
      ),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                children: [
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Text(
                          'Avaliar experiência',
                          style: TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w800,
                            color: Color(0xFF173B57),
                          ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          'Partilhe a sua opinião connosco.',
                          style: TextStyle(
                            fontSize: 12,
                            color: Colors.grey.shade600,
                          ),
                        ),
                      ],
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    style: IconButton.styleFrom(
                      backgroundColor: const Color(0xFFF3F7F4),
                    ),
                    icon: const Icon(Icons.close_rounded),
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.pop(context),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.all(13),
                decoration: BoxDecoration(
                  color: const Color(0xFFF0F7F2),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Row(
                  children: [
                    const Icon(
                      Icons.local_pharmacy_rounded,
                      color: AppColors.primary,
                      size: 21,
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      child: Text(
                        'Reserva concluída na ${widget.reservation.pharmacyName}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: Color(0xFF315B43),
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 22),
              _buildSectionHeader(
                icon: Icons.local_pharmacy_rounded,
                title: '1. Atendimento da farmácia',
                description:
                    'Qualidade do serviço, rapidez e simpatia no balcão.',
              ),
              const SizedBox(height: 12),
              StarRatingInput(
                label: 'Classificação do atendimento',
                description:
                    'Seleccione o número de estrelas correspondente.',
                rating: _pharmacyRating,
                onRatingChanged: (val) {
                  setState(() => _pharmacyRating = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _pharmacyCommentController,
                maxLines: 3,
                minLines: 2,
                decoration: _commentDecoration(
                  label: 'Comentário sobre a farmácia (opcional)',
                  hint:
                      'Ex.: Atendimento atencioso e medicamento pronto a tempo.',
                  icon: Icons.rate_review_outlined,
                ),
              ),
              const SizedBox(height: 24),
              const Divider(color: Color(0xFFEDF1EE)),
              const SizedBox(height: 20),
              _buildSectionHeader(
                icon: Icons.phone_android_rounded,
                title: '2. Aplicação FARCLIK',
                description:
                    'Facilidade de busca, reserva, navegação e rapidez da aplicação.',
              ),
              const SizedBox(height: 12),
              StarRatingInput(
                label: 'Classificação da aplicação',
                description:
                    'Avalie a sua experiência ao utilizar a FARCLIK.',
                rating: _appRating,
                onRatingChanged: (val) {
                  setState(() => _appRating = val);
                },
              ),
              const SizedBox(height: 12),
              TextField(
                controller: _appCommentController,
                maxLines: 3,
                minLines: 2,
                decoration: _commentDecoration(
                  label: 'Comentário sobre a aplicação (opcional)',
                  hint: 'Ex.: Encontrei facilmente o medicamento.',
                  icon: Icons.smartphone_rounded,
                ),
              ),
              const SizedBox(height: 18),
              if (isLowRating)
                Container(
                  padding: const EdgeInsets.all(13),
                  decoration: BoxDecoration(
                    color: const Color(0xFFFFF8E8),
                    borderRadius: BorderRadius.circular(13),
                    border: Border.all(
                      color: const Color(0xFFF3D48B),
                    ),
                  ),
                  child: Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Icon(
                        Icons.info_outline_rounded,
                        color: Color(0xFF9A6700),
                        size: 20,
                      ),
                      const SizedBox(width: 10),
                      const Expanded(
                        child: Text(
                          'Avaliações com 1 ou 2 estrelas devem ser analisadas antes de serem publicadas.',
                          style: TextStyle(
                            fontSize: 11,
                            height: 1.4,
                            fontWeight: FontWeight.w600,
                            color: Color(0xFF805500),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 22),
              SizedBox(
                height: 52,
                child: FilledButton.icon(
                  style: FilledButton.styleFrom(
                    backgroundColor: AppColors.primary,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                        AppColors.primary.withValues(alpha: 0.55),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(14),
                    ),
                  ),
                  icon: _isSubmitting
                      ? const SizedBox(
                          width: 19,
                          height: 19,
                          child: CircularProgressIndicator(
                            color: Colors.white,
                            strokeWidth: 2,
                          ),
                        )
                      : const Icon(Icons.send_rounded, size: 19),
                  label: Text(
                    _isSubmitting
                        ? 'A submeter...'
                        : 'Enviar avaliação',
                    style: const TextStyle(
                      fontWeight: FontWeight.w700,
                      fontSize: 14,
                    ),
                  ),
                  onPressed: _isSubmitting ? null : _handleSubmit,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
