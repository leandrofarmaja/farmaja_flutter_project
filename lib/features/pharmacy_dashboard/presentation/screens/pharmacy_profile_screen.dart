
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../pharmacies/domain/pharmacy_model.dart';
import '../providers/pharmacy_dashboard_provider.dart';

class PharmacyProfileScreen extends ConsumerStatefulWidget {
  const PharmacyProfileScreen({super.key});

  @override
  ConsumerState<PharmacyProfileScreen> createState() =>
      _PharmacyProfileScreenState();
}

class _PharmacyProfileScreenState
    extends ConsumerState<PharmacyProfileScreen> {
  final _formKey = GlobalKey<FormState>();

  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _provinceController = TextEditingController();
  final _municipalityController = TextEditingController();
  final _neighborhoodController = TextEditingController();
  final _addressController = TextEditingController();

  bool _formInitialized = false;
  bool _isSaving = false;

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _provinceController.dispose();
    _municipalityController.dispose();
    _neighborhoodController.dispose();
    _addressController.dispose();
    super.dispose();
  }

  void _initializeForm(PharmacyModel pharmacy) {
    if (_formInitialized) return;

    _nameController.text = pharmacy.name;
    _phoneController.text = pharmacy.phone;
    _provinceController.text = pharmacy.province;
    _municipalityController.text = pharmacy.district;
    _neighborhoodController.text = pharmacy.neighborhood;
    _addressController.text = pharmacy.address;

    _formInitialized = true;
  }

  Future<void> _saveProfile(PharmacyModel pharmacy) async {
    if (!_formKey.currentState!.validate()) return;

    final user = Supabase.instance.client.auth.currentUser;

    if (user == null) {
      _showMessage('Sessão expirada. Inicie sessão novamente.');
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await Supabase.instance.client
          .from('farmacias')
          .update({
            'nome': _nameController.text.trim(),
            'telefone': _phoneController.text.trim(),
            'provincia': _provinceController.text.trim(),
            'municipio': _municipalityController.text.trim(),
            'bairro': _neighborhoodController.text.trim(),
            'endereco': _addressController.text.trim(),
          })
          .eq('id', pharmacy.id)
          .eq('owner_user_id', user.id)
          .select('id');

      if (!mounted) return;

      if (response.isEmpty) {
        _showMessage(
          'Não foi possível actualizar os dados da farmácia.',
        );
        return;
      }

      await ref
          .read(pharmacyDashboardProvider.notifier)
          .loadDashboardData();

      if (!mounted) return;

      _showMessage('Perfil da farmácia actualizado com sucesso.');
    } on PostgrestException catch (error) {
      if (!mounted) return;
      _showMessage('Erro ao actualizar: ${error.message}');
    } catch (error) {
      if (!mounted) return;
      _showMessage('Ocorreu um erro inesperado ao guardar os dados.');
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  void _showMessage(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  String? _validateRequired(String? value) {
    if (value == null || value.trim().isEmpty) {
      return 'Este campo é obrigatório.';
    }
    return null;
  }

  Widget _buildField({
    required String label,
    required String hint,
    required TextEditingController controller,
    required IconData icon,
    TextInputType keyboardType = TextInputType.text,
    String? Function(String?)? validator,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w600,
              color: Color(0xFF173B57),
            ),
          ),
          const SizedBox(height: 8),
          TextFormField(
            controller: controller,
            keyboardType: keyboardType,
            validator: validator ?? _validateRequired,
            textCapitalization: TextCapitalization.sentences,
            decoration: InputDecoration(
              hintText: hint,
              prefixIcon: Icon(icon, color: AppColors.primary),
              filled: true,
              fillColor: Colors.white,
              contentPadding: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 16,
              ),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Color(0xFFE5E7EB)),
              ),
              focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(
                  color: AppColors.primary,
                  width: 1.5,
                ),
              ),
              errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(14),
                borderSide: const BorderSide(color: Colors.red),
              ),
            ),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final dashboardState = ref.watch(pharmacyDashboardProvider);
    final pharmacy = dashboardState.pharmacyDetails;

    if (pharmacy == null) {
      return Scaffold(
        backgroundColor: const Color(0xFFF8FBF9),
        appBar: AppBar(
          title: const Text('Perfil da Farmácia'),
          backgroundColor: Colors.white,
          foregroundColor: const Color(0xFF173B57),
          elevation: 0,
        ),
        body: Center(
          child: dashboardState.isLoading
              ? const CircularProgressIndicator()
              : Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.store_outlined,
                      size: 48,
                      color: Colors.grey,
                    ),
                    const SizedBox(height: 12),
                    const Text('Não foi possível carregar a farmácia.'),
                    const SizedBox(height: 12),
                    ElevatedButton(
                      onPressed: () => ref
                          .read(pharmacyDashboardProvider.notifier)
                          .loadDashboardData(),
                      child: const Text('Tentar novamente'),
                    ),
                  ],
                ),
        ),
      );
    }

    _initializeForm(pharmacy);

    return Scaffold(
      backgroundColor: const Color(0xFFF8FBF9),
      appBar: AppBar(
        title: const Text(
          'Perfil da Farmácia',
          style: TextStyle(
            fontWeight: FontWeight.w700,
            color: Color(0xFF173B57),
          ),
        ),
        backgroundColor: Colors.white,
        foregroundColor: const Color(0xFF173B57),
        elevation: 0,
      ),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(20),
            children: [
              Container(
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: const Color(0xFFE5E7EB)),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(
                          Icons.storefront_outlined,
                          color: AppColors.primary,
                          size: 25,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Text(
                            'Dados da farmácia',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.w700,
                              color: Color(0xFF173B57),
                            ),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 8),
                    const Text(
                      'Mantenha as informações da sua farmácia actualizadas.',
                      style: TextStyle(
                        fontSize: 13,
                        color: Colors.black54,
                      ),
                    ),
                    const SizedBox(height: 24),
                    _buildField(
                      label: 'Nome da farmácia',
                      hint: 'Nome da farmácia',
                      controller: _nameController,
                      icon: Icons.local_pharmacy_outlined,
                    ),
                    _buildField(
                      label: 'Telefone',
                      hint: 'Número de telefone',
                      controller: _phoneController,
                      icon: Icons.phone_outlined,
                      keyboardType: TextInputType.phone,
                    ),
                    _buildField(
                      label: 'Província',
                      hint: 'Província',
                      controller: _provinceController,
                      icon: Icons.map_outlined,
                    ),
                    _buildField(
                      label: 'Município',
                      hint: 'Município',
                      controller: _municipalityController,
                      icon: Icons.location_city_outlined,
                    ),
                    _buildField(
                      label: 'Bairro',
                      hint: 'Bairro',
                      controller: _neighborhoodController,
                      icon: Icons.place_outlined,
                    ),
                    _buildField(
                      label: 'Endereço',
                      hint: 'Rua, número ou referência',
                      controller: _addressController,
                      icon: Icons.home_outlined,
                    ),
                    const SizedBox(height: 8),
                    SizedBox(
                      width: double.infinity,
                      height: 54,
                      child: ElevatedButton.icon(
                        onPressed: _isSaving
                            ? null
                            : () => _saveProfile(pharmacy),
                        icon: _isSaving
                            ? const SizedBox(
                                width: 19,
                                height: 19,
                                child: CircularProgressIndicator(
                                  strokeWidth: 2,
                                  color: Colors.white,
                                ),
                              )
                            : const Icon(Icons.save_outlined),
                        label: Text(
                          _isSaving ? 'A guardar...' : 'Guardar alterações',
                          style: const TextStyle(
                            fontWeight: FontWeight.w700,
                            fontSize: 15,
                          ),
                        ),
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: Colors.white,
                          disabledBackgroundColor: Colors.grey,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(14),
                          ),
                          elevation: 0,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 4),
                child: Text(
                  'A fotografia da farmácia e a localização GPS serão '
                  'integradas numa etapa posterior.',
                  style: TextStyle(
                    fontSize: 12,
                    color: Colors.black54,
                    height: 1.5,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
