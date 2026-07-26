import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/constants/app_colors.dart';
import '../../../pharmacies/domain/pharmacy_model.dart';
import '../../../pharmacies/domain/pharmacy_payment_model.dart';
import '../providers/admin_subscription_provider.dart';
import '../providers/admin_reviews_provider.dart';
import '../widgets/admin_reviews_moderation_tab.dart';
import '../widgets/admin_reviews_analytics_tab.dart';

class AdminSubscriptionsScreen extends ConsumerStatefulWidget {
  const AdminSubscriptionsScreen({super.key});

  @override
  ConsumerState<AdminSubscriptionsScreen> createState() => _AdminSubscriptionsScreenState();
}

class _AdminSubscriptionsScreenState extends ConsumerState<AdminSubscriptionsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;
  String _selectedFilter = 'Todos'; // 'Todos', 'trial', 'active', 'expired', 'blocked'
  String _searchQuery = '';

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

  void _showChangeStatusDialog(PharmacyModel pharm) {
    String selectedStatus = pharm.subscriptionStatus;
    int extendMonths = 1;

    showDialog(
      context: context,
      builder: (context) {
        return StatefulBuilder(
          builder: (context, setModalState) {
            return AlertDialog(
              title: Text('Gerir Subscrição: ${pharm.name}'),
              content: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text('Estado da Subscrição:', style: TextStyle(fontWeight: FontWeight.bold)),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: selectedStatus,
                    items: const [
                      DropdownMenuItem(value: 'trial', child: Text('Trial Gratuito (3 Meses)')),
                      DropdownMenuItem(value: 'active', child: Text('Ativo (Mensalidade Paga)')),
                      DropdownMenuItem(value: 'expired', child: Text('Expirado (Aguarda Pagamento)')),
                      DropdownMenuItem(value: 'blocked', child: Text('Bloqueado (Acesso Suspenso)')),
                    ],
                    onChanged: (val) => setModalState(() => selectedStatus = val!),
                  ),
                  const SizedBox(height: 12),
                  if (selectedStatus == 'active') ...[
                    const Text('Período de Renovação:', style: TextStyle(fontWeight: FontWeight.bold)),
                    DropdownButtonFormField<int>(
                      value: extendMonths,
                      items: const [
                        DropdownMenuItem(value: 1, child: Text('1 Mês (15.000 Kz)')),
                        DropdownMenuItem(value: 3, child: Text('3 Meses (45.000 Kz)')),
                        DropdownMenuItem(value: 6, child: Text('6 Meses (90.000 Kz)')),
                        DropdownMenuItem(value: 12, child: Text('12 Meses (180.000 Kz)')),
                      ],
                      onChanged: (val) => setModalState(() => extendMonths = val!),
                    ),
                  ],
                ],
              ),
              actions: [
                TextButton(
                  onPressed: () => Navigator.pop(context),
                  child: const Text('Cancelar'),
                ),
                FilledButton(
                  onPressed: () async {
                    DateTime? newDueDate;
                    if (selectedStatus == 'active') {
                      newDueDate = DateTime.now().add(Duration(days: 30 * extendMonths));
                    } else if (selectedStatus == 'trial') {
                      newDueDate = DateTime.now().add(const Duration(days: 90));
                    }

                    await ref
                        .read(adminSubscriptionProvider.notifier)
                        .setPharmacyStatus(pharm.id, selectedStatus, customDueDate: newDueDate);

                    if (mounted) {
                      Navigator.pop(context);
                      ScaffoldMessenger.of(context).showSnackBar(
                        SnackBar(content: Text('Subscrição de ${pharm.name} atualizada!')),
                      );
                    }
                  },
                  child: const Text('Guardar Alterações'),
                ),
              ],
            );
          },
        );
      },
    );
  }

  void _showProofDialog(PharmacyPaymentModel pay) {
    int extendMonths = pay.periodMonths;

    showDialog(
      context: context,
      builder: (context) {
        return AlertDialog(
          title: Text('Validar Comprovativo: ${pay.pharmacyName}'),
          content: SingleChildScrollView(
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Valor: ${pay.amount.toInt()} Kz', style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.green)),
                Text('Método: ${pay.paymentMethod}'),
                Text('Referência: ${pay.referenceNumber ?? 'N/A'}'),
                if (pay.notes != null) Text('Obs: ${pay.notes}'),
                const SizedBox(height: 12),
                ClipRRect(
                  borderRadius: BorderRadius.circular(12),
                  child: Image.network(
                    pay.proofUrl ?? '',
                    height: 200,
                    width: double.infinity,
                    fit: BoxFit.cover,
                    errorBuilder: (context, error, stack) => Container(
                      height: 120,
                      color: Colors.grey.shade200,
                      child: const Center(child: Text('Comprovativo de transferência em anexo')),
                    ),
                  ),
                ),
              ],
            ),
          ),
          actions: [
            OutlinedButton(
              onPressed: () async {
                await ref
                    .read(adminSubscriptionProvider.notifier)
                    .rejectPayment(pay.id, 'Comprovativo inválido ou valor incorreto');
                if (mounted) Navigator.pop(context);
              },
              style: OutlinedButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Rejeitar'),
            ),
            FilledButton(
              onPressed: () async {
                await ref.read(adminSubscriptionProvider.notifier).approvePayment(
                      pay.id,
                      pay.pharmacyId,
                      extendMonths,
                    );
                if (mounted) Navigator.pop(context);
              },
              style: FilledButton.styleFrom(backgroundColor: Colors.green),
              child: const Text('Aprovar (Aprovar 15.000 Kz)'),
            ),
          ],
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(adminSubscriptionProvider);
    final reviewsState = ref.watch(adminReviewsProvider);
    final pendingModCount = reviewsState.pendingModerationReviews.length;

    return Scaffold(
      appBar: AppBar(
        title: const Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Painel Geral de Administração', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900)),
            Text('FarmaJá Angola 🇦🇴 • Subscrições & Moderação', style: TextStyle(fontSize: 11, color: AppColors.textSecondaryLight)),
          ],
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh_rounded),
            tooltip: 'Atualizar Dados',
            onPressed: () {
              ref.read(adminSubscriptionProvider.notifier).loadAdminData();
              ref.read(adminReviewsProvider.notifier).loadReviewsData();
            },
          ),
        ],
        bottom: TabBar(
          controller: _tabController,
          isScrollable: true,
          labelColor: AppColors.primary,
          unselectedLabelColor: Colors.grey,
          indicatorColor: AppColors.primary,
          tabs: [
            Tab(text: 'Farmácias (${state.totalPharmacies})'),
            Tab(
              child: Row(
                children: [
                  const Text('Pagamentos'),
                  if (state.pendingPaymentsCount > 0) ...[
                    const SizedBox(width: 6),
                    Badge(label: Text('${state.pendingPaymentsCount}')),
                  ],
                ],
              ),
            ),
            Tab(
              child: Row(
                children: [
                  const Text('Moderação'),
                  if (pendingModCount > 0) ...[
                    const SizedBox(width: 6),
                    Badge(
                      label: Text('$pendingModCount'),
                      backgroundColor: Colors.amber.shade900,
                    ),
                  ],
                ],
              ),
            ),
            const Tab(text: 'Relatório & Analytics 📊'),
          ],
        ),
      ),
      body: state.isLoading
          ? const Center(child: CircularProgressIndicator())
          : TabBarView(
              controller: _tabController,
              children: [
                _buildPharmaciesTab(state),
                _buildPaymentsTab(state),
                const AdminReviewsModerationTab(),
                const AdminReviewsAnalyticsTab(),
              ],
            ),
    );
  }

  Widget _buildPharmaciesTab(AdminSubscriptionState state) {
    final filtered = state.pharmacies.where((p) {
      if (_selectedFilter != 'Todos' && p.subscriptionStatus != _selectedFilter) {
        return false;
      }
      if (_searchQuery.isNotEmpty) {
        final q = _searchQuery.toLowerCase();
        return p.name.toLowerCase().contains(q) || p.province.toLowerCase().contains(q);
      }
      return true;
    }).toList();

    return Column(
      children: [
        // KPI Summary Bar
        Container(
          padding: const EdgeInsets.all(12),
          color: Colors.grey.shade50,
          child: Row(
            children: [
              _buildKpiChip('Trial (3M)', state.trialCount, Colors.blue),
              const SizedBox(width: 8),
              _buildKpiChip('Ativos', state.activeCount, Colors.green),
              const SizedBox(width: 8),
              _buildKpiChip('Expirados', state.expiredCount, Colors.amber.shade800),
              const SizedBox(width: 8),
              _buildKpiChip('Bloqueados', state.blockedCount, Colors.red),
            ],
          ),
        ),

        // Filter chips and Search
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 8.0),
          child: Column(
            children: [
              TextField(
                decoration: InputDecoration(
                  hintText: 'Pesquisar farmácia por nome ou província...',
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
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    FilterChip(
                      label: const Text('Todos'),
                      selected: _selectedFilter == 'Todos',
                      onSelected: (_) => setState(() => _selectedFilter = 'Todos'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Trial Gratuito (3M)'),
                      selected: _selectedFilter == 'trial',
                      onSelected: (_) => setState(() => _selectedFilter = 'trial'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Ativos (15.000 Kz)'),
                      selected: _selectedFilter == 'active',
                      onSelected: (_) => setState(() => _selectedFilter = 'active'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Expirados'),
                      selected: _selectedFilter == 'expired',
                      onSelected: (_) => setState(() => _selectedFilter = 'expired'),
                    ),
                    const SizedBox(width: 8),
                    FilterChip(
                      label: const Text('Bloqueados'),
                      selected: _selectedFilter == 'blocked',
                      onSelected: (_) => setState(() => _selectedFilter = 'blocked'),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),

        // Pharmacies list
        Expanded(
          child: ListView.builder(
            padding: const EdgeInsets.symmetric(horizontal: 16),
            itemCount: filtered.length,
            itemBuilder: (context, index) {
              final pharm = filtered[index];
              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: _getStatusColor(pharm.subscriptionStatus).withOpacity(0.15),
                    child: Icon(
                      _getStatusIcon(pharm.subscriptionStatus),
                      color: _getStatusColor(pharm.subscriptionStatus),
                    ),
                  ),
                  title: Text(pharm.name, style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('${pharm.province} • ${pharm.district}'),
                      if (pharm.subscriptionStatus == 'trial')
                        Text('Trial de 3 Meses: Restam ${pharm.daysLeftInTrial} dias',
                            style: const TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold))
                      else if (pharm.subscriptionStatus == 'active')
                        Text('Próximo Pagamento: em ${pharm.daysUntilPaymentDue} dias (15.000 Kz/mês)',
                            style: const TextStyle(fontSize: 12, color: Colors.green, fontWeight: FontWeight.bold))
                      else
                        Text('Subscrição Expirada / Acesso Suspenso',
                            style: const TextStyle(fontSize: 12, color: Colors.red, fontWeight: FontWeight.bold)),
                    ],
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: _getStatusColor(pharm.subscriptionStatus).withOpacity(0.15),
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          _getStatusLabel(pharm.subscriptionStatus),
                          style: TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.bold,
                            color: _getStatusColor(pharm.subscriptionStatus),
                          ),
                        ),
                      ),
                      IconButton(
                        icon: const Icon(Icons.edit_note_rounded, color: AppColors.primary),
                        tooltip: 'Gerir Subscrição',
                        onPressed: () => _showChangeStatusDialog(pharm),
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

  Widget _buildPaymentsTab(AdminSubscriptionState state) {
    if (state.payments.isEmpty) {
      return const Center(
        child: Text('Nenhum comprovativo de pagamento registado.'),
      );
    }

    return ListView.builder(
      padding: const EdgeInsets.all(16),
      itemCount: state.payments.length,
      itemBuilder: (context, index) {
        final pay = state.payments[index];
        final isPending = pay.status == 'pending';
        final isApproved = pay.status == 'approved';

        return Card(
          margin: const EdgeInsets.only(bottom: 12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  mainAxisAlignment: MainAxisAlignment.between,
                  children: [
                    Text(pay.pharmacyName, style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    Chip(
                      label: Text(
                        isApproved ? 'Aprovado' : (isPending ? 'Pendente' : 'Rejeitado'),
                        style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold, fontSize: 11),
                      ),
                      backgroundColor: isApproved ? Colors.green : (isPending ? Colors.amber.shade900 : Colors.red),
                    ),
                  ],
                ),
                Text('Valor: ${pay.amount.toInt()} Kz (Mensalidade)', style: const TextStyle(color: Colors.green, fontWeight: FontWeight.bold)),
                Text('Método: ${pay.paymentMethod}'),
                Text('Referência: ${pay.referenceNumber ?? 'N/A'}'),
                if (pay.notes != null) Text('Obs: ${pay.notes}', style: const TextStyle(fontSize: 12, fontStyle: FontStyle.italic)),
                const SizedBox(height: 12),

                if (isPending)
                  Align(
                    alignment: Alignment.centerRight,
                    child: FilledButton.icon(
                      icon: const Icon(Icons.fact_check_rounded),
                      label: const Text('Analisar & Aprovar Pagamento'),
                      onPressed: () => _showProofDialog(pay),
                    ),
                  ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildKpiChip(String label, int count, Color color) {
    return Expanded(
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
        decoration: BoxDecoration(
          color: color.withOpacity(0.12),
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: color.withOpacity(0.3)),
        ),
        child: Column(
          children: [
            Text('$count', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w900, color: color)),
            Text(label, style: TextStyle(fontSize: 10, fontWeight: FontWeight.bold, color: color.withOpacity(0.8))),
          ],
        ),
      ),
    );
  }

  Color _getStatusColor(String status) {
    switch (status) {
      case 'active':
        return Colors.green;
      case 'trial':
        return Colors.blue;
      case 'expired':
        return Colors.amber.shade900;
      case 'blocked':
        return Colors.red;
      default:
        return Colors.grey;
    }
  }

  IconData _getStatusIcon(String status) {
    switch (status) {
      case 'active':
        return Icons.verified_rounded;
      case 'trial':
        return Icons.timer_rounded;
      case 'expired':
        return Icons.warning_rounded;
      case 'blocked':
        return Icons.lock_rounded;
      default:
        return Icons.help_outline;
    }
  }

  String _getStatusLabel(String status) {
    switch (status) {
      case 'active':
        return 'Ativo';
      case 'trial':
        return 'Trial 3M';
      case 'expired':
        return 'Expirado';
      case 'blocked':
        return 'Bloqueado';
      default:
        return status;
    }
  }
}
