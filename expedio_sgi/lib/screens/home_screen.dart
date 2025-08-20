// lib/screens/home_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login_screen.dart'; // Para o logout
import 'novo_carregamento_screen.dart'; // Para navegar para a nova tela

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  String _userName = 'Carregando...';

  @override
  void initState() {
    super.initState();
    _loadUserName(); // Carrega o nome do usuário ao iniciar a tela
  }

  // Função para buscar o nome do usuário salvo no dispositivo
  Future<void> _loadUserName() async {
    final prefs = await SharedPreferences.getInstance();
    // A chave 'user_name' foi a que definimos no api_service.dart
    setState(() {
      _userName = prefs.getString('user_name') ?? 'Usuário';
    });
  }

  // Função para fazer logout
  Future<void> _logout() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Limpa todos os dados salvos (token, nome, etc.)

    if (mounted) {
      // Retorna para a tela de login, impedindo o usuário de "voltar" para a home
      Navigator.of(context).pushAndRemoveUntil(
        MaterialPageRoute(builder: (context) => const LoginScreen()),
        (Route<dynamic> route) => false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Painel Principal'),
        actions: [
          // Ícone de Logout na barra superior
          IconButton(
            icon: const Icon(Icons.logout),
            tooltip: 'Sair',
            onPressed: _logout,
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.start,
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text(
              'Bem-vindo(a),',
              style: Theme.of(context).textTheme.titleLarge,
            ),
            Text(
              _userName, // Mostra o nome do usuário carregado
              style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                    fontWeight: FontWeight.bold,
                  ),
            ),
            const SizedBox(height: 48),
            ElevatedButton.icon(
              icon: const Icon(Icons.add, size: 28),
              label: const Text('Iniciar Novo Carregamento'),
              onPressed: () {
                // Navega para a tela que criamos no passo 1
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NovoCarregamentoScreen(),
                  ),
                );
              },
              style: ElevatedButton.styleFrom(
                padding: const EdgeInsets.symmetric(vertical: 20),
                textStyle: const TextStyle(fontSize: 18),
              ),
            ),
          ],
        ),
      ),
    );
  }
}