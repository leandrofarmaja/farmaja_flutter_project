import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/widgets/qr_code_widget.dart';
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
  bool _isScanning = false;
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
    if (code.isEmpty) return;

    setState(() {
      _isValidating = true;
      _errorMessage = null;
      _validatedReservation = null;
    });

    try {
      final res = await widget.onValidateCode(code);
      if (res != null) {
        setState(() {
          _validatedReservation = res;
          _isValidating = false;
        });
      } else {
        setState(() {
          _errorMessage = 'Código de reserva "$code" não encontrado ou já resgatado.';
          _isValidating = false;
        });
      }
    } catch (e) {
      setState(() {
        _errorMessage = 'Erro ao validar código. Verifique a ligação.';
        _isValidating = false;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      child: Container(
        padding: const EdgeInsets.all(24),
        maxWidth: 450,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.between,
              children: [
                const Row(
                  children: [
                    Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary, size: 28),
                    SizedBox(width: 8),
                    Text(
                      'Validar QR Code',
                      style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
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
              // Success result layout
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: Colors.green.shade50,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: Colors.green.shade300),
                ),
                child: Column(
                  children: [
                    const Icon(Icons.check_circle_rounded, color: Colors.green, size: 48),
                    const SizedBox(height: 8),
                    const Text(
                      'Reserva Confirmada com Sucesso!',
                      style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: Colors.green),
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Medicamento: ${_validatedReservation!.medicineName}',
                      style: const TextStyle(fontWeight: FontWeight.bold),
                    ),
                    Text('Código: ${_validatedReservation!.pickupCode}'),
                    Text('Valor Total: ${_validatedReservation!.totalPriceKz.toInt()} Kz'),
                    const SizedBox(height: 8),
                    const Chip(
                      label: Text('Status: Entregue ao Cliente'),
                      backgroundColor: Colors.green,
                      labelStyle: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              SizedBox(
                width: double.infinity,
                child: FilledButton(
                  onPressed: () {
                    setState(() {
                      _validatedReservation = null;
                      _codeController.clear();
                    });
                  },
                  child: const Text('Validar Outro QR Code'),
                ),
              ),
            ] else ...[
              // Simulated Scanner Graphic / Code Input
              Container(
                width: double.infinity,
                height: 160,
                decoration: BoxDecoration(
                  color: Colors.grey.shade100,
                  borderRadius: BorderRadius.circular(16),
                  border: Border.all(color: AppColors.borderLight, width: 2),
                ),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      _isScanning ? Icons.qr_code_2_rounded : Icons.camera_alt_outlined,
                      size: 56,
                      color: AppColors.primary,
                    ),
                    const SizedBox(height: 8),
                    Text(
                      _isScanning ? 'Scanner Ativo - Aponte para a câmara' : 'Digitalização de QR Code ativa',
                      style: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.black80),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: _codeController,
                textCapitalization: TextCapitalization.characters,
                decoration: InputDecoration(
                  labelText: 'Ou Digite o Código de Levantamento',
                  hintText: 'Ex: FJ-9281',
                  prefixIcon: const Icon(Icons.key_rounded),
                  suffixIcon: IconButton(
                    icon: const Icon(Icons.arrow_forward_rounded, color: AppColors.primary),
                    onPressed: _isValidating ? null : _handleValidate,
                  ),
                ),
                onFieldSubmitted: (_) => _handleValidate(),
              ),

              if (_errorMessage != null) ...[
                const SizedBox(height: 12),
                Text(
                  _errorMessage!,
                  style: const TextStyle(color: Colors.red, fontSize: 12, fontWeight: FontWeight.bold),
                  textAlign: TextAlign.center,
                ),
              ],

              const SizedBox(height: 20),
              SizedBox(
                width: double.infinity,
                child: FilledButton.icon(
                  icon: _isValidating
                      ? const SizedBox(width: 18, height: 18, child: CircularProgressIndicator(color: Colors.white, strokeWidth: 2))
                      : const Icon(Icons.verified_user_rounded),
                  label: Text(_isValidating ? 'A Validar...' : 'Validar & Confirmar Levantamento'),
                  onPressed: _isValidating ? null : _handleValidate,
                ),
              ),
            ],
          ],
        ),
      ),
    );
  }
}
