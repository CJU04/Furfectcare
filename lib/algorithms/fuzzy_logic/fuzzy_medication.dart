import 'membership_functions.dart';
import 'fuzzy_rule.dart';
import 'fuzzy_engine.dart';
import 'fuzzy_input.dart';

class FuzzyMedicationDosage {
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
        name: 'Body Weight',
        variableName: 'bodyWeight',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'bodyWeight',
            membershipFunction: TrapezoidalMF.create(
              name: 'Small',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 15.0,
              right: 25.0,
            ),
          ),
          FuzzySet(
            variableName: 'bodyWeight',
            membershipFunction: TriangularMF.create(
              name: 'Medium',
              minValue: 0.0,
              maxValue: 100.0,
              left: 20.0,
              peak: 40.0,
              right: 60.0,
            ),
          ),
          FuzzySet(
            variableName: 'bodyWeight',
            membershipFunction: TrapezoidalMF.create(
              name: 'Large',
              minValue: 0.0,
              maxValue: 100.0,
              left: 50.0,
              leftShoulder: 70.0,
              rightShoulder: 100.0,
              right: 100.0,
            ),
          ),
        ],
      ),
      FuzzyVariable(
        name: 'Age',
        variableName: 'age',
        minValue: 0.0,
        maxValue: 20.0,
        sets: [
          FuzzySet(
            variableName: 'age',
            membershipFunction: TrapezoidalMF.create(
              name: 'Young',
              minValue: 0.0,
              maxValue: 20.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 3.0,
              right: 5.0,
            ),
          ),
          FuzzySet(
            variableName: 'age',
            membershipFunction: TriangularMF.create(
              name: 'Adult',
              minValue: 0.0,
              maxValue: 20.0,
              left: 3.0,
              peak: 8.0,
              right: 12.0,
            ),
          ),
          FuzzySet(
            variableName: 'age',
            membershipFunction: TrapezoidalMF.create(
              name: 'Senior',
              minValue: 0.0,
              maxValue: 20.0,
              left: 10.0,
              leftShoulder: 13.0,
              rightShoulder: 20.0,
              right: 20.0,
            ),
          ),
        ],
      ),
      FuzzyVariable(
        name: 'Kidney Function',
        variableName: 'kidneyFunction',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'kidneyFunction',
            membershipFunction: TrapezoidalMF.create(
              name: 'Impaired',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 40.0,
              right: 60.0,
            ),
          ),
          FuzzySet(
            variableName: 'kidneyFunction',
            membershipFunction: TriangularMF.create(
              name: 'Normal',
              minValue: 0.0,
              maxValue: 100.0,
              left: 50.0,
              peak: 75.0,
              right: 100.0,
            ),
          ),
        ],
      ),
      FuzzyVariable(
        name: 'Liver Function',
        variableName: 'liverFunction',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'liverFunction',
            membershipFunction: TrapezoidalMF.create(
              name: 'Impaired',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 40.0,
              right: 60.0,
            ),
          ),
          FuzzySet(
            variableName: 'liverFunction',
            membershipFunction: TriangularMF.create(
              name: 'Normal',
              minValue: 0.0,
              maxValue: 100.0,
              left: 50.0,
              peak: 75.0,
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
        name: 'Dosage Adjustment',
        variableName: 'dosageAdjustment',
        minValue: 0.0,
        maxValue: 100.0,
        sets: [
          FuzzySet(
            variableName: 'dosageAdjustment',
            membershipFunction: TrapezoidalMF.create(
              name: 'Reduce 50%',
              minValue: 0.0,
              maxValue: 100.0,
              left: 0.0,
              leftShoulder: 0.0,
              rightShoulder: 15.0,
              right: 25.0,
            ),
          ),
          FuzzySet(
            variableName: 'dosageAdjustment',
            membershipFunction: TriangularMF.create(
              name: 'Reduce 25%',
              minValue: 0.0,
              maxValue: 100.0,
              left: 15.0,
              peak: 30.0,
              right: 45.0,
            ),
          ),
          FuzzySet(
            variableName: 'dosageAdjustment',
            membershipFunction: TriangularMF.create(
              name: 'Standard',
              minValue: 0.0,
              maxValue: 100.0,
              left: 40.0,
              peak: 55.0,
              right: 70.0,
            ),
          ),
          FuzzySet(
            variableName: 'dosageAdjustment',
            membershipFunction: TrapezoidalMF.create(
              name: 'Increase 25%',
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

  static List<FuzzyRule> _createRules() {
    return [
      FuzzyRule(
        id: 'M1',
        description: 'IF kidneyFunction is Impaired THEN reduce dosage by 50%',
        antecedents: [
          FuzzyCondition(variableName: 'kidneyFunction', setName: 'Impaired'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'dosageAdjustment', setName: 'Reduce 50%'),
        ],
        weight: 2.0,
      ),
      FuzzyRule(
        id: 'M2',
        description: 'IF liverFunction is Impaired THEN reduce dosage by 50%',
        antecedents: [
          FuzzyCondition(variableName: 'liverFunction', setName: 'Impaired'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'dosageAdjustment', setName: 'Reduce 50%'),
        ],
        weight: 2.0,
      ),
      FuzzyRule(
        id: 'M3',
        description:
            'IF age is Senior AND kidneyFunction is Impaired THEN reduce dosage by 50%',
        antecedents: [
          FuzzyCondition(variableName: 'age', setName: 'Senior'),
          FuzzyCondition(variableName: 'kidneyFunction', setName: 'Impaired'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'dosageAdjustment', setName: 'Reduce 50%'),
        ],
        weight: 2.5,
      ),
      FuzzyRule(
        id: 'M4',
        description:
            'IF age is Senior AND liverFunction is Normal THEN reduce dosage by 25%',
        antecedents: [
          FuzzyCondition(variableName: 'age', setName: 'Senior'),
          FuzzyCondition(variableName: 'liverFunction', setName: 'Normal'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'dosageAdjustment', setName: 'Reduce 25%'),
        ],
      ),
      FuzzyRule(
        id: 'M5',
        description:
            'IF bodyWeight is Small AND age is Young THEN increase dosage by 25%',
        antecedents: [
          FuzzyCondition(variableName: 'bodyWeight', setName: 'Small'),
          FuzzyCondition(variableName: 'age', setName: 'Young'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'dosageAdjustment', setName: 'Increase 25%'),
        ],
      ),
      FuzzyRule(
        id: 'M6',
        description:
            'IF bodyWeight is Medium AND age is Adult AND kidneyFunction is Normal THEN standard dosage',
        antecedents: [
          FuzzyCondition(variableName: 'bodyWeight', setName: 'Medium'),
          FuzzyCondition(variableName: 'age', setName: 'Adult'),
          FuzzyCondition(variableName: 'kidneyFunction', setName: 'Normal'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'dosageAdjustment', setName: 'Standard'),
        ],
      ),
      FuzzyRule(
        id: 'M7',
        description:
            'IF bodyWeight is Large AND age is Adult AND kidneyFunction is Normal THEN standard dosage',
        antecedents: [
          FuzzyCondition(variableName: 'bodyWeight', setName: 'Large'),
          FuzzyCondition(variableName: 'age', setName: 'Adult'),
          FuzzyCondition(variableName: 'kidneyFunction', setName: 'Normal'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'dosageAdjustment', setName: 'Standard'),
        ],
      ),
    ];
  }
}
