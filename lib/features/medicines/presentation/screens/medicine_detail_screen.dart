
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../providers/medicines_provider.dart';
import '../../../reservations/presentation/providers/reservations_provider.dart';
import '../../../auth/presentation/providers/auth_provider.dart';

class MedicineDetailScreen extends ConsumerStatefulWidget {
  final String medicineId;

  const MedicineDetailScreen({
    super.key,
    required this.medicineId,
  });

  @override
  ConsumerState<MedicineDetailScreen> createState() =>
      _MedicineDetailScreenState();
}

class _MedicineDetailScreenState
    extends ConsumerState<MedicineDetailScreen> {
  bool _isCreatingReservation = false;

  Future<void> _handleCreateReservation({
    required bool requiresPrescription,
    required bool inStock,
    required String medicineId,
    required String pharmacyId,
  }) async {
    if (_isCreatingReservation) {
      return;
    }

    final user = ref.read(authProvider).user;

    if (user == null) {
      _showMessage(
        'Inicia sessão antes de efectuar a reserva.',
      );
      return;
    }

    if (!inStock) {
      _showMessage(
        'Este medicamento está sem stock e não pode ser reservado.',
      );
      return;
    }

    if (medicineId.trim().isEmpty ||
        pharmacyId.trim().isEmpty) {
      _showMessage(
        'Não foi possível identificar o medicamento ou a farmácia.',
      );
      return;
    }

    setState(() {
      _isCreatingReservation = true;
    });

    try {
      await ref.read(reservationsProvider.notifier).addReservation(
            medicineId: medicineId,
            pharmacyId: pharmacyId,
            prescriptionUploaded: false,
            prescriptionPath: null,
          );

      if (!mounted) return;

      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text(
            'Reserva criada com sucesso. Consulta os detalhes da reserva.',
          ),
          backgroundColor: AppColors.primary,
        ),
      );

      context.go('/reservations');
    } catch (e) {
      if (!mounted) return;

      _showMessage(
        'Não foi possível efectuar a reserva: $e',
      );
    } finally {
      if (mounted) {
        setState(() {
          _isCreatingReservation = false;
        });
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final repo = ref.watch(medicinesRepositoryProvider);
    final filterState = ref.watch(medicineFilterProvider);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Detalhes do Medicamento',
        ),
      ),
      body: FutureBuilder(
        future: repo.getMedicineById(widget.medicineId),
        builder: (context, snapshot) {
          if (snapshot.connectionState ==
              ConnectionState.waiting) {
            return const Center(
              child: CircularProgressIndicator(),
            );
          }

          if (snapshot.hasError) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(24),
                child: Text(
                  'Não foi possível carregar o medicamento: ${snapshot.error}',
                  textAlign: TextAlign.center,
                ),
              ),
            );
          }

          final med = snapshot.data;

          if (med == null) {
            return const Center(
              child: Text(
                'Medicamento não encontrado.',
              ),
            );
          }

          final distance = med
              .calculateDistanceFrom(
                filterState.userLat,
                filterState.userLng,
              )
              .toStringAsFixed(1);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(20),
                  decoration: BoxDecoration(
                    color: AppColors.surfaceLight,
                    borderRadius: BorderRadius.circular(24),
                    border: Border.all(
                      color: AppColors.borderLight,
                    ),
                  ),
                  child: Column(
                    crossAxisAlignment:
                        CrossAxisAlignment.start,
                    children: [
                      Row(
                        crossAxisAlignment:
                            CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment:
                                  CrossAxisAlignment.start,
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
                                    margin: const EdgeInsets.only(
                                      top: 4,
                                    ),
                                    padding:
                                        const EdgeInsets.symmetric(
                                      horizontal: 8,
                                      vertical: 2,
                                    ),
                                    decoration: BoxDecoration(
                                      color: Colors.blue.shade50,
                                      borderRadius:
                                          BorderRadius.circular(6),
                                    ),
                                    child: const Text(
                                      'Medicamento Genérico',
                                      style: TextStyle(
                                        fontSize: 10,
                                        color: Colors.blue,
                                        fontWeight: FontWeight.bold,
                                      ),
                                    ),
                                  ),
                              ],
                            ),
                          ),
                          const SizedBox(width: 8),
                          Text(
                            '${med.priceKz.toInt()} Kz',
                            style: const TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w900,
                              color: AppColors.primary,
                            ),
                          ),
                        ],
                      ),
                      const SizedBox(height: 12),
                      Text(
                        'Princípio activo: ${med.activeIngredient}',
                        style: const TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondaryLight,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 12),
                      Wrap(
                        spacing: 8,
                        runSpacing: 8,
                        children: [
                          Chip(
                            avatar: const Icon(
                              Icons.storefront_rounded,
                              size: 16,
                              color: AppColors.primary,
                            ),
                            label: Text(
                              '${med.pharmacyName} (${med.district})',
                            ),
                            backgroundColor:
                                AppColors.primaryLight,
                          ),
                          Chip(
                            avatar: const Icon(
                              Icons.near_me_rounded,
                              size: 16,
                              color: AppColors.primaryDark,
                            ),
                            label: Text(
                              '$distance km de distância GPS',
                            ),
                            backgroundColor:
                                Colors.teal.shade50,
                          ),
                          Chip(
                            avatar: Icon(
                              med.inStock
                                  ? Icons.check_circle_rounded
                                  : Icons.cancel_rounded,
                              size: 16,
                              color: med.inStock
                                  ? AppColors.primary
                                  : Colors.red,
                            ),
                            label: Text(
                              med.inStock
                                  ? 'Disponível'
                                  : 'Sem stock',
                            ),
                            backgroundColor: med.inStock
                                ? AppColors.primaryLight
                                : Colors.red.shade50,
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                Container(
                  padding: const EdgeInsets.all(14),
                  decoration: BoxDecoration(
                    color: Colors.blue.shade50,
                    borderRadius: BorderRadius.circular(16),
                    border: Border.all(
                      color: Colors.blue.shade200,
                    ),
                  ),
                  child: const Row(
                    children: [
                      Icon(
                        Icons.timer_outlined,
                        color: Colors.blue,
                        size: 24,
                      ),
                      SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment:
                              CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Reserva por 2 horas',
                              style: TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                                color: Colors.blue,
                              ),
                            ),
                            Text(
                              'A validade é definida pelo servidor quando a reserva é criada.',
                              style: TextStyle(
                                fontSize: 11,
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),
                const SizedBox(height: 20),
                const Text(
                  'Indicação e descrição',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  med.description,
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 16),
                const Text(
                  'Posologia',
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  med.dosageInstructions,
                  style: const TextStyle(
                    color: AppColors.textSecondaryLight,
                    height: 1.4,
                  ),
                ),
                const SizedBox(height: 24),
                if (med.requiresPrescription) ...[
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: Colors.amber.shade50,
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: Colors.amber.shade300,
                      ),
                    ),
                    child: const Row(
                      crossAxisAlignment:
                          CrossAxisAlignment.start,
                      children: [
                        Icon(
                          Icons.assignment_late_rounded,
                          color: Colors.amber,
                        ),
                        SizedBox(width: 10),
                        Expanded(
                          child: Column(
                            crossAxisAlignment:
                                CrossAxisAlignment.start,
                            children: [
                              Text(
                                'Receita médica obrigatória',
                                style: TextStyle(
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                ),
                              ),
                              SizedBox(height: 8),
                              Text(
                                'Envio de receitas indisponível. '
                                'Por enquanto, apresente a receita médica '
                                'directamente na farmácia para verificação '
                                'pelo farmacêutico.',
                                style: TextStyle(
                                  fontSize: 12,
                                  height: 1.4,
                                ),
                              ),
                            ],
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
                    icon: _isCreatingReservation
                        ? const SizedBox(
                            width: 18,
                            height: 18,
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                            ),
                          )
                        : const Icon(
                            Icons.bookmark_add,
                          ),
                    label: Text(
                      _isCreatingReservation
                          ? 'A criar reserva...'
                          : med.inStock
                              ? 'Confirmar reserva'
                              : 'Medicamento indisponível',
                    ),
                    onPressed: _isCreatingReservation ||
                            !med.inStock
                        ? null
                        : () => _handleCreateReservation(
                              requiresPrescription:
                                  med.requiresPrescription,
                              inStock: med.inStock,
                              medicineId: med.id,
                              pharmacyId: med.pharmacyId,
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
