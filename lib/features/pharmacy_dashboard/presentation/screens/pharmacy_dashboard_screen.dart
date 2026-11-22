import 'dart:math' as math;

import 'package:flutter/material.dart';
import 'package:flutter_animate/flutter_animate.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:icons_plus/icons_plus.dart' show Iconsax;
import 'package:flutter_lucide/flutter_lucide.dart';

import '../../../../core/constants/app_colors.dart';
import '../../../auth/presentation/providers/auth_provider.dart';
import '../../../medicines/domain/medicine_model.dart';
import '../../../reservations/domain/reservation_model.dart';
import '../providers/pharmacy_dashboard_provider.dart';
import 'pharmacy_profile_screen.dart';
import '../widgets/add_edit_medicine_dialog.dart';
import '../widgets/qr_scanner_dialog.dart';
import '../widgets/prescription_review_dialog.dart';
import '../widgets/subscription_payment_dialog.dart';

// ---------------------------------------------------------------------------
// Recursos gráficos
// ---------------------------------------------------------------------------
// Nomes exactamente como estão na pasta assets/images do repositório.
const String _kHeroPhoto = 'assets/images/farmacia_destaquec.jpg';
const String _kHealthIllustration = 'assets/images/Ilustração_3d_saude.jpg';

// Profissional de farmácia.
// Se o ficheiro não existir, o errorBuilder esconde a imagem sem partir o ecrã.
const String _kProfessional = 'assets/images/esmy_foto.jpg';

// ---------------------------------------------------------------------------
// Dicionário oficial de ícones
// ---------------------------------------------------------------------------
const Color _kYellow = Color(0xFFF59E0B);
const Color _kOrange = Color(0xFFF97316);
final Color _kBlue = Colors.blue.shade700;
const Color _kGreen = AppColors.primary;

