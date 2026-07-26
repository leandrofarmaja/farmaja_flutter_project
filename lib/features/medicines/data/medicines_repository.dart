import '../../../core/services/supabase_database_service.dart';
import '../domain/medicine_model.dart';

class MedicinesRepository {
  final SupabaseDatabaseService _dbService = SupabaseDatabaseService();

  Future<List<MedicineModel>> getMedicines({
    String? query,
    String? province,
    bool? onlyInStock,
    bool? genericsOnly,
    bool? only24h,
  }) async {
    return _dbService.getMedicines(
      query: query,
      province: province,
      onlyInStock: onlyInStock,
      genericsOnly: genericsOnly,
    );
  }

  Future<MedicineModel?> getMedicineById(String id) async {
    return _dbService.getMedicineById(id);
  }
}
