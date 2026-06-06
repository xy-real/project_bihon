import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/crisync_bottom_navigation.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';
import 'package:project_bihon/features/preparedness_instruction/models/instruction_guide.dart';
import 'package:project_bihon/features/preparedness_instruction/repositories/instruction_guide_repository.dart';
import 'package:project_bihon/features/preparedness_instruction/ui/category_grid.dart';

class PreparednessGuideViewerPage extends StatefulWidget {
  const PreparednessGuideViewerPage({
    super.key,
    required this.repository,
    required this.guideId,
    this.guidesListenable,
    this.onMarkGuideRead,
  });

  static const String routeName = '/preparedness-guide';

  final InstructionGuideRepository repository;
  final String guideId;
  final ValueListenable<List<InstructionGuide>>? guidesListenable;
  final Future<void> Function(String guideId)? onMarkGuideRead;

  @override
  State<PreparednessGuideViewerPage> createState() =>
      _PreparednessGuideViewerPageState();
}

class _PreparednessGuideViewerPageState
    extends State<PreparednessGuideViewerPage> {
  final PageController _pageController = PageController();
  final Set<String> _precachedGuideIds = <String>{};
  final Set<String> _completionRequestedForGuideIds = <String>{};

  int _currentPage = 0;

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  int _pageCountFor(InstructionGuide guide) {
    return math.max(1, guide.contentSteps.length);
  }

  String _stepText(InstructionGuide guide, int index) {
    if (guide.contentSteps.isEmpty) {
      return 'No instruction steps are available for this guide yet.';
    }
    return guide.contentSteps[index.clamp(0, guide.contentSteps.length - 1)];
  }

  String? _imagePath(InstructionGuide guide, int index) {
    if (_isEmergencyKitGuide(guide) && index == 0) {
      return 'assets/images/guides/emergency_guide_step_1.png';
    }
    if (guide.imageAssetPaths.isEmpty) {
      return null;
    }
    return guide.imageAssetPaths[index.clamp(
      0,
      guide.imageAssetPaths.length - 1,
    )];
  }

  String? _fallbackImagePath(InstructionGuide guide, int index) {
    if (!_isEmergencyKitGuide(guide) || index != 0) {
      return null;
    }
    if (guide.imageAssetPaths.isEmpty) {
      return null;
    }
    return guide.imageAssetPaths.first;
  }

  bool _isEmergencyKitGuide(InstructionGuide guide) {
    final searchable = '${guide.id} ${guide.title} ${guide.category}'.toLowerCase();
    return searchable.contains('go_bag') ||
        searchable.contains('go bag') ||
        searchable.contains('emergency kit') ||
        searchable.contains('family readiness');
  }

  List<String> _checklistItemsFor(InstructionGuide guide) {
    if (!_isEmergencyKitGuide(guide)) {
      return const [];
    }

    return const [
      'Drinking water',
      'Ready-to-eat food',
      'Medicines and first aid supplies',
      'Flashlight and whistle',
    ];
  }

  _StepContent _stepContentFor(InstructionGuide guide, int index) {
    final text = _stepText(guide, index).trim();
    final colonIndex = text.indexOf(': ');
    if (colonIndex > 0 && colonIndex <= 48) {
      return _StepContent(
        title: text.substring(0, colonIndex).trim(),
        body: text.substring(colonIndex + 2).trim(),
      );
    }

    final dashIndex = text.indexOf(' - ');
    if (dashIndex > 0 && dashIndex <= 48) {
      return _StepContent(
        title: text.substring(0, dashIndex).trim(),
        body: text.substring(dashIndex + 3).trim(),
      );
    }

    return _StepContent(title: guide.title, body: text);
  }

  void _precacheGuideImages(InstructionGuide guide) {
    if (_precachedGuideIds.contains(guide.id)) {
      return;
    }

    _precachedGuideIds.add(guide.id);
    for (final path in guide.imageAssetPaths) {
      precacheImage(
        AssetImage(path),
        context,
        onError: (error, stackTrace) {
          debugPrint(
            '[GuideViewer] Unable to precache image asset "$path": $error',
          );
        },
      );
    }
  }

  Widget _buildImagePlaceholder(BuildContext context) {
    return ColoredBox(
      color: DashboardDesign.surfaceVariant(context),
      child: Center(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Icon(
                Icons.image_not_supported_outlined,
                size: 48,
                color: DashboardDesign.mutedText(context),
              ),
              const SizedBox(height: 12),
              Text(
                'Image unavailable',
                textAlign: TextAlign.center,
                style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                      color: DashboardDesign.mutedText(context),
                      fontWeight: FontWeight.w700,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuideImage(
    BuildContext context,
    String? imagePath, {
    String? fallbackImagePath,
  }) {
    return ClipRRect(
      borderRadius: BorderRadius.circular(DashboardDesign.radius),
      child: imagePath == null
          ? _buildImagePlaceholder(context)
          : Image.asset(
              imagePath,
              width: double.infinity,
              height: double.infinity,
              fit: BoxFit.contain,
              errorBuilder: (context, error, stackTrace) {
                if (fallbackImagePath != null &&
                    fallbackImagePath != imagePath) {
                  return Image.asset(
                    fallbackImagePath,
                    width: double.infinity,
                    height: double.infinity,
                    fit: BoxFit.contain,
                    errorBuilder: (context, error, stackTrace) {
                      return _buildImagePlaceholder(context);
                    },
                  );
                }
                return _buildImagePlaceholder(context);
              },
            ),
    );
  }

  Future<void> _markReadIfFinalPage(
    InstructionGuide guide,
    int pageIndex,
  ) async {
    final finalPageIndex = _pageCountFor(guide) - 1;
    if (pageIndex != finalPageIndex || guide.isRead) {
      return;
    }
    if (_completionRequestedForGuideIds.contains(guide.id)) {
      return;
    }

    _completionRequestedForGuideIds.add(guide.id);
    final markGuideRead = widget.onMarkGuideRead;
    if (markGuideRead != null) {
      await markGuideRead(guide.id);
      return;
    }

    await widget.repository.markGuideRead(guide.id);
  }

  Widget _buildProgressSection(BuildContext context, InstructionGuide guide) {
    final pageCount = _pageCountFor(guide);
    final currentStep = (_currentPage + 1).clamp(1, pageCount);
    final progress = pageCount == 0 ? 0.0 : currentStep / pageCount;
    final percent = (progress * 100).round();

    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 14, 16, 12),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 768),
          child: Column(
            children: [
              Row(
                children: [
                  Text(
                    'STEP $currentStep OF $pageCount',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: DashboardDesign.mutedText(context),
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                  const Spacer(),
                  Text(
                    '$percent%',
                    style: Theme.of(context).textTheme.labelLarge?.copyWith(
                          color: DashboardDesign.deepNavy,
                          fontWeight: FontWeight.w900,
                        ),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              ClipRRect(
                borderRadius: BorderRadius.circular(999),
                child: LinearProgressIndicator(
                  minHeight: 8,
                  value: progress,
                  backgroundColor: DashboardDesign.surfaceVariant(context),
                  valueColor: const AlwaysStoppedAnimation<Color>(
                    DashboardDesign.deepNavy,
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildGuidePage(
    BuildContext context,
    InstructionGuide guide,
    int index,
  ) {
    final imagePath = _imagePath(guide, index);
    final fallbackImagePath = _fallbackImagePath(guide, index);
    final stepContent = _stepContentFor(guide, index);
    final checklistItems = index == 0 ? _checklistItemsFor(guide) : const <String>[];

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 768),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                AspectRatio(
                  aspectRatio: 16 / 10,
                  child: DecoratedBox(
                    decoration: BoxDecoration(
                      color: DashboardDesign.surface(context),
                      borderRadius: BorderRadius.circular(DashboardDesign.radius),
                      boxShadow: DashboardDesign.cardShadow(context),
                    ),
                    child: _buildGuideImage(
                      context,
                      imagePath,
                      fallbackImagePath: fallbackImagePath,
                    ),
                  ),
                ),
                const SizedBox(height: DashboardDesign.gap),
                _ContentCard(
                  title: stepContent.title,
                  body: stepContent.body,
                ),
                if (checklistItems.isNotEmpty) ...[
                  const SizedBox(height: DashboardDesign.gap),
                  _ChecklistCard(items: checklistItems),
                ],
                const SizedBox(height: 120),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildActionBar(InstructionGuide guide, int pageCount) {
    return Material(
      color: DashboardDesign.surface(context),
      elevation: 8,
      shadowColor: Colors.black.withValues(alpha: 0.10),
      child: SafeArea(
        top: false,
        bottom: false,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 12),
          child: Center(
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 768),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _currentPage == 0 ? null : _goToPrevious,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
                      style: OutlinedButton.styleFrom(
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DashboardDesign.radius),
                        ),
                        side: BorderSide(color: DashboardDesign.outline(context)),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: FilledButton.icon(
                      onPressed: () => _goToNext(guide),
                      icon: Icon(
                        _currentPage == pageCount - 1
                            ? Icons.check
                            : Icons.arrow_forward,
                      ),
                      label: Text(
                        _currentPage == pageCount - 1 ? 'Finish' : 'Next',
                      ),
                      style: FilledButton.styleFrom(
                        backgroundColor: DashboardDesign.deepNavy,
                        foregroundColor: Colors.white,
                        minimumSize: const Size.fromHeight(52),
                        shape: RoundedRectangleBorder(
                          borderRadius:
                              BorderRadius.circular(DashboardDesign.radius),
                        ),
                        textStyle: const TextStyle(fontWeight: FontWeight.w900),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  void _handleBack() {
    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed(PreparednessCategoryGridPage.routeName);
  }

  void _openTab(int index) {
    final navigator = Navigator.of(context);
    final routeName = switch (index) {
      0 => '/home',
      1 => '/alerts',
      2 => '/evacuation-centers',
      3 => '/supplies',
      4 => '/contacts',
      _ => null,
    };

    if (routeName == null) {
      return;
    }

    if (index == 0) {
      navigator.pushNamedAndRemoveUntil(routeName, (route) => false);
    } else {
      navigator.pushReplacementNamed(routeName);
    }
  }

  void _goToPrevious() {
    if (_currentPage <= 0) {
      return;
    }
    _pageController.previousPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  void _goToNext(InstructionGuide guide) {
    final finalPageIndex = _pageCountFor(guide) - 1;
    if (_currentPage >= finalPageIndex) {
      _markReadIfFinalPage(guide, finalPageIndex);
      Navigator.of(context).pop();
      return;
    }
    _pageController.nextPage(
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final guidesListenable = widget.guidesListenable;
    if (guidesListenable != null) {
      return ValueListenableBuilder<List<InstructionGuide>>(
        valueListenable: guidesListenable,
        builder: (context, guides, _) {
          final guide = _findGuide(guides);
          return _buildScaffold(context, guide);
        },
      );
    }

    return ValueListenableBuilder<Box<InstructionGuide>>(
      valueListenable: widget.repository.getGuidesListenable(),
      builder: (context, box, _) {
        return _buildScaffold(context, box.get(widget.guideId));
      },
    );
  }

  InstructionGuide? _findGuide(List<InstructionGuide> guides) {
    for (final guide in guides) {
      if (guide.id == widget.guideId) {
        return guide;
      }
    }
    return null;
  }

  Widget _buildScaffold(BuildContext context, InstructionGuide? guide) {
    if (guide == null) {
      return Scaffold(
        backgroundColor: DashboardDesign.background(context),
        appBar: AppBar(
          title: const Text('Emergency Guide'),
          leading: IconButton(
            tooltip: 'Back',
            icon: const Icon(Icons.arrow_back),
            onPressed: _handleBack,
          ),
        ),
        body: const Center(child: Text('This guide could not be found.')),
        bottomNavigationBar: CrisyncBottomNavigation(
          selectedIndex: null,
          onDestinationSelected: _openTab,
        ),
      );
    }

    final pageCount = _pageCountFor(guide);
    if (_currentPage > pageCount - 1) {
      _currentPage = pageCount - 1;
    }

    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) {
        return;
      }
      _precacheGuideImages(guide);
      if (pageCount == 1) {
        _markReadIfFinalPage(guide, 0);
      }
    });

    return Scaffold(
      backgroundColor: DashboardDesign.background(context),
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: DashboardDesign.surface(context),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: 'Back',
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
        titleSpacing: 0,
        title: const Text(
          'Emergency Guide',
          style: TextStyle(fontWeight: FontWeight.w800),
        ),
      ),
      body: Column(
        children: [
          _buildProgressSection(context, guide),
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: pageCount,
              onPageChanged: (index) {
                setState(() {
                  _currentPage = index;
                });
                _markReadIfFinalPage(guide, index);
              },
              itemBuilder: (context, index) {
                return _buildGuidePage(context, guide, index);
              },
            ),
          ),
        ],
      ),
      bottomNavigationBar: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          _buildActionBar(guide, pageCount),
          CrisyncBottomNavigation(
            selectedIndex: null,
            onDestinationSelected: _openTab,
          ),
        ],
      ),
    );
  }
}

class _StepContent {
  const _StepContent({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;
}

class _ContentCard extends StatelessWidget {
  const _ContentCard({
    required this.title,
    required this.body,
  });

  final String title;
  final String body;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        border: Border.all(color: DashboardDesign.outline(context)),
        boxShadow: DashboardDesign.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            title,
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Theme.of(context).colorScheme.onSurface,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          Text(
            body,
            style: Theme.of(context).textTheme.bodyLarge?.copyWith(
                  color: DashboardDesign.mutedText(context),
                  height: 1.5,
                ),
          ),
        ],
      ),
    );
  }
}

class _ChecklistCard extends StatelessWidget {
  const _ChecklistCard({required this.items});

  final List<String> items;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        border: Border.all(color: DashboardDesign.outline(context)),
        boxShadow: DashboardDesign.cardShadow(context),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Checklist',
            style: Theme.of(context).textTheme.titleMedium?.copyWith(
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 10),
          for (final item in items)
            Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                children: [
                  Container(
                    width: 24,
                    height: 24,
                    decoration: BoxDecoration(
                      color: DashboardDesign.statusBackground(
                        context,
                        DashboardDesign.success,
                      ),
                      borderRadius: BorderRadius.circular(999),
                    ),
                    child: const Icon(
                      Icons.check,
                      color: DashboardDesign.success,
                      size: 16,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      item,
                      style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                            fontWeight: FontWeight.w700,
                          ),
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }
}
