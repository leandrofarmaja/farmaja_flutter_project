import 'package:flutter/material.dart';
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
  State<PrescriptionReviewDialog> createState() => _PrescriptionReviewDialogState();
}

class _PrescriptionReviewDialogState extends State<PrescriptionReviewDialog> {
  final TextEditingController _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _notesController.dispose();
    super.dispose();
  }

  void _handleAction(String status) {
    setState(() => _isSubmitting = true);
    widget.onReview(status, _notesController.text.trim());
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    final p = widget.prescription;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        maxWidth: 500,
        child: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.between,
                children: [
                  const Text(
                    'Análise de Receita Médica',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close_rounded),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),
              const Divider(),
              const SizedBox(height: 8),

              Text('Paciente: ${p.userName}', style: const TextStyle(fontWeight: FontWeight.bold)),
              Text('Medicamento: ${p.medicineName}', style: const TextStyle(color: AppColors.textSecondaryLight)),
              const SizedBox(height: 12),

              // Image viewer container
              ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: Container(
                  height: 240,
                  width: double.infinity,
                  color: Colors.black12,
                  child: Image.network(
                    p.imageUrl,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stackTrace) {
                      return const Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.description_rounded, size: 48, color: Colors.grey),
                            SizedBox(height: 8),
                            Text('Imagem da receita médica indisponível', style: TextStyle(color: Colors.grey)),
                          ],
                        ),
                      );
                    },
                  ),
                ),
              ),

              const SizedBox(height: 12),

              TextFormField(
                controller: _notesController,
                decoration: const InputDecoration(
                  labelText: 'Observações do Farmacêutico (Opcional)',
                  hintText: 'Ex: Validade confirmada. Dosagem correta.',
                  prefixIcon: Icon(Icons.note_alt_outlined),
                ),
              ),

              const SizedBox(height: 20),

              Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      icon: const Icon(Icons.cancel_outlined, color: Colors.red),
                      label: const Text('Rejeitar Receita', style: TextStyle(color: Colors.red)),
                      onPressed: _isSubmitting ? null : () => _handleAction('rejected'),
                      style: OutlinedButton.styleFrom(
                        side: const BorderSide(color: Colors.red),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      icon: const Icon(Icons.check_circle_rounded),
                      label: const Text('Aprovar Receita'),
                      onPressed: _isSubmitting ? null : () => _handleAction('verified'),
                      style: FilledButton.styleFrom(
                        backgroundColor: Colors.green,
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
