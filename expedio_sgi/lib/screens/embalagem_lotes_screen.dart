import 'package:flutter/material.dart';
import '../services/api_service.dart';
import 'inserir_embalagem_screen.dart';

class EmbalagemLotesScreen extends StatefulWidget {
  const EmbalagemLotesScreen({super.key});

  @override
  State<EmbalagemLotesScreen> createState() => _EmbalagemLotesScreenState();
}

class _EmbalagemLotesScreenState extends State<EmbalagemLotesScreen> {
  final ApiService _apiService = ApiService();

  List<Map<String, dynamic>> _allLotes = []; // Lista original completa
  List<Map<String, dynamic>> _filteredLotes = []; // Lista filtrada exibida
  bool _isLoading = true;
  final TextEditingController _searchController = TextEditingController();

  @override
  void initState() {
    super.initState();
    _fetchLotes();
  }

  Future<void> _fetchLotes() async {
    try {
      final data = await _apiService.getLotesEmbalagem();
      setState(() {
        _allLotes = data;
        _filteredLotes = data;
        _isLoading = false;
      });
    } catch (e) {
      setState(() => _isLoading = false);
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Erro ao carregar lotes: $e')));
    }
  }

  // Função que filtra a lista em tempo real
  void _filterLotes(String query) {
    setState(() {
      _filteredLotes = _allLotes.where((lote) {
        final codigo =
            lote['lote_completo_calculado']?.toString().toLowerCase() ?? '';
        final produto = lote['produto_nome']?.toString().toLowerCase() ?? '';
        return codigo.contains(query.toLowerCase()) ||
            produto.contains(query.toLowerCase());
      }).toList();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Lotes para Embalagem', // Título em Caps para destaque
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        backgroundColor: Colors.purple.shade700,
        iconTheme: const IconThemeData(
          color: Colors.white,
        ), // Seta de voltar branca
      ),
      body: Column(
        children: [
          // Campo de Busca
          Padding(
            padding: const EdgeInsets.all(12.0),
            child: TextField(
              controller: _searchController,
              onChanged: _filterLotes,
              decoration: InputDecoration(
                labelText: 'Buscar Lote ou Produto...',
                prefixIcon: const Icon(Icons.search, color: Colors.purple),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide(
                    color: Colors.purple.shade700,
                    width: 2,
                  ),
                ),
              ),
            ),
          ),

          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : _filteredLotes.isEmpty
                ? const Center(child: Text('Nenhum lote encontrado.'))
                : ListView.builder(
                    itemCount: _filteredLotes.length,
                    itemBuilder: (context, index) {
                      final lote = _filteredLotes[index];

                      /*  return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.shade100,
                            child: const Icon(
                              Icons.inventory,
                              color: Colors.purple,
                            ),
                          ),
                          title: Text(
                            'Lote: ${lote['lote_completo_calculado']}',
                            style: const TextStyle(fontWeight: FontWeight.bold),
                          ),
                          subtitle: Text('Produto: ${lote['prod_descricao']}'),
                          trailing: const Icon(Icons.chevron_right),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InserirEmbalagemScreen(
                                  loteId: int.parse(lote['lote_id'].toString()),
                                ),
                              ),
                            );
                          },
                        ),
                      );*/

                      // lib/screens/embalagem_lotes_screen.dart

                      // ... dentro do ListView.builder
                      return Card(
                        margin: const EdgeInsets.symmetric(
                          horizontal: 12,
                          vertical: 6,
                        ),
                        elevation: 4,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(10),
                        ),
                        child: ListTile(
                          contentPadding: const EdgeInsets.symmetric(
                            horizontal: 16,
                            vertical: 8,
                          ),
                          leading: CircleAvatar(
                            backgroundColor: Colors.purple.shade100,
                            child: const Icon(
                              Icons.inventory,
                              color: Colors.purple,
                            ),
                          ),
                          title: Text(
                            'Lote: ${lote['lote_completo_calculado']}', // Exibe a numeração do lote completo
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 18,
                              color: Colors.black87,
                            ),
                          ),
                          trailing: const Icon(
                            Icons.arrow_forward_ios,
                            color: Colors.purple,
                          ),
                          onTap: () {
                            Navigator.push(
                              context,
                              MaterialPageRoute(
                                builder: (context) => InserirEmbalagemScreen(
                                  loteId: int.parse(lote['lote_id'].toString()),
                                  loteCodigo:
                                      lote['lote_completo_calculado'] ??
                                      lote['lote_codigo'].toString(),
                                ),
                              ),
                            );
                          },
                        ),
                      );
                    },
                  ),
          ),
        ],
      ),
    );
  }
}
