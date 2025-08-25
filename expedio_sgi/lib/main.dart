// lib/main.dart

import 'package:flutter/material.dart';
import 'screens/login_screen.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'App de Carregamento',
      debugShowCheckedModeBanner: false,
      // --- TEMA GLOBAL APLICADO ---
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color.fromARGB(255, 58, 130, 197),
        ),
        useMaterial3: true,

        // Define o tema padrão para todos os ElevatedButtons do app
        elevatedButtonTheme: ElevatedButtonThemeData(
          style: ElevatedButton.styleFrom(
            backgroundColor: const Color.fromARGB(223, 77, 140, 199),
            foregroundColor: Colors.white,
            padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
            textStyle: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
            ),
          ),
        ),

        // Tema padrão para FloatingActionButtons
        floatingActionButtonTheme: const FloatingActionButtonThemeData(
          backgroundColor: Color.fromARGB(255, 58, 130, 197),
          foregroundColor: Colors.white,
          extendedTextStyle: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),

      // -----------------------------
      home: const LoginScreen(),
    );
  }
}
