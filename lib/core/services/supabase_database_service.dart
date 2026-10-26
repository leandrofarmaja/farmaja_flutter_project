
Future<void> addMedicine(MedicineModel medicine) async {
  if (_client.auth.currentUser == null) {
    throw Exception(
      'A sessão expirou. Inicia sessão novamente para guardar o medicamento.',
    );
  }

  if (medicine.name.trim().isEmpty) {
    throw ArgumentError(
      'O nome do medicamento é obrigatório.',
    );
  }

  if (!medicine.priceKz.isFinite ||
      medicine.priceKz < 0 ||
      medicine.stockQuantity < 0) {
    throw ArgumentError(
      'O preço e o stock devem ser valores válidos e não negativos.',
    );
  }

  try {
    // Confirma que a conta autenticada tem uma farmácia associada.
    // O identificador enviado pelo formulário não determina
    // a propriedade do novo medicamento.
    final pharmacy = await getOwnedPharmacy().timeout(
      const Duration(seconds: 15),
      onTimeout: () {
        throw TimeoutException(
          'A consulta da farmácia excedeu 15 segundos.',
        );
      },
    );

    if (pharmacy == null || pharmacy.id.trim().isEmpty) {
      throw Exception(
        'Esta conta não tem uma farmácia associada. '
        'Confirma se a farmácia foi aprovada e associada à tua conta.',
      );
    }

    // A função SQL deve obter a farmácia através de auth.uid()
    // e validar a propriedade no próprio Supabase.
    final result = await _client.rpc(
      'farclik_criar_medicamento',
      params: {
        'p_nome_medicamento': medicine.name.trim(),
        'p_preco_kwanza': medicine.priceKz,
        'p_quantidade_stock': medicine.stockQuantity,
        'p_receita_obrigatoria': medicine.requiresPrescription,
      },
    ).timeout(
      const Duration(seconds: 20),
      onTimeout: () {
        throw TimeoutException(
          'O Supabase não respondeu à gravação em 20 segundos.',
        );
      },
    );

    final createdId = result?.toString().trim() ?? '';

    if (createdId.isEmpty || createdId.toLowerCase() == 'false') {
      throw Exception(
        'O Supabase não confirmou a criação do medicamento.',
      );
    }
  } on TimeoutException {
    rethrow;
  } on PostgrestException catch (e) {
    throw Exception(
      'O Supabase recusou a criação do medicamento: ${e.message}',
    );
  } catch (e) {
    throw Exception(
      'Não foi possível criar o medicamento: $e',
    );
  }
}
