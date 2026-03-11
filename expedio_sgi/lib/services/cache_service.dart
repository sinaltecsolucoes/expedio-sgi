// lib/services/cache_service.dart

import 'api_service.dart';
import 'package:shared_preferences/shared_preferences.dart';

class CacheService {
  // Instância privada e estática (Singleton)
  static final CacheService _instance = CacheService._internal();

  // Construtor de fábrica que retorna a instância única
  factory CacheService() {
    return _instance;
  }

  // Construtor interno
  CacheService._internal();

  // O nosso "caderno" para anotar a lista de clientes
  List<Map<String, dynamic>>? _cachedClientes;

  // Instância do nosso serviço de API para buscar os dados
  final ApiService _apiService = ApiService();

  // Função pública para obter os clientes
  Future<List<Map<String, dynamic>>> getClientes() async {
    // Se o "caderno" estiver vazio, busca os dados da API
    if (_cachedClientes == null) {
      print('CACHE: Buscando clientes da API pela primeira vez...');
      final response = await _apiService.getDadosNovoCarregamento();
      if (response['success'] == true) {
        // Anota a lista no caderno
        _cachedClientes = List<Map<String, dynamic>>.from(response['clientes']);
      } else {
        // Se der erro, lança uma exceção para a tela poder tratar
        throw Exception(
          'Falha ao carregar clientes da API: ${response['message']}',
        );
      }
    } else {
      print('CACHE: Carregando clientes da memória (cache).');
    }
    // Retorna a lista (seja a nova ou a que já estava no caderno)
    return _cachedClientes!;
  }

  Future<void> saveUserName(String userName) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('userName', userName);
  }

  Future<String?> getUserName() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('userName');
  }

  Future<void> clear() async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.clear(); // Apaga todos os dados salvos
  }

  Future<void> saveToken(String token) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('token', token);
  }

  Future<String?> getToken() async {
    final prefs = await SharedPreferences.getInstance();
    return prefs.getString('token');
  }

  Future<void> saveUserFuncao(String funcao) async {
    final prefs = await SharedPreferences.getInstance();
    print('DEBUG CACHE: Gravando "$funcao" na chave "user_funcao"');
    await prefs.setString('user_funcao', funcao);
  }

  Future<String?> getUserFuncao() async {
    final prefs = await SharedPreferences.getInstance();
    final valor = prefs.getString('user_funcao');
    print('DEBUG CACHE: Lido "$valor" da chave "user_funcao"');
    return valor;
  }
}
