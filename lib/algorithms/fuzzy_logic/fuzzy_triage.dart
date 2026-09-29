import 'membership_functions.dart';
import 'fuzzy_rule.dart';
import 'fuzzy_engine.dart';
import 'fuzzy_input.dart';

class FuzzyTriagePriority {
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
        name: ' consciousness Level',
        variableName: 'consciousness',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'consciousness',
            membershipFunction: TrapezoidalMF.create(
              name: 'Unresponsive',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 20.0,
              right: 40.0,
            ),
          ),
          FuzzySet(
            variableName: 'consciousness',
            membershipFunction: TriangularMF.create(
              name: 'Depressed',
              minValue: 0.0,
              maxValue: 100.0,
              left: 30.0,
              peak: 50.0,
              right: 70.0,
            ),
          ),
          FuzzySet(
            variableName: 'consciousness',
            membershipFunction: TrapezoidalMF.create(
              name: 'Alert',
              minValue: 0.0,
              maxValue: 100.0,
              left: 60.0,
              leftShoulder: 80.0,
              rightShoulder: 100.0,
              right: 100.0,
            ),
          ),
        ],
      ),
      FuzzyVariable(
        name: 'Respiratory Distress',
        variableName: 'respiratoryDistress',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'respiratoryDistress',
            membershipFunction: TrapezoidalMF.create(
              name: 'None',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 20.0,
              right: 40.0,
            ),
          ),
          FuzzySet(
            variableName: 'respiratoryDistress',
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
            variableName: 'respiratoryDistress',
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
        name: 'Cardiovascular Stability',
        variableName: 'cardiovascular',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'cardiovascular',
            membershipFunction: TrapezoidalMF.create(
              name: 'Unstable',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 30.0,
              right: 50.0,
            ),
          ),
          FuzzySet(
            variableName: 'cardiovascular',
            membershipFunction: TriangularMF.create(
              name: 'Borderline',
              minValue: 0.0,
              maxValue: 100.0,
              left: 35.0,
              peak: 55.0,
              right: 75.0,
            ),
          ),
          FuzzySet(
            variableName: 'cardiovascular',
            membershipFunction: TrapezoidalMF.create(
              name: 'Stable',
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
        name: 'Pain Level',
        variableName: 'painLevel',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'painLevel',
            membershipFunction: TrapezoidalMF.create(
              name: 'Mild',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 30.0,
              right: 50.0,
            ),
          ),
          FuzzySet(
            variableName: 'painLevel',
            membershipFunction: TriangularMF.create(
              name: 'Moderate',
              minValue: 0.0,
              maxValue: 100.0,
              left: 35.0,
              peak: 60.0,
              right: 85.0,
            ),
          ),
          FuzzySet(
            variableName: 'painLevel',
            membershipFunction: TrapezoidalMF.create(
              name: 'Severe',
              minValue: 0.0,
              maxValue: 100.0,
              left: 75.0,
              leftShoulder: 90.0,
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
        name: 'Triage Priority',
        variableName: 'triagePriority',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'triagePriority',
            membershipFunction: TrapezoidalMF.create(
              name: 'Low',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 25.0,
              right: 40.0,
            ),
          ),
          FuzzySet(
            variableName: 'triagePriority',
            membershipFunction: TriangularMF.create(
              name: 'Medium',
              minValue: 0.0,
              maxValue: 100.0,
              left: 30.0,
              peak: 50.0,
              right: 70.0,
            ),
          ),
          FuzzySet(
            variableName: 'triagePriority',
            membershipFunction: TriangularMF.create(
              name: 'High',
              minValue: 0.0,
              maxValue: 100.0,
              left: 55.0,
              peak: 75.0,
              right: 90.0,
            ),
          ),
          FuzzySet(
            variableName: 'triagePriority',
            membershipFunction: TrapezoidalMF.create(
              name: 'Critical',
              minValue: 0.0,
              maxValue: 100.0,
              left: 80.0,
              leftShoulder: 90.0,
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
        id: 'T1',
        description:
            'IF consciousness is Unresponsive OR cardiovascular is Unstable THEN triage is Critical',
        antecedents: [
          FuzzyCondition(
              variableName: 'consciousness', setName: 'Unresponsive'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'triagePriority', setName: 'Critical'),
        ],
        weight: 2.0,
      ),
      FuzzyRule(
        id: 'T2',
        description: 'IF respiratoryDistress is Severe THEN triage is Critical',
        antecedents: [
          FuzzyCondition(
              variableName: 'respiratoryDistress', setName: 'Severe'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'triagePriority', setName: 'Critical'),
        ],
        weight: 2.0,
      ),
      FuzzyRule(
        id: 'T3',
        description:
            'IF painLevel is Severe AND cardiovascular is Borderline THEN triage is High',
        antecedents: [
          FuzzyCondition(variableName: 'painLevel', setName: 'Severe'),
          FuzzyCondition(variableName: 'cardiovascular', setName: 'Borderline'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'triagePriority', setName: 'High'),
        ],
      ),
      FuzzyRule(
        id: 'T4',
        description:
            'IF consciousness is Depressed AND respiratoryDistress is Moderate THEN triage is High',
        antecedents: [
          FuzzyCondition(variableName: 'consciousness', setName: 'Depressed'),
          FuzzyCondition(
              variableName: 'respiratoryDistress', setName: 'Moderate'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'triagePriority', setName: 'High'),
        ],
      ),
      FuzzyRule(
        id: 'T5',
        description:
            'IF painLevel is Moderate AND cardiovascular is Borderline THEN triage is Medium',
        antecedents: [
          FuzzyCondition(variableName: 'painLevel', setName: 'Moderate'),
          FuzzyCondition(variableName: 'cardiovascular', setName: 'Borderline'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'triagePriority', setName: 'Medium'),
        ],
      ),
      FuzzyRule(
        id: 'T6',
        description:
            'IF consciousness is Alert AND cardiovascular is Stable AND painLevel is Mild THEN triage is Low',
        antecedents: [
          FuzzyCondition(variableName: 'consciousness', setName: 'Alert'),
          FuzzyCondition(variableName: 'cardiovascular', setName: 'Stable'),
          FuzzyCondition(variableName: 'painLevel', setName: 'Mild'),
        ],
        consequents: [
          FuzzyConclusion(outputVariableName: 'triagePriority', setName: 'Low'),
        ],
      ),
      FuzzyRule(
        id: 'T7',
        description:
            'IF respiratoryDistress is Moderate AND consciousness is Depressed THEN triage is Medium',
        antecedents: [
          FuzzyCondition(
              variableName: 'respiratoryDistress', setName: 'Moderate'),
          FuzzyCondition(variableName: 'consciousness', setName: 'Depressed'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'triagePriority', setName: 'Medium'),
        ],
      ),
      FuzzyRule(
        id: 'T8',
        description: 'IF cardiovascular is Unstable THEN triage is High',
        antecedents: [
          FuzzyCondition(variableName: 'cardiovascular', setName: 'Unstable'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'triagePriority', setName: 'High'),
        ],
        weight: 1.5,
      ),
    ];
  }
}
