
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../medicines/domain/medicine_model.dart';
import '../providers/pharmacy_dashboard_provider.dart';
import '../widgets/add_edit_medicine_dialog.dart';
import '../widgets/qr_scanner_dialog.dart';
import '../widgets/prescription_review_dialog.dart';
import '../widgets/subscription_payment_dialog.dart';

class PharmacyDashboardScreen extends ConsumerStatefulWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  ConsumerState<PharmacyDashboardScreen> createState() =>
      _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState
    extends ConsumerState<PharmacyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedStatsPeriod = 'Dia';

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(pharmacyDashboardProvider.notifier).loadDashboardData();
      }
    });
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showMessage(
    String message, {
    bool isError = false,
  }) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          content: Text(message),
          backgroundColor:
              isError ? Colors.red.shade700 : AppColors.primary,
        ),
      );
  }

  Future<void> _runOperation(
    Future<dynamic> Function() operation, {
    required String successMessage,
    required String failureMessage,
  }) async {
    try {
      final result = await operation();

      if (!mounted) return;

      if (result == true) {
        _showMessage(successMessage);
      } else {
        _showMessage(failureMessage, isError: true);
      }
    } catch (e) {
      if (!mounted) return;
      _showMessage(failureMessage, isError: true);
    }
  }

  void _showAddEditMedicineModal([MedicineModel? medicine]) {
    final state = ref.read(pharmacyDashboardProvider);

    if (state.isBlockedOrExpired) {
      _showBlockedDialog();
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => AddEditMedicineDialog(
        medicine: medicine,
        onSave: (updated) {
          Navigator.of(dialogContext).pop();

          _runOperation(
            () => medicine == null
                ? ref
                    .read(pharmacyDashboardProvider.notifier)
                    .addMedicine(updated)
                : ref
                    .read(pharmacyDashboardProvider.notifier)
                    .updateMedicine(updated),
            successMessage: medicine == null
                ? 'Medicamento adicionado com sucesso.'
                : 'Medicamento atualizado com sucesso.',
            failureMessage:
                'Não foi possível guardar o medicamento. Verifica os dados e as permissões.',
          );
        },
      ),
    );
  }

  void _showQrScannerModal() {
    final state = ref.read(pharmacyDashboardProvider);

    if (state.isBlockedOrExpired) {
      _showBlockedDialog();
      return;
    }

    showDialog<void>(
      context: context,
      builder: (dialogContext) => QrScannerDialog(
        onValidateCode: (code) async {
          return await ref
              .read(pharmacyDashboardProvider.notifier)
              .validateQrCode(code);
        },
      ),
    );
  }

  void _showPaymentModal() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => SubscriptionPaymentDialog(
        onSubmit: ({
          required paymentMethod,
          required referenceNumber,
          required proofUrl,
          notes,
        }) async {
          return await ref
              .read(pharmacyDashboardProvider.notifier)
              .submitPaymentProof(
                paymentMethod: paymentMethod,
                referenceNumber: referenceNumber,
                proofUrl: proofUrl,
                notes: notes,
              );
        },
      ),
    );
  }

  void _showBlockedDialog() {
    showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.lock_rounded,
          size: 48,
          color: Colors.red,
        ),
        title: const Text(
          'Acesso bloqueado',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        content: const Text(
          'A subscrição desta farmácia está expirada ou bloqueada. '
          'Consulta o estado da conta antes de efectuar um pagamento.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.of(dialogContext).pop();
              context.push('/admin/subscriptions');
            },
            child: const Text('Painel Admin'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Enviar comprovativo'),
            onPressed: () {
              Navigator.of(dialogContext).pop();
              _showPaymentModal();
            },
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pharmacyDashboardProvider);

    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              state.activePharmacyName ?? 'Painel da Farmácia',
              style: const TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w900,
              ),
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              'Subscrição: ${_getSubscriptionStatusBadge(state)}',
              style: const TextStyle(
                fontSize: 11,
                color: AppColors.textSecondaryLight,
              ),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(
              Icons.admin_panel_settings_rounded,
              color: AppColors.primary,
            ),
            tooltip: 'Painel Admin Subscrições',
            onPressed: () => context.push('/admin/subscriptions'),
          ),
          IconButton(
            icon: const Icon(
              Icons.qr_code_scanner_rounded,
              color: AppColors.primary,
            ),
            tooltip: 'Validar código de levantamento',
            onPressed: _showQrScannerModal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Actualizar dados',
            onPressed: () {
              ref
                  .read(pharmacyDashboardProvider.notifier)
                  .loadDashboardData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: const [
            Tab(
              icon: Icon(Icons.analytics_rounded),
              text: 'Estatísticas',
            ),
            Tab(
              icon: Icon(Icons.inventory_rounded),
              text: 'Medicamentos',
            ),
            Tab(
              icon: Icon(Icons.bookmark_rounded),
              text: 'Reservas',
            ),
            Tab(
              icon: Icon(Icons.assignment_turned_in_rounded),
              text: 'Receitas',
            ),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : _buildDashboardBody(state),
      floatingActionButton: state.isLoading || state.isBlockedOrExpired
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddEditMedicineModal(),
              backgroundColor: AppColors.primary,
              icon: const Icon(
                Icons.add_rounded,
                color: Colors.white,
              ),
              label: const Text(
                'Novo Medicamento',
                style: TextStyle(
                  color: Colors.white,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
    );
  }

  Widget _buildDashboardBody(PharmacyDashboardState state) {
    if (state.error != null && state.error!.trim().isNotEmpty) {
      return Center(
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(
                Icons.error_outline_rounded,
                size: 56,
                color: Colors.red,
              ),
              const SizedBox(height: 12),
              const Text(
                'Não foi possível carregar o painel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 8),
              Text(
                state.error!,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  ref
                      .read(pharmacyDashboardProvider.notifier)
                      .loadDashboardData();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildSubscriptionBanner(state),
        Expanded(
          child: state.isBlockedOrExpired
              ? _buildBlockedOverlay()
              : TabBarView(
                  controller: _tabController,
                  children: [
                    _buildStatsTab(state),
                    _buildMedicinesTab(state),
                    _buildReservationsTab(state),
                    _buildPrescriptionsTab(state),
                  ],
                ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionBanner(PharmacyDashboardState state) {
    final status =
        state.pharmacyDetails?.subscriptionStatus ?? 'trial';

    if (status == 'trial') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 10,
        ),
        color: Colors.blue.shade50,
        child: Row(
          children: [
            const Icon(
              Icons.timer_outlined,
              color: Colors.blue,
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Período experimental: ${state.daysLeftInTrial} dias restantes',
                    style: const TextStyle(
                      fontWeight: FontWeight.bold,
                      fontSize: 12,
                      color: AppColors.primaryDark,
                    ),
                  ),
                  const Text(
                    'Confirma as condições da subscrição antes de efectuar pagamentos.',
                    style: TextStyle(fontSize: 11),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _showPaymentModal,
              child: const Text('Renovar'),
            ),
          ],
        ),
      );
    }

    if (status == 'active') {
      return Container(
        width: double.infinity,
        padding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 8,
        ),
        color: Colors.green.shade50,
        child: Row(
          children: [
            const Icon(
              Icons.verified_rounded,
              color: Colors.green,
            ),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Subscrição activa • Próximo pagamento em '
                '${state.daysUntilPaymentDue} dias',
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 12,
                  color: Colors.green,
                ),
              ),
            ),
            OutlinedButton(
              onPressed: _showPaymentModal,
              child: const Text('Renovar'),
            ),
          ],
        ),
      );
    }

    return const SizedBox.shrink();
  }

  Widget _buildBlockedOverlay() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      color: Colors.red.shade50.withValues(alpha: 0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(
              Icons.lock_clock_rounded,
              size: 64,
              color: Colors.red,
            ),
            const SizedBox(height: 16),
            const Text(
              'Acesso ao painel suspenso',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w900,
                color: Colors.red,
              ),
            ),
            const SizedBox(height: 8),
            const Text(
              'O acesso à gestão está bloqueado. '
              'Contacta o administrador para confirmar o estado da conta.',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 13,
                color: Colors.black87,
              ),
            ),
            const SizedBox(height: 24),
            Wrap(
              alignment: WrapAlignment.center,
              spacing: 12,
              runSpacing: 12,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Enviar comprovativo'),
                  onPressed: _showPaymentModal,
                ),
                OutlinedButton.icon(
                  icon: const Icon(Icons.admin_panel_settings_rounded),
                  label: const Text('Painel Admin'),
                  onPressed: () => context.push('/admin/subscriptions'),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  String _getSubscriptionStatusBadge(
    PharmacyDashboardState state,
  ) {
    final status =
        state.pharmacyDetails?.subscriptionStatus ?? 'trial';

    if (status == 'trial') {
      return 'Período experimental (${state.daysLeftInTrial}d)';
    }
    if (status == 'active') return 'Activa';
    if (status == 'expired') return 'Expirada';
    return 'Bloqueada';
  }

  bool _isCompleted(String status) {
    final normalized = status.trim().toLowerCase();
    return normalized == 'completed' ||
        normalized == 'levantada' ||
        normalized == 'resgatado' ||
        normalized == 'entregue';
  }

  Widget _buildStatsTab(PharmacyDashboardState state) {
    // Os dados apresentados são os valores carregados pelo serviço.
    // Não multiplicamos totais para simular períodos que não foram
    // consultados na base de dados.
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            'Visão geral do desempenho',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Dia', label: Text('Dia')),
              ButtonSegment(value: 'Semana', label: Text('Semana')),
              ButtonSegment(value: 'Mês', label: Text('Mês')),
            ],
            selected: {_selectedStatsPeriod},
            onSelectionChanged: (selection) {
              setState(() {
                _selectedStatsPeriod = selection.first;
              });
            },
          ),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount:
                MediaQuery.of(context).size.width > 600 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                title: 'Faturação carregada',
                value: '${state.totalRevenue.toInt()} Kz',
                icon: Icons.payments_rounded,
                color: Colors.green.shade700,
                bgColor: Colors.green.shade50,
              ),
              _buildStatCard(
                title: 'Reservas concluídas',
                value: '${state.completedReservationsCount}',
                icon: Icons.check_circle_rounded,
                color: Colors.blue.shade700,
                bgColor: Colors.blue.shade50,
              ),
              _buildStatCard(
                title: 'Itens em stock',
                value: '${state.totalStockItems}',
                icon: Icons.inventory_2_rounded,
                color: Colors.amber.shade800,
                bgColor: Colors.amber.shade50,
              ),
              _buildStatCard(
                title: 'Receitas pendentes',
                value: '${state.pendingPrescriptionsCount}',
                icon: Icons.assignment_late_rounded,
                color: Colors.purple.shade700,
                bgColor: Colors.purple.shade50,
              ),
            ],
          ),
          const SizedBox(height: 24),
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [
                  AppColors.primaryDark,
                  AppColors.primary,
                ],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(
                  Icons.qr_code_2_rounded,
                  color: Colors.white,
                  size: 40,
                ),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Validar código de levantamento',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.bold,
                          fontSize: 15,
                        ),
                      ),
                      Text(
                        'Confirma o código da reserva no levantamento.',
                        style: TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
                ElevatedButton(
                  onPressed: _showQrScannerModal,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: Colors.white,
                    foregroundColor: AppColors.primaryDark,
                  ),
                  child: const Text('Validar'),
                ),
              ],
            ),
          ),
          const SizedBox(height: 24),
          const Text(
            'Actividade recente',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w900,
            ),
          ),
          const SizedBox(height: 8),
          if (state.reservations.isEmpty)
            const Padding(
              padding: EdgeInsets.all(16),
              child: Text('Ainda não existem reservas para apresentar.'),
            )
          else
            ...state.reservations.take(3).map((reservation) {
              final completed = _isCompleted(reservation.status);

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: completed
                        ? Colors.green.shade100
                        : Colors.blue.shade100,
                    child: Icon(
                      completed ? Icons.check : Icons.bookmark,
                      color: completed ? Colors.green : AppColors.primary,
                    ),
                  ),
                  title: Text(
                    reservation.medicineName,
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text(
                    'Código: ${reservation.pickupCode} • '
                    '${reservation.totalPriceKz.toInt()} Kz',
                  ),
                  trailing: Text(
                    completed ? 'Concluída' : 'Pendente',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: completed ? Colors.green : AppColors.primary,
                    ),
                  ),
                ),
              );
            }),
        ],
      ),
    );
  }

  Widget _buildStatCard({
    required String title,
    required String value,
    required IconData icon,
    required Color color,
    required Color bgColor,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: color.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Icon(icon, color: color, size: 22),
          const Spacer(),
          Text(
            value,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w900,
              color: color,
            ),
          ),
          Text(
            title,
            style: TextStyle(
              fontSize: 11,
              color: color.withValues(alpha: 0.8),
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMedicinesTab(PharmacyDashboardState state) {
    final filtered = state.medicines.where((medicine) {
      if (_searchQuery.isEmpty) return true;

      final query = _searchQuery.toLowerCase();
      return medicine.name.toLowerCase().contains(query) ||
          medicine.activeIngredient.toLowerCase().contains(query);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: TextField(
            decoration: InputDecoration(
              hintText: 'Pesquisar medicamentos no stock...',
              prefixIcon: const Icon(Icons.search_rounded),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
            onChanged: (value) => setState(() => _searchQuery = value),
          ),
        ),
        Expanded(
          child: filtered.isEmpty
              ? const Center(
                  child: Text('Não existem medicamentos para apresentar.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: filtered.length,
                  itemBuilder: (context, index) {
                    final medicine = filtered[index];

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(12),
                        child: Column(
                          children: [
                            Row(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Expanded(
                                  child: Column(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      Text(
                                        medicine.name,
                                        style: const TextStyle(
                                          fontWeight: FontWeight.bold,
                                          fontSize: 16,
                                        ),
                                      ),
                                      Text(
                                        medicine.activeIngredient,
                                        style: const TextStyle(
                                          fontSize: 12,
                                          color:
                                              AppColors.textSecondaryLight,
                                        ),
                                      ),
                                      const SizedBox(height: 4),
                                      Wrap(
                                        spacing: 6,
                                        runSpacing: 4,
                                        children: [
                                          if (medicine.requiresPrescription)
                                            _medicineTag(
                                              'Exige receita',
                                              Colors.amber.shade100,
                                              Colors.amber.shade900,
                                            ),
                                          if (medicine.isGeneric)
                                            _medicineTag(
                                              'Genérico',
                                              Colors.blue.shade100,
                                              Colors.blue.shade900,
                                            ),
                                        ],
                                      ),
                                    ],
                                  ),
                                ),
                                const SizedBox(width: 8),
                                Column(
                                  crossAxisAlignment: CrossAxisAlignment.end,
                                  children: [
                                    Text(
                                      '${medicine.priceKz.toInt()} Kz',
                                      style: const TextStyle(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w900,
                                        color: AppColors.primaryDark,
                                      ),
                                    ),
                                    const SizedBox(height: 4),
                                    Text(
                                      'Stock: ${medicine.stockQuantity}',
                                      style: TextStyle(
                                        fontSize: 11,
                                        fontWeight: FontWeight.bold,
                                        color: medicine.inStock
                                            ? AppColors.primary
                                            : Colors.red,
                                      ),
                                    ),
                                  ],
                                ),
                              ],
                            ),
                            const Divider(height: 20),
                            Row(
                              children: [
                                IconButton.outlined(
                                  icon: const Icon(Icons.remove, size: 16),
                                  tooltip: 'Reduzir stock',
                                  onPressed: medicine.stockQuantity > 0
                                      ? () {
                                          _runOperation(
                                            () => ref
                                                .read(
                                                  pharmacyDashboardProvider
                                                      .notifier,
                                                )
                                                .updateStock(
                                                  medicine.id,
                                                  medicine.stockQuantity - 1,
                                                ),
                                            successMessage: 'Stock actualizado.',
                                            failureMessage:
                                                'Não foi possível actualizar o stock.',
                                          );
                                        }
                                      : null,
                                ),
                                Padding(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 8,
                                  ),
                                  child: Text(
                                    '${medicine.stockQuantity}',
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                    ),
                                  ),
                                ),
                                IconButton.outlined(
                                  icon: const Icon(Icons.add, size: 16),
                                  tooltip: 'Aumentar stock',
                                  onPressed: () {
                                    _runOperation(
                                      () => ref
                                          .read(
                                            pharmacyDashboardProvider.notifier,
                                          )
                                          .updateStock(
                                            medicine.id,
                                            medicine.stockQuantity + 1,
                                          ),
                                      successMessage: 'Stock actualizado.',
                                      failureMessage:
                                          'Não foi possível actualizar o stock.',
                                    );
                                  },
                                ),
                                const Spacer(),
                                IconButton(
                                  icon: const Icon(
                                    Icons.edit_outlined,
                                    color: AppColors.primary,
                                  ),
                                  tooltip: 'Editar medicamento',
                                  onPressed: () =>
                                      _showAddEditMedicineModal(medicine),
                                ),
                                IconButton(
                                  icon: const Icon(
                                    Icons.delete_outline,
                                    color: Colors.red,
                                  ),
                                  tooltip: 'Eliminar medicamento',
                                  onPressed: () =>
                                      _confirmDeleteMedicine(medicine),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _medicineTag(
    String label,
    Color background,
    Color foreground,
  ) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
      decoration: BoxDecoration(
        color: background,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          color: foreground,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Future<void> _confirmDeleteMedicine(MedicineModel medicine) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: const Text('Eliminar medicamento?'),
        content: Text(
          'Confirma a eliminação de "${medicine.name}" do stock.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: FilledButton.styleFrom(
              backgroundColor: Colors.red,
            ),
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Eliminar'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    await _runOperation(
      () => ref
          .read(pharmacyDashboardProvider.notifier)
          .deleteMedicine(medicine.id),
      successMessage: 'Medicamento eliminado.',
      failureMessage: 'Não foi possível eliminar o medicamento.',
    );
  }

  Widget _buildReservationsTab(PharmacyDashboardState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16),
          child: SizedBox(
            width: double.infinity,
            child: FilledButton.icon(
              icon: const Icon(Icons.qr_code_scanner),
              label: const Text('Validar código de levantamento'),
              onPressed: _showQrScannerModal,
            ),
          ),
        ),
        Expanded(
          child: state.reservations.isEmpty
              ? const Center(
                  child: Text('Ainda não existem reservas.'),
                )
              : ListView.builder(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  itemCount: state.reservations.length,
                  itemBuilder: (context, index) {
                    final reservation = state.reservations[index];
                    final completed = _isCompleted(reservation.status);

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: ListTile(
                        title: Text(
                          reservation.medicineName,
                          style: const TextStyle(
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                        subtitle: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text('Código: ${reservation.pickupCode}'),
                            Text(
                              'Preço: ${reservation.totalPriceKz.toInt()} Kz',
                            ),
                            const Text('Prazo de levantamento: 2 horas'),
                          ],
                        ),
                        trailing: Container(
                          padding: const EdgeInsets.symmetric(
                            horizontal: 10,
                            vertical: 4,
                          ),
                          decoration: BoxDecoration(
                            color: completed
                                ? Colors.green.shade100
                                : Colors.amber.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            completed ? 'Levantada' : 'Pendente',
                            style: TextStyle(
                              fontSize: 11,
                              fontWeight: FontWeight.bold,
                              color: completed
                                  ? Colors.green.shade800
                                  : Colors.amber.shade900,
                            ),
                          ),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }

  Widget _buildPrescriptionsTab(PharmacyDashboardState state) {
    if (state.prescriptions.isEmpty) {
      return const Center(
        child: Text('Ainda não existem receitas para apresentar.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.prescriptions.length,
      itemBuilder: (context, index) {
        final prescription = state.prescriptions[index];
        final isVerified = prescription.status == 'verified';
        final isRejected = prescription.status == 'rejected';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        'Paciente: ${prescription.userName}',
                        style: const TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 16,
                        ),
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 8,
                        vertical: 2,
                      ),
                      decoration: BoxDecoration(
                        color: isVerified
                            ? Colors.green.shade100
                            : isRejected
                                ? Colors.red.shade100
                                : Colors.amber.shade100,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isVerified
                            ? 'Aprovada'
                            : isRejected
                                ? 'Rejeitada'
                                : 'Pendente',
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isVerified
                              ? Colors.green.shade800
                              : isRejected
                                  ? Colors.red.shade800
                                  : Colors.amber.shade900,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Medicamento: ${prescription.medicineName}'),
                Text(
                  'Data do pedido: ${prescription.createdAt}',
                  style: const TextStyle(
                    fontSize: 11,
                    color: Colors.grey,
                  ),
                ),
                if (prescription.notes != null &&
                    prescription.notes!.isNotEmpty) ...[
                  const SizedBox(height: 8),
                  Text('Observações: ${prescription.notes}'),
                ],
                const SizedBox(height: 12),
                Align(
                  alignment: Alignment.centerRight,
                  child: OutlinedButton.icon(
                    icon: const Icon(
                      Icons.remove_red_eye_rounded,
                      size: 16,
                    ),
                    label: const Text('Analisar receita'),
                    onPressed: () {
                      showDialog<void>(
                        context: context,
                        builder: (dialogContext) =>
                            PrescriptionReviewDialog(
                          prescription: prescription,
                          onReview: (status, notes) {
                            Navigator.of(dialogContext).pop();

                            _runOperation(
                              () => ref
                                  .read(pharmacyDashboardProvider.notifier)
                                  .updatePrescription(
                                    prescription.id,
                                    status,
                                    notes,
                                  ),
                              successMessage: status == 'verified'
                                  ? 'Receita aprovada.'
                                  : 'Receita actualizada.',
                              failureMessage:
                                  'Não foi possível actualizar a receita.',
                            );
                          },
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
