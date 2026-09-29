import 'membership_functions.dart';
import 'fuzzy_rule.dart';
import 'fuzzy_engine.dart';
import 'fuzzy_input.dart';

class FuzzyVaccinationTiming {
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
        name: 'Age (weeks)',
        variableName: 'ageWeeks',
        minValue: 0.0,
        maxValue: 520.0,
        sets: [
          FuzzySet(
            variableName: 'ageWeeks',
            membershipFunction: TrapezoidalMF.create(
              name: 'Neonatal',
              minValue: 0.0,
              maxValue: 520.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 8.0,
              right: 12.0,
            ),
          ),
          FuzzySet(
            variableName: 'ageWeeks',
            membershipFunction: TriangularMF.create(
              name: 'Juvenile',
              minValue: 0.0,
              maxValue: 520.0,
              left: 8.0,
              peak: 26.0,
              right: 52.0,
            ),
          ),
          FuzzySet(
            variableName: 'ageWeeks',
            membershipFunction: TriangularMF.create(
              name: 'Adult',
              minValue: 0.0,
              maxValue: 520.0,
              left: 40.0,
              peak: 156.0,
              right: 312.0,
            ),
          ),
          FuzzySet(
            variableName: 'ageWeeks',
            membershipFunction: TrapezoidalMF.create(
              name: 'Senior',
              minValue: 0.0,
              maxValue: 520.0,
              left: 312.0,
              leftShoulder: 390.0,
              rightShoulder: 520.0,
              right: 520.0,
            ),
          ),
        ],
      ),
      FuzzyVariable(
        name: 'Exposure Risk',
        variableName: 'exposureRisk',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'exposureRisk',
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
            variableName: 'exposureRisk',
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
            variableName: 'exposureRisk',
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
        name: 'Previous Vaccination',
        variableName: 'previousVaccination',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'previousVaccination',
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
            variableName: 'previousVaccination',
            membershipFunction: TriangularMF.create(
              name: 'Partial',
              minValue: 0.0,
              maxValue: 100.0,
              left: 25.0,
              peak: 50.0,
              right: 75.0,
            ),
          ),
          FuzzySet(
            variableName: 'previousVaccination',
            membershipFunction: TrapezoidalMF.create(
              name: 'Complete',
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
        name: 'Geographic Risk',
        variableName: 'geographicRisk',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'geographicRisk',
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
            variableName: 'geographicRisk',
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
            variableName: 'geographicRisk',
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
    ];
  }

  static List<FuzzyVariable> _createOutputVariables() {
    return [
      FuzzyVariable(
        name: 'Vaccination Urgency',
        variableName: 'vaccinationUrgency',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'vaccinationUrgency',
            membershipFunction: TrapezoidalMF.create(
              name: 'Defer',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 20.0,
              right: 35.0,
            ),
          ),
          FuzzySet(
            variableName: 'vaccinationUrgency',
            membershipFunction: TriangularMF.create(
              name: 'Routine',
              minValue: 0.0,
              maxValue: 100.0,
              left: 30.0,
              peak: 50.0,
              right: 70.0,
            ),
          ),
          FuzzySet(
            variableName: 'vaccinationUrgency',
            membershipFunction: TriangularMF.create(
              name: 'Urgent',
              minValue: 0.0,
              maxValue: 100.0,
              left: 60.0,
              peak: 78.0,
              right: 90.0,
            ),
          ),
          FuzzySet(
            variableName: 'vaccinationUrgency',
            membershipFunction: TrapezoidalMF.create(
              name: 'Immediate',
              minValue: 0.0,
              maxValue: 100.0,
              left: 85.0,
              leftShoulder: 92.0,
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
        id: 'V1',
        description:
            'IF exposureRisk is High AND geographicRisk is High AND previousVaccination is None THEN vaccination is Immediate',
        antecedents: [
          FuzzyCondition(variableName: 'exposureRisk', setName: 'High'),
          FuzzyCondition(variableName: 'geographicRisk', setName: 'High'),
          FuzzyCondition(variableName: 'previousVaccination', setName: 'None'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'vaccinationUrgency', setName: 'Immediate'),
        ],
        weight: 2.0,
      ),
      FuzzyRule(
        id: 'V2',
        description:
            'IF ageWeeks is Neonatal AND previousVaccination is None THEN vaccination is Urgent',
        antecedents: [
          FuzzyCondition(variableName: 'ageWeeks', setName: 'Neonatal'),
          FuzzyCondition(variableName: 'previousVaccination', setName: 'None'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'vaccinationUrgency', setName: 'Urgent'),
        ],
      ),
      FuzzyRule(
        id: 'V3',
        description:
            'IF exposureRisk is Moderate AND previousVaccination is Partial THEN vaccination is Routine',
        antecedents: [
          FuzzyCondition(variableName: 'exposureRisk', setName: 'Moderate'),
          FuzzyCondition(
              variableName: 'previousVaccination', setName: 'Partial'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'vaccinationUrgency', setName: 'Routine'),
        ],
      ),
      FuzzyRule(
        id: 'V4',
        description:
            'IF previousVaccination is Complete AND exposureRisk is Low THEN defer vaccination',
        antecedents: [
          FuzzyCondition(
              variableName: 'previousVaccination', setName: 'Complete'),
          FuzzyCondition(variableName: 'exposureRisk', setName: 'Low'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'vaccinationUrgency', setName: 'Defer'),
        ],
      ),
      FuzzyRule(
        id: 'V5',
        description:
            'IF ageWeeks is Senior AND previousVaccination is Complete THEN defer vaccination',
        antecedents: [
          FuzzyCondition(variableName: 'ageWeeks', setName: 'Senior'),
          FuzzyCondition(
              variableName: 'previousVaccination', setName: 'Complete'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'vaccinationUrgency', setName: 'Defer'),
        ],
      ),
      FuzzyRule(
        id: 'V6',
        description:
            'IF ageWeeks is Juvenile AND exposureRisk is High THEN vaccination is Urgent',
        antecedents: [
          FuzzyCondition(variableName: 'ageWeeks', setName: 'Juvenile'),
          FuzzyCondition(variableName: 'exposureRisk', setName: 'High'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'vaccinationUrgency', setName: 'Urgent'),
        ],
      ),
      FuzzyRule(
        id: 'V7',
        description:
            'IF geographicRisk is High AND previousVaccination is Partial THEN vaccination is Urgent',
        antecedents: [
          FuzzyCondition(variableName: 'geographicRisk', setName: 'High'),
          FuzzyCondition(
              variableName: 'previousVaccination', setName: 'Partial'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'vaccinationUrgency', setName: 'Urgent'),
        ],
      ),
    ];
  }
}
