
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PharmacyApplicationScreen extends StatefulWidget {
  const PharmacyApplicationScreen({super.key});

  @override
  State<PharmacyApplicationScreen> createState() =>
      _PharmacyApplicationScreenState();
}

class _PharmacyApplicationScreenState
    extends State<PharmacyApplicationScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supabase = Supabase.instance.client;

  final _pharmacyName = TextEditingController();
  final _contactPerson = TextEditingController();
  final _phone = TextEditingController();
  final _province = TextEditingController();
  final _district = TextEditingController();
  final _address = TextEditingController();
  final _licenseNumber = TextEditingController();

  PlatformFile? _licenseFile;
  bool _loading = false;
  bool _submitted = false;
  String? _error;

  @override
  void dispose() {
    _pharmacyName.dispose();
    _contactPerson.dispose();
    _phone.dispose();
    _province.dispose();
    _district.dispose();
    _address.dispose();
    _licenseNumber.dispose();
    super.dispose();
  }

  Future<void> _pickLicense() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['pdf', 'jpg', 'jpeg', 'png'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;

      if (file.bytes == null) {
        setState(() => _error =
            'Não foi possível ler o ficheiro. Escolha-o novamente.');
        return;
      }

      if (file.size > 10 * 1024 * 1024) {
        setState(() =>
            _error = 'O documento não pode ultrapassar 10 MB.');
        return;
      }

      setState(() {
        _licenseFile = file;
        _error = null;
      });
    } catch (e) {
      setState(() => _error = 'Erro ao selecionar o documento: $e');
    }
  }

  String _contentType(PlatformFile file) {
    final extension = file.extension?.toLowerCase();

    switch (extension) {
      case 'pdf':
        return 'application/pdf';
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      default:
        throw Exception('Formato de documento não permitido.');
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_licenseFile == null || _licenseFile!.bytes == null) {
      setState(
        () => _error = 'Anexe a licença da farmácia antes de continuar.',
      );
      return;
    }

    final user = _supabase.auth.currentUser;

    if (user == null) {
      setState(
        () => _error = 'A sua sessão terminou. Inicie sessão novamente.',
      );
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    String? uploadedPath;

    try {
      final profile = await _supabase
          .from('profiles')
          .select('role')
          .eq('id', user.id)
          .maybeSingle();

      if (profile == null || profile['role'] != 'customer') {
        throw Exception(
          'Esta candidatura só pode ser enviada por uma conta de cliente.',
        );
      }

      final file = _licenseFile!;
      final extension = file.extension!.toLowerCase();
      final fileName =
          'licenca_${DateTime.now().microsecondsSinceEpoch}.$extension';
      uploadedPath = '${user.id}/$fileName';

      await _supabase.storage
          .from('pharmacy-licenses')
          .uploadBinary(
            uploadedPath,
            file.bytes as Uint8List,
            fileOptions: FileOptions(
              contentType: _contentType(file),
              upsert: false,
            ),
          );

      await _supabase.from('pharmacy_applications').insert({
        'user_id': user.id,
        'pharmacy_name': _pharmacyName.text.trim(),
        'contact_person': _contactPerson.text.trim(),
        'phone': _phone.text.trim(),
        'province': _province.text.trim(),
        'district': _district.text.trim(),
        'address': _address.text.trim(),
        'license_number': _licenseNumber.text.trim(),
        'license_document_path': uploadedPath,
        'status': 'pending',
      });

      if (!mounted) return;

      setState(() {
        _submitted = true;
        _loading = false;
      });
    } on StorageException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = 'Não foi possível enviar a licença: ${e.message}';
      });
    } on PostgrestException catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.code == '23505'
            ? 'Já existe uma candidatura pendente para esta conta.'
            : 'Não foi possível guardar a candidatura: ${e.message}';
      });
    } catch (e) {
      if (!mounted) return;
      setState(() {
        _loading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
  }

  Widget _textField(
    String label,
    TextEditingController controller, {
    TextInputType keyboardType = TextInputType.text,
    int maxLines = 1,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 16),
      child: TextFormField(
        controller: controller,
        keyboardType: keyboardType,
        maxLines: maxLines,
        textCapitalization: TextCapitalization.sentences,
        decoration: InputDecoration(
          labelText: label,
          border: OutlineInputBorder(
            borderRadius: BorderRadius.circular(12),
          ),
        ),
        validator: (value) {
          if (value == null || value.trim().isEmpty) {
            return 'Este campo é obrigatório.';
          }
          return null;
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF16A34A);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Registar a minha farmácia'),
      ),
      body: SafeArea(
        child: _submitted
            ? Center(
                child: Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Icon(
                        Icons.check_circle_outline,
                        color: green,
                        size: 64,
                      ),
                      const SizedBox(height: 16),
                      const Text(
                        'Candidatura enviada',
                        style: TextStyle(
                          fontSize: 22,
                          fontWeight: FontWeight.bold,
                        ),
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 12),
                      const Text(
                        'A candidatura está pendente de análise. '
                        'A farmácia só poderá operar na plataforma '
                        'depois da aprovação manual pelo FARCLIK.',
                        textAlign: TextAlign.center,
                      ),
                      const SizedBox(height: 24),
                      FilledButton(
                        onPressed: () => Navigator.of(context).pop(),
                        child: const Text('Voltar'),
                      ),
                    ],
                  ),
                ),
              )
            : SingleChildScrollView(
                padding: const EdgeInsets.all(20),
                child: Form(
                  key: _formKey,
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Dados da farmácia',
                        style: TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Apenas farmácias devidamente licenciadas '
                        'poderão registar-se na plataforma.',
                      ),
                      const SizedBox(height: 24),
                      _textField('Nome da farmácia', _pharmacyName),
                      _textField('Nome do responsável', _contactPerson),
                      _textField(
                        'Telefone de contacto',
                        _phone,
                        keyboardType: TextInputType.phone,
                      ),
                      _textField('Província', _province),
                      _textField('Município', _district),
                      _textField(
                        'Endereço completo',
                        _address,
                        maxLines: 2,
                      ),
                      _textField(
                        'Número da licença',
                        _licenseNumber,
                      ),
                      const SizedBox(height: 4),
                      const Text(
                        'Licença da farmácia',
                        style: TextStyle(fontWeight: FontWeight.bold),
                      ),
                      const SizedBox(height: 8),
                      OutlinedButton.icon(
                        onPressed: _loading ? null : _pickLicense,
                        icon: const Icon(Icons.attach_file),
                        label: Text(
                          _licenseFile == null
                              ? 'Selecionar PDF ou imagem'
                              : _licenseFile!.name,
                        ),
                      ),
                      const Padding(
                        padding: EdgeInsets.only(top: 8, bottom: 20),
                        child: Text(
                          'Formatos aceites: PDF, JPG ou PNG. '
                          'Tamanho máximo: 10 MB.',
                          style: TextStyle(fontSize: 12),
                        ),
                      ),
                      if (_error != null) ...[
                        Text(
                          _error!,
                          style: const TextStyle(color: Colors.red),
                        ),
                        const SizedBox(height: 16),
                      ],
                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed:
                              _loading ? null : _submitApplication,
                          style: FilledButton.styleFrom(
                            backgroundColor: green,
                            padding: const EdgeInsets.symmetric(
                              vertical: 16,
                            ),
                          ),
                          child: _loading
                              ? const SizedBox(
                                  width: 22,
                                  height: 22,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text('Enviar candidatura'),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
      ),
    );
  }
}
