import 'membership_functions.dart';
import 'fuzzy_input.dart';
import 'fuzzy_rule.dart';
import 'fuzzy_engine.dart';
import 'fuzzy_result.dart';

class VeterinaryFuzzyLogic {
  static FuzzyEngine createEngine() {
    return FuzzyEngine(
      inputVariables: _createInputVariables(),
      outputVariables: _createOutputVariables(),
      rules: _createRules(),
    );
  }

  static List<FuzzyVariable> _createInputVariables() {
    return [
      // Temperature (°C): 35.0 - 42.0
      FuzzyVariable(
        name: 'Body Temperature',
        variableName: 'temperature',
        minValue: 35.0,
        maxValue: 42.0,
        sets: [
          FuzzySet(
            variableName: 'temperature',
            membershipFunction: TrapezoidalMF.create(
              name: 'Low',
              minValue: 35.0,
              maxValue: 42.0,
              left: 35.0,
              leftShoulder: 35.0,
              rightShoulder: 37.0,
              right: 37.5,
            ),
          ),
          FuzzySet(
            variableName: 'temperature',
            membershipFunction: TriangularMF.create(
              name: 'Normal',
              minValue: 35.0,
              maxValue: 42.0,
              left: 37.0,
              peak: 38.0,
              right: 39.0,
            ),
          ),
          FuzzySet(
            variableName: 'temperature',
            membershipFunction: TriangularMF.create(
              name: 'Elevated',
              minValue: 35.0,
              maxValue: 42.0,
              left: 38.5,
              peak: 39.5,
              right: 40.5,
            ),
          ),
          FuzzySet(
            variableName: 'temperature',
            membershipFunction: TriangularMF.create(
              name: 'High',
              minValue: 35.0,
              maxValue: 42.0,
              left: 40.0,
              peak: 41.0,
              right: 41.5,
            ),
          ),
          FuzzySet(
            variableName: 'temperature',
            membershipFunction: TrapezoidalMF.create(
              name: 'Very High',
              minValue: 35.0,
              maxValue: 42.0,
              left: 41.0,
              leftShoulder: 41.5,
              rightShoulder: 42.0,
              right: 42.0,
            ),
          ),
        ],
      ),

      // Appetite (%): 0 - 100
      FuzzyVariable(
        name: 'Appetite Level',
        variableName: 'appetite',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'appetite',
            membershipFunction: TrapezoidalMF.create(
              name: 'Poor',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 20.0,
              right: 35.0,
            ),
          ),
          FuzzySet(
            variableName: 'appetite',
            membershipFunction: TriangularMF.create(
              name: 'Fair',
              minValue: 0.0,
              maxValue: 100.0,
              left: 25.0,
              peak: 40.0,
              right: 55.0,
            ),
          ),
          FuzzySet(
            variableName: 'appetite',
            membershipFunction: TriangularMF.create(
              name: 'Normal',
              minValue: 0.0,
              maxValue: 100.0,
              left: 50.0,
              peak: 70.0,
              right: 85.0,
            ),
          ),
          FuzzySet(
            variableName: 'appetite',
            membershipFunction: TrapezoidalMF.create(
              name: 'Good',
              minValue: 0.0,
              maxValue: 100.0,
              left: 75.0,
              leftShoulder: 85.0,
              rightShoulder: 100.0,
              right: 100.0,
            ),
          ),
        ],
      ),

