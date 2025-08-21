// lib/screens/leitura_qrcode_screen.dart

import 'package:flutter/material.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import '../services/api_service.dart';

class LeituraQrCodeScreen extends StatefulWidget {
  final int carregamentoId;
  final int filaId;
  final int clienteId;

  const LeituraQrCodeScreen({
    super.key,
    required this.carregamentoId,
    required this.filaId,
    required this.clienteId,
  });

  @override
  State<LeituraQrCodeScreen> createState() => _LeituraQrCodeScreenState();
}

class _LeituraQrCodeScreenState extends State<LeituraQrCodeScreen> {
  final ApiService _apiService = ApiService();
  final List<Map<String, dynamic>> _produtosLidos = [];
  bool _isProcessing = false;
  
  // ==========================================================
  // NOVA VARIÁVEL PARA GUARDAR A ÚLTIMA LEITURA
  // ==========================================================
  String? _lastScannedCode;

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing) return;

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String codigoLido = barcodes.first.rawValue!;
      
      // Atualiza a tela com o código lido para depuração
      setState(() {
        _isProcessing = true;
        _lastScannedCode = codigoLido;
      });

      final resultado = await _apiService.validarLeitura(codigoLido);

      if (mounted) {
        if (resultado['success'] == true) {
          setState(() {
            _produtosLidos.add({
              'qrCode': codigoLido,
              'produto': resultado['produto'] ?? 'Produto'
            });
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('✔️ ${resultado['produto']} adicionado!'), backgroundColor: Colors.green),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('❌ Erro: ${resultado['message']}'), backgroundColor: Colors.red),
          );
        }
      }
    }

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() { _isProcessing = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lendo para Fila #${widget.filaId}'),
      ),
      body: Column(
        children: [
          Expanded(
            flex: 3,
            child: Stack(
              alignment: Alignment.center,
              children: [
                MobileScanner(onDetect: _onDetect),
                Container(
                  width: 250,
                  height: 250,
                  decoration: BoxDecoration(
                    border: Border.all(color: Colors.red, width: 4),
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                if (_isProcessing) const CircularProgressIndicator(),
              ],
            ),
          ),
          Expanded(
            flex: 2,
            child: Column(
              children: [
                // ==========================================================
                // NOSSO NOVO PAINEL DE DEPURAÇÃO
                // ==========================================================
                Card(
                  color: Colors.yellow[100],
                  margin: const EdgeInsets.all(8.0),
                  child: Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        const Text('DEBUG: Último QR Code Lido:', style: TextStyle(fontWeight: FontWeight.bold)),
                        const SizedBox(height: 4),
                        Text(
                          _lastScannedCode ?? 'Nenhum código lido ainda',
                          style: const TextStyle(fontFamily: 'monospace', fontSize: 16),
                        ),
                      ],
                    ),
                  ),
                ),
                // ==========================================================
                Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Text(
                    'Produtos Lidos: ${_produtosLidos.length}',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    itemCount: _produtosLidos.length,
                    itemBuilder: (context, index) {
                      final item = _produtosLidos[index];
                      return ListTile(
                        leading: const Icon(Icons.qr_code),
                        title: Text(item['produto']),
                        subtitle: Text(item['qrCode']),
                      );
                    },
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}