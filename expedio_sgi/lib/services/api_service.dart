// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiService {
  //  static const String _baseUrl = 'http://10.0.0.250/marchef/public/api.php';

  // Função para buscar o IP salvo e montar a URL base dinamicamente
  /*  Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();
    // Busca o IP salvo. Se não houver, usa um valor padrão.
    final ip =
        prefs.getString('server_ip') ??
       // '192.168.3.27'; // IP padrão aqui quando usar o celular fisico
    //prefs.getString('server_ip') ?? '10.0.2.2'; // IP padrão aqui quando usar emulador
     prefs.getString('server_ip') ?? 'marchef.ddns.net'; // IP padrão aqui quando usar servidor
    //return 'http://$ip/marchef/public/api.php';
    return 'http://$ip/marchef/public/api.php';
  }*/

  Future<String> _getBaseUrl() async {
    final prefs = await SharedPreferences.getInstance();

    // 1. Tenta buscar um IP/endereço personalizado salvo nas configurações.
    final String? customUrl = prefs.getString('server_ip');

    // 2. Verifica se o campo não está vazio ou nulo.
    if (customUrl != null && customUrl.isNotEmpty) {
      // Se o usuário digitou um IP (ex: 192.168.0.10), monta a URL local.
      return 'http://$customUrl/marchef/public/api.php';
    } else {
      // 3. Se não houver nada salvo, usa a URL online como padrão.
      return 'https://marchef.ddns.net/marchef/public/api.php';
    }
  }

  // Função para fazer login
  Future<Map<String, dynamic>> login(String login, String senha) async {
    // final url = Uri.parse('$_baseUrl?action=login');
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=login');

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
    // final url = Uri.parse('$_baseUrl?action=getDadosNovoCarregamento');
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=getDadosNovoCarregamento');
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
    //final url = Uri.parse('$_baseUrl?action=salvarCarregamentoHeader');
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=salvarCarregamentoHeader');
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
    // 1. Busca a URL base dinâmica primeiro
    final baseUrl = await _getBaseUrl();
    // 2. Usa a nova URL para montar o endereço final
    final url = Uri.parse(
      '$baseUrl?action=getCarregamentosAtivos&limit=$limit',
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
    /* final url = Uri.parse(
      '$_baseUrl?action=getCarregamentosFinalizados&limit=$limit',
    );*/

    final baseUrl = await _getBaseUrl();

    // 2. Usa a nova URL para montar o endereço final
    final url = Uri.parse(
      '$baseUrl?action=getCarregamentosFinalizados&limit=$limit',
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
    /* final url = Uri.parse(
      '$_baseUrl?action=getResumoCarregamento&carregamentoId=$carregamentoId',
    );*/

    final baseUrl = await _getBaseUrl();

    // 2. Usa a nova URL para montar o endereço final
    final url = Uri.parse(
      '$baseUrl?action=getResumoCarregamento&carregamentoId=$carregamentoId',
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
    /*  final url = Uri.parse(
      '$_baseUrl?action=getFilasPorCarregamento&carregamentoId=$carregamentoId',
    );*/

    final baseUrl = await _getBaseUrl();

    // 2. Usa a nova URL para montar o endereço final
    final url = Uri.parse(
      '$baseUrl?action=getFilasPorCarregamento&carregamentoId=$carregamentoId',
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
    //final url = Uri.parse('$_baseUrl?action=criarFila');
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=criarFila');
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
    //final url = Uri.parse('$_baseUrl?action=atualizarCarregamentoHeader');
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=atualizarCarregamentoHeader');
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
    // 1. Busca a URL base dinâmica (com o IP que o usuário digitou)
    final baseUrl = await _getBaseUrl();

    // 2. Usa essa nova URL para montar o endereço final
    final url = Uri.parse(
      '$baseUrl?action=getCarregamentoHeader&carregamentoId=$carregamentoId',
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
    //final url = Uri.parse('$_baseUrl?action=getDetalhesFila&filaId=$filaId');
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=getDetalhesFila&filaId=$filaId');
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
    //final baseUrl = await _getBaseUrl();
    //final url = Uri.parse('$_baseUrl?action=validarLeitura');
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=validarLeitura');
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

      try {
        return jsonDecode(response.body);
      } catch (e) {
        print("--- RESPOSTA BRUTA DO SERVIDOR (DEBUG PHP) ---");
        print(response.body);
        print("--- FIM DA RESPOSTA BRUTA ---");
        return {
          'success': false,
          'message': 'Resposta inválida do servidor (ver DEBUG CONSOLE)',
        };
      }
    } catch (e) {
      print("--- ERRO DE CONEXÃO/HTTP CAPTURADO ---");
      print("MENSAGEM DO ERRO: $e");
      print("--- FIM DO ERRO DE CONEXÃO ---");
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<Map<String, dynamic>> salvarLeituras({
    required int carregamentoId,
    required int filaId,
    required int clienteId,
    required List<Map<String, dynamic>> leituras,
  }) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=salvarFilaComLeituras');
    final authData = await getAuthData();
    final token = authData['token'];

    if (token == null) return {'success': false, 'message': 'Não autenticado'};

    // Monta o corpo da requisição em uma variável separada
    final body = jsonEncode({
      'carregamentoId': carregamentoId,
      'filaId': filaId,
      'clienteId': clienteId,
      'leituras': leituras,
    });

    // ==========================================================
    // A PARTE DE DEPURAÇÃO ESTÁ AQUI
    // ==========================================================
    print("--- DEBUG FLUTTER: ENVIANDO DADOS PARA SALVAR ---");
    print(body);
    print("--- FIM DOS DADOS ---");
    // ==========================================================

    try {
      final response = await http.post(
        url,
        headers: {
          'Content-Type': 'application/json',
          'Authorization': 'Bearer $token',
        },
        body: body, // Usa a variável que criamos
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Faz o upload de uma foto para uma fila
  Future<Map<String, dynamic>> uploadFotoFila({
    required int filaId,
    required String imagePath, // O caminho do arquivo da imagem no celular
  }) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=uploadFotoFila');
    final authData = await getAuthData();
    final token = authData['token'];

    if (token == null) return {'success': false, 'message': 'Não autenticado'};

    // Cria uma requisição do tipo "multipart" para envio de arquivos
    var request = http.MultipartRequest('POST', url);

    // Adiciona o token no cabeçalho
    request.headers['Authorization'] = 'Bearer $token';

    // Adiciona os campos de texto (neste caso, o filaId)
    request.fields['filaId'] = filaId.toString();

    // Adiciona o arquivo da imagem
    request.files.add(
      await http.MultipartFile.fromPath(
        'foto', // Este é o nome do campo que o seu api.php espera: $_FILES['foto']
        imagePath,
      ),
    );

    try {
      final streamedResponse = await request.send();
      final response = await http.Response.fromStream(streamedResponse);

      if (response.statusCode >= 200 && response.statusCode < 300) {
        return jsonDecode(response.body);
      } else {
        return {
          'success': false,
          'message': 'Erro do servidor: ${response.body}',
        };
      }
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  Future<String> getBaseUrlForImages() async {
    final prefs = await SharedPreferences.getInstance();
    final ip = prefs.getString('server_ip') ?? '10.0.0.250';
    return 'http://$ip/marchef/public'; // Retorna a URL da pasta public
  }

  Future<Map<String, dynamic>> finalizarCarregamento(int carregamentoId) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=finalizarCarregamento');
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

  // NOVA FUNÇÃO: Exclui um carregamento.
  Future<Map<String, dynamic>> excluirCarregamento(int carregamentoId) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=excluirCarregamento');
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

  // Função remove um cliente de uma fila.
  Future<Map<String, dynamic>> removerClienteDeFila(
    int filaId,
    int clienteId,
  ) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=removerClienteDeFila');
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
        body: jsonEncode({'filaId': filaId, 'clienteId': clienteId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Função atualiza a lista de produtos de um cliente
  Future<Map<String, dynamic>> atualizarLeituras({
    required int carregamentoId,
    required int filaId,
    required int clienteId,
    required List<Map<String, dynamic>> leituras,
  }) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=atualizarItensCliente');
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
          'filaId': filaId,
          'clienteId': clienteId,
          'leituras': leituras,
        }),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // NOVA FUNÇÃO: Exclui uma fila específica.
  Future<Map<String, dynamic>> excluirFila(int filaId) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse(
      '$baseUrl?action=removerFilaCompleta',
    ); // Usaremos a ação que já existe no seu backend
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
        body: jsonEncode({'fila_id': filaId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // Função atualiza a quantidade de um único item.
  Future<Map<String, dynamic>> atualizarQuantidadeItem({
    required int itemId,
    required int novaQuantidade,
  }) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=atualizarQuantidadeItem');
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
        body: jsonEncode({'itemId': itemId, 'novaQuantidade': novaQuantidade}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  // NOVA FUNÇÃO: Exclui a foto de uma fila.
  Future<Map<String, dynamic>> excluirFotoFila(int filaId) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=excluirFotoFila');
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
        body: jsonEncode({'filaId': filaId}),
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }
}
