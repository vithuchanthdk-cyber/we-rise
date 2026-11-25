import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import '../../complaints/data/in_memory_repositories.dart';
import '../../complaints/data/providers.dart';
import '../../complaints/domain/models.dart';
import '../../complaints/domain/repositories.dart';
import '../data/supabase_auth_repository.dart';

final authRepositoryProvider = Provider<AuthRepository>((ref) {
  if (ref.watch(useMockProvider)) {
    return InMemoryAuthRepository();
  }
  return SupabaseAuthRepository(Supabase.instance.client);
});

final authStateProvider = StreamProvider<AppUser?>((ref) {
  return ref.watch(authRepositoryProvider).watchCurrentUser();
});

final currentUserProvider = Provider<AppUser?>((ref) {
  return ref.watch(authStateProvider).valueOrNull;
});
