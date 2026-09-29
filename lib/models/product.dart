class Product {
  String? productId;
  String productName;
  String category;
  String description;
  double price;
  int stockQuantity;
  String? expirationDate;
  int? minimumStock;
  String? unit;
  String? productCode;
  String? imageUrl;

  Product({
    this.productId,
    required this.productName,
    required this.category,
    required this.description,
    required this.price,
    required this.stockQuantity,
    this.expirationDate,
    this.minimumStock,
    this.unit,
    this.productCode,
    this.imageUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'productId': productId,
      'productName': productName,
      'category': category,
      'description': description,
      'price': price,
      'stockQuantity': stockQuantity,
      'expirationDate': expirationDate,
      'minimumStock': minimumStock,
      'unit': unit,
      'productCode': productCode,
      'imageUrl': imageUrl,
    };
  }

  factory Product.fromMap(Map<String, dynamic> map) {
    return Product(
      productId: map['productId'] as String?,
      productName: map['productName'] as String? ?? '',
      category: map['category'] as String? ?? '',
      description: map['description'] as String? ?? '',
      price: (map['price'] as num?)?.toDouble() ?? 0.0,
      stockQuantity: map['stockQuantity'] as int? ?? 0,
      expirationDate: map['expirationDate'] as String?,
      minimumStock: map['minimumStock'] as int?,
      unit: map['unit'] as String?,
      productCode: map['productCode'] as String?,
      imageUrl: map['imageUrl'] as String?,
    );
  }

  Product copyWith({
    String? productId,
    String? productName,
    String? category,
    String? description,
    double? price,
    int? stockQuantity,
    String? expirationDate,
    int? minimumStock,
    String? unit,
    String? productCode,
    String? imageUrl,
  }) {
    return Product(
      productId: productId ?? this.productId,
      productName: productName ?? this.productName,
      category: category ?? this.category,
      description: description ?? this.description,
      price: price ?? this.price,
      stockQuantity: stockQuantity ?? this.stockQuantity,
      expirationDate: expirationDate ?? this.expirationDate,
      minimumStock: minimumStock ?? this.minimumStock,
      unit: unit ?? this.unit,
      productCode: productCode ?? this.productCode,
      imageUrl: imageUrl ?? this.imageUrl,
    );
  }
}
