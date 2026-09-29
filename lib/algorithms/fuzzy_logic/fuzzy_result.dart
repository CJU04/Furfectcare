import 'package:flutter/material.dart';
import 'fuzzy_input.dart';

class FuzzyResult {
  final double crispOutput;
  final String linguisticOutput;
  final String concernLevel;
  final Map<String, double> outputMemberships;
  final Map<String, double> ruleActivations;
  final List<FuzzyInput> inputs;
  final DateTime timestamp;
  final String disclaimer;

  FuzzyResult({
    required this.crispOutput,
    required this.linguisticOutput,
    required this.concernLevel,
    required this.outputMemberships,
    required this.ruleActivations,
    required this.inputs,
    DateTime? timestamp,
    String? disclaimer,
  })  : timestamp = timestamp ?? DateTime.now(),
        disclaimer = disclaimer ??
            'This assessment is intended only as decision support and does not replace professional veterinary evaluation.';

  bool get isHighConcern => crispOutput >= 61;
  bool get isVeryHighConcern => crispOutput >= 81;

  String get recommendation {
    if (crispOutput >= 81) {
      return 'URGENT: Schedule immediate veterinary consultation. Very high concern level detected.';
    } else if (crispOutput >= 61) {
      return 'Schedule veterinary consultation within 24 hours. High concern level detected.';
    } else if (crispOutput >= 31) {
      return 'Monitor closely and consider veterinary consultation if symptoms persist or worsen. Moderate concern.';
    } else {
      return 'Continue monitoring. Low concern level. Consult veterinarian if symptoms change.';
    }
  }

  Map<String, dynamic> toJson() => {
        'crispOutput': crispOutput,
        'linguisticOutput': linguisticOutput,
        'concernLevel': concernLevel,
        'outputMemberships': outputMemberships,
        'ruleActivations': ruleActivations,
        'inputs': inputs.map((i) => i.toJson()).toList(),
        'timestamp': timestamp.toIso8601String(),
        'disclaimer': disclaimer,
        'recommendation': recommendation,
      };

  static FuzzyResult createDefault() {
    return FuzzyResult(
      crispOutput: 0.0,
      linguisticOutput: 'Unknown',
      concernLevel: 'Unknown',
      outputMemberships: {},
      ruleActivations: {},
      inputs: [],
      timestamp: DateTime.now(),
    );
  }
}

class ConcernLevel {
  static const String low = 'Low Concern';
  static const String moderate = 'Moderate Concern';
  static const String high = 'High Concern';
  static const String veryHigh = 'Very High Concern';

  static String fromScore(double score) {
    if (score >= 81) return veryHigh;
    if (score >= 61) return high;
    if (score >= 31) return moderate;
    return low;
  }

  static Color getColor(String level) {
    switch (level) {
      case veryHigh:
        return const Color(0xFFD32F2F);
      case high:
        return const Color(0xFFFF9800);
      case moderate:
        return const Color(0xFFFFC107);
      case low:
        return const Color(0xFF4CAF50);
      default:
        return const Color(0xFF9E9E9E);
    }
  }

  static IconData getIcon(String level) {
    switch (level) {
      case veryHigh:
        return Icons.warning_amber_rounded;
      case high:
        return Icons.warning_rounded;
      case moderate:
        return Icons.help_outline;
      case low:
        return Icons.check_circle_outline;
      default:
        return Icons.help;
    }
  }
}
