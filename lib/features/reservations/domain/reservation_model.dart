import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';

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

  late final MobileScannerController _scannerController;

  bool _isValidating = false;
  bool _isCameraActive = true;
  bool _showManualEntry = false;
  bool _isCameraError = false;

  ReservationModel? _validatedReservation;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();

    _scannerController = MobileScannerController(
      detectionSpeed: DetectionSpeed.noDuplicates,
      facing: CameraFacing.back,
      torchEnabled: false,
    );
  }

  @override
  void dispose() {
    _codeController.dispose();
    _scannerController.dispose();
    super.dispose();
  }

  Future<void> _handleScan(BarcodeCapture capture) async {
    if (_isValidating || _validatedReservation != null) return;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();

      if (value != null && value.isNotEmpty) {
        await _validateCode(value);
        return;
      }
    }
  }

  Future<void> _validateCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();

    if (code.isEmpty || _isValidating) {
      setState(() {
        _errorMessage = 'Introduza um código de reserva.';
      });
      return;
    }

    setState(() {
      _isValidating = true;
      _errorMessage = null;
      _validatedReservation = null;
      _isCameraActive = false;
    });

    try {
      await _scannerController.stop();

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
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _errorMessage =
            'Não foi possível validar o código. Verifique a ligação e tente novamente.';
        _isValidating = false;
      });
    }
  }

  Future<void> _restartCamera() async {
    if (_isValidating || !mounted) return;

    setState(() {
      _errorMessage = null;
      _isCameraActive = true;
      _showManualEntry = false;
      _isCameraError = false;
    });

    try {
      await _scannerController.start();
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCameraActive = false;
        _showManualEntry = true;
        _isCameraError = true;
        _errorMessage =
            'Não foi possível iniciar a câmara. Introduza o código manualmente.';
      });
    }
  }

  Future<void> _showManualInput() async {
    if (_isCameraActive) {
      try {
        await _scannerController.stop();
      } catch (_) {
        // A câmara pode já estar parada.
      }
    }

    if (!mounted) return;

    setState(() {
      _isCameraActive = false;
      _showManualEntry = true;
      _errorMessage = null;
    });
  }

  Future<void> _resetForAnotherCode() async {
    setState(() {
      _validatedReservation = null;
      _errorMessage = null;
      _codeController.clear();
      _showManualEntry = false;
    });

    await _restartCamera();
  }

  bool get _clientConfirmedPayment =>
      _validatedReservation?.clienteConfirmouPagamentoEm != null;

  bool get _pharmacyConfirmedPayment =>
      _validatedReservation?.farmaciaConfirmouPagamentoEm != null;

  bool get _paymentConfirmedByBoth =>
      _clientConfirmedPayment && _pharmacyConfirmedPayment;

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(24),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                Row(
                  children: [
                    const Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.primary,
                      size: 28,
                    ),
                    const SizedBox(width: 8),
                    const Expanded(
                      child: Text(
                        'Validar código de reserva',
                        style: TextStyle(
                          fontSize: 17,
                          fontWeight: FontWeight.w900,
                        ),
                      ),
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
                  _buildValidatedReservation(),
                ] else ...[
                  if (_isCameraActive && !_showManualEntry)
                    _buildCameraScanner(),

                  if (_isValidating) ...[
                    const Padding(
                      padding: EdgeInsets.all(24),
                      child: CircularProgressIndicator(),
                    ),
                    const Text('A validar o código...'),
                  ],

                  if (_showManualEntry) ...[
                    const SizedBox(height: 12),
                    TextFormField(
                      controller: _codeController,
                      textCapitalization: TextCapitalization.characters,
                      enabled: !_isValidating,
                      decoration: InputDecoration(
                        labelText: 'Código de reserva',
                        hintText: 'Introduza o código da reserva',
                        prefixIcon: const Icon(Icons.key_rounded),
                        border: OutlineInputBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      onFieldSubmitted: (value) {
                        _validateCode(value);
                      },
                    ),
                  ],

                  if (_errorMessage != null) ...[
                    const SizedBox(height: 12),
                    Text(
                      _errorMessage!,
                      textAlign: TextAlign.center,
                      style: const TextStyle(
                        color: Colors.red,
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                  ],

                  const SizedBox(height: 16),

                  if (!_showManualEntry && !_isValidating)
                    OutlinedButton.icon(
                      onPressed: _showManualInput,
                      icon: const Icon(Icons.keyboard_rounded),
                      label: const Text('Introduzir código manualmente'),
                    ),

                  if (_showManualEntry && !_isValidating) ...[
                    SizedBox(
                      width: double.infinity,
                      child: FilledButton.icon(
                        onPressed: () {
                          _validateCode(_codeController.text);
                        },
                        icon: const Icon(Icons.verified_user_rounded),
                        label: const Text('Validar código'),
                      ),
                    ),
                    TextButton.icon(
                      onPressed: _restartCamera,
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Tentar novamente com a câmara'),
                    ),
                  ],
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildCameraScanner() {
    return Column(
      children: [
        Container(
          height: 230,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(16),
            border: Border.all(
              color: AppColors.primary,
              width: 2,
            ),
          ),
          child: MobileScanner(
            controller: _scannerController,
            onDetect: _handleScan,
            errorBuilder: (context, error) {
              return Center(
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.camera_alt_outlined,
                        color: Colors.white,
                        size: 38,
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Não foi possível abrir a câmara.',
                        textAlign: TextAlign.center,
                        style: TextStyle(color: Colors.white),
                      ),
                      TextButton(
                        onPressed: _showManualInput,
                        child: const Text(
                          'Introduzir código manualmente',
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
        const SizedBox(height: 12),
        const Text(
          'Aponte a câmara para o QR Code apresentado pelo cliente.',
          textAlign: TextAlign.center,
          style: TextStyle(
            fontSize: 13,
            color: Colors.black87,
          ),
        ),
      ],
    );
  }

  Widget _buildValidatedReservation() {
    final reservation = _validatedReservation!;

    return Container(
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
            'Medicamento: ${reservation.medicineName}',
            textAlign: TextAlign.center,
            style: const TextStyle(
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 4),
          Text('Farmácia: ${reservation.pharmacyName}'),
          Text('Código: ${reservation.pickupCode}'),
          Text('Valor: ${reservation.totalPriceKz.toStringAsFixed(2)} Kz'),
          const SizedBox(height: 12),

          _buildStatusChip(reservation.status),

          const SizedBox(height: 12),
          _buildPaymentStatus(),

          const SizedBox(height: 16),
          const Text(
            'A validação do código não confirma o pagamento nem o levantamento. '
            'Verifique presencialmente a receita médica, quando exigida. '
            'Confirme o levantamento apenas depois de entregar fisicamente '
            'o medicamento ao cliente.',
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
              onPressed: _resetForAnotherCode,
              child: const Text('Validar outro código'),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStatusChip(String status) {
    return Chip(
      avatar: const Icon(
        Icons.info_outline_rounded,
        color: Colors.white,
        size: 18,
      ),
      label: Text(
        'Estado: $status',
        textAlign: TextAlign.center,
      ),
      backgroundColor: Colors.orange,
      labelStyle: const TextStyle(
        color: Colors.white,
        fontWeight: FontWeight.bold,
        fontSize: 11,
      ),
    );
  }

  Widget _buildPaymentStatus() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Confirmação do pagamento',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildPaymentLine(
            'Cliente',
            _clientConfirmedPayment,
          ),
          const SizedBox(height: 6),
          _buildPaymentLine(
            'Farmácia',
            _pharmacyConfirmedPayment,
          ),
          const Divider(height: 18),
          Row(
            children: [
              Icon(
                _paymentConfirmedByBoth
                    ? Icons.check_circle_rounded
                    : Icons.pending_rounded,
                color: _paymentConfirmedByBoth
                    ? Colors.green
                    : Colors.orange,
                size: 19,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  _paymentConfirmedByBoth
                      ? 'Pagamento confirmado pelas duas partes'
                      : 'Pagamento ainda não confirmado pelas duas partes',
                  style: const TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildPaymentLine(String label, bool confirmed) {
    return Row(
      children: [
        Icon(
          confirmed
              ? Icons.check_circle_rounded
              : Icons.radio_button_unchecked_rounded,
          color: confirmed ? Colors.green : Colors.orange,
          size: 18,
        ),
        const SizedBox(width: 8),
        Text(
          '$label: ${confirmed ? 'Confirmado' : 'Pendente'}',
          style: const TextStyle(fontSize: 12),
        ),
      ],
    );
  }
}
