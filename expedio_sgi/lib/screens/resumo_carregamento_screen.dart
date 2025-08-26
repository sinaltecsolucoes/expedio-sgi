// lib/screens/resumo_carregamento_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/api_service.dart';
//import 'visualizar_foto_screen.dart';
import 'galeria_fila_screen.dart';

class ResumoCarregamentoScreen extends StatefulWidget {
  final String carregamentoId;

  const ResumoCarregamentoScreen({super.key, required this.carregamentoId});

  @override
  State<ResumoCarregamentoScreen> createState() =>
      _ResumoCarregamentoScreenState();
}

class _ResumoCarregamentoScreenState extends State<ResumoCarregamentoScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _dadosCarregamento;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  Future<void> _carregarResumo() async {
    try {
      final response = await _apiService.getResumoCarregamento(
        widget.carregamentoId,
      );

      if (mounted) {
        setState(() {
          if (response['success'] == true) {
            _dadosCarregamento = response['data'];
          } else {
            _errorMessage = response['message'] ?? 'Erro desconhecido.';
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

  // Função para formatar data e hora
  String _formatarData(String? dataString, {bool apenasHora = false}) {
    if (dataString == null || dataString.isEmpty) return 'N/A';
    try {
      final DateTime date = DateTime.parse(dataString);
      if (apenasHora) {
        return DateFormat('HH:mm').format(date);
      }
      return DateFormat('dd/MM/yyyy').format(date);
    } catch (e) {
      // Retorna o valor original se não for uma data/hora válida (como "10:30")
      return dataString;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        // 1. TÍTULO
        title: const Text(
          'Resumo',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text('Erro: $_errorMessage'))
          : _buildResumoBody(),
    );
  }

  Widget _buildResumoBody() {
    if (_dadosCarregamento == null) {
      return const Center(child: Text('Nenhum dado para exibir.'));
    }

    final header = _dadosCarregamento!['header'] as Map<String, dynamic>;
    final filas = _dadosCarregamento!['filas'] as List<dynamic>;

    return RefreshIndicator(
      onRefresh: _carregarResumo,
      child: ListView(
        padding: const EdgeInsets.all(16.0),
        children: [
          _buildInfoGeralCard(header),
          const SizedBox(height: 24),
          Text(
            'Detalhes das Filas',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const Divider(),
          if (filas.isEmpty)
            const Padding(
              padding: EdgeInsets.all(8.0),
              child: Text('Nenhuma fila encontrada neste carregamento.'),
            )
          else
            ...filas.map((fila) => _buildFilaCard(fila)).toList(),
        ],
      ),
    );
  }

  Widget _buildInfoGeralCard(Map<String, dynamic> header) {
    // Parse dos totais gerais com segurança
    final double totalCaixasGeralDouble =
        double.tryParse(header['total_caixas_geral']?.toString() ?? '0.0') ??
        0.0;
    final int totalCaixasGeral = totalCaixasGeralDouble.toInt();

    final double totalQuilosGeral =
        double.tryParse(header['total_quilos_geral']?.toString() ?? '0.0') ??
        0.0;
    // Formata para ter 2 casas decimais
    final String totalQuilosFormatado = totalQuilosGeral.toStringAsFixed(2);

    return Card(
      elevation: 2,
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            _buildInfoRow(
              'Ordem de Expedição:',
              header['car_ordem_expedicao'] ?? 'N/A',
            ),
            _buildInfoRow('Organizador:', header['ent_razao_social'] ?? 'N/A'),
            _buildInfoRow('Data:', _formatarData(header['car_data'])),
            _buildInfoRow(
              'Início:',
              _formatarData(header['car_hora_inicio'], apenasHora: true),
            ),
            _buildInfoRow(
              'Fim:',
              _formatarData(header['car_data_finalizacao'], apenasHora: true),
            ),
            _buildInfoRow('Responsável:', header['responsavel'] ?? 'N/A'),
            _buildInfoRow('Placa(s):', header['car_placa_veiculo'] ?? 'N/A'),
            _buildInfoRow('Lacre:', header['car_lacre'] ?? 'N/A'),
            const Divider(height: 24),
            _buildInfoRow('Total de Caixas:', totalCaixasGeral.toString()),
            _buildInfoRow('Total de Quilos:', '$totalQuilosFormatado kg'),
          ],
        ),
      ),
    );
  }

  Widget _buildInfoRow(String label, String value) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 4.0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
          const SizedBox(width: 8),
          Expanded(child: Text(value)),
        ],
      ),
    );
  }

  Widget _buildFilaCard(Map<String, dynamic> fila) {
    // Agrupar itens por cliente
    final Map<String, List<dynamic>> clientesAgrupados = {};
    for (var item in (fila['itens'] as List<dynamic>)) {
      final clienteNome =
          item['cliente_razao_social'] ?? 'Cliente Desconhecido';
      if (!clientesAgrupados.containsKey(clienteNome)) {
        clientesAgrupados[clienteNome] = [];
      }
      clientesAgrupados[clienteNome]!.add(item);
    }

    final int totalClientes = (fila['total_clientes'] is int)
        ? fila['total_clientes']
        : int.tryParse(fila['total_clientes']?.toString() ?? '0') ?? 0;

    final double totalCaixasDouble =
        double.tryParse(fila['total_caixas']?.toString() ?? '0.0') ?? 0.0;
    final int totalCaixas = totalCaixasDouble.toInt();

    final int totalFotos = (fila['total_fotos'] is int)
        ? fila['total_fotos']
        : int.tryParse(fila['total_fotos']?.toString() ?? '0') ?? 0;
    final bool temFotos = totalFotos > 0;

    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: ExpansionTile(
        leading: CircleAvatar(child: Text('${fila['fila_numero_sequencial']}')),
        title: Text('Fila #${fila['fila_numero_sequencial']}'),

        subtitle: Padding(
          padding: const EdgeInsets.only(top: 4.0),
          child: Text(
            'Clientes: $totalClientes • Caixas: $totalCaixas',
            style: TextStyle(color: Colors.grey.shade600, fontSize: 12),
          ),
        ),

        trailing: temFotos
            ? IconButton(
                icon: Badge(
                  label: Text('$totalFotos'),
                  child: const Icon(Icons.photo_library, color: Colors.blue),
                ),
                tooltip: 'Ver Foto da Fila',
                onPressed: () {
                  Navigator.of(context).push(
                    MaterialPageRoute(
                      builder: (context) => GaleriaFilaScreen(
                        filaId: fila['fila_id'],
                        filaNumero: fila['fila_numero_sequencial'],
                      ),
                    ),
                  );
                },
              )
            : const SizedBox(width: 48), // Espaço vazio se não houver foto
        children: clientesAgrupados.entries.map(
          (entry) {
            final clienteNome = entry.key;
            final produtosDoCliente = entry.value;

            return Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Padding(
                    padding: const EdgeInsets.only(left: 8.0, bottom: 8.0),
                    child: Text(
                      clienteNome,
                      style: const TextStyle(
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  ),
                  SingleChildScrollView(
                    scrollDirection: Axis.horizontal,
                    child: DataTable(
                      columnSpacing: 16,
                      horizontalMargin: 8,
                      headingRowHeight: 32,
                      dataRowMinHeight: 32,
                      dataRowMaxHeight: 48,
                      columns: const [
                        DataColumn(
                          label: Text(
                            'PRODUTO',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'LOTE',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                        ),
                        DataColumn(
                          label: Text(
                            'QTD',
                            style: TextStyle(fontWeight: FontWeight.bold),
                          ),
                          numeric: true,
                        ),
                      ],
                      rows: produtosDoCliente.map<DataRow>((produto) {
                        // O .map começa aqui
                        final int quantidade =
                            (double.tryParse(
                                      produto['car_item_quantidade'].toString(),
                                    ) ??
                                    0)
                                .toInt();
                        return DataRow(
                          cells: [
                            DataCell(Text(produto['prod_descricao'] ?? '')),
                            DataCell(
                              Text(produto['lote_completo_calculado'] ?? ''),
                            ),
                            DataCell(Text(quantidade.toString())),
                          ],
                        );
                      }).toList(), // <-- O .toList() fecha o .map
                    ), // <-- Fecha o DataTable
                  ), // <-- Fecha o SingleChildScrollView
                ], // <-- Fecha a lista de children do Column
              ), // <-- Fecha o Column
            ); // <-- Fecha o return Padding
          },
        ).toList(), // <-- O .toList() que converte o map dos clientes em uma lista de widgets
      ), // <-- Fecha o ExpansionTile
    ); // <-- Fecha o return Card
  }
}
