import 'membership_functions.dart';
import 'fuzzy_rule.dart';
import 'fuzzy_engine.dart';
import 'fuzzy_input.dart';

class FuzzySurgeryRisk {
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
        name: 'ASA Status',
        variableName: 'asaStatus',
        minValue: 1.0,
        maxValue: 5.0,
        sets: [
          FuzzySet(
            variableName: 'asaStatus',
            membershipFunction: TrapezoidalMF.create(
              name: 'Low',
              minValue: 1.0,
              maxValue: 5.0,
              left: 1.0,
              leftShoulder: 1.0,
              rightShoulder: 2.0,
              right: 3.0,
            ),
          ),
          FuzzySet(
            variableName: 'asaStatus',
            membershipFunction: TriangularMF.create(
              name: 'Moderate',
              minValue: 1.0,
              maxValue: 5.0,
              left: 2.0,
              peak: 3.0,
              right: 4.0,
            ),
          ),
          FuzzySet(
            variableName: 'asaStatus',
            membershipFunction: TrapezoidalMF.create(
              name: 'High',
              minValue: 1.0,
              maxValue: 5.0,
              left: 3.5,
              leftShoulder: 4.5,
              rightShoulder: 5.0,
              right: 5.0,
            ),
          ),
        ],
      ),
      FuzzyVariable(
        name: 'Anesthesia Risk',
        variableName: 'anesthesiaRisk',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'anesthesiaRisk',
            membershipFunction: TrapezoidalMF.create(
              name: 'Low',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 30.0,
              right: 45.0,
            ),
          ),
          FuzzySet(
            variableName: 'anesthesiaRisk',
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
            variableName: 'anesthesiaRisk',
            membershipFunction: TrapezoidalMF.create(
              name: 'High',
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
        name: 'Surgical Complexity',
        variableName: 'surgicalComplexity',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'surgicalComplexity',
            membershipFunction: TrapezoidalMF.create(
              name: 'Minor',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 30.0,
              right: 45.0,
            ),
          ),
          FuzzySet(
            variableName: 'surgicalComplexity',
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
            variableName: 'surgicalComplexity',
            membershipFunction: TrapezoidalMF.create(
              name: 'Major',
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
        name: 'Preanesthetic Health',
        variableName: 'preanestheticHealth',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'preanestheticHealth',
            membershipFunction: TrapezoidalMF.create(
              name: 'Poor',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 35.0,
              right: 50.0,
            ),
          ),
          FuzzySet(
            variableName: 'preanestheticHealth',
            membershipFunction: TriangularMF.create(
              name: 'Fair',
              minValue: 0.0,
              maxValue: 100.0,
              left: 40.0,
              peak: 60.0,
              right: 80.0,
            ),
          ),
          FuzzySet(
            variableName: 'preanestheticHealth',
            membershipFunction: TrapezoidalMF.create(
              name: 'Good',
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

  static List<FuzzyVariable> _createOutputVariables() {
    return [
      FuzzyVariable(
        name: 'Surgical Risk',
        variableName: 'surgicalRisk',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'surgicalRisk',
            membershipFunction: TrapezoidalMF.create(
              name: 'Minimal',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 20.0,
              right: 35.0,
            ),
          ),
          FuzzySet(
            variableName: 'surgicalRisk',
            membershipFunction: TriangularMF.create(
              name: 'Moderate',
              minValue: 0.0,
              maxValue: 100.0,
              left: 25.0,
              peak: 45.0,
              right: 65.0,
            ),
          ),
          FuzzySet(
            variableName: 'surgicalRisk',
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
            variableName: 'surgicalRisk',
            membershipFunction: TrapezoidalMF.create(
              name: 'Very High',
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
        id: 'SR1',
        description:
            'IF preanestheticHealth is Good AND asaStatus is Low AND anesthesiaRisk is Low AND surgicalComplexity is Minor THEN surgical risk is Minimal',
        antecedents: [
          FuzzyCondition(variableName: 'preanestheticHealth', setName: 'Good'),
          FuzzyCondition(variableName: 'asaStatus', setName: 'Low'),
          FuzzyCondition(variableName: 'anesthesiaRisk', setName: 'Low'),
          FuzzyCondition(variableName: 'surgicalComplexity', setName: 'Minor'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'surgicalRisk', setName: 'Minimal'),
        ],
      ),
      FuzzyRule(
        id: 'SR2',
        description:
            'IF asaStatus is High AND anesthesiaRisk is High THEN surgical risk is Very High',
        antecedents: [
          FuzzyCondition(variableName: 'asaStatus', setName: 'High'),
          FuzzyCondition(variableName: 'anesthesiaRisk', setName: 'High'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'surgicalRisk', setName: 'Very High'),
        ],
        weight: 2.0,
      ),
      FuzzyRule(
        id: 'SR3',
        description:
            'IF surgicalComplexity is Major AND asaStatus is Moderate THEN surgical risk is High',
        antecedents: [
          FuzzyCondition(variableName: 'surgicalComplexity', setName: 'Major'),
          FuzzyCondition(variableName: 'asaStatus', setName: 'Moderate'),
        ],
        consequents: [
          FuzzyConclusion(outputVariableName: 'surgicalRisk', setName: 'High'),
        ],
      ),
      FuzzyRule(
        id: 'SR4',
        description:
            'IF preanestheticHealth is Poor AND anesthesiaRisk is Moderate THEN surgical risk is High',
        antecedents: [
          FuzzyCondition(variableName: 'preanestheticHealth', setName: 'Poor'),
          FuzzyCondition(variableName: 'anesthesiaRisk', setName: 'Moderate'),
        ],
        consequents: [
          FuzzyConclusion(outputVariableName: 'surgicalRisk', setName: 'High'),
        ],
      ),
      FuzzyRule(
        id: 'SR5',
        description:
            'IF preanestheticHealth is Fair AND asaStatus is Moderate AND anesthesiaRisk is Low AND surgicalComplexity is Moderate THEN surgical risk is Moderate',
        antecedents: [
          FuzzyCondition(variableName: 'preanestheticHealth', setName: 'Fair'),
          FuzzyCondition(variableName: 'asaStatus', setName: 'Moderate'),
          FuzzyCondition(variableName: 'anesthesiaRisk', setName: 'Low'),
          FuzzyCondition(
              variableName: 'surgicalComplexity', setName: 'Moderate'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'surgicalRisk', setName: 'Moderate'),
        ],
      ),
      FuzzyRule(
        id: 'SR6',
        description:
            'IF preanestheticHealth is Good AND surgicalComplexity is Minor THEN surgical risk is Minimal',
        antecedents: [
          FuzzyCondition(variableName: 'preanestheticHealth', setName: 'Good'),
          FuzzyCondition(variableName: 'surgicalComplexity', setName: 'Minor'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'surgicalRisk', setName: 'Minimal'),
        ],
      ),
    ];
  }
}
