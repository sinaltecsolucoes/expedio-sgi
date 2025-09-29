import 'package:flutter/material.dart';
import '../services/cache_service.dart';
import 'entradas_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';

class SelecaoOperacaoScreen extends StatefulWidget {
  const SelecaoOperacaoScreen({super.key});

  @override
  State<SelecaoOperacaoScreen> createState() => _SelecaoOperacaoScreenState();
}

class _SelecaoOperacaoScreenState extends State<SelecaoOperacaoScreen> {
  final CacheService _cacheService = CacheService();
  String? _userName;
  String _greeting = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  // Carrega os dados do utilizador e define a saudação
  Future<void> _loadUserData() async {
    final name = await _cacheService.getUserName();
    setState(() {
      _userName = name;
      _greeting = _getGreeting();
    });
  }

  // Determina a saudação com base na hora do dia
  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) {
      return 'Bom dia';
    }
    if (hour < 18) {
      return 'Boa tarde';
    }
    return 'Boa noite';
  }

  // Realiza o logout
  Future<void> _logout() async {
    await _cacheService.clear(); // Limpa o token e o nome do utilizador
    if (mounted) {
      // Navega para a tela de login e remove todas as outras telas do histórico
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Selecionar Operação'),
        centerTitle: true,
        actions: [
          // Botão de Logout
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: _logout,
            tooltip: 'Sair',
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            // Mensagem de Saudação
            if (_userName != null)
              Text(
                '$_greeting, $_userName!',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
            const SizedBox(height: 8),
            Text(
              'Seja bem-vindo. Qual operação gostaria de fazer agora?',
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
            const SizedBox(height: 48),

            // Botão para ENTRADAS
            ElevatedButton.icon(
              icon: const Icon(Icons.input, size: 32),
              label: const Text('ENTRADAS', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => EntradasScreen()),
                );
              },
            ),
            const SizedBox(height: 24),

            // Botão para SAÍDAS
            ElevatedButton.icon(
              icon: const Icon(Icons.output, size: 32),
              label: const Text('SAÍDAS', style: TextStyle(fontSize: 18)),
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => HomeScreen()),
                );
              },
            ),
          ],
        ),
      ),
    );
  }
}