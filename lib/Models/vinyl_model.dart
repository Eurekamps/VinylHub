class VinylPrice {
  final String store;
  final double price;
  final String url;

  VinylPrice({required this.store, required this.price, required this.url});

  factory VinylPrice.fromJson(Map<String, dynamic> json) {
    return VinylPrice(
      store: json['store'],
      price: json['price'].toDouble(),
      url: json['url'],
    );
  }
}
