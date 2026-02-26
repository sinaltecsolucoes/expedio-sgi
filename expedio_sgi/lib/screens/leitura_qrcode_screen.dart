// lib/screens/leitura_qrcode_screen.dart

import 'package:flutter/material.dart';
//import 'package:shared_preferences/shared_preferences.dart';
import 'package:mobile_scanner/mobile_scanner.dart';
import 'package:audioplayers/audioplayers.dart';
import '../services/api_service.dart';
import '../models/operacao_modo.dart';

class LeituraQrCodeScreen extends StatefulWidget {
  final OperacaoModo modo;
  final int? carregamentoId;
  final int? filaId;
  final int? clienteId;
  final int? filaNumero;
  final List<Map<String, dynamic>>? produtosIniciais;
  final int? enderecoId;

  const LeituraQrCodeScreen({
    super.key,
    required this.modo,
    this.carregamentoId,
    this.filaId,
    this.clienteId,
    this.filaNumero,
    this.produtosIniciais,
    this.enderecoId,
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
    if (widget.modo == OperacaoModo.saida && widget.produtosIniciais != null) {
      _carregarProdutosIniciais();
    }
  }

  void _carregarProdutosIniciais() {
    // A sua lógica para carregar produtos iniciais continua a mesma
    final Map<String, Map<String, dynamic>> agrupados = {};
    for (var produto in widget.produtosIniciais!) {
      final String key =
          produto['produtoTexto']?.toString() ?? 'Produto Desconhecido';
      final int quantidade =
          (double.tryParse(produto['quantidade'].toString()) ?? 0.0).toInt();

      if (agrupados.containsKey(key)) {
        agrupados[key]!['quantidade'] += quantidade;
      } else {
        agrupados[key] = {
          'produtoNome': key,
          'quantidade': quantidade,
          'produtoId': produto['produtoId'],
          'loteId': produto['loteId'],
          'itemId': produto['itemId'],
        };
      }
    }
    setState(() {
      _produtosAgrupados.addAll(agrupados.values);
    });
  }

  // --- FUNÇÃO DE LEITURA CORRIGIDA ---

  /* Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _isSaving) return;

    final barcode = capture.barcodes.firstOrNull;
    if (barcode?.rawValue == null) return;

    final String codigoLido = barcode.rawValue!;
    final now = DateTime.now();
    if (codigoLido == _lastScannedCode && now.difference(_lastScanTime).inSeconds < 2) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _lastScannedCode = codigoLido;
      _lastScanTime = now;
    });

    try {
      Map<String, dynamic> resultado;

      // **AQUI ESTÁ A MUDANÇA PRINCIPAL**
      // Verificamos o modo PRIMEIRO e chamamos a API correta
      if (widget.modo == OperacaoModo.entrada) {
        // MODO ENTRADA: Chama a função que valida E aloca no estoque
        resultado = await _apiService.registrarEntrada(widget.enderecoId!, codigoLido);
      } else {
        // MODO SAÍDA: Continua a usar apenas a validação
        resultado = await _apiService.validarLeitura(codigoLido);
      }

      if (mounted && resultado['success'] == true) {
        final player = AudioPlayer();
        player.setReleaseMode(ReleaseMode.release);
        await player.play(AssetSource('sounds/beep-leituraQR.mp3'));
        
        // A API de entrada devolve os dados dentro de uma chave "data"
        final dadosParaLista = resultado['data'] ?? resultado;
        _adicionarProdutoNaListaLocal(dadosParaLista);

        if (widget.modo == OperacaoModo.entrada) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Entrada registrada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: ${resultado['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(SnackBar(content: Text('❌ Erro: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  } */

  Future<void> _onDetect(BarcodeCapture capture) async {
    if (_isProcessing || _isSaving) return;

    final barcode = capture.barcodes.firstOrNull;

    // --- CORREÇÃO DE NULL SAFETY APLICADA AQUI ---
    // Fazemos uma verificação explícita e segura. Se não houver barcode ou valor,
    // a função simplesmente para aqui e espera pela próxima imagem da câmara.
    if (barcode == null || barcode.rawValue == null) {
      return;
    }
    // Daqui para baixo, o Dart tem a certeza de que 'barcode' e 'barcode.rawValue' não são nulos.
    final String codigoLido = barcode.rawValue!;
    // ---------------------------------------------

    final now = DateTime.now();
    if (codigoLido == _lastScannedCode &&
        now.difference(_lastScanTime).inSeconds < 2) {
      return;
    }

    setState(() {
      _isProcessing = true;
      _lastScannedCode = codigoLido;
      _lastScanTime = now;
    });

    try {
      Map<String, dynamic> resultado;

      if (widget.modo == OperacaoModo.entrada) {
        resultado = await _apiService.registrarEntrada(
          widget.enderecoId!,
          codigoLido,
        );
      } else {
        resultado = await _apiService.validarLeitura(codigoLido);
      }

      if (mounted && resultado['success'] == true) {
        final player = AudioPlayer();
        player.setReleaseMode(ReleaseMode.release);
        await player.play(AssetSource('sounds/beep-leituraQR.mp3'));

        final dadosParaLista = resultado['data'] ?? resultado;
        _adicionarProdutoNaListaLocal(dadosParaLista);

        if (widget.modo == OperacaoModo.entrada) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('✅ Entrada registrada com sucesso!'),
              backgroundColor: Colors.green,
            ),
          );
        }
      } else if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('❌ Erro: ${resultado['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('❌ Erro: ${e.toString()}')));
      }
    } finally {
      if (mounted) {
        setState(() {
          _isProcessing = false;
        });
      }
    }
  }

  void _adicionarProdutoNaListaLocal(Map<String, dynamic> dados) {
    setState(() {
      // 1. Captura os nomes para exibição na interface
      final String produtoNome = dados['produto'] ?? 'Produto Desconhecido';
      final String lote = dados['lote'] ?? 'N/A';
      final String chaveDeBusca = "$produtoNome (Lote: $lote)";

      // 2. Busca se o produto já está na lista da tela
      final index = _produtosAgrupados.indexWhere(
        (p) => p['produtoNome'] == chaveDeBusca,
      );

      if (index != -1) {
        // Se já existe, apenas incrementa a quantidade
        _produtosAgrupados[index]['quantidade']++;
      } else {
        // Se é novo, adiciona o mapa com todas as chaves necessárias para o PHP
        _produtosAgrupados.add({
          'produtoNome': chaveDeBusca,
          'quantidade': 1,
          'produtoId': dados['produtoId'],
          'loteId': dados['loteIdHeader'],
          //'alocacaoId': dados['lote_item_id'] ?? dados['alocacao_id'],
          'oeiId': dados['oeiId'] ?? null,
        });
      }
    });
  }

  /*Future<void> _salvarLeiturasDeSaida() async {
    // A sua função de salvar para saídas continua a mesma
    if (_isSaving || _produtosAgrupados.isEmpty) return;
    setState(() => _isSaving = true);
    try {
      final response = await _apiService.atualizarLeituras(
        carregamentoId: widget.carregamentoId!,
        filaId: widget.filaId!,
        clienteId: widget.clienteId!,
        leituras: _produtosAgrupados,
      );
      if (mounted) {
        if (response['success'] == true) {
          Navigator.of(context).pop(true); // Retorna true para a tela anterior
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text('Erro: ${response['message']}'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }*/

  /* Future<void> _salvarLeiturasDeSaida() async {
    // 1. Verificação com debug para sabermos por que ele trava
    if (_produtosAgrupados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum item lido para salvar.')),
      );
      return;
    }
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // 2. Garante que os IDs não sejam nulos e que a quantidade seja tratada corretamente
      final int carregamentoId = widget.carregamentoId ?? 0;
      final int filaId = widget.filaId ?? 0;
      final int clienteId = widget.clienteId ?? 0;

      // 3. Limpeza dos dados: transforma qualquer valor de quantidade em numérico puro
      final leiturasTratadas = _produtosAgrupados.map((item) {
        return {
          'alocacaoId': item['alocacaoId'],
          'quantidade': double.parse(
            item['quantidade'].toString(),
          ), // Trata int ou double
          'motivo': item['motivo'],
          'oeiId': item['oeiId'],
        };
      }).toList();

      final response = await _apiService.atualizarLeituras(
        carregamentoId: carregamentoId,
        filaId: filaId,
        clienteId: clienteId,
        leituras: leiturasTratadas,
      );

      if (mounted) {
        if (response['success'] == true) {
          Navigator.of(context).pop(true);
        } else {
          throw Exception(response['message'] ?? 'Erro desconhecido');
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha ao salvar: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }*/

  Future<void> _salvarLeiturasDeSaida() async {
    if (_produtosAgrupados.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Nenhum item lido para salvar.')),
      );
      return;
    }
    if (_isSaving) return;

    setState(() => _isSaving = true);

    try {
      // Tratamento seguro de IDs para evitar erro de Null Check (!)
      final int carregamentoId = widget.carregamentoId ?? 0;
      final int filaId = widget.filaId ?? 0;
      final int clienteId = widget.clienteId ?? 0;

      // Conversão segura da lista para JSON
      final leiturasTratadas = _produtosAgrupados.map((item) {
        return {
          // 'alocacaoId': item['alocacaoId'] ?? 0,
          'produtoId': item['produtoId'],
          'loteId': item['loteId'],
          'quantidade': double.parse(item['quantidade'].toString()),
          'motivo': item['motivo']?.toString() ?? '',
          'oeiId': item['oeiId'],
        };
      }).toList();

      final response = await _apiService.atualizarLeituras(
        carregamentoId: carregamentoId,
        filaId: filaId,
        clienteId: clienteId,
        leituras: leiturasTratadas,
      );

      if (mounted) {
        if (response['success'] == true) {
          Navigator.of(context).pop(true);
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text('Erro: ${response['message']}')),
          );
        }
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Falha técnica: $e'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  int get _totalItensLidos {
    if (_produtosAgrupados.isEmpty) return 0;
    return _produtosAgrupados
        .map((p) => (double.tryParse(p['quantidade'].toString()) ?? 0).toInt())
        .fold(0, (a, b) => a + b);
  }

  @override
  Widget build(BuildContext context) {
    final bool isModoSaida = widget.modo == OperacaoModo.saida;
    final String titulo = isModoSaida
        ? 'Lendo para Fila #${widget.filaNumero}'
        : 'Registrando Entrada';

    return Scaffold(
      appBar: AppBar(
        title: Text(titulo),
        actions: [
          if (isModoSaida) // Mostra o botão de salvar apenas no modo de saída
            _isSaving
                ? const Padding(
                    padding: EdgeInsets.all(16.0),
                    child: SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(color: Colors.white),
                    ),
                  )
                : IconButton(
                    icon: const Icon(Icons.save),
                    onPressed: _salvarLeiturasDeSaida,
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
                    'Itens Lidos: $_totalItensLidos',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ),
                const Divider(),
                Expanded(
                  child: ListView.builder(
                    itemCount: _produtosAgrupados.length,
                    itemBuilder: (context, index) {
                      final item = _produtosAgrupados[index];
                      return ListTile(
                        title: Text(
                          item['produtoNome'] ?? 'Produto Desconhecido',
                        ),
                        trailing: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              item['quantidade'].toString(),
                              style: const TextStyle(
                                fontWeight: FontWeight.bold,
                                fontSize: 16,
                              ),
                            ),
                            // **LÓGICA DO BOTÃO DE LIXEIRA CORRIGIDA**
                            IconButton(
                              icon: const Icon(
                                Icons.delete_outline,
                                color: Colors.redAccent,
                              ),
                              onPressed: () {
                                if (isModoSaida) {
                                  // No modo Saída, apenas removemos da lista local
                                  setState(() {
                                    _produtosAgrupados.removeAt(index);
                                  });
                                } else {
                                  // No modo Entrada, informamos que a ação não é possível
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text(
                                        'Não é possível remover. Entrada já registrada.',
                                      ),
                                    ),
                                  );
                                }
                              },
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
