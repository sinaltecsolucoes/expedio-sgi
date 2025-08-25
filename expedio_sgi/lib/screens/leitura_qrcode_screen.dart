// lib/screens/leitura_qrcode_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';

class LeituraQrCodeScreen extends StatefulWidget {
  final int carregamentoId;
  final int filaId;
  final int clienteId;
  final int filaNumero;
  final List<Map<String, dynamic>>? produtosIniciais;

  const LeituraQrCodeScreen({
    super.key,
    required this.carregamentoId,
    required this.filaId,
    required this.clienteId,
    required this.filaNumero,
    this.produtosIniciais,
  });

  @override
  State<LeituraQrCodeScreen> createState() => _LeituraQrCodeScreenState();
}

class _LeituraQrCodeScreenState extends State<LeituraQrCodeScreen> {
  final ApiService _apiService = ApiService();
  final List<Map<String, dynamic>> _produtosAgrupados = [];
  bool _isProcessing = false;
  bool _isSaving = false;

  String? _lastScannedCode;
  DateTime _lastScanTime = DateTime.now();

  @override
  void initState() {
    super.initState();
    // Se a tela recebeu produtos iniciais, ela já começa com eles na lista
    if (widget.produtosIniciais != null &&
        widget.produtosIniciais!.isNotEmpty) {
      final Map<String, Map<String, dynamic>> agrupados = {};

      for (var produto in widget.produtosIniciais!) {
        // UNIFICAÇÃO: A chave para agrupar e exibir é sempre 'produtoNome'
        final String key =
            produto['produtoTexto']?.toString() ?? 'Produto Desconhecido';

        // CONVERSÃO SEGURA: Converte a quantidade para double (aceita "1.000") e depois para int
        final double qtdDouble =
            double.tryParse(produto['quantidade'].toString()) ?? 0.0;
        final int quantidade = qtdDouble.toInt();

        if (agrupados.containsKey(key)) {
          agrupados[key]!['quantidade'] += quantidade;
        } else {
          // CRIA UM NOVO MAPA UNIFICADO, garantindo que os tipos estejam corretos
          agrupados[key] = {
            'produtoNome': key,
            'quantidade': quantidade,
            'produtoId': produto['produtoId'],
            'loteId': produto['loteId'],
            'itemId': produto['itemId'],
          };
        }
      }
      _produtosAgrupados.addAll(agrupados.values);
    }
  }

  Future<void> _salvarOuAtualizarLeituras() async {
    // A validação de lista vazia foi movida para o início para maior clareza
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

    final response = await _apiService.atualizarLeituras(
      carregamentoId: widget.carregamentoId,
      filaId: widget.filaId,
      clienteId: widget.clienteId,
      leituras: _produtosAgrupados,
    );

    if (mounted) {
      if (response['success'] == true) {
        Navigator.of(context).pop(); // Volta para a tela anterior com sucesso
      } else {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }

    if (mounted) {
      setState(() {
        _isSaving = false;
      });
    }
  }

  /*  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _isSaving) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final String codigoLido = barcode!.rawValue!;

    final now = DateTime.now();
    if (codigoLido == _lastScannedCode &&
        now.difference(_lastScanTime).inSeconds < 2) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final resultado = await _apiService.validarLeitura(codigoLido);

      if (mounted && resultado['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final bool somAtivado = prefs.getBool('beep_sound_enabled') ?? true;
        if (somAtivado) {
          final player = AudioPlayer();
          player.setReleaseMode(ReleaseMode.release);
          await player.play(AssetSource('sounds/beep-leituraQR.mp3'));
        }

        setState(() {
          _lastScannedCode = codigoLido;
          _lastScanTime = now;

          // UNIFICAÇÃO: A chave do nome do produto lido também é 'produtoNome'
          final String produtoNome =
              resultado['produto'] ?? 'Produto Desconhecido';
          final index = _produtosAgrupados.indexWhere(
            (p) => p['produtoNome'] == produtoNome,
          );

          if (index != -1) {
            _produtosAgrupados[index]['quantidade']++;
          } else {
            // CRIA UM NOVO MAPA UNIFICADO, com a mesma estrutura do initState
            _produtosAgrupados.add({
              'produtoNome': produtoNome,
              'quantidade': 1,
              'produtoId': resultado['produtoId'],
              'loteId': resultado['loteIdHeader'],
              'itemId': null,
            });
          }
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: ${resultado['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }
*/

  // Em leitura_qrcode_screen.dart
  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _isSaving) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final String codigoLido = barcode!.rawValue!;

    final now = DateTime.now();
    if (codigoLido == _lastScannedCode &&
        now.difference(_lastScanTime).inSeconds < 2) {
      return;
    }

    setState(() {
      _isProcessing = true;
    });

    try {
      final resultado = await _apiService.validarLeitura(codigoLido);

      if (mounted && resultado['success'] == true) {
        final prefs = await SharedPreferences.getInstance();
        final bool somAtivado = prefs.getBool('beep_sound_enabled') ?? true;

        if (somAtivado) {
          final player = AudioPlayer();
          player.setReleaseMode(ReleaseMode.release);
          await player.play(AssetSource('sounds/beep-leituraQR.mp3'));
        }

        setState(() {
          _lastScannedCode = codigoLido;
          _lastScanTime = now;

          // --- INÍCIO DA CORREÇÃO ---

          // 1. Recriamos a chave completa (Produto + Lote) a partir do resultado do scan
          final String produtoNome =
              resultado['produto'] ?? 'Produto Desconhecido';
          final String lote = resultado['lote'] ?? 'N/A';
          final String chaveDeBusca = "$produtoNome (Lote: $lote)";

          // 2. Usamos a chave completa para procurar na lista
          final index = _produtosAgrupados.indexWhere(
            (p) => p['produtoNome'] == chaveDeBusca, // <-- Comparação correta
          );

          if (index != -1) {
            // Se encontrou, apenas incrementa a quantidade
            _produtosAgrupados[index]['quantidade']++;
          } else {
            // Se não encontrou, adiciona um novo item usando a chave completa
            _produtosAgrupados.add({
              'produtoNome':
                  chaveDeBusca, // <-- Usamos a chave completa aqui também
              'quantidade': 1,
              'produtoId': resultado['produtoId'],
              'loteId': resultado['loteIdHeader'],
              'itemId': null,
            });
          }
          // --- FIM DA CORREÇÃO ---
        });
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: ${resultado['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
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
        title: Text('Lendo para Fila #${widget.filaNumero}'),
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
              onPressed: _salvarOuAtualizarLeituras,
              tooltip: 'Salvar Alterações',
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
                      const SizedBox(
                        width: 48,
                      ), // Espaço para o botão de lixeira
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
                          vertical: 4.0,
                        ),
                        child: Row(
                          children: [
                            Expanded(
                              flex: 5,
                              child: Text(
                                item['produtoNome'] ?? 'Produto Desconhecido',
                              ),
                            ),
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
                            // BOTÃO DE LIXEIRA PARA REMOVER O ITEM
                            SizedBox(
                              width: 48,
                              child: IconButton(
                                icon: const Icon(
                                  Icons.delete_outline,
                                  color: Colors.redAccent,
                                ),
                                onPressed: () {
                                  setState(() {
                                    _produtosAgrupados.removeAt(index);
                                  });
                                },
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
