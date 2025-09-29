// lib/screens/selecao_tipo_saida_screen.dart

import 'package:flutter/material.dart';
import 'novo_carregamento_screen.dart'; // A tela que se tornará a "Saída Avulsa"
import 'selecao_ordem_expedicao_screen.dart';

class SelecaoTipoSaidaScreen extends StatelessWidget {
  const SelecaoTipoSaidaScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Selecione o Tipo de Saída')),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: ListView(
          children: [
            _buildOptionCard(
              context: context,
              icon: Icons.local_shipping,
              title: 'Saída por Ordem de Expedição',
              subtitle:
                  'Carregar itens de uma Ordem de Expedição pré-definida.',
              onTap: () {
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const SelecaoOrdemExpedicaoScreen(),
                  ),
                );
              },
            ),
            _buildOptionCard(
              context: context,
              icon: Icons.add_box,
              title: 'Saída Avulsa',
              subtitle: 'Registrar uma nova saída de itens de forma manual.',
              onTap: () {
                // Navega para a tela de carregamento que já conhecemos
                Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (context) => const NovoCarregamentoScreen(),
                  ),
                );
              },
            ),
            _buildOptionCard(
              context: context,
              icon: Icons.delete_forever,
              title: 'Descarte',
              subtitle: 'Registrar a saída de itens para descarte ou perda.',
              onTap: () {
                // A fazer: Navegar para a tela de Descarte
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidade em desenvolvimento.'),
                  ),
                );
              },
            ),
            _buildOptionCard(
              context: context,
              icon: Icons.sync_alt,
              title: 'Reprocesso',
              subtitle: 'Registrar a movimentação de itens para um novo lote.',
              onTap: () {
                // A fazer: Navegar para a tela de Reprocesso
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text('Funcionalidade em desenvolvimento.'),
                  ),
                );
              },
            ),
          ],
        ),
      ),
    );
  }

  // Widget auxiliar para criar os cartões de opção de forma consistente
  Widget _buildOptionCard({
    required BuildContext context,
    required IconData icon,
    required String title,
    required String subtitle,
    required VoidCallback onTap,
  }) {
    return Card(
      elevation: 4,
      margin: const EdgeInsets.symmetric(vertical: 8),
      child: ListTile(
        leading: Icon(icon, size: 40, color: Theme.of(context).primaryColor),
        title: Text(title, style: const TextStyle(fontWeight: FontWeight.bold)),
        subtitle: Text(subtitle),
        onTap: onTap,
        contentPadding: const EdgeInsets.all(16),
      ),
    );
  }
}
