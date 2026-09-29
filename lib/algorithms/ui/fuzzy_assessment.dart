import 'dart:math';
import 'package:flutter/material.dart';
import 'package:vetcare_connect/algorithms/fuzzy_logic.dart';
import 'package:vetcare_connect/config/theme/app_theme.dart';

class FuzzyAssessmentScreen extends StatefulWidget {
  const FuzzyAssessmentScreen({super.key});

  @override
  State<FuzzyAssessmentScreen> createState() => _FuzzyAssessmentScreenState();
}

class _FuzzyAssessmentScreenState extends State<FuzzyAssessmentScreen> {
  static final _engine = VeterinaryFuzzyLogic.createEngine();
  static final _defaults = FuzzyInput.getVeterinaryDefaults();

  late final TextEditingController _tempController;
  late final TextEditingController _appetiteController;
  late final TextEditingController _activityController;
  late final TextEditingController _severityController;
  late final TextEditingController _durationController;

  FuzzyResult? _result;
  bool _isLoading = false;

  @override
  void initState() {
    super.initState();
    _tempController =
        TextEditingController(text: _defaults[0].value.toString());
    _appetiteController =
        TextEditingController(text: _defaults[1].value.toString());
    _activityController =
        TextEditingController(text: _defaults[2].value.toString());
    _severityController =
        TextEditingController(text: _defaults[3].value.toString());
    _durationController =
        TextEditingController(text: _defaults[4].value.toString());
  }

  @override
  void dispose() {
    _tempController.dispose();
    _appetiteController.dispose();
    _activityController.dispose();
    _severityController.dispose();
    _durationController.dispose();
    super.dispose();
  }

  FuzzyInput _buildInput(String variableName, double value) {
    final defaultInput =
        _defaults.firstWhere((i) => i.variableName == variableName);
    return FuzzyInput(
      name: defaultInput.name,
      variableName: defaultInput.variableName,
      value: value.clamp(defaultInput.minValue, defaultInput.maxValue),
      minValue: defaultInput.minValue,
      maxValue: defaultInput.maxValue,
      unit: defaultInput.unit,
      description: defaultInput.description,
    );
  }

