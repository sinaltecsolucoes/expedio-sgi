// lib/screens/gerenciar_carregamento_screen.dart

import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart'; // Importa o seletor de imagem
import '../services/api_service.dart';
import 'gerenciar_fila_screen.dart'; // Importa a tela de detalhes da fila
import 'visualizar_foto_screen.dart';

class GerenciarCarregamentoScreen extends StatefulWidget {
  final int carregamentoId;
  final String numeroCarregamento;

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
  final ImagePicker _picker = ImagePicker(); // Instancia o seletor de imagens
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

  // Abre a câmera/galeria e envia a foto
  Future<void> _selecionarEEnviarFoto(int filaId) async {
    try {
      final XFile? foto = await _picker.pickImage(
        source: ImageSource.camera,
        imageQuality: 50,
      );

      if (foto != null) {
        // Mostra um indicador de loading
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

  Future<void> _finalizarCarregamento() async {
    final response = await _apiService.finalizarCarregamento(
      widget.carregamentoId,
    );
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(response['message']),
          backgroundColor: response['success'] ? Colors.green : Colors.red,
        ),
      );
      // Se deu sucesso, fecha a tela e volta para a Home
      if (response['success']) {
        Navigator.of(context).pop();
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Carreg. Nº ${widget.numeroCarregamento}'),
        // Ações na barra de título
        actions: [
          // ==========================================================
          // A CORREÇÃO ESTÁ AQUI: Trocamos por um IconButton
          // ==========================================================
          IconButton(
            onPressed: _finalizarCarregamento,
            icon: const Icon(Icons.check_circle_outline),
            tooltip:
                'Finalizar Carregamento', // Texto que aparece ao pressionar e segurar
          ),
        ],
      ),
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
              final bool temFoto =
                  fila['fila_foto_path'] != null &&
                  fila['fila_foto_path'].isNotEmpty;

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
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (temFoto)
                        IconButton(
                          icon: const Icon(Icons.photo_library),
                          onPressed: () async {
                            final baseUrl = await _apiService
                                .getBaseUrlForImages();
                            if (mounted) {
                              Navigator.of(context).push(
                                MaterialPageRoute(
                                  builder: (context) => VisualizarFotoScreen(
                                    partialImagePath: fila['fila_foto_path'],
                                    baseUrl: baseUrl,
                                  ),
                                ),
                              );
                            }
                          },
                          tooltip: 'Ver Foto',
                        ),
                      IconButton(
                        icon: const Icon(Icons.camera_alt),
                        onPressed: () =>
                            _selecionarEEnviarFoto(fila['fila_id']),
                        tooltip: 'Enviar Foto da Fila',
                      ),
                      const Icon(Icons.arrow_forward_ios),
                    ],
                  ),
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
                        .then((_) => _carregarFilas());
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
