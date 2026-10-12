  Future<ReservationModel> createReservation({
    required String userId,
    required String medicineId,
    required String pharmacyId,
    required bool prescriptionUploaded,
    String? prescriptionPath,
  }) async {
    final currentUser = _client.auth.currentUser;

    if (currentUser == null) {
      throw Exception(
        'É necessário iniciar sessão para efectuar uma reserva.',
      );
    }

    if (currentUser.id != userId) {
      throw Exception(
        'O utilizador autenticado não corresponde ao utilizador da reserva.',
      );
    }

    if (medicineId.trim().isEmpty || pharmacyId.trim().isEmpty) {
      throw ArgumentError(
        'O medicamento e a farmácia devem ser identificados.',
      );
    }

    if (prescriptionUploaded &&
        (prescriptionPath == null ||
            prescriptionPath.trim().isEmpty)) {
      throw ArgumentError(
        'A receita foi indicada como enviada, mas o caminho do ficheiro está vazio.',
      );
    }

    try {
      final rpcResult = await _client.rpc(
        'criar_reserva',
        params: {
          'p_medicamento_id': medicineId,
          'p_farmacia_id': pharmacyId,
          'p_receita_enviada': prescriptionUploaded,
          'p_url_foto_receita': prescriptionUploaded
              ? prescriptionPath!.trim()
              : null,
        },
      );

      Map<String, dynamic>? createdReservation;

      if (rpcResult is Map) {
        createdReservation = Map<String, dynamic>.from(rpcResult);
      } else if (rpcResult is List && rpcResult.isNotEmpty) {
        final first = rpcResult.first;

        if (first is Map) {
          createdReservation = Map<String, dynamic>.from(first);
        }
      }

      final reservationId = createdReservation?['id']?.toString();

      if (reservationId == null || reservationId.isEmpty) {
        throw Exception(
          'O Supabase não devolveu o identificador da reserva criada.',
        );
      }

      final response = await _client
          .from('reservas')
          .select(
            'id, medicamento_id, farmacia_id, status, '
            'codigo_reserva, url_foto_receita, criado_em, '
            'user_id, preco_kwanza, expira_em, receita_enviada, '
            'medicamentos(nome_medicamento), farmacias(nome)',
          )
          .eq('id', reservationId)
          .eq('user_id', currentUser.id)
          .single();

      return _reservationFromDatabase(
        Map<String, dynamic>.from(response),
      );
    } catch (e) {
      throw Exception(
        'Não foi possível criar a reserva: $e',
      );
    }
  }
