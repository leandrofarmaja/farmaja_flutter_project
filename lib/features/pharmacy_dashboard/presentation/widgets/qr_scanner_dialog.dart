import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../reservations/domain/reservation_model.dart';

class QrScannerDialog extends StatefulWidget {
  final Future<ReservationModel?> Function(String code) onValidateCode;

  const QrScannerDialog({
    super.key,
    required this.onValidateCode,
  });

  @override
  State<QrScannerDialog> createState() => _QrScannerDialogState();
}

class _QrScannerDialogState extends State<QrScannerDialog> {
  final TextEditingController _codeController = TextEditingController();

  bool _isValidating = false;

  ReservationModel? _validatedReservation;
  String? _errorMessage;

  @override
  void dispose() {
    _codeController.dispose();
    super.dispose();
  }

  Future<void> _handleValidate() async {
    final code = _codeController.text.trim().toUpperCase();

    if (code.isEmpty || _isValidating) {
      setState(() {
        _errorMessage = 'Introduza o código da reserva.';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
      _validatedReservation = null;
    });

    try {
      final reservation = await widget.onValidateCode(code);

      if (!mounted) return;

      setState(() {
        _validatedReservation = reservation;
        _isValidating = false;

        if (reservation == null) {
          _errorMessage =
              'Código inválido, reserva expirada ou sem autorização para esta farmácia.';
        }
      });
    } catch (_) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Não foi possível validar o código. Verifique a ligação e tente novamente.';
        _isValidating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Row(
                    children: [
                      Icon(
                        Icons.qr_code_scanner_rounded,
                        color: AppColors.primary,
                        size: 28,
                      ),
                      SizedBox(width: 8),
                      Text(
                        'Validar código de reserva',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
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
              const SizedBox(height: 12),

              if (_validatedReservation != null) ...[
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(16),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.shade300,
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.verified_rounded,
                        color: Colors.blue.shade700,
                        size: 48,
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Código de reserva válido',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: Colors.blue.shade800,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Medicamento: ${_validatedReservation!.medicineName}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Código: ${_validatedReservation!.pickupCode}',
                      ),
                      Text(
                        'Valor: ${_validatedReservation!.totalPriceKz.toInt()} Kz',
                      ),
                      const SizedBox(height: 12),
                      const Chip(
                        avatar: Icon(
                          Icons.schedule_rounded,
                          color: Colors.white,
                          size: 18,
                        ),
                        label: Text('Estado: Aguardando confirmação'),
                        backgroundColor: Colors.orange,
                        labelStyle: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 11,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 12),
                const Text(
                  'A validação do código não confirma o levantamento. '
                  'Verifique presencialmente a receita médica, quando exigida, '
                  'e só confirme a entrega depois de entregar o medicamento.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 16),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: () {
                      setState(() {
                        _validatedReservation = null;
                        _errorMessage = null;
                        _codeController.clear();
                      });
                    },
                    child: const Text('Validar outro código'),
                  ),
                ),
              ] else ...[
                Container(
                  width: double.infinity,
                  height: 150,
                  decoration: BoxDecoration(
                    color: Colors.grey.shade100,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: AppColors.borderLight,
                      width: 2,
                    ),
                  ),
                  child: const Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(
                        Icons.qr_code_2_rounded,
                        size: 56,
                        color: AppColors.primary,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Introduza o código apresentado pelo cliente',
                        textAlign: TextAlign.center,
                        style: TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 16),
                TextFormField(
                  controller: _codeController,
                  textCapitalization: TextCapitalization.characters,
                  enabled: !_isValidating,
                  decoration: InputDecoration(
                    labelText: 'Código de levantamento',
                    hintText: 'Introduza o código da reserva',
                    prefixIcon: const Icon(Icons.key_rounded),
                    suffixIcon: IconButton(
                      icon: const Icon(
                        Icons.arrow_forward_rounded,
                        color: AppColors.primary,
                      ),
                      onPressed: _isValidating ? null : _handleValidate,
                    ),
                  ),
                  onFieldSubmitted: (_) => _handleValidate(),
                ),
                if (_errorMessage != null) ...[
                  const SizedBox(height: 12),
                  Text(
                    _errorMessage!,
                    style: const TextStyle(
                      color: Colors.red,
                      fontSize: 12,
                      fontWeight: FontWeight.bold,
                    ),
                    textAlign: TextAlign.center,
                  ),
                ],
                const SizedBox(height: 20),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: _isValidating
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              color: Colors.white,
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.verified_user_rounded),
                    label: Text(
                      _isValidating
                          ? 'A validar...'
                          : 'Validar código',
                    ),
                    onPressed: _isValidating ? null : _handleValidate,
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}
