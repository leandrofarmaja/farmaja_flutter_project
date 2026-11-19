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
  State<SubscriptionPaymentDialog> createState() =>
      _SubscriptionPaymentDialogState();
}

class _SubscriptionPaymentDialogState
    extends State<SubscriptionPaymentDialog> {
  final _formKey = GlobalKey<FormState>();

  String _paymentMethod = 'Transferência IBAN';

  final _referenceController = TextEditingController();

  final _proofUrlController = TextEditingController(
    text:
        'https://images.unsplash.com/photo-1554224155-8d04cb21cd6c?w=500',
  );

  final _notesController = TextEditingController();

  bool _isSubmitting = false;

  @override
  void dispose() {
    _referenceController.dispose();
    _proofUrlController.dispose();
    _notesController.dispose();
    super.dispose();
  }

  Future<void> _submit() async {
    if (_isSubmitting) return;

    if (_formKey.currentState!.validate()) {
      setState(() => _isSubmitting = true);

      try {
        await widget.onSubmit(
          paymentMethod: _paymentMethod,
          referenceNumber: _referenceController.text.trim(),
          proofUrl: _proofUrlController.text.trim(),
          notes: _notesController.text.trim().isEmpty
              ? null
              : _notesController.text.trim(),
        );

        if (!mounted) return;

        Navigator.pop(context);

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text(
              'Comprovativo de 15.000 Kz enviado com sucesso! Aguarda aprovação do administrador.',
            ),
            backgroundColor: AppColors.primary,
          ),
        );
      } catch (e) {
        if (!mounted) return;

        setState(() => _isSubmitting = false);

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Não foi possível submeter o pagamento: $e'),
            backgroundColor: Colors.red.shade700,
          ),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final screenHeight = MediaQuery.of(context).size.height;

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
        constraints: const BoxConstraints(maxWidth: 480),
        child: Container(
          padding: const EdgeInsets.all(22),
          decoration: BoxDecoration(
            color: Colors.white,
            borderRadius: BorderRadius.circular(24),
          ),
          child: SizedBox(
            height: screenHeight * 0.82,
            child: SingleChildScrollView(
              child: Form(
                key: _formKey,
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Row(
                      children: [
                        Container(
                          width: 46,
                          height: 46,
                          decoration: BoxDecoration(
                            color: AppColors.primary.withValues(alpha: 0.10),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: const Icon(
                            Icons.workspace_premium_rounded,
                            color: AppColors.primary,
                            size: 26,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Renovar subscrição',
                                style: TextStyle(
                                  fontSize: 18,
                                  fontWeight: FontWeight.w800,
                                  color: Color(0xFF173B57),
                                ),
                              ),
                              SizedBox(height: 3),
                              Text(
                                'Pagamento mensal da farmácia',
                                style: TextStyle(
                                  fontSize: 12,
                                  color: Colors.black54,
                                ),
                              ),
                            ],
                          ),
                        ),
                        IconButton(
                          tooltip: 'Fechar',
                          onPressed: _isSubmitting
                              ? null
                              : () => Navigator.pop(context),
                          icon: const Icon(Icons.close_rounded),
                        ),
                      ],
                    ),

                    const SizedBox(height: 20),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        gradient: LinearGradient(
                          colors: [
                            AppColors.primary.withValues(alpha: 0.10),
                            const Color(0xFFEFF8F1),
                          ],
                        ),
                        borderRadius: BorderRadius.circular(18),
                        border: Border.all(
                          color: AppColors.primary.withValues(alpha: 0.20),
                        ),
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          const Text(
                            'VALOR DA MENSALIDADE',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.w700,
                              letterSpacing: 0.8,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          const SizedBox(height: 5),
                          const Text(
                            '15.000 Kz',
                            style: TextStyle(
                              fontSize: 27,
                              fontWeight: FontWeight.w900,
                              color: Color(0xFF173B57),
                            ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            'Subscrição mensal da plataforma FARCLIK',
                            style: TextStyle(
                              fontSize: 12,
                              color: Colors.grey.shade700,
                            ),
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 20),

                    const Text(
                      'Dados bancários',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF173B57),
                      ),
                    ),
                    const SizedBox(height: 10),

                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(15),
                      decoration: BoxDecoration(
                        color: const Color(0xFFF4F8FC),
                        borderRadius: BorderRadius.circular(16),
                        border: Border.all(
                          color: const Color(0xFFDCE8F2),
                        ),
                      ),
                      child: const Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            '🇦🇴 Dados para pagamento',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w800,
                              color: AppColors.primaryDark,
                            ),
                          ),
                          SizedBox(height: 12),
                          _BankDetailRow(
                            label: 'Banco',
                            value: 'BFA / BAI / Atlântico',
                          ),
                          _BankDetailRow(
                            label: 'Titular',
                            value: 'FarmaJá Angola Lda',
                          ),
                          _BankDetailRow(
                            label: 'IBAN',
                            value: 'AO06 0040 0000 8192 1001 3018 9',
                          ),
                          _BankDetailRow(
                            label: 'Mensalidade',
                            value: '15.000 Kz / mês',
                            valueColor: AppColors.primary,
                          ),
                        ],
                      ),
                    ),

                    const SizedBox(height: 22),

                    const Text(
                      'Informações do pagamento',
                      style: TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Color(0xFF173B57),
                      ),
                    ),
                    const SizedBox(height: 12),

                    DropdownButtonFormField<String>(
                      initialValue: _paymentMethod,
                      isExpanded: true,
                      decoration: InputDecoration(
                        labelText: 'Método de pagamento',
                        prefixIcon: const Icon(Icons.payment_rounded),
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
                      items: const [
                        DropdownMenuItem(
                          value: 'Transferência IBAN',
                          child: Text('Transferência IBAN (BFA / BAI)'),
                        ),
                        DropdownMenuItem(
                          value: 'Multicaixa Express',
                          child: Text('Multicaixa Express'),
                        ),
                        DropdownMenuItem(
                          value: 'BAI Directo',
                          child: Text('BAI Directo'),
                        ),
                      ],
                      onChanged: _isSubmitting
                          ? null
                          : (val) {
                              if (val != null) {
                                setState(() => _paymentMethod = val);
                              }
                            },
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _referenceController,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'N.º do comprovativo / referência *',
                        hintText: 'Ex.: MCX-882319',
                        prefixIcon: const Icon(Icons.tag_rounded),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                      validator: (v) =>
                          v == null || v.trim().isEmpty
                              ? 'Insira a referência'
                              : null,
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _proofUrlController,
                      keyboardType: TextInputType.url,
                      textInputAction: TextInputAction.next,
                      decoration: InputDecoration(
                        labelText: 'URL da imagem do comprovativo',
                        hintText: 'https://...',
                        helperText: 'Campo opcional',
                        prefixIcon: const Icon(Icons.image_outlined),
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 14),

                    TextFormField(
                      controller: _notesController,
                      minLines: 2,
                      maxLines: 3,
                      textInputAction: TextInputAction.newline,
                      decoration: InputDecoration(
                        labelText: 'Observações / NIF da farmácia',
                        hintText:
                            'Ex.: NIF: 5001928312 - Pagamento referente a Agosto',
                        prefixIcon: const Icon(Icons.notes_rounded),
                        alignLabelWithHint: true,
                        filled: true,
                        fillColor: const Color(0xFFF8FAFC),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                        ),
                        enabledBorder: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(14),
                          borderSide: const BorderSide(
                            color: Color(0xFFE2E8F0),
                          ),
                        ),
                      ),
                    ),

                    const SizedBox(height: 22),

                    SizedBox(
                      width: double.infinity,
                      height: 52,
                      child: FilledButton.icon(
                        style: FilledButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor:
                              AppColors.primary.withValues(alpha: 0.5),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
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
                            : const Icon(Icons.send_rounded),
                        label: Text(
                          _isSubmitting
                              ? 'A submeter...'
                              : 'Enviar comprovativo de 15.000 Kz',
                          style: const TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w800,
                          ),
                        ),
                        onPressed: _isSubmitting ? null : _submit,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _BankDetailRow extends StatelessWidget {
  final String label;
  final String value;
  final Color? valueColor;

  const _BankDetailRow({
    required this.label,
    required this.value,
    this.valueColor,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 88,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 12,
                color: Colors.black54,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value,
              style: TextStyle(
                fontSize: 12,
                color: valueColor ?? const Color(0xFF173B57),
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
