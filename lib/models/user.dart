class User {
  int? userid;
  String username;
  String password;
  String fullname;
  String usertype; // admin, staff, veterinarian, customer
  String contactNumber;
  String email;
  String address;
  String status;
  String? profileImagePath;

  User({
    this.userid,
    required this.username,
    required this.password,
    required this.fullname,
    required this.usertype,
    required this.contactNumber,
    required this.email,
    required this.address,
    required this.status,
    this.profileImagePath,
  });

  // Convert User object to Map for database insertion
  Map<String, dynamic> toMap() {
    return {
      'userid': userid,
      'username': username,
      'password': password,
      'fullname': fullname,
      'usertype': usertype,
      'contactNumber': contactNumber,
      'email': email,
      'address': address,
      'status': status,
      'profileImagePath': profileImagePath,
    };
  }

  // Create User object from Map (database row)
  factory User.fromMap(Map<String, dynamic> map) {
    return User(
      userid: map['userid'],
      username: map['username'],
      password: map['password'],
      fullname: map['fullname'],
      usertype: map['usertype'],
      contactNumber: map['contactNumber'],
      email: map['email'],
      address: map['address'],
      status: map['status'],
      profileImagePath: map['profileImagePath'],
    );
  }

  User copyWith({
    int? userid,
    String? username,
    String? password,
    String? fullname,
    String? usertype,
    String? contactNumber,
    String? email,
    String? address,
    String? status,
    String? profileImagePath,
  }) {
    return User(
      userid: userid ?? this.userid,
      username: username ?? this.username,
      password: password ?? this.password,
      fullname: fullname ?? this.fullname,
      usertype: usertype ?? this.usertype,
      contactNumber: contactNumber ?? this.contactNumber,
      email: email ?? this.email,
      address: address ?? this.address,
      status: status ?? this.status,
      profileImagePath: profileImagePath ?? this.profileImagePath,
    );
  }
}

class AppNotification {
  String? notificationId;
  String recipientUserId;
  String title;
  String message;
  String type; // 'order', 'appointment', 'payment', 'inventory', 'general'
  String? relatedDocumentId;
  bool isRead;
  DateTime createdAt;

  AppNotification({
    this.notificationId,
    required this.recipientUserId,
    required this.title,
    required this.message,
    required this.type,
    this.relatedDocumentId,
    this.isRead = false,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'notificationId': notificationId,
      'userId': recipientUserId, // for firestore.rules compatibility
      'recipientUserId': recipientUserId,
      'title': title,
      'message': message,
      'type': type,
      'relatedDocumentId': relatedDocumentId,
      'isRead': isRead,
      'read': isRead, // for firestore.rules compatibility
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory AppNotification.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parsedDate;
    final rawDate = map['createdAt'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return AppNotification(
      notificationId: docId ?? map['notificationId'] as String?,
      recipientUserId:
          map['recipientUserId'] as String? ?? map['userId'] as String? ?? '',
      title: map['title'] as String? ?? '',
      message: map['message'] as String? ?? '',
      type: map['type'] as String? ?? 'general',
      relatedDocumentId: map['relatedDocumentId'] as String?,
      isRead: (map['isRead'] as bool?) ?? (map['read'] as bool?) ?? false,
      createdAt: parsedDate,
    );
  }
}

class SmsLog {
  String? smsId;
  String recipientPhone;
  String message;
  String status; // 'Not Configured', 'Pending', 'Sent', 'Failed'
  DateTime createdAt;
  String provider;

  SmsLog({
    this.smsId,
    required this.recipientPhone,
    required this.message,
    required this.status,
    required this.provider,
    DateTime? createdAt,
  }) : createdAt = createdAt ?? DateTime.now();

  Map<String, dynamic> toMap() {
    return {
      'smsId': smsId,
      'recipientPhone': recipientPhone,
      'message': message,
      'status': status,
      'provider': provider,
      'createdAt': createdAt.toIso8601String(),
    };
  }

  factory SmsLog.fromMap(Map<String, dynamic> map, {String? docId}) {
    DateTime parsedDate;
    final rawDate = map['createdAt'];
    if (rawDate is String) {
      parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
    } else {
      parsedDate = DateTime.now();
    }

    return SmsLog(
      smsId: docId ?? map['smsId'] as String?,
      recipientPhone: map['recipientPhone'] as String? ?? '',
      message: map['message'] as String? ?? '',
      status: map['status'] as String? ?? 'Not Configured',
      provider: map['provider'] as String? ?? 'Semaphore / Twilio',
      createdAt: parsedDate,
    );
  }
}
