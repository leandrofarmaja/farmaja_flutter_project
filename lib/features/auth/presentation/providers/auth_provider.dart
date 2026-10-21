
import 'dart:async';

import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../../../core/services/supabase_auth_service.dart';
import '../../../../core/services/supabase_database_service.dart';
import '../../domain/user_model.dart';

final supabaseAuthServiceProvider =
    Provider<SupabaseAuthService>((ref) {
  return SupabaseAuthService();
});

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;
  final bool isPasswordRecovery;

  const AuthState({
    this.user,
    this.isLoading = false,
    this.error,
    this.isPasswordRecovery = false,
  });

  AuthState copyWith({
    UserModel? user,
    bool? isLoading,
    String? error,
    bool clearUser = false,
    bool clearError = false,
    bool? isPasswordRecovery,
  }) {
    return AuthState(
      user: clearUser ? null : (user ?? this.user),
      isLoading: isLoading ?? this.isLoading,
      error: clearError ? null : (error ?? this.error),
      isPasswordRecovery:
          isPasswordRecovery ?? this.isPasswordRecovery,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseAuthService _authService;
  final SupabaseDatabaseService _dbService;

  StreamSubscription<AuthState>? _unusedSubscription;
  StreamSubscription<dynamic>? _authSubscription;

  AuthNotifier(
    this._authService,
    this._dbService,
  ) : super(const AuthState(isLoading: true)) {
    _initAuth();
  }

  UserModel _userFromMetadata(
    String id,
    String email,
    Map<String, dynamic> metadata,
  ) {
    return UserModel(
      id: id,
      email: email,
      fullName: (metadata['full_name'] ??
              metadata['fullName'] ??
              '')
          .toString(),
      phone: (metadata['phone'] ?? '').toString(),
      province: (metadata['province'] ?? '').toString(),
      district: (metadata['district'] ?? '').toString(),
      insuranceProvider:
          metadata['insurance_provider']?.toString(),
      // Nunca confiar no papel indicado pelo cliente.
      role: 'customer',
      pharmacyName: null,
    );
  }

  Future<UserModel> _loadUserProfile(
    String id,
    String email,
    Map<String, dynamic> metadata,
  ) async {
    final profile = await _dbService.getUserProfile(id);

    if (profile != null) {
      return profile;
    }

    // Alternativa apenas em memória. Não altera permissões
    // nem grava um perfil na base de dados.
    return _userFromMetadata(id, email, metadata);
  }

  Future<void> _initAuth() async {
    try {
      final currentUser = _authService.currentUser;

      if (currentUser == null) {
        state = const AuthState();
      } else {
        final profile = await _loadUserProfile(
          currentUser.id,
          currentUser.email ?? '',
          currentUser.userMetadata ?? <String, dynamic>{},
        );

        state = AuthState(user: profile);
      }
    } catch (e) {
      state = AuthState(
        isLoading: false,
        error: 'Não foi possível carregar o perfil: $e',
      );
    }

    _authSubscription =
        _authService.authStateChanges.listen(
      (data) async {
        final event = data.event;
        final isRecovery =
            event == AuthChangeEvent.passwordRecovery;

        try {
          final user = data.session?.user;

          if (user == null) {
            state = AuthState(
              isPasswordRecovery: isRecovery,
            );
            return;
          }

          state = AuthState(
            user: state.user,
            isLoading: true,
            isPasswordRecovery: isRecovery,
          );

          final profile = await _loadUserProfile(
            user.id,
            user.email ?? '',
            user.userMetadata ?? <String, dynamic>{},
          );

          state = AuthState(
            user: profile,
            isPasswordRecovery: isRecovery,
          );
        } catch (e) {
          state = AuthState(
            isLoading: false,
            error: 'Erro ao actualizar a sessão: $e',
            isPasswordRecovery: isRecovery,
          );
        }
      },
      onError: (Object error) {
        state = AuthState(
          isLoading: false,
          error: 'Erro na autenticação: $error',
        );
      },
    );
  }

  Future<bool> login(
    String email,
    String password,
  ) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      final response =
          await _authService.signInWithEmailAndPassword(
        email: email.trim(),
        password: password,
      );

      final user = response.user;

      if (user == null) {
        state = const AuthState(
          error:
              'O Supabase não devolveu um utilizador autenticado.',
        );
        return false;
      }

      final profile = await _loadUserProfile(
        user.id,
        user.email ?? email.trim(),
        user.userMetadata ?? <String, dynamic>{},
      );

      state = AuthState(user: profile);
      return true;
    } catch (e) {
      state = AuthState(
        isLoading: false,
        error: 'Não foi possível iniciar sessão: $e',
      );
      return false;
    }
  }

  Future<bool> register({
    required String fullName,
    required String email,
    required String password,
    required String phone,
    required String province,
    required String district,
    String role = 'customer',
    String? pharmacyName,
  }) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    if (role != 'customer') {
      state = const AuthState(
        error:
            'O registo público de farmácias ainda não está disponível. '
            'A activação de uma farmácia exige aprovação.',
      );
      return false;
    }

    try {
      final response = await _authService.signUp(
        email: email.trim(),
        password: password,
        userMetadata: {
          'full_name': fullName.trim(),
          'phone': phone.trim(),
          'province': province,
          'district': district,
        },
      );

      if (response.user == null) {
        state = const AuthState(
          error:
              'O Supabase não devolveu um utilizador. '
              'Verifica a configuração do registo e a confirmação do email.',
        );
        return false;
      }

      if (response.session != null) {
        final user = response.user!;

        final profile = await _loadUserProfile(
          user.id,
          user.email ?? email.trim(),
          user.userMetadata ?? <String, dynamic>{},
        );

        state = AuthState(user: profile);
      } else {
        state = const AuthState();
      }

      return true;
    } catch (e) {
      state = AuthState(
        isLoading: false,
        error: 'Não foi possível concluir o registo: $e',
      );
      return false;
    }
  }

  Future<bool> resetPassword(String email) async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await _authService.resetPasswordForEmail(email.trim());
      state = const AuthState();
      return true;
    } catch (e) {
      state = AuthState(
        isLoading: false,
        error: 'Não foi possível pedir a recuperação: $e',
      );
      return false;
    }
  }

  Future<void> logout() async {
    state = state.copyWith(
      isLoading: true,
      clearError: true,
    );

    try {
      await _authService.signOut();
      state = const AuthState();
    } catch (e) {
      state = AuthState(
        user: state.user,
        isLoading: false,
        error: 'Não foi possível terminar a sessão: $e',
      );
    }
  }

  @override
  void dispose() {
    _authSubscription?.cancel();
    super.dispose();
  }
}

final authProvider =
    StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(supabaseAuthServiceProvider);
  final dbService = ref.watch(supabaseDatabaseServiceProvider);

  return AuthNotifier(authService, dbService);
});
