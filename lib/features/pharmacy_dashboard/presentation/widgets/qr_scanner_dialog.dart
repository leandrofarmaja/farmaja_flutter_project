import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:iconsax_flutter/iconsax_flutter.dart';
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

  static const Color _navy = Color(0xFF173B57);
  static const Color _background = Color(0xFFF7FBF8);
  static const Color _border = Color(0xFFE5EDE8);

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

  InputDecoration _inputDecoration() {
    return InputDecoration(
      labelText: 'Código de levantamento',
      hintText: 'Introduza o código da reserva',
      prefixIcon: const Icon(Icons.key_rounded),
      filled: true,
      fillColor: _background,
      contentPadding: const EdgeInsets.symmetric(
        horizontal: 14,
        vertical: 16,
      ),
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
    );
  }

  @override
  Widget build(BuildContext context) {
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
        constraints: const BoxConstraints(maxWidth: 450),
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(22),
          child: Column(
            mainAxisSize: MainAxisSize.min,
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
                    child: Icon(
                      Icons.qr_code_scanner_rounded,
                      color: AppColors.primary,
                      size: 25,
                    ),
                  ),
                  const SizedBox(width: 12),
                  const Expanded(
                    child: Text(
                      'Validar código de reserva',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 17,
                        fontWeight: FontWeight.w900,
                      ),
                    ),
                  ),
                  IconButton(
                    tooltip: 'Fechar',
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.close_rounded),
                    style: IconButton.styleFrom(
                      backgroundColor: _background,
                      foregroundColor: _navy,
                    ),
                  ),
                ],
              ),

              const SizedBox(height: 22),

              if (_validatedReservation != null) ...[
                _buildValidatedReservation(),
              ] else ...[
                if (_isCameraActive && !_showManualEntry)
                  _buildCameraScanner(),

                if (_isCameraUnavailable && !_showManualEntry)
                  _buildCameraUnavailable(),

                if (_isValidating) ...[
                  const SizedBox(height: 24),
                  const CircularProgressIndicator(),
                  const SizedBox(height: 14),
                  const Text(
                    'A validar o código...',
                    style: TextStyle(
                      color: _navy,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  const SizedBox(height: 12),
                ],

                if (_showManualEntry) ...[
                  _buildSectionTitle(
                    'Introdução manual',
                    Icons.keyboard_alt_outlined,
                  ),
                  const SizedBox(height: 13),
                  TextFormField(
                    controller: _codeController,
                    textCapitalization: TextCapitalization.characters,
                    enabled: !_isValidating,
                    textInputAction: TextInputAction.done,
                    decoration: _inputDecoration(),
                    onFieldSubmitted: (value) {
                      _validateCode(value);
                    },
                    onChanged: (_) {
                      if (_errorMessage != null) {
                        setState(() {
                          _errorMessage = null;
                        });
                      }
                    },
                  ),
                ],

                if (_errorMessage != null) ...[
                  const SizedBox(height: 14),
                  Container(
                    width: double.infinity,
                    padding: const EdgeInsets.all(13),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(12),
                      border: Border.all(
                        color: Colors.red.shade100,
                      ),
                    ),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.error_outline_rounded,
                          color: Colors.red.shade700,
                          size: 19,
                        ),
                        const SizedBox(width: 9),
                        Expanded(
                          child: Text(
                            _errorMessage!,
                            style: TextStyle(
                              color: Colors.red.shade800,
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                            ),
                            textAlign: TextAlign.left,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],

                const SizedBox(height: 18),

                if (!_showManualEntry && !_isValidating)
                  SizedBox(
                    width: double.infinity,
                    child: OutlinedButton.icon(
                      onPressed: _switchToManualEntry,
                      icon: const Icon(Icons.keyboard_rounded),
                      label: const Text(
                        'Introduzir código manualmente',
                      ),
                      style: OutlinedButton.styleFrom(
                        foregroundColor: AppColors.primary,
                        side: BorderSide(
                          color: AppColors.primary.withValues(alpha: 0.45),
                        ),
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
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
                      style: FilledButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 15),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _restartCamera,
                    icon: const Icon(Icons.camera_alt_rounded),
                    label: const Text('Tentar novamente com a câmara'),
                    style: TextButton.styleFrom(
                      foregroundColor: _navy,
                    ),
                  ),
                ],
              ],
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildCameraScanner() {
    return Column(
      children: [
        _buildSectionTitle(
          'Leitura do código QR',
          Icons.qr_code_2_rounded,
        ),
        const SizedBox(height: 13),
        Container(
          height: 230,
          width: double.infinity,
          clipBehavior: Clip.antiAlias,
          decoration: BoxDecoration(
            color: Colors.black,
            borderRadius: BorderRadius.circular(17),
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
        const SizedBox(height: 13),
        Container(
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: _background,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Row(
            children: [
              Icon(
                Icons.info_outline_rounded,
                color: AppColors.primary,
                size: 20,
              ),
              const SizedBox(width: 10),
              const Expanded(
                child: Text(
                  'Aponte a câmara para o QR Code apresentado pelo cliente.',
                  style: TextStyle(
                    color: _navy,
                    fontSize: 12,
                    height: 1.4,
                  ),
                ),
              ),
            ],
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
        border: Border.all(
          color: Colors.orange.shade100,
        ),
      ),
      child: Column(
        children: [
          Icon(
            Icons.camera_alt_outlined,
            size: 42,
            color: Colors.orange.shade700,
          ),
          const SizedBox(height: 10),
          const Text(
            'Câmara indisponível.',
            textAlign: TextAlign.center,
            style: TextStyle(
              color: _navy,
              fontWeight: FontWeight.w800,
            ),
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
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: const Color(0xFFF1F8FF),
        borderRadius: BorderRadius.circular(18),
        border: Border.all(
          color: Colors.blue.shade100,
        ),
      ),
      child: Column(
        children: [
          Container(
            width: 64,
            height: 64,
            decoration: BoxDecoration(
              color: Colors.blue.shade100,
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.verified_rounded,
              color: Colors.blue.shade800,
              size: 38,
            ),
          ),
          const SizedBox(height: 13),
          Text(
            'Código lido com sucesso',
            style: TextStyle(
              fontSize: 17,
              fontWeight: FontWeight.w900,
              color: Colors.blue.shade900,
            ),
            textAlign: TextAlign.center,
          ),
          const SizedBox(height: 18),

          _buildReservationDetail(
            'Medicamento',
            reservation.medicineName,
            LucideIcons.pill,
          ),
          const SizedBox(height: 10),
          _buildReservationDetail(
            'Código',
            reservation.pickupCode,
            Icons.qr_code_rounded,
          ),
          const SizedBox(height: 10),
          _buildReservationDetail(
            'Valor',
            '${reservation.totalPriceKz.toInt()} Kz',
            Icons.payments_outlined,
          ),

          const SizedBox(height: 14),

          Chip(
            avatar: const Icon(
              Iconsax.clock,
              color: Colors.white,
              size: 18,
            ),
            label: Text('Estado: ${reservation.status}'),
            backgroundColor: Colors.orange.shade700,
            labelStyle: const TextStyle(
              color: Colors.white,
              fontWeight: FontWeight.bold,
              fontSize: 11,
            ),
          ),

          const SizedBox(height: 14),

          Container(
            padding: const EdgeInsets.all(13),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: _border),
            ),
            child: const Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Icon(
                  Icons.warning_amber_rounded,
                  color: Colors.orange,
                  size: 21,
                ),
                SizedBox(width: 9),
                Expanded(
                  child: Text(
                    'A validação do código não confirma o pagamento nem o levantamento. '
                    'Verifique presencialmente a receita médica, quando exigida, '
                    'e só confirme a entrega depois de entregar o medicamento.',
                    style: TextStyle(
                      fontSize: 11,
                      height: 1.5,
                      color: _navy,
                    ),
                  ),
                ),
              ],
            ),
          ),

          const SizedBox(height: 18),

          SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              onPressed: _resetForAnotherCode,
              icon: const Icon(Icons.qr_code_scanner_rounded),
              label: const Text('Validar outro código'),
              style: FilledButton.styleFrom(
                backgroundColor: AppColors.primary,
                foregroundColor: Colors.white,
                padding: const EdgeInsets.symmetric(vertical: 15),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildReservationDetail(
    String label,
    String value,
    IconData icon,
  ) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: _border),
      ),
      child: Row(
        children: [
          Icon(
            icon,
            color: AppColors.primary,
            size: 19,
          ),
          const SizedBox(width: 10),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  label,
                  style: TextStyle(
                    color: Colors.grey.shade600,
                    fontSize: 11,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  value,
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
    );
  }
}
