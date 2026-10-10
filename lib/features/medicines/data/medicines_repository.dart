import '../../../essencial/serviços/serviço_catálogo_de_medicamentos.dart';
import '../domain/medicine_model.dart';

class MedicinesRepository {
  final MedicinesCatalogService _catalogService =
      MedicinesCatalogService();

  Future<List<MedicineModel>> getMedicines({
    String? query,
    String? province,
    bool? onlyInStock,
    bool? genericsOnly,
    bool? only24h,
  }) async {
    return _catalogService.getMedicines(
      query: query,
      province: province,
      onlyInStock: onlyInStock,
      genericsOnly: genericsOnly,
    );
  }

  Future<MedicineModel?> getMedicineById(String id) async {
    return _catalogService.getMedicineById(id);
  }
}
