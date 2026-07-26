import '../../../core/services/supabase_database_service.dart';
import '../domain/pharmacy_model.dart';

class PharmaciesRepository {
  final SupabaseDatabaseService _dbService = SupabaseDatabaseService();

  Future<List<PharmacyModel>> getPharmacies({String? province, bool? only24h}) async {
    return _dbService.getPharmacies(province: province, only24h: only24h);
  }
}
