import 'package:supabase_flutter/supabase_flutter.dart';

import '../../features/medicines/domain/medicine_model.dart';

/// Serviço responsável por consultar o catálogo real de medicamentos
/// nas tabelas medicamentos e farmacias do Supabase.
class MedicinesCatalogService {
  MedicinesCatalogService({SupabaseClient? client})
      : _client = client ?? Supabase.instance.client;

  final SupabaseClient _client;

  Future<List<MedicineModel>> getMedicines({
    String? query,
    String? province,
    bool? onlyInStock,
    bool? genericsOnly,
  }) async {
    try {
      var medicinesQuery = _client
          .from('medicamentos')
          .select(
            'id, farmacia_id, nome_medicamento, preco_kwanza, '
            'distancia_km, disponivel',
          );

      if (onlyInStock == true) {
        medicinesQuery = medicinesQuery.eq('disponivel', true);
      }

      final medicineRows = await medicinesQuery;

      final pharmacyRows = await _client
          .from('farmacias')
          .select(
            'id, nome, endereco, telefone, avaliacao, aberta_agora',
          );

      final pharmaciesById = <String, Map<String, dynamic>>{};

      for (final row in pharmacyRows) {
        final pharmacy = Map<String, dynamic>.from(row);
        final id = pharmacy['id']?.toString();

        if (id != null && id.isNotEmpty) {
          pharmaciesById[id] = pharmacy;
        }
      }

      final results = <MedicineModel>[];

      for (final row in medicineRows) {
        final medicine = Map<String, dynamic>.from(row);
        final pharmacyId =
            medicine['farmacia_id']?.toString() ?? '';
        final pharmacy = pharmaciesById[pharmacyId];

        final medicineId = medicine['id']?.toString() ?? '';
        final name =
            medicine['nome_medicamento']?.toString() ?? '';
        final pharmacyName =
            pharmacy?['nome']?.toString() ?? '';
        final available = medicine['disponivel'] == true;

        if (medicineId.isEmpty || name.isEmpty) {
          continue;
        }

        if (query != null && query.trim().isNotEmpty) {
          final search = query.trim().toLowerCase();

          if (!name.toLowerCase().contains(search) &&
              !pharmacyName.toLowerCase().contains(search)) {
            continue;
          }
        }

        results.add(
          MedicineModel(
            id: medicineId,
            pharmacyId: pharmacyId,
            name: name,
            activeIngredient: '',
            category: 'Geral',
            dosage: 'Não especificado',
            priceKz: _toDouble(medicine['preco_kwanza']),
            pharmacyName: pharmacyName,
            province: '',
            district: pharmacy?['endereco']?.toString() ?? '',
            inStock: available,
            stockQuantity: 0,
            requiresPrescription: false,
            isGeneric: false,
            genericAlternative: null,
            description: '',
            dosageInstructions:
                'Consulta a embalagem e as indicações de um profissional de saúde.',
          ),
        );
      }

      return results;
    } on PostgrestException catch (error) {
      throw Exception(
        'Erro ao consultar o catálogo no Supabase: ${error.message}',
      );
    } catch (error) {
      throw Exception(
        'Não foi possível carregar os medicamentos: $error',
      );
    }
  }

  Future<MedicineModel?> getMedicineById(String id) async {
    try {
      final row = await _client
          .from('medicamentos')
          .select(
            'id, farmacia_id, nome_medicamento, preco_kwanza, '
            'distancia_km, disponivel',
          )
          .eq('id', id)
          .maybeSingle();

      if (row == null) {
        return null;
      }

      final medicine = Map<String, dynamic>.from(row);
      final pharmacyId =
          medicine['farmacia_id']?.toString() ?? '';

      Map<String, dynamic>? pharmacy;

      if (pharmacyId.isNotEmpty) {
        final pharmacyRow = await _client
            .from('farmacias')
            .select(
              'id, nome, endereco, telefone, avaliacao, aberta_agora',
            )
            .eq('id', pharmacyId)
            .maybeSingle();

        if (pharmacyRow != null) {
          pharmacy = Map<String, dynamic>.from(pharmacyRow);
        }
      }

      final medicineId = medicine['id']?.toString() ?? '';
      final name =
          medicine['nome_medicamento']?.toString() ?? '';

      if (medicineId.isEmpty || name.isEmpty) {
        return null;
      }

      return MedicineModel(
        id: medicineId,
        pharmacyId: pharmacyId,
        name: name,
        activeIngredient: '',
        category: 'Geral',
        dosage: 'Não especificado',
        priceKz: _toDouble(medicine['preco_kwanza']),
        pharmacyName: pharmacy?['nome']?.toString() ?? '',
        province: '',
        district: pharmacy?['endereco']?.toString() ?? '',
        inStock: medicine['disponivel'] == true,
        stockQuantity: 0,
        requiresPrescription: false,
        isGeneric: false,
        genericAlternative: null,
        description: '',
        dosageInstructions:
            'Consulta a embalagem e as indicações de um profissional de saúde.',
      );
    } on PostgrestException catch (error) {
      throw Exception(
        'Erro ao consultar o medicamento: ${error.message}',
      );
    } catch (error) {
      throw Exception(
        'Não foi possível carregar o medicamento: $error',
      );
    }
  }

  double _toDouble(dynamic value) {
    if (value is num) {
      return value.toDouble();
    }

    return double.tryParse(value?.toString() ?? '') ?? 0.0;
  }
}
