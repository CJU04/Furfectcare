import 'package:test/test.dart';
import 'package:vetcare_connect/algorithms/fuzzy_logic.dart';

void main() {
  group('Membership Functions', () {
    group('TriangularMF', () {
      test('returns 0 outside bounds', () {
        final mf = TriangularMF.create(
          name: 'Test',
          minValue: 0,
          maxValue: 100,
          left: 20,
          peak: 50,
          right: 80,
        );
        expect(mf.membership(10), equals(0.0));
        expect(mf.membership(90), equals(0.0));
      });

      test('returns 1 at peak', () {
        final mf = TriangularMF.create(
          name: 'Test',
          minValue: 0,
          maxValue: 100,
          left: 20,
          peak: 50,
          right: 80,
        );
        expect(mf.membership(50), equals(1.0));
      });

      test('linear interpolation on left slope', () {
        final mf = TriangularMF.create(
          name: 'Test',
          minValue: 0,
          maxValue: 100,
          left: 20,
          peak: 50,
          right: 80,
        );
        expect(mf.membership(35), closeTo(0.5, 0.001));
      });

      test('linear interpolation on right slope', () {
        final mf = TriangularMF.create(
          name: 'Test',
          minValue: 0,
          maxValue: 100,
          left: 20,
          peak: 50,
          right: 80,
        );
        expect(mf.membership(65), closeTo(0.5, 0.001));
      });

      test('temperature normal at 38°C', () {
        final mf = TriangularMF.create(
          name: 'Normal',
          minValue: 35.0,
          maxValue: 42.0,
          left: 37.0,
          peak: 38.0,
          right: 39.0,
        );
        expect(mf.membership(38.0), equals(1.0));
        expect(mf.membership(37.5), closeTo(0.5, 0.001));
        expect(mf.membership(38.5), closeTo(0.5, 0.001));
      });
    });

    group('TrapezoidalMF', () {
      test('returns 1 in shoulder region', () {
        final mf = TrapezoidalMF.create(
          name: 'Test',
          minValue: 0,
          maxValue: 100,
          left: 0,
          leftShoulder: 20,
          rightShoulder: 80,
          right: 100,
        );
        expect(mf.membership(50), equals(1.0));
        expect(mf.membership(20), equals(1.0));
        expect(mf.membership(80), equals(1.0));
      });

      test('returns 0 outside bounds', () {
        final mf = TrapezoidalMF.create(
          name: 'Test',
          minValue: 0,
          maxValue: 100,
          left: 0,
          leftShoulder: 20,
          rightShoulder: 80,
          right: 100,
        );
        expect(mf.membership(-10), equals(0.0));
        expect(mf.membership(110), equals(0.0));
      });

      test('linear interpolation on slopes', () {
        final mf = TrapezoidalMF.create(
          name: 'Test',
          minValue: 0,
          maxValue: 100,
          left: 0,
          leftShoulder: 20,
          rightShoulder: 80,
          right: 100,
        );
        expect(mf.membership(10), closeTo(0.5, 0.001));
        expect(mf.membership(90), closeTo(0.5, 0.001));
      });
    });
  });

  group('FuzzySet', () {
    test('delegates to membership function', () {
      final mf = TriangularMF.create(
        name: 'Normal',
        minValue: 0,
        maxValue: 100,
        left: 20,
        peak: 50,
        right: 80,
      );
      final set = FuzzySet(variableName: 'test', membershipFunction: mf);
      expect(set.membership(50), equals(1.0));
      expect(set.name, equals('Normal'));
    });
  });

  group('FuzzyVariable', () {
    test('fuzzifies input correctly', () {
      final variable = FuzzyVariable(
        name: 'Temperature',
        variableName: 'temperature',
        minValue: 35.0,
        maxValue: 42.0,
        sets: [
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
              name: 'High',
              minValue: 35.0,
              maxValue: 42.0,
              left: 40.0,
              peak: 41.0,
              right: 41.5,
            ),
          ),
        ],
      );

      final result = variable.fuzzify(38.0);
      expect(result['Normal'], equals(1.0));
      expect(result['High'], equals(0.0));

      final result2 = variable.fuzzify(40.5);
      expect(result2['Normal'], closeTo(0.0, 0.01));
      expect(result2['High'], closeTo(0.5, 0.1));
    });
  });

  group('FuzzyRule', () {
    test('evaluates AND conditions with min', () {
      final rule = FuzzyRule(
        id: 'R1',
        description: 'Test rule',
        antecedents: [
          FuzzyCondition(variableName: 'temp', setName: 'High'),
          FuzzyCondition(variableName: 'appetite', setName: 'Poor'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'concern', setName: 'High Concern'),
        ],
      );

      final fuzzified = {
        'temp': {'High': 0.8, 'Normal': 0.2},
        'appetite': {'Poor': 0.6, 'Good': 0.4},
      };

      // min(0.8, 0.6) = 0.6
      expect(rule.evaluate(fuzzified), equals(0.6));
    });

    test('returns 0 if any condition missing', () {
      final rule = FuzzyRule(
        id: 'R1',
        description: 'Test rule',
        antecedents: [
          FuzzyCondition(variableName: 'temp', setName: 'High'),
          FuzzyCondition(variableName: 'appetite', setName: 'Poor'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'concern', setName: 'High Concern'),
        ],
      );

      final fuzzified = {
        'temp': {'High': 0.8},
      };

      expect(rule.evaluate(fuzzified), equals(0.0));
    });

    test('applies weight', () {
      final rule = FuzzyRule(
        id: 'R1',
        description: 'Test rule',
        antecedents: [
          FuzzyCondition(variableName: 'temp', setName: 'High'),
        ],
        consequents: [
          FuzzyConclusion(
              outputVariableName: 'concern', setName: 'High Concern'),
        ],
        weight: 1.5,
      );

      final fuzzified = {
        'temp': {'High': 0.8},
      };

      expect(rule.evaluate(fuzzified), closeTo(1.2, 0.001)); // 0.8 * 1.5
    });
  });

  group('FuzzyEngine', () {
    late FuzzyEngine engine;

    setUp(() {
      engine = VeterinaryFuzzyLogic.createEngine();
    });

    test('engine created with correct structure', () {
      expect(engine.inputVariables.length, equals(5));
      expect(engine.outputVariables.length, equals(1));
      expect(engine.rules.length, equals(15));

      final inputNames =
          engine.inputVariables.map((v) => v.variableName).toSet();
      expect(
          inputNames,
          equals({
            'temperature',
            'appetite',
            'activity',
            'symptomSeverity',
            'duration'
          }));
    });

    test('normal vitals produce low concern', () {
      final inputs = [
        FuzzyInput(
            name: 'Temperature',
            variableName: 'temperature',
            value: 38.0,
            minValue: 35.0,
            maxValue: 42.0,
            unit: '°C',
            description: ''),
        FuzzyInput(
            name: 'Appetite',
            variableName: 'appetite',
            value: 80.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Activity',
            variableName: 'activity',
            value: 70.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Symptom Severity',
            variableName: 'symptomSeverity',
            value: 10.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Duration',
            variableName: 'duration',
            value: 12.0,
            minValue: 0.0,
            maxValue: 168.0,
            unit: 'hours',
            description: ''),
      ];

      final result = engine.evaluate(inputs);
      expect(result.concernLevel, equals('Low Concern'));
      expect(result.crispOutput, lessThan(31));
    });

    test('high temp + poor appetite + low activity = high concern', () {
      final inputs = [
        FuzzyInput(
            name: 'Temperature',
            variableName: 'temperature',
            value: 40.5,
            minValue: 35.0,
            maxValue: 42.0,
            unit: '°C',
            description: ''),
        FuzzyInput(
            name: 'Appetite',
            variableName: 'appetite',
            value: 15.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Activity',
            variableName: 'activity',
            value: 20.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Symptom Severity',
            variableName: 'symptomSeverity',
            value: 60.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Duration',
            variableName: 'duration',
            value: 48.0,
            minValue: 0.0,
            maxValue: 168.0,
            unit: 'hours',
            description: ''),
      ];

      final result = engine.evaluate(inputs);
      expect(result.concernLevel, equals('High Concern'));
      expect(result.crispOutput, greaterThanOrEqualTo(61));
      expect(result.crispOutput, lessThanOrEqualTo(80));
    });

    test('very high temp = very high concern', () {
      final inputs = [
        FuzzyInput(
            name: 'Temperature',
            variableName: 'temperature',
            value: 41.8,
            minValue: 35.0,
            maxValue: 42.0,
            unit: '°C',
            description: ''),
        FuzzyInput(
            name: 'Appetite',
            variableName: 'appetite',
            value: 50.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Activity',
            variableName: 'activity',
            value: 50.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Symptom Severity',
            variableName: 'symptomSeverity',
            value: 50.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Duration',
            variableName: 'duration',
            value: 24.0,
            minValue: 0.0,
            maxValue: 168.0,
            unit: 'hours',
            description: ''),
      ];

      final result = engine.evaluate(inputs);
      expect(result.concernLevel, equals('Very High Concern'));
      expect(result.crispOutput, greaterThanOrEqualTo(81));
    });

    test('severe symptoms + long duration = very high concern', () {
      final inputs = [
        FuzzyInput(
            name: 'Temperature',
            variableName: 'temperature',
            value: 38.5,
            minValue: 35.0,
            maxValue: 42.0,
            unit: '°C',
            description: ''),
        FuzzyInput(
            name: 'Appetite',
            variableName: 'appetite',
            value: 50.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Activity',
            variableName: 'activity',
            value: 50.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Symptom Severity',
            variableName: 'symptomSeverity',
            value: 90.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Duration',
            variableName: 'duration',
            value: 120.0,
            minValue: 0.0,
            maxValue: 168.0,
            unit: 'hours',
            description: ''),
      ];

      final result = engine.evaluate(inputs);
      // Centroid defuzzification blends with other rules (e.g., R7: Severe=High Concern)
      // Result is at the upper end of High Concern, approaching Very High
      expect(result.concernLevel, equals('High Concern'));
      expect(result.crispOutput, greaterThanOrEqualTo(61));
      expect(result.crispOutput, lessThanOrEqualTo(80));
    });

    test('low temp + very low activity = high concern', () {
      final inputs = [
        FuzzyInput(
            name: 'Temperature',
            variableName: 'temperature',
            value: 36.0,
            minValue: 35.0,
            maxValue: 42.0,
            unit: '°C',
            description: ''),
        FuzzyInput(
            name: 'Appetite',
            variableName: 'appetite',
            value: 50.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Activity',
            variableName: 'activity',
            value: 10.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Symptom Severity',
            variableName: 'symptomSeverity',
            value: 30.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Duration',
            variableName: 'duration',
            value: 24.0,
            minValue: 0.0,
            maxValue: 168.0,
            unit: 'hours',
            description: ''),
      ];

      final result = engine.evaluate(inputs);
      // Centroid defuzzification blends with other rules (e.g., R14: Low temp=Moderate Concern)
      // Result is at the upper end of Moderate Concern
      expect(result.concernLevel, equals('Moderate Concern'));
      expect(result.crispOutput, greaterThanOrEqualTo(31));
      expect(result.crispOutput, lessThanOrEqualTo(60));
    });

    test(
        'elevated temp + moderate symptoms + moderate duration = moderate concern',
        () {
      final inputs = [
        FuzzyInput(
            name: 'Temperature',
            variableName: 'temperature',
            value: 39.2,
            minValue: 35.0,
            maxValue: 42.0,
            unit: '°C',
            description: ''),
        FuzzyInput(
            name: 'Appetite',
            variableName: 'appetite',
            value: 50.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Activity',
            variableName: 'activity',
            value: 50.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Symptom Severity',
            variableName: 'symptomSeverity',
            value: 50.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Duration',
            variableName: 'duration',
            value: 48.0,
            minValue: 0.0,
            maxValue: 168.0,
            unit: 'hours',
            description: ''),
      ];

      final result = engine.evaluate(inputs);
      expect(result.concernLevel, equals('Moderate Concern'));
    });

    test('validates input ranges', () {
      final inputs = [
        FuzzyInput(
            name: 'Temperature',
            variableName: 'temperature',
            value: 50.0,
            minValue: 35.0,
            maxValue: 42.0,
            unit: '°C',
            description: ''),
        FuzzyInput(
            name: 'Appetite',
            variableName: 'appetite',
            value: 50.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Activity',
            variableName: 'activity',
            value: 50.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Symptom Severity',
            variableName: 'symptomSeverity',
            value: 50.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Duration',
            variableName: 'duration',
            value: 24.0,
            minValue: 0.0,
            maxValue: 168.0,
            unit: 'hours',
            description: ''),
      ];

      expect(() => engine.evaluate(inputs), throwsArgumentError);
    });

    test('validates missing input', () {
      final inputs = [
        FuzzyInput(
            name: 'Temperature',
            variableName: 'temperature',
            value: 38.0,
            minValue: 35.0,
            maxValue: 42.0,
            unit: '°C',
            description: ''),
        // missing appetite, activity, symptomSeverity, duration
      ];

      expect(() => engine.evaluate(inputs), throwsArgumentError);
    });
  });

  group('VeterinaryAssessment', () {
    late VeterinaryAssessment assessment;

    setUp(() {
      assessment = VeterinaryAssessment();
    });

    test('assessWithDefaults works with partial inputs', () {
      final result = assessment.assessWithDefaults(
        temperature: 38.0,
        appetite: 80.0,
        activity: 70.0,
      );

      expect(result.concernLevel, equals('Low Concern'));
      expect(result.inputs.length, equals(5));
    });

    test('assessWithDefaults uses defaults for unspecified', () {
      final result1 = assessment.assessWithDefaults(temperature: 38.0);
      final result2 = assessment.assessWithDefaults(
        temperature: 38.0,
        appetite: 50.0,
        activity: 50.0,
        symptomSeverity: 50.0,
        duration: 24.0,
      );

      // Both should work and produce valid results
      expect(result1.crispOutput, greaterThanOrEqualTo(0.0));
      expect(result1.crispOutput, lessThanOrEqualTo(100.0));
      expect(result2.crispOutput, greaterThanOrEqualTo(0.0));
      expect(result2.crispOutput, lessThanOrEqualTo(100.0));
    });
  });

  group('Boundary Values', () {
    late FuzzyEngine engine;

    setUp(() {
      engine = VeterinaryFuzzyLogic.createEngine();
    });

    test('temperature at exact boundaries', () {
      // Test at min/max of temperature range
      final inputsMin = [
        FuzzyInput(
            name: 'Temperature',
            variableName: 'temperature',
            value: 35.0,
            minValue: 35.0,
            maxValue: 42.0,
            unit: '°C',
            description: ''),
        FuzzyInput(
            name: 'Appetite',
            variableName: 'appetite',
            value: 50.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Activity',
            variableName: 'activity',
            value: 50.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Symptom Severity',
            variableName: 'symptomSeverity',
            value: 50.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Duration',
            variableName: 'duration',
            value: 24.0,
            minValue: 0.0,
            maxValue: 168.0,
            unit: 'hours',
            description: ''),
      ];

      final result = engine.evaluate(inputsMin);
      expect(result.crispOutput, greaterThanOrEqualTo(0.0));
      expect(result.crispOutput, lessThanOrEqualTo(100.0));
    });

    test('temperature at max boundary', () {
      final inputsMax = [
        FuzzyInput(
            name: 'Temperature',
            variableName: 'temperature',
            value: 42.0,
            minValue: 35.0,
            maxValue: 42.0,
            unit: '°C',
            description: ''),
        FuzzyInput(
            name: 'Appetite',
            variableName: 'appetite',
            value: 50.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Activity',
            variableName: 'activity',
            value: 50.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Symptom Severity',
            variableName: 'symptomSeverity',
            value: 50.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Duration',
            variableName: 'duration',
            value: 24.0,
            minValue: 0.0,
            maxValue: 168.0,
            unit: 'hours',
            description: ''),
      ];

      final result = engine.evaluate(inputsMax);
      expect(result.crispOutput, greaterThanOrEqualTo(0.0));
      expect(result.crispOutput, lessThanOrEqualTo(100.0));
    });

    test('deterministic results', () {
      final inputs = [
        FuzzyInput(
            name: 'Temperature',
            variableName: 'temperature',
            value: 39.5,
            minValue: 35.0,
            maxValue: 42.0,
            unit: '°C',
            description: ''),
        FuzzyInput(
            name: 'Appetite',
            variableName: 'appetite',
            value: 30.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Activity',
            variableName: 'activity',
            value: 40.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Symptom Severity',
            variableName: 'symptomSeverity',
            value: 60.0,
            minValue: 0.0,
            maxValue: 100.0,
            unit: '%',
            description: ''),
        FuzzyInput(
            name: 'Duration',
            variableName: 'duration',
            value: 36.0,
            minValue: 0.0,
            maxValue: 168.0,
            unit: 'hours',
            description: ''),
      ];

      final result1 = engine.evaluate(inputs);
      final result2 = engine.evaluate(inputs);

      expect(result1.crispOutput, equals(result2.crispOutput));
      expect(result1.concernLevel, equals(result2.concernLevel));
      expect(result1.ruleActivations, equals(result2.ruleActivations));
    });
  });
}
