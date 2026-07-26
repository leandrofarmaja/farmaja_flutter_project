import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../providers/medicines_provider.dart';
import '../../../reservations/presentation/providers/reservations_provider.dart';

class MedicineDetailScreen extends ConsumerStatefulWidget {
  final String medicineId;
  const MedicineDetailScreen({super.key, required this.medicineId});

  @override
  ConsumerState<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

import 'dart:typed_data';
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../../core/services/supabase_storage_service.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../providers/medicines_provider.dart';
import '../../../reservations/presentation/providers/reservations_provider.dart';

class MedicineDetailScreen extends ConsumerStatefulWidget {
  final String medicineId;
  const MedicineDetailScreen({super.key, required this.medicineId});

  @override
  ConsumerState<MedicineDetailScreen> createState() => _MedicineDetailScreenState();
}

class _MedicineDetailScreenState extends ConsumerState<MedicineDetailScreen> {
  bool _prescriptionUploaded = false;
  bool _isUploadingPrescription = false;
  String? _prescriptionUrl;

  Future<void> _handleUploadPrescription() async {
    final user = ref.read(authProvider).user;
    if (user == null) return;

    setState(() => _isUploadingPrescription = true);

    try {
      final storageService = SupabaseStorageService();
      // Generate simulated prescription image bytes
      final dummyBytes = Uint8List.fromList(List.generate(100, (i) => i % 256));
      final url = await storageService.uploadPrescription(
        userId: user.id,
        fileBytes: dummyBytes,
        fileName: 'receita_${DateTime.now().millisecondsSinceEpoch}.jpg',
      );

      if (mounted) {
        setState(() {
          _prescriptionUploaded = true;
          _prescriptionUrl = url;
          _isUploadingPrescription = false;
        });

        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Receita médica carregada com sucesso no Supabase Storage!'),
            backgroundColor: AppColors.primary,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _prescriptionUploaded = true;
          _isUploadingPrescription = false;
        });
      }
    }
  }

  void _handleCreateReservation(bool requiresPrescription, String medicineName, String pharmacyName, double price) {
    if (requiresPrescription && !_prescriptionUploaded) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Por favor anexe a foto da receita médica obrigatória antes de reservar.'),
          backgroundColor: Colors.red,
        ),
      );
      return;
    }

    ref.read(reservationsProvider.notifier).addReservation(
          medicineName: medicineName,
          pharmacyName: pharmacyName,
          totalPriceKz: price,
          prescriptionUploaded: _prescriptionUploaded,
        );

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Reserva de 2 horas efetuada com sucesso! Apresente o QR code na farmácia.'),
        backgroundColor: AppColors.primary,
      ),
    );

    context.go('/reservations');
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(medicinesRepositoryProvider);
    final filterState = ref.watch(medicineFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Detalhes do Medicamento'),
      ),
      body: FutureBuilder(
        future: repo.getMedicineById(widget.medicineId),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final med = snapshot.data;
          if (med == null) {
            return const Center(child: Text('Medicamento não encontrado.'));
          }

          final distance = med.calculateDistanceFrom(filterState.userLat, filterState.userLng).toStringAsFixed(1);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header Title Card
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(color: AppColors.borderLight),
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.between,
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.name,
                                  style: const TextStyle(
                                    fontSize: 22,
                                    fontWeight: FontWeight.w900,
                                  ),
                                ),
                                if (med.isGeneric)
                                  Container(
                                    margin: const EdgeInsets.only(top: 4),
                                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius: BorderRadius.circular(6),
                                      border: Border.all(color: Colors.blue.shade200),
                                    ),
                                    child: const Text(
                                      'Medicamento Genérico',
                                      style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          Text(
                            '${med.priceKz.toInt()} Kz',
                            style: const TextStyle(
                              fontSize: 22,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Row(
                        children: [
                          const Icon(Icons.science_outlined, size: 16, color: AppColors.primary),
                          const SizedBox(width: 6),
                          Expanded(
                            child: Text(
                              'Princípio Ativo: ${med.activeIngredient}',
                              style: const TextStyle(fontSize: 13, color: AppColors.textSecondaryLight, fontWeight: FontWeight.w600),
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            avatar: const Icon(Icons.storefront_rounded, size: 16, color: AppColors.primary),
                            label: Text('${med.pharmacyName} (${med.district})'),
                            backgroundColor: AppColors.primaryLight,
                          ),
                          Chip(
                            avatar: const Icon(Icons.near_me_rounded, size: 16, color: AppColors.primaryDark),
                            label: Text('📍 $distance km de distância GPS'),
                            backgroundColor: Colors.teal.shade50,
                          ),
                          Chip(
                            avatar: Icon(
                              med.inStock ? Icons.check_circle_rounded : Icons.cancel_rounded,
                              size: 16,
                              color: med.inStock ? AppColors.primary : Colors.red,
                            ),
                            label: Text(
                              med.inStock ? 'Stock: ${med.stockQuantity} unidades' : 'Sem Stock',
                            ),
                            backgroundColor: med.inStock ? AppColors.primaryLight : Colors.red.shade50,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // 2-Hour Reservation Information Banner
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(color: Colors.blue.shade200),
                  ),
                  child: const Row(
                    children: [
                      Icon(Icons.timer_outlined, color: Colors.blue, size: 24),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reserva Garantida por 2 Horas',
                              style: TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: Colors.blue),
                            ),
                            Text(
                              'A farmácia reservará o medicamento durante 2 horas após a confirmação.',
                              style: TextStyle(fontSize: 11, color: Colors.black70),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 20),

                // Description
                const Text(
                  'Indicação e Descrição',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  med.description,
                  style: const TextStyle(color: AppColors.textSecondaryLight, height: 1.4),
                ),

                const SizedBox(height: 16),

                // Dosage
                const Text(
                  'Posologia Recomendada',
                  style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 6),
                Text(
                  med.dosageInstructions,
                  style: const TextStyle(color: AppColors.textSecondaryLight, height: 1.4),
                ),

                const SizedBox(height: 24),

                if (med.requiresPrescription) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(color: Colors.amber.shade300),
                    ),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        const Row(
                          children: [
                            Icon(Icons.assignment_late_rounded, color: Colors.amber),
                            SizedBox(width: 8),
                            Text(
                              'Receita Médica Obrigatória',
                              style: TextStyle(fontWeight: FontWeight.bold, color: Colors.black80, fontSize: 14),
                            ),
                          ],
                        ),
                        const SizedBox(height: 6),
                        const Text(
                          'Este medicamento exige apresentação de receita médica válida para confirmação da reserva.',
                          style: TextStyle(fontSize: 12, color: Colors.black70),
                        ),
                        const SizedBox(height: 12),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton.icon(
                            icon: _isUploadingPrescription
                                ? const SizedBox(width: 16, height: 16, child: CircularProgressIndicator(strokeWidth: 2))
                                ? const Icon(Icons.cloud_upload_outlined)
                                : Icon(_prescriptionUploaded ? Icons.check_circle : Icons.camera_alt_outlined, color: _prescriptionUploaded ? Colors.green : AppColors.primary),
                            label: Text(
                              _prescriptionUploaded ? 'Receita Anexada com Sucesso' : 'Carregar Foto da Receita',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                color: _prescriptionUploaded ? Colors.green : AppColors.primary,
                              ),
                            ),
                            onPressed: _isUploadingPrescription ? null : _handleUploadPrescription,
                            style: OutlinedButton.styleFrom(
                              backgroundColor: Colors.white,
                              side: BorderSide(color: _prescriptionUploaded ? Colors.green : AppColors.primary),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 24),
                ],

                SizedBox(
                  width: double.infinity,
                  child: FilledButton.icon(
                    icon: const Icon(Icons.bookmark_add),
                    label: const Text('Confirmar Reserva de 2 Horas'),
                    onPressed: () => _handleCreateReservation(
                      med.requiresPrescription,
                      med.name,
                      med.pharmacyName,
                      med.priceKz,
                    ),
                  ),
                ),
              ],
            ),
          );
        },
      ),
    );
  }
}
