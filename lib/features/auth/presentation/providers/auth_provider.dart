import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../../../core/services/supabase_auth_service.dart';
import '../../../../core/services/supabase_database_service.dart';
import '../../domain/user_model.dart';

final supabaseAuthServiceProvider = Provider<SupabaseAuthService>((ref) {
  return SupabaseAuthService();
});

final supabaseDatabaseServiceProvider = Provider<SupabaseDatabaseService>((ref) {
  return SupabaseDatabaseService();
});

class AuthState {
  final UserModel? user;
  final bool isLoading;
  final String? error;

  AuthState({this.user, this.isLoading = false, this.error});

  AuthState copyWith({UserModel? user, bool? isLoading, String? error}) {
    return AuthState(
      user: user ?? this.user,
      isLoading: isLoading ?? this.isLoading,
      error: error,
    );
  }
}

class AuthNotifier extends StateNotifier<AuthState> {
  final SupabaseAuthService _authService;
  final SupabaseDatabaseService _dbService;

  AuthNotifier(this._authService, this._dbService) : super(AuthState(isLoading: true)) {
    _initAuth();
  }

  Future<void> _initAuth() async {
    final currentUser = _authService.currentUser;
    if (currentUser != null) {
      final profile = await _dbService.getUserProfile(currentUser.id);
      if (profile != null) {
        state = AuthState(user: profile, isLoading: false);
      } else {
        final meta = currentUser.userMetadata ?? {};
        final user = UserModel(
          id: currentUser.id,
          email: currentUser.email ?? '',
          fullName: meta['full_name'] ?? meta['fullName'] ?? 'Utilizador FarmaJá',
          phone: meta['phone'] ?? '+244 923 000 000',
          province: meta['province'] ?? 'Luanda',
          district: meta['district'] ?? 'Talatona',
          insuranceProvider: meta['insurance_provider'] ?? 'ENSA Seguros',
          role: meta['role'] ?? 'customer',
          pharmacyName: meta['pharmacy_name'],
        );
        state = AuthState(user: user, isLoading: false);
      }
    } else {
      // Unauthenticated state
      state = AuthState(user: null, isLoading: false);
    }

    // Listen to Supabase Auth state changes
    _authService.authStateChanges.listen((data) async {
      final user = data.session?.user;
      if (user != null) {
        final profile = await _dbService.getUserProfile(user.id);
        if (profile != null) {
          state = AuthState(user: profile, isLoading: false);
        } else {
          final meta = user.userMetadata ?? {};
          final newUser = UserModel(
            id: user.id,
            email: user.email ?? '',
            fullName: meta['full_name'] ?? meta['fullName'] ?? 'Utilizador FarmaJá',
            phone: meta['phone'] ?? '+244 923 000 000',
            province: meta['province'] ?? 'Luanda',
            district: meta['district'] ?? 'Talatona',
            insuranceProvider: meta['insurance_provider'] ?? 'ENSA Seguros',
            role: meta['role'] ?? 'customer',
            pharmacyName: meta['pharmacy_name'],
          );
          state = AuthState(user: newUser, isLoading: false);
        }
      } else {
        state = AuthState(user: null, isLoading: false);
      }
    });
  }

  /// Real Supabase Auth Login
  Future<bool> login(String email, String password) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.signInWithEmailAndPassword(
        email: email,
        password: password,
      );

      final user = response.user;
      if (user != null) {
        UserModel? profile = await _dbService.getUserProfile(user.id);
        if (profile == null) {
          final meta = user.userMetadata ?? {};
          profile = UserModel(
            id: user.id,
            email: user.email ?? email,
            fullName: meta['full_name'] ?? meta['fullName'] ?? 'Utilizador FarmaJá',
            phone: meta['phone'] ?? '+244 923 000 000',
            province: meta['province'] ?? 'Luanda',
            district: meta['district'] ?? 'Talatona',
            insuranceProvider: meta['insurance_provider'] ?? 'ENSA Seguros',
            role: meta['role'] ?? 'customer',
            pharmacyName: meta['pharmacy_name'],
          );
          await _dbService.upsertUserProfile(profile);
        }
        state = AuthState(user: profile, isLoading: false);
        return true;
      } else {
        state = state.copyWith(
          isLoading: false,
          error: 'Falha na autenticação Supabase.',
        );
        return false;
      }
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Real Supabase Auth Register
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
    state = state.copyWith(isLoading: true, error: null);
    try {
      final response = await _authService.signUp(
        email: email,
        password: password,
        userMetadata: {
          'full_name': fullName,
          'phone': phone,
          'province': province,
          'district': district,
          'role': role,
          if (pharmacyName != null && pharmacyName.isNotEmpty) 'pharmacy_name': pharmacyName,
        },
      );

      final user = response.user;
      final userId = user?.id ?? 'usr-${DateTime.now().millisecondsSinceEpoch}';

      final newProfile = UserModel(
        id: userId,
        email: email,
        fullName: fullName,
        phone: phone,
        province: province,
        district: district,
        insuranceProvider: 'ENSA Seguros',
        role: role,
        pharmacyName: pharmacyName,
      );

      await _dbService.upsertUserProfile(newProfile);

      state = AuthState(user: newProfile, isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Real Supabase Auth Password Reset
  Future<bool> resetPassword(String email) async {
    state = state.copyWith(isLoading: true, error: null);
    try {
      await _authService.resetPasswordForEmail(email);
      state = state.copyWith(isLoading: false);
      return true;
    } catch (e) {
      state = state.copyWith(
        isLoading: false,
        error: e.toString(),
      );
      return false;
    }
  }

  /// Logout from Supabase Auth
  Future<void> logout() async {
    await _authService.signOut();
    state = AuthState(user: null);
  }
}

final authProvider = StateNotifierProvider<AuthNotifier, AuthState>((ref) {
  final authService = ref.watch(supabaseAuthServiceProvider);
  final dbService = ref.watch(supabaseDatabaseServiceProvider);
  return AuthNotifier(authService, dbService);
});
