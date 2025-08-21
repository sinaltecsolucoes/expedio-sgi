// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  static const String _baseUrl = 'http://10.0.0.250/marchef/public/api.php';

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
        String token = responseData['token'];
        String userName = responseData['userName'];
        await _saveAuthData(token, userName);
        return {'success': true, 'message': 'Login bem-sucedido!'};
      } else {
        return {
          'success': false,
          'message': responseData['message'] ?? 'Erro desconhecido.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Função privada para salvar os dados no dispositivo
  Future<void> _saveAuthData(String token, String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);
    await prefs.setString('user_name', userName);
  }

  // Função para buscar dados do token e do nome de usuário
  Future<Map<String, String?>> getAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString('api_token'),
      'userName': prefs.getString('usu_nome'),
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
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        return jsonDecode(response.body);
      } else {
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

  // Função para salvar o cabeçalho do carregamento
  Future<Map<String, dynamic>> salvarCarregamentoHeader({
    required String numero,
    required String data,
    required String clienteOrganizadorId,
    required String lacre,
    required String placa,
    required String horaInicio,
    required String ordemExpedicao,
  }) async {
    final url = Uri.parse('$_baseUrl?action=salvarCarregamentoHeader');
    final authData = await getAuthData();
    final token = authData['token'];

    if (token == null)
      return {'success': false, 'message': 'Usuário não autenticado.'};

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
          'lacre': lacre,
          'placa': placa,
          'hora_inicio': horaInicio,
          'ordem_expedicao': ordemExpedicao,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Busca a lista de carregamentos ativos
  Future<List<Map<String, dynamic>>> getCarregamentosAtivos({
    int limit = 3,
  }) async {
    final url = Uri.parse(
      '$_baseUrl?action=getCarregamentosAtivos&limit=$limit',
    );
    final authData = await getAuthData();
    final token = authData['token'];

    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return List<Map<String, dynamic>>.from(responseData['data'] ?? []);
        }
      }
    } catch (e) {
      print('Erro ao buscar carregamentos ativos: $e');
    }
    return []; // Retorna lista vazia em caso de qualquer falha
  }

  // Busca a lista de carregamentos finalizados
  Future<List<Map<String, dynamic>>> getCarregamentosFinalizados({
    int limit = 3,
  }) async {
    final url = Uri.parse(
      '$_baseUrl?action=getCarregamentosFinalizados&limit=$limit',
    );
    final authData = await getAuthData();
    final token = authData['token'];

    if (token == null) return [];

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return List<Map<String, dynamic>>.from(responseData['data'] ?? []);
        }
      }
    } catch (e) {
      print('Erro ao buscar carregamentos finalizados: $e');
    }
    return []; // Retorna lista vazia em caso de qualquer falha
  }

  // Busca o resumo de um carregamento finalizado
  Future<Map<String, dynamic>> getResumoCarregamento(
    String carregamentoId,
  ) async {
    final url = Uri.parse(
      '$_baseUrl?action=getResumoCarregamento&carregamentoId=$carregamentoId',
    );
    final authData = await getAuthData();
    final token = authData['token'];

    if (token == null) {
      return {'success': false, 'message': 'Usuário não autenticado.'};
    }

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );

      if (response.statusCode == 200) {
        final responseData = jsonDecode(response.body);
        if (responseData['success'] == true) {
          return {'success': true, 'data': responseData['data'] ?? {}};
        } else {
          return {
            'success': false,
            'message': responseData['message'] ?? 'Erro desconhecido.',
          };
        }
      } else {
        return {
          'success': false,
          'message': 'Falha ao carregar resumo do carregamento.',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Busca as filas de um carregamento específico.
  Future<Map<String, dynamic>> getFilasPorCarregamento(
    int carregamentoId,
  ) async {
    final url = Uri.parse(
      '$_baseUrl?action=getFilasPorCarregamento&carregamentoId=$carregamentoId',
    );
    final authData = await getAuthData();
    final token = authData['token'];

    if (token == null) return {'success': false, 'message': 'Não autenticado'};

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Cria uma nova fila em um carregamento.
  Future<Map<String, dynamic>> criarFila(int carregamentoId) async {
    final url = Uri.parse('$_baseUrl?action=criarFila');
    final authData = await getAuthData();
    final token = authData['token'];

    if (token == null) return {'success': false, 'message': 'Não autenticado'};

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'carregamentoId': carregamentoId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<Map<String, dynamic>> atualizarCarregamentoHeader({
    required int carregamentoId,
    required String lacre,
    required String placa,
    required String horaInicio,
    required String ordemExpedicao,
  }) async {
    final url = Uri.parse('$_baseUrl?action=atualizarCarregamentoHeader');
    final authData = await getAuthData();
    final token = authData['token'];

    if (token == null) return {'success': false, 'message': 'Não autenticado'};

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({
          'carregamentoId': carregamentoId,
          'lacre': lacre,
          'placa': placa,
          'hora_inicio': horaInicio,
          'ordem_expedicao': ordemExpedicao,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Busca os detalhes do cabeçalho de um carregamento específico.
  Future<Map<String, dynamic>> getCarregamentoHeader(int carregamentoId) async {
    final url = Uri.parse(
      '$_baseUrl?action=getCarregamentoHeader&carregamentoId=$carregamentoId',
    );
    final authData = await getAuthData();
    final token = authData['token'];

    if (token == null) return {'success': false, 'message': 'Não autenticado'};

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {
        'success': false,
        'message': 'Erro de conexão: $e',
      }; // Dois pontos adicionados
    }
  }

  // Busca os detalhes de uma fila específica.
  Future<Map<String, dynamic>> getDetalhesFila(int filaId) async {
    final url = Uri.parse('$_baseUrl?action=getDetalhesFila&filaId=$filaId');
    final authData = await getAuthData();
    final token = authData['token'];

    if (token == null) return {'success': false, 'message': 'Não autenticado'};

    try {
      final response = await http.get(
        url,
        headers: {'Authorization': 'Bearer $token'},
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Valida um QR Code lido com a API
  Future<Map<String, dynamic>> validarLeitura(String qrCode) async {
    final url = Uri.parse('$_baseUrl?action=validarLeitura');
    final authData = await getAuthData();
    final token = authData['token'];

    if (token == null) return {'success': false, 'message': 'Não autenticado'};

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: jsonEncode({'qrCode': qrCode}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }
}
