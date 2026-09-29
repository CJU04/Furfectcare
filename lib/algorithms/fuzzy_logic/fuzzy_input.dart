import 'membership_functions.dart';

class FuzzyInput {
  final String name;
  final String variableName;
  final double value;
  final double minValue;
  final double maxValue;
  final String unit;
  final String description;

  FuzzyInput({
    required this.name,
    required this.variableName,
    required this.value,
    required this.minValue,
    required this.maxValue,
    required this.unit,
    required this.description,
  });

  bool get isValid => value >= minValue && value <= maxValue;

  String get validationError {
    if (value < minValue) {
      return '$name ($value $unit) is below minimum ($minValue $unit)';
    }
    if (value > maxValue) {
      return '$name ($value $unit) exceeds maximum ($maxValue $unit)';
    }
    return '';
  }

  FuzzyInput copyWith({
    String? name,
    String? variableName,
    double? value,
    double? minValue,
    double? maxValue,
    String? unit,
    String? description,
  }) {
    return FuzzyInput(
      name: name ?? this.name,
      variableName: variableName ?? this.variableName,
      value: value ?? this.value,
      minValue: minValue ?? this.minValue,
      maxValue: maxValue ?? this.maxValue,
      unit: unit ?? this.unit,
      description: description ?? this.description,
    );
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'variableName': variableName,
        'value': value,
        'minValue': minValue,
        'maxValue': maxValue,
        'unit': unit,
        'description': description,
      };

  factory FuzzyInput.fromJson(Map<String, dynamic> json) => FuzzyInput(
        name: json['name'] as String,
        variableName: json['variableName'] as String,
        value: (json['value'] as num).toDouble(),
        minValue: (json['minValue'] as num).toDouble(),
        maxValue: (json['maxValue'] as num).toDouble(),
        unit: json['unit'] as String,
        description: json['description'] as String,
      );

  static List<FuzzyInput> getVeterinaryDefaults() {
    return [
      FuzzyInput(
        name: 'Body Temperature',
        variableName: 'temperature',
        value: 38.5,
        minValue: 35.0,
        maxValue: 42.0,
        unit: '°C',
        description: 'Rectal body temperature of the animal',
      ),
      FuzzyInput(
        name: 'Appetite Level',
        variableName: 'appetite',
        value: 50,
        minValue: 0,
        maxValue: 100,
        unit: '%',
        description: 'Percentage of normal food intake',
      ),
      FuzzyInput(
        name: 'Activity Level',
        variableName: 'activity',
        value: 50,
        minValue: 0,
        maxValue: 100,
        unit: '%',
        description: 'Percentage of normal activity/movement',
      ),
      FuzzyInput(
        name: 'Symptom Severity',
        variableName: 'symptomSeverity',
        value: 50,
        minValue: 0,
        maxValue: 100,
        unit: '%',
        description: 'Overall severity of presenting symptoms',
      ),
      FuzzyInput(
        name: 'Symptom Duration',
        variableName: 'duration',
        value: 24,
        minValue: 0,
        maxValue: 168,
        unit: 'hours',
        description: 'Time since symptoms first appeared',
      ),
    ];
  }
}

class FuzzyVariable {
  final String name;
  final String variableName;
  final double minValue;
  final double maxValue;
  final List<FuzzySet> sets;

  FuzzyVariable({
    required this.name,
    required this.variableName,
    required this.minValue,
    required this.maxValue,
    required this.sets,
  });

  FuzzySet? getSet(String setName) {
    try {
      return sets.firstWhere((s) => s.name == setName);
    } catch (_) {
      return null;
    }
  }

  Map<String, double> fuzzify(double value) {
    final result = <String, double>{};
    for (final set in sets) {
      result[set.name] = set.membership(value);
    }
    return result;
  }

  Map<String, dynamic> toJson() => {
        'name': name,
        'variableName': variableName,
        'minValue': minValue,
        'maxValue': maxValue,
        'sets': sets.map((s) => s.toJson()).toList(),
      };
}
