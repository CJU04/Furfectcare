import 'membership_functions.dart';
import 'fuzzy_rule.dart';
import 'fuzzy_engine.dart';
import 'fuzzy_input.dart';

class FuzzyPainAssessment {
  static FuzzyEngine createEngine() {
    return FuzzyEngine(
      inputVariables: _createInputVariables(),
      outputVariables: _createOutputVariables(),
      rules: _createRules(),
    );
  }

  static List<FuzzyVariable> _createInputVariables() {
    return [
      FuzzyVariable(
        name: 'Vocalization',
        variableName: 'vocalization',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'vocalization',
            membershipFunction: TrapezoidalMF.create(
              name: 'None',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 20.0,
              right: 35.0,
            ),
          ),
          FuzzySet(
            variableName: 'vocalization',
            membershipFunction: TriangularMF.create(
              name: 'Moderate',
              minValue: 0.0,
              maxValue: 100.0,
              left: 25.0,
              peak: 50.0,
              right: 75.0,
            ),
          ),
          FuzzySet(
            variableName: 'vocalization',
            membershipFunction: TrapezoidalMF.create(
              name: 'Severe',
              minValue: 0.0,
              maxValue: 100.0,
              left: 65.0,
              leftShoulder: 80.0,
              rightShoulder: 100.0,
              right: 100.0,
            ),
          ),
        ],
      ),
      FuzzyVariable(
        name: 'Mobility',
        variableName: 'mobility',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'mobility',
            membershipFunction: TrapezoidalMF.create(
              name: 'Normal',
              minValue: 0.0,
              maxValue: 100.0,
              left: 70.0,
              leftShoulder: 85.0,
              rightShoulder: 100.0,
              right: 100.0,
            ),
          ),
          FuzzySet(
            variableName: 'mobility',
            membershipFunction: TriangularMF.create(
              name: 'Reduced',
              minValue: 0.0,
              maxValue: 100.0,
              left: 30.0,
              peak: 55.0,
              right: 80.0,
            ),
          ),
          FuzzySet(
            variableName: 'mobility',
            membershipFunction: TrapezoidalMF.create(
              name: 'Non-weight Bearing',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 25.0,
              right: 45.0,
            ),
          ),
        ],
      ),
      FuzzyVariable(
        name: 'Behavior Changes',
        variableName: 'behaviorChanges',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'behaviorChanges',
            membershipFunction: TrapezoidalMF.create(
              name: 'None',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 25.0,
              right: 40.0,
            ),
          ),
          FuzzySet(
            variableName: 'behaviorChanges',
            membershipFunction: TriangularMF.create(
              name: 'Moderate',
              minValue: 0.0,
              maxValue: 100.0,
              left: 30.0,
              peak: 55.0,
              right: 80.0,
            ),
          ),
          FuzzySet(
            variableName: 'behaviorChanges',
            membershipFunction: TrapezoidalMF.create(
              name: 'Severe',
              minValue: 0.0,
              maxValue: 100.0,
              left: 70.0,
              leftShoulder: 85.0,
              rightShoulder: 100.0,
              right: 100.0,
            ),
          ),
        ],
      ),
      FuzzyVariable(
        name: 'Palpation Response',
        variableName: 'palpationResponse',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'palpationResponse',
            membershipFunction: TrapezoidalMF.create(
              name: 'None',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 20.0,
              right: 35.0,
            ),
          ),
          FuzzySet(
            variableName: 'palpationResponse',
            membershipFunction: TriangularMF.create(
              name: 'Moderate',
              minValue: 0.0,
              maxValue: 100.0,
              left: 25.0,
              peak: 50.0,
              right: 75.0,
            ),
          ),
          FuzzySet(
            variableName: 'palpationResponse',
            membershipFunction: TrapezoidalMF.create(
              name: 'Severe',
              minValue: 0.0,
              maxValue: 100.0,
              left: 65.0,
              leftShoulder: 80.0,
              rightShoulder: 100.0,
              right: 100.0,
            ),
          ),
        ],
      ),
    ];
  }

  static List<FuzzyVariable> _createOutputVariables() {
    return [
      FuzzyVariable(
        name: 'Pain Score',
        variableName: 'painScore',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'painScore',
            membershipFunction: TrapezoidalMF.create(
              name: 'Mild',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 30.0,
              right: 45.0,
            ),
          ),
          FuzzySet(
            variableName: 'painScore',
            membershipFunction: TriangularMF.create(
              name: 'Moderate',
              minValue: 0.0,
              maxValue: 100.0,
              left: 35.0,
              peak: 55.0,
              right: 75.0,
            ),
          ),
          FuzzySet(
            variableName: 'painScore',
            membershipFunction: TrapezoidalMF.create(
              name: 'Severe',
              minValue: 0.0,
              maxValue: 100.0,
              left: 70.0,
              leftShoulder: 85.0,
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
      FuzzyRule(
        id: 'P1',
        description:
            'IF vocalization is Severe AND palpationResponse is Severe AND mobility is Non-weight Bearing THEN pain score is Severe',
        antecedents: [
          FuzzyCondition(variableName: 'vocalization', setName: 'Severe'),
          FuzzyCondition(variableName: 'palpationResponse', setName: 'Severe'),
          FuzzyCondition(
              variableName: 'mobility', setName: 'Non-weight Bearing'),
        ],
        consequents: [
          FuzzyConclusion(outputVariableName: 'painScore', setName: 'Severe'),
        ],
        weight: 2.0,
      ),
      FuzzyRule(
        id: 'P2',
        description:
            'IF behaviorChanges is Severe AND palpationResponse is Moderate AND mobility is Reduced THEN pain score is Moderate',
        antecedents: [
          FuzzyCondition(variableName: 'behaviorChanges', setName: 'Severe'),
          FuzzyCondition(
              variableName: 'palpationResponse', setName: 'Moderate'),
          FuzzyCondition(variableName: 'mobility', setName: 'Reduced'),
        ],
        consequents: [
          FuzzyConclusion(outputVariableName: 'painScore', setName: 'Moderate'),
        ],
      ),
      FuzzyRule(
        id: 'P3',
        description:
            'IF vocalization is None AND behaviorChanges is None AND mobility is Normal THEN pain score is Mild',
        antecedents: [
          FuzzyCondition(variableName: 'vocalization', setName: 'None'),
          FuzzyCondition(variableName: 'behaviorChanges', setName: 'None'),
          FuzzyCondition(variableName: 'mobility', setName: 'Normal'),
        ],
        consequents: [
          FuzzyConclusion(outputVariableName: 'painScore', setName: 'Mild'),
        ],
      ),
      FuzzyRule(
        id: 'P4',
        description: 'IF palpationResponse is Severe THEN pain score is Severe',
        antecedents: [
          FuzzyCondition(variableName: 'palpationResponse', setName: 'Severe'),
        ],
        consequents: [
          FuzzyConclusion(outputVariableName: 'painScore', setName: 'Severe'),
        ],
        weight: 1.8,
      ),
      FuzzyRule(
        id: 'P5',
        description:
            'IF vocalization is Moderate AND mobility is Reduced THEN pain score is Moderate',
        antecedents: [
          FuzzyCondition(variableName: 'vocalization', setName: 'Moderate'),
          FuzzyCondition(variableName: 'mobility', setName: 'Reduced'),
        ],
        consequents: [
          FuzzyConclusion(outputVariableName: 'painScore', setName: 'Moderate'),
        ],
      ),
    ];
  }
}
