import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';

class SubscriptionPaymentDialog extends StatefulWidget {
  final Function({
    required String paymentMethod,
    required String referenceNumber,
    required String proofUrl,
    String? notes,
  }) onSubmit;

  const SubscriptionPaymentDialog({
    super.key,
    required this.onSubmit,
  });

  @override
  State<SubscriptionPaymentDialog> createState() => _SubscriptionPaymentDialogState();
}

class _SubscriptionPaymentDialogState extends State<SubscriptionPaymentDialog> {
  final _formKey = GlobalKey<FormState>();
  String _paymentMethod = 'Transferência IBAN';
  final _referenceController = TextEditingController();
  final _proofUrlController = TextEditingController(
      text: 'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=500');
  final _notesController = TextEditingController();
  bool _isSubmitting = false;

  @override
  void dispose() {
    _referenceController.dispose();
    _proofUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  void _submit() async {
    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);
      await widget.onSubmit(
        paymentMethod: _paymentMethod,
        referenceNumber: _referenceController.text.trim(),
        proofUrl: _proofUrlController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
      );
      if (mounted) {
        Navigator.pop(context);
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Comprovativo de 15.000 Kz enviado com sucesso! Aguarda aprovação do administrador.'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(20),
        maxWidth: 480,
        child: SingleChildScrollView(
          child: Form(
            key: _formKey,
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.workspace_premium_rounded, color: AppColors.primary, size: 28),
                        SizedBox(width: 8),
                        Text(
                          'Renovar Subscrição (15.000 Kz)',
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
                        ),
                      ],
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 8),

                // Bank details box
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(12),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        '🇦🇴 Dados Bancários para Pagamento:',
                        style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                      ),
                      SizedBox(height: 6),
                      Text('• Banco: BFA / BAI / Atlântico', style: TextStyle(fontSize: 12)),
                      Text('• Titular: FarmaJá Angola Lda', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('• IBAN: AO06 0040 0000 8192 1001 3018 9', style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold)),
                      Text('• Mensalidade: 15.000 Kz / mês', style: TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold)),
                    ],
                  ),
                ),
                const SizedBox(height: 16),

                // Method
                DropdownButtonFormField<String>(
                  value: _paymentMethod,
                  decoration: const InputDecoration(
                    labelText: 'Método de Pagamento',
                    prefixIcon: Icon(Icons.payment_rounded),
                  ),
                  items: const [
                    DropdownMenuItem(value: 'Transferência IBAN', child: Text('Transferência IBAN (BFA / BAI)')),
                    DropdownMenuItem(value: 'Multicaixa Express', child: Text('Multicaixa Express')),
                    DropdownMenuItem(value: 'BAI Directo', child: Text('BAI Directo')),
                  ],
                  onChanged: (val) => setState(() => _paymentMethod = val!),
                ),
                const SizedBox(height: 12),

                // Reference / ID
                TextFormField(
                  controller: _referenceController,
                  decoration: const InputDecoration(
                    labelText: 'Nº do Comprovativo / Referência *',
                    hintText: 'Ex: MCX-882319 ou Ref. Transferência',
                    prefixIcon: Icon(Icons.tag_rounded),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Insira a referência' : null,
                ),
                const SizedBox(height: 12),

                // Proof Image URL
                TextFormField(
                  controller: _proofUrlController,
                  decoration: const InputDecoration(
                    labelText: 'URL da Imagem do Comprovativo (Opcional)',
                    hintText: 'https://...',
                    prefixIcon: Icon(Icons.image_outlined),
                  ),
                ),
                const SizedBox(height: 12),

                // Notes
                TextFormField(
                  controller: _notesController,
                  decoration: const InputDecoration(
                    labelText: 'Observações / NIF da Farmácia',
                    hintText: 'Ex: NIF: 5001928312 - Pagamento referente a Agosto',
                    prefixIcon: Icon(Icons.notes_rounded),
                  ),
                ),
                const SizedBox(height: 20),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: _isSubmitting
                        ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                        : const Icon(Icons.send_rounded),
                    label: Text(_isSubmitting ? 'A submeter...' : 'Enviar Comprovativo de 15.000 Kz'),
                    onPressed: _isSubmitting ? null : _submit,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
