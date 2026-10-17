
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/medicines_repository.dart';
import '../../domain/medicine_model.dart';

final medicinesRepositoryProvider = Provider<MedicinesRepository>((ref) {
  return MedicinesRepository();
});

class MedicineFilterState {
  final String query;
  final String selectedProvince;
  final String selectedDistrict;
  final bool onlyInStock;
  final bool genericsOnly;
  final bool only24h;
  final double userLat;
  final double userLng;

  MedicineFilterState({
    this.query = '',
    this.selectedProvince = 'Luanda',
    this.selectedDistrict = 'Todos os Municípios',
    this.onlyInStock = true,
    this.genericsOnly = false,
    this.only24h = false,
    this.userLat = -8.8383,
    this.userLng = 13.2344,
  });

  MedicineFilterState copyWith({
    String? query,
    String? selectedProvince,
    String? selectedDistrict,
    bool? onlyInStock,
    bool? genericsOnly,
    bool? only24h,
    double? userLat,
    double? userLng,
  }) {
    return MedicineFilterState(
      query: query ?? this.query,
      selectedProvince: selectedProvince ?? this.selectedProvince,
      selectedDistrict: selectedDistrict ?? this.selectedDistrict,
      onlyInStock: onlyInStock ?? this.onlyInStock,
      genericsOnly: genericsOnly ?? this.genericsOnly,
      only24h: only24h ?? this.only24h,
      userLat: userLat ?? this.userLat,
      userLng: userLng ?? this.userLng,
    );
  }
}

final medicineFilterProvider =
    StateNotifierProvider<MedicineFilterNotifier, MedicineFilterState>((ref) {
  return MedicineFilterNotifier();
});

class MedicineFilterNotifier extends StateNotifier<MedicineFilterState> {
  MedicineFilterNotifier() : super(MedicineFilterState());

  void setQuery(String q) {
    state = state.copyWith(query: q);
  }

  void setProvince(String p) {
    state = state.copyWith(
      selectedProvince: p,
      selectedDistrict: 'Todos os Municípios',
    );
  }

  void setDistrict(String d) {
    state = state.copyWith(selectedDistrict: d);
  }

  void toggleOnlyInStock(bool val) {
    state = state.copyWith(onlyInStock: val);
  }

  void toggleGenericsOnly(bool val) {
    state = state.copyWith(genericsOnly: val);
  }

  void toggleOnly24h(bool val) {
    state = state.copyWith(only24h: val);
  }

  void resetFilters() {
    state = MedicineFilterState();
  }
}

final medicinesListProvider =
    FutureProvider<List<MedicineModel>>((ref) async {
  final repository = ref.watch(medicinesRepositoryProvider);
  final filter = ref.watch(medicineFilterProvider);

  // A base de dados atual ainda não suporta estes filtros.
  // Não enviar valores fictícios ou filtros não implementados.
  final list = await repository.getMedicines(
    query: filter.query.trim(),
    province: null,
    onlyInStock: filter.onlyInStock,
    genericsOnly: false,
    only24h: false,
  );

  // O município só pode ser filtrado quando houver dados reais
  // de localização associados aos medicamentos/farmácias.
  return list;
});
