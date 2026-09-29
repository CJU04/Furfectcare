import 'package:flutter/material.dart';
import 'package:vetcare_connect/models/user_role.dart';
import 'package:vetcare_connect/services/firestore/user_service.dart';

class FirebaseUser {
  final String uid;
  final String name;
  final String email;
  final UserRole role;
  final bool approved;
  final String contactNumber;
  final String address;
  final String imageUrl;
  final String photoUrl;

  FirebaseUser({
    required this.uid,
    required this.name,
    required this.email,
    required this.role,
    this.approved = false,
    this.contactNumber = '',
    this.address = '',
    this.imageUrl = '',
    this.photoUrl = '',
  });

  factory FirebaseUser.fromMap(Map<String, dynamic> map) {
    final roleValue = map['role'] as String?;

    // Defensive field fallbacks for older/alternate schemas.
    final name = (map['name'] as String?) ?? (map['fullName'] as String?) ?? '';
    final photoUrl =
        (map['photoUrl'] as String?) ?? (map['photoURL'] as String?) ?? '';
    final imageUrl =
        (map['imageUrl'] as String?) ?? (map['imageURL'] as String?) ?? '';

    return FirebaseUser(
      uid: map['uid'] as String? ?? '',
      name: name,
      email: map['email'] as String? ?? '',
      role: UserRoleX.fromValue(roleValue) ?? UserRole.customer,
      approved: map['approved'] as bool? ?? false,
      contactNumber: map['contactNumber'] as String? ?? '',
      address: map['address'] as String? ?? '',
      imageUrl: imageUrl,
      photoUrl: photoUrl,
    );
  }

  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'name': name,
      'email': email,
      'role': role.value,
      'approved': approved,
      'contactNumber': contactNumber,
      'address': address,
      'imageUrl': imageUrl,
      'photoUrl': photoUrl,
    };
  }

  FirebaseUser copyWith({
    String? uid,
    String? name,
    String? email,
    UserRole? role,
    bool? approved,
    String? contactNumber,
    String? address,
    String? imageUrl,
    String? photoUrl,
  }) {
    return FirebaseUser(
      uid: uid ?? this.uid,
      name: name ?? this.name,
      email: email ?? this.email,
      role: role ?? this.role,
      approved: approved ?? this.approved,
      contactNumber: contactNumber ?? this.contactNumber,
      address: address ?? this.address,
      imageUrl: imageUrl ?? this.imageUrl,
      photoUrl: photoUrl ?? this.photoUrl,
    );
  }

  String get fullname => name;
  String get usertype => role.value;
}

class FirebaseUserProvider with ChangeNotifier {
  final UserService _userService;

  FirebaseUserProvider({UserService? userService})
      : _userService = userService ?? UserService();

  List<FirebaseUser> _users = [];
  FirebaseUser? _currentUser;

  List<FirebaseUser> get users => _users;
  FirebaseUser? get currentUser => _currentUser;

  Future<void> loadUsers() async {
    try {
      final maps = await _userService.getAllUsers();
      debugPrint(
          'FirebaseUserProvider.loadUsers(): fetched ${maps.length} docs from /users');
      _users = maps.map((map) => FirebaseUser.fromMap(map)).toList();
      debugPrint(
          'FirebaseUserProvider.loadUsers(): mapped to ${_users.length} FirebaseUser objects');
      notifyListeners();
    } catch (e, st) {
      debugPrint('FirebaseUserProvider.loadUsers() failed: $e');
      debugPrintStack(stackTrace: st);
      rethrow;
    }
  }

  Future<void> syncCurrentFirebaseUser(String uid) async {
    _currentUser = await getUserByUid(uid);
    notifyListeners();
  }

  Future<FirebaseUser?> getUserByUid(String uid) async {
    final doc = await _userService.users.doc(uid).get();
    if (!doc.exists || doc.data() == null) return null;
    return FirebaseUser.fromMap(doc.data()!);
  }

  Future<void> addUser({
    required String uid,
    required String name,
    required String email,
    required UserRole role,
    String? contactNumber,
    String? address,
  }) async {
    await _userService.createUserProfile(
      uid: uid,
      name: name,
      email: email,
      role: role,
      contactNumber: contactNumber,
      address: address,
    );
    await loadUsers();
  }

  Future<void> updateUser(FirebaseUser user) async {
    await _userService.updateUser(
      uid: user.uid,
      name: user.name,
      email: user.email,
      role: user.role,
      approved: user.approved,
      contactNumber: user.contactNumber,
      address: user.address,
      imageUrl: user.imageUrl,
      photoUrl: user.photoUrl,
    );
    await loadUsers();
    try {
      _currentUser = _users.firstWhere((u) => u.uid == user.uid);
    } on StateError {
      _currentUser = user;
    }
    notifyListeners();
  }

  Future<void> deleteUser(String uid) async {
    await _userService.deleteUser(uid);
    await loadUsers();
  }

  void setCurrentUser(FirebaseUser? user) {
    _currentUser = user;
    notifyListeners();
  }
}
