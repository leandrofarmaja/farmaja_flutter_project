
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'package:url_launcher/url_launcher.dart';

import '../../../../core/constants/app_colors.dart';

class AdminPharmacyApplicationsScreen extends StatefulWidget {
  const AdminPharmacyApplicationsScreen({super.key});

  @override
  State<AdminPharmacyApplicationsScreen> createState() =>
      _AdminPharmacyApplicationsScreenState();
}

class _AdminPharmacyApplicationsScreenState
    extends State<AdminPharmacyApplicationsScreen> {
  final SupabaseClient _supabase = Supabase.instance.client;

  List<Map<String, dynamic>> _applications = [];
  bool _loading = true;
  String? _error;
  final Set<String> _processingIds = {};

  @override
  void initState() {
    super.initState();
    _loadApplications();
  }

  Future<void> _loadApplications() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }

    try {
      final result = await _supabase
          .from('pharmacy_applications')
          .select()
          .eq('status', 'pending')
          .order('created_at', ascending: true);

      if (!mounted) return;

      setState(() {
        _applications = List<Map<String, dynamic>>.from(
          result.map((item) => Map<String, dynamic>.from(item)),
        );
        _loading = false;
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Erro ao consultar candidaturas: ${e.message}';
        _loading = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _error = 'Não foi possível carregar as candidaturas.';
        _loading = false;
      });
    }
  }

  Future<void> _openLicense(Map<String, dynamic> application) async {
    final path = application['license_document_path']?.toString();

    if (path == null || path.isEmpty) {
      _showMessage('O caminho do documento da licença não está disponível.');
      return;
    }

    try {
      final signedUrl = await _supabase.storage
          .from('pharmacy-licenses')
          .createSignedUrl(path, 300);

      final uri = Uri.tryParse(signedUrl);

      if (uri == null) {
        _showMessage('Não foi possível gerar o acesso à licença.');
        return;
      }

      final opened = await launchUrl(
        uri,
        mode: LaunchMode.externalApplication,
      );

      if (!opened && mounted) {
        _showMessage(
          'Não foi possível abrir o documento neste dispositivo.',
        );
      }
    } on StorageException catch (e) {
      _showMessage('Erro ao abrir a licença: ${e.message}');
    } catch (e) {
      _showMessage('Falha ao abrir a licença. Verifica a ligação.');
    }
  }

  Future<void> _reviewApplication(
    Map<String, dynamic> application,
    String decision,
  ) async {
    final id = application['id']?.toString();
    final pharmacyName =
        application['pharmacy_name']?.toString() ?? 'esta farmácia';

    if (id == null || id.isEmpty || _processingIds.contains(id)) {
      return;
    }

    final notesController = TextEditingController();

    final confirmed = await showDialog<bool>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        title: Text(
          decision == 'approved'
              ? 'Aprovar candidatura'
              : 'Rejeitar candidatura',
        ),
        content: SingleChildScrollView(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                decision == 'approved'
                    ? 'Confirmas a aprovação de "$pharmacyName"? '
                        'A farmácia será registada na plataforma.'
                    : 'Confirmas a rejeição da candidatura de '
                        '"$pharmacyName"?',
              ),
              const SizedBox(height: 16),
              TextField(
                controller: notesController,
                maxLines: 3,
                maxLength: 500,
                decoration: const InputDecoration(
                  labelText: 'Observações (opcional)',
                  hintText: 'Indica o motivo ou outras observações',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(dialogContext, false),
            child: const Text('Cancelar'),
          ),
          FilledButton(
            style: decision == 'rejected'
                ? FilledButton.styleFrom(
                    backgroundColor: Colors.red,
                  )
                : null,
            onPressed: () => Navigator.pop(dialogContext, true),
            child: Text(
              decision == 'approved' ? 'Confirmar aprovação' : 'Confirmar rejeição',
            ),
          ),
        ],
      ),
    );

    if (confirmed != true || !mounted) {
      notesController.dispose();
      return;
    }

    setState(() => _processingIds.add(id));

    try {
      await _supabase.rpc(
        'review_pharmacy_application',
        params: {
          'p_application_id': id,
          'p_decision': decision,
          'p_admin_notes': notesController.text.trim().isEmpty
              ? null
              : notesController.text.trim(),
        },
      );

      if (!mounted) return;

      setState(() {
        _applications.removeWhere(
          (item) => item['id']?.toString() == id,
        );
      });

      _showMessage(
        decision == 'approved'
            ? 'Candidatura aprovada. A operação foi confirmada pelo Supabase.'
            : 'Candidatura rejeitada. A operação foi confirmada pelo Supabase.',
      );
    } on PostgrestException catch (e) {
      if (mounted) {
        _showMessage('Não foi possível concluir a análise: ${e.message}');
      }
    } catch (e) {
      if (mounted) {
        _showMessage('Ocorreu um erro. Atualiza a lista e verifica o estado.');
      }
    } finally {
      notesController.dispose();
      if (mounted) {
        setState(() => _processingIds.remove(id));
      }
    }
  }

  void _showMessage(String message) {
    if (!mounted) return;

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message)),
    );
  }

  String _value(Map<String, dynamic> item, String key) {
    final value = item[key]?.toString().trim();
    return value == null || value.isEmpty ? 'Não informado' : value;
  }

  String _formatDate(dynamic value) {
    if (value == null) return 'Data não disponível';

    final date = DateTime.tryParse(value.toString())?.toLocal();
    if (date == null) return 'Data não disponível';

    final day = date.day.toString().padLeft(2, '0');
    final month = date.month.toString().padLeft(2, '0');

    return '$day/$month/${date.year} '
        '${date.hour.toString().padLeft(2, '0')}:'
        '${date.minute.toString().padLeft(2, '0')}';
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Candidaturas de Farmácias',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        actions: [
          IconButton(
            onPressed: _loading ? null : _loadApplications,
            tooltip: 'Atualizar candidaturas',
            icon: const Icon(Icons.refresh_rounded),
          ),
        ],
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator())
          : _error != null
              ? Center(
                  child: Padding(
                    padding: const EdgeInsets.all(24),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        const Icon(
                          Icons.error_outline_rounded,
                          size: 48,
                          color: Colors.red,
                        ),
                        const SizedBox(height: 12),
                        Text(
                          _error!,
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 12),
                        FilledButton.icon(
                          onPressed: _loadApplications,
                          icon: const Icon(Icons.refresh),
                          label: const Text('Tentar novamente'),
                        ),
                      ],
                    ),
                  ),
                )
              : _applications.isEmpty
                  ? RefreshIndicator(
                      onRefresh: _loadApplications,
                      child: ListView(
                        physics: const AlwaysScrollableScrollPhysics(),
                        children: const [
                          SizedBox(height: 140),
                          Icon(
                            Icons.fact_check_outlined,
                            size: 64,
                            color: Colors.grey,
                          ),
                          SizedBox(height: 16),
                          Center(
                            child: Text(
                              'Não existem candidaturas pendentes.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                          SizedBox(height: 8),
                          Center(
                            child: Text(
                              'As novas candidaturas aparecerão aqui.',
                              textAlign: TextAlign.center,
                            ),
                          ),
                        ],
                      ),
                    )
                  : RefreshIndicator(
                      onRefresh: _loadApplications,
                      child: ListView.builder(
                        physics: const AlwaysScrollableScrollPhysics(),
                        padding: const EdgeInsets.all(16),
                        itemCount: _applications.length,
                        itemBuilder: (context, index) {
                          final application = _applications[index];
                          final id = application['id']?.toString() ?? '';
                          final processing = _processingIds.contains(id);

                          return Card(
                            margin: const EdgeInsets.only(bottom: 16),
                            clipBehavior: Clip.antiAlias,
                            child: Padding(
                              padding: const EdgeInsets.all(16),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Row(
                                    crossAxisAlignment:
                                        CrossAxisAlignment.start,
                                    children: [
                                      CircleAvatar(
                                        backgroundColor:
                                            AppColors.primaryLight,
                                        child: Icon(
                                          Icons.local_pharmacy_outlined,
                                          color: AppColors.primary,
                                        ),
                                      ),
                                      const SizedBox(width: 12),
                                      Expanded(
                                        child: Column(
                                          crossAxisAlignment:
                                              CrossAxisAlignment.start,
                                          children: [
                                            Text(
                                              _value(
                                                application,
                                                'pharmacy_name',
                                              ),
                                              style: const TextStyle(
                                                fontSize: 17,
                                                fontWeight: FontWeight.bold,
                                              ),
                                            ),
                                            const SizedBox(height: 4),
                                            Text(
                                              'Recebida em '
                                              '${_formatDate(application['created_at'])}',
                                              style: const TextStyle(
                                                fontSize: 12,
                                                color: Colors.grey,
                                              ),
                                            ),
                                          ],
                                        ),
                                      ),
                                      const Chip(
                                        label: Text('Pendente'),
                                      ),
                                    ],
                                  ),
                                  const Divider(height: 24),
                                  _detail(
                                    'Responsável',
                                    _value(application, 'contact_person'),
                                  ),
                                  _detail(
                                    'Telefone',
                                    _value(application, 'phone'),
                                  ),
                                  _detail(
                                    'N.º da licença',
                                    _value(application, 'license_number'),
                                  ),
                                  _detail(
                                    'Província',
                                    _value(application, 'province'),
                                  ),
                                  _detail(
                                    'Município / distrito',
                                    _value(application, 'district'),
                                  ),
                                  _detail(
                                    'Endereço',
                                    _value(application, 'address'),
                                  ),
                                  const SizedBox(height: 12),
                                  OutlinedButton.icon(
                                    onPressed: processing
                                        ? null
                                        : () => _openLicense(application),
                                    icon: const Icon(
                                      Icons.description_outlined,
                                    ),
                                    label: const Text('Consultar licença'),
                                  ),
                                  const SizedBox(height: 12),
                                  if (processing)
                                    const LinearProgressIndicator()
                                  else
                                    Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.stretch,
                                      children: [
                                        FilledButton.icon(
                                          onPressed: () =>
                                              _reviewApplication(
                                            application,
                                            'approved',
                                          ),
                                          icon: const Icon(
                                            Icons.check_circle_outline,
                                          ),
                                          label: const Text(
                                            'Aprovar candidatura',
                                          ),
                                        ),
                                        const SizedBox(height: 8),
                                        OutlinedButton.icon(
                                          onPressed: () =>
                                              _reviewApplication(
                                            application,
                                            'rejected',
                                          ),
                                          style: OutlinedButton.styleFrom(
                                            foregroundColor: Colors.red,
                                          ),
                                          icon: const Icon(
                                            Icons.cancel_outlined,
                                          ),
                                          label: const Text(
                                            'Rejeitar candidatura',
                                          ),
                                        ),
                                      ],
                                    ),
                                ],
                              ),
                            ),
                          );
                        },
                      ),
                    ),
    );
  }

  Widget _detail(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            label,
            style: const TextStyle(
              fontSize: 12,
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
          const SizedBox(height: 2),
          SelectableText(
            value,
            style: const TextStyle(fontSize: 14),
          ),
        ],
      ),
    );
  }
}
