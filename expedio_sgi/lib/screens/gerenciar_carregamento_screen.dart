// lib/screens/gerenciar_carregamento_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:shared_preferences/shared_preferences.dart'; // Adicionado para a lógica do som
import '../services/api_service.dart';
import 'gerenciar_fila_screen.dart';
import 'visualizar_foto_screen.dart';
import 'package:audioplayers/audioplayers.dart'; // Adicionado para o som de beep

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
            final temFotoNaUltimaFila =
                ultimaFila['fila_foto_path'] != null &&
                ultimaFila['fila_foto_path'].isNotEmpty;
            _podeAdicionarNovaFila = temFotoNaUltimaFila;
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

  Future<void> _confirmarExcluirFoto(int filaId, int numeroFila) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Excluir Foto da Fila #$numeroFila?'),
        content: const Text(
          'A foto atual será removida permanentemente. Você poderá tirar uma nova foto em seguida.',
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
      final response = await _apiService.excluirFotoFila(filaId);
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
    if (_podeAdicionarNovaFila == false && _listaDeFilas.isNotEmpty) {
      final ultimaFila = _listaDeFilas.last;
      _mostrarDialogoResolverFotoPendente(
        ultimaFila['fila_id'],
        ultimaFila['fila_numero_sequencial'],
      );
      return;
    }

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
            onPressed: _finalizarCarregamento,
            icon: const Icon(Icons.check_circle_outline),
            tooltip: 'Finalizar Carregamento',
            style: IconButton.styleFrom(
              foregroundColor: Colors.white,
              backgroundColor: Colors.green,
              disabledBackgroundColor: Colors.grey.shade300,
              highlightColor: Colors.green.shade700,
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
                        final fila = _listaDeFilas[index];
                        final bool temFoto =
                            fila['fila_foto_path'] != null &&
                            fila['fila_foto_path'].isNotEmpty;
                        final bool ehUltimaFila =
                            index == _listaDeFilas.length - 1;
                        final double qtdDouble =
                            double.tryParse(
                              fila['total_quantidade']?.toString() ?? '0.0',
                            ) ??
                            0.0;
                        final int totalCaixas = qtdDouble.toInt();

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
                              padding: const EdgeInsets.only(top: 8.0),
                              child: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: [
                                  Text(
                                    'Clientes: ${fila['total_clientes'] ?? 0}',
                                  ),
                                  Text('Total Caixas: $totalCaixas'),
                                ],
                              ),
                            ),
                            trailing: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                if (temFoto) ...[
                                  IconButton(
                                    icon: const Icon(
                                      Icons.photo_library,
                                      color: Colors.green,
                                    ),
                                    onPressed: () async {
                                      final baseUrl = await _apiService
                                          .getBaseUrlForImages();
                                      if (mounted) {
                                        Navigator.of(context).push(
                                          MaterialPageRoute(
                                            builder: (context) =>
                                                VisualizarFotoScreen(
                                                  partialImagePath:
                                                      fila['fila_foto_path'],
                                                  baseUrl: baseUrl,
                                                ),
                                          ),
                                        );
                                      }
                                    },
                                    tooltip: 'Ver Foto',
                                  ),
                                  IconButton(
                                    icon: const Icon(
                                      Icons.hide_image,
                                      color: Colors.red,
                                    ),
                                    onPressed: () => _confirmarExcluirFoto(
                                      fila['fila_id'],
                                      fila['fila_numero_sequencial'],
                                    ),
                                    tooltip: 'Excluir Foto',
                                  ),
                                ],
                                if (totalCaixas > 0 && !temFoto)
                                  IconButton(
                                    icon: const Icon(Icons.camera_alt),
                                    onPressed: () =>
                                        _selecionarEEnviarFoto(fila['fila_id']),
                                    tooltip: 'Tirar Foto para Encerrar Fila',
                                  ),
                                if (ehUltimaFila && !temFoto)
                                  IconButton(
                                    icon: const Icon(
                                      Icons.delete,
                                      color: Colors.redAccent,
                                    ),
                                    onPressed: () => _excluirFila(
                                      fila['fila_id'],
                                      fila['fila_numero_sequencial'],
                                    ),
                                    tooltip: 'Excluir Fila',
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
