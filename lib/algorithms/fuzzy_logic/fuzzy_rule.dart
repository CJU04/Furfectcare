import 'dart:math' as math;

class FuzzyRule {
  final String id;
  final String description;
  final List<FuzzyCondition> antecedents;
  final List<FuzzyConclusion> consequents;
  final double weight;

  FuzzyRule({
    required this.id,
    required this.description,
    required this.antecedents,
    required this.consequents,
    this.weight = 1.0,
  });

  double evaluate(Map<String, Map<String, double>> fuzzifiedInputs) {
    if (antecedents.isEmpty) return 0.0;

    double minActivation = 1.0;
    for (final condition in antecedents) {
      final variableFuzzified = fuzzifiedInputs[condition.variableName];
      if (variableFuzzified == null) {
        return 0.0;
      }
      final membership = variableFuzzified[condition.setName] ?? 0.0;
      minActivation = math.min(minActivation, membership);
    }
    return minActivation * weight;
  }

  Map<String, dynamic> toJson() => {
        'id': id,
        'description': description,
        'antecedents': antecedents.map((c) => c.toJson()).toList(),
        'consequents': consequents.map((c) => c.toJson()).toList(),
        'weight': weight,
      };

  factory FuzzyRule.fromJson(Map<String, dynamic> json) => FuzzyRule(
        id: json['id'] as String,
        description: json['description'] as String,
        antecedents: (json['antecedents'] as List)
            .map((c) => FuzzyCondition.fromJson(c))
            .toList(),
        consequents: (json['consequents'] as List)
            .map((c) => FuzzyConclusion.fromJson(c))
            .toList(),
        weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      );
}

class FuzzyCondition {
  final String variableName;
  final String setName;
  final FuzzyOperator operator;

  FuzzyCondition({
    required this.variableName,
    required this.setName,
    this.operator = FuzzyOperator.and,
  });

  Map<String, dynamic> toJson() => {
        'variableName': variableName,
        'setName': setName,
        'operator': operator.name,
      };

  factory FuzzyCondition.fromJson(Map<String, dynamic> json) => FuzzyCondition(
        variableName: json['variableName'] as String,
        setName: json['setName'] as String,
        operator: FuzzyOperator.values.firstWhere(
          (o) => o.name == json['operator'],
          orElse: () => FuzzyOperator.and,
        ),
      );
}

class FuzzyConclusion {
  final String outputVariableName;
  final String setName;
  final double weight;

  FuzzyConclusion({
    required this.outputVariableName,
    required this.setName,
    this.weight = 1.0,
  });

  Map<String, dynamic> toJson() => {
        'outputVariableName': outputVariableName,
        'setName': setName,
        'weight': weight,
      };

  factory FuzzyConclusion.fromJson(Map<String, dynamic> json) =>
      FuzzyConclusion(
        outputVariableName: json['outputVariableName'] as String,
        setName: json['setName'] as String,
        weight: (json['weight'] as num?)?.toDouble() ?? 1.0,
      );
}

enum FuzzyOperator { and, or }
