
import '../../../core/services/supabase_database_service.dart';
import '../domain/pharmacy_model.dart';

class PharmaciesRepository {
  final SupabaseDatabaseService _dbService =
      SupabaseDatabaseService();

  Future<List<PharmacyModel>> getPharmacies({
    String? province,
    bool? only24h,
    String? searchQuery,
    String? municipality,
    String? neighborhood,
    double? userLatitude,
    double? userLongitude,
    bool nearestFirst = false,
  }) async {
    // Obter os dados reais através do Supabase.
    final pharmacies = await _dbService.getPharmacies(
      province: province,
      only24h: only24h,
    );

    final normalizedQuery = _normalize(searchQuery);
    final normalizedMunicipality = _normalize(municipality);
    final normalizedNeighborhood = _normalize(neighborhood);

    // Aplicar a pesquisa sem distinguir maiúsculas de minúsculas
    // e ignorando acentos.
    final filteredPharmacies = pharmacies.where((pharmacy) {
      final matchesQuery = normalizedQuery.isEmpty ||
          _normalize(pharmacy.name).contains(normalizedQuery) ||
          _normalize(pharmacy.district).contains(normalizedQuery) ||
          _normalize(pharmacy.neighborhood).contains(normalizedQuery);

      final matchesMunicipality =
          normalizedMunicipality.isEmpty ||
          _normalize(pharmacy.district)
              .contains(normalizedMunicipality);

      final matchesNeighborhood =
          normalizedNeighborhood.isEmpty ||
          _normalize(pharmacy.neighborhood)
              .contains(normalizedNeighborhood);

      return matchesQuery &&
          matchesMunicipality &&
          matchesNeighborhood;
    }).toList();

    // Ordenar pela distância apenas quando as coordenadas reais
    // do utilizador forem fornecidas.
    final hasUserCoordinates =
        userLatitude != null &&
        userLongitude != null &&
        userLatitude != 0.0 &&
        userLongitude != 0.0;

    if (nearestFirst && hasUserCoordinates) {
      filteredPharmacies.sort((a, b) {
        final distanceA = a.calculateDistanceFrom(
          userLatitude,
          userLongitude,
        );
        final distanceB = b.calculateDistanceFrom(
          userLatitude,
          userLongitude,
        );

        return distanceA.compareTo(distanceB);
      });
    }

    return filteredPharmacies;
  }

  String _normalize(String? value) {
    if (value == null || value.trim().isEmpty) {
      return '';
    }

    return value
        .toLowerCase()
        .trim()
        .replaceAll(RegExp(r'[áàâãä]'), 'a')
        .replaceAll(RegExp(r'[éèêë]'), 'e')
        .replaceAll(RegExp(r'[íìîï]'), 'i')
        .replaceAll(RegExp(r'[óòôõö]'), 'o')
        .replaceAll(RegExp(r'[úùûü]'), 'u')
        .replaceAll('ç', 'c');
  }
}
Não 
