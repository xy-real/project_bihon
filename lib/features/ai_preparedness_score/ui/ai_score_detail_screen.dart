import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/ai_preparedness_score/data/repositories/ai_score_repository.dart';
import 'package:project_bihon/features/ai_preparedness_score/models/ai_score_cache.dart';
import 'package:project_bihon/features/ai_preparedness_score/services/ai_score_service.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';
import 'package:project_bihon/shared/widgets/app_toast.dart';

class AIScoreDetailScreen extends StatefulWidget {
  const AIScoreDetailScreen({
    super.key,
    this.repository,
    this.service,
    this.onRecalculate,
    this.scoreListenable,
  }) : assert(
          repository != null || scoreListenable != null,
          'A repository or score listenable is required.',
        );

  static const String routeName = '/ai-score-details';

  final AIScoreRepository? repository;
  final AIScoreService? service;
  final Future<AIScoreCalculationResult> Function()? onRecalculate;
  final ValueListenable<AIScoreCache?>? scoreListenable;

  @override
  State<AIScoreDetailScreen> createState() => _AIScoreDetailScreenState();
}

class _AIScoreDetailScreenState extends State<AIScoreDetailScreen> {
  final Set<String> _checkedItems = {};
  bool _isRecalculating = false;

  Future<void> _recalculate() async {
    final recalculate = widget.onRecalculate ?? widget.service?.recalculate;
    if (_isRecalculating || recalculate == null) {
      return;
    }

    setState(() {
      _isRecalculating = true;
    });

    AIScoreCalculationResult result;
    try {
      result = await recalculate();
    } on Object {
      result = AIScoreCalculationResult.failed(
        cachedScore: widget.repository?.getLatestScore(),
      );
    }

    if (!mounted) {
      return;
    }

    setState(() {
      _isRecalculating = false;
    });
    AppToast.show(
      context,
      title: result.isSuccess ? 'Score updated' : 'Unable to calculate score',
      message: result.message,
      destructive: !result.isSuccess,
    );
  }

  String _formattedDate(DateTime date) {
    final local = date.toLocal();
    final month = local.month.toString().padLeft(2, '0');
    final day = local.day.toString().padLeft(2, '0');
    return '${local.year}-$month-$day';
  }

