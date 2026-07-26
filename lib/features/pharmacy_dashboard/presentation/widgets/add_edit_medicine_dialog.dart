import 'package:flutter/material.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/constants/app_constants.dart';
import '../../../medicines/domain/medicine_model.dart';

class AddEditMedicineDialog extends StatefulWidget {
  final MedicineModel? medicine;
  final Function(MedicineModel) onSave;

  const AddEditMedicineDialog({
    super.key,
    this.medicine,
    required this.onSave,
  });

  @override
  State<AddEditMedicineDialog> createState() => _AddEditMedicineDialogState();
}

class _AddEditMedicineDialogState extends State<AddEditMedicineDialog> {
  final _formKey = GlobalKey<FormState>();

  late TextEditingController _nameController;
  late TextEditingController _activeIngredientController;
  late TextEditingController _categoryController;
  late TextEditingController _dosageController;
  late TextEditingController _priceController;
  late TextEditingController _stockController;
  late TextEditingController _descriptionController;

  bool _requiresPrescription = false;
  bool _isGeneric = false;
  String _selectedProvince = 'Luanda';
  String _selectedDistrict = 'Talatona';

  @override
  void initState() {
    super.initState();
    final med = widget.medicine;
    _nameController = TextEditingController(text: med?.name ?? '');
    _activeIngredientController = TextEditingController(text: med?.activeIngredient ?? '');
    _categoryController = TextEditingController(text: med?.category ?? 'Analgésicos');
    _dosageController = TextEditingController(text: med?.dosage ?? 'Caixa de 20 Comprimidos');
    _priceController = TextEditingController(text: med?.priceKz.toInt().toString() ?? '1500');
    _stockController = TextEditingController(text: med?.stockQuantity.toString() ?? '20');
    _descriptionController = TextEditingController(text: med?.description ?? '');

    _requiresPrescription = med?.requiresPrescription ?? false;
    _isGeneric = med?.isGeneric ?? false;
    _selectedProvince = med?.province ?? 'Luanda';
    _selectedDistrict = med?.district ?? 'Talatona';
  }

  @override
  void dispose() {
    _nameController.dispose();
    _activeIngredientController.dispose();
    _categoryController.dispose();
    _dosageController.dispose();
    _priceController.dispose();
    _stockController.dispose();
    _descriptionController.dispose();
    super.dispose();
  }

  void _submit() {
    if (_formKey.currentState!.validate()) {
      final stock = int.tryParse(_stockController.text.trim()) ?? 0;
      final price = double.tryParse(_priceController.text.trim()) ?? 0.0;

      final model = MedicineModel(
        id: widget.medicine?.id ?? 'med-${DateTime.now().millisecondsSinceEpoch}',
        name: _nameController.text.trim(),
        activeIngredient: _activeIngredientController.text.trim(),
        category: _categoryController.text.trim(),
        dosage: _dosageController.text.trim(),
        priceKz: price,
        pharmacyName: widget.medicine?.pharmacyName ?? 'Farmácia Mecofarma Talatona',
        province: _selectedProvince,
        district: _selectedDistrict,
        inStock: stock > 0,
        stockQuantity: stock,
        requiresPrescription: _requiresPrescription,
        isGeneric: _isGeneric,
        description: _descriptionController.text.trim().isEmpty
            ? 'Medicamento disponibilizado pela farmácia com garantia de autenticidade.'
            : _descriptionController.text.trim(),
      );

      widget.onSave(model);
      Navigator.pop(context);
    }
  }

  @override
  Widget build(BuildContext context) {
    final isEditing = widget.medicine != null;

    return Dialog(
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      child: Container(
        padding: const EdgeInsets.all(24),
        maxWidth: 500,
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
                    Text(
                      isEditing ? 'Editar Medicamento' : 'Novo Medicamento',
                      style: const TextStyle(fontSize: 20, fontWeight: FontWeight.w900),
                    ),
                    IconButton(
                      icon: const Icon(Icons.close_rounded),
                      onPressed: () => Navigator.pop(context),
                    ),
                  ],
                ),
                const Divider(),
                const SizedBox(height: 12),

                // Name
                TextFormField(
                  controller: _nameController,
                  decoration: const InputDecoration(
                    labelText: 'Nome do Medicamento *',
                    prefixIcon: Icon(Icons.medication_rounded),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Insira o nome' : null,
                ),
                const SizedBox(height: 12),

                // Active Ingredient
                TextFormField(
                  controller: _activeIngredientController,
                  decoration: const InputDecoration(
                    labelText: 'Princípio Ativo *',
                    prefixIcon: Icon(Icons.science_rounded),
                  ),
                  validator: (v) => v == null || v.isEmpty ? 'Insira o princípio ativo' : null,
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _priceController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Preço (Kz) *',
                          prefixIcon: Icon(Icons.payments_rounded),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Insira o preço' : null,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _stockController,
                        keyboardType: TextInputType.number,
                        decoration: const InputDecoration(
                          labelText: 'Quantidade em Stock *',
                          prefixIcon: Icon(Icons.inventory_2_rounded),
                        ),
                        validator: (v) => v == null || v.isEmpty ? 'Insira o stock' : null,
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                Row(
                  children: [
                    Expanded(
                      child: TextFormField(
                        controller: _categoryController,
                        decoration: const InputDecoration(
                          labelText: 'Categoria',
                          prefixIcon: Icon(Icons.category_rounded),
                        ),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: TextFormField(
                        controller: _dosageController,
                        decoration: const InputDecoration(
                          labelText: 'Dosagem / Apresentação',
                          prefixIcon: Icon(Icons.inventory_rounded),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 12),

                // Switches for Prescription & Generic
                SwitchListTile(
                  title: const Text('Exige Receita Médica', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('O cliente deverá carregar a receita para reservar.', style: TextStyle(fontSize: 11)),
                  value: _requiresPrescription,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _requiresPrescription = v),
                ),
                SwitchListTile(
                  title: const Text('Medicamento Genérico', style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold)),
                  subtitle: const Text('Marque se for uma alternativa genérica.', style: TextStyle(fontSize: 11)),
                  value: _isGeneric,
                  activeColor: AppColors.primary,
                  onChanged: (v) => setState(() => _isGeneric = v),
                ),
                const SizedBox(height: 16),

                // Save button
                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.save_rounded),
                    label: Text(isEditing ? 'Guardar Alterações' : 'Adicionar ao Stock'),
                    onPressed: _submit,
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
