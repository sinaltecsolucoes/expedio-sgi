// lib/services/api_service.dart

import 'dart:convert';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';
//import '../models/operacao_modo.dart';
import 'cache_service.dart';

class ApiService {
  Future<String> _getServerRoot() async {
    final prefs = await SharedPreferences.getInstance();
    final customAddress = prefs.getString('server_ip');

    if (customAddress != null && customAddress.trim().isNotEmpty) {
      // Se o utilizador digitou um endereço/IP, usamos ele com http
      print('Usando IP local para testes: $customAddress');
      return 'http://${customAddress.trim()}';
    } else {
      // Caso contrário, usamos a URL online padrão com https
      print('Nenhum IP local encontrado. Usando servidor de produção.');
      return 'https://marchef.ddns.net';
    }
  }

  Future<String> _getBaseUrl() async {
    final root = await _getServerRoot();
    return '$root/marchef/public/api.php';
  }

  Future<String> getBaseUrlForImages() async {
    final root = await _getServerRoot();
    return '$root/marchef/public'; // Retorna a URL da pasta public
  }

  /*  Future<Map<String, dynamic>> login(String login, String senha) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=login');
    print('Tentando conectar a: $url');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'login': login, 'senha': senha}),
    );

    if (response.statusCode == 200) {
      return jsonDecode(response.body);
    } else {
      throw Exception('Falha ao autenticar: ${response.body}');
    }
  }
*/

  /*  Future<Map<String, dynamic>> login(String login, String senha) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=login');
    print('Tentando conectar a: $url');

    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: jsonEncode({'login': login, 'senha': senha}),
    );

    if (response.statusCode == 200) {
      final body = jsonDecode(response.body);
      // Adicionamos a verificação de sucesso e a chamada para salvar o token
      if (body['success'] == true) {
        final token = body['token'];
        final userName = body['usu_nome'];
        // SALVA O TOKEN E O NOME DE UTILIZADOR
        await _saveAuthData(token, userName);
      }
      return body;
    } else {
      throw Exception('Falha ao autenticar: ${response.body}');
    }
  }
*/

  Future<Map<String, dynamic>> login(String login, String senha) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=login');
    print('Tentando conectar a URL: $url');