/// Animação de entrada em cascata (fade + subida suave).
extension _Cascade on Widget {
  Widget cascade(int index, {int stepMs = 60}) {
    return Animate(
      delay: (stepMs * math.min(index, 8)).ms,
      effects: [
        FadeEffect(duration: 380.ms, curve: Curves.easeOut),
        SlideEffect(
          begin: const Offset(0, 0.08),
          end: Offset.zero,
          duration: 380.ms,
          curve: Curves.easeOutCubic,
        ),
      ],
      child: this,
    );
  }
}

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
  bool _isSigningOut = false;

  int _lastTabIndex = 0;

  final Set<String> _processingReservations = {};

  @override
  void initState() {
    super.initState();

    _tabController = TabController(length: 5, vsync: this);
    _tabController.addListener(_handleTabChange);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (mounted) {
        ref.read(pharmacyDashboardProvider.notifier).loadDashboardData();
      }
    });
  }

  void _handleTabChange() {
    if (_tabController.index == _lastTabIndex) return;

    _lastTabIndex = _tabController.index;

    if (_tabController.index == 2) {
      ref
          .read(pharmacyDashboardProvider.notifier)
          .markReservationNotificationsAsRead();
    }
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabChange);
    _tabController.dispose();
    super.dispose();
  }

  void _showMessage(String message, {bool isError = false}) {
    if (!mounted) return;

    ScaffoldMessenger.of(context)
      ..hideCurrentSnackBar()
      ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          content: Text(message),
          backgroundColor:
              isError ? Colors.red.shade700 : AppColors.primary,
        ),
      );
  }

  Future<void> _confirmAndSignOut() async {
    if (_isSigningOut) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(Icons.logout_rounded),
        title: const Text('Terminar sessão?'),
        content: const Text(
          'Queres sair da conta desta farmácia neste dispositivo?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton.icon(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            icon: const Icon(Icons.logout_rounded),
            label: const Text('Terminar sessão'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _isSigningOut = true);

    try {
      await ref.read(authProvider.notifier).logout();

      if (!mounted) return;

      final authState = ref.read(authProvider);

      if (authState.user == null) {
        context.go('/login');
      } else {
        _showMessage(
          authState.error ??
              'Não foi possível terminar a sessão. Tenta novamente.',
          isError: true,
        );
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Não foi possível terminar a sessão. Tenta novamente. Detalhe: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSigningOut = false);
      }
    }
  }

  Future<bool> _runOperation(
    Future<dynamic> Function() operation, {
    required String successMessage,
    required String failureMessage,
  }) async {
    try {
      final result = await operation();

      if (!mounted) return false;

      final success = result == true ||
          (result is String && result.trim().isNotEmpty);

      if (success) {
        _showMessage(successMessage);
        return true;
      }

      _showMessage(failureMessage, isError: true);
      return false;
    } catch (e) {
      if (!mounted) return false;

      _showMessage('$failureMessage Detalhe: $e', isError: true);
      return false;
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
      barrierDismissible: false,
      builder: (dialogContext) => AddEditMedicineDialog(
        medicine: medicine,
        onSave: (updated, image) async {
          final success = medicine == null
              ? await ref
                  .read(pharmacyDashboardProvider.notifier)
                  .addMedicine(updated, image: image)
              : await ref
                  .read(pharmacyDashboardProvider.notifier)
                  .updateMedicine(updated, image: image);

          if (!mounted) return;

          if (!success) {
            throw Exception(
              'Não foi possível guardar o medicamento. '
              'Verifica os dados e as permissões.',
            );
          }

          _showMessage(
            medicine == null
                ? 'Medicamento adicionado com sucesso.'
                : 'Medicamento actualizado com sucesso.',
          );
        },
      ),
    );
  }

  Future<void> _showQrScannerModal() async {
    final state = ref.read(pharmacyDashboardProvider);

    if (state.isBlockedOrExpired) {
      _showBlockedDialog();
      return;
    }

    await showDialog<void>(
      context: context,
      builder: (dialogContext) => QrScannerDialog(
        onValidateCode: (code) async {
          return await ref
              .read(pharmacyDashboardProvider.notifier)
              .validateQrCode(code);
        },
      ),
    );

    if (!mounted) return;

    await ref.read(pharmacyDashboardProvider.notifier).loadDashboardData();
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
            onPressed: () => Navigator.of(dialogContext).pop(),
            child: const Text('Fechar'),
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

  Future<void> _confirmPhysicalDelivery(dynamic reservation) async {
    final reservationId = reservation.id as String;

    if (_processingReservations.contains(reservationId)) return;

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: const Icon(
          Icons.inventory_2_rounded,
          color: AppColors.primary,
          size: 40,
        ),
        title: const Text('Confirmar entrega'),
        content: const Text(
          'Confirma apenas se o medicamento já foi entregue fisicamente '
          'ao cliente. Esta operação concluirá a reserva.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            child: const Text('Confirmar entrega'),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) return;

    setState(() => _processingReservations.add(reservationId));

    try {
      await ref
          .read(pharmacyDashboardProvider.notifier)
          .confirmarLevantamento(reservationId);

      await ref.read(pharmacyDashboardProvider.notifier).loadDashboardData();

      if (mounted) {
        _showMessage('Entrega confirmada. Reserva concluída.');
      }
    } catch (e) {
      if (mounted) {
        _showMessage(
          'Não foi possível confirmar a entrega. Detalhe: $e',
          isError: true,
        );
      }
    } finally {
      if (mounted) {
        setState(() => _processingReservations.remove(reservationId));
      }
    }
  }

  // -------------------------------------------------------------------------
  // Componentes visuais partilhados
  // -------------------------------------------------------------------------

  Widget _countBadge(int count, {required Widget child}) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        child,
        if (count > 0)
          Positioned(
            right: -11,
            top: -7,
            child: Container(
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              padding: const EdgeInsets.symmetric(
                horizontal: 4,
                vertical: 2,
              ),
              decoration: BoxDecoration(
                color: Colors.red.shade700,
                borderRadius: BorderRadius.circular(20),
                border: Border.all(color: Colors.white, width: 1.5),
              ),
              alignment: Alignment.center,
              child: Text(
                count > 99 ? '99+' : '$count',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 10,
                  fontWeight: FontWeight.w900,
                ),
              ),
            ),
          ),
      ],
    );
  }

  Widget _buildReservationsTabIcon(int unreadCount) {
    return _countBadge(
      unreadCount,
      child: const Icon(Iconsax.calendar_tick_bold),
    );
  }

  /// Estado vazio com a ilustração 3D. Se o ficheiro faltar, mostra só o texto.
  Widget _buildEmptyState(String message) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              _kHealthIllustration,
              height: 150,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ).cascade(0),
            const SizedBox(height: 12),
            Text(
              message,
              textAlign: TextAlign.center,
              style: const TextStyle(fontWeight: FontWeight.w600),
            ).cascade(1),
          ],
        ),
      ),
    );
  }

  /// Cabeçalho com fotografia, profissional (PNG transparente) e nome da farmácia.
  Widget _buildHero(PharmacyDashboardState state) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(24),
      child: SizedBox(
        height: 172,
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              _kHeroPhoto,
              fit: BoxFit.cover,
              errorBuilder: (_, __, ___) => const DecoratedBox(
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    colors: [AppColors.primaryDark, AppColors.primary],
                  ),
                ),
              ),
            ),
            DecoratedBox(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [
                    AppColors.primaryDark.withValues(alpha: 0.92),
                    AppColors.primaryDark.withValues(alpha: 0.35),
                  ],
                ),
              ),
            ),
            Positioned(
              right: 0,
              bottom: 0,
              height: 160,
              // A foto é JPG (sem transparência): esbatemos a borda esquerda
              // para se fundir com o cabeçalho.
              child: ShaderMask(
                blendMode: BlendMode.dstIn,
                shaderCallback: (rect) => const LinearGradient(
                  begin: Alignment.centerLeft,
                  end: Alignment.centerRight,
                  colors: [Colors.transparent, Colors.black],
                  stops: [0.0, 0.45],
                ).createShader(rect),
                child: Image.asset(
                  _kProfessional,
                  fit: BoxFit.contain,
                  alignment: Alignment.bottomRight,
                  errorBuilder: (_, __, ___) => const SizedBox.shrink(),
                ),
              ),
            ),
            Padding(
              padding: const EdgeInsets.all(18),
              child: Align(
                alignment: Alignment.centerLeft,
                child: FractionallySizedBox(
                  widthFactor: 0.62,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Container(
                        padding: const EdgeInsets.all(8),
                        decoration: const BoxDecoration(
                          color: Colors.white,
                          shape: BoxShape.circle,
                        ),
                        child: const Icon(
                          Iconsax.shop_bold,
                          color: _kGreen,
                          size: 20,
                        ),
                      ),
                      const SizedBox(height: 10),
                      Text(
                        state.activePharmacyName ?? 'Painel da Farmácia',
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: const TextStyle(
                          color: Colors.white,
                          fontSize: 20,
                          fontWeight: FontWeight.w800,
                          height: 1.15,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Subscrição: ${_getSubscriptionStatusBadge(state)}',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontSize: 12,
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  // -------------------------------------------------------------------------
  // Build
  // -------------------------------------------------------------------------

  @override
  Widget build(BuildContext context) {
    final state = ref.watch(pharmacyDashboardProvider);

    // Material 3 + Plus Jakarta Sans aplicados a todo o ecrã e aos diálogos
    // abertos a partir dele.
    final base = Theme.of(context);
    final theme = base.copyWith(
      useMaterial3: true,
      textTheme: GoogleFonts.plusJakartaSansTextTheme(base.textTheme),
      primaryTextTheme:
          GoogleFonts.plusJakartaSansTextTheme(base.primaryTextTheme),
    );

    return Theme(
      data: theme,
      child: Scaffold(
        appBar: AppBar(
          title: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                state.activePharmacyName ?? 'Painel da Farmácia',
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
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
              tooltip: 'Notificações de reservas',
              icon: _countBadge(
                state.unreadReservationsCount,
                child: const Icon(LucideIcons.bell),
              ),
              onPressed: () => _tabController.animateTo(2),
            ),
            IconButton(
              icon: _isSigningOut
                  ? const SizedBox(
                      width: 20,
                      height: 20,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Icon(
                      Icons.logout_rounded,
                      color: AppColors.primary,
                    ),
              tooltip: 'Terminar sessão',
              onPressed: _isSigningOut ? null : _confirmAndSignOut,
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
            labelStyle: const TextStyle(fontWeight: FontWeight.w700),
            tabs: [
              const Tab(
                icon: Icon(LucideIcons.activity),
                text: 'Estatísticas',
              ),
              const Tab(
                icon: Icon(LucideIcons.pill),
                text: 'Medicamentos',
              ),
              Tab(
                icon: _buildReservationsTabIcon(
                  state.unreadReservationsCount,
                ),
                text: 'Reservas',
              ),
              const Tab(
                icon: Icon(Iconsax.document_text_bold),
                text: 'Receitas',
              ),
              const Tab(
                icon: Icon(Iconsax.shop_bold),
                text: 'Perfil',
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
              ).animate().fadeIn(delay: 500.ms).scale(
                    begin: const Offset(0.85, 0.85),
                    curve: Curves.easeOutBack,
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
              ).cascade(0),
              const SizedBox(height: 12),
              const Text(
                'Não foi possível carregar o painel',
                textAlign: TextAlign.center,
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.bold,
                ),
              ).cascade(1),
              const SizedBox(height: 8),
              Text(state.error!, textAlign: TextAlign.center).cascade(2),
              const SizedBox(height: 16),
              FilledButton.icon(
                onPressed: () {
                  ref
                      .read(pharmacyDashboardProvider.notifier)
                      .loadDashboardData();
                },
                icon: const Icon(Icons.refresh_rounded),
                label: const Text('Tentar novamente'),
              ).cascade(3),
            ],
          ),
        ),
      );
    }

    return Column(
      children: [
        _buildSubscriptionBanner(state),
        Expanded(
          child: TabBarView(
            controller: _tabController,
            children: [
              if (state.isBlockedOrExpired)
                _buildBlockedOverlay()
              else
                _buildStatsTab(state),
              if (state.isBlockedOrExpired)
                _buildBlockedOverlay()
              else
                _buildMedicinesTab(state),
              if (state.isBlockedOrExpired)
                _buildBlockedOverlay()
              else
                _buildReservationsTab(state),
              if (state.isBlockedOrExpired)
                _buildBlockedOverlay()
              else
                _buildPrescriptionsTab(state),
              const PharmacyProfileScreen(),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildSubscriptionBanner(PharmacyDashboardState state) {
    final status = state.pharmacyDetails?.subscriptionStatus ?? 'trial';

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
            const Icon(Iconsax.clock_bold, color: _kOrange),
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
      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.3, end: 0);
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
            const Icon(Icons.verified_rounded, color: Colors.green),
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
      ).animate().fadeIn(duration: 300.ms).slideY(begin: -0.3, end: 0);
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
            ).cascade(0),
            const SizedBox(height: 16),
            const Text(
              'Acesso ao painel suspenso',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w800,
                color: Colors.red,
              ),
            ).cascade(1),
            const SizedBox(height: 8),
            const Text(
              'O acesso à gestão está bloqueado. '
              'Contacta o administrador para confirmar o estado da conta.',
              textAlign: TextAlign.center,
              style: TextStyle(fontSize: 13, color: Colors.black87),
            ).cascade(2),
            const SizedBox(height: 24),
            FilledButton.icon(
              icon: const Icon(Icons.upload_file_rounded),
              label: const Text('Enviar comprovativo'),
              onPressed: _showPaymentModal,
            ).cascade(3),
          ],
        ),
      ),
    );
  }

  String _getSubscriptionStatusBadge(
    PharmacyDashboardState state,
  ) {
    final status =
        state.pharmacyDetails?.subscriptionStatus.trim().toLowerCase() ??
            'unknown';

    if (status == 'trial') {
      return 'Período experimental (${state.daysLeftInTrial}d)';
    }
    if (status == 'active') return 'Activa';
    if (status == 'expired') return 'Expirada';
    if (status == 'blocked') return 'Bloqueada';

    return 'Estado não confirmado';
  }

  String _getReservationStatusLabel(String status) {
    switch (status.trim().toLowerCase()) {
      case 'levantada':
      case 'completed':
      case 'resgatado':
      case 'entregue':
        return 'Levantada';

      case 'pago':
      case 'paid':
        return 'Pago';

      case 'expirada':
      case 'expired':
        return 'Expirada';

      default:
        return 'Aguardando confirmação';
    }
  }

  bool _isCompleted(String status) {
    return _getReservationStatusLabel(status) == 'Levantada';
  }

  DateTime? _getFinalPaymentConfirmationDate(
    ReservationModel reservation,
  ) {
    final clientConfirmation = reservation.clienteConfirmouPagamentoEm;
    final pharmacyConfirmation = reservation.farmaciaConfirmouPagamentoEm;

    // A confirmação final exige a confirmação das duas partes.
    if (clientConfirmation == null || pharmacyConfirmation == null) {
      return null;
    }

    final clientLocal = clientConfirmation.toLocal();
    final pharmacyLocal = pharmacyConfirmation.toLocal();

    return clientLocal.isAfter(pharmacyLocal) ? clientLocal : pharmacyLocal;
  }

  DateTime _getStatsPeriodStart(DateTime now) {
    final today = DateTime(now.year, now.month, now.day);

    switch (_selectedStatsPeriod) {
      case 'Semana':
        return today.subtract(Duration(days: today.weekday - 1));
      case 'Mês':
        return DateTime(now.year, now.month, 1);
      case 'Dia':
      default:
        return today;
    }
  }

  DateTime _getStatsPeriodEnd(DateTime start) {
    switch (_selectedStatsPeriod) {
      case 'Semana':
        return start.add(const Duration(days: 7));
      case 'Mês':
        return DateTime(start.year, start.month + 1, 1);
      case 'Dia':
      default:
        return start.add(const Duration(days: 1));
    }
  }

  // -------------------------------------------------------------------------
  // Estatísticas
  // -------------------------------------------------------------------------

  Widget _buildStatsTab(PharmacyDashboardState state) {
    final now = DateTime.now();
    final periodStart = _getStatsPeriodStart(now);
    final periodEnd = _getStatsPeriodEnd(periodStart);

    final completedReservationsInPeriod =
        state.reservations.where((reservation) {
      if (!_isCompleted(reservation.status)) return false;

      final paymentConfirmedAt =
          _getFinalPaymentConfirmationDate(reservation);

      if (paymentConfirmedAt == null) return false;

      return !paymentConfirmedAt.isBefore(periodStart) &&
          paymentConfirmedAt.isBefore(periodEnd);
    }).toList();

    final revenueInPeriod = completedReservationsInPeriod.fold<double>(
      0,
      (total, reservation) => total + reservation.totalPriceKz,
    );

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          _buildHero(state).cascade(0),
          const SizedBox(height: 20),
          const Text(
            'Visão geral do desempenho',
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w800,
            ),
          ).cascade(1),
          const SizedBox(height: 12),
          SegmentedButton<String>(
            segments: const [
              ButtonSegment(value: 'Dia', label: Text('Dia')),
              ButtonSegment(value: 'Semana', label: Text('Semana')),
              ButtonSegment(value: 'Mês', label: Text('Mês')),
            ],
            selected: {_selectedStatsPeriod},
            onSelectionChanged: (selection) {
              setState(() => _selectedStatsPeriod = selection.first);
            },
          ).cascade(2),
          const SizedBox(height: 16),
          GridView.count(
            crossAxisCount: MediaQuery.of(context).size.width > 600 ? 4 : 2,
            crossAxisSpacing: 12,
            mainAxisSpacing: 12,
            childAspectRatio: 1.4,
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            children: [
              _buildStatCard(
                title: 'Faturação confirmada',
                value: '${revenueInPeriod.toInt()} Kz',
                icon: Icons.payments_rounded,
                color: Colors.green.shade700,
                bgColor: Colors.green.shade50,
              ).cascade(3),
              _buildStatCard(
                title: 'Reservas concluídas',
                value: '${completedReservationsInPeriod.length}',
                icon: Iconsax.calendar_tick_bold,
                color: _kGreen,
                bgColor: Colors.green.shade50,
              ).cascade(4),
              _buildStatCard(
                title: 'Itens em stock',
                value: '${state.totalStockItems}',
                icon: LucideIcons.pill,
                color: _kBlue,
                bgColor: Colors.blue.shade50,
              ).cascade(5),
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
              borderRadius: BorderRadius.circular(20),
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
          ).cascade(6),
          const SizedBox(height: 24),
          const Text(
            'Actividade recente',
            style: TextStyle(
              fontSize: 16,
              fontWeight: FontWeight.w800,
            ),
          ).cascade(7),
          const SizedBox(height: 8),
          if (state.reservations.isEmpty)
            SizedBox(
              width: double.infinity,
              child: _buildEmptyState(
                'Ainda não existem reservas para apresentar.',
              ),
            )
          else
            ...state.reservations.take(3).toList().asMap().entries.map((entry) {
              final reservation = entry.value;
              final label = _getReservationStatusLabel(reservation.status);
              final completed = label == 'Levantada';
              final paid = label == 'Pago';
              final expired = label == 'Expirada';

              final color = completed || paid
                  ? Colors.green
                  : expired
                      ? Colors.red
                      : AppColors.primary;

              return Card(
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor: color.withValues(alpha: 0.12),
                    child: Icon(
                      completed
                          ? Icons.check
                          : paid
                              ? Icons.payments
                              : expired
                                  ? Icons.timer_off
                                  : Iconsax.calendar_tick_bold,
                      color: color,
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
                    label,
                    style: TextStyle(
                      fontWeight: FontWeight.bold,
                      color: color,
                    ),
                  ),
                ),
              ).cascade(8 + entry.key);
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
        borderRadius: BorderRadius.circular(20),
        border: Border.all(color: color.withValues(alpha: 0.2)),
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
              fontWeight: FontWeight.w800,
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

  // -------------------------------------------------------------------------
  // Medicamentos
  // -------------------------------------------------------------------------

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
              prefixIcon: const Icon(LucideIcons.search),
              suffixIcon: _searchQuery.isNotEmpty
                  ? IconButton(
                      icon: const Icon(Icons.clear),
                      onPressed: () => setState(() => _searchQuery = ''),
                    )
                  : null,
            ),
            onChanged: (value) {
              setState(() => _searchQuery = value);
            },
          ).cascade(0),
        ),
        Expanded(
          child: filtered.isEmpty
              ? _buildEmptyState('Não existem medicamentos para apresentar.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
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
                                Container(
                                  padding: const EdgeInsets.all(10),
                                  decoration: BoxDecoration(
                                    color: Colors.blue.shade50,
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Icon(
                                    LucideIcons.pill,
                                    color: _kBlue,
                                    size: 20,
                                  ),
                                ),
                                const SizedBox(width: 12),
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
                                        fontWeight: FontWeight.w800,
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
                                            successMessage:
                                                'Stock actualizado.',
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
                                            pharmacyDashboardProvider
                                                .notifier,
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
                    ).cascade(index);
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
      padding: const EdgeInsets.symmetric(
        horizontal: 6,
        vertical: 2,
      ),
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

  Future<void> _confirmDeleteMedicine(
    MedicineModel medicine,
  ) async {
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

  // -------------------------------------------------------------------------
  // Reservas
  // -------------------------------------------------------------------------

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
          ).cascade(0),
        ),
        Expanded(
          child: state.reservations.isEmpty
              ? _buildEmptyState('Ainda não existem reservas.')
              : ListView.builder(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 96),
                  itemCount: state.reservations.length,
                  itemBuilder: (context, index) {
                    final reservation = state.reservations[index];

                    final label = _getReservationStatusLabel(
                      reservation.status,
                    );

                    final completed = label == 'Levantada';
                    final paid = label == 'Pago';
                    final expired = label == 'Expirada';

                    final clientConfirmed =
                        reservation.clienteConfirmouPagamentoEm != null;

                    final qrValidated = reservation.qrValidadoEm != null;

                    // A entrega depende apenas do pagamento confirmado
                    // pelo cliente e da validação prévia do QR Code.
                    final canConfirmDelivery =
                        paid && clientConfirmed && qrValidated;

                    final isProcessing = _processingReservations.contains(
                      reservation.id,
                    );

                    final statusColor = completed || paid
                        ? Colors.green
                        : expired
                            ? Colors.red
                            : Colors.amber.shade800;

                    return Card(
                      margin: const EdgeInsets.only(bottom: 12),
                      child: Padding(
                        padding: const EdgeInsets.all(14),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Row(
                              children: [
                                Expanded(
                                  child: Text(
                                    reservation.medicineName,
                                    style: const TextStyle(
                                      fontWeight: FontWeight.bold,
                                      fontSize: 16,
                                    ),
                                  ),
                                ),
                                Container(
                                  padding: const EdgeInsets.symmetric(
                                    horizontal: 10,
                                    vertical: 5,
                                  ),
                                  decoration: BoxDecoration(
                                    color: statusColor.withValues(
                                      alpha: 0.12,
                                    ),
                                    borderRadius: BorderRadius.circular(12),
                                  ),
                                  child: Text(
                                    label,
                                    style: TextStyle(
                                      fontSize: 11,
                                      fontWeight: FontWeight.bold,
                                      color: statusColor,
                                    ),
                                  ),
                                ),
                              ],
                            ),
                            const SizedBox(height: 8),
                            Text('Código: ${reservation.pickupCode}'),
                            Text(
                              'Preço: ${reservation.totalPriceKz.toInt()} Kz',
                            ),
                            const SizedBox(height: 2),
                            const Row(
                              children: [
                                Icon(
                                  Iconsax.clock_bold,
                                  size: 16,
                                  color: _kOrange,
                                ),
                                SizedBox(width: 6),
                                Text('Prazo de levantamento: 2 horas'),
                              ],
                            ),
                            if (!expired) ...[
                              const Divider(height: 20),
                              Text(
                                'Confirmação do cliente: '
                                '${clientConfirmed ? "Confirmada" : "Pendente"}',
                                style: TextStyle(
                                  color: clientConfirmed
                                      ? Colors.green.shade700
                                      : Colors.orange.shade800,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                              const SizedBox(height: 4),
                              Row(
                                children: [
                                  Icon(
                                    qrValidated
                                        ? Icons.qr_code_rounded
                                        : Icons.qr_code_2_rounded,
                                    size: 17,
                                    color: qrValidated
                                        ? Colors.green.shade700
                                        : Colors.orange.shade800,
                                  ),
                                  const SizedBox(width: 6),
                                  Text(
                                    'QR Code: '
                                    '${qrValidated ? "Validado" : "Pendente"}',
                                    style: TextStyle(
                                      color: qrValidated
                                          ? Colors.green.shade700
                                          : Colors.orange.shade800,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ],
                            if (isProcessing) ...[
                              const SizedBox(height: 12),
                              const LinearProgressIndicator(),
                            ] else if (!completed && !expired && paid) ...[
                              const SizedBox(height: 12),
                              SizedBox(
                                width: double.infinity,
                                child: FilledButton.icon(
                                  icon: const Icon(
                                    Icons.inventory_2_rounded,
                                  ),
                                  label: Text(
                                    canConfirmDelivery
                                        ? 'Confirmar entrega ao cliente'
                                        : 'Aguardar validação e confirmação do cliente',
                                  ),
                                  onPressed: canConfirmDelivery
                                      ? () => _confirmPhysicalDelivery(
                                            reservation,
                                          )
                                      : null,
                                ),
                              ),
                              if (!canConfirmDelivery) ...[
                                const SizedBox(height: 6),
                                const Text(
                                  'A entrega só pode ser confirmada depois '
                                  'da validação do QR Code e da confirmação '
                                  'do pagamento pelo cliente.',
                                  style: TextStyle(
                                    fontSize: 11,
                                    color: Colors.grey,
                                  ),
                                ),
                              ],
                            ],
                          ],
                        ),
                      ),
                    ).cascade(index);
                  },
                ),
        ),
      ],
    );
  }

  // -------------------------------------------------------------------------
  // Receitas
  // -------------------------------------------------------------------------

  Widget _buildPrescriptionsTab(PharmacyDashboardState state) {
    if (state.prescriptions.isEmpty) {
      return _buildEmptyState('Ainda não existem receitas para apresentar.');
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 16, 16, 96),
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
                    const Icon(
                      Iconsax.document_text_bold,
                      color: _kGreen,
                      size: 22,
                    ),
                    const SizedBox(width: 8),
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
                        builder: (dialogContext) => PrescriptionReviewDialog(
                          prescription: prescription,
                          onReview: (status, notes) {
                            Navigator.of(dialogContext).pop();

                            _runOperation(
                              () => ref
                                  .read(
                                    pharmacyDashboardProvider.notifier,
                                  )
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
        ).cascade(index);
      },
    );
  }
}
