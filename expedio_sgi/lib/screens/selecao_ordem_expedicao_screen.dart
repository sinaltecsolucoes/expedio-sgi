// lib/screens/selecao_ordem_expedicao_screen.dart

import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'novo_carregamento_screen.dart';
import 'gerenciar_carregamento_screen.dart';

class SelecaoOrdemExpedicaoScreen extends StatefulWidget {
  const SelecaoOrdemExpedicaoScreen({super.key});

  @override
  State<SelecaoOrdemExpedicaoScreen> createState() =>
      _SelecaoOrdemExpedicaoScreenState();
}

class _SelecaoOrdemExpedicaoScreenState
    extends State<SelecaoOrdemExpedicaoScreen> {
  final ApiService _apiService = ApiService();
  late Future<List<Map<String, dynamic>>> _ordensFuture;

  @override
  void initState() {
    super.initState();
    _ordensFuture = _apiService.getOrdensProntas();
  }

  /*  Future<void> _onOrdemSelected(Map<String, dynamic> ordem) async {
    try {
      // Mostra um indicador de loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final int oeId = ordem['oe_id'];
      final detalhes = await _apiService.getDetalhesOE(oeId);

      // Fecha o loading
      Navigator.of(context).pop();

      // Navega para a tela de novo carregamento, passando os detalhes
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => NovoCarregamentoScreen(
              // Passamos os dados para pré-preencher
              dadosIniciaisOE: {
                'oe_id': oeId,
                'oe_numero': ordem['oe_numero'],
                'cliente_id': detalhes['cliente_id'],
                'transportadora_id': detalhes['transportadora_id'],
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Fecha o loading em caso de erro
      Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar detalhes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

*/

  // Substitua a sua função _onOrdemSelected por esta:

  /* Future<void> _onOrdemSelected(Map<String, dynamic> ordem) async {
    try {
      // Mostra um indicador de loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final int oeId = ordem['oe_id'];

      // Chamamos a API que cria o carregamento a partir da OE
      final response = await _apiService.criarCarregamentoDeOe(oeId);

      // Fecha o loading
      Navigator.of(context).pop();

      if (mounted && response['success'] == true) {
        final int novoCarregamentoId = response['carregamentoId'];
        final String numeroOE = ordem['oe_numero'].toString();

        // --- CORREÇÃO DA NAVEGAÇÃO ---
        // Agora navegamos para a tela de GESTÃO, passando o ID do novo carregamento
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => GerenciarCarregamentoScreen(
              carregamentoId: novoCarregamentoId,
              numeroCarregamento:
                  numeroOE, // Podemos usar o número da OE como referência inicial
            ),
          ),
        );
      } else if (mounted) {
        // Se a API retornar um erro
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro: ${response['message']}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    } catch (e) {
      // Fecha o loading em caso de erro de conexão
      Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao criar carregamento: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  } */

  // Substitua a sua função _onOrdemSelected por esta:

/*  Future<void> _onOrdemSelected(Map<String, dynamic> ordem) async {
    try {
      // Mostra um indicador de loading
      showDialog(
        context: context,
        barrierDismissible: false,
        builder: (context) => const Center(child: CircularProgressIndicator()),
      );

      final int oeId = ordem['oe_id'];

      // PASSO 1: Busca os detalhes da OE na API
      final detalhes = await _apiService.getDetalhesOE(oeId);

      // Fecha o loading
      Navigator.of(context).pop();

      // PASSO 2: Navega para a tela de Novo Carregamento, passando os detalhes
      if (mounted) {
        Navigator.of(context).pushReplacement(
          MaterialPageRoute(
            builder: (context) => NovoCarregamentoScreen(
              // Passamos os dados para pré-preencher o formulário
              dadosIniciaisOE: {
                'oe_id': oeId,
                'oe_numero': ordem['oe_numero'],
                'cliente_id': detalhes['cliente_id'],
                'transportadora_id': detalhes['transportadora_id'],
              },
            ),
          ),
        );
      }
    } catch (e) {
      // Fecha o loading em caso de erro
      Navigator.of(context).pop();
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Erro ao buscar detalhes: ${e.toString()}'),
            backgroundColor: Colors.red,
          ),
        );
      }
    }
  }

*/

Future<void> _onOrdemSelected(Map<String, dynamic> ordem) async {
  // A busca de detalhes e o loading continuam iguais
  try {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => const Center(child: CircularProgressIndicator()),
    );
    final int oeId = ordem['oe_id'];
    final detalhes = await _apiService.getDetalhesOE(oeId);
    Navigator.of(context).pop(); // Fecha o loading

    // --- CORREÇÃO DA NAVEGAÇÃO ---
    // Agora navegamos para a tela de formulário (NovoCarregamentoScreen),
    // passando os dados da OE para que ela possa pré-preencher os campos.
    if (mounted) {
      Navigator.of(context).push( // Usamos .push() para poder voltar
        MaterialPageRoute(
          builder: (context) => NovoCarregamentoScreen(
            dadosIniciaisOE: {
              'oe_id': oeId,
              'oe_numero': ordem['oe_numero'],
              'cliente_id': detalhes['cliente_id'],
              'transportadora_id': detalhes['transportadora_id'],
            },
          ),
        ),
      );
    }
  } catch (e) {
    Navigator.of(context).pop(); // Fecha o loading em caso de erro
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao buscar detalhes: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }
}


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecionar Ordem de Expedição')),
      body: FutureBuilder<List<Map<String, dynamic>>>(
        future: _ordensFuture,
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }
          if (snapshot.hasError) {
            return Center(
              child: Text('Erro ao carregar ordens: ${snapshot.error}'),
            );
          }
          if (!snapshot.hasData || snapshot.data!.isEmpty) {
            return const Center(
              child: Text('Nenhuma Ordem de Expedição pronta para carregar.'),
            );
          }

          final ordens = snapshot.data!;
          return ListView.builder(
            itemCount: ordens.length,
            itemBuilder: (context, index) {
              final ordem = ordens[index];
              return Card(
                margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                child: ListTile(
                  title: Text(
                    'OE Nº: ${ordem['oe_numero']}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Text('Clientes: ${ordem['clientes']}'),
                  trailing: const Icon(Icons.arrow_forward_ios),
                  onTap: () => _onOrdemSelected(ordem),
                ),
              );
            },
          );
        },
      ),
    );
  }
}
