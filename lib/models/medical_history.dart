class MedicalHistory {
  String? historyId;
  String petId; // FK to Pet.petId
  String appointmentId; // FK to Appointment.appointmentId
  String date;
  String diagnosis;
  String treatment;
  String notes;
  double? fuzzyUrgencyScore;
  String? fuzzyConcernLevel;
  String? fuzzyAssessmentDate;
  String? fuzzyAssessmentNotes;

  MedicalHistory({
    this.historyId,
    required this.petId,
    required this.appointmentId,
    required this.date,
    required this.diagnosis,
    required this.treatment,
    required this.notes,
    this.fuzzyUrgencyScore,
    this.fuzzyConcernLevel,
    this.fuzzyAssessmentDate,
    this.fuzzyAssessmentNotes,
  });

  Map<String, dynamic> toMap() {
    return {
      'historyId': historyId,
      'petId': petId,
      'appointmentId': appointmentId,
      'date': date,
      'diagnosis': diagnosis,
      'treatment': treatment,
      'notes': notes,
      'fuzzyUrgencyScore': fuzzyUrgencyScore,
      'fuzzyConcernLevel': fuzzyConcernLevel,
      'fuzzyAssessmentDate': fuzzyAssessmentDate,
      'fuzzyAssessmentNotes': fuzzyAssessmentNotes,
    };
  }

  factory MedicalHistory.fromMap(Map<String, dynamic> map) {
    return MedicalHistory(
      historyId: map['historyId'] as String?,
      petId: map['petId'] as String? ?? '',
      appointmentId: map['appointmentId'] as String? ?? '',
      date: map['date'] as String? ?? '',
      diagnosis: map['diagnosis'] as String? ?? '',
      treatment: map['treatment'] as String? ?? '',
      notes: map['notes'] as String? ?? '',
      fuzzyUrgencyScore: (map['fuzzyUrgencyScore'] as num?)?.toDouble(),
      fuzzyConcernLevel: map['fuzzyConcernLevel'] as String?,
      fuzzyAssessmentDate: map['fuzzyAssessmentDate'] as String?,
      fuzzyAssessmentNotes: map['fuzzyAssessmentNotes'] as String?,
    );
  }

  MedicalHistory copyWith({
    String? historyId,
    String? petId,
    String? appointmentId,
    String? date,
    String? diagnosis,
    String? treatment,
    String? notes,
    double? fuzzyUrgencyScore,
    String? fuzzyConcernLevel,
    String? fuzzyAssessmentDate,
    String? fuzzyAssessmentNotes,
  }) {
    return MedicalHistory(
      historyId: historyId ?? this.historyId,
      petId: petId ?? this.petId,
      appointmentId: appointmentId ?? this.appointmentId,
      date: date ?? this.date,
      diagnosis: diagnosis ?? this.diagnosis,
      treatment: treatment ?? this.treatment,
      notes: notes ?? this.notes,
      fuzzyUrgencyScore: fuzzyUrgencyScore ?? this.fuzzyUrgencyScore,
      fuzzyConcernLevel: fuzzyConcernLevel ?? this.fuzzyConcernLevel,
      fuzzyAssessmentDate: fuzzyAssessmentDate ?? this.fuzzyAssessmentDate,
      fuzzyAssessmentNotes: fuzzyAssessmentNotes ?? this.fuzzyAssessmentNotes,
    );
  }

  /// Sortable timestamp for the stored `date` string (`yyyy-MM-dd`, ISO-8601
  /// in legacy rows, or blank). Unparseable values sort as epoch so the list
  /// never crashes on dirty data.
  DateTime get recordedAt {
    final trimmed = date.trim();
    if (trimmed.isEmpty) return DateTime.fromMillisecondsSinceEpoch(0);
    final parsed = DateTime.tryParse(trimmed);
    return parsed ?? DateTime.fromMillisecondsSinceEpoch(0);
  }
}
