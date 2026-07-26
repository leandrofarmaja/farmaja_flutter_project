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
  ConsumerState<RateExperienceDialog> createState() => _RateExperienceDialogState();
}

class _RateExperienceDialogState extends ConsumerState<RateExperienceDialog> {
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

  void _handleSubmit() async {
    final user = ref.read(authProvider).user;
    if (user == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Inicie sessão para enviar a sua avaliação.')),
      );
      return;
    }

    setState(() => _isSubmitting = true);

    final review = ReviewModel(
      id: 'rev-${DateTime.now().millisecondsSinceEpoch}',
      reservationId: widget.reservation.id,
      userId: user.id,
      userName: user.fullName,
      userPhone: user.phone,
      pharmacyId: widget.reservation.pharmacyId,
      pharmacyName: widget.reservation.pharmacyName,
      pharmacyRating: _pharmacyRating,
      pharmacyComment: _pharmacyCommentController.text.trim().isNotEmpty
          ? _pharmacyCommentController.text.trim()
          : null,
      appRating: _appRating,
      appComment: _appCommentController.text.trim().isNotEmpty
          ? _appCommentController.text.trim()
          : null,
      createdAt: DateTime.now(),
    );

    final db = SupabaseDatabaseService();
    final result = await db.submitReview(review);

    setState(() => _isSubmitting = false);

    if (mounted) {
      Navigator.pop(context);
      widget.onSubmitted();

      final isLow = result['requiresModeration'] == true;
      final msg = result['message'] as String? ?? 'Avaliação submetida!';

      showDialog(
        context: context,
        builder: (ctx) => AlertDialog(
          icon: Icon(
            isLow ? Icons.shield_outlined : Icons.check_circle_rounded,
            size: 48,
            color: isLow ? Colors.amber.shade800 : Colors.green,
          ),
          title: Text(
            isLow ? 'Avaliação para Moderação 🛡️' : 'Obrigado pela sua Avaliação! ⭐',
            textAlign: TextAlign.center,
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
          content: Text(
            msg,
            textAlign: TextAlign.center,
            style: const TextStyle(fontSize: 14),
          ),
          actions: [
            FilledButton(
              onPressed: () => Navigator.pop(ctx),
              child: const Text('Concluído'),
            ),
          ],
        ),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isLowRating = _pharmacyRating <= 2 || _appRating <= 2;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Avaliar Experiência ⭐',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              Text(
                'Reserva concluída na ${widget.reservation.pharmacyName}',
                style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
              ),
              const SizedBox(height: 16),

              // 1. Pharmacy Service Rating
              StarRatingInput(
                label: '1. Atendimento da Farmácia',
                description: 'Qualidade do serviço, rapidez e simpatia no balcão.',
                rating: _pharmacyRating,
                onRatingChanged: (val) => setState(() => _pharmacyRating = val),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _pharmacyCommentController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Comentário sobre a Farmácia (Opcional)',
                  hintText: 'Ex: Atendimento atencioso e medicamento pronto a tempo.',
                  prefixIcon: Icon(Icons.rate_review_outlined),
                ),
              ),
              const SizedBox(height: 20),

              // 2. FarmaJá App Rating
              StarRatingInput(
                label: '2. Aplicação FarmaJá 📱',
                description: 'Facilidade de busca, reserva, navegação e rapidez do app.',
                rating: _appRating,
                onRatingChanged: (val) => setState(() => _appRating = val),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: _appCommentController,
                maxLines: 2,
                decoration: const InputDecoration(
                  labelText: 'Comentário sobre o Aplicativo (Opcional)',
                  hintText: 'Ex: Encontrei fácil o fármaco em Luanda.',
                  prefixIcon: Icon(Icons.smartphone_rounded),
                ),
              ),
              const SizedBox(height: 16),

              if (isLowRating)
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.amber.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.amber.shade300),
                  ),
                  child: Row(
                    children: [
                      Icon(Icons.shield_outlined, color: Colors.amber.shade900),
                      const SizedBox(width: 10),
                      Expanded(
                        child: Text(
                          'Avaliações com 1 ou 2 estrelas passam por moderação no Painel Admin FarmaJá antes de ficarem públicas.',
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: Colors.amber.shade900,
                          ),
                        ),
                      ),
                    ],
                  ),
                ),
              const SizedBox(height: 20),

              FilledButton.icon(
                style: FilledButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 14),
                  backgroundColor: AppColors.primary,
                ),
                icon: _isSubmitting
                    ? const SizedBox(
                        width: 18,
                        height: 18,
                        child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2),
                      )
                    : const Icon(Icons.send_rounded),
                label: Text(
                  _isSubmitting ? 'A submeter...' : 'Enviar Avaliação',
                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                ),
                onPressed: _isSubmitting ? null : _handleSubmit,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
