import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';

import '../../features/auth/presentation/providers/auth_provider.dart';
import '../../features/auth/presentation/screens/login_screen.dart';

// Mantém aqui os imports das restantes telas já existentes
// no teu projecto, caso sejam necessários pelo código original.

final appRouterProvider = Provider<GoRouter>((ref) {
  final authState = ref.watch(authProvider);

  return GoRouter(
    initialLocation: '/login',
    refreshListenable: _RouterRefreshNotifier(ref),
    redirect: (context, state) {
      final location = state.matchedLocation;

      // A recuperação da palavra-passe deve continuar acessível.
      if (authState.isPasswordRecovery) {
        return null;
      }

      final user = authState.user;
      final isLoading = authState.isLoading;

      // Enquanto o Supabase valida a sessão, não redireccionar
      // prematuramente para uma área de utilizador.
      if (isLoading) {
        return null;
      }

      final isLogin = location == '/login' ||
          location == '/register' ||
          location == '/forgot-password';

      if (user == null) {
        return isLogin ? null : '/login';
      }

      switch (user.role) {
        case 'customer':
          if (location == '/login' ||
              location == '/register' ||
              location == '/forgot-password' ||
              location.startsWith('/pharmacy-dashboard') ||
              location.startsWith('/admin')) {
            return '/home';
          }
          break;

        case 'pharmacy':
          if (location == '/login' ||
              location == '/register' ||
              location == '/forgot-password' ||
              location == '/home' ||
              location.startsWith('/admin')) {
            return '/pharmacy-dashboard';
          }
          break;

        case 'admin':
          if (location == '/login' ||
              location == '/register' ||
              location == '/forgot-password' ||
              location == '/home' ||
              location.startsWith('/pharmacy-dashboard')) {
            return '/admin/subscriptions';
          }
          break;

        default:
          return '/login';
      }

      return null;
    },
    routes: [
      GoRoute(
        path: '/login',
        builder: (context, state) => const LoginScreen(),
      ),
    ],
  );
});

class _RouterRefreshNotifier extends ChangeNotifier {
  _RouterRefreshNotifier(Ref ref) {
    ref.listen(authProvider, (previous, next) {
      notifyListeners();
    });
  }
}