  @override
  Widget build(BuildContext context) {
    final scoreListenable = widget.scoreListenable;

    return Scaffold(
      backgroundColor: DashboardDesign.background(context),
      appBar: AppBar(
        centerTitle: true,
        title: const Text(
          'Preparedness Advice',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: scoreListenable != null
          ? ValueListenableBuilder<AIScoreCache?>(
              valueListenable: scoreListenable,
              builder: (context, score, _) => _buildBody(context, score),
            )
          : ValueListenableBuilder<Box<AIScoreCache>>(
              valueListenable: widget.repository!.getListenable(),
              builder: (context, box, _) {
                return _buildBody(
                  context,
                  box.get(AIScoreCache.latestScoreKey),
                );
              },
            ),
    );
  }

  Widget _buildBody(BuildContext context, AIScoreCache? score) {
    debugPrint(
      '[AIScoreDetail] Cache listener: ${score?.overallScore ?? 'empty'}.',
    );
    return score == null
        ? _buildEmptyState(context)
        : _buildScoreDetails(context, score);
  }

  Widget _buildEmptyState(BuildContext context) {
    return Center(
      child: SingleChildScrollView(
        padding: const EdgeInsets.all(24),
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 520),
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 72,
                height: 72,
                decoration: BoxDecoration(
                  color: DashboardDesign.statusBackground(
                    context,
                    DashboardDesign.deepNavy,
                  ),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.auto_awesome_outlined,
                  size: 34,
                  color: DashboardDesign.deepNavy,
                ),
              ),
              const SizedBox(height: 20),
              Text(
                'No preparedness score yet',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.headlineSmall?.copyWith(
                      fontWeight: FontWeight.w900,
                    ),
              ),
              const SizedBox(height: 8),
              Text(
                'Calculate your score to receive personalized advice and a list of missing essentials.',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                      color: DashboardDesign.mutedText(context),
                      height: 1.45,
                    ),
              ),
              const SizedBox(height: 24),
              _RecalculateButton(
                isLoading: _isRecalculating,
                onPressed: _recalculate,
                label: 'Calculate Score',
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildScoreDetails(BuildContext context, AIScoreCache score) {
    final missingItems = score.missingEssentialItems;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _DetailCard(
                child: Column(
                  children: [
                    Text(
                      '${score.overallScore}%',
                      style: Theme.of(context).textTheme.displayMedium?.copyWith(
                            color: DashboardDesign.deepNavy,
                            fontWeight: FontWeight.w900,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      score.status,
                      textAlign: TextAlign.center,
                      style: Theme.of(context).textTheme.titleLarge?.copyWith(
                            fontWeight: FontWeight.w800,
                          ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      'Calculated ${_formattedDate(score.calculatedAt)}',
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                            color: DashboardDesign.mutedText(context),
                          ),
                    ),
                    const SizedBox(height: 18),
                    ClipRRect(
                      borderRadius: BorderRadius.circular(999),
                      child: LinearProgressIndicator(
                        value: score.overallScore / 100,
                        minHeight: 10,
                        backgroundColor:
                            DashboardDesign.surfaceVariant(context),
                        valueColor: const AlwaysStoppedAnimation<Color>(
                          DashboardDesign.deepNavy,
                        ),
                      ),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                icon: Icons.lightbulb_outline,
                title: 'Personalized Advice',
                child: Text(
                  score.customAdvice,
                  style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                        height: 1.5,
                      ),
                ),
              ),
              const SizedBox(height: 16),
              _SectionCard(
                icon: Icons.checklist_rounded,
                title: 'Missing Essential Items',
                trailing: missingItems.isEmpty
                    ? null
                    : Text(
                        '${missingItems.length}',
                        style: Theme.of(context).textTheme.labelLarge?.copyWith(
                              color: DashboardDesign.deepNavy,
                              fontWeight: FontWeight.w900,
                            ),
                      ),
                child: missingItems.isEmpty
                    ? Text(
                        'No missing essentials were identified.',
                        style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                              color: DashboardDesign.mutedText(context),
                            ),
                      )
                    : Column(
                        children: [
                          for (final item in missingItems)
                            CheckboxListTile(
                              contentPadding: EdgeInsets.zero,
                              controlAffinity: ListTileControlAffinity.leading,
                              value: _checkedItems.contains(item),
                              title: Text(item),
                              onChanged: (checked) {
                                setState(() {
                                  if (checked ?? false) {
                                    _checkedItems.add(item);
                                  } else {
                                    _checkedItems.remove(item);
                                  }
                                });
                              },
                            ),
                          const SizedBox(height: 4),
                          Align(
                            alignment: Alignment.centerLeft,
                            child: Text(
                              'Use this list when shopping.',
                              style:
                                  Theme.of(context).textTheme.bodySmall?.copyWith(
                                        color:
                                            DashboardDesign.mutedText(context),
                                      ),
                            ),
                          ),
                        ],
                      ),
              ),
              const SizedBox(height: 20),
              _RecalculateButton(
                isLoading: _isRecalculating,
                onPressed: _recalculate,
                label: 'Recalculate',
              ),
              const SizedBox(height: 24),
            ],
          ),
        ),
      ),
    );
  }
}

class _RecalculateButton extends StatelessWidget {
  const _RecalculateButton({
    required this.isLoading,
    required this.onPressed,
    required this.label,
  });

  final bool isLoading;
  final VoidCallback onPressed;
  final String label;

  @override
  Widget build(BuildContext context) {
    return FilledButton.icon(
      onPressed: isLoading ? null : onPressed,
      icon: isLoading
          ? const SizedBox.square(
              dimension: 18,
              child: CircularProgressIndicator(strokeWidth: 2),
            )
          : const Icon(Icons.refresh_rounded),
      label: Text(isLoading ? 'Calculating...' : label),
      style: FilledButton.styleFrom(
        minimumSize: const Size.fromHeight(52),
        backgroundColor: DashboardDesign.deepNavy,
        foregroundColor: Colors.white,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(DashboardDesign.radius),
        ),
      ),
    );
  }
}

class _DetailCard extends StatelessWidget {
  const _DetailCard({required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        border: Border.all(color: DashboardDesign.outline(context)),
        boxShadow: DashboardDesign.cardShadow(context),
      ),
      child: child,
    );
  }
}

class _SectionCard extends StatelessWidget {
  const _SectionCard({
    required this.icon,
    required this.title,
    required this.child,
    this.trailing,
  });

  final IconData icon;
  final String title;
  final Widget child;
  final Widget? trailing;

  @override
  Widget build(BuildContext context) {
    return _DetailCard(
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(icon, color: DashboardDesign.deepNavy),
              const SizedBox(width: 10),
              Expanded(
                child: Text(
                  title,
                  style: Theme.of(context).textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w900,
                      ),
                ),
              ),
              if (trailing != null) trailing!,
            ],
          ),
          const SizedBox(height: 16),
          child,
        ],
      ),
    );
  }
}
