// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'login_screen.dart'; 
import 'novo_carregamento_screen.dart';
import 'leitura_qrcode_screen.dart';
import 'resumo_carregamento_screen.dart';
import 'detalhes_carregamento_screen.dart';

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final ApiService _apiService = ApiService();
  String _userName = 'Carregando...';
  // Usaremos um FutureBuilder, então a lógica de loading fica mais simples
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
    //void _loadInitialData() {
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

    // O retorno da sua API agora é uma Lista, não um Mapa
    final ativosResponse = results[0];
    final finalizadosResponse = results[1];

    // Retorna as listas, que já são tratadas no ApiService
    return {'ativos': ativosResponse, 'finalizados': finalizadosResponse};
  }

  // Função para fazer logout
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear();
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

  @override
  Widget build(BuildContext context) {
    return Scaffold(
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
      // Adicionamos o RefreshIndicator para poder "puxar para atualizar"
      body: RefreshIndicator(
        onRefresh: _onRefresh,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              // 1. Mensagem de Boas-vindas
              Text(
                'Bem-vindo(a),',
                style: Theme.of(context).textTheme.titleLarge,
              ),
              Text(
                _userName,
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 24),

              // 2. Botão grande para Novo Carregamento
              ElevatedButton.icon(
                icon: const Icon(Icons.add, size: 28),
                label: const Text('Iniciar Novo Carregamento'),
                onPressed: () {
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (context) => const NovoCarregamentoScreen(),
                        ),
                      )
                      .then(
                        (_) => _loadInitialData(),
                      ); // Recarrega os dados ao voltar
                },
                style: ElevatedButton.styleFrom(
                  padding: const EdgeInsets.symmetric(vertical: 20),
                  textStyle: const TextStyle(fontSize: 18),
                ),
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
                      child: Text('Erro ao carregar listas: ${snapshot.error}'),
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
                          context,
                          'Carregamentos Ativos',
                          ativos,
                        ),
                        const SizedBox(height: 24),
                        _buildCarregamentoSection(
                          context,
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
    );
  }

  // Widget auxiliar para construir cada seção de lista
  Widget _buildCarregamentoSection(
    BuildContext context,
    String title,
    List<dynamic> carregamentos,
  ) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleLarge),
        const Divider(),
        if (carregamentos.isEmpty)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 16.0),
            child: Text('Nenhum carregamento nesta categoria.'),
          ),
        // Mapeia a lista de dados para uma lista de Cards
        ...carregamentos.map((carregamento) {
          bool isAtivo = title.contains('Ativos');
          return Card(
            margin: const EdgeInsets.symmetric(vertical: 4.0),
            child: ListTile(
              leading: Icon(
                Icons.local_shipping,
                color: isAtivo ? Colors.orange : Colors.green,
              ),
             
              title: Text(
                'Nº ${carregamento['numero']} - ${carregamento['nome_cliente']}',
              ),
              subtitle: Text(
                'Responsável: ${carregamento['responsavel']}\nData: ${_formatarData(carregamento['data'])}',
              ),

              onTap: () {
                final carregamentoId = carregamento['carregamentoId'];
                if (carregamentoId == null) return;

                if (isAtivo) {
                  // Se for ATIVO, vai para a nova tela de DETALHES
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (context) => DetalhesCarregamentoScreen(
                            carregamentoId: carregamentoId,
                            numeroCarregamento: carregamento['numero']
                                .toString(),
                          ),
                        ),
                      )
                      .then((_) => _loadInitialData());
                } else {
                  // Se for FINALIZADO, continua indo para o RESUMO
                  Navigator.of(context)
                      .push(
                        MaterialPageRoute(
                          builder: (context) => ResumoCarregamentoScreen(
                            carregamentoId: carregamentoId.toString(),
                          ),
                        ),
                      )
                      .then((_) => _loadInitialData());
                }
              },
            ),
          );
        }).toList(),
      ],
    );
  }
}
