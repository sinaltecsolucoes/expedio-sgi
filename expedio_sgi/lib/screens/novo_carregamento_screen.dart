// lib/screens/novo_carregamento_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart'; // Importa o pacote de busca
import '../services/api_service.dart';
import '../services/cache_service.dart';
import 'leitura_qrcode_screen.dart';
import 'gerenciar_carregamento_screen.dart';

class NovoCarregamentoScreen extends StatefulWidget {
  const NovoCarregamentoScreen({super.key});

  @override
  State<NovoCarregamentoScreen> createState() => _NovoCarregamentoScreenState();
}

class _NovoCarregamentoScreenState extends State<NovoCarregamentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();

  final _lacreController = TextEditingController();
  final _placaController = TextEditingController();
  final _ordemExpedicaoController = TextEditingController();

  int? _proximoNumero;
  List<Map<String, dynamic>> _clientes = [];
  Map<String, dynamic>? _clienteSelecionado;
  TimeOfDay? _horaInicio;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    try {
      final results = await Future.wait([
        _apiService.getDadosNovoCarregamento(),
        _cacheService.getClientes(),
      ]);

      final responseApi = results[0] as Map<String, dynamic>;
      final responseClientes = results[1] as List<Map<String, dynamic>>;

      if (mounted) {
        setState(() {
          if (responseApi['success'] == true) {
            _proximoNumero = int.tryParse(
              responseApi['proximoNumero'].toString(),
            );
            _clientes = responseClientes;

            _horaInicio = TimeOfDay.now();
            if (_proximoNumero != null) {
              final numeroFormatado = _proximoNumero.toString().padLeft(4, '0');
              final mesAno = DateFormat('MM.yyyy').format(DateTime.now());
              _ordemExpedicaoController.text = '$numeroFormatado.$mesAno';
            }
          } else {
            _errorMessage = responseApi['message'] ?? 'Erro desconhecido.';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  Future<void> _salvarCabecalho() async {
    if (_formKey.currentState?.validate() != true) return;

    setState(() {
      _isSaving = true;
    });

    final numeroFormatado = _proximoNumero!.toString().padLeft(4, '0');

    final response = await _apiService.salvarCarregamentoHeader(
      numero: numeroFormatado,
      data: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      clienteOrganizadorId: _clienteSelecionado!['ent_codigo'].toString(),
      lacre: _lacreController.text,
      placa: _placaController.text,
      horaInicio: _horaInicio!.format(context),
      ordemExpedicao: _ordemExpedicaoController.text,
    );

    setState(() {
      _isSaving = false;
    });

    if (mounted) {
      if (response['success'] == true) {
        final carregamentoId = response['carregamentoId'];
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GerenciarCarregamentoScreen(
              carregamentoId: carregamentoId,
              numeroCarregamento: numeroFormatado, // Passamos o número para exibir no título
            ),
          ),
        );

      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _selecionarHora() async {
    final TimeOfDay? horaSelecionada = await showTimePicker(
      context: context,
      initialTime: _horaInicio ?? TimeOfDay.now(),
    );
    if (horaSelecionada != null) {
      setState(() {
        _horaInicio = horaSelecionada;
      });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Novo Carregamento')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text('Erro: $_errorMessage'))
          : _buildForm(),
    );
  }

  Widget _buildForm() {
    return Form(
      key: _formKey,
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Número: ${_proximoNumero != null ? _proximoNumero!.toString().padLeft(4, '0') : 'N/A'}',
            ),
            const SizedBox(height: 16),
            DropdownSearch<Map<String, dynamic>>(
              popupProps: PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(
                    labelText: "Pesquisar cliente",
                    border: OutlineInputBorder(),
                  ),
                ),
                itemBuilder: (context, item, isSelected) {
                  return ListTile(title: Text(item['nome_display'] ?? ''));
                },
              ),
              items: _clientes,
              itemAsString: (Map<String, dynamic> cliente) =>
                  cliente['nome_display'] ?? '',
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Cliente Organizador',
                  border: OutlineInputBorder(),
                ),
              ),
              onChanged: (newValue) {
                setState(() {
                  _clienteSelecionado = newValue;
                });
              },
              selectedItem: _clienteSelecionado,
              validator: (value) => value == null || value['ent_codigo'] == null
                  ? 'Selecione um cliente válido'
                  : null,
            ),
            const SizedBox(height: 24),
            TextFormField(
              controller: _lacreController,
              decoration: const InputDecoration(
                labelText: 'Lacre',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _placaController,
              decoration: const InputDecoration(
                labelText: 'Placa do Veículo',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null ||
                      value.isEmpty ||
                      !RegExp(r'^[A-Z]{3}\d[A-Z0-9][0-9]{2}$').hasMatch(value))
                  ? 'Placa inválida (ex.: ABC1D23)'
                  : null,
            ),
            const SizedBox(height: 16),
            InkWell(
              onTap: _selecionarHora,
              child: InputDecorator(
                decoration: const InputDecoration(
                  labelText: 'Hora de Início',
                  border: OutlineInputBorder(),
                ),
                child: Text(
                  _horaInicio?.format(context) ?? 'Selecione uma hora',
                ),
              ),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _ordemExpedicaoController,
              decoration: const InputDecoration(
                labelText: 'Ordem de Expedição',
                border: OutlineInputBorder(),
              ),
              validator: (value) =>
                  (value == null || value.isEmpty) ? 'Campo obrigatório' : null,
            ),
            const SizedBox(height: 32),
            _isSaving
                ? Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: () {
                      if (_formKey.currentState?.validate() ?? false) {
                        _salvarCabecalho();
                      }
                    },
                    style: ElevatedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                    ),
                    child: Text(
                      'Salvar e Continuar',
                      style: TextStyle(fontSize: 18),
                    ),
                  ),
          ],
        ),
      ),
    );
  }
}