  void _runAssessment() {
    setState(() => _isLoading = true);

    Future.microtask(() {
      try {
        final temp =
            double.tryParse(_tempController.text) ?? _defaults[0].value;
        final appetite =
            double.tryParse(_appetiteController.text) ?? _defaults[1].value;
        final activity =
            double.tryParse(_activityController.text) ?? _defaults[2].value;
        final severity =
            double.tryParse(_severityController.text) ?? _defaults[3].value;
        final duration =
            double.tryParse(_durationController.text) ?? _defaults[4].value;

        final inputs = [
          _buildInput('temperature', temp),
          _buildInput('appetite', appetite),
          _buildInput('activity', activity),
          _buildInput('symptomSeverity', severity),
          _buildInput('duration', duration),
        ];

        final result = _engine.evaluate(inputs);
        setState(() => _result = result);
      } catch (e) {
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
                content: Text('Assessment error: $e'),
                backgroundColor: Colors.red),
          );
        }
      } finally {
        if (mounted) setState(() => _isLoading = false);
      }
    });
  }

  void _resetDefaults() {
    setState(() {
      _tempController.text = _defaults[0].value.toStringAsFixed(1);
      _appetiteController.text = _defaults[1].value.toStringAsFixed(0);
      _activityController.text = _defaults[2].value.toStringAsFixed(0);
      _severityController.text = _defaults[3].value.toStringAsFixed(0);
      _durationController.text = _defaults[4].value.toStringAsFixed(0);
      _result = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(
        title: const Text('Fuzzy Health Assessment'),
        backgroundColor: AppTheme.primaryGreen,
        foregroundColor: Colors.white,
      ),
      body: LayoutBuilder(
        builder: (context, constraints) {
          final maxWidth = min(constraints.maxWidth, 900.0);
          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Center(
              child: ConstrainedBox(
                constraints: BoxConstraints(maxWidth: maxWidth),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    _buildInputCard(theme),
                    const SizedBox(height: 16),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton.icon(
                            onPressed: _isLoading ? null : _runAssessment,
                            icon: _isLoading
                                ? const SizedBox(
                                    width: 20,
                                    height: 20,
                                    child: CircularProgressIndicator(
                                      strokeWidth: 2,
                                      color: Colors.white,
                                    ),
                                  )
                                : const Icon(Icons.analytics_rounded),
                            label: Text(
                                _isLoading ? 'Analyzing...' : 'Run Assessment'),
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppTheme.primaryGreen,
                              foregroundColor: Colors.white,
                              padding: const EdgeInsets.symmetric(vertical: 14),
                            ),
                          ),
                        ),
                        const SizedBox(width: 12),
                        OutlinedButton.icon(
                          onPressed: _resetDefaults,
                          icon: const Icon(Icons.restore_rounded),
                          label: const Text('Reset'),
                        ),
                      ],
                    ),
                    if (_result != null) ...[
                      const SizedBox(height: 20),
                      _buildResultCard(theme),
                    ],
                  ],
                ),
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildInputCard(ThemeData theme) {
    return Card(
      elevation: 2,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text('Patient Vitals',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold)),
            const SizedBox(height: 16),
            _InputField(
              label: 'Body Temperature',
              controller: _tempController,
              unit: '°C',
              min: _defaults[0].minValue,
              max: _defaults[0].maxValue,
              decimals: 1,
            ),
            const SizedBox(height: 12),
            _InputField(
              label: 'Appetite Level',
              controller: _appetiteController,
              unit: '%',
              min: _defaults[1].minValue,
              max: _defaults[1].maxValue,
              decimals: 0,
            ),
            const SizedBox(height: 12),
            _InputField(
              label: 'Activity Level',
              controller: _activityController,
              unit: '%',
              min: _defaults[2].minValue,
              max: _defaults[2].maxValue,
              decimals: 0,
            ),
            const SizedBox(height: 12),
            _InputField(
              label: 'Symptom Severity',
              controller: _severityController,
              unit: '%',
              min: _defaults[3].minValue,
              max: _defaults[3].maxValue,
              decimals: 0,
            ),
            const SizedBox(height: 12),
            _InputField(
              label: 'Symptom Duration',
              controller: _durationController,
              unit: 'hours',
              min: _defaults[4].minValue,
              max: _defaults[4].maxValue,
              decimals: 0,
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildResultCard(ThemeData theme) {
    final result = _result!;
    final scoreColor = ConcernLevel.getColor(result.concernLevel);
    final scoreIcon = ConcernLevel.getIcon(result.concernLevel);

    return Card(
      elevation: 3,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(scoreIcon, size: 32, color: scoreColor),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text('Assessment Result',
                          style: theme.textTheme.titleMedium
                              ?.copyWith(fontWeight: FontWeight.bold)),
                      Text(result.concernLevel,
                          style: TextStyle(
                              fontSize: 20,
                              fontWeight: FontWeight.w800,
                              color: scoreColor)),
                    ],
                  ),
                ),
                Container(
                  padding:
                      const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                  decoration: BoxDecoration(
                    color: scoreColor.withValues(alpha: 0.12),
                    borderRadius: BorderRadius.circular(12),
                    border:
                        Border.all(color: scoreColor.withValues(alpha: 0.4)),
                  ),
                  child: Text(
                    '${result.crispOutput.toStringAsFixed(1)} / 100',
                    style: TextStyle(
                        fontSize: 18,
                        fontWeight: FontWeight.bold,
                        color: scoreColor),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(12),
              decoration: BoxDecoration(
                color: scoreColor.withValues(alpha: 0.08),
                borderRadius: BorderRadius.circular(12),
                border: Border.all(color: scoreColor.withValues(alpha: 0.25)),
              ),
              child: Text(result.recommendation,
                  style: const TextStyle(fontSize: 14)),
            ),
            const SizedBox(height: 16),
            const Text('Linguistic Output',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            Wrap(
              spacing: 8,
              runSpacing: 8,
              children: result.outputMemberships.entries.map((entry) {
                final membership = entry.value;
                final isBest =
                    membership == result.outputMemberships.values.reduce(max);
                return Chip(
                  label: Text(entry.key),
                  backgroundColor:
                      isBest ? scoreColor.withValues(alpha: 0.15) : null,
                  side: BorderSide(
                      color: isBest ? scoreColor : Colors.grey.shade300),
                );
              }).toList(),
            ),
            const SizedBox(height: 16),
            const Text('Top Rule Activations',
                style: TextStyle(fontWeight: FontWeight.w600)),
            const SizedBox(height: 6),
            _RuleActivationList(activations: result.ruleActivations),
            const SizedBox(height: 12),
            _ComputationDetails(result: result),
            const SizedBox(height: 12),
            Text(
              result.disclaimer,
              style: theme.textTheme.bodySmall?.copyWith(
                  color: Colors.grey[600], fontStyle: FontStyle.italic),
            ),
          ],
        ),
      ),
    );
  }
}

/// Educational, CS-focused walkthrough of the exact math behind the result:
/// fuzzification → Mamdani MIN-MAX rule evaluation → weighted-average
/// (centroid) defuzzification, with the real numbers from the last run.
class _ComputationDetails extends StatelessWidget {
  final FuzzyResult result;

  const _ComputationDetails({required this.result});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final firedRules = result.ruleActivations.entries
        .where((e) => e.value > 0)
        .toList()
      ..sort((a, b) => b.value.compareTo(a.value));
    final activationSum = firedRules.fold<double>(0, (sum, e) => sum + e.value);
    final totalRules = result.ruleActivations.length;

