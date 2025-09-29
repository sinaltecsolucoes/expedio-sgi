import 'package:flutter/material.dart';
import '../models/operacao_modo.dart';
import '../services/api_service.dart';
import 'leitura_qrcode_screen.dart';

class EntradasScreen extends StatefulWidget {
  const EntradasScreen({super.key});

  @override
  State<EntradasScreen> createState() => _EntradasScreenState();
}

class _EntradasScreenState extends State<EntradasScreen> {
  final ApiService _apiService = ApiService();

  // Variáveis de estado para controlar a tela
  bool _isLoadingCamaras = true;
  bool _isLoadingEnderecos = false;
  bool _isLoadingEntradas = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _camaras = [];
  List<Map<String, dynamic>> _enderecos = [];

  Map<String, dynamic>? _selectedCamara;
  Map<String, dynamic>? _selectedEndereco;

  @override
  void initState() {
    super.initState();
    _fetchCamaras();
  }

  /// Busca a lista de câmaras da API ao iniciar a tela.
  Future<void> _fetchCamaras() async {
    try {
      final camaras = await _apiService.getCamaras();
      if (mounted) {
        setState(() {
          _camaras = camaras;
          _isLoadingCamaras = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingCamaras = false;
        });
      }
    }
  }

  /// Busca os endereços correspondentes quando uma câmara é selecionada.
  Future<void> _fetchEnderecos(int camaraId) async {
    setState(() {
      _isLoadingEnderecos = true;
      _errorMessage = null;
      _enderecos = []; // Limpa a lista antiga
      _selectedEndereco = null; // Reseta o endereço selecionado
    });

    try {
      final enderecos = await _apiService.getEnderecosPorCamara(camaraId);
      if (mounted) {
        setState(() {
          _enderecos = enderecos;
          _isLoadingEnderecos = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoadingEnderecos = false;
        });
      }
    }
  }

  Widget _buildBody() {
    if (_isLoadingCamaras) {
      return const Center(child: CircularProgressIndicator());
    }

    if (_errorMessage != null) {
      return Center(
        child: Padding(
          padding: const EdgeInsets.all(16.0),
          child: Text('Erro: $_errorMessage', textAlign: TextAlign.center),
        ),
      );
    }

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Dropdown para selecionar a CÂMARA
          DropdownButtonFormField<Map<String, dynamic>>(
            initialValue: _selectedCamara,
            isExpanded: true,
            hint: const Text('Selecione a Câmara'),
            items: _camaras.map((camara) {
              return DropdownMenuItem(
                value: camara,
                child: Text(camara['camara_nome'] ?? 'Nome inválido'),
              );
            }).toList(),
            onChanged: (newValue) {
              setState(() {
                _selectedCamara = newValue;
              });
              if (newValue != null) {
                // Busca os endereços da câmara selecionada
                //_fetchEnderecos(int.parse(newValue['camara_id']));
                _fetchEnderecos(newValue['camara_id'] as int);
              }
            },
            decoration: const InputDecoration(
              labelText: 'Câmara de Destino',
              border: OutlineInputBorder(),
            ),
          ),
          const SizedBox(height: 20),

          // Dropdown para selecionar o ENDEREÇO
          DropdownButtonFormField<Map<String, dynamic>>(
            initialValue: _selectedEndereco,
            isExpanded: true,
            hint: Text(
              _selectedCamara == null
                  ? 'Selecione uma câmara primeiro'
                  : 'Selecione o Endereço',
            ),
            onChanged: _selectedCamara == null
                ? null
                : (newValue) {
                    setState(() {
                      _selectedEndereco = newValue;
                    });
                  },
            items: _enderecos.map((endereco) {
              return DropdownMenuItem(
                value: endereco,
                child: Text(
                  endereco['endereco_completo'] ?? 'Endereço inválido',
                ),
              );
            }).toList(),
            decoration: InputDecoration(
              labelText: 'Endereço de Destino',
              border: const OutlineInputBorder(),
              suffixIcon: _isLoadingEnderecos
                  ? const Padding(
                      padding: EdgeInsets.all(8.0),
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : null,
            ),
          ),
          const SizedBox(height: 40),

          // Botão para LER QR CODE
          ElevatedButton.icon(
            icon: const Icon(Icons.qr_code_scanner),
            label: const Text('LER QR CODES'),
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
              textStyle: const TextStyle(fontSize: 18),
            ),
            onPressed: (_selectedCamara != null && _selectedEndereco != null)
                ? () {
                    /*final int enderecoId = int.parse(
                      _selectedEndereco!['endereco_id'],
                    );*/
                    final int enderecoId =
                        _selectedEndereco!['endereco_id'] as int;

                    print('Navegando para leitura de QR Code...');
                    print('Câmara ID: ${_selectedCamara!['camara_id']}');
                    print('Endereço ID: $enderecoId');

                    Navigator.push(
                      context,
                      MaterialPageRoute(
                        //builder: (context) => LeituraQrcodeScreen(
                        builder: (context) => LeituraQrCodeScreen(
                          modo: OperacaoModo.entrada,
                          enderecoId: enderecoId,
                        ),
                      ),
                    );
                  }
                : null,
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Entrada de Estoque')),
      body: _buildBody(),
    );
  }
}
