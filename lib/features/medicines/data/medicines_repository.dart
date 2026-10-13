import '../../../core/services/supabase_database_service.dart';
import '../domain/medicine_model.dart';

class MedicinesRepository {
  final SupabaseDatabaseService _databaseService =
      SupabaseDatabaseService();

  Future<List<MedicineModel>> getMedicines({
    String? query,
    String? province,
    bool? onlyInStock,
    bool? genericsOnly,
    bool? only24h,
  }) async {
    try {
      return await _databaseService.getMedicines(
        query: query,
        province: province,
        onlyInStock: onlyInStock,
        genericsOnly: genericsOnly,
      );
    } catch (e) {
      throw Exception('Não foi possível carregar os medicamentos: $e');
    }
  }

  Future<MedicineModel?> getMedicineById(String id) async {
    try {
      return await _databaseService.getMedicineById(id);
    } catch (e) {
      throw Exception('Não foi possível consultar o medicamento: $e');
    }
  }
}
