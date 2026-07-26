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

      final isAuthRoute = state.matchedLocation == '/login' ||
          state.matchedLocation == '/register' ||
          state.matchedLocation == '/welcome' ||
          state.matchedLocation == '/splash' ||
          state.matchedLocation == '/forgot-password';

      final isLoggedIn = authState.user != null;

      if (!isLoggedIn && !isAuthRoute) {
        return '/login';
      }

      if (isLoggedIn && (state.matchedLocation == '/login' || state.matchedLocation == '/register' || state.matchedLocation == '/welcome')) {
        return authState.user?.role == 'pharmacy' ? '/pharmacy-dashboard' : '/home';
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
  const MainNavigationShell({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    final String location = GoRouterState.of(context).uri.toString();

    int selectedIndex = 0;
    if (location.startsWith('/pharmacies')) {
      selectedIndex = 1;
    } else if (location.startsWith('/reservations')) {
      selectedIndex = 2;
    } else if (location.startsWith('/profile')) {
      selectedIndex = 3;
    }

    return Scaffold(
      body: child,
      bottomNavigationBar: NavigationBar(
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
            selectedIcon: Icon(Icons.home_rounded, color: Color(0xFF16A34A)),
            label: 'Início',
          ),
          NavigationDestination(
            icon: Icon(Icons.local_pharmacy_outlined),
            selectedIcon: Icon(Icons.local_pharmacy, color: Color(0xFF16A34A)),
            label: 'Farmácias',
          ),
          NavigationDestination(
            icon: Icon(Icons.bookmark_outline),
            selectedIcon: Icon(Icons.bookmark, color: Color(0xFF16A34A)),
            label: 'Reservas',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: Color(0xFF16A34A)),
            label: 'Perfil',
          ),
        ],
      ),
    );
  }
}
