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
    final dados = await _apiService.getProdutosLoteEmbalagem(
      widget.loteId,
    ); // Rota 'get_produtos_lote_embalagem'
    setState(() {
      _produtosPrimarios = (dados as List)
          .map((e) => ProdutoPrimario.fromJson(e))
          .toList();
    });
  }

  void _calcular() {
    if (_primarioSelecionado == null ||
        _secundarioSelecionado == null ||
        _qtdController.text.isEmpty)
      return;

    double qtdSec = double.tryParse(_qtdController.text) ?? 0;
    // Lógica do PHP: peso_secundario / peso_primario
    double fator =
        _secundarioSelecionado!.prodPesoEmbalagem /
        _primarioSelecionado!.pesoPrimario;
    double consumo = qtdSec * fator;

    setState(() {
      if (consumo > (_primarioSelecionado!.saldo + 0.001)) {
        _feedback =
            'Aviso: Falta ${(consumo - _primarioSelecionado!.saldo).toStringAsFixed(2)} ${_primarioSelecionado!.unidade}';
        _precisaAjuste = true; // Muda o comportamento do botão como no JS
      } else {
        _feedback =
            'Consumo: ${consumo.toStringAsFixed(2)} ${_primarioSelecionado!.unidade}';
        _precisaAjuste = false;
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Embalar Lote ${widget.loteId}')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            DropdownButtonFormField<ProdutoPrimario>(
              value: _primarioSelecionado,
              decoration: const InputDecoration(labelText: 'Produto Primário'),
              items: _produtosPrimarios
                  .map(
                    (p) => DropdownMenuItem(
                      value: p,
                      child: Text('${p.nome} (Saldo: ${p.saldo})'),
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
            DropdownButtonFormField<ProdutoSecundario>(
              value: _secundarioSelecionado,
              decoration: const InputDecoration(
                labelText: 'Produto Secundário',
              ),
              items: _primarioSelecionado?.secundarios
                  .map(
                    (s) => DropdownMenuItem(
                      value: s,
                      child: Text(s.prodDescricao),
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
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(
                labelText: 'Quantidade de Caixas',
                border: OutlineInputBorder(),
              ),
              onChanged: (_) => _calcular(),
            ),
            const SizedBox(height: 24),
            Text(
              _feedback,
              style: TextStyle(
                color: _precisaAjuste ? Colors.red : Colors.grey,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 24),
            ElevatedButton(
              style: ElevatedButton.styleFrom(
                backgroundColor: _precisaAjuste ? Colors.orange : Colors.purple,
                minimumSize: const Size.fromHeight(50),
              ),
              onPressed: () {
                /* Chamar apiSalvarItemEmbalagem */
              },
              child: Text(_precisaAjuste ? 'AJUSTAR E SALVAR' : 'ADICIONAR'),
            ),
          ],
        ),
      ),
    );
  }
}
