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
  bool _isCameraUnavailable = false;

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

    String? scannedCode;

    for (final barcode in capture.barcodes) {
      final value = barcode.rawValue?.trim();

      if (value != null && value.isNotEmpty) {
        scannedCode = value;
        break;
      }
    }

    if (scannedCode == null) return;

    await _validateCode(scannedCode);
  }

  Future<void> _validateCode(String rawCode) async {
    final code = rawCode.trim().toUpperCase();

    if (code.isEmpty || _isValidating) {
      if (code.isEmpty && mounted) {
        setState(() {
          _errorMessage = 'Introduza um código de reserva válido.';
        });
      }
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
      _isCameraUnavailable = false;
    });

    try {
      await _scannerController.start();

      if (!mounted) return;
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _isCameraActive = false;
        _showManualEntry = true;
        _isCameraUnavailable = true;
        _errorMessage =
            'Não foi possível iniciar a câmara. Introduza o código manualmente.';
      });
    }
  }

  Future<void> _resetForAnotherCode() async {
    if (!mounted) return;

    setState(() {
      _validatedReservation = null;
      _errorMessage = null;
      _codeController.clear();
      _showManualEntry = false;
      _isCameraUnavailable = false;
    });

    await _restartCamera();
  }

  void _switchToManualEntry() {
    if (_isValidating) return;

    if (_isCameraActive) {
      _scannerController.stop();
    }

    if (!mounted) return;

    setState(() {
      _isCameraActive = false;
      _showManualEntry = true;
      _errorMessage = null;
    });
  }

  void _handleCameraError() {
    if (!mounted) return;

    setState(() {
      _isCameraActive = false;
      _showManualEntry = true;
      _isCameraUnavailable = true;
      _errorMessage =
          'Não foi possível abrir a câmara. Introduza o código manualmente.';
    });
  }

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

                  if (_isCameraUnavailable && !_showManualEntry)
                    _buildCameraUnavailable(),

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
                        labelText: 'Código de levantamento',
                        hintText: 'Introduza o código da reserva',
                        prefixIcon: const Icon(Icons.key_rounded),
                        suffixIcon: IconButton(
                          icon: const Icon(
                            Icons.arrow_forward_rounded,
                            color: AppColors.primary,
                          ),
                          onPressed: _isValidating
                              ? null
                              : () => _validateCode(_codeController.text),
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
                      onPressed: _switchToManualEntry,
                      icon: const Icon(Icons.keyboard_rounded),
                      label: const Text('Introduzir código manualmente'),
                    ),

                  if (_showManualEntry && !_isValidating)
                    TextButton.icon(
                      onPressed: _restartCamera,
                      icon: const Icon(Icons.camera_alt_rounded),
                      label: const Text('Tentar novamente com a câmara'),
                    ),

                  if (_showManualEntry && !_isValidating)
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
              WidgetsBinding.instance.addPostFrameCallback((_) {
                _handleCameraError();
              });

              return const Center(
                child: Padding(
                  padding: EdgeInsets.all(16),
                  child: Text(
                    'Não foi possível abrir a câmara.\n'
                    'A activar a introdução manual...',
                    textAlign: TextAlign.center,
                    style: TextStyle(color: Colors.white),
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

  Widget _buildCameraUnavailable() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        children: [
          const Icon(
            Icons.camera_alt_outlined,
            size: 42,
            color: Colors.orange,
          ),
          const SizedBox(height: 8),
          const Text(
            'Câmara indisponível.',
            textAlign: TextAlign.center,
          ),
          TextButton(
            onPressed: _switchToManualEntry,
            child: const Text('Introduzir código manualmente'),
          ),
        ],
      ),
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
          Text('Código: ${reservation.pickupCode}'),
          Text('Valor: ${reservation.totalPriceKz.toInt()} Kz'),
          const SizedBox(height: 12),
          Chip(
            avatar: const Icon(
              Icons.schedule_rounded,
              color: Colors.white,
              size: 18,
            ),
            label: Text('Estado: ${reservation.status}'),
            backgroundColor: Colors.orange,
            labelStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'A validação do código não confirma o pagamento nem o levantamento. '
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
              onPressed: _resetForAnotherCode,
              child: const Text('Validar outro código'),
            ),
          ),
        ],
      ),
    );
  }
}
