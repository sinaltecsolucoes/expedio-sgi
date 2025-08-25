// lib/screens/login_screen.dart

import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../services/api_service.dart';
import 'home_screen.dart';

class LoginScreen extends StatefulWidget {
  const LoginScreen({super.key});

  @override
  State<LoginScreen> createState() => _LoginScreenState();
}

class _LoginScreenState extends State<LoginScreen> {
  final _loginController = TextEditingController();
  final _senhaController = TextEditingController();
  final ApiService _apiService = ApiService();
  bool _isLoading = false;

  void _doLogin() async {
    setState(() {
      _isLoading = true;
    });

    final result = await _apiService.login(
      _loginController.text,
      _senhaController.text,
    );

    setState(() {
      _isLoading = false;
    });

    if (result['success'] == true && mounted) {
      // Navega para a tela principal em caso de sucesso
      Navigator.of(context).pushReplacement(
        MaterialPageRoute(builder: (context) => const HomeScreen()),
      );
    } else if (mounted) {
      // Mostra uma mensagem de erro
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text(result['message']), backgroundColor: Colors.red),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Stack(
        children: [
          Center(
            // Centraliza o conteúdo na tela
            child: SingleChildScrollView(
              // Permite rolagem se o teclado cobrir a tela
              padding: const EdgeInsets.all(
                32.0,
              ), // Aumenta o espaçamento das bordas
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Image.asset(
                    'assets/images/logo_marchef.png', //Adiciona a logomarca
                    height: 150, // Ajustar altura conforme necessário
                  ),
                  const SizedBox(height: 48), // Espaço entre a logo e os campos

                  TextField(
                    controller: _loginController,
                    decoration: const InputDecoration(
                      labelText: 'Usuário',
                      border: OutlineInputBorder(),
                    ),
                    keyboardType: TextInputType.text,
                  ),
                  const SizedBox(height: 16),
                  TextField(
                    controller: _senhaController,
                    decoration: const InputDecoration(
                      labelText: 'Senha',
                      border: OutlineInputBorder(),
                    ),
                    obscureText: true,
                  ),
                  const SizedBox(height: 24),
                  _isLoading
                      ? const Center(child: CircularProgressIndicator())
                      : ElevatedButton(
                          onPressed: _doLogin,
                          child: const Text('Entrar'),
                        ),
                ],
              ),
            ),
          ),

          Positioned(
            top: 40.0,
            right: 16.0,
            child: SafeArea(
              // Garante que não fique sob a barra de status
              child: IconButton(
                icon: const Icon(Icons.more_vert, size: 28.0),
                onPressed: _mostrarDialogoConfiguracoes,
                tooltip: 'Configurações',
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _mostrarDialogoConfiguracoes() async {
    final prefs = await SharedPreferences.getInstance();
    final ipController = TextEditingController(
      text: prefs.getString('server_ip'),
    );
    // O padrão é 'true' se ainda não houver configuração salva
    bool somAtivado = prefs.getBool('beep_sound_enabled') ?? true;

    return showDialog<void>(
      context: context,
      barrierDismissible: false, // O usuário deve salvar ou cancelar
      builder: (BuildContext context) {
        // Usamos um StatefulWidget para o Switch funcionar dentro do Dialog
        return StatefulBuilder(
          builder: (context, setDialogState) {
            return AlertDialog(
              title: const Text('Configurações'),
              content: SingleChildScrollView(
                child: ListBody(
                  children: <Widget>[
                    TextFormField(
                      controller: ipController,
                      decoration: const InputDecoration(
                        labelText: 'IP do Servidor',
                        hintText: 'ex: 192.168.0.10',
                        border: OutlineInputBorder(),
                      ),
                    ),
                    const SizedBox(height: 24),
                    SwitchListTile(
                      title: const Text('Som de Leitura (Beep)'),
                      value: somAtivado,
                      onChanged: (bool value) {
                        setDialogState(() {
                          // Atualiza o estado do Dialog
                          somAtivado = value;
                        });
                      },
                    ),
                  ],
                ),
              ),
              actions: <Widget>[
                TextButton(
                  child: const Text('Cancelar'),
                  onPressed: () {
                    Navigator.of(context).pop();
                  },
                ),
                TextButton(
                  child: const Text('Salvar'),
                  onPressed: () async {
                    await prefs.setString('server_ip', ipController.text);
                    await prefs.setBool('beep_sound_enabled', somAtivado);
                    if (mounted) {
                      Navigator.of(context).pop();
                      ScaffoldMessenger.of(context).showSnackBar(
                        const SnackBar(
                          content: Text('Configurações salvas!'),
                          backgroundColor: Colors.green,
                        ),
                      );
                    }
                  },
                ),
              ],
            );
          },
        );
      },
    );
  }
}
