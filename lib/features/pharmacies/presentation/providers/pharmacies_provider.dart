import 'package:flutter_riverpod/flutter_riverpod.dart';
import '../../data/pharmacies_repository.dart';
import '../../domain/pharmacy_model.dart';
import '../../../medicines/presentation/providers/medicines_provider.dart';

final pharmaciesRepositoryProvider = Provider<PharmaciesRepository>((ref) {
  return PharmaciesRepository();
});

final pharmaciesListProvider = FutureProvider<List<PharmacyModel>>((ref) async {
  final repository = ref.watch(pharmaciesRepositoryProvider);
  final filter = ref.watch(medicineFilterProvider);

  return repository.getPharmacies(
    province: filter.selectedProvince,
    only24h: filter.only24h,
  );
});
