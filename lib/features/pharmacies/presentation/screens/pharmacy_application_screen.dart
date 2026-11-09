
import 'dart:typed_data';

import 'package:file_picker/file_picker.dart';
import 'package:flutter/material.dart';
import 'package:flutter_map/flutter_map.dart';
import 'package:geolocator/geolocator.dart';
import 'package:latlong2/latlong.dart';
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
  PlatformFile? _pharmacyPhotoFile;

  LatLng? _pharmacyLocation;

  bool _loading = false;
  bool _locationLoading = false;
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

  Future<void> _getCurrentLocation() async {
    setState(() {
      _locationLoading = true;
      _error = null;
    });

    try {
      final serviceEnabled =
          await Geolocator.isLocationServiceEnabled();

      if (!serviceEnabled) {
        throw Exception(
          'Active o GPS do dispositivo para continuar.',
        );
      }

      LocationPermission permission =
          await Geolocator.checkPermission();

      if (permission == LocationPermission.denied) {
        permission = await Geolocator.requestPermission();
      }

      if (permission == LocationPermission.denied) {
        throw Exception(
          'A autorização de localização foi recusada.',
        );
      }

      if (permission == LocationPermission.deniedForever) {
        throw Exception(
          'A localização está bloqueada nas definições. '
          'Autorize o acesso à localização da aplicação.',
        );
      }

      final position = await Geolocator.getCurrentPosition(
        locationSettings: const LocationSettings(
          accuracy: LocationAccuracy.high,
          timeLimit: Duration(seconds: 30),
        ),
      );

      if (!mounted) return;

      setState(() {
        _pharmacyLocation = LatLng(
          position.latitude,
          position.longitude,
        );
        _locationLoading = false;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _locationLoading = false;
        _error = e.toString().replaceFirst('Exception: ', '');
      });
    }
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
        setState(() {
          _error = 'Não foi possível ler o ficheiro. Escolha-o novamente.';
        });
        return;
      }

      if (file.size > 10 * 1024 * 1024) {
        setState(() {
          _error = 'O documento não pode ultrapassar 10 MB.';
        });
        return;
      }

      setState(() {
        _licenseFile = file;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Erro ao selecionar o documento: $e';
      });
    }
  }

  Future<void> _pickPharmacyPhoto() async {
    try {
      final result = await FilePicker.platform.pickFiles(
        type: FileType.custom,
        allowedExtensions: ['jpg', 'jpeg', 'png', 'webp'],
        withData: true,
      );

      if (result == null || result.files.isEmpty) return;

      final file = result.files.single;

      if (file.bytes == null) {
        setState(() {
          _error =
              'Não foi possível ler a fotografia. Escolha-a novamente.';
        });
        return;
      }

      if (file.size > 5 * 1024 * 1024) {
        setState(() {
          _error = 'A fotografia não pode ultrapassar 5 MB.';
        });
        return;
      }

      setState(() {
        _pharmacyPhotoFile = file;
        _error = null;
      });
    } catch (e) {
      if (!mounted) return;

      setState(() {
        _error = 'Erro ao selecionar a fotografia: $e';
      });
    }
  }

  String _licenseContentType(PlatformFile file) {
    switch (file.extension?.toLowerCase()) {
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

  String _photoContentType(PlatformFile file) {
    switch (file.extension?.toLowerCase()) {
      case 'jpg':
      case 'jpeg':
        return 'image/jpeg';
      case 'png':
        return 'image/png';
      case 'webp':
        return 'image/webp';
      default:
        throw Exception('Formato de fotografia não permitido.');
    }
  }

  Future<void> _removeUploadedFiles(
    String? licensePath,
    String? photoPath,
  ) async {
    if (photoPath != null) {
      try {
        await _supabase.storage
            .from('pharmacy-photos')
            .remove([photoPath]);
      } catch (_) {}
    }

    if (licensePath != null) {
      try {
        await _supabase.storage
            .from('pharmacy-licenses')
            .remove([licensePath]);
      } catch (_) {}
    }
  }

  Future<void> _submitApplication() async {
    if (!_formKey.currentState!.validate()) return;

    if (_pharmacyLocation == null) {
      setState(() {
        _error = 'Obtenha e confirme a localização GPS da farmácia.';
      });
      return;
    }

    if (_pharmacyPhotoFile == null ||
        _pharmacyPhotoFile!.bytes == null) {
      setState(() {
        _error = 'Anexe uma fotografia frontal da farmácia.';
      });
      return;
    }

    if (_licenseFile == null || _licenseFile!.bytes == null) {
      setState(() {
        _error = 'Anexe a licença da farmácia antes de continuar.';
      });
      return;
    }

    final user = _supabase.auth.currentUser;

    if (user == null) {
      setState(() {
        _error = 'A sua sessão terminou. Inicie sessão novamente.';
      });
      return;
    }

    setState(() {
      _loading = true;
      _error = null;
    });

    String? licensePath;
    String? photoPath;

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

      final timestamp = DateTime.now().microsecondsSinceEpoch;

      final license = _licenseFile!;
      final licenseExtension = license.extension!.toLowerCase();

      licensePath =
          '${user.id}/licenca_${timestamp}.$licenseExtension';

      await _supabase.storage
          .from('pharmacy-licenses')
          .uploadBinary(
            licensePath,
            license.bytes as Uint8List,
            fileOptions: FileOptions(
              contentType: _licenseContentType(license),
              upsert: false,
            ),
          );

      final photo = _pharmacyPhotoFile!;
      final photoExtension = photo.extension!.toLowerCase();

      photoPath =
          '${user.id}/farmacia_${timestamp}.$photoExtension';

      await _supabase.storage
          .from('pharmacy-photos')
          .uploadBinary(
            photoPath,
            photo.bytes as Uint8List,
            fileOptions: FileOptions(
              contentType: _photoContentType(photo),
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
        'license_document_path': licensePath,
        'pharmacy_photo_path': photoPath,
        'latitude': _pharmacyLocation!.latitude,
        'longitude': _pharmacyLocation!.longitude,
        'status': 'pending',
      });

      if (!mounted) return;

      setState(() {
        _submitted = true;
        _loading = false;
      });
    } catch (e) {
      await _removeUploadedFiles(licensePath, photoPath);

      if (!mounted) return;

      String message;

      if (e is StorageException) {
        message = 'Não foi possível enviar o ficheiro: ${e.message}';
      } else if (e is PostgrestException) {
        message = e.code == '23505'
            ? 'Já existe uma candidatura pendente para esta conta.'
            : 'Não foi possível guardar a candidatura: ${e.message}';
      } else {
        message = e.toString().replaceFirst('Exception: ', '');
      }

      setState(() {
        _loading = false;
        _error = message;
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

  Widget _buildLocationSection() {
    const green = Color(0xFF16A34A);
    final location = _pharmacyLocation;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Localização exacta da farmácia',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Obtenha a posição GPS da farmácia. Depois poderá '
          'ajustar o marcador no mapa para indicar o local exacto.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        SizedBox(
          width: double.infinity,
          child: OutlinedButton.icon(
            onPressed: _loading || _locationLoading
                ? null
                : _getCurrentLocation,
            icon: _locationLoading
                ? const SizedBox(
                    width: 18,
                    height: 18,
                    child: CircularProgressIndicator(strokeWidth: 2),
                  )
                : const Icon(Icons.my_location),
            label: Text(
              _locationLoading
                  ? 'A obter localização...'
                  : location == null
                      ? 'Obter localização GPS'
                      : 'Actualizar localização GPS',
            ),
          ),
        ),
        if (location != null) ...[
          const SizedBox(height: 12),
          ClipRRect(
            borderRadius: BorderRadius.circular(14),
            child: SizedBox(
              height: 280,
              child: FlutterMap(
                key: ValueKey(
                  '${location.latitude}_${location.longitude}',
                ),
                options: MapOptions(
                  initialCenter: location,
                  initialZoom: 17,
                  onTap: (tapPosition, point) {
                    setState(() {
                      _pharmacyLocation = point;
                      _error = null;
                    });
                  },
                ),
                children: [
                  TileLayer(
                    urlTemplate:
                        'https://tile.openstreetmap.org/{z}/{x}/{y}.png',
                    userAgentPackageName: 'ao.farclik.app',
                  ),
                  MarkerLayer(
                    markers: [
                      Marker(
                        point: location,
                        width: 50,
                        height: 60,
                        child: const Icon(
                          Icons.location_on,
                          color: Color(0xFFDC2626),
                          size: 48,
                        ),
                      ),
                    ],
                  ),
                  RichAttributionWidget(
                    attributions: [
                      TextSourceAttribution('OpenStreetMap contributors'),
                    ],
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 10),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: const Color(0xFFDCFCE7),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Row(
                  children: [
                    Icon(Icons.check_circle, color: green, size: 19),
                    SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        'Localização seleccionada',
                        style: TextStyle(
                          color: Color(0xFF166534),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 8),
                Text(
                  'Latitude: ${location.latitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 13),
                ),
                Text(
                  'Longitude: ${location.longitude.toStringAsFixed(6)}',
                  style: const TextStyle(fontSize: 13),
                ),
              ],
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Toque no mapa para ajustar a posição do marcador. '
            'Confirme que o ponto corresponde à localização real '
            'da farmácia.',
            style: TextStyle(fontSize: 12),
          ),
        ] else ...[
          Container(
            width: double.infinity,
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: const Color(0xFFF1F5F9),
              borderRadius: BorderRadius.circular(12),
            ),
            child: const Column(
              children: [
                Icon(
                  Icons.location_searching,
                  size: 36,
                  color: Colors.blueGrey,
                ),
                SizedBox(height: 8),
                Text(
                  'A localização ainda não foi definida.',
                  textAlign: TextAlign.center,
                ),
              ],
            ),
          ),
        ],
        const SizedBox(height: 24),
      ],
    );
  }

  Widget _buildPhotoSection() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Fotografia frontal da farmácia',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        const SizedBox(height: 8),
        const Text(
          'Envie uma fotografia real, nítida e frontal da fachada. '
          'Será utilizada como imagem de capa após a aprovação.',
          style: TextStyle(fontSize: 13),
        ),
        const SizedBox(height: 12),
        if (_pharmacyPhotoFile?.bytes != null) ...[
          ClipRRect(
            borderRadius: BorderRadius.circular(12),
            child: Image.memory(
              _pharmacyPhotoFile!.bytes!,
              width: double.infinity,
              height: 190,
              fit: BoxFit.cover,
            ),
          ),
          const SizedBox(height: 8),
        ],
        OutlinedButton.icon(
          onPressed: _loading ? null : _pickPharmacyPhoto,
          icon: const Icon(Icons.add_a_photo_outlined),
          label: Text(
            _pharmacyPhotoFile == null
                ? 'Selecionar fotografia'
                : 'Alterar fotografia',
          ),
        ),
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 20),
          child: Text(
            'Formatos aceites: JPG, JPEG, PNG ou WebP. '
            'Tamanho máximo: 5 MB.',
            style: TextStyle(fontSize: 12),
          ),
        ),
      ],
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
                      _buildLocationSection(),
                      _buildPhotoSection(),
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
                          onPressed: _loading
                              ? null
                              : _submitApplication,
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
