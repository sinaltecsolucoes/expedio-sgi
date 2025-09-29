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

  // Variáveis de estado
  bool _isLoadingCamaras = true;
  bool _isLoadingEnderecos = false;
  bool _isLoadingEntradas = false;
  String? _errorMessage;

  List<Map<String, dynamic>> _camaras = [];
  List<Map<String, dynamic>> _enderecos = [];
  List<Map<String, dynamic>> _entradasDoDia = [];

  Map<String, dynamic>? _selectedCamara;
  Map<String, dynamic>? _selectedEndereco;

  @override
  void initState() {
    super.initState();
    _fetchCamaras();
  }

  Future<void> _fetchCamaras() async {
    // Lógica para buscar câmaras (inalterada)
    try {
      final camaras = await _apiService.getCamaras();
      if (mounted)
        setState(() {
          _camaras = camaras;
          _isLoadingCamaras = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = e.toString();
          _isLoadingCamaras = false;
        });
    }
  }

  Future<void> _onCamaraSelected(Map<String, dynamic>? newCamara) async {
    setState(() {
      _selectedCamara = newCamara;
      _isLoadingEnderecos = true;
      _enderecos = [];
      _selectedEndereco = null;
      _entradasDoDia = []; // Limpa a lista de entradas ao trocar de câmara
    });

    if (newCamara == null) {
      setState(() => _isLoadingEnderecos = false);
      return;
    }

    try {
      final enderecos = await _apiService.getEnderecosPorCamara(
        newCamara['camara_id'] as int,
      );
      if (mounted)
        setState(() {
          _enderecos = enderecos;
          _isLoadingEnderecos = false;
        });
    } catch (e) {
      if (mounted)
        setState(() {
          _errorMessage = e.toString();
          _isLoadingEnderecos = false;
        });
    }
  }

  Future<void> _onEnderecoSelected(Map<String, dynamic>? newEndereco) async {
    setState(() {
      _selectedEndereco = newEndereco;
      _entradasDoDia = []; // Limpa a lista antiga
    });
    if (newEndereco != null) {
      _fetchEntradasDoDia(newEndereco['endereco_id'] as int);
    }
  }

  Future<void> _fetchEntradasDoDia(int enderecoId) async {
    setState(() => _isLoadingEntradas = true);
    try {
      final entradas = await _apiService.getEntradasDoDia(enderecoId);
      if (mounted)
        setState(() {
          _entradasDoDia = entradas;
          _isLoadingEntradas = false;
        });
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
        );
        setState(() => _isLoadingEntradas = false);
      }
    }
  }

  // Ações da Tabela
  Future<void> _excluirEntrada(int alocacaoId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Confirmar Exclusão'),
        content: const Text(
          'Tem a certeza de que deseja excluir este registo? A ação não pode ser desfeita.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(true),
            child: const Text('Excluir'),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        await _apiService.excluirAlocacao(alocacaoId);
        _fetchEntradasDoDia(
          _selectedEndereco!['endereco_id'] as int,
        ); // Atualiza a lista
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
      }
    }
  }

  Future<void> _editarEntrada(Map<String, dynamic> entrada) async {
    final qtdController = TextEditingController(
      text: entrada['quantidade'].toString(),
    );
    final novoValor = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text('Editar Quantidade\n${entrada['produto']}'),
        content: TextField(
          controller: qtdController,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          autofocus: true,
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(ctx).pop(qtdController.text),
            child: const Text('Salvar'),
          ),
        ],
      ),
    );

    if (novoValor != null) {
      final double? novaQtd = double.tryParse(novoValor);
      if (novaQtd == null) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Valor inválido.'),
            backgroundColor: Colors.orange,
          ),
        );
        return;
      }
      try {
        await _apiService.editarQuantidade(entrada['alocacao_id'], novaQtd);
        _fetchEntradasDoDia(
          _selectedEndereco!['endereco_id'] as int,
        ); // Atualiza a lista
      } catch (e) {
        if (mounted)
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text(e.toString()), backgroundColor: Colors.red),
          );
      }
    }
  }

  void _navegarParaLeitura() async {
    final result = await Navigator.push<bool>(
      context,
      MaterialPageRoute(
        builder: (context) => LeituraQrCodeScreen(
          modo: OperacaoModo.entrada,
          enderecoId: _selectedEndereco!['endereco_id'] as int,
        ),
      ),
    );
    // Se a tela de leitura retornar 'true' (opcional), atualizamos a lista
    if (result == true && _selectedEndereco != null) {
      _fetchEntradasDoDia(_selectedEndereco!['endereco_id'] as int);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Registrar Entrada de Estoque')),
      body: _isLoadingCamaras
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text('Erro: $_errorMessage'))
          : Padding(
              padding: const EdgeInsets.all(16.0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedCamara,
                    onChanged: _onCamaraSelected,
                    items: _camaras
                        .map(
                          (c) => DropdownMenuItem(
                            value: c,
                            child: Text(c['camara_nome']),
                          ),
                        )
                        .toList(),
                    hint: const Text('Selecione a Câmara'),
                  ),
                  const SizedBox(height: 16),
                  DropdownButtonFormField<Map<String, dynamic>>(
                    value: _selectedEndereco,
                    onChanged: _onEnderecoSelected,
                    items: _enderecos
                        .map(
                          (e) => DropdownMenuItem(
                            value: e,
                            child: Text(e['endereco_completo']),
                          ),
                        )
                        .toList(),
                    hint: Text(
                      _selectedCamara == null
                          ? 'Selecione uma câmara'
                          : 'Selecione o Endereço',
                    ),
                  ),
                  const SizedBox(height: 24),
                  ElevatedButton.icon(
                    icon: const Icon(Icons.qr_code_scanner),
                    label: const Text('LER QR CODES'),
                    onPressed: _selectedEndereco == null
                        ? null
                        : _navegarParaLeitura,
                  ),
                  const Divider(height: 32),

                  const Text(
                    'Entradas de Hoje Neste Endereço',
                    style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Expanded(
                    child: _isLoadingEntradas
                        ? const Center(child: CircularProgressIndicator())
                        : _entradasDoDia.isEmpty
                        ? const Center(
                            child: Text(
                              'Nenhuma entrada registrada hoje para este endereço.',
                            ),
                          )
                        : ListView.separated(
                            itemCount: _entradasDoDia.length,
                            separatorBuilder: (context, index) =>
                                const Divider(),
                            itemBuilder: (context, index) {
                              final entrada = _entradasDoDia[index];
                              return Padding(
                                padding: const EdgeInsets.symmetric(
                                  vertical: 8.0,
                                ),
                                child: Column(
                                  crossAxisAlignment: CrossAxisAlignment.start,
                                  children: [
                                    // --- LINHA 1: PRODUTO E LOTE ---
                                    Row(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Expanded(
                                          child: Text(
                                            entrada['produto'] ??
                                                'Produto desconhecido',
                                            style: const TextStyle(
                                              fontWeight: FontWeight.bold,
                                              fontSize: 16,
                                            ),
                                          ),
                                        ),
                                        const SizedBox(width: 16),
                                        Text(
                                          entrada['lote'] ?? 'Lote N/A',
                                          style: const TextStyle(
                                            fontWeight: FontWeight.bold,
                                            fontSize: 16,
                                          ),
                                        ),
                                      ],
                                    ),
                                    const SizedBox(height: 8),
                                    // --- LINHA 2: QUANTIDADE E AÇÕES ---
                                    Row(
                                      mainAxisAlignment:
                                          MainAxisAlignment.spaceBetween,
                                      children: [
                                        Text(
                                          'Quantidade: ${entrada['quantidade']}',
                                          style: TextStyle(
                                            color: Colors.grey[700],
                                          ),
                                        ),
                                        Row(
                                          mainAxisSize: MainAxisSize.min,
                                          children: [
                                            IconButton(
                                              icon: const Icon(
                                                Icons.edit,
                                                color: Colors.blueAccent,
                                              ),
                                              onPressed: () =>
                                                  _editarEntrada(entrada),
                                              tooltip: 'Editar Quantidade',
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                            IconButton(
                                              icon: const Icon(
                                                Icons.delete,
                                                color: Colors.redAccent,
                                              ),
                                              onPressed: () => _excluirEntrada(
                                                entrada['alocacao_id'],
                                              ),
                                              tooltip: 'Excluir Entrada',
                                              padding:
                                                  const EdgeInsets.symmetric(
                                                    horizontal: 12,
                                                  ),
                                              constraints:
                                                  const BoxConstraints(),
                                            ),
                                          ],
                                        ),
                                      ],
                                    ),
                                  ],
                                ),
                              );
                            },
                          ),
                  ),
                ],
              ),
            ),
    );
  }
}
