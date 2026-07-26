import 'package:supabase_flutter/supabase_flutter.dart';

class SupabaseAuthService {
  final SupabaseClient _client = Supabase.instance.client;

  SupabaseClient get client => _client;

  User? get currentUser => _client.auth.currentUser;

  Session? get currentSession => _client.auth.currentSession;

  Stream<AuthState> get authStateChanges => _client.auth.onAuthStateChange;

  /// Sign in with email and password using Supabase Auth
  Future<AuthResponse> signInWithEmailAndPassword({
    required String email,
    required String password,
  }) async {
    try {
      final response = await _client.auth.signInWithPassword(
        email: email,
        password: password,
      );
      return response;
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Ocorreu um erro ao iniciar sessão no Supabase: ${e.toString()}';
    }
  }

  /// Sign up new user using Supabase Auth
  Future<AuthResponse> signUp({
    required String email,
    required String password,
    required Map<String, dynamic> userMetadata,
  }) async {
    try {
      final response = await _client.auth.signUp(
        email: email,
        password: password,
        data: userMetadata,
      );
      return response;
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Ocorreu um erro ao criar conta no Supabase: ${e.toString()}';
    }
  }

  /// Send password reset email via Supabase Auth
  Future<void> resetPasswordForEmail(String email) async {
    try {
      await _client.auth.resetPasswordForEmail(
        email,
        redirectTo: 'farmaja://reset-callback',
      );
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Erro ao enviar e-mail de recuperação: ${e.toString()}';
    }
  }

  /// Update user password
  Future<UserResponse> updatePassword(String newPassword) async {
    try {
      return await _client.auth.updateUser(
        UserAttributes(password: newPassword),
      );
    } on AuthException catch (e) {
      throw e.message;
    } catch (e) {
      throw 'Erro ao atualizar palavra-passe: ${e.toString()}';
    }
  }

  /// Sign out current user
  Future<void> signOut() async {
    try {
      await _client.auth.signOut();
    } catch (e) {
      throw 'Erro ao terminar sessão: ${e.toString()}';
    }
  }
}
