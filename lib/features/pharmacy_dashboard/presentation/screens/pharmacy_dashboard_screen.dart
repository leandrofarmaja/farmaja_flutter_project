import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../medicines/domain/medicine_model.dart';
import '../../../pharmacies/domain/pharmacy_model.dart';
import '../providers/pharmacy_dashboard_provider.dart';
import '../widgets/add_edit_medicine_dialog.dart';
import '../widgets/qr_scanner_dialog.dart';
import '../widgets/prescription_review_dialog.dart';
import '../widgets/subscription_payment_dialog.dart';

class PharmacyDashboardScreen extends ConsumerStatefulWidget {
  const PharmacyDashboardScreen({super.key});

  @override
  ConsumerState<PharmacyDashboardScreen> createState() => _PharmacyDashboardScreenState();
}

class _PharmacyDashboardScreenState extends ConsumerState<PharmacyDashboardScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _searchQuery = '';
  String _selectedStatsPeriod = 'Dia'; // 'Dia', 'Semana', 'Mês'

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 4, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  void _showAddEditMedicineModal([MedicineModel? med]) {
    final state = ref.read(pharmacyDashboardProvider);
    if (state.isBlockedOrExpired) {
      _showBlockedDialog();
      return;
    }

    showDialog(
      context: context,
      builder: (context) => AddEditMedicineDialog(
        medicine: med,
        onSave: (updated) {
          if (med == null) {
            ref.read(pharmacyDashboardProvider.notifier).addMedicine(updated);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Medicamento adicionado ao stock da farmácia com sucesso!'),
                backgroundColor: AppColors.primary,
              ),
            );
          } else {
            ref.read(pharmacyDashboardProvider.notifier).updateMedicine(updated);
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Medicamento atualizado no Supabase!'),
                backgroundColor: AppColors.primary,
              ),
            );
          }
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

    showDialog(
      context: context,
      builder: (context) => QrScannerDialog(
        onValidateCode: (code) async {
          return await ref.read(pharmacyDashboardProvider.notifier).validateQrCode(code);
        },
      ),
    );
  }

  void _showPaymentModal() {
    showDialog(
      context: context,
      builder: (context) => SubscriptionPaymentDialog(
        onSubmit: ({
          required paymentMethod,
          required referenceNumber,
          required proofUrl,
          notes,
        }) async {
          return await ref.read(pharmacyDashboardProvider.notifier).submitPaymentProof(
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
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        icon: const Icon(Icons.lock_rounded, size: 48, color: Colors.red),
        title: const Text('Acesso Bloqueado', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text(
          'A subscrição desta farmácia expirou (3 meses de teste concluídos). '
          'Para continuar a utilizar o painel, envie o comprovativo do pagamento de 15.000 Kz/mês.',
        ),
        actions: [
          TextButton(
            onPressed: () {
              Navigator.pop(context);
              context.push('/admin/subscriptions');
            },
            child: const Text('Painel Admin'),
          ),
          FilledButton.icon(
            icon: const Icon(Icons.upload_file_rounded),
            label: const Text('Pagar 15.000 Kz'),
            onPressed: () {
              Navigator.pop(context);
              _showPaymentModal();
            },
          ),
        ],
      ),
    );
  }

  void _showPharmacySwitcherModal() {
    final mockPharmacies = [
      PharmacyModel(
        id: 'pharm-1',
        name: 'Farmácia Mecofarma Talatona',
        province: 'Luanda',
        district: 'Talatona',
        address: 'Via AL15',
        phone: '923 100 200',
        subscriptionStatus: 'trial',
        trialEndsAt: DateTime.now().add(const Duration(days: 68)),
        paymentDueDate: DateTime.now().add(const Duration(days: 68)),
      ),
      PharmacyModel(
        id: 'pharm-2',
        name: 'Farmácia Sagrada Esperança',
        province: 'Luanda',
        district: 'Maianga',
        address: 'Avenida Lenine',
        phone: '912 300 400',
        subscriptionStatus: 'active',
        trialEndsAt: DateTime.now().subtract(const Duration(days: 30)),
        paymentDueDate: DateTime.now().add(const Duration(days: 22)),
      ),
      PharmacyModel(
        id: 'pharm-3',
        name: 'Farmácia Popular de Luanda',
        province: 'Luanda',
        district: 'Ingombota',
        address: 'Rua Rainha Ginga',
        phone: '924 555 777',
        subscriptionStatus: 'trial',
        trialEndsAt: DateTime.now().add(const Duration(days: 3)), // Expiring soon
        paymentDueDate: DateTime.now().add(const Duration(days: 3)),
      ),
      PharmacyModel(
        id: 'pharm-4',
        name: 'Farmácia Central Benguela',
        province: 'Benguela',
        district: 'Benguela Centro',
        address: 'Avenida 10 de Fevereiro',
        phone: '931 222 333',
        subscriptionStatus: 'expired',
        trialEndsAt: DateTime.now().subtract(const Duration(days: 10)),
        paymentDueDate: DateTime.now().subtract(const Duration(days: 10)),
      ),
      PharmacyModel(
        id: 'pharm-5',
        name: 'Farmácia Moderna Huambo',
        province: 'Huambo',
        district: 'Huambo Centro',
        address: 'Rua do Comércio',
        phone: '945 888 999',
        subscriptionStatus: 'blocked',
        trialEndsAt: DateTime.now().subtract(const Duration(days: 45)),
        paymentDueDate: DateTime.now().subtract(const Duration(days: 45)),
      ),
    ];

    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) {
        return Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Mudar Perfil da Farmácia (Testar Estados de Subscrição)',
                style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15),
              ),
              const SizedBox(height: 12),
              Expanded(
                child: ListView.builder(
                  shrinkWrap: true,
                  itemCount: mockPharmacies.length,
                  itemBuilder: (context, idx) {
                    final p = mockPharmacies[idx];
                    return ListTile(
                      leading: Icon(
                        p.subscriptionStatus == 'active'
                            ? Icons.check_circle_rounded
                            : (p.subscriptionStatus == 'trial'
                                ? Icons.timer_rounded
                                : Icons.lock_rounded),
                        color: p.subscriptionStatus == 'active'
                            ? Colors.green
                            : (p.subscriptionStatus == 'trial' ? Colors.blue : Colors.red),
                      ),
                      title: Text(p.name, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)),
                      subtitle: Text(
                        'Estado: ${p.subscriptionStatus.toUpperCase()} '
                        '${p.subscriptionStatus == 'trial' ? '(${p.daysLeftInTrial} dias de teste restantes)' : ''}',
                        style: const TextStyle(fontSize: 12),
                      ),
                      onTap: () {
                        ref.read(pharmacyDashboardProvider.notifier).switchPharmacy(p);
                        Navigator.pop(context);
                      },
                    );
                  },
                ),
              ),
            ],
          ),
        );
      },
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
            Row(
              children: [
                Flexible(
                  child: Text(
                    state.activePharmacyName ?? 'Painel da Farmácia',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.w900),
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
                IconButton(
                  icon: const Icon(Icons.swap_horiz_rounded, size: 20),
                  tooltip: 'Mudar Farmácia / Testar Estado',
                  onPressed: _showPharmacySwitcherModal,
                ),
              ],
            ),
            Text(
              'Subscrição: ${_getSubscriptionStatusBadge(state)}',
              style: const TextStyle(fontSize: 11, color: AppColors.textSecondaryLight),
            ),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.admin_panel_settings_rounded, color: AppColors.primary),
            tooltip: 'Painel Admin Subscrições',
            onPressed: () => context.push('/admin/subscriptions'),
          ),
          IconButton(
            icon: const Icon(Icons.qr_code_scanner_rounded, color: AppColors.primary),
            tooltip: 'Validar QR Code',
            onPressed: _showQrScannerModal,
          ),
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar Dados',
            onPressed: () {
              ref.read(pharmacyDashboardProvider.notifier).loadDashboardData();
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
            Tab(icon: Icon(Icons.analytics_rounded), text: 'Estatísticas'),
            Tab(icon: Icon(Icons.inventory_rounded), text: 'Medicamentos'),
            Tab(icon: Icon(Icons.bookmark_rounded), text: 'Reservas'),
            Tab(icon: Icon(Icons.assignment_turned_in_rounded), text: 'Receitas'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(
              children: [
                _buildSubscriptionBanner(state),
                Expanded(
                  child: state.isBlockedOrExpired
                      ? _buildBlockedOverlay(state)
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
            ),
      floatingActionButton: state.isBlockedOrExpired
          ? null
          : FloatingActionButton.extended(
              onPressed: () => _showAddEditMedicineModal(),
              backgroundColor: AppColors.primary,
              icon: const Icon(Icons.add_rounded, color: Colors.white),
              label: const Text('Novo Medicamento', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
            ),
    );
  }

  Widget _buildSubscriptionBanner(PharmacyDashboardState state) {
    final status = state.pharmacyDetails?.subscriptionStatus ?? 'trial';

    if (status == 'trial') {
      final days = state.daysLeftInTrial;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
        color: Colors.blue.shade50,
        child: Row(
          children: [
            const Icon(Icons.timer_outlined, color: Colors.blue, size: 22),
            const SizedBox(width: 10),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    'Período Experimental de 3 Meses: Restam $days dias',
                    style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 13, color: AppColors.primaryDark),
                  ),
                  const Text(
                    'Utilização gratuita para clientes e farmácia. Mensalidade: 15.000 Kz/mês após o teste.',
                    style: TextStyle(fontSize: 11, color: Colors.black87),
                  ),
                ],
              ),
            ),
            TextButton(
              onPressed: _showPaymentModal,
              child: const Text('Renovar Já', style: TextStyle(fontWeight: FontWeight.bold)),
            ),
          ],
        ),
      );
    } else if (status == 'active') {
      final days = state.daysUntilPaymentDue;
      return Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
        color: Colors.green.shade50,
        child: Row(
          children: [
            const Icon(Icons.verified_rounded, color: Colors.green, size: 20),
            const SizedBox(width: 8),
            Expanded(
              child: Text(
                'Subscrição Ativa (15.000 Kz/mês) • Próximo pagamento em $days dias',
                style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 12, color: Colors.green),
              ),
            ),
            OutlinedButton(
              onPressed: _showPaymentModal,
              style: OutlinedButton.styleFrom(
                minimumSize: const Size(80, 30),
                padding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              child: const Text('Renovar', style: TextStyle(fontSize: 11)),
            ),
          ],
        ),
      );
    }
    return const SizedBox.shrink();
  }

  Widget _buildBlockedOverlay(PharmacyDashboardState state) {
    return Container(
      padding: const EdgeInsets.all(24),
      color: Colors.red.shade50.withOpacity(0.5),
      child: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const Icon(Icons.lock_clock_rounded, size: 64, color: Colors.red),
            const SizedBox(height: 16),
            const Text(
              'Acesso ao Painel Suspenso',
              style: TextStyle(fontSize: 20, fontWeight: FontWeight.w900, color: Colors.red),
            ),
            const SizedBox(height: 8),
            const Text(
              'O seu período de teste gratuito de 3 meses expirou.\n'
              'Para desbloquear a gestão da farmácia e aprovação de reservas, efetue o pagamento da mensalidade de 15.000 Kz.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ),
            const SizedBox(height: 24),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                FilledButton.icon(
                  icon: const Icon(Icons.upload_file_rounded),
                  label: const Text('Enviar Comprovativo de 15.000 Kz'),
                  style: FilledButton.styleFrom(backgroundColor: AppColors.primary),
                  onPressed: _showPaymentModal,
                ),
                const SizedBox(width: 12),
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

  String _getSubscriptionStatusBadge(PharmacyDashboardState state) {
    final status = state.pharmacyDetails?.subscriptionStatus ?? 'trial';
    if (status == 'trial') return 'Trial Gratuito (${state.daysLeftInTrial}d)';
    if (status == 'active') return 'Ativo ✅';
    if (status == 'expired') return 'Expirado ⚠️';
    return 'Bloqueado 🔒';
  }

  // -------------------------------------------------------------
  // TAB 1: ESTATÍSTICAS E VISÃO GERAL
  // -------------------------------------------------------------
  Widget _buildStatsTab(PharmacyDashboardState state) {
    // Multipliers for stats filter
    double periodMultiplier = _selectedStatsPeriod == 'Dia' ? 1.0 : (_selectedStatsPeriod == 'Semana' ? 7.0 : 30.0);
    double estimatedRevenue = state.totalRevenue * periodMultiplier;
    int estimatedReservations = (state.completedReservationsCount * periodMultiplier).toInt();

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.between,
            children: [
              const Text(
                'Visão Geral do Desempenho',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900),
              ),
              SegmentedButton<String>(
                segments: const [
                  ButtonSegment(value: 'Dia', label: Text('Dia')),
                  ButtonSegment(value: 'Semana', label: Text('Semana')),
                  ButtonSegment(value: 'Mês', label: Text('Mês')),
                ],
                selected: {_selectedStatsPeriod},
                onSelectionChanged: (set) {
                  setState(() => _selectedStatsPeriod = set.first);
                },
              ),
            ],
          ),
          const SizedBox(height: 16),

          // Stat Cards Grid
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                title: 'Faturação (${_selectedStatsPeriod})',
                value: '${estimatedRevenue.toInt()} Kz',
                icon: Icons.payments_rounded,
                color: Colors.emerald.shade700,
                bgColor: Colors.emerald.shade50,
              ),
              _buildStatCard(
                title: 'Reservas Concluídas',
                value: '$estimatedReservations',
                icon: Icons.check_circle_rounded,
                color: Colors.blue.shade700,
                bgColor: Colors.blue.shade50,
              ),
              _buildStatCard(
                title: 'Itens em Stock',
                value: '${state.totalStockItems} un.',
                icon: Icons.inventory_2_rounded,
                color: Colors.amber.shade800,
                bgColor: Colors.amber.shade50,
              ),
              _buildStatCard(
                title: 'Receitas Pendentes',
                value: '${state.pendingPrescriptionsCount}',
                icon: Icons.assignment_late_rounded,
                color: Colors.purple.shade700,
                bgColor: Colors.purple.shade50,
              ),
            ],
          ),

          const SizedBox(height: 24),

          // Quick Action Banner
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              gradient: const LinearGradient(
                colors: [AppColors.primaryDark, AppColors.primary],
              ),
              borderRadius: BorderRadius.circular(16),
            ),
            child: Row(
              children: [
                const Icon(Icons.qr_code_2_rounded, color: Colors.white, size: 40),
                const SizedBox(width: 12),
                const Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Validação de Código do Cliente',
                        style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 16),
                      ),
                      Text(
                        'Digitalize o QR Code do cliente no momento do levantamento para concluir a reserva.',
                        style: TextStyle(color: Colors.white70, fontSize: 12),
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
                  child: const Text('Validar', style: TextStyle(fontWeight: FontWeight.bold)),
                ),
              ],
            ),
          ),

          const SizedBox(height: 24),

          const Text(
            'Atividade Recente',
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900),
          ),
          const SizedBox(height: 8),

          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: state.reservations.length > 3 ? 3 : state.reservations.length,
            itemBuilder: (context, index) {
              final res = state.reservations[index];
              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: res.status == 'completed' ? Colors.green.shade100 : Colors.blue.shade100,
                    child: Icon(
                      res.status == 'completed' ? Icons.check : Icons.bookmark,
                      color: res.status == 'completed' ? Colors.green : AppColors.primary,
                    ),
                  ),
                  title: Text(res.medicineName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text('Código: ${res.pickupCode} • ${res.totalPriceKz.toInt()} Kz'),
                  trailing: Text(
                    res.status == 'completed' ? 'Concluída' : 'Ativa',
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: res.status == 'completed' ? Colors.green : AppColors.primary,
                    ),
                  ),
                ),
              );
            },
          ),
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
        border: Border.all(color: color.withOpacity(0.2)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Icon(icon, color: color, size: 22),
            ],
          ),
          const Spacer(),
          Text(
            value,
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.w900, color: color),
          ),
          Text(
            title,
            style: TextStyle(fontSize: 11, color: color.withOpacity(0.8), fontWeight: FontWeight.w600),
          ),
        ],
      ),
    );
  }

  // -------------------------------------------------------------
  // TAB 2: MEDICAMENTOS & GESTÃO DE STOCK E PREÇOS
  // -------------------------------------------------------------
  Widget _buildMedicinesTab(PharmacyDashboardState state) {
    final filtered = state.medicines.where((m) {
      if (_searchQuery.isEmpty) return true;
      final q = _searchQuery.toLowerCase();
      return m.name.toLowerCase().contains(q) || m.activeIngredient.toLowerCase().contains(q);
    }).toList();

    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
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
            onChanged: (val) => setState(() => _searchQuery = val),
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final med = filtered[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: Padding(
                  padding: const EdgeInsets.all(12.0),
                  child: Column(
                    children: [
                      Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  med.name,
                                  style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                                ),
                                Text(
                                  med.activeIngredient,
                                  style: const TextStyle(fontSize: 12, color: AppColors.textSecondaryLight),
                                ),
                                const SizedBox(height: 4),
                                Row(
                                  children: [
                                    if (med.requiresPrescription)
                                      Container(
                                        margin: const EdgeInsets.only(right: 6),
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.amber.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Exige Receita',
                                          style: TextStyle(fontSize: 10, color: Colors.amber, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                    if (med.isGeneric)
                                      Container(
                                        padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                                        decoration: BoxDecoration(
                                          color: Colors.blue.shade100,
                                          borderRadius: BorderRadius.circular(6),
                                        ),
                                        child: const Text(
                                          'Genérico',
                                          style: TextStyle(fontSize: 10, color: Colors.blue, fontWeight: FontWeight.bold),
                                        ),
                                      ),
                                  ],
                                ),
                              ],
                            ),
                          ),
                          Column(
                            crossAxisAlignment: CrossAxisAlignment.end,
                            children: [
                              Text(
                                '${med.priceKz.toInt()} Kz',
                                style: const TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w900,
                                  color: AppColors.primaryDark,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Container(
                                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                                decoration: BoxDecoration(
                                  color: med.inStock ? AppColors.primaryLight : Colors.red.shade50,
                                  borderRadius: BorderRadius.circular(8),
                                ),
                                child: Text(
                                  'Stock: ${med.stockQuantity}',
                                  style: TextStyle(
                                    fontSize: 11,
                                    fontWeight: FontWeight.bold,
                                    color: med.inStock ? AppColors.primary : Colors.red,
                                  ),
                                ),
                              ),
                            ],
                          ),
                        ],
                      ),
                      const Divider(height: 20),

                      // Quick Real-Time Controls (Price & Stock)
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Row(
                            children: [
                              IconButton.outlined(
                                icon: const Icon(Icons.remove, size: 16),
                                tooltip: 'Reduzir Stock',
                                onPressed: med.stockQuantity > 0
                                    ? () {
                                        ref
                                            .read(pharmacyDashboardProvider.notifier)
                                            .updateStock(med.id, med.stockQuantity - 1);
                                      }
                                    : null,
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 8.0),
                                child: Text(
                                  '${med.stockQuantity}',
                                  style: const TextStyle(fontWeight: FontWeight.bold),
                                ),
                              ),
                              IconButton.outlined(
                                icon: const Icon(Icons.add, size: 16),
                                tooltip: 'Aumentar Stock',
                                onPressed: () {
                                  ref
                                      .read(pharmacyDashboardProvider.notifier)
                                      .updateStock(med.id, med.stockQuantity + 1);
                                },
                              ),
                            ],
                          ),
                          Row(
                            children: [
                              IconButton(
                                icon: const Icon(Icons.edit_outlined, color: AppColors.primary),
                                tooltip: 'Editar Detalhes',
                                onPressed: () => _showAddEditMedicineModal(med),
                              ),
                              IconButton(
                                icon: const Icon(Icons.delete_outline, color: Colors.red),
                                tooltip: 'Eliminar Medicamento',
                                onPressed: () {
                                  ref.read(pharmacyDashboardProvider.notifier).deleteMedicine(med.id);
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(content: Text('Medicamento removido do stock.')),
                                  );
                                },
                              ),
                            ],
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

  // -------------------------------------------------------------
  // TAB 3: RESERVAS & VALIDAÇÃO
  // -------------------------------------------------------------
  Widget _buildReservationsTab(PharmacyDashboardState state) {
    return Column(
      children: [
        Padding(
          padding: const EdgeInsets.all(16.0),
          child: Row(
            children: [
              Expanded(
                child: FilledButton.icon(
                  icon: const Icon(Icons.qr_code_scanner),
                  label: const Text('Validar QR Code de Levantamento'),
                  onPressed: _showQrScannerModal,
                ),
              ),
            ],
          ),
        ),
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: state.reservations.length,
            itemBuilder: (context, index) {
              final res = state.reservations[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  title: Text(res.medicineName, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Código: ${res.pickupCode} • Validade: 2 Horas'),
                      Text('Preço: ${res.totalPriceKz.toInt()} Kz'),
                    ],
                  ),
                  trailing: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
                    decoration: BoxDecoration(
                      color: res.status == 'completed' ? Colors.green.shade100 : Colors.amber.shade100,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      res.status == 'completed' ? 'Resgatado' : 'Aguardando',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.bold,
                        color: res.status == 'completed' ? Colors.green : Colors.amber.shade900,
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

  // -------------------------------------------------------------
  // TAB 4: APROVAÇÃO DE RECEITAS MÉDICAS
  // -------------------------------------------------------------
  Widget _buildPrescriptionsTab(PharmacyDashboardState state) {
    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.prescriptions.length,
      itemBuilder: (context, index) {
        final presc = state.prescriptions[index];
        final isVerified = presc.status == 'verified';
        final isRejected = presc.status == 'rejected';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    Text(
                      'Paciente: ${presc.userName}',
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: isVerified
                            ? Colors.green.shade100
                            : (isRejected ? Colors.red.shade100 : Colors.amber.shade100),
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Text(
                        isVerified ? 'Aprovada' : (isRejected ? 'Rejeitada' : 'Pendente'),
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.bold,
                          color: isVerified
                              ? Colors.green
                              : (isRejected ? Colors.red : Colors.amber.shade900),
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 4),
                Text('Medicamento Solicitado: ${presc.medicineName}'),
                Text('Data do Pedido: ${presc.createdAt}', style: const TextStyle(fontSize: 11, color: Colors.grey)),
                const SizedBox(height: 12),

                if (presc.notes != null && presc.notes!.isNotEmpty) ...[
                  Text('Obs: ${presc.notes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                  const SizedBox(height: 8),
                ],

                Row(
                  mainAxisAlignment: MainAxisAlignment.end,
                  children: [
                    OutlinedButton.icon(
                      icon: const Icon(Icons.remove_red_eye_rounded, size: 16),
                      label: const Text('Analisar Receita'),
                      onPressed: () {
                        showDialog(
                          context: context,
                          builder: (context) => PrescriptionReviewDialog(
                            prescription: presc,
                            onReview: (status, notes) {
                              ref
                                  .read(pharmacyDashboardProvider.notifier)
                                  .updatePrescription(presc.id, status, notes);
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(status == 'verified'
                                      ? 'Receita aprovada com sucesso!'
                                      : 'Receita rejeitada.'),
                                  backgroundColor: status == 'verified' ? Colors.green : Colors.red,
                                ),
                              );
                            },
                          ),
                        );
                      },
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }
}
