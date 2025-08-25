// lib/screens/gerenciar_fila_screen.dart

import 'package:flutter/material.dart';
import 'package:dropdown_search/dropdown_search.dart'; // Para o dialog de busca
import '../services/api_service.dart';
import '../services/cache_service.dart'; // Para buscar a lista de clientes
import 'leitura_qrcode_screen.dart'; // A tela de destino

class GerenciarFilaScreen extends StatefulWidget {
  final int filaId;
  final int filaNumero;
  final int carregamentoId;

  const GerenciarFilaScreen({
    super.key,
    required this.filaId,
    required this.filaNumero,
    required this.carregamentoId,
  });

  @override
  State<GerenciarFilaScreen> createState() => _GerenciarFilaScreenState();
}

class _GerenciarFilaScreenState extends State<GerenciarFilaScreen> {
  final ApiService _apiService = ApiService();
  final CacheService _cacheService = CacheService();
  late Future<Map<String, dynamic>> _filaDetailsFuture;

  @override
  void initState() {
    super.initState();
    _carregarDetalhesFila();
  }

  void _carregarDetalhesFila() {
    setState(() {
      _filaDetailsFuture = _apiService.getDetalhesFila(widget.filaId);
    });
  }

  // Cria e exibe o dialog para selecionar o cliente
  Future<void> _mostrarDialogoSelecionarCliente() async {
    // Busca a lista completa de clientes do nosso cache
    final List<Map<String, dynamic>> todosOsClientes = await _cacheService
        .getClientes();
    Map<String, dynamic>? clienteSelecionado;

    if (!mounted) return;

    await showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Selecionar Cliente'),
          content: SizedBox(
            width: double.maxFinite,
            child: DropdownSearch<Map<String, dynamic>>(
              popupProps: const PopupProps.menu(showSearchBox: true),
              items: todosOsClientes,
              itemAsString: (Map<String, dynamic> cliente) =>
                  cliente['nome_display'] ?? '',
              onChanged: (Map<String, dynamic>? data) {
                clienteSelecionado = data;
              },
              dropdownDecoratorProps: const DropDownDecoratorProps(
                dropdownSearchDecoration: InputDecoration(labelText: "Cliente"),
              ),
            ),
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () => Navigator.of(context).pop(),
            ),
            TextButton(
              child: const Text('Avançar'),
              onPressed: () {
                Navigator.of(context).pop(); // Fecha o dialog
                if (clienteSelecionado != null) {
                  // Navega para a tela de leitura de QR Code
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (context) => LeituraQrCodeScreen(
                            carregamentoId: widget.carregamentoId,
                            filaId: widget.filaId,
                            clienteId: clienteSelecionado!['ent_codigo'],
                            filaNumero: widget.filaNumero,
                          ),
                        ),
                      )
                      .then(
                        (_) => _carregarDetalhesFila(),
                      ); // Recarrega os detalhes ao voltar
                }
              },
            ),
          ],
        );
      },
    );
  }

  // Função para remover o cliente
  Future<void> _removerCliente(int clienteId) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Remover Cliente?'),
        content: const Text(
          'Todos os produtos deste cliente na fila serão removidos. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Remover'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmado == true) {
      final response = await _apiService.removerClienteDeFila(
        widget.filaId,
        clienteId,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );
        if (response['success']) {
          _carregarDetalhesFila(); // Recarrega a lista
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Gerenciar Fila #${widget.filaNumero}')),
      body: FutureBuilder<Map<String, dynamic>>(
        future: _filaDetailsFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError ||
              snapshot.data == null ||
              snapshot.data!['success'] == false) {
            return Center(
              child: Text(
                'Erro ao carregar detalhes: ${snapshot.data?['message'] ?? snapshot.error}',
              ),
            );
          }

          final fila = snapshot.data!['data'];
          final clientes = List<Map<String, dynamic>>.from(
            fila['clientes'] ?? [],
          );

          if (clientes.isEmpty) {
            return const Center(
              child: Text('Nenhum cliente nesta fila ainda.'),
            );
          }

          return ListView.builder(
            itemCount: clientes.length,
            itemBuilder: (context, index) {
              final cliente = clientes[index];
              final produtos = List<Map<String, dynamic>>.from(
                cliente['produtos'] ?? [],
              );

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  leading: const Icon(Icons.person),
                  title: Text(cliente['clienteNome'] ?? 'Nome do Cliente'),
                  subtitle: Text('${produtos.length} produto(s)'),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () {
                          Navigator.of(context).push(MaterialPageRoute(
                            builder: (context) => LeituraQrCodeScreen(
                              carregamentoId: widget.carregamentoId,
                              filaId: widget.filaId,
                              clienteId: cliente['clienteId'],
                              filaNumero: widget.filaNumero,
                              produtosIniciais: produtos, // Passa a lista de produtos
                            ),
                          )).then((_) => _carregarDetalhesFila());
                          print('Editar cliente: ${cliente['clienteId']}');
                        },
                        tooltip: 'Editar/Adicionar produtos',
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _removerCliente(cliente['clienteId']),
                        tooltip: 'Remover cliente da fila',
                      ),
                    ],
                  ),
                  children: produtos.map((produto) {
                    return ListTile(
                      contentPadding: const EdgeInsets.only(
                        left: 32,
                        right: 16,
                      ),
                      title: Text(produto['produtoTexto'] ?? 'Produto'),
                      subtitle: Text('Quantidade: ${produto['quantidade']}'),
                    );
                  }).toList(),
                ),
              );
            },
          );
        },
      ),
      // O botão agora chama nossa nova função
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _mostrarDialogoSelecionarCliente,
        label: const Text('Adicionar Cliente/Produtos'),
        icon: const Icon(Icons.qr_code_scanner),
      ),
    );
  }
}
