// lib/screens/resumo_carregamento_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';

class ResumoCarregamentoScreen extends StatefulWidget {
  final String carregamentoId;

  const ResumoCarregamentoScreen({super.key, required this.carregamentoId});

  @override
  State<ResumoCarregamentoScreen> createState() => _ResumoCarregamentoScreenState();
}

class _ResumoCarregamentoScreenState extends State<ResumoCarregamentoScreen> {
  final ApiService _apiService = ApiService();
  Map<String, dynamic>? _resumo;
  bool _isLoading = true;
  String? _errorMessage;

  @override
  void initState() {
    super.initState();
    _carregarResumo();
  }

  Future<void> _carregarResumo() async {
    try {
      final response = await _apiService.getResumoCarregamento(widget.carregamentoId);

      if (mounted) {
        setState(() {
          if (response['success'] == true) {
            _resumo = response['data'];
          } else {
            _errorMessage = response['message'] ?? 'Erro desconhecido.';
          }
          _isLoading = false;
        });
      }
    } catch (e) {
      if (mounted) {
        setState(() {
          _errorMessage = e.toString();
          _isLoading = false;
        });
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Resumo do Carregamento'),
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : _errorMessage != null
              ? Center(child: Text('Erro: $_errorMessage'))
              : _buildResumo(),
    );
  }

  Widget _buildResumo() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          Text(
            'Carregamento ${_resumo?['numero'] ?? 'N/A'}',
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 16),
          _buildInfoCard('Responsável', _resumo?['responsavel'] ?? 'Desconhecido'),
          _buildInfoCard('Total de Filas', _resumo?['total_filas']?.toString() ?? '0'),
          _buildInfoCard('Total de Quilos', _resumo?['total_quilos']?.toString() ?? '0'),
          const SizedBox(height: 24),
          const Text(
            'Produtos Carregados',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          _buildProdutosList(),
        ],
      ),
    );
  }

  Widget _buildInfoCard(String label, String value) {
    return Card(
      margin: const EdgeInsets.symmetric(vertical: 8.0),
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label, style: const TextStyle(fontWeight: FontWeight.bold)),
            Text(value),
          ],
        ),
      ),
    );
  }

  Widget _buildProdutosList() {
    final produtos = _resumo?['produtos'] as List<Map<String, dynamic>>? ?? [];

    if (produtos.isEmpty) {
      return const Text('Nenhum produto encontrado.');
    }

    return ListView.builder(
      shrinkWrap: true,
      physics: const NeverScrollableScrollPhysics(),
      itemCount: produtos.length,
      itemBuilder: (context, index) {
        final produto = produtos[index];
        return Card(
          margin: const EdgeInsets.symmetric(vertical: 8.0),
          child: ListTile(
            title: Text(produto['nome'] ?? 'Produto Desconhecido'),
            subtitle: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('Lote: ${produto['lote'] ?? 'N/A'}'),
                Text('Quantidade: ${produto['quantidade']?.toString() ?? '0'}'),
              ],
            ),
          ),
        );
      },
    );
  }
}