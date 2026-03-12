// lib/screens/galeria_fila_screen.dart
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../services/api_service.dart';
import 'visualizar_foto_screen.dart';

class GaleriaFilaScreen extends StatefulWidget {
  final int filaId;
  final int filaNumero;

  const GaleriaFilaScreen({
    super.key,
    required this.filaId,
    required this.filaNumero,
  });

  @override
  State<GaleriaFilaScreen> createState() => _GaleriaFilaScreenState();
}

class _GaleriaFilaScreenState extends State<GaleriaFilaScreen> {
  final ApiService _apiService = ApiService();
  final ImagePicker _picker = ImagePicker();

  bool _isLoading = true;
  String? _errorMessage;
  List<dynamic> _fotos = [];
  String _baseUrlParaImagens = '';

  @override
  void initState() {
    super.initState();
    _carregarFotos();
  }

  Future<void> _carregarFotos() async {
    setState(() => _isLoading = true);
    try {
      _baseUrlParaImagens = await _apiService.getBaseUrlForImages();
      final response = await _apiService.getFotosDaFila(widget.filaId);
      if (mounted) {
        setState(() {
          if (response['success'] == true) {
            _fotos = response['data'];
          } else {
            _errorMessage = response['message'];
          }
        });
      }
    } catch (e) {
      if (mounted) setState(() => _errorMessage = e.toString());
    } finally {
      if (mounted) setState(() => _isLoading = false);
    }
  }

  Future<void> _adicionarFoto() async {
    final XFile? foto = await _picker.pickImage(
      source: ImageSource.camera,
      imageQuality: 60,
    );

    if (foto != null && mounted) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(const SnackBar(content: Text('Enviando foto...')));

      final response = await _apiService.uploadFotoFila(
        filaId: widget.filaId,
        imagePath: foto.path,
      );

      if (mounted) {
        ScaffoldMessenger.of(context)
          ..removeCurrentSnackBar()
          ..showSnackBar(
            SnackBar(
              content: Text(response['message']),
              backgroundColor: response['success'] ? Colors.green : Colors.red,
            ),
          );
        if (response['success']) {
          _carregarFotos(); // Recarrega a galeria
        }
      }
    }
  }

  Future<void> _excluirFoto(int fotoId) async {
    print('Tentando excluir a foto com ID: $fotoId');
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Excluir Foto?'),
        content: const Text('Esta ação não pode ser desfeita.'),
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

    if (confirmado != true) return;

    final response = await _apiService.excluirFotoFila(fotoId);
    if (mounted) {
      ScaffoldMessenger.of(context)
        ..removeCurrentSnackBar()
        ..showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );
      if (response['success']) {
        _carregarFotos(); // Recarrega a galeria
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Fotos da Fila #${widget.filaNumero}')),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
          ? Center(child: Text('Erro: $_errorMessage'))
          : _fotos.isEmpty
          ? const Center(child: Text('Nenhuma foto adicionada.'))
          : GridView.builder(
              padding: const EdgeInsets.all(8),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 8,
                mainAxisSpacing: 8,
              ),
              itemCount: _fotos.length,
              itemBuilder: (context, index) {
                final foto = _fotos[index];
                final imageUrl = '$_baseUrlParaImagens/${foto['foto_path']}';
                return GridTile(
                  header: Align(
                    alignment: Alignment.topRight,
                    child: IconButton(
                      icon: const CircleAvatar(
                        backgroundColor: Colors.red,
                        child: Icon(Icons.close, color: Colors.white, size: 18),
                      ),
                      // onPressed: () => _excluirFoto(foto['foto_id']),
                      onPressed: () {
                        print(
                          "Dados da foto selecionada: $foto",
                        ); // <--- Adicione isso
                        _excluirFoto(foto['foto_id']);
                      },
                      tooltip: 'Excluir Foto',
                    ),
                  ),
                  child: GestureDetector(
                    onTap: () => Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) => VisualizarFotoScreen(
                          partialImagePath: foto['foto_path'],
                          baseUrl: _baseUrlParaImagens,
                        ),
                      ),
                    ),
                    child: Card(
                      clipBehavior: Clip.antiAlias,
                      //child: Image.network(
                      child: CachedNetworkImage(
                        imageUrl: imageUrl,
                        fit: BoxFit.cover,
                        placeholder: (context, url) => Container(
                          color: Colors.grey[200],
                          child: const Center(
                            child: CircularProgressIndicator(),
                          ),
                        ),
                        errorWidget: (context, url, error) => const Icon(
                          Icons.broken_image,
                          size: 40,
                          color: Colors.grey,
                        ),
                      ),
                    ),
                  ),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: _adicionarFoto,
        child: const Icon(Icons.camera_alt),
        tooltip: 'Adicionar Foto',
      ),
    );
  }
}
