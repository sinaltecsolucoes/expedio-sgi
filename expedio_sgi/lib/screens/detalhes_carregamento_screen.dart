// lib/screens/detalhes_carregamento_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'gerenciar_carregamento_screen.dart';

class DetalhesCarregamentoScreen extends StatefulWidget {
  final int carregamentoId;
  final String numeroCarregamento;

  const DetalhesCarregamentoScreen({
    super.key,
    required this.carregamentoId,
    required this.numeroCarregamento,
  });

  @override
  State<DetalhesCarregamentoScreen> createState() =>
      _DetalhesCarregamentoScreenState();
}

class _DetalhesCarregamentoScreenState
    extends State<DetalhesCarregamentoScreen> {
  final ApiService _apiService = ApiService();
  final _formKey = GlobalKey<FormState>();

  final _lacreController = TextEditingController();
  final _placaController = TextEditingController();
  final _ordemExpedicaoController = TextEditingController();

  String _clienteOrganizador = '';
  String _data = '';
  String _horaInicio = '';

  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarDetalhes();
  }

  Future<void> _carregarDetalhes() async {
    final response = await _apiService.getCarregamentoHeader(
      widget.carregamentoId,
    );
    if (mounted) {
      setState(() {
        if (response['success'] == true) {
          final header = response['data'];
          _lacreController.text = header['car_lacre'] ?? '';
          _placaController.text = header['car_placa_veiculo'] ?? '';
          _ordemExpedicaoController.text = header['car_ordem_expedicao'] ?? '';
          _clienteOrganizador = header['nome_cliente'] ?? 'Não informado';
          _data = header['car_data'] ?? 'Não informado';
          _horaInicio = header['car_hora_inicio'] ?? 'Não informado';
        } else {
          _errorMessage = response['message'];
        }
        _isLoading = false;
      });
    }
  }

  Future<void> _atualizarDados() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isSaving = true;
    });

    final response = await _apiService.atualizarCarregamentoHeader(
      carregamentoId: widget.carregamentoId,
      lacre: _lacreController.text,
      placa: _placaController.text,
      horaInicio: _horaInicio,
      ordemExpedicao: _ordemExpedicaoController.text,
    );

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: response['success'] ? Colors.green : Colors.red,
        ),
      );
    }
  }

  void _avancarParaFilas() {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (context) => GerenciarCarregamentoScreen(
          carregamentoId: widget.carregamentoId,
          numeroCarregamento: widget.numeroCarregamento,
          ordemExpedicao: _ordemExpedicaoController.text,
        ),
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 1. TÍTULO ENCURTADO, COMO VOCÊ SUGERIU
        title: Text('Carreg. #${widget.numeroCarregamento}'),
        actions: [
          if (!_isLoading)
            IconButton(
              onPressed: _avancarParaFilas,
              icon: const Icon(Icons.arrow_forward),
              tooltip:
                  'Avançar para Filas', // Texto que aparece ao pressionar e segurar
            ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text('Erro: $_errorMessage'))
          : _buildForm(),
      bottomNavigationBar: _buildBottomSaveButton(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
        child: Column(
          children: [
            _buildInfoField('Cliente Organizador', _clienteOrganizador),
            _buildInfoField('Data', _data),
            _buildInfoField('Hora de Início', _horaInicio),
            const SizedBox(height: 16),
            TextFormField(
              controller: _placaController,
              decoration: const InputDecoration(
                labelText: 'Placa do Veículo',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _lacreController,
              decoration: const InputDecoration(
                labelText: 'Lacre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ordemExpedicaoController,
              decoration: const InputDecoration(
                labelText: 'Ordem de Expedição',
                border: OutlineInputBorder(),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoField(String label, String value) {
    return Card(
      margin: const EdgeInsets.only(bottom: 12),
      child: ListTile(
        title: Text(
          label,
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        subtitle: Text(
          value,
          style: const TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.bold,
            color: Colors.black,
          ),
        ),
      ),
    );
  }

  Widget _buildBottomSaveButton() {
    if (_isLoading) return const SizedBox.shrink();

    // 2. ADICIONADO SAFEAREA PARA NÃO FICAR ATRÁS DOS BOTÕES DO CELULAR
    return SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(8.0),
        child: _isSaving
            ? const Center(
                child: Padding(
                  padding: EdgeInsets.all(12.0),
                  child: CircularProgressIndicator(),
                ),
              )
            : ElevatedButton.icon(
                icon: const Icon(Icons.save),
                label: const Text('Atualizar Dados'),
                onPressed: _atualizarDados,
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  textStyle: const TextStyle(fontSize: 18),
                ),
              ),
      ),
    );
  }
}