      // Activity Level (%): 0 - 100
      FuzzyVariable(
        name: 'Activity Level',
        variableName: 'activity',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'activity',
            membershipFunction: TrapezoidalMF.create(
              name: 'Very Low',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 15.0,
              right: 30.0,
            ),
          ),
          FuzzySet(
            variableName: 'activity',
            membershipFunction: TriangularMF.create(
              name: 'Low',
              minValue: 0.0,
              maxValue: 100.0,
              left: 20.0,
              peak: 35.0,
              right: 50.0,
            ),
          ),
          FuzzySet(
            variableName: 'activity',
            membershipFunction: TriangularMF.create(
              name: 'Normal',
              minValue: 0.0,
              maxValue: 100.0,
              left: 45.0,
              peak: 65.0,
              right: 80.0,
            ),
          ),
          FuzzySet(
            variableName: 'activity',
            membershipFunction: TrapezoidalMF.create(
              name: 'High',
              minValue: 0.0,
              maxValue: 100.0,
              left: 70.0,
              leftShoulder: 80.0,
              rightShoulder: 100.0,
              right: 100.0,
            ),
          ),
        ],
      ),

      // Symptom Severity (%): 0 - 100
      FuzzyVariable(
        name: 'Symptom Severity',
        variableName: 'symptomSeverity',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'symptomSeverity',
            membershipFunction: TrapezoidalMF.create(
              name: 'Mild',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 25.0,
              right: 40.0,
            ),
          ),
          FuzzySet(
            variableName: 'symptomSeverity',
            membershipFunction: TriangularMF.create(
              name: 'Moderate',
              minValue: 0.0,
              maxValue: 100.0,
              left: 30.0,
              peak: 50.0,
              right: 70.0,
            ),
          ),
          FuzzySet(
            variableName: 'symptomSeverity',
            membershipFunction: TrapezoidalMF.create(
              name: 'Severe',
              minValue: 0.0,
              maxValue: 100.0,
              left: 60.0,
              leftShoulder: 70.0,
              rightShoulder: 100.0,
              right: 100.0,
            ),
          ),
        ],
      ),

      // Duration (hours): 0 - 168 (1 week)
      FuzzyVariable(
        name: 'Symptom Duration',
        variableName: 'duration',
        minValue: 0.0,
        maxValue: 168.0,
        sets: [
          FuzzySet(
            variableName: 'duration',
            membershipFunction: TrapezoidalMF.create(
              name: 'Short',
              minValue: 0.0,
              maxValue: 168.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 12.0,
              right: 24.0,
            ),
          ),
          FuzzySet(
            variableName: 'duration',
            membershipFunction: TriangularMF.create(
              name: 'Moderate',
              minValue: 0.0,
              maxValue: 168.0,
              left: 18.0,
              peak: 48.0,
              right: 72.0,
            ),
          ),
          FuzzySet(
            variableName: 'duration',
            membershipFunction: TrapezoidalMF.create(
              name: 'Long',
              minValue: 0.0,
              maxValue: 168.0,
              left: 60.0,
              leftShoulder: 72.0,
              rightShoulder: 168.0,
              right: 168.0,
            ),
          ),
        ],
      ),
    ];
  }

  static List<FuzzyVariable> _createOutputVariables() {
    return [
      FuzzyVariable(
        name: 'Concern Level',
        variableName: 'concern',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'concern',
            membershipFunction: TrapezoidalMF.create(
              name: 'Low Concern',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 15.0,
              right: 30.0,
            ),
          ),
          FuzzySet(
            variableName: 'concern',
            membershipFunction: TriangularMF.create(
              name: 'Moderate Concern',
              minValue: 0.0,
              maxValue: 100.0,
              left: 20.0,
              peak: 45.0,
              right: 60.0,
            ),
          ),
          FuzzySet(
            variableName: 'concern',
            membershipFunction: TriangularMF.create(
              name: 'High Concern',
              minValue: 0.0,
              maxValue: 100.0,
              left: 50.0,
              peak: 70.0,
              right: 80.0,
            ),
          ),
          FuzzySet(
            variableName: 'concern',
            membershipFunction: TrapezoidalMF.create(
              name: 'Very High Concern',
              minValue: 0.0,
              maxValue: 100.0,
              left: 75.0,
              leftShoulder: 81.0,
              rightShoulder: 100.0,
              right: 100.0,
            ),
          ),
        ],
      ),
    ];
  }

  static List<FuzzyRule> _createRules() {
    return [
      // Rule 1: Normal vitals = Low Concern
      FuzzyRule(
        id: 'R1',
        description:
            'IF temperature is Normal AND appetite is Normal AND activity is Normal THEN concern is Low Concern',
        antecedents: [
          FuzzyCondition(variableName: 'temperature', setName: 'Normal'),
          FuzzyCondition(variableName: 'appetite', setName: 'Normal'),
          FuzzyCondition(variableName: 'activity', setName: 'Normal'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'concern', setName: 'Low Concern'),
        ],
      ),

      // Rule 2: Good appetite + normal temp + normal activity = Low Concern
      FuzzyRule(
        id: 'R2',
        description:
            'IF temperature is Normal AND appetite is Good AND activity is High THEN concern is Low Concern',
        antecedents: [
          FuzzyCondition(variableName: 'temperature', setName: 'Normal'),
          FuzzyCondition(variableName: 'appetite', setName: 'Good'),
          FuzzyCondition(variableName: 'activity', setName: 'High'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'concern', setName: 'Low Concern'),
        ],
      ),

      // Rule 3: High temp + poor appetite + low activity = High Concern
      FuzzyRule(
        id: 'R3',
        description:
            'IF temperature is High AND appetite is Poor AND activity is Low THEN concern is High Concern',
        antecedents: [
          FuzzyCondition(variableName: 'temperature', setName: 'High'),
          FuzzyCondition(variableName: 'appetite', setName: 'Poor'),
          FuzzyCondition(variableName: 'activity', setName: 'Low'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'concern', setName: 'High Concern'),
        ],
      ),

      // Rule 4: Very High temp = Very High Concern
      FuzzyRule(
        id: 'R4',
        description:
            'IF temperature is Very High THEN concern is Very High Concern',
        antecedents: [
          FuzzyCondition(variableName: 'temperature', setName: 'Very High'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'concern', setName: 'Very High Concern'),
        ],
        weight: 1.5,
      ),

      // Rule 5: Elevated temp + poor appetite = High Concern
      FuzzyRule(
        id: 'R5',
        description:
            'IF temperature is Elevated AND appetite is Poor THEN concern is High Concern',
        antecedents: [
          FuzzyCondition(variableName: 'temperature', setName: 'Elevated'),
          FuzzyCondition(variableName: 'appetite', setName: 'Poor'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'concern', setName: 'High Concern'),
        ],
      ),

      // Rule 6: Severe symptoms + long duration = Very High Concern
      FuzzyRule(
        id: 'R6',
        description:
            'IF symptomSeverity is Severe AND duration is Long THEN concern is Very High Concern',
        antecedents: [
          FuzzyCondition(variableName: 'symptomSeverity', setName: 'Severe'),
          FuzzyCondition(variableName: 'duration', setName: 'Long'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'concern', setName: 'Very High Concern'),
        ],
        weight: 15.0,
      ),

      // Rule 7: Severe symptoms = High Concern
      FuzzyRule(
        id: 'R7',
        description:
            'IF symptomSeverity is Severe THEN concern is High Concern',
        antecedents: [
          FuzzyCondition(variableName: 'symptomSeverity', setName: 'Severe'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'concern', setName: 'High Concern'),
        ],
      ),

      // Rule 8: High temp + severe symptoms = Very High Concern
      FuzzyRule(
        id: 'R8',
        description:
            'IF temperature is High AND symptomSeverity is Severe THEN concern is Very High Concern',
        antecedents: [
          FuzzyCondition(variableName: 'temperature', setName: 'High'),
          FuzzyCondition(variableName: 'symptomSeverity', setName: 'Severe'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'concern', setName: 'Very High Concern'),
        ],
        weight: 15.0,
      ),

      // Rule 9: Low temp + very low activity = High Concern
      FuzzyRule(
        id: 'R9',
        description:
            'IF temperature is Low AND activity is Very Low THEN concern is High Concern',
        antecedents: [
          FuzzyCondition(variableName: 'temperature', setName: 'Low'),
          FuzzyCondition(variableName: 'activity', setName: 'Very Low'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'concern', setName: 'High Concern'),
        ],
        weight: 12.0,
      ),

      // Rule 10: Elevated temp + moderate symptoms + moderate duration = Moderate Concern
      FuzzyRule(
        id: 'R10',
        description:
            'IF temperature is Elevated AND symptomSeverity is Moderate AND duration is Moderate THEN concern is Moderate Concern',
        antecedents: [
          FuzzyCondition(variableName: 'temperature', setName: 'Elevated'),
          FuzzyCondition(variableName: 'symptomSeverity', setName: 'Moderate'),
          FuzzyCondition(variableName: 'duration', setName: 'Moderate'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'concern', setName: 'Moderate Concern'),
        ],
      ),

      // Rule 11: Poor appetite + very low activity = High Concern
      FuzzyRule(
        id: 'R11',
        description:
            'IF appetite is Poor AND activity is Very Low THEN concern is High Concern',
        antecedents: [
          FuzzyCondition(variableName: 'appetite', setName: 'Poor'),
          FuzzyCondition(variableName: 'activity', setName: 'Very Low'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'concern', setName: 'High Concern'),
        ],
        weight: 12.0,
      ),

      // Rule 12: Normal temp + fair appetite + low activity = Moderate Concern
      FuzzyRule(
        id: 'R12',
        description:
            'IF temperature is Normal AND appetite is Fair AND activity is Low THEN concern is Moderate Concern',
        antecedents: [
          FuzzyCondition(variableName: 'temperature', setName: 'Normal'),
          FuzzyCondition(variableName: 'appetite', setName: 'Fair'),
          FuzzyCondition(variableName: 'activity', setName: 'Low'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'concern', setName: 'Moderate Concern'),
        ],
      ),

      // Rule 13: Long duration + moderate severity = Moderate Concern
      FuzzyRule(
        id: 'R13',
        description:
            'IF duration is Long AND symptomSeverity is Moderate THEN concern is Moderate Concern',
        antecedents: [
          FuzzyCondition(variableName: 'duration', setName: 'Long'),
          FuzzyCondition(variableName: 'symptomSeverity', setName: 'Moderate'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'concern', setName: 'Moderate Concern'),
        ],
      ),

      // Rule 14: Low temp = Moderate Concern (hypothermia risk)
      FuzzyRule(
        id: 'R14',
        description: 'IF temperature is Low THEN concern is Moderate Concern',
        antecedents: [
          FuzzyCondition(variableName: 'temperature', setName: 'Low'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'concern', setName: 'Moderate Concern'),
        ],
      ),

      // Rule 15: Elevated temp + good appetite + normal activity = Low Concern
      FuzzyRule(
        id: 'R15',
        description:
            'IF temperature is Elevated AND appetite is Good AND activity is Normal THEN concern is Low Concern',
        antecedents: [
          FuzzyCondition(variableName: 'temperature', setName: 'Elevated'),
          FuzzyCondition(variableName: 'appetite', setName: 'Good'),
          FuzzyCondition(variableName: 'activity', setName: 'Normal'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'concern', setName: 'Low Concern'),
        ],
      ),
    ];
  }
}

class VeterinaryAssessment {
  final FuzzyEngine _engine = VeterinaryFuzzyLogic.createEngine();

  FuzzyResult assess(List<FuzzyInput> inputs) {
    return _engine.evaluate(inputs);
  }

  FuzzyResult assessWithDefaults({
    double? temperature,
    double? appetite,
    double? activity,
    double? symptomSeverity,
    double? duration,
  }) {
    final defaults = FuzzyInput.getVeterinaryDefaults();
    final inputs = defaults.map((input) {
      switch (input.variableName) {
        case 'temperature':
          return input.copyWith(value: temperature ?? input.value);
        case 'appetite':
          return input.copyWith(value: appetite ?? input.value);
        case 'activity':
          return input.copyWith(value: activity ?? input.value);
        case 'symptomSeverity':
          return input.copyWith(value: symptomSeverity ?? input.value);
        case 'duration':
          return input.copyWith(value: duration ?? input.value);
        default:
          return input;
      }
    }).toList();

    return _engine.evaluate(inputs);
  }

  Map<String, dynamic> getEngineConfig() => _engine.toJson();
}
