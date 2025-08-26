// lib/screens/gerenciar_carregamento_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'galeria_fila_screen.dart';
import '../services/api_service.dart';
import 'gerenciar_fila_screen.dart';

class GerenciarCarregamentoScreen extends StatefulWidget {
  final int carregamentoId;
  final String numeroCarregamento;
  final String ordemExpedicao;

  const GerenciarCarregamentoScreen({
    super.key,
    required this.carregamentoId,
    required this.numeroCarregamento,
    required this.ordemExpedicao,
  });

  @override
  State<GerenciarCarregamentoScreen> createState() =>
      _GerenciarCarregamentoScreenState();
}

class _GerenciarCarregamentoScreenState
    extends State<GerenciarCarregamentoScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  // Variáveis de estado
  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _listaDeFilas = [];
  bool _podeAdicionarNovaFila = false;
  bool _podeFinalizarCarregamento = false;

  @override
  void initState() {
    super.initState();
    _carregarFilas();
  }

  Future<void> _carregarFilas() async {
    if (!mounted) return;
    setState(() {
      _isLoading = true;
    });

    try {
      final response = await _apiService.getFilasPorCarregamento(
        widget.carregamentoId,
      );
      if (!mounted) return;

      if (response['success'] == true) {
        final List<dynamic> filas = response['data'] ?? [];
        setState(() {
          _listaDeFilas = filas;
          _errorMessage = null;

          if (filas.isEmpty) {
            _podeAdicionarNovaFila = true;
          } else {
            final ultimaFila = filas.last;
            /* final double qtdDouble =
                double.tryParse(
                  ultimaFila['total_quantidade']?.toString() ?? '0.0',
                ) ??
                0.0;
            final bool ultimaFilaTemItens = qtdDouble > 0;
            _podeAdicionarNovaFila = ultimaFilaTemItens;*/
            _podeAdicionarNovaFila = (ultimaFila['total_fotos'] ?? 0) > 0;
          }

          if (filas.isEmpty) {
            // Não pode finalizar um carregamento sem filas.
            _podeFinalizarCarregamento = false;
          } else {
            // O método 'every' verifica se a condição é verdadeira para TODOS os elementos da lista.
            final todasAsFilasEstaoCompletas = filas.every((fila) {
              final bool temClientes = (fila['total_clientes'] ?? 0) > 0;
              final bool temFotos = (fila['total_fotos'] ?? 0) > 0;
              final bool temProdutos =
                  (double.tryParse(
                        fila['total_quantidade']?.toString() ?? '0.0',
                      ) ??
                      0.0) >
                  0;
              return temClientes && temFotos && temProdutos;
            });
            _podeFinalizarCarregamento = todasAsFilasEstaoCompletas;
          }
        });
      } else {
        setState(() {
          _errorMessage = response['message'];
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = "Erro de conexão: ${e.toString()}";
        });
      }
    } finally {
      if (mounted) {
        setState(() {
          _isLoading = false;
        });
      }
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

  Future<void> _selecionarEEnviarFoto(int filaId) async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 80,
      );

      if (foto != null && mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(const SnackBar(content: Text('Enviando foto...')));

        final response = await _apiService.uploadFotoFila(
          filaId: filaId,
          imagePath: foto.path,
        );

        if (mounted) {
          ScaffoldMessenger.of(context).removeCurrentSnackBar();
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: response['success'] ? Colors.green : Colors.red,
            ),
          );
          if (response['success']) {
            _carregarFilas();
          }
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao processar foto: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

  Future<void> _excluirFila(int filaId, int numeroFila) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Fila #$numeroFila?'),
        content: const Text(
          'Esta ação não pode ser desfeita. Deseja continuar?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Excluir'),
            style: TextButton.styleFrom(foregroundColor: Colors.red),
          ),
        ],
      ),
    );

    if (confirmado == true && mounted) {
      final response = await _apiService.excluirFila(filaId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );
        if (response['success']) {
          _carregarFilas();
        }
      }
    }
  }

  Future<void> _finalizarCarregamento() async {
   /*if (_podeAdicionarNovaFila == false && _listaDeFilas.isNotEmpty) {
      final ultimaFila = _listaDeFilas.last;
      _mostrarDialogoResolverFotoPendente(
        ultimaFila['fila_id'],
        ultimaFila['fila_numero_sequencial'],
      );
      return;
    }*/

    final bool? confirmar = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Finalizar Carregamento?'),
        content: const Text(
          'Deseja enviar este carregamento para conferência?',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Sim, Finalizar'),
          ),
        ],
      ),
    );

    if (confirmar != true) return;

    final response = await _apiService.finalizarCarregamento(
      widget.carregamentoId,
    );

    if (mounted) {
      if (response['success'] == false &&
          response['error_code'] == 'FILA_SEM_FOTO') {
        final data = response['data'];
        _mostrarDialogoResolverFotoPendente(data['filaId'], data['filaNumero']);
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );
        if (response['success']) {
          Navigator.of(context).popUntil((route) => route.isFirst);
        }
      }
    }
  }

  Future<void> _mostrarDialogoResolverFotoPendente(
    int filaId,
    int numeroFila,
  ) async {
    final bool? irParaCamera = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Fila Incompleta'),
        content: Text(
          'A Fila nº $numeroFila está sem foto. É necessário tirar a foto para continuar.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Depois'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text('Tirar Foto'),
          ),
        ],
      ),
    );

    if (irParaCamera == true) {
      await _selecionarEEnviarFoto(filaId);
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carreg. Nº ${widget.numeroCarregamento}'),
        actions: [
          IconButton(
            // onPressed: _finalizarCarregamento,
            onPressed: _podeFinalizarCarregamento
                ? _finalizarCarregamento
                : null,
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Finalizar Carregamento',
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green,
              disabledBackgroundColor: Colors.grey.shade400,
              //highlightColor: Colors.green.shade700,
            ),
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text('Erro: $_errorMessage'))
          : RefreshIndicator(
              onRefresh: _carregarFilas,
              child: _listaDeFilas.isEmpty
                  ? const Center(
                      child: Text(
                        'Nenhuma fila criada para este carregamento.',
                        style: TextStyle(fontSize: 16),
                      ),
                    )
                  : ListView.builder(
                      itemCount: _listaDeFilas.length,
                      itemBuilder: (context, index) {
                        // 1. Organizando as variáveis no início para maior clareza
                        final fila = _listaDeFilas[index];
                        final int totalFotos = fila['total_fotos'] ?? 0;
                        final int totalClientes = fila['total_clientes'] ?? 0;
                        final double qtdDouble =
                            double.tryParse(
                              fila['total_quantidade']?.toString() ?? '0.0',
                            ) ??
                            0.0;
                        final int totalCaixas = qtdDouble.toInt();
                        final bool temItens = totalCaixas > 0;
                        final bool ehUltimaFila =
                            index == _listaDeFilas.length - 1;

                        return Card(
                          margin: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          child: ListTile(
                            leading: CircleAvatar(
                              child: Text('${fila['fila_numero_sequencial']}'),
                            ),
                            title: Text(
                              'Fila #${fila['fila_numero_sequencial']}',
                            ),
                            subtitle: Padding(
                              padding: const EdgeInsets.only(top: 4.0),
                              child: Text(
                                'Clientes: $totalClientes • Caixas: $totalCaixas',
                                style: TextStyle(
                                  color: Colors.grey.shade600,
                                  fontSize: 12,
                                ),
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                // Botão da Galeria de Fotos (só aparece se a fila tiver itens)
                                if (temItens)
                                  IconButton(
                                    icon: Badge(
                                      label: Text('$totalFotos'),
                                      isLabelVisible: totalFotos > 0,
                                      child: const Icon(Icons.photo_library),
                                    ),
                                    color: totalFotos > 0
                                        ? Colors.blue
                                        : Colors.grey,
                                    tooltip: 'Gerenciar Fotos da Fila',
                                    onPressed: () {
                                      // A sintaxe aqui foi corrigida
                                      Navigator.of(context)
                                          .push(
                                            MaterialPageRoute(
                                              builder: (context) =>
                                                  GaleriaFilaScreen(
                                                    filaId: fila['fila_id'],
                                                    filaNumero:
                                                        fila['fila_numero_sequencial'],
                                                  ),
                                            ),
                                          )
                                          .then(
                                            (_) => _carregarFilas(),
                                          ); // Recarrega a lista ao voltar
                                    }, // Faltava fechar o onPressed corretamente
                                  ),

                                // Botão de Excluir Fila (só aparece em condições específicas)
                                if (ehUltimaFila &&
                                    totalFotos == 0 &&
                                    !temItens)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _excluirFila(
                                      fila['fila_id'],
                                      fila['fila_numero_sequencial'],
                                    ),
                                    tooltip: 'Excluir Fila Vazia',
                                  ),
                              ],
                            ),
                            onTap: () {
                              Navigator.of(context)
                                  .push(
                                    MaterialPageRoute(
                                      builder: (context) => GerenciarFilaScreen(
                                        filaId: fila['fila_id'],
                                        filaNumero:
                                            fila['fila_numero_sequencial'],
                                        carregamentoId: widget.carregamentoId,
                                      ),
                                    ),
                                  )
                                  .then((_) => _carregarFilas());
                            },
                          ),
                        );
                      },
                    ),
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: _podeAdicionarNovaFila ? _adicionarFila : null,
        label: const Text('Adicionar Fila'),
        icon: const Icon(Icons.add),
        backgroundColor: _podeAdicionarNovaFila ? null : Colors.grey,
      ),
    );
  }
}
