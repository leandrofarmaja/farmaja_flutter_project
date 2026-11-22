import 'dart:io';

import 'package:flutter/material.dart';
import 'package:flutter_lucide/flutter_lucide.dart';
import 'package:image_picker/image_picker.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../medicines/domain/medicine_model.dart';

class AddEditMedicineDialog extends StatefulWidget {
  final MedicineModel? medicine;

  final Future<void> Function(
    MedicineModel medicine,
    XFile? image,
  ) onSave;

  const AddEditMedicineDialog({
    super.key,
    this.medicine,
    required this.onSave,
  });

  @override
  State<AddEditMedicineDialog> createState() =>
      _AddEditMedicineDialogState();
}

class _AddEditMedicineDialogState
    extends State<AddEditMedicineDialog> {
  final _formKey = GlobalKey<FormState>();
  final ImagePicker _imagePicker = ImagePicker();

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;

  XFile? _selectedImage;

  bool _requiresPrescription = false;
  bool _isSaving = false;
  bool _isPickingImage = false;

  static const Color _navy = Color(0xFF173B57);
  static const Color _background = Color(0xFFF7FBF8);
  static const Color _border = Color(0xFFE5EDE8);

  @override
  void initState() {
    super.initState();

    final medicine = widget.medicine;

    _nameController = TextEditingController(
      text: medicine?.name ?? '',
    );

    _priceController = TextEditingController(
      text: medicine == null
          ? ''
          : medicine.priceKz.toStringAsFixed(0),
    );

    _stockController = TextEditingController(
      text: medicine == null
          ? '0'
          : medicine.stockQuantity.toString(),
    );

    _requiresPrescription =
        medicine?.requiresPrescription ?? false;
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    super.dispose();
  }

  String? _validateName(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Insira o nome do medicamento.';
    }

    return null;
  }

  String? _validatePrice(String? value) {
    final normalized = (value ?? '').trim().replaceAll(',', '.');
    final price = double.tryParse(normalized);

    if (normalized.isEmpty ||
        price == null ||
        !price.isFinite ||
        price < 0) {
      return 'Insira um preço válido, igual ou superior a zero.';
    }

    return null;
  }

  String? _validateStock(String? value) {
    final stock = int.tryParse((value ?? '').trim());

    if (stock == null || stock < 0) {
      return 'Insira um número inteiro igual ou superior a zero.';
    }

    return null;
  }

  Future<void> _pickImage() async {
    if (_isSaving || _isPickingImage) return;

    setState(() {
      _isPickingImage = true;
    });

    try {
      final image = await _imagePicker.pickImage(
        source: ImageSource.gallery,
        imageQuality: 85,
        maxWidth: 1600,
        maxHeight: 1600,
      );

      if (!mounted) return;

      if (image != null) {
        setState(() {
          _selectedImage = image;
        });
      }
    } catch (error, stackTrace) {
      debugPrint('Erro ao seleccionar fotografia: $error');
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Não foi possível seleccionar a fotografia.',
              ),
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isPickingImage = false;
        });
      }
    }
  }

  void _removeSelectedImage() {
    if (_isSaving || _isPickingImage) return;

    setState(() {
      _selectedImage = null;
    });
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 190,
      color: _background,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 58,
            height: 58,
            decoration: BoxDecoration(
              color: AppColors.primary.withValues(alpha: 0.09),
              shape: BoxShape.circle,
            ),
            child: Icon(
              Icons.add_photo_alternate_outlined,
              size: 29,
              color: AppColors.primary,
            ),
          ),
          const SizedBox(height: 12),
          const Text(
            'Sem fotografia seleccionada',
            style: TextStyle(
              color: _navy,
              fontSize: 13,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            'Adicione uma imagem do medicamento',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 12,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildImagePreview() {
    final existingImageUrl = widget.medicine?.imageUrl;

    Widget image;

    if (_selectedImage != null) {
      image = Image.file(
        File(_selectedImage!.path),
        width: double.infinity,
        height: 190,
        fit: BoxFit.cover,
      );
    } else if (existingImageUrl != null &&
        existingImageUrl.trim().isNotEmpty) {
      image = Image.network(
        existingImageUrl,
        width: double.infinity,
        height: 190,
        fit: BoxFit.cover,
        errorBuilder: (context, error, stackTrace) {
          return _buildImagePlaceholder();
        },
      );
    } else {
      image = _buildImagePlaceholder();
    }

    return ClipRRect(
      borderRadius: BorderRadius.circular(16),
      child: SizedBox(
        width: double.infinity,
        height: 190,
        child: image,
      ),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Icon(
          icon,
          size: 19,
          color: AppColors.primary,
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

  InputDecoration _inputDecoration({
    required String label,
    required IconData icon,
  }) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon, size: 20),
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
      errorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(color: Colors.redAccent),
      ),
      focusedErrorBorder: OutlineInputBorder(
        borderRadius: BorderRadius.circular(13),
        borderSide: const BorderSide(
          color: Colors.redAccent,
          width: 1.5,
        ),
      ),
    );
  }

  Future<void> _submit() async {
    if (_isSaving || _isPickingImage) return;

    FocusScope.of(context).unfocus();

    final form = _formKey.currentState;
    if (form == null || !form.validate()) return;

    final price = double.tryParse(
      _priceController.text.trim().replaceAll(',', '.'),
    );

    final stock = int.tryParse(_stockController.text.trim());

    if (price == null ||
        !price.isFinite ||
        price < 0 ||
        stock == null ||
        stock < 0) {
      return;
    }

    final existingMedicine = widget.medicine;

    final medicine = MedicineModel(
      id: existingMedicine?.id ?? '',
      pharmacyId: existingMedicine?.pharmacyId ?? '',
      name: _nameController.text.trim(),
      activeIngredient:
          existingMedicine?.activeIngredient ?? '',
      category: existingMedicine?.category ?? '',
      dosage: existingMedicine?.dosage ?? '',
      dosageInstructions:
          existingMedicine?.dosageInstructions ?? '',
      priceKz: price,
      pharmacyName: existingMedicine?.pharmacyName ?? '',
      province: existingMedicine?.province ?? '',
      district: existingMedicine?.district ?? '',
      inStock: stock > 0,
      stockQuantity: stock,
      requiresPrescription: _requiresPrescription,
      isGeneric: existingMedicine?.isGeneric ?? false,
      genericAlternative:
          existingMedicine?.genericAlternative,
      description: existingMedicine?.description ?? '',
      pharmacyLatitude:
          existingMedicine?.pharmacyLatitude ?? 0.0,
      pharmacyLongitude:
          existingMedicine?.pharmacyLongitude ?? 0.0,
      imageUrl: existingMedicine?.imageUrl,
    );

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(medicine, _selectedImage);

      if (!mounted) return;

      Navigator.of(context).pop();
    } catch (error, stackTrace) {
      debugPrint(
        'Erro ao guardar medicamento no formulário: $error',
      );
      debugPrintStack(stackTrace: stackTrace);

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..hideCurrentSnackBar()
          ..showSnackBar(
            const SnackBar(
              content: Text(
                'Ocorreu um erro ao guardar. '
                'Verifica a mensagem apresentada no painel.',
              ),
            ),
          );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isSaving = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.medicine != null;

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
          padding: const EdgeInsets.fromLTRB(22, 22, 22, 24),
          child: Form(
            key: _formKey,
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
                      child: Icon(
                        isEditing
                            ? Icons.edit_note_rounded
                            : LucideIcons.pill,
                        color: AppColors.primary,
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            isEditing
                                ? 'Editar medicamento'
                                : 'Novo medicamento',
                            style: const TextStyle(
                              color: _navy,
                              fontSize: 19,
                              fontWeight: FontWeight.w900,
                            ),
                          ),
                          const SizedBox(height: 3),
                          Text(
                            isEditing
                                ? 'Actualize os dados do produto.'
                                : 'Preencha os dados para adicionar ao stock.',
                            style: TextStyle(
                              color: Colors.grey.shade600,
                              fontSize: 11,
                            ),
                          ),
                        ],
                      ),
                    ),
                    IconButton(
                      tooltip: 'Fechar',
                      onPressed: _isSaving
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

                const SizedBox(height: 24),

                _buildSectionTitle(
                  'Fotografia do medicamento',
                  Icons.photo_camera_outlined,
                ),
                const SizedBox(height: 12),

                Stack(
                  children: [
                    _buildImagePreview(),
                    if (_selectedImage != null)
                      Positioned(
                        top: 9,
                        right: 9,
                        child: IconButton.filled(
                          tooltip: 'Remover fotografia seleccionada',
                          onPressed: _isSaving || _isPickingImage
                              ? null
                              : _removeSelectedImage,
                          icon: const Icon(Icons.close_rounded),
                          style: IconButton.styleFrom(
                            backgroundColor: Colors.white,
                            foregroundColor: Colors.redAccent,
                          ),
                        ),
                      ),
                  ],
                ),

                const SizedBox(height: 11),

                SizedBox(
                  width: double.infinity,
                  child: OutlinedButton.icon(
                    onPressed: _isSaving || _isPickingImage
                        ? null
                        : _pickImage,
                    icon: _isPickingImage
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(Icons.photo_library_outlined),
                    label: Text(
                      _isPickingImage
                          ? 'A abrir galeria...'
                          : 'Seleccionar fotografia',
                    ),
                    style: OutlinedButton.styleFrom(
                      foregroundColor: AppColors.primary,
                      side: BorderSide(
                        color: AppColors.primary.withValues(alpha: 0.45),
                      ),
                      padding: const EdgeInsets.symmetric(vertical: 13),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 25),

                _buildSectionTitle(
                  'Informações do medicamento',
                  Icons.description_outlined,
                ),
                const SizedBox(height: 14),

                TextFormField(
                  controller: _nameController,
                  enabled: !_isSaving,
                  textCapitalization: TextCapitalization.sentences,
                  textInputAction: TextInputAction.next,
                  maxLength: 150,
                  decoration: _inputDecoration(
                    label: 'Nome do medicamento *',
                    icon: LucideIcons.pill,
                  ).copyWith(counterText: ''),
                  validator: _validateName,
                ),

                const SizedBox(height: 16),

                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        enabled: !_isSaving,
                        keyboardType:
                            const TextInputType.numberWithOptions(
                          decimal: true,
                        ),
                        textInputAction: TextInputAction.next,
                        decoration: _inputDecoration(
                          label: 'Preço (Kz) *',
                          icon: Icons.payments_rounded,
                        ),
                        validator: _validatePrice,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        enabled: !_isSaving,
                        keyboardType: TextInputType.number,
                        textInputAction: TextInputAction.done,
                        decoration: _inputDecoration(
                          label: 'Quantidade em stock *',
                          icon: LucideIcons.pill,
                        ),
                        validator: _validateStock,
                        onFieldSubmitted: (_) {
                          if (!_isSaving) {
                            _submit();
                          }
                        },
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 18),

                Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 13,
                    vertical: 9,
                  ),
                  decoration: BoxDecoration(
                    color: _background,
                    borderRadius: BorderRadius.circular(14),
                    border: Border.all(color: _border),
                  ),
                  child: SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Exige receita médica',
                      style: TextStyle(
                        color: _navy,
                        fontSize: 13,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
                    subtitle: const Text(
                      'Indica se é necessária receita para reservar.',
                      style: TextStyle(fontSize: 11),
                    ),
                    value: _requiresPrescription,
                    activeThumbColor: AppColors.primary,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _requiresPrescription = value;
                            });
                          },
                  ),
                ),

                const SizedBox(height: 24),

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: _isSaving
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              color: Colors.white,
                            ),
                          )
                        : const Icon(Icons.save_rounded),
                    label: Text(
                      _isSaving
                          ? 'A guardar...'
                          : isEditing
                              ? 'Guardar alterações'
                              : 'Adicionar ao stock',
                    ),
                    onPressed: _isSaving || _isPickingImage
                        ? null
                        : _submit,
                    style: FilledButton.styleFrom(
                      backgroundColor: AppColors.primary,
                      foregroundColor: Colors.white,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      elevation: 0,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(13),
                      ),
                      textStyle: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w800,
                      ),
                    ),
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
