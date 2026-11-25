import 'dart:async';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../complaints/domain/enums.dart';
import '../../complaints/domain/models.dart';
import '../../complaints/domain/repositories.dart';

/// Production Supabase implementation of [AuthRepository].
/// Email/Google sign-in only (no phone OTP).
class SupabaseAuthRepository implements AuthRepository {
  SupabaseAuthRepository(this._client);

  final SupabaseClient _client;

  @override
  Future<AppUser?> getCurrentUser() async {
    final authUser = _client.auth.currentUser;
    if (authUser == null) return null;
    final row = await _client
        .from('app_users')
        .select()
        .eq('auth_user_id', authUser.id)
        .maybeSingle();
    if (row == null) return null;
    return userFromRow(row);
  }

  @override
  Future<AppUser> signInWithEmail(String email, String password) async {
    await _client.auth.signInWithPassword(email: email, password: password);
    final user = await getCurrentUser();
    if (user == null) {
      throw StateError('User profile not found in app_users.');
    }
    return user;
  }

  @override
  Future<AppUser> signUpWithEmail(String email, String password) async {
    final res = await _client.auth.signUp(email: email, password: password);
    final authUser = res.user;
    if (authUser == null) {
      throw StateError('Sign up failed.');
    }
    final handle = 'Citizen#${authUser.id.substring(0, 4).toUpperCase()}';
    final inserted = await _client
        .from('app_users')
        .insert({
          'auth_user_id': authUser.id,
          'anonymous_handle': handle,
          'role': 'citizen',
        })
        .select()
        .single();
    return userFromRow(inserted);
  }

  @override
  Future<void> signOut() => _client.auth.signOut();

  @override
  Future<void> deleteAccount() async {
    await _client.rpc<void>('delete_own_account');
    await _client.auth.signOut();
  }

  @override
  Stream<AppUser?> watchCurrentUser() {
    return _client.auth.onAuthStateChange.asyncMap((_) => getCurrentUser());
  }

  @override
  Future<void> setDemoUser(AppUser user) async {
    // No-op in production Supabase mode
  }

  static AppUser userFromRow(Map<String, dynamic> r) => AppUser(
        id: r['id'] as String,
        anonymousHandle: r['anonymous_handle'] as String,
        role: UserRole.values.byName(r['role'] as String),
        wardId: (r['ward_id'] as String?) ?? 'tondiarpet',
        languagePref: 'en',
        orgId: r['organisation_id'] as String?,
        volunteerHours: (r['volunteer_hours'] as num?)?.toDouble() ?? 0.0,
      );
}
