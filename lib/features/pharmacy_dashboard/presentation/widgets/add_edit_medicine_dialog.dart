import 'package:flutter/material.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../medicines/domain/medicine_model.dart';

class AddEditMedicineDialog extends StatefulWidget {
  final MedicineModel? medicine;
  final Future<void> Function(MedicineModel) onSave;

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

  late final TextEditingController _nameController;
  late final TextEditingController _priceController;
  late final TextEditingController _stockController;

  bool _requiresPrescription = false;
  bool _isSaving = false;

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

  Future<void> _submit() async {
    if (_isSaving) return;

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
    );

    setState(() {
      _isSaving = true;
    });

    try {
      await widget.onSave(medicine);

      // O callback do ecrã pai decide se fecha o formulário.
      // Se a gravação falhar, o formulário permanece aberto.
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
                      onPressed: _isSaving ? null : _submit,
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
