import 'package:flutter/material.dart';
import '../services/api_service.dart';
import '../models/embalagem_model.dart';

class InserirEmbalagemScreen extends StatefulWidget {
  final int loteId;
  final String loteCodigo;

  const InserirEmbalagemScreen({
    super.key,
    required this.loteId,
    required this.loteCodigo,
  });

  @override
  State<InserirEmbalagemScreen> createState() => _InserirEmbalagemScreenState();
}

class _InserirEmbalagemScreenState extends State<InserirEmbalagemScreen> {
  final ApiService _apiService = ApiService();
  final _qtdController = TextEditingController();
  bool _isSaving = false;

  List<ProdutoPrimario> _produtosPrimarios = [];
  ProdutoPrimario? _primarioSelecionado;
  ProdutoSecundario? _secundarioSelecionado;

  String _feedback = 'Preencha os campos para calcular.';
  bool _precisaAjuste = false;

  @override
  void initState() {
    super.initState();
    _carregarDados();
  }

  void _carregarDados() async {
    try {
      final dados = await _apiService.getProdutosLoteEmbalagem(widget.loteId);
      setState(() {
        _produtosPrimarios = (dados as List)
            .map((e) => ProdutoPrimario.fromJson(e))
            .toList();
      });
    } catch (e) {
      _showSnackBar('Erro ao carregar produtos: $e', Colors.red);
    }
  }

  void _calcular() {
    if (_primarioSelecionado == null ||
        _secundarioSelecionado == null ||
        _qtdController.text.isEmpty) {
      setState(() {
        _feedback = 'Preencha os campos para calcular.';
        _precisaAjuste = false;
      });
      return;
    }

    double qtdSec = double.tryParse(_qtdController.text) ?? 0;
    // Lógica idêntica ao seu repositório PHP
    double fator =
        _secundarioSelecionado!.prodPesoEmbalagem /
        _primarioSelecionado!.pesoPrimario;
    double consumo = qtdSec * fator;

    setState(() {
      if (consumo > (_primarioSelecionado!.saldo + 0.001)) {
        _feedback =
            'Aviso: Falta ${(consumo - _primarioSelecionado!.saldo).toStringAsFixed(2)} ${_primarioSelecionado!.unidade}';
        _precisaAjuste = true;
      } else {
        _feedback =
            'Consumo: ${consumo.toStringAsFixed(2)} ${_primarioSelecionado!.unidade}';
        _precisaAjuste = false;
      }
    });
  }

  Future<void> _salvarEmbalagem() async {
    if (_primarioSelecionado == null ||
        _secundarioSelecionado == null ||
        _qtdController.text.isEmpty) {
      _showSnackBar('Preencha todos os campos.', Colors.orange);
      return;
    }

    setState(() => _isSaving = true);

    // Montando o JSON conforme o seu LoteNovoRepository.php espera
    final dadosParaEnvio = {
      'item_emb_lote_id': widget.loteId,
      'item_emb_prod_prim_id':
          _primarioSelecionado!.prodId, // ID do Produto para o repositório
      'item_emb_prod_sec_id': _secundarioSelecionado!.prodCodigo,
      'item_emb_qtd_sec': double.tryParse(_qtdController.text) ?? 0,
    };

    try {
      final result = await _apiService.salvarItemEmbalagem(dadosParaEnvio);
      if (result['success'] == true) {
        _showSnackBar(result['message'], Colors.green);
        Navigator.pop(context); // Volta para a lista após salvar
      } else {
        _showSnackBar(result['message'] ?? 'Erro ao salvar', Colors.red);
      }
    } catch (e) {
      _showSnackBar('Erro de conexão: $e', Colors.red);
    } finally {
      setState(() => _isSaving = false);
    }
  }

  void _showSnackBar(String msg, Color color) {
    ScaffoldMessenger.of(
      context,
    ).showSnackBar(SnackBar(content: Text(msg), backgroundColor: color));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(
          'Embalar: ${widget.loteCodigo}',
          style: const TextStyle(
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        backgroundColor: Colors.purple.shade700,
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Dropdown Produto Primário com CORREÇÃO DE OVERFLOW
            DropdownButtonFormField<ProdutoPrimario>(
              isExpanded: true, // SOLUÇÃO PARA O OVERFLOW
              value: _primarioSelecionado,
              decoration: const InputDecoration(
                labelText: 'Produto Primário',
                border: OutlineInputBorder(),
              ),
              items: _produtosPrimarios
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text(
                        '${p.nome} (Saldo: ${p.saldo})',
                        overflow: TextOverflow.ellipsis,
                      ), // SOLUÇÃO PARA O OVERFLOW
                    ),
                  )
                  .toList(),
              onChanged: (p) => setState(() {
                _primarioSelecionado = p;
                _secundarioSelecionado = null;
                _calcular();
              }),
            ),
            const SizedBox(height: 16),

            // Dropdown Produto Secundário com CORREÇÃO DE OVERFLOW
            DropdownButtonFormField<ProdutoSecundario>(
              isExpanded: true, // SOLUÇÃO PARA O OVERFLOW
              value: _secundarioSelecionado,
              decoration: const InputDecoration(
                labelText: 'Produto Secundário',
                border: OutlineInputBorder(),
              ),
              items: _primarioSelecionado?.secundarios
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(
                        s.prodDescricao,
                        overflow: TextOverflow.ellipsis,
                      ), // SOLUÇÃO PARA O OVERFLOW
                    ),
                  )
                  .toList(),
              onChanged: (s) => setState(() {
                _secundarioSelecionado = s;
                _calcular();
              }),
            ),
            const SizedBox(height: 16),

            TextField(
              controller: _qtdController,
              keyboardType: const TextInputType.numberWithOptions(
                decimal: true,
              ),
              decoration: const InputDecoration(
                labelText: 'Quantidade de Caixas',
                border: OutlineInputBorder(),
                prefixIcon: Icon(Icons.calculate),
              ),
              onChanged: (_) => _calcular(),
            ),
            const SizedBox(height: 24),

            // Feedback de Consumo
            Container(
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: _precisaAjuste
                    ? Colors.red.shade50
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                _feedback,
                textAlign: TextAlign.center,
                style: TextStyle(
                  color: _precisaAjuste ? Colors.red.shade900 : Colors.black87,
                  fontWeight: FontWeight.bold,
                  fontSize: 16,
                ),
              ),
            ),
            const SizedBox(height: 32),

            _isSaving
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton.icon(
                    icon: Icon(
                      _precisaAjuste ? Icons.warning : Icons.save,
                      color: Colors.white,
                    ),
                    label: Text(
                      _precisaAjuste ? 'AJUSTAR E SALVAR' : 'ADICIONAR ITEM',
                      style: const TextStyle(color: Colors.white, fontSize: 18),
                    ),
                    style: ElevatedButton.styleFrom(
                      backgroundColor: _precisaAjuste
                          ? Colors.orange.shade800
                          : Colors.purple.shade700,
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    onPressed: _salvarEmbalagem,
                  ),
          ],
        ),
      ),
    );
  }
}
