
import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/splash_screen.dart';
import '../../features/auth/presentation/screens/welcome_screen.dart';
import '../../features/auth/presentation/screens/login_screen.dart';
import '../../features/auth/presentation/screens/register_screen.dart';
import '../../features/auth/presentation/screens/forgot_password_screen.dart';
import '../../features/medicines/presentation/screens/home_screen.dart';
import '../../features/pharmacies/presentation/screens/pharmacies_screen.dart';
import '../../features/reservations/presentation/screens/reservations_screen.dart';
import '../../features/profile/presentation/screens/profile_screen.dart';
import '../../features/medicines/presentation/screens/medicine_detail_screen.dart';
import '../../features/pharmacy_dashboard/presentation/screens/pharmacy_dashboard_screen.dart';
import '../../features/admin/presentation/screens/admin_subscriptions_screen.dart';

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    redirect: (context, state) {
      if (authState.isLoading) return null;

      final user = authState.user;
      final location = state.matchedLocation;

      final isAuthRoute = location == '/login' ||
          location == '/register' ||
          location == '/welcome' ||
          location == '/splash' ||
          location == '/forgot-password';

      if (user == null) {
        return isAuthRoute ? null : '/login';
      }

      final role = user.role;
      final isPharmacy = role == 'pharmacy';
      final isAdmin = role == 'admin';
      final isCustomer = role == 'customer';

      // Não permitir que contas com papel desconhecido
      // acedam às áreas privadas da aplicação.
      if (!isPharmacy && !isAdmin && !isCustomer) {
        return '/login';
      }

      // Redireccionar utilizadores autenticados
      // para a área correspondente ao seu papel.
      if (isAuthRoute) {
        if (location == '/forgot-password' ||
            location == '/splash') {
          return null;
        }

        if (isPharmacy) return '/pharmacy-dashboard';
        if (isAdmin) return '/admin/subscriptions';
        return '/home';
      }

      // Área exclusiva das farmácias.
      if (location == '/pharmacy-dashboard' && !isPharmacy) {
        if (isAdmin) return '/admin/subscriptions';
        return '/home';
      }

      // Área exclusiva dos administradores.
      if (location == '/admin/subscriptions' && !isAdmin) {
        if (isPharmacy) return '/pharmacy-dashboard';
        return '/home';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/splash',
        builder: (context, state) => const SplashScreen(),
      ),
      GoRoute(
        path: '/welcome',
        builder: (context, state) => const WelcomeScreen(),
      ),
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
      GoRoute(
        path: '/register',
        builder: (context, state) => const RegisterScreen(),
      ),
      GoRoute(
        path: '/forgot-password',
        builder: (context, state) => const ForgotPasswordScreen(),
      ),
      ShellRoute(
        builder: (context, state, child) {
          return MainNavigationShell(child: child);
        },
        routes: [
          GoRoute(
            path: '/home',
            builder: (context, state) => const HomeScreen(),
          ),
          GoRoute(
            path: '/pharmacies',
            builder: (context, state) => const PharmaciesScreen(),
          ),
          GoRoute(
            path: '/reservations',
            builder: (context, state) => const ReservationsScreen(),
          ),
          GoRoute(
            path: '/profile',
            builder: (context, state) => const ProfileScreen(),
          ),
        ],
      ),
      GoRoute(
        path: '/medicine/:id',
        builder: (context, state) {
          final medicineId = state.pathParameters['id'] ?? '';
          return MedicineDetailScreen(medicineId: medicineId);
        },
      ),
      GoRoute(
        path: '/pharmacy-dashboard',
        builder: (context, state) => const PharmacyDashboardScreen(),
      ),
      GoRoute(
        path: '/admin/subscriptions',
        builder: (context, state) => const AdminSubscriptionsScreen(),
      ),
    ],
  );
});

class MainNavigationShell extends StatelessWidget {
  final Widget child;

  const MainNavigationShell({
    super.key,
    required this.child,
  });

  static const Color _darkGreen = Color(0xFF15803D);
  static const Color _softGreen = Color(0xFFE8F7ED);
  static const Color _muted = Color(0xFF7B8794);

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.path;

    int selectedIndex = 0;

    if (location.startsWith('/pharmacies')) {
      selectedIndex = 1;
    } else if (location.startsWith('/reservations')) {
      selectedIndex = 2;
    } else if (location.startsWith('/profile')) {
      selectedIndex = 3;
    }

    return Scaffold(
      backgroundColor: Colors.white,
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          border: const Border(
            top: BorderSide(
              color: Color(0xFFF0F3F1),
              width: 1,
            ),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.035),
              blurRadius: 18,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: NavigationBarTheme(
            data: NavigationBarThemeData(
              height: 72,
              backgroundColor: Colors.white,
              surfaceTintColor: Colors.transparent,
              indicatorColor: _softGreen,
              indicatorShape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(16),
              ),
              elevation: 0,
              labelBehavior:
                  NavigationDestinationLabelBehavior.alwaysShow,
              labelTextStyle:
                  WidgetStateProperty.resolveWith<TextStyle>(
                (states) {
                  final selected =
                      states.contains(WidgetState.selected);

                  return TextStyle(
                    fontSize: 11,
                    height: 1.2,
                    fontWeight:
                        selected ? FontWeight.w700 : FontWeight.w500,
                    letterSpacing: 0.1,
                    color: selected ? _darkGreen : _muted,
                  );
                },
              ),
              iconTheme:
                  WidgetStateProperty.resolveWith<IconThemeData>(
                (states) {
                  final selected =
                      states.contains(WidgetState.selected);

                  return IconThemeData(
                    size: selected ? 24 : 22,
                    color: selected ? _darkGreen : _muted,
                  );
                },
              ),
            ),
            child: NavigationBar(
              selectedIndex: selectedIndex,
              onDestinationSelected: (index) {
                switch (index) {
                  case 0:
                    context.go('/home');
                    break;
                  case 1:
                    context.go('/pharmacies');
                    break;
                  case 2:
                    context.go('/reservations');
                    break;
                  case 3:
                    context.go('/profile');
                    break;
                }
              },
              destinations: const [
                NavigationDestination(
                  icon: Icon(Icons.home_outlined),
                  selectedIcon: Icon(Icons.home_rounded),
                  label: 'Início',
                ),
                NavigationDestination(
                  icon: Icon(Icons.local_pharmacy_outlined),
                  selectedIcon: Icon(Icons.local_pharmacy_rounded),
                  label: 'Farmácias',
                ),
                NavigationDestination(
                  icon: Icon(Icons.confirmation_number_outlined),
                  selectedIcon: Icon(Icons.confirmation_number_rounded),
                  label: 'Reservas',
                ),
                NavigationDestination(
                  icon: Icon(Icons.person_outline_rounded),
                  selectedIcon: Icon(Icons.person_rounded),
                  label: 'Perfil',
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
