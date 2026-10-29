import 'package:flutter_riverpod/flutter_riverpod.dart';

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

// Lista de farmácias obtida através do Supabase.
final pharmaciesListProvider =
    FutureProvider<List<PharmacyModel>>((ref) async {
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
