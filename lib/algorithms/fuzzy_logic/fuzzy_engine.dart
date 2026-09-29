import 'dart:math' as math;

import 'fuzzy_input.dart';
import 'fuzzy_rule.dart';
import 'fuzzy_result.dart';

class FuzzyEngine {
  final List<FuzzyVariable> inputVariables;
  final List<FuzzyVariable> outputVariables;
  final List<FuzzyRule> rules;

  FuzzyEngine({
    required this.inputVariables,
    required this.outputVariables,
    required this.rules,
  });

  FuzzyResult evaluate(List<FuzzyInput> inputs) {
    final validationErrors = <String>[];
    for (final input in inputs) {
      if (!input.isValid) {
        validationErrors.add(input.validationError);
      }
    }
    if (validationErrors.isNotEmpty) {
      throw ArgumentError('Invalid inputs: ${validationErrors.join('; ')}');
    }

    final fuzzifiedInputs = <String, Map<String, double>>{};
    for (final variable in inputVariables) {
      final input = inputs.firstWhere(
        (i) => i.variableName == variable.variableName,
        orElse: () =>
            throw ArgumentError('Missing input for ${variable.variableName}'),
      );
      fuzzifiedInputs[variable.variableName] = variable.fuzzify(input.value);
    }

    final ruleActivations = <String, double>{};
    final outputAccumulator = <String, Map<String, double>>{};

    for (final rule in rules) {
      final activation = rule.evaluate(fuzzifiedInputs);
      ruleActivations[rule.id] = activation;

      if (activation > 0) {
        for (final conclusion in rule.consequents) {
          outputAccumulator.putIfAbsent(
              conclusion.outputVariableName, () => <String, double>{});
          final current = outputAccumulator[conclusion.outputVariableName]![
                  conclusion.setName] ??
              0.0;
          outputAccumulator[conclusion.outputVariableName]![conclusion
              .setName] = math.max(current, activation * conclusion.weight);
        }
      }
    }

    final aggregatedOutputs = <String, double>{};
    for (final variable in outputVariables) {
      final aggregated = outputAccumulator[variable.variableName] ?? {};
      aggregatedOutputs[variable.variableName] =
          _defuzzifyCentroid(variable, aggregated);
    }

    final primaryOutput = outputVariables.first;
    final crispOutput = aggregatedOutputs[primaryOutput.variableName] ?? 0.0;
    final outputMemberships = Map.fromEntries(
      primaryOutput.sets
          .map((s) => MapEntry(s.name, s.membership(crispOutput))),
    );

    final concernLevel = ConcernLevel.fromScore(crispOutput);
    final linguisticOutput = _getLinguisticOutput(primaryOutput, crispOutput);

    return FuzzyResult(
      crispOutput: crispOutput.clamp(0.0, 100.0),
      linguisticOutput: linguisticOutput,
      concernLevel: concernLevel,
      outputMemberships: outputMemberships,
      ruleActivations: ruleActivations,
      inputs: inputs,
    );
  }

  double _defuzzifyCentroid(
      FuzzyVariable variable, Map<String, double> aggregated) {
    const steps = 1000;
    double numerator = 0.0;
    double denominator = 0.0;

    for (int i = 0; i <= steps; i++) {
      final x = variable.minValue +
          (variable.maxValue - variable.minValue) * i / steps;
      double maxMembership = 0.0;

      for (final entry in aggregated.entries) {
        final set = variable.getSet(entry.key);
        if (set != null) {
          final clipped = math.min(set.membership(x), entry.value);
          maxMembership = math.max(maxMembership, clipped);
        }
      }

      numerator += x * maxMembership;
      denominator += maxMembership;
    }

    if (denominator == 0.0) {
      return (variable.minValue + variable.maxValue) / 2;
    }

    final result = numerator / denominator;
    return ((result - variable.minValue) /
            (variable.maxValue - variable.minValue)) *
        100.0;
  }

  String _getLinguisticOutput(FuzzyVariable variable, double crispValue) {
    var bestSet = variable.sets.first;
    var bestMembership = 0.0;

    for (final set in variable.sets) {
      final m = set.membership(crispValue);
      if (m > bestMembership) {
        bestMembership = m;
        bestSet = set;
      }
    }

    return bestSet.name;
  }

  Map<String, dynamic> toJson() => {
        'inputVariables': inputVariables.map((v) => v.toJson()).toList(),
        'outputVariables': outputVariables.map((v) => v.toJson()).toList(),
        'rules': rules.map((r) => r.toJson()).toList(),
      };
}
