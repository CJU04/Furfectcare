class Pet {
  String? petId;
  String ownerUid; // FK to FirebaseUser.uid
  String name;
  String type;
  String breed;
  int age;
  String gender;
  String vaccinationStatus;
  String healthNotes;
  String? imageUrl;
  String?
      vaccinationProofUrl; // proof document when vaccinationStatus is up to date

  Pet({
    this.petId,
    required this.ownerUid,
    required this.name,
    required this.type,
    required this.breed,
    required this.age,
    required this.gender,
    required this.vaccinationStatus,
    required this.healthNotes,
    this.imageUrl,
    this.vaccinationProofUrl,
  });

  Map<String, dynamic> toMap() {
    return {
      'petId': petId,
      'ownerUid': ownerUid,
      'name': name,
      'type': type,
      'breed': breed,
      'age': age,
      'gender': gender,
      'vaccination_status': vaccinationStatus,
      'healthnotes': healthNotes,
      'imageUrl': imageUrl,
      'vaccinationProofUrl': vaccinationProofUrl,
    };
  }

  factory Pet.fromMap(Map<String, dynamic> map) {
    return Pet(
      petId: map['petId'] as String?,
      ownerUid: map['ownerUid'] as String? ?? '',
      name: map['name'] as String? ?? '',
      type: map['type'] as String? ?? '',
      breed: map['breed'] as String? ?? '',
      age: map['age'] as int? ?? 0,
      gender: map['gender'] as String? ?? '',
      vaccinationStatus: map['vaccination_status'] as String? ?? '',
      healthNotes: map['healthnotes'] as String? ?? '',
      imageUrl: map['imageUrl'] as String?,
      vaccinationProofUrl: map['vaccinationProofUrl'] as String?,
    );
  }

  Pet copyWith({
    String? petId,
    String? ownerUid,
    String? name,
    String? type,
    String? breed,
    int? age,
    String? gender,
    String? vaccinationStatus,
    String? healthNotes,
    String? imageUrl,
    String? vaccinationProofUrl,
  }) {
    return Pet(
      petId: petId ?? this.petId,
      ownerUid: ownerUid ?? this.ownerUid,
      name: name ?? this.name,
      type: type ?? this.type,
      breed: breed ?? this.breed,
      age: age ?? this.age,
      gender: gender ?? this.gender,
      vaccinationStatus: vaccinationStatus ?? this.vaccinationStatus,
      healthNotes: healthNotes ?? this.healthNotes,
      imageUrl: imageUrl ?? this.imageUrl,
      vaccinationProofUrl: vaccinationProofUrl ?? this.vaccinationProofUrl,
    );
  }
}
