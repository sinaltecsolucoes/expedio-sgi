// lib/screens/novo_carregamento_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import '../services/api_service.dart';
import '../services/cache_service.dart';

class NovoCarregamentoScreen extends StatefulWidget {
  const NovoCarregamentoScreen({super.key});

  @override
  State<NovoCarregamentoScreen> createState() => _NovoCarregamentoScreenState();
}

class _NovoCarregamentoScreenState extends State<NovoCarregamentoScreen> {
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();

  int? _proximoNumero;
  List<Map<String, dynamic>> _clientes = [];
  Map<String, dynamic>? _clienteSelecionado;
  bool _isLoading = true;
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
            _proximoNumero = int.tryParse(responseApi['proximoNumero'].toString());
            _clientes = responseClientes;
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
    if (_proximoNumero == null || _clienteSelecionado == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Dados inválidos!')),
      );
      return;
    }

    final response = await _apiService.salvarCarregamentoHeader(
      numero: _proximoNumero!,
      data: DateFormat('yyyy-MM-dd').format(DateTime.now()),
      clienteOrganizadorId: _clienteSelecionado!['id'].toString(),
    );

    if (mounted) {
      if (response['success'] == true) {
        final carregamentoId = response['carregamentoId'];
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Cabeçalho salvo com sucesso! ID: $carregamentoId'),
            backgroundColor: Colors.green,
          ),
        );
        // TODO: Navegar para a próxima tela de leitura de QR Code
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Novo Carregamento'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Erro: $_errorMessage'))
              : _buildForm(),
    );
  }

  Widget _buildForm() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Número do Carregamento:',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            _proximoNumero.toString().padLeft(4, '0'),
            style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: Theme.of(context).primaryColor,
                ),
          ),
          const SizedBox(height: 24),
          Text(
            'Data:',
            style: Theme.of(context).textTheme.bodyLarge,
          ),
          Text(
            DateFormat('dd/MM/yyyy').format(DateTime.now()),
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 24),
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
                return ListTile(
                  title: Text(item['nome_display'] ?? ''),
                );
              },
            ),
            items: _clientes,
            itemAsString: (Map<String, dynamic> cliente) =>
                cliente['nome_display'] ?? 'Nome indisponível',
            dropdownDecoratorProps: const DropDownDecoratorProps(
              dropdownSearchDecoration: InputDecoration(
                labelText: 'Cliente Organizador',
                hintText: 'Selecione o Cliente Organizador',
                border: OutlineInputBorder(),
              ),
            ),
            onChanged: (newValue) {
              setState(() {
                _clienteSelecionado = newValue;
              });
            },
            selectedItem: _clienteSelecionado,
          ),
          const SizedBox(height: 32),
          ElevatedButton(
            onPressed: _clienteSelecionado == null ? null : _salvarCabecalho,
            style: ElevatedButton.styleFrom(
              padding: const EdgeInsets.symmetric(vertical: 16),
            ),
            child: Text(
              'Salvar e Continuar',
              style: const TextStyle(fontSize: 18),
            ),
          ),
        ],
      ),
    );
  }
}