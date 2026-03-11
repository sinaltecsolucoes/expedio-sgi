class ProdutoPrimario {
  final int itemProdId;
  final int prodId;
  final String nome;
  final String unidade;
  final double saldo;
  final double pesoPrimario;
  final List<ProdutoSecundario> secundarios;

  ProdutoPrimario({
    required this.itemProdId,
    required this.prodId,
    required this.nome,
    required this.unidade,
    required this.saldo,
    required this.pesoPrimario,
    required this.secundarios,
  });

  factory ProdutoPrimario.fromJson(Map<String, dynamic> json) {
    var list = json['secundarios'] as List;
    List<ProdutoSecundario> secundariosList = list
        .map((i) => ProdutoSecundario.fromJson(i))
        .toList();

    return ProdutoPrimario(
      itemProdId: json['item_prod_id'],
      prodId: json['prod_id'],
      nome: json['nome'],
      unidade: json['unidade'],
      saldo: double.parse(json['saldo'].toString()),
      pesoPrimario: double.parse(json['peso_primario'].toString()),
      secundarios: secundariosList,
    );
  }
}

class ProdutoSecundario {
  final int prodCodigo;
  final String prodDescricao;
  final double prodPesoEmbalagem;

  ProdutoSecundario({
    required this.prodCodigo,
    required this.prodDescricao,
    required this.prodPesoEmbalagem,
  });

  factory ProdutoSecundario.fromJson(Map<String, dynamic> json) {
    return ProdutoSecundario(
      prodCodigo: json['prod_codigo'],
      prodDescricao: json['prod_descricao'],
      prodPesoEmbalagem: double.parse(json['prod_peso_embalagem'].toString()),
    );
  }
}
