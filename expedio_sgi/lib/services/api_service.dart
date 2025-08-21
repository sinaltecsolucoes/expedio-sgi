// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  // !!! URL REAL DA API !!!
  static const String _baseUrl = 'http://192.168.3.27/marchef/public/api.php';

  // Função para fazer login
  Future<Map<String, dynamic>> login(String login, String senha) async {
    final url = Uri.parse('$_baseUrl?action=login');

    try {
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json'},
        body: jsonEncode({'login': login, 'senha': senha}),
      );

      final responseData = jsonDecode(response.body);

      if (response.statusCode == 200 && responseData['success'] == true) {
        // Se o login for bem-sucedido, salva o token e o nome do usuário
        String token = responseData['token'];
        String userName = responseData['userName'];
        await _saveAuthData(token, userName);
        return {'success': true, 'message': 'Login bem-sucedido!'};
      } else {
        // Se falhar, retorna a mensagem de erro da API
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erro desconhecido.',
        };
      }
    } catch (e) {
      // Em caso de erro de conexão ou outro problema
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Função privada para salvar os dados no dispositivo
  Future<void> _saveAuthData(String token, String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);
    await prefs.setString('user_name', userName);
  }

  // DENTRO DA CLASSE ApiService, EM lib/services/api_service.dart

  // Função para buscar dados do token e do nome de usuário
  Future<Map<String, String?>> getAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString('api_token'),
      'userName': prefs.getString('user_name'),
    };
  }

  // Função para buscar os dados iniciais de um novo carregamento
  Future<Map<String, dynamic>> getDadosNovoCarregamento() async {
    final url = Uri.parse('$_baseUrl?action=getDadosNovoCarregamento');
    final authData = await getAuthData();
    final token = authData['token'];

    if (token == null) {
      return {'success': false, 'message': 'Usuário não autenticado.'};
    }

    try {
      final response = await http.get(
        url,
        // As rotas protegidas precisam do token no cabeçalho (Header)
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
        // Tenta decodificar a mensagem de erro da API, se houver
        final responseData = jsonDecode(response.body);
        return {
          'success': false,
          'message': responseData['message'] ?? 'Falha ao carregar dados.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<Map<String, dynamic>> salvarCarregamentoHeader({
    required int numero,
    required String data,
    required String clienteOrganizadorId,
  }) async {
    final url = Uri.parse('$_baseUrl?action=salvarCarregamentoHeader');
    final authData = await getAuthData();
    final token = authData['token'];

    if (token == null || token.isEmpty) {
      return {
        'success': false,
        'message': 'Usuário não autenticado no Flutter.',
      };
    }

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'numero': numero,
          'data': data,
          'clienteOrganizadorId': clienteOrganizadorId,
        }),
      );
      // Apenas retorna o corpo da resposta decodificado
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }
}