    return ExpansionTile(
      tilePadding: EdgeInsets.zero,
      childrenPadding: const EdgeInsets.fromLTRB(0, 4, 0, 8),
      leading: const Icon(Icons.functions, color: AppTheme.primaryGreen),
      title: const Text('Computation Breakdown',
          style: TextStyle(fontWeight: FontWeight.w600, fontSize: 14)),
      subtitle: const Text('Step-by-step fuzzy math (CS major focus)',
          style: TextStyle(fontSize: 11)),
      children: [
        _step(
          theme,
          '1. Fuzzification — crisp → fuzzy',
          'Each crisp input x is mapped to membership degrees μ(x) ∈ [0, 1] '
              'via triangular/trapezoidal membership functions over its domain:',
        ),
        ...result.inputs.map(
          (input) => Padding(
            padding: const EdgeInsets.only(left: 16, bottom: 4),
            child: Text(
              'x(${input.variableName}) = '
              '${input.value.toStringAsFixed(1)} ${input.unit} '
              '∈ [${input.minValue.toStringAsFixed(0)}, '
              '${input.maxValue.toStringAsFixed(0)}] → μ(x) computed per term',
              style:
                  theme.textTheme.bodySmall?.copyWith(fontFamily: 'monospace'),
            ),
          ),
        ),
        _step(
          theme,
          '2. Inference — Mamdani MIN-MAX',
          'Every rule r fires with strength αᵣ = MIN(μ of its antecedents). '
              'Of the $totalRules rules in the knowledge base, '
              '${firedRules.length} fired for the current inputs:',
        ),
        ...firedRules.take(5).map(
              (entry) => Padding(
                padding: const EdgeInsets.only(left: 16, bottom: 4),
                child: Text(
                  'α(${entry.key}) = ${entry.value.toStringAsFixed(3)}',
                  style: theme.textTheme.bodySmall
                      ?.copyWith(fontFamily: 'monospace'),
                ),
              ),
            ),
        _step(
          theme,
          '3. Defuzzification — weighted average (centroid)',
          'z* = Σ(αᵣ · cᵣ) / Σ(αᵣ), where cᵣ is each output term\'s center.\n'
              'Σ αᵣ = ${activationSum.toStringAsFixed(3)}  →  '
              'z* ≈ ${result.crispOutput.toStringAsFixed(1)} / 100 '
              '(${result.concernLevel}).',
        ),
      ],
    );
  }

  Widget _step(ThemeData theme, String title, String body) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(title,
              style: theme.textTheme.bodyMedium
                  ?.copyWith(fontWeight: FontWeight.bold)),
          const SizedBox(height: 2),
          Text(body, style: theme.textTheme.bodySmall?.copyWith(height: 1.35)),
        ],
      ),
    );
  }
}

class _InputField extends StatelessWidget {
  final String label;
  final TextEditingController controller;
  final String unit;
  final double min;
  final double max;
  final int decimals;

  const _InputField({
    required this.label,
    required this.controller,
    required this.unit,
    required this.min,
    required this.max,
    required this.decimals,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Text(label,
                style:
                    const TextStyle(fontWeight: FontWeight.w600, fontSize: 13)),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 4),
              decoration: BoxDecoration(
                color: AppTheme.primaryGreen.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text('$min – $max $unit',
                  style: const TextStyle(
                      fontSize: 12, color: AppTheme.primaryGreen)),
            ),
          ],
        ),
        const SizedBox(height: 8),
        TextField(
          controller: controller,
          keyboardType: const TextInputType.numberWithOptions(decimal: true),
          decoration: InputDecoration(
            suffixText: unit,
            border: const OutlineInputBorder(),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
          ),
        ),
      ],
    );
  }
}

class _RuleActivationList extends StatelessWidget {
  final Map<String, double> activations;

  const _RuleActivationList({required this.activations});

  @override
  Widget build(BuildContext context) {
    final sorted = activations.entries.where((e) => e.value > 0).toList()
      ..sort((a, b) => b.value.compareTo(a.value));

    if (sorted.isEmpty)
      return const Text('No rules activated for current inputs.');

    final top = sorted.take(5).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: top.map((entry) {
        final pct = (entry.value * 100).toStringAsFixed(1);
        return Padding(
          padding: const EdgeInsets.symmetric(vertical: 4),
          child: Row(
            children: [
              Container(
                width: 40,
                alignment: Alignment.center,
                padding: const EdgeInsets.symmetric(vertical: 4),
                decoration: BoxDecoration(
                  color: Colors.blue.withValues(alpha: 0.12),
                  borderRadius: BorderRadius.circular(8),
                ),
                child: Text(entry.key,
                    style: const TextStyle(
                        fontWeight: FontWeight.bold, fontSize: 12)),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: LinearProgressIndicator(
                  value: (entry.value).clamp(0.0, 1.0),
                  minHeight: 8,
                  borderRadius: BorderRadius.circular(4),
                  backgroundColor: Colors.grey.shade200,
                ),
              ),
              const SizedBox(width: 12),
              SizedBox(
                  width: 56,
                  child: Text('$pct%', style: const TextStyle(fontSize: 12))),
            ],
          ),
        );
      }).toList(),
    );
  }
}
