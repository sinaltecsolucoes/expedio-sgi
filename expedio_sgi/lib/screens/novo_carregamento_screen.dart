// lib/screens/novo_carregamento_screen.dart

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:intl/intl.dart';
import 'package:dropdown_search/dropdown_search.dart';
import 'package:mask_text_input_formatter/mask_text_input_formatter.dart';
import '../services/api_service.dart';
import 'gerenciar_carregamento_screen.dart';

class UpperCaseTextFormatter extends TextInputFormatter {
  @override
  TextEditingValue formatEditUpdate(
    TextEditingValue oldValue,
    TextEditingValue newValue,
  ) {
    return TextEditingValue(
      text: newValue.text.toUpperCase(),
      selection: newValue.selection,
    );
  }
}

class NovoCarregamentoScreen extends StatefulWidget {
  final Map<String, dynamic>? dadosIniciaisOE;

  const NovoCarregamentoScreen({super.key, this.dadosIniciaisOE});

  @override
  State<NovoCarregamentoScreen> createState() => _NovoCarregamentoScreenState();
}

class _NovoCarregamentoScreenState extends State<NovoCarregamentoScreen> {
  final _formKey = GlobalKey<FormState>();
  final ApiService _apiService = ApiService();

  final _lacreController = TextEditingController();
  final _placaController = TextEditingController();
  final _ordemExpedicaoController = TextEditingController();

  final placaFormatter = MaskTextInputFormatter(
    mask: 'AAA-@### / AAA-@###',
    filter: {
      "#": RegExp(r'[0-9]'),
      "A": RegExp(r'[a-zA-Z]'),
      "@": RegExp(r'[a-zA-Z0-9]'), // Aceita letra ou número para Mercosul
    },
  );

  int? _proximoNumero;
  List<Map<String, dynamic>> _clientes = [];
  Map<String, dynamic>? _clienteSelecionado;
  TimeOfDay? _horaInicio;
  bool _isLoading = true;
  bool _isSaving = false;
  String? _errorMessage;

  bool get _isModoOE => widget.dadosIniciaisOE != null;

  @override
  void initState() {
    super.initState();
    _carregarDadosIniciais();
  }

  Future<void> _carregarDadosIniciais() async {
    try {
      final responseApi = await _apiService.getDadosNovoCarregamento();
      if (!mounted) return;

      if (responseApi['success'] == true) {
        setState(() {
          _proximoNumero = int.tryParse(
            responseApi['proximo_numero'].toString(),
          );
          _clientes = List<Map<String, dynamic>>.from(responseApi['clientes']);
          _horaInicio = TimeOfDay.now();

          // Se estamos no modo OE, apenas preenchemos o campo da OE
          if (_isModoOE) {
            final oeData = widget.dadosIniciaisOE!;
            _ordemExpedicaoController.text = oeData['oe_numero'].toString();
          }
          _isLoading = false;
        });
      } else {
        setState(() {
          _errorMessage = responseApi['message'] ?? 'Erro desconhecido.';
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
    // 1. O PONTO DE VERIFICAÇÃO FINAL: o valor do cliente
    final clienteSelecionado = _clienteSelecionado;
    if (clienteSelecionado == null) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Por favor, selecione um cliente.'),
            backgroundColor: Colors.red,
          ),
        );
      }
      return;
    }

    // 2. Garante que os outros campos do formulário são válidos
    if (_formKey.currentState?.validate() != true) {
      return;
    }

    setState(() => _isSaving = true);

    try {
      final response = await _apiService.salvarCarregamentoHeader(
        numero: _proximoNumero!.toString(),
        data: DateFormat('yyyy-MM-dd').format(DateTime.now()),
        // Usamos a variável local, que garantimos que não é nula
        clienteOrganizadorId: clienteSelecionado['id'].toString(),
        lacre: _lacreController.text,
        placa: _placaController.text,
        horaInicio: _horaInicio!.format(context),
        ordemExpedicaoId: _isModoOE
            ? widget.dadosIniciaisOE!['oe_id']?.toString()
            : null,
        tipo: _isModoOE ? 'ORDEM_EXPEDICAO' : 'AVULSA',
      );

      if (mounted) {
        if (response['success'] == true) {
          final carregamentoId = response['carregamentoId'];
          Navigator.of(context).pushReplacement(
            MaterialPageRoute(
              builder: (context) => GerenciarCarregamentoScreen(
                carregamentoId: carregamentoId,
                numeroCarregamento: _proximoNumero.toString(),
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
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao salvar: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_isModoOE ? 'Carregar por OE' : 'Nova Saída Avulsa'),
      ),
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
              'Número: ${_proximoNumero?.toString().padLeft(4, '0') ?? 'N/A'}',
              style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),

            if (_isModoOE) ...[
              TextFormField(
                controller: _ordemExpedicaoController,
                readOnly: true, // Bloqueado
                decoration: const InputDecoration(
                  labelText: 'Baseado na Ordem de Expedição Nº',
                  border: OutlineInputBorder(),
                  filled: true,
                ),
              ),
              const SizedBox(height: 16),
            ],

            DropdownSearch<Map<String, dynamic>>(
              items: _clientes,
              selectedItem: _clienteSelecionado,
              onChanged: (value) => setState(() => _clienteSelecionado = value),
              itemAsString: (item) => item['text'] ?? '',
              popupProps: const PopupProps.menu(
                showSearchBox: true,
                searchFieldProps: TextFieldProps(
                  decoration: InputDecoration(labelText: "Pesquisar cliente"),
                ),
              ),
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(
                  labelText: 'Cliente Organizador',
                  border: OutlineInputBorder(),
                ),
              ),
              // Adiciona um validador para campo obrigatório
              validator: (value) => value == null ? 'Campo obrigatório' : null,

              // A nova função para comparar os itens
              compareFn: (item, selectedItem) {
                // Compara os itens pelo 'ent_codigo', que é o identificador único
                return item['id'] == selectedItem['id'];
              },
            ),

            const SizedBox(height: 16),

            TextFormField(
              controller: _placaController,
              // 1. APLICAMOS OS FORMATADORES
              inputFormatters: [
                // Primeiro, a máscara que força o formato
                placaFormatter,
                // Segundo, o formatador que garante as maiúsculas
                UpperCaseTextFormatter(),
              ],
              textCapitalization: TextCapitalization.characters,
              decoration: const InputDecoration(
                labelText: 'Placa(s) do Veículo',
                hintText: 'AAA-1234 / BBB-5C67',
                border: OutlineInputBorder(),
              ),
              // 2. O VALIDADOR FINAL (ainda importante)
              validator: (value) {
                if (value == null || value.trim().isEmpty) {
                  return 'Campo obrigatório';
                }
                // A validação pode ser simplificada, pois a máscara já ajuda muito
                if (value.trim().length < 8) {
                  // Mínimo para uma placa com hífen
                  return 'Placa incompleta.';
                }
                return null;
              },
            ),

            const SizedBox(height: 16),
            TextFormField(
              controller: _lacreController,
              decoration: const InputDecoration(
                labelText: 'Lacre',
                border: OutlineInputBorder(),
              ),
            ),
            const SizedBox(height: 32),
            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
                    onPressed: _salvarCabecalho,
                    child: const Text(
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
