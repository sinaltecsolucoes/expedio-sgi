import 'package:flutter/material.dart';
import 'home_screen.dart'; // Tela antiga de SAÍDAS
import 'entradas_screen.dart'; // Nossa nova tela de ENTRADAS (vamos criar a seguir)

class SelecaoOperacaoScreen extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text('Selecionar Operação'), centerTitle: true),
      body: Center(
        child: Padding(
          padding: const EdgeInsets.all(32.0),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: <Widget>[
              // Botão para ENTRADAS
              ElevatedButton.icon(
                icon: Icon(Icons.input, size: 40),
                label: Text('ENTRADAS', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Navega para a nova tela de Entradas
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => EntradasScreen()),
                  );
                },
              ),
              SizedBox(height: 40), // Espaçamento
              // Botão para SAÍDAS
              ElevatedButton.icon(
                icon: Icon(Icons.output, size: 40),
                label: Text('SAÍDAS', style: TextStyle(fontSize: 20)),
                style: ElevatedButton.styleFrom(
                  padding: EdgeInsets.symmetric(vertical: 20),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                ),
                onPressed: () {
                  // Navega para a tela Home (que agora é o fluxo de Saídas)
                  Navigator.push(
                    context,
                    MaterialPageRoute(builder: (context) => HomeScreen()),
                  );
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
