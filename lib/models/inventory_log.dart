class InventoryLog {
  String? logId;
  String productId; // FK to Product.productId
  String date;
  int quantityChange;
  String reason;

  InventoryLog({
    this.logId,
    required this.productId,
    required this.date,
    required this.quantityChange,
    required this.reason,
  });

  Map<String, dynamic> toMap() {
    return {
      'logId': logId,
      'productId': productId,
      'date': date,
      'quantityChange': quantityChange,
      'reason': reason,
    };
  }

  factory InventoryLog.fromMap(Map<String, dynamic> map) {
    return InventoryLog(
      logId: map['logId'] as String?,
      productId: map['productId'] as String? ?? '',
      date: map['date'] as String? ?? '',
      quantityChange: map['quantityChange'] as int? ?? 0,
      reason: map['reason'] as String? ?? '',
    );
  }

  InventoryLog copyWith({
    String? logId,
    String? productId,
    String? date,
    int? quantityChange,
    String? reason,
  }) {
    return InventoryLog(
      logId: logId ?? this.logId,
      productId: productId ?? this.productId,
      date: date ?? this.date,
      quantityChange: quantityChange ?? this.quantityChange,
      reason: reason ?? this.reason,
    );
  }

  /// Sortable timestamp for the stored `date` string (`yyyy-MM-dd`, ISO-8601
  /// in legacy rows, or blank). Unparseable values sort as epoch so the list
  /// never crashes on dirty data.
  DateTime get loggedAt {
    final trimmed = date.trim();
    if (trimmed.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    final parsed = DateTime.tryParse(trimmed);
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}
