// lib/screens/gerenciar_carregamento_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'gerenciar_fila_screen.dart';

class GerenciarCarregamentoScreen extends StatefulWidget {
  final int carregamentoId;
  final String numeroCarregamento; // Para exibir no título

  const GerenciarCarregamentoScreen({
    super.key,
    required this.carregamentoId,
    required this.numeroCarregamento,
  });

  @override
  State<GerenciarCarregamentoScreen> createState() =>
      _GerenciarCarregamentoScreenState();
}

class _GerenciarCarregamentoScreenState
    extends State<GerenciarCarregamentoScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<dynamic>> _filasFuture;

  @override
  void initState() {
    super.initState();
    _carregarFilas();
  }

  void _carregarFilas() {
    setState(() {
      _filasFuture = _fetchFilas();
    });
  }

  Future<List<dynamic>> _fetchFilas() async {
    final response = await _apiService.getFilasPorCarregamento(
      widget.carregamentoId,
    );
    if (response['success'] == true) {
      return response['data'];
    } else {
      // Lança um erro para que o FutureBuilder possa exibi-lo
      throw Exception('Falha ao carregar filas: ${response['message']}');
    }
  }

  Future<void> _adicionarFila() async {
    final response = await _apiService.criarFila(widget.carregamentoId);
    if (mounted) {
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Nova fila adicionada!'),
            backgroundColor: Colors.green,
          ),
        );
        // Recarrega a lista de filas para mostrar a nova
        _carregarFilas();
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
      appBar: AppBar(title: Text('Carreg. Nº ${widget.numeroCarregamento}')),
      body: FutureBuilder<List<dynamic>>(
        future: _filasFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(child: Text('${snapshot.error}'));
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text(
                'Nenhuma fila criada para este carregamento.',
                style: TextStyle(fontSize: 16),
              ),
            );
          }

          final filas = snapshot.data!;

          return ListView.builder(
            itemCount: filas.length,
            itemBuilder: (context, index) {
              final fila = filas[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  leading: CircleAvatar(
                    child: Text('${fila['fila_numero_sequencial']}'),
                  ),
                  title: Text('Fila #${fila['fila_numero_sequencial']}'),
                  subtitle: Text(
                    'Clientes: ${fila['total_clientes'] ?? 0} | '
                    'Qtd. Total: ${fila['total_quantidade'] ?? 0}',
                  ),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (context) => GerenciarFilaScreen(
                              filaId: fila['fila_id'],
                              filaNumero: fila['fila_numero_sequencial'],
                              carregamentoId: widget.carregamentoId,
                            ),
                          ),
                        )
                        .then(
                          (_) => _carregarFilas(),
                        ); // Recarrega a lista ao voltar
                  },
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _adicionarFila,
        label: const Text('Adicionar Fila'),
        icon: const Icon(Icons.add),
      ),
    );
  }
}
