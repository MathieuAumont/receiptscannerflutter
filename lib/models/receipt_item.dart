class ReceiptItem {
  final String id;
  final String name;
  final double price;
  final int quantity;

  ReceiptItem({
    required this.id,
    required this.name,
    required this.price,
    required this.quantity,
  });

  factory ReceiptItem.fromJson(Map<String, dynamic> json) {
    return ReceiptItem(
      id: json['id'] as String,
      name: json['name'] as String,
      price: (json['price'] as num).toDouble(),
      quantity: json['quantity'] as int,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'price': price,
      'quantity': quantity,
    };
  }
} 