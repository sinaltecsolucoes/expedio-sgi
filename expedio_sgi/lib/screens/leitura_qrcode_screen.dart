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
  final List<Map<String, dynamic>> _produtosAgrupados = [];
  bool _isProcessing = false;
  bool _isSaving = false; // Nova variável de estado para o salvamento

  /* Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _isSaving)
      return; // Não processa se já estiver salvando

    setState(() {
      _isProcessing = true;
    });

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String codigoLido = barcodes.first.rawValue!;

      final resultado = await _apiService.validarLeitura(codigoLido);

      if (mounted) {
        if (resultado['success'] == true) {
          setState(() {
            final produtoNome = resultado['produto'];
            final index = _produtosAgrupados.indexWhere(
              (p) => p['produto'] == produtoNome,
            );

            if (index != -1) {
              _produtosAgrupados[index]['quantidade']++;
            } else {
              _produtosAgrupados.add({
                'produto': produtoNome,
                'quantidade': 1,
                'produtoId': resultado['produtoId'],
                'loteId': resultado['loteIdHeader'],
                // Adicione qualquer outro dado que a API de salvar precise
              });
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✔️ ${resultado['produto']} adicionado!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erro: ${resultado['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    await Future.delayed(const Duration(seconds: 2));
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }
*/

  Future<void> _salvarLeituras() async {
    if (_produtosAgrupados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Nenhum produto para salvar.'),
          backgroundColor: Colors.orange,
        ),
      );
      return;
    }
    setState(() {
      _isSaving = true;
    });

    // Chama a função do ApiService
    final response = await _apiService.salvarLeituras(
      carregamentoId: widget.carregamentoId,
      filaId: widget.filaId,
      clienteId: widget.clienteId,
      leituras: _produtosAgrupados,
    );

    if (mounted) {
      if (response['success'] == true) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: Colors.green,
          ),
        );
        Navigator.of(context).pop();
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    setState(() {
      _isSaving = false;
    });
  }

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _isSaving) return;

    setState(() {
      _isProcessing = true;
    });

    final List<Barcode> barcodes = capture.barcodes;
    if (barcodes.isNotEmpty && barcodes.first.rawValue != null) {
      final String codigoLido = barcodes.first.rawValue!;

      final resultado = await _apiService.validarLeitura(codigoLido);

      if (mounted) {
        if (resultado['success'] == true) {
          setState(() {
            final produtoNome = resultado['produto'];
            final index = _produtosAgrupados.indexWhere(
              (p) => p['produto'] == produtoNome,
            );

            if (index != -1) {
              _produtosAgrupados[index]['quantidade']++;
            } else {
              _produtosAgrupados.add({
                'produto': produtoNome,
                'quantidade': 1,
                'qrCode': codigoLido,
                'produtoId':
                    resultado['produtoId'], // Tenta ler o ID do produto
                'loteId': resultado['loteIdHeader'], // Tenta ler o ID do lote
              });
            }
          });
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('✔️ ${resultado['produto']} adicionado!'),
              backgroundColor: Colors.green,
            ),
          );
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('❌ Erro: ${resultado['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }

    await Future.delayed(const Duration(milliseconds: 500));
    if (mounted) {
      setState(() {
        _isProcessing = false;
      });
    }
  }

  int get _totalItensLidos {
    if (_produtosAgrupados.isEmpty) return 0;
    return _produtosAgrupados
        .map((p) => p['quantidade'] as int)
        .reduce((a, b) => a + b);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Lendo para Fila #${widget.filaId}'),
        // Adiciona um botão de salvar na barra de título
        actions: [
          if (_isSaving)
            const Padding(
              padding: EdgeInsets.only(right: 16.0),
              child: Center(
                child: SizedBox(
                  width: 24,
                  height: 24,
                  child: CircularProgressIndicator(color: Colors.white),
                ),
              ),
            )
          else
            IconButton(
              icon: const Icon(Icons.save),
              onPressed: _salvarLeituras,
              tooltip: 'Salvar Leituras',
            ),
        ],
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
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 16.0,
                    vertical: 8.0,
                  ),
                  child: Text(
                    'Produtos Lidos: $_totalItensLidos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16.0),
                  child: Row(
                    children: [
                      const Expanded(
                        flex: 1,
                        child: Text(
                          'Ordem',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Expanded(
                        flex: 5,
                        child: Text(
                          'Descrição',
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                      const Expanded(
                        flex: 2,
                        child: Text(
                          'Quant.',
                          textAlign: TextAlign.right,
                          style: TextStyle(fontWeight: FontWeight.bold),
                        ),
                      ),
                    ],
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _produtosAgrupados.length,
                    itemBuilder: (context, index) {
                      final item = _produtosAgrupados[index];
                      return Padding(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 16.0,
                          vertical: 8.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 1,
                              child: Text('${index + 1}'.padLeft(2, '0')),
                            ),
                            Expanded(flex: 5, child: Text(item['produto'])),
                            Expanded(
                              flex: 2,
                              child: Text(
                                item['quantidade'].toString(),
                                textAlign: TextAlign.right,
                                style: const TextStyle(
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                          ],
                        ),
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
