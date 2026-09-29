class Sales {
  String? saleId;
  String ownerUid;
  String customerName;
  String customerEmail;
  String customerContact;
  String customerAddress;
  String date;
  double totalAmount;
  String paymentStatus;
  String paymentMethod;
  String paymentDate;
  String orderStatus;
  String orderReference;
  String paymentReference;
  String? paymentProofUrl;
  String? pickupDate;
  String? orderNotes;

  Sales({
    this.saleId,
    required this.ownerUid,
    this.customerName = '',
    this.customerEmail = '',
    this.customerContact = '',
    this.customerAddress = '',
    required this.date,
    required this.totalAmount,
    required this.paymentStatus,
    required this.paymentMethod,
    required this.paymentDate,
    this.orderStatus = 'completed',
    this.orderReference = '',
    this.paymentReference = '',
    this.paymentProofUrl,
    this.pickupDate,
    this.orderNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'saleId': saleId,
      'ownerUid': ownerUid,
      'customerName': customerName,
      'customerEmail': customerEmail,
      'customerContact': customerContact,
      'customerAddress': customerAddress,
      'date': date,
      'totalAmount': totalAmount,
      'paymentStatus': paymentStatus,
      'paymentMethod': paymentMethod,
      'paymentDate': paymentDate,
      'orderStatus': orderStatus,
      'orderReference': orderReference,
      'paymentReference': paymentReference,
      'paymentProofUrl': paymentProofUrl,
      'pickupDate': pickupDate,
      'orderNotes': orderNotes,
    };
  }

  factory Sales.fromMap(Map<String, dynamic> map) {
    final status = (map['paymentStatus'] as String?) ?? '';
    final defaultOrderStatus =
        (status.toLowerCase() == 'paid') ? 'completed' : 'pending_confirmation';

    return Sales(
      saleId: map['saleId'] as String?,
      ownerUid: map['ownerUid'] as String? ?? '',
      customerName: map['customerName'] as String? ?? '',
      customerEmail: map['customerEmail'] as String? ?? '',
      customerContact: map['customerContact'] as String? ?? '',
      customerAddress: map['customerAddress'] as String? ?? '',
      date: map['date'] as String? ?? '',
      totalAmount: (map['totalAmount'] as num?)?.toDouble() ?? 0.0,
      paymentStatus: status,
      paymentMethod: map['paymentMethod'] as String? ?? 'Cash',
      paymentDate: map['paymentDate'] as String? ?? '',
      orderStatus: map['orderStatus'] as String? ?? defaultOrderStatus,
      orderReference: map['orderReference'] as String? ?? '',
      paymentReference: map['paymentReference'] as String? ?? '',
      paymentProofUrl: map['paymentProofUrl'] as String?,
      pickupDate: map['pickupDate'] as String?,
      orderNotes: map['orderNotes'] as String?,
    );
  }

  Sales copyWith({
    String? saleId,
    String? ownerUid,
    String? customerName,
    String? customerEmail,
    String? customerContact,
    String? customerAddress,
    String? date,
    double? totalAmount,
    String? paymentStatus,
    String? paymentMethod,
    String? paymentDate,
    String? orderStatus,
    String? orderReference,
    String? paymentReference,
    String? paymentProofUrl,
    String? pickupDate,
    String? orderNotes,
  }) {
    return Sales(
      saleId: saleId ?? this.saleId,
      ownerUid: ownerUid ?? this.ownerUid,
      customerName: customerName ?? this.customerName,
      customerEmail: customerEmail ?? this.customerEmail,
      customerContact: customerContact ?? this.customerContact,
      customerAddress: customerAddress ?? this.customerAddress,
      date: date ?? this.date,
      totalAmount: totalAmount ?? this.totalAmount,
      paymentStatus: paymentStatus ?? this.paymentStatus,
      paymentMethod: paymentMethod ?? this.paymentMethod,
      paymentDate: paymentDate ?? this.paymentDate,
      orderStatus: orderStatus ?? this.orderStatus,
      orderReference: orderReference ?? this.orderReference,
      paymentReference: paymentReference ?? this.paymentReference,
      paymentProofUrl: paymentProofUrl ?? this.paymentProofUrl,
      pickupDate: pickupDate ?? this.pickupDate,
      orderNotes: orderNotes ?? this.orderNotes,
    );
  }
}
