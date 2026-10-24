
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

  StreamSubscription<dynamic>? _authSubscription;

  AuthNotifier(
    this._authService,
    this._dbService,
  ) : super(const AuthState(isLoading: true)) {
    _authSubscription = _authService.authStateChanges.listen(
      _handleAuthEvent,
      onError: (Object error) {
        state = AuthState(
          user: state.user,
          isLoading: false,
          error: 'Ocorreu um erro no estado da autenticação.',
          isPasswordRecovery: state.isPasswordRecovery,
        );
      },
    );

    _initAuth();
  }

  static const Set<String> _validRoles = {
    'customer',
    'pharmacy',
    'admin',
  };

  /// Carrega exclusivamente o perfil persistido no Supabase.
  ///
  /// Não cria um perfil fictício a partir dos metadados
  /// nem transforma automaticamente uma conta em cliente.
  Future<UserModel> _loadUserProfile(String id) async {
    final profile = await _dbService.getUserProfile(id);

    if (profile == null) {
      throw StateError(
        'O perfil desta conta não existe em public.profiles.',
      );
    }

    if (profile.id != id) {
      throw StateError(
        'O perfil devolvido não corresponde à conta autenticada.',
      );
    }

    final role = profile.role.trim().toLowerCase();

    if (!_validRoles.contains(role)) {
      throw StateError(
        'O perfil não tem uma função válida autorizada.',
      );
    }

    if (role != profile.role) {
      return UserModel(
        id: profile.id,
        email: profile.email,
        fullName: profile.fullName,
        phone: profile.phone,
        province: profile.province,
        district: profile.district,
        insuranceProvider: profile.insuranceProvider,
        role: role,
        pharmacyName: profile.pharmacyName,
      );
    }

    return profile;
  }

  Future<void> _initAuth() async {
    try {
      final currentUser = _authService.currentUser;

      if (currentUser == null) {
        if (!state.isPasswordRecovery) {
          state = const AuthState();
        }
        return;
      }

      final profile = await _loadUserProfile(currentUser.id);

      state = AuthState(
        user: profile,
        isPasswordRecovery: state.isPasswordRecovery,
      );
    } catch (e) {
      final recovery = state.isPasswordRecovery;

      // Nunca terminar uma sessão de recuperação da palavra-passe
      // apenas porque o perfil não pôde ser carregado.
      if (!recovery && _authService.currentUser != null) {
        try {
          await _authService.signOut();
        } catch (_) {
          // O acesso continua bloqueado pelo estado sem utilizador.
        }
      }

      state = AuthState(
        isLoading: false,
        error: recovery
            ? null
            : 'Não foi possível validar o perfil desta conta. '
                'Contacte o suporte FARCLIK.',
        isPasswordRecovery: recovery,
      );
    }
  }

  Future<void> _handleAuthEvent(dynamic data) async {
    final AuthChangeEvent event = data.event;
    final bool isRecovery =
        event == AuthChangeEvent.passwordRecovery;

    if (isRecovery) {
      state = state.copyWith(
        isPasswordRecovery: true,
        clearError: true,
      );
    }

    final user = data.session?.user;

    if (user == null) {
      if (event == AuthChangeEvent.signedOut) {
        state = const AuthState();
      } else if (isRecovery) {
        state = state.copyWith(isLoading: false);
      } else if (event == AuthChangeEvent.initialSession) {
        state = AuthState(
          isPasswordRecovery: state.isPasswordRecovery,
        );
      }
      return;
    }

    try {
      final profile = await _loadUserProfile(user.id);

      state = AuthState(
        user: profile,
        isPasswordRecovery:
            isRecovery || state.isPasswordRecovery,
      );
    } catch (e) {
      // Preserva o fluxo de recuperação, sem conceder acesso
      // a áreas de cliente, farmácia ou administração.
      state = AuthState(
        isLoading: false,
        error: (isRecovery || state.isPasswordRecovery)
            ? null
            : 'Não foi possível validar o perfil desta conta. '
                'Contacte o suporte FARCLIK.',
        isPasswordRecovery:
            isRecovery || state.isPasswordRecovery,
      );
    }
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
          error: 'Não foi possível confirmar a conta autenticada.',
        );
        return false;
      }

      final profile = await _loadUserProfile(user.id);

      state = AuthState(user: profile);
      return true;
    } catch (e) {
      // Uma conta sem perfil válido não deve permanecer
      // autenticada na aplicação como se fosse um cliente.
      try {
        if (_authService.currentUser != null) {
          await _authService.signOut();
        }
      } catch (_) {
        // O estado abaixo continua sem conceder acesso.
      }

      state = const AuthState(
        error: 'Não foi possível validar a conta. '
            'Confirma se o perfil está correctamente configurado '
            'e tenta novamente.',
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
        error: 'O registo público de farmácias ainda não está '
            'disponível. A activação de uma farmácia exige aprovação.',
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
          error: 'O Supabase não devolveu um utilizador. '
              'Verifica a configuração do registo e a confirmação '
              'do email.',
        );
        return false;
      }

      if (response.session != null) {
        final user = response.user!;

        try {
          final profile = await _loadUserProfile(user.id);
          state = AuthState(user: profile);
        } catch (_) {
          try {
            await _authService.signOut();
          } catch (_) {
            // Não atribuir um papel fictício ao utilizador.
          }

          state = const AuthState(
            error: 'A conta foi criada, mas o perfil ainda não '
                'está disponível. Confirma a criação do perfil '
                'no Supabase antes de iniciar sessão.',
          );

          return false;
        }
      } else {
        state = const AuthState();
      }

      return true;
    } catch (e) {
      state = const AuthState(
        error: 'Não foi possível concluir o registo. '
            'Verifica os dados e tenta novamente.',
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

      state = state.copyWith(
        isLoading: false,
        clearError: true,
      );

      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: 'Não foi possível pedir a recuperação. '
            'Tenta novamente.',
      );
      return false;
    }
  }

  Future<void> leavePasswordRecovery() async {
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
        error: 'Não foi possível voltar ao início de sessão. '
            'Tenta novamente.',
        isPasswordRecovery: state.isPasswordRecovery,
      );
      rethrow;
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
        error: 'Não foi possível terminar a sessão. '
            'Tenta novamente.',
        isPasswordRecovery: state.isPasswordRecovery,
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
