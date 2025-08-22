// lib/screens/visualizar_foto_screen.dart

import 'package:flutter/material.dart';

class VisualizarFotoScreen extends StatelessWidget {
  final String partialImagePath;
  final String baseUrl; // Precisamos da URL base para montar o caminho completo

  const VisualizarFotoScreen({
    super.key,
    required this.partialImagePath,
    required this.baseUrl,
  });

  @override
  Widget build(BuildContext context) {
    // Monta a URL completa da imagem
    final fullImageUrl =
        '${baseUrl.replaceAll('/api.php', '')}/$partialImagePath';
    print('Carregando imagem de: $fullImageUrl');

    return Scaffold(
      appBar: AppBar(
        backgroundColor: Colors.black,
        title: const Text('Visualizar Foto'),
      ),
      backgroundColor: Colors.black,
      body: Center(
        // Permite dar zoom na imagem
        child: InteractiveViewer(
          panEnabled: false,
          minScale: 1.0,
          maxScale: 4.0,
          child: Image.network(
            fullImageUrl,
            fit: BoxFit.contain,
            // Mostra um loading enquanto a imagem carrega
            loadingBuilder: (context, child, loadingProgress) {
              if (loadingProgress == null) return child;
              return const Center(child: CircularProgressIndicator());
            },
            // Mostra um erro se a imagem não puder ser carregada
            errorBuilder: (context, error, stackTrace) {
              return const Center(
                child: Icon(Icons.error, color: Colors.red, size: 50),
              );
            },
          ),
        ),
      ),
    );
  }
}
