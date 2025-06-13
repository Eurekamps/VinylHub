class FbPedido {
  final String direccion;
  final String codigoPostal;
  final String ciudad;
  final String provincia;
  final int precio;
  final String numeroPedido;
  final String compradorUid;
  final String vendedorUid;
  final String postId;
  final DateTime timestamp;

  FbPedido({
    required this.direccion,
    required this.codigoPostal,
    required this.ciudad,
    required this.provincia,
    required this.precio,
    required this.numeroPedido,
    required this.compradorUid,
    required this.vendedorUid,
    required this.postId,
    required this.timestamp,
  });

  Map<String, dynamic> toMap() {
    return {
      'direccion': direccion,
      'codigoPostal': codigoPostal,
      'ciudad': ciudad,
      'provincia': provincia,
      'precio': precio,
      'numeroPedido': numeroPedido,
      'compradorUid': compradorUid,
      'vendedorUid': vendedorUid,
      'postId': postId,
      'timestamp': timestamp,
    };
  }
}