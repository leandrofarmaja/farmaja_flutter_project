
import 'dart:io';

import 'package:flutter/material.dart';
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
      borderRadius: BorderRadius.circular(14),
      child: SizedBox(
        width: double.infinity,
        height: 190,
        child: image,
      ),
    );
  }

  Widget _buildImagePlaceholder() {
    return Container(
      width: double.infinity,
      height: 190,
      color: Colors.grey.shade100,
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            Icons.add_photo_alternate_outlined,
            size: 46,
            color: Colors.grey.shade500,
          ),
          const SizedBox(height: 8),
          Text(
            'Sem fotografia seleccionada',
            style: TextStyle(
              color: Colors.grey.shade600,
              fontSize: 13,
            ),
          ),
        ],
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
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(20),
      ),
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 500),
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: SingleChildScrollView(
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: Text(
                          isEditing
                              ? 'Editar medicamento'
                              : 'Novo medicamento',
                          style: const TextStyle(
                            fontSize: 20,
                            fontWeight: FontWeight.w900,
                          ),
                        ),
                      ),
                      IconButton(
                        tooltip: 'Fechar',
                        icon: const Icon(Icons.close_rounded),
                        onPressed: _isSaving
                            ? null
                            : () => Navigator.of(context).pop(),
                      ),
                    ],
                  ),
                  const Divider(),
                  const SizedBox(height: 16),

                  const Text(
                    'Fotografia do medicamento',
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  Stack(
                    children: [
                      _buildImagePreview(),
                      if (_selectedImage != null)
                        Positioned(
                          top: 8,
                          right: 8,
                          child: IconButton.filled(
                            tooltip: 'Remover fotografia seleccionada',
                            onPressed: _isSaving || _isPickingImage
                                ? null
                                : _removeSelectedImage,
                            icon: const Icon(Icons.close_rounded),
                          ),
                        ),
                    ],
                  ),

                  const SizedBox(height: 10),

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
                    ),
                  ),

                  const SizedBox(height: 20),

                  TextFormField(
                    controller: _nameController,
                    enabled: !_isSaving,
                    textCapitalization:
                        TextCapitalization.sentences,
                    textInputAction: TextInputAction.next,
                    maxLength: 150,
                    decoration: const InputDecoration(
                      labelText: 'Nome do medicamento *',
                      prefixIcon: Icon(Icons.medication_rounded),
                      counterText: '',
                    ),
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
                          decoration: const InputDecoration(
                            labelText: 'Preço (Kz) *',
                            prefixIcon: Icon(Icons.payments_rounded),
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
                          decoration: const InputDecoration(
                            labelText: 'Quantidade em stock *',
                            prefixIcon:
                                Icon(Icons.inventory_2_rounded),
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

                  const SizedBox(height: 12),

                  SwitchListTile(
                    contentPadding: EdgeInsets.zero,
                    title: const Text(
                      'Exige receita médica',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    subtitle: const Text(
                      'Indica se é necessária receita para reservar.',
                      style: TextStyle(fontSize: 12),
                    ),
                    value: _requiresPrescription,
                    activeColor: AppColors.primary,
                    onChanged: _isSaving
                        ? null
                        : (value) {
                            setState(() {
                              _requiresPrescription = value;
                            });
                          },
                  ),

                  const SizedBox(height: 20),

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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
