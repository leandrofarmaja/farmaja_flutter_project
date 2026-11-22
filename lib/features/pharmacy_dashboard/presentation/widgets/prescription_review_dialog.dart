import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../prescriptions/domain/prescription_model.dart';

class PrescriptionReviewDialog extends StatefulWidget {
  final PrescriptionModel prescription;
  final Function(String status, String? notes) onReview;

  const PrescriptionReviewDialog({
    super.key,
    required this.prescription,
    required this.onReview,
  });

  @override
  State<PrescriptionReviewDialog> createState() =>
      _PrescriptionReviewDialogState();
}

class _PrescriptionReviewDialogState
    extends State<PrescriptionReviewDialog> {
  final TextEditingController _notesController =
      TextEditingController();

  bool _isSubmitting = false;

  static const Color _navy = Color(0xFF173B57);
  static const Color _background = Color(0xFFF7FBF8);
  static const Color _border = Color(0xFFE5EDE8);

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleAction(String status) {
    if (_isSubmitting) return;

    setState(() {
      _isSubmitting = true;
    });

    try {
      widget.onReview(
        status,
        _notesController.text.trim(),
      );

      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      debugPrint('Erro ao submeter análise da receita: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (!mounted) return;

      setState(() {
        _isSubmitting = false;
      });

      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
          const SnackBar(
            content: Text(
              'Não foi possível submeter a análise da receita.',
            ),
          ),
        );
    }
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          color: AppColors.primary,
          size: 19,
        ),
        const SizedBox(width: 9),
        Text(
          title,
          style: const TextStyle(
            color: _navy,
            fontSize: 14,
            fontWeight: FontWeight.w800,
          ),
        ),
      ],
    );
  }

  Widget _buildPatientDetails(PrescriptionModel prescription) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: _background,
        borderRadius: BorderRadius.circular(14),
        border: Border.all(color: _border),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                Icons.person_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Paciente',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      prescription.userName,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
          const SizedBox(height: 13),
          const Divider(height: 1, color: _border),
          const SizedBox(height: 13),
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Icon(
                LucideIcons.pill,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'Medicamento',
                      style: TextStyle(
                        color: Colors.grey.shade600,
                        fontSize: 11,
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      prescription.medicineName,
                      style: const TextStyle(
                        color: _navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPrescriptionImage(String imageUrl) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(15),
      child: Container(
        height: 250,
        width: double.infinity,
        color: _background,
        child: Image.network(
          imageUrl,
          fit: BoxFit.contain,
          loadingBuilder: (context, child, progress) {
            if (progress == null) return child;

            return const Center(
              child: CircularProgressIndicator(),
            );
          },
          errorBuilder: (context, error, stackTrace) {
            return Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(
                  Iconsax.document_text_bold,
                  size: 46,
                  color: Colors.grey.shade500,
                ),
                const SizedBox(height: 10),
                Text(
                  'Imagem da receita médica indisponível',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 12,
                  ),
                ),
              ],
            );
          },
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final prescription = widget.prescription;

    return Dialog(
      backgroundColor: Colors.white,
      elevation: 12,
      insetPadding: const EdgeInsets.symmetric(
        horizontal: 18,
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
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      color: AppColors.primary.withValues(alpha: 0.09),
                      borderRadius: BorderRadius.circular(13),
                    ),
                    child: const Icon(
                      Icons.medical_information_outlined,
                      color: AppColors.primary,
                      size: 24,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Análise de receita médica',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: _isSubmitting
                        ? null
                        : () => Navigator.of(context).pop(),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: _background,
                      foregroundColor: _navy,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              _buildSectionTitle(
                'Dados da solicitação',
                Icons.person_outline_rounded,
              ),
              const SizedBox(height: 12),

              _buildPatientDetails(prescription),

              const SizedBox(height: 22),

              _buildSectionTitle(
                'Receita médica',
                Iconsax.document_text_bold,
              ),
              const SizedBox(height: 12),

              _buildPrescriptionImage(prescription.imageUrl),

              const SizedBox(height: 22),

              _buildSectionTitle(
                'Observações do farmacêutico',
                Icons.note_alt_outlined,
              ),
              const SizedBox(height: 12),

              TextFormField(
                controller: _notesController,
                enabled: !_isSubmitting,
                maxLines: 3,
                minLines: 2,
                textCapitalization: TextCapitalization.sentences,
                decoration: InputDecoration(
                  hintText:
                      'Ex.: Validade confirmada. Dosagem correcta.',
                  hintStyle: TextStyle(
                    color: Colors.grey.shade500,
                    fontSize: 12,
                  ),
                  filled: true,
                  fillColor: _background,
                  alignLabelWithHint: true,
                  contentPadding: const EdgeInsets.all(14),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(color: _border),
                  ),
                  enabledBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: const BorderSide(color: _border),
                  ),
                  focusedBorder: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(13),
                    borderSide: BorderSide(
                      color: AppColors.primary,
                      width: 1.5,
                    ),
                  ),
                ),
              ),

              const SizedBox(height: 24),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(
                        Icons.cancel_outlined,
                        size: 18,
                      ),
                      label: const Text('Rejeitar'),
                      onPressed: _isSubmitting
                          ? null
                          : () => _handleAction('rejected'),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: Colors.red.shade700,
                        side: BorderSide(
                          color: Colors.red.shade300,
                        ),
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: _isSubmitting
                          ? const SizedBox(
                              width: 17,
                              height: 17,
                              child: CircularProgressIndicator(
                                strokeWidth: 2,
                                color: Colors.white,
                              ),
                            )
                          : const Icon(
                              Icons.check_circle_rounded,
                              size: 18,
                            ),
                      label: Text(
                        _isSubmitting ? 'A submeter...' : 'Aprovar',
                      ),
                      onPressed: _isSubmitting
                          ? null
                          : () => _handleAction('verified'),
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(
                          vertical: 14,
                        ),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
