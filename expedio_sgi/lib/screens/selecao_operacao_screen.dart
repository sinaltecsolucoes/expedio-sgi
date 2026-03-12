import 'package:flutter/material.dart';
import '../services/cache_service.dart';
import '../models/usuario_funcao.dart';
import 'entradas_screen.dart';
import 'home_screen.dart';
import 'login_screen.dart';
import 'embalagem_lotes_screen.dart';

class SelecaoOperacaoScreen extends StatefulWidget {
  const SelecaoOperacaoScreen({super.key});

  @override
  State<SelecaoOperacaoScreen> createState() => _SelecaoOperacaoScreenState();
}

class _SelecaoOperacaoScreenState extends State<SelecaoOperacaoScreen> {
  final CacheService _cacheService = CacheService();
  String? _userName;
  String? _userFuncao;
  String _greeting = '';

  @override
  void initState() {
    super.initState();
    _loadUserData();
  }

  Future<void> _loadUserData() async {
    final name = await _cacheService.getUserName();
    final funcao = await _cacheService.getUserFuncao();
    print('--- DEBUG TELA SELEÇÃO ---');
    print('Usuário: $name');
    print('Função vinda do Cache: "$funcao"');
    print('Comparação com Admin: ${funcao == UsuarioFuncao.administrador}');
    print('--------------------------');
    setState(() {
      _userName = name;
      _userFuncao = funcao;
      _greeting = _getGreeting();
    });
  }

  String _getGreeting() {
    final hour = DateTime.now().hour;
    if (hour < 12) return 'Bom dia';
    if (hour < 18) return 'Boa tarde';
    return 'Boa noite';
  }

  // ÚNICA FUNÇÃO DE ACESSO: Centralizada e usando o modelo
  bool _podeAcessar(List<String> cargosPermitidos) {
    if (_userFuncao == UsuarioFuncao.administrador ||
        _userFuncao == UsuarioFuncao.gerente) {
      return true;
    }
    return cargosPermitidos.contains(_userFuncao);
  }

  Future<void> _logout() async {
    await _cacheService.clear();
    if (mounted) {
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
        title: const Text('Selecionar Operação'),
        centerTitle: true,
        actions: [
          IconButton(icon: const Icon(Icons.logout), onPressed: _logout),
        ],
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(24.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
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

            // ENTRADAS
            if (_podeAcessar([
              UsuarioFuncao.logistica,
              UsuarioFuncao.recebimento,
              UsuarioFuncao.embalagem,
            ]))
              _buildMenuButton(
                context,
                label: 'ENTRADAS',
                icon: Icons.input,
                color: Colors.blue.shade700,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => const EntradasScreen(),
                  ),
                ),
              ),

            // SAÍDAS
            if (_podeAcessar([
              UsuarioFuncao.logistica,
              UsuarioFuncao.embalagem,
            ]))
              _buildMenuButton(
                context,
                label: 'SAÍDAS',
                icon: Icons.output,
                color: Colors.orange.shade800,
                onPressed: () => Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const HomeScreen()),
                ),
              ),

            // PRODUÇÃO
            if (_podeAcessar([UsuarioFuncao.producao]))
              _buildMenuButton(
                context,
                label: 'PRODUÇÃO',
                icon: Icons.precision_manufacturing,
                color: Colors.green.shade700,
                onPressed: () {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Módulo Produção em breve.')),
                  );
                },
              ),

            // EMBALAGEM
            if (_podeAcessar([UsuarioFuncao.embalagem]))
              _buildMenuButton(
                context,
                label: 'EMBALAGEM',
                icon: Icons.inventory_2,
                color: Colors.purple.shade700,
                onPressed: () {
                  // Substituindo o SnackBar pela navegação real
                  /* Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (context) => const EmbalagemLotesScreen(),
                    ),
                  );*/
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(content: Text('Módulo Embalagem em breve.')),
                  );
                },
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildMenuButton(
    BuildContext context, {
    required String label,
    required IconData icon,
    required Color color,
    required VoidCallback onPressed,
  }) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 20.0),
      child: ElevatedButton.icon(
        icon: Icon(icon, size: 32, color: Colors.white),
        label: Text(
          label,
          style: const TextStyle(
            fontSize: 18,
            color: Colors.white,
            fontWeight: FontWeight.bold,
          ),
        ),
        style: ElevatedButton.styleFrom(
          backgroundColor: color,
          padding: const EdgeInsets.symmetric(vertical: 18),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(15),
          ),
        ),
        onPressed: onPressed,
      ),
    );
  }
}
