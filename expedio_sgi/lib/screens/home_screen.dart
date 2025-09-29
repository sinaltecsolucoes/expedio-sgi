// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:expedio_sgi/screens/gerenciar_carregamento_screen.dart';
import '../services/api_service.dart';
import 'login_screen.dart';
import 'novo_carregamento_screen.dart';
//import 'leitura_qrcode_screen.dart';
import 'resumo_carregamento_screen.dart';
import 'detalhes_carregamento_screen.dart';
import 'selecao_tipo_saida_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  String _userName = 'Carregando...';

  Future<Map<String, List<dynamic>>>? _listasCarregamentos;

  @override
  void initState() {
    super.initState();
    _loadInitialData();
    _listasCarregamentos = _fetchCarregamentos();
    _loadUserName();
  }

  Future<void> _onRefresh() async {
    setState(() {
      _listasCarregamentos = _fetchCarregamentos();
    });
  }

  // Função para carregar todos os dados iniciais da tela
  Future<void> _loadInitialData() async {
    await _loadUserName(); // Carrega o nome do usuário
    setState(() {
      // Inicia a busca pelas listas de carregamentos
      _listasCarregamentos = _fetchCarregamentos();
    });
  }

  // Busca o nome do usuário salvo no dispositivo
  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Usuário';
    });
  }

  // Busca as listas de carregamentos de forma segura
  Future<Map<String, List<dynamic>>> _fetchCarregamentos() async {
    // Tenta buscar as duas listas em paralelo
    final results = await Future.wait([
      _apiService.getCarregamentosAtivos(limit: 3),
      _apiService.getCarregamentosFinalizados(limit: 3),
    ]);

    // O retorno da API agora é uma Lista, não um Mapa
    final ativosResponse = results[0];
    final finalizadosResponse = results[1];

    // Retorna as listas, que já são tratadas no ApiService
    return {'ativos': ativosResponse, 'finalizados': finalizadosResponse};
  }

  // Função para fazer logout
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    // await prefs.clear();
    await prefs.remove('api_token');
    await prefs.remove('user_name');
    if (mounted) {
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  // Função para formatar a data que vem do banco
  String _formatarData(String? dataDoBanco) {
    if (dataDoBanco == null) return 'Data inválida';
    try {
      final parsedDate = DateTime.parse(dataDoBanco);
      return DateFormat('dd/MM/yyyy').format(parsedDate);
    } catch (e) {
      return 'Data inválida';
    }
  }

  // Função lida com a exclusão e o diálogo de confirmação
  Future<void> _excluirCarregamento(
    int carregamentoId,
    String numeroCarregamento,
  ) async {
    final bool? confirmado = await showDialog<bool>(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: const Text('Confirmar Exclusão'),
          content: Text(
            'Tem certeza que deseja excluir permanentemente o Carregamento Nº $numeroCarregamento?',
          ),
          actions: <Widget>[
            TextButton(
              child: const Text('Cancelar'),
              onPressed: () =>
                  Navigator.of(context).pop(false), // Retorna false
            ),
            TextButton(
              style: TextButton.styleFrom(foregroundColor: Colors.red),
              child: const Text('Excluir'),
              onPressed: () => Navigator.of(context).pop(true), // Retorna true
            ),
          ],
        );
      },
    );

    // Se o usuário confirmou (retornou true)
    if (confirmado == true) {
      final response = await _apiService.excluirCarregamento(carregamentoId);
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(response['message']),
            backgroundColor: response['success'] ? Colors.green : Colors.red,
          ),
        );
        // Se a exclusão foi bem-sucedida, recarrega a lista
        if (response['success']) {
          _loadInitialData();
        }
      }
    }
  }

  Widget _buildCarregamentoSection(String titulo, List<dynamic> carregamentos) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(left: 16.0, top: 16.0, bottom: 8.0),
          child: Text(
            titulo,
            style: const TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
          ),
        ),
        if (carregamentos.isEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 16.0),
            child: Text(
              'Nenhum carregamento nesta categoria.',
              style: TextStyle(color: Colors.grey[600]),
            ),
          )
        else
          ListView.builder(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: carregamentos.length,
            itemBuilder: (context, index) {
              final item = carregamentos[index];
              return Card(
                margin: const EdgeInsets.symmetric(
                  horizontal: 16.0,
                  vertical: 8.0,
                ),
                child: ListTile(
                  leading: const Icon(
                    Icons.local_shipping,
                    color: Colors.orange,
                    size: 40,
                  ),
                  title: Text(
                    'Nº ${item['numero']?.toString().padLeft(4, '0') ?? 'null'} - ${item['cliente_nome'] ?? 'null'}',
                    style: const TextStyle(fontWeight: FontWeight.bold),
                  ),
                  subtitle: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Responsável: ${item['responsavel'] ?? 'null'}'),
                      Text('Data: ${_formatarData(item['data'])}'),
                    ],
                  ),
                  trailing: IconButton(
                    icon: const Icon(Icons.delete, color: Colors.red),
                    onPressed: () {
                      _excluirCarregamento(
                        item['carregamentoId'] as int,
                        item['numero'].toString(),
                      );
                    },
                  ),
                  onTap: () {
                    Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (context) => GerenciarCarregamentoScreen(
                          carregamentoId: item['carregamentoId'] as int,
                          numeroCarregamento: item['numero'].toString(),
                        ),
                      ),
                    );
                  },
                ),
              );
            },
          ),
      ],
    );
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Scaffold(
        appBar: AppBar(
          title: const Text('Painel Principal'),
          actions: [
            IconButton(
              icon: const Icon(Icons.logout),
              tooltip: 'Sair',
              onPressed: _logout,
            ),
          ],
        ),
        // Adicionado o RefreshIndicator para poder "puxar para atualizar"
        body: RefreshIndicator(
          onRefresh: _onRefresh,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: const EdgeInsets.all(16.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                // 2. Botão grande para Novo Carregamento
                ElevatedButton.icon(
                  icon: const Icon(Icons.add, size: 28),
                  label: const Text('Iniciar Novo Carregamento'),
                  onPressed: () {
                    Navigator.of(context)
                        .push(
                          MaterialPageRoute(
                            builder: (context) =>
                                const SelecaoTipoSaidaScreen(),
                          ),
                        )
                        .then(
                          (_) => _loadInitialData(),
                        ); // Recarrega os dados ao voltar
                  },
                ),
                const SizedBox(height: 32),

                // 3. Futuro que constrói as listas
                FutureBuilder<Map<String, List<dynamic>>>(
                  future: _listasCarregamentos,
                  builder: (context, snapshot) {
                    // Enquanto espera, mostra um loading
                    if (snapshot.connectionState == ConnectionState.waiting) {
                      return const Center(child: CircularProgressIndicator());
                    }
                    // Se deu algum erro de conexão
                    if (snapshot.hasError) {
                      return Center(
                        child: Text(
                          'Erro ao carregar listas: ${snapshot.error}',
                        ),
                      );
                    }
                    // Se os dados chegaram
                    if (snapshot.hasData) {
                      final ativos = snapshot.data!['ativos']!;
                      final finalizados = snapshot.data!['finalizados']!;

                      return Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          _buildCarregamentoSection(
                            'Carregamentos Ativos',
                            ativos,
                          ),
                          const SizedBox(height: 24),
                          _buildCarregamentoSection(
                            'Carregamentos Finalizados',
                            finalizados,
                          ),
                        ],
                      );
                    }
                    // Caso padrão
                    return const Center(
                      child: Text('Nenhum carregamento encontrado.'),
                    );
                  },
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
