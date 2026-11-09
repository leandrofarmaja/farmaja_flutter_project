import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import '../../data/pharmacies_repository.dart';
import '../../domain/pharmacy_model.dart';
import '../../../medicines/presentation/providers/medicines_provider.dart';

final pharmaciesRepositoryProvider =
    Provider<PharmaciesRepository>((ref) {
  return PharmaciesRepository();
});

// Pesquisa exclusiva da lista de farmácias.
final pharmaciesSearchQueryProvider =
    StateProvider<String>((ref) => '');

// Escuta alterações na tabela farmacias em tempo real.
final AutoDisposeProvider<void> pharmaciesRealtimeProvider =
    Provider.autoDispose<void>((ref) {
  final client = Supabase.instance.client;

  final channel = client
      .channel('farmacias-public-catalog')
      .onPostgresChanges(
        event: PostgresChangeEvent.all,
        schema: 'public',
        table: 'farmacias',
        callback: (payload) {
          ref.invalidate(pharmaciesListProvider);
        },
      )
      .subscribe();

  ref.onDispose(() {
    client.removeChannel(channel);
  });
});

// Lista de farmácias obtida através do Supabase.
final pharmaciesListProvider =
    FutureProvider<List<PharmacyModel>>((ref) async {
  // Mantém activa a subscrição de alterações em tempo real.
  ref.watch(pharmaciesRealtimeProvider);

  final repository = ref.watch(pharmaciesRepositoryProvider);
  final filter = ref.watch(medicineFilterProvider);
  final searchQuery = ref.watch(pharmaciesSearchQueryProvider);

  final selectedProvince = filter.selectedProvince.trim();
  final selectedMunicipality = filter.selectedDistrict.trim();

  return repository.getPharmacies(
    province: selectedProvince.isEmpty
        ? null
        : selectedProvince,
    only24h: filter.only24h,
    searchQuery: searchQuery.trim(),
    municipality:
        selectedMunicipality.isEmpty ||
                selectedMunicipality == 'Todos os Municípios'
            ? null
            : selectedMunicipality,
  );
});
