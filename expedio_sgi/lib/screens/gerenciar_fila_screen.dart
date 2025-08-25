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

  List<Map<String, dynamic>> _listaDeClientes = [];

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
  /*  Future<void> _mostrarDialogoSelecionarCliente() async {
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
*/

  Future<void> _mostrarDialogoSelecionarCliente() async {
    final List<Map<String, dynamic>> todosOsClientes = await _cacheService
        .getClientes();
    Map<String, dynamic>? clienteSelecionado;

    if (!mounted) return;

    // 1. O usuário seleciona um cliente no pop-up de busca
    clienteSelecionado = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (BuildContext context) {
        Map<String, dynamic>? clienteParaRetornar;
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
                clienteParaRetornar = data;
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
              onPressed: () => Navigator.of(context).pop(clienteParaRetornar),
            ),
          ],
        );
      },
    );

    if (clienteSelecionado == null)
      return; // Usuário cancelou ou não selecionou

    // 2. Verificamos se o cliente selecionado JÁ EXISTE na fila atual
    final idClienteSelecionado = clienteSelecionado['ent_codigo'];
    final clienteExistente = _listaDeClientes
        .cast<Map<String, dynamic>?>()
        .firstWhere(
          (c) => c!['clienteId'] == idClienteSelecionado,
          orElse: () => null,
        );

    // 3. SE O CLIENTE EXISTE, mostramos o diálogo de confirmação
    if (clienteExistente != null) {
      final bool? querAdicionar = await showDialog<bool>(
        context: context,
        builder: (context) => AlertDialog(
          title: const Text('Cliente já existe'),
          content: Text(
            'O cliente ${clienteExistente['clienteNome']} já está nesta fila. Deseja adicionar mais produtos para ele?',
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(false),
              child: const Text('Não'),
            ),
            TextButton(
              onPressed: () => Navigator.of(context).pop(true),
              child: const Text('Sim'),
            ),
          ],
        ),
      );

      // Se respondeu SIM, navegamos para a tela de leitura passando os produtos que ele já tem
      if (querAdicionar == true) {
        Navigator.of(context)
            .push(
              MaterialPageRoute(
                builder: (context) => LeituraQrCodeScreen(
                  carregamentoId: widget.carregamentoId,
                  filaId: widget.filaId,
                  clienteId: idClienteSelecionado,
                  filaNumero: widget.filaNumero,
                  produtosIniciais: List<Map<String, dynamic>>.from(
                    clienteExistente['produtos'],
                  ), // Passa a lista de produtos existentes!
                ),
              ),
            )
            .then((_) => _carregarDetalhesFila());
      }
      // Se respondeu NÃO, não fazemos nada.
    } else {
      // 4. SE O CLIENTE É NOVO, navegamos diretamente para a tela de leitura (sem produtos iniciais)
      Navigator.of(context)
          .push(
            MaterialPageRoute(
              builder: (context) => LeituraQrCodeScreen(
                carregamentoId: widget.carregamentoId,
                filaId: widget.filaId,
                clienteId: idClienteSelecionado,
                filaNumero: widget.filaNumero,
                // Não passamos produtos iniciais, pois é um cliente novo na fila
              ),
            ),
          )
          .then((_) => _carregarDetalhesFila());
    }
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

  Future<void> _mostrarDialogoEditarQuantidade(
    Map<String, dynamic> produto,
  ) async {
    final controller = TextEditingController(
      text: (double.tryParse(produto['quantidade'].toString()) ?? 0.0)
          .toInt()
          .toString(),
    );

    final novaQuantidade = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Editar Quantidade'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              produto['produtoTexto'] ?? 'Produto',
              style: TextStyle(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: controller,
              keyboardType: TextInputType.number,
              autofocus: true,
              decoration: const InputDecoration(labelText: 'Nova quantidade'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () =>
                Navigator.of(context).pop(int.tryParse(controller.text)),
            child: const Text('Confirmar'),
          ),
        ],
      ),
    );

    if (novaQuantidade != null) {
      final response = await _apiService.atualizarQuantidadeItem(
        itemId: produto['itemId'],
        novaQuantidade: novaQuantidade,
      );
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );
        if (response['success']) {
          _carregarDetalhesFila(); // Recarrega a tela para mostrar o novo valor
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

          _listaDeClientes = clientes;

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

              // Calcula o total de caixas para este cliente
              int totalCaixasCliente = 0;
              for (var p in produtos) {
                totalCaixasCliente +=
                    (double.tryParse(p['quantidade'].toString()) ?? 0.0)
                        .toInt();
              }

              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ExpansionTile(
                  leading: const Icon(Icons.person),
                  title: Text(cliente['clienteNome'] ?? 'Nome do Cliente'),
                  subtitle: Text(
                    'Total Caixas: $totalCaixasCliente',
                  ), // Mostra o total de caixas
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Ícone de editar o cliente (leva para a tela de leitura)
                      IconButton(
                        icon: const Icon(Icons.edit, color: Colors.blueAccent),
                        onPressed: () {
                          Navigator.of(context)
                              .push(
                                MaterialPageRoute(
                                  builder: (context) => LeituraQrCodeScreen(
                                    carregamentoId: widget.carregamentoId,
                                    filaId: widget.filaId,
                                    clienteId: cliente['clienteId'],
                                    filaNumero: widget.filaNumero,
                                    produtosIniciais: produtos,
                                  ),
                                ),
                              )
                              .then((_) => _carregarDetalhesFila());
                        },
                        tooltip: 'Adicionar/Remover produtos',
                      ),
                      // Ícone de remover o cliente
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.redAccent),
                        onPressed: () => _removerCliente(cliente['clienteId']),
                        tooltip: 'Remover cliente da fila',
                      ),
                    ],
                  ),
                  children: produtos.map((produto) {
                    final int quantidadeInt =
                        (double.tryParse(produto['quantidade'].toString()) ??
                                0.0)
                            .toInt();
                    return ListTile(
                      contentPadding: const EdgeInsets.only(
                        left: 32,
                        right: 16,
                      ),
                      title: Text(produto['produtoTexto'] ?? 'Produto'),
                      subtitle: Text('Quantidade: $quantidadeInt caixas'),
                      onTap: () => _mostrarDialogoEditarQuantidade(
                        produto,
                      ), // Chama o diálogo de edição
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