    try {
      print('Iniciando requisição HTTP POST...');
      final response = await http.post(
        url,
        headers: {'Content-Type': 'application/json; charset=UTF-8'},
        body: jsonEncode({'login': login, 'senha': senha}),
      );
      print('Requisição finalizada com status: ${response.statusCode}');

      if (response.statusCode == 200) {
        final body = jsonDecode(response.body);
        if (body['success'] == true) {
          final token = body['token'];
          // Garante que userName é sempre uma String, mesmo que a resposta da API seja null
          final userName = body['usu_nome'] ?? '';
          await _saveAuthData(token, userName);
        }
        return body;
      } else {
        throw Exception('Falha ao autenticar: ${response.body}');
      }
    } catch (e) {
      print('Erro de conexão ou requisição: $e');
      throw Exception(
        'Erro de rede ou conexão. Por favor, verifique sua conexão ou o endereço do servidor.',
      );
    }
  }

  // Função privada para salvar os dados no dispositivo
  /* Future<void> _saveAuthData(String token, String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);
    await prefs.setString('user_name', userName);
  }
*/
  // Função para buscar dados do token e do nome de usuário
  Future<Map<String, String?>> getAuthData() async {
    final prefs = await SharedPreferences.getInstance();
    return {
      'token': prefs.getString('api_token'),
      'userName': prefs.getString('usu_nome'),
    };
  }

  Future<void> _saveAuthData(String token, String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('api_token', token);
    await prefs.setString(
      'user_name',
      userName,
    ); // Garante que a chave é sempre 'user_name'
  }

  Future<Map<String, dynamic>> getDadosNovoCarregamento() async {
    final cacheService = CacheService();
    final token = await cacheService.getToken(); // Pega o token do cache

    if (token == null) {
      // Se não houver token, retorna um erro antes mesmo de chamar a API
      return {'success': false, 'message': 'Usuário não autenticado.'};
    }

    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=getDadosNovoCarregamento');

    final response = await http.get(
      url,
      headers: {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token', // Envia o token para a API
      },
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao carregar dados da API: ${response.body}');
    }
  }

  // Função para salvar o cabeçalho do carregamento
  Future<Map<String, dynamic>> salvarCarregamentoHeader({
    required String numero,
    required String data,
    required String clienteOrganizadorId,
    String? transportadoraId,
    String? lacre,
    String? placa,
    String? horaInicio,
    String? motoristaNome,
    String? motoristaCpf,
    required String tipo,
    String? ordemExpedicaoId,
  }) async {
    print('ApiService: Cliente ID recebido da tela: $clienteOrganizadorId');
    final cacheService = CacheService();
    final token = await cacheService.getToken();

    if (token == null) {
      throw Exception('Token não encontrado, faça o login novamente.');
    }

    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=salvar_carregamento_header');

    // Construímos o corpo da requisição com todos os campos
    final body = {
      'numero': numero,
      'data': data,
      'clienteOrganizadorId': clienteOrganizadorId,
      'transportadoraId': transportadoraId,
      'lacre': lacre,
      'placa': placa,
      'horaInicio': horaInicio,
      'motoristaNome': motoristaNome,
      'motoristaCpf': motoristaCpf,
      'tipo': tipo,
      'ordemExpedicaoId': ordemExpedicaoId,
    };

    // Removemos chaves com valores nulos para não enviar dados desnecessários
    body.removeWhere((key, value) => value == null);

    final response = await http.post(
      url,
      headers: {
        'Content-Type': 'application/json; charset=UTF-8',
        'Authorization': 'Bearer $token',
      },
      body: json.encode(body),
    );

    if (response.statusCode == 200) {
      return json.decode(response.body);
    } else {
      throw Exception('Falha ao salvar o cabeçalho: ${response.body}');
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
    // DEPURAÇÃO
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

  // Função para exclui um carregamento.
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

  // Função para excluir uma fila específica.
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

  Future<Map<String, dynamic>> getFotosDaFila(int filaId) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=getFotosDaFila&filaId=$filaId');
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

  Future<Map<String, dynamic>> excluirFotoFila(int fotoId) async {
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
        body: jsonEncode({'fotoId': fotoId}), // Enviando fotoId
      );
      return jsonDecode(response.body);
    } catch (e) {
      return {'success': false, 'message': 'Erro de conexão: $e'};
    }
  }

  /// Busca a lista de todas as câmaras de estoque.
  Future<List<Map<String, dynamic>>> getCamaras() async {
    final baseUrl = await _getBaseUrl();
    //final url = Uri.parse('$baseUrl?action=get_camaras');
    final url = Uri.parse('$baseUrl?action=get_camaras');
    final response = await http.get(url);

    print('Resposta da API (Endereços): ${response.body}');

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body['status'] == 'success') {
        // A API retorna uma lista de objetos, então fazemos o cast para o tipo correto.
        return List<Map<String, dynamic>>.from(body['data']);
      } else {
        throw Exception('Falha ao carregar câmaras: ${body['message']}');
      }
    } else {
      throw Exception('Erro de rede ao buscar câmaras: ${response.statusCode}');
    }
  }

  /// Busca a lista de endereços para uma câmara específica.
  Future<List<Map<String, dynamic>>> getEnderecosPorCamara(int camaraId) async {
    // Passamos o camara_id como um parâmetro na URL.
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse(
      '$baseUrl?action=get_enderecos_por_camara&camara_id=$camaraId',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body['status'] == 'success') {
        return List<Map<String, dynamic>>.from(body['data']);
      } else {
        throw Exception('Falha ao carregar endereços: ${body['message']}');
      }
    } else {
      throw Exception(
        'Erro de rede ao buscar endereços: ${response.statusCode}',
      );
    }
  }

  Future<Map<String, dynamic>> registrarEntrada(
    int enderecoId,
    String qrCode,
  ) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=registrar_entrada_estoque');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({
        'endereco_id': enderecoId,
        'qrcode': qrCode,
        // 'usuario_id': SEU_ID_DE_USUARIO_LOGADO, // Futuramente, pegar da sessão
      }),
    );

    if (response.statusCode == 200 ||
        response.statusCode == 409 ||
        response.statusCode == 404) {
      // Aceita respostas de sucesso (200) ou de erros de negócio (409, 404)
      return json.decode(response.body);
    } else {
      // Erros de servidor inesperados
      throw Exception('Falha ao registrar entrada: ${response.body}');
    }
  }

  Future<List<Map<String, dynamic>>> getEntradasDoDia(int enderecoId) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse(
      '$baseUrl?action=get_entradas_do_dia&endereco_id=$enderecoId',
    );
    final response = await http.get(url);

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body['success'] == true) {
        return List<Map<String, dynamic>>.from(body['data']);
      } else {
        throw Exception('Falha ao buscar entradas: ${body['message']}');
      }
    } else {
      throw Exception('Erro de rede ao buscar entradas: ${response.body}');
    }
  }

  Future<bool> excluirAlocacao(int alocacaoId) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=excluir_alocacao_entrada');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({'alocacao_id': alocacaoId}),
    );
    return response.statusCode == 200 &&
        json.decode(response.body)['success'] == true;
  }

  Future<bool> editarQuantidade(int alocacaoId, double novaQuantidade) async {
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=editar_quantidade_alocacao');
    final response = await http.post(
      url,
      headers: {'Content-Type': 'application/json; charset=UTF-8'},
      body: json.encode({
        'alocacao_id': alocacaoId,
        'nova_quantidade': novaQuantidade,
      }),
    );
    return response.statusCode == 200 &&
        json.decode(response.body)['success'] == true;
  }

  /// Busca a lista de Ordens de Expedição prontas para carregar.
  Future<List<Map<String, dynamic>>> getOrdensProntas() async {
    final token = await CacheService().getToken();
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=get_ordens_prontas');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body['success'] == true) {
        return List<Map<String, dynamic>>.from(body['data']);
      } else {
        throw Exception('Falha ao buscar OEs: ${body['message']}');
      }
    } else {
      throw Exception('Erro de rede ao buscar OEs: ${response.body}');
    }
  }

  /// Busca os detalhes de uma OE específica para pré-preencher o carregamento.
  Future<Map<String, dynamic>> getDetalhesOE(int oeId) async {
    final token = await CacheService().getToken();
    final baseUrl = await _getBaseUrl();
    final url = Uri.parse('$baseUrl?action=get_detalhes_oe&oe_id=$oeId');

    final response = await http.get(
      url,
      headers: {'Authorization': 'Bearer $token'},
    );

    if (response.statusCode == 200) {
      final body = json.decode(response.body);
      if (body['success'] == true) {
        return Map<String, dynamic>.from(body['data']);
      } else {
        throw Exception('Falha ao buscar detalhes da OE: ${body['message']}');
      }
    } else {
      throw Exception(
        'Erro de rede ao buscar detalhes da OE: ${response.body}',
      );
    }
  }
}
