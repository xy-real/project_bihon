import 'dart:math' as math;

import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/preparedness_instruction/models/instruction_guide.dart';
import 'package:project_bihon/features/preparedness_instruction/repositories/instruction_guide_repository.dart';

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
    if (guide.imageAssetPaths.isEmpty) {
      return null;
    }
    return guide.imageAssetPaths[index.clamp(0, guide.imageAssetPaths.length - 1)];
  }

  void _precacheGuideImages(InstructionGuide guide) {
    if (_precachedGuideIds.contains(guide.id)) {
      return;
    }

    _precachedGuideIds.add(guide.id);
    for (final path in guide.imageAssetPaths) {
      precacheImage(AssetImage(path), context);
    }
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

  Widget _buildGuidePage(
    BuildContext context,
    InstructionGuide guide,
    int index,
  ) {
    final imagePath = _imagePath(guide, index);

    return SafeArea(
      top: false,
      child: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            AspectRatio(
              aspectRatio: 16 / 9,
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: imagePath == null
                    ? ColoredBox(
                        color: Theme.of(context).colorScheme.surfaceContainerHighest,
                        child: const Icon(Icons.image_not_supported_outlined),
                      )
                    : Image.asset(
                        imagePath,
                        fit: BoxFit.cover,
                        errorBuilder: (context, error, stackTrace) {
                          return ColoredBox(
                            color: Theme.of(context)
                                .colorScheme
                                .surfaceContainerHighest,
                            child: const Icon(Icons.broken_image_outlined),
                          );
                        },
                      ),
              ),
            ),
            const SizedBox(height: 20),
            Text(
              'Step ${index + 1} of ${_pageCountFor(guide)}',
              style: Theme.of(context).textTheme.labelLarge,
            ),
            const SizedBox(height: 8),
            Text(
              _stepText(guide, index),
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    );
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
        appBar: AppBar(title: const Text('Guide unavailable')),
        body: const Center(child: Text('This guide could not be found.')),
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
      appBar: AppBar(
        title: Text(guide.title),
      ),
      body: Column(
        children: [
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
          SafeArea(
            top: false,
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
              child: Row(
                children: [
                  Expanded(
                    child: OutlinedButton.icon(
                      onPressed: _currentPage == 0 ? null : _goToPrevious,
                      icon: const Icon(Icons.arrow_back),
                      label: const Text('Previous'),
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
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }
}
