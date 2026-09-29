import 'dart:math';

abstract class MembershipFunction {
  final String name;
  final double minValue;
  final double maxValue;

  MembershipFunction({
    required this.name,
    required this.minValue,
    required this.maxValue,
  });

  double membership(double x);
}

class TriangularMF extends MembershipFunction {
  final double left;
  final double peak;
  final double right;

  TriangularMF({
    required super.name,
    required super.minValue,
    required super.maxValue,
    required this.left,
    required this.peak,
    required this.right,
  });

  @override
  double membership(double x) {
    if (x <= left || x >= right) return 0.0;
    if (x == peak) return 1.0;
    if (x < peak) return (x - left) / (peak - left);
    return (right - x) / (right - peak);
  }

  static TriangularMF create({
    required String name,
    required double minValue,
    required double maxValue,
    required double left,
    required double peak,
    required double right,
  }) {
    return TriangularMF(
      name: name,
      minValue: minValue,
      maxValue: maxValue,
      left: left,
      peak: peak,
      right: right,
    );
  }
}

class TrapezoidalMF extends MembershipFunction {
  final double left;
  final double leftShoulder;
  final double rightShoulder;
  final double right;

  TrapezoidalMF({
    required super.name,
    required super.minValue,
    required super.maxValue,
    required this.left,
    required this.leftShoulder,
    required this.rightShoulder,
    required this.right,
  });

  @override
  double membership(double x) {
    if (x <= left || x >= right) return 0.0;
    if (x >= leftShoulder && x <= rightShoulder) return 1.0;
    if (x < leftShoulder) return (x - left) / (leftShoulder - left);
    return (right - x) / (right - rightShoulder);
  }

  static TrapezoidalMF create({
    required String name,
    required double minValue,
    required double maxValue,
    required double left,
    required double leftShoulder,
    required double rightShoulder,
    required double right,
  }) {
    return TrapezoidalMF(
      name: name,
      minValue: minValue,
      maxValue: maxValue,
      left: left,
      leftShoulder: leftShoulder,
      rightShoulder: rightShoulder,
      right: right,
    );
  }
}

class GaussianMF extends MembershipFunction {
  final double mean;
  final double sigma;

  GaussianMF({
    required super.name,
    required super.minValue,
    required super.maxValue,
    required this.mean,
    required this.sigma,
  });

  @override
  double membership(double x) {
    if (x < minValue || x > maxValue) return 0.0;
    return exp(-pow(x - mean, 2) / (2 * pow(sigma, 2)));
  }

  static GaussianMF create({
    required String name,
    required double minValue,
    required double maxValue,
    required double mean,
    required double sigma,
  }) {
    return GaussianMF(
      name: name,
      minValue: minValue,
      maxValue: maxValue,
      mean: mean,
      sigma: sigma,
    );
  }
}

class FuzzySet {
  final String variableName;
  final MembershipFunction membershipFunction;

  FuzzySet({
    required this.variableName,
    required this.membershipFunction,
  });

  String get name => membershipFunction.name;

  double membership(double x) => membershipFunction.membership(x);

  Map<String, dynamic> toJson() => {
        'variableName': variableName,
        'name': name,
        'type': membershipFunction.runtimeType.toString(),
        'params': _getParams(),
      };

  Map<String, dynamic> _getParams() {
    if (membershipFunction is TriangularMF) {
      final mf = membershipFunction as TriangularMF;
      return {
        'left': mf.left,
        'peak': mf.peak,
        'right': mf.right,
      };
    } else if (membershipFunction is TrapezoidalMF) {
      final mf = membershipFunction as TrapezoidalMF;
      return {
        'left': mf.left,
        'leftShoulder': mf.leftShoulder,
        'rightShoulder': mf.rightShoulder,
        'right': mf.right,
      };
    } else if (membershipFunction is GaussianMF) {
      final mf = membershipFunction as GaussianMF;
      return {
        'mean': mf.mean,
        'sigma': mf.sigma,
      };
    }
    return {};
  }
}
