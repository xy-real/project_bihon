import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/crisync_bottom_navigation.dart';
import 'package:project_bihon/features/dashboard/presentation/widgets/dashboard_design.dart';
import 'package:project_bihon/features/preparedness_instruction/models/instruction_guide.dart';
import 'package:project_bihon/features/preparedness_instruction/repositories/instruction_guide_repository.dart';
import 'package:project_bihon/features/preparedness_instruction/ui/guide_viewer.dart';

class PreparednessCategoryGridPage extends StatefulWidget {
  const PreparednessCategoryGridPage({
    super.key,
    required this.repository,
    this.guidesListenable,
  });

  static const String routeName = '/preparedness';

  final InstructionGuideRepository repository;
  final ValueListenable<List<InstructionGuide>>? guidesListenable;

  @override
  State<PreparednessCategoryGridPage> createState() =>
      _PreparednessCategoryGridPageState();
}

class _PreparednessCategoryGridPageState
    extends State<PreparednessCategoryGridPage> {
  String? _selectedCategory;

  Map<String, List<InstructionGuide>> _groupByCategory(
    List<InstructionGuide> guides,
  ) {
    final grouped = <String, List<InstructionGuide>>{};
    for (final guide in guides) {
      grouped.putIfAbsent(guide.category, () => []).add(guide);
    }

    for (final categoryGuides in grouped.values) {
      categoryGuides.sort(
        (a, b) => a.title.toLowerCase().compareTo(b.title.toLowerCase()),
      );
    }

    return grouped;
  }

  List<String> _sortedCategories(Map<String, List<InstructionGuide>> grouped) {
    const preferredOrder = [
      'Typhoon',
      'First Aid',
      'Earthquake',
      'Flood',
      'Evacuation',
      'Family Readiness',
    ];

    final categories = grouped.keys.toList();
    categories.sort((a, b) {
      final aIndex = preferredOrder.indexOf(a);
      final bIndex = preferredOrder.indexOf(b);
      if (aIndex != -1 || bIndex != -1) {
        return (aIndex == -1 ? 999 : aIndex)
            .compareTo(bIndex == -1 ? 999 : bIndex);
      }
      return a.toLowerCase().compareTo(b.toLowerCase());
    });
    return categories;
  }

  void _openGuide(InstructionGuide guide) {
    Navigator.of(context).pushNamed(
      PreparednessGuideViewerPage.routeName,
      arguments: guide.id,
    );
  }

  void _handleBack() {
    if (_selectedCategory != null) {
      setState(() {
        _selectedCategory = null;
      });
      return;
    }

    final navigator = Navigator.of(context);
    if (navigator.canPop()) {
      navigator.pop();
      return;
    }
    navigator.pushReplacementNamed('/home');
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

  void _showSuggestUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Suggest category is not available yet.'),
      ),
    );
  }

  void _showFeaturedUnavailable() {
    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(
        content: Text('Emergency Kit guide is not available yet.'),
      ),
    );
  }

  InstructionGuide? _findFeaturedGuide(List<InstructionGuide> guides) {
    for (final guide in guides) {
      final searchable =
          '${guide.id} ${guide.title} ${guide.category}'.toLowerCase();
      if (searchable.contains('go_bag') ||
          searchable.contains('go bag') ||
          searchable.contains('emergency kit') ||
          searchable.contains('kit') ||
          searchable.contains('family readiness')) {
        return guide;
      }
    }
    return null;
  }

  Widget _buildLogoAvatar() {
    return CircleAvatar(
      radius: 18,
      backgroundColor: DashboardDesign.deepNavy,
      child: ClipOval(
        child: Image.asset(
          'assets/logo.png',
          width: 36,
          height: 36,
          fit: BoxFit.cover,
          errorBuilder: (context, error, stackTrace) {
            return const Icon(
              Icons.shield_outlined,
              color: Colors.white,
              size: 20,
            );
          },
        ),
      ),
    );
  }

  Widget _buildHeader(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Expanded(
              child: Text(
                'Preparedness Guides',
                style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                      fontWeight: FontWeight.w900,
                      color: Theme.of(context).colorScheme.onSurface,
                    ),
              ),
            ),
            const SizedBox(width: 12),
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 7),
              decoration: BoxDecoration(
                color: DashboardDesign.statusBackground(
                  context,
                  DashboardDesign.success,
                ),
                borderRadius: BorderRadius.circular(999),
                border: Border.all(
                  color: DashboardDesign.success.withValues(alpha: 0.18),
                ),
              ),
              child: const Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Icon(
                    Icons.cloud_done_outlined,
                    size: 16,
                    color: DashboardDesign.success,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'OFFLINE READY',
                    style: TextStyle(
                      color: DashboardDesign.success,
                      fontSize: 11,
                      fontWeight: FontWeight.w900,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
        const SizedBox(height: 10),
        Text(
          'Essential safety protocols and life-saving instructions designed for immediate access, even without internet connectivity.',
          style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                color: DashboardDesign.mutedText(context),
                height: 1.45,
              ),
        ),
      ],
    );
  }

  Widget _buildCategoryGrid(
    BuildContext context,
    Map<String, List<InstructionGuide>> grouped,
  ) {
    final categories = _sortedCategories(grouped);

    if (categories.isEmpty) {
      return const _EmptyGuidesCard();
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 840 ? 3 : 2;
        const gap = DashboardDesign.gap;
        final cardWidth = (width - (gap * (columns - 1))) / columns;

        return Wrap(
          spacing: gap,
          runSpacing: gap,
          children: [
            for (final category in categories)
              SizedBox(
                width: cardWidth,
                child: _CategoryCard(
                  category: category,
                  guides: grouped[category] ?? const [],
                  onTap: () {
                    setState(() {
                      _selectedCategory = category;
                    });
                  },
                ),
              ),
            SizedBox(
              width: cardWidth,
              child: _SuggestCategoryCard(onTap: _showSuggestUnavailable),
            ),
          ],
        );
      },
    );
  }

  Widget _buildFeaturedGuide(
    BuildContext context,
    List<InstructionGuide> guides,
  ) {
    final featuredGuide = _findFeaturedGuide(guides);

    return _FeaturedGuideBanner(
      onStart: featuredGuide == null
          ? _showFeaturedUnavailable
          : () => _openGuide(featuredGuide),
    );
  }

  Widget _buildGuideList(
    BuildContext context,
    String category,
    List<InstructionGuide> guides,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 96),
      itemCount: guides.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final guide = guides[index];

        return Card(
          elevation: 0,
          color: DashboardDesign.surface(context),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(DashboardDesign.radius),
            side: BorderSide(color: DashboardDesign.outline(context)),
          ),
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Icon(
              guide.isRead
                  ? Icons.check_circle_outline
                  : Icons.radio_button_unchecked,
              color: guide.isRead ? DashboardDesign.success : null,
            ),
            title: Text(
              guide.title,
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
            subtitle: Text(
              '${guide.contentSteps.length} steps'
              '${guide.isRead ? ' - Read' : ' - Unread'}',
            ),
            trailing: const Icon(Icons.chevron_right),
            onTap: () => _openGuide(guide),
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final guidesListenable = widget.guidesListenable;
    if (guidesListenable != null) {
      return ValueListenableBuilder<List<InstructionGuide>>(
        valueListenable: guidesListenable,
        builder: (context, guides, _) {
          return _buildScaffold(context, guides);
        },
      );
    }

    return ValueListenableBuilder<Box<InstructionGuide>>(
      valueListenable: widget.repository.getGuidesListenable(),
      builder: (context, box, _) {
        return _buildScaffold(context, box.values.toList());
      },
    );
  }

  Widget _buildScaffold(
    BuildContext context,
    List<InstructionGuide> guides,
  ) {
    final grouped = _groupByCategory(guides);
    final selectedCategory = _selectedCategory;
    final selectedGuides = selectedCategory == null
        ? null
        : grouped[selectedCategory] ?? const <InstructionGuide>[];
    final horizontalPadding = MediaQuery.sizeOf(context).width >= 600
        ? DashboardDesign.marginTablet
        : DashboardDesign.marginMobile;

    return Scaffold(
      backgroundColor: DashboardDesign.background(context),
      appBar: AppBar(
        toolbarHeight: 56,
        backgroundColor: DashboardDesign.surface(context),
        foregroundColor: Theme.of(context).colorScheme.onSurface,
        surfaceTintColor: Colors.transparent,
        elevation: 0,
        leading: IconButton(
          tooltip: selectedCategory == null ? 'Back' : 'Back to categories',
          icon: const Icon(Icons.arrow_back),
          onPressed: _handleBack,
        ),
        titleSpacing: 0,
        title: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            _buildLogoAvatar(),
            const SizedBox(width: 10),
            const Text(
              'Crisync',
              style: TextStyle(fontWeight: FontWeight.w800),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Profile Settings',
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              Navigator.of(context).pushNamed('/profile-settings');
            },
          ),
          const SizedBox(width: 8),
        ],
      ),
      bottomNavigationBar: CrisyncBottomNavigation(
        selectedIndex: null,
        onDestinationSelected: _openTab,
      ),
      body: selectedCategory == null
          ? SafeArea(
              top: false,
              child: SingleChildScrollView(
                padding: EdgeInsets.fromLTRB(
                  horizontalPadding,
                  DashboardDesign.gap,
                  horizontalPadding,
                  96,
                ),
                child: Center(
                  child: ConstrainedBox(
                    constraints: const BoxConstraints(maxWidth: 900),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.stretch,
                      children: [
                        _buildHeader(context),
                        const SizedBox(height: DashboardDesign.sectionGap),
                        _buildCategoryGrid(context, grouped),
                        const SizedBox(height: DashboardDesign.sectionGap),
                        _buildFeaturedGuide(context, guides),
                      ],
                    ),
                  ),
                ),
              ),
            )
          : _buildGuideList(context, selectedCategory, selectedGuides!),
    );
  }
}

class _CategoryCard extends StatelessWidget {
  const _CategoryCard({
    required this.category,
    required this.guides,
    required this.onTap,
  });

  final String category;
  final List<InstructionGuide> guides;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final completedCount = guides.where((guide) => guide.isRead).length;
    final totalCount = guides.length;
    final unreadCount = totalCount - completedCount;
    final progress = totalCount == 0 ? 0.0 : completedCount / totalCount;
    final isComplete = totalCount > 0 && completedCount == totalCount;
    final visual = _CategoryVisual.forCategory(category);

    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        border: Border.all(color: DashboardDesign.outline(context)),
        boxShadow: DashboardDesign.cardShadow(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: IntrinsicHeight(
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                ColoredBox(
                  color: visual.accent,
                  child: const SizedBox(width: 5),
                ),
                Expanded(
                  child: Padding(
                    padding: const EdgeInsets.all(12),
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Container(
                              width: 34,
                              height: 34,
                              decoration: BoxDecoration(
                                color: DashboardDesign.statusBackground(
                                  context,
                                  visual.accent,
                                ),
                                borderRadius: BorderRadius.circular(
                                  DashboardDesign.compactRadius,
                                ),
                              ),
                              child: Icon(
                                visual.icon,
                                color: visual.accent,
                                size: 20,
                              ),
                            ),
                            const Spacer(),
                            if (isComplete)
                              const Icon(
                                Icons.check_circle,
                                color: DashboardDesign.success,
                                size: 19,
                              ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Text(
                          category,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.titleSmall?.copyWith(
                                    fontWeight: FontWeight.w900,
                                    height: 1.12,
                                  ),
                        ),
                        const SizedBox(height: 5),
                        Text(
                          '$totalCount ${totalCount == 1 ? 'guide' : 'guides'}',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: DashboardDesign.mutedText(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                        const SizedBox(height: 10),
                        ClipRRect(
                          borderRadius: BorderRadius.circular(999),
                          child: LinearProgressIndicator(
                            minHeight: 6,
                            value: progress,
                            backgroundColor:
                                DashboardDesign.surfaceVariant(context),
                            valueColor: AlwaysStoppedAnimation<Color>(
                              isComplete
                                  ? DashboardDesign.success
                                  : visual.accent,
                            ),
                          ),
                        ),
                        const SizedBox(height: 7),
                        Text(
                          _progressText(completedCount, totalCount),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: isComplete
                                        ? DashboardDesign.success
                                        : DashboardDesign.mutedText(context),
                                    fontWeight: FontWeight.w800,
                                  ),
                        ),
                        const SizedBox(height: 3),
                        Text(
                          isComplete ? 'All read' : '$unreadCount unread',
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                          style:
                              Theme.of(context).textTheme.bodySmall?.copyWith(
                                    color: DashboardDesign.mutedText(context),
                                    fontWeight: FontWeight.w600,
                                  ),
                        ),
                      ],
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }

  String _progressText(int completedCount, int totalCount) {
    if (totalCount == 0 || completedCount == 0) {
      return 'Not started';
    }
    if (completedCount == totalCount) {
      return 'All completed';
    }
    return '$completedCount of $totalCount read';
  }
}

class _SuggestCategoryCard extends StatelessWidget {
  const _SuggestCategoryCard({required this.onTap});

  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return Container(
      clipBehavior: Clip.antiAlias,
      decoration: BoxDecoration(
        color: DashboardDesign.surface(context),
        borderRadius: BorderRadius.circular(DashboardDesign.radius),
        border: Border.all(color: DashboardDesign.outline(context)),
        boxShadow: DashboardDesign.cardShadow(context),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Container(
                  width: 34,
                  height: 34,
                  decoration: BoxDecoration(
                    color: DashboardDesign.surfaceVariant(context),
                    borderRadius:
                        BorderRadius.circular(DashboardDesign.compactRadius),
                  ),
                  child: Icon(
                    Icons.add_task_outlined,
                    color: DashboardDesign.mutedText(context),
                    size: 20,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  'Suggest Category',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.w900,
                        height: 1.12,
                      ),
                ),
                const SizedBox(height: 5),
                Text(
                  'Request a new guide topic',
                  maxLines: 2,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DashboardDesign.mutedText(context),
                        fontWeight: FontWeight.w600,
                      ),
                ),
                const SizedBox(height: 18),
                Text(
                  'Not available yet',
                  maxLines: 1,
                  overflow: TextOverflow.ellipsis,
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: DashboardDesign.mutedText(context),
                        fontWeight: FontWeight.w800,
                      ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

class _FeaturedGuideBanner extends StatelessWidget {
  const _FeaturedGuideBanner({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final isWide = constraints.maxWidth >= 720;
        final image = _FeaturedGuideImage(isWide: isWide);
        final content = _FeaturedGuideContent(onStart: onStart);

        return Container(
          decoration: BoxDecoration(
            color: DashboardDesign.deepNavy,
            borderRadius: BorderRadius.circular(DashboardDesign.radius),
            boxShadow: DashboardDesign.cardShadow(context),
          ),
          clipBehavior: Clip.antiAlias,
          child: isWide
              ? Row(
                  children: [
                    Expanded(flex: 3, child: content),
                    Expanded(flex: 2, child: image),
                  ],
                )
              : Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    content,
                    image,
                  ],
                ),
        );
      },
    );
  }
}

class _FeaturedGuideContent extends StatelessWidget {
  const _FeaturedGuideContent({required this.onStart});

  final VoidCallback onStart;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(18),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 9, vertical: 6),
            decoration: BoxDecoration(
              color: DashboardDesign.danger.withValues(alpha: 0.16),
              borderRadius: BorderRadius.circular(999),
            ),
            child: const Text(
              'PRIORITY UPDATE',
              style: TextStyle(
                color: Color(0xFFFFDAD6),
                fontSize: 11,
                fontWeight: FontWeight.w900,
              ),
            ),
          ),
          const SizedBox(height: 14),
          Text(
            'Emergency Kit Checklist',
            style: Theme.of(context).textTheme.titleLarge?.copyWith(
                  color: Colors.white,
                  fontWeight: FontWeight.w900,
                ),
          ),
          const SizedBox(height: 8),
          Text(
            'Ensure your family has everything required to survive 72 hours independently. Updated for 2024 standards.',
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: Colors.white.withValues(alpha: 0.82),
                  height: 1.45,
                ),
          ),
          const SizedBox(height: 16),
          FilledButton.icon(
            onPressed: onStart,
            icon: const Icon(Icons.arrow_forward),
            label: const Text('Start Guide'),
            style: FilledButton.styleFrom(
              backgroundColor: Colors.white,
              foregroundColor: DashboardDesign.deepNavy,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(DashboardDesign.radius),
              ),
              textStyle: const TextStyle(fontWeight: FontWeight.w900),
            ),
          ),
        ],
      ),
    );
  }
}

class _FeaturedGuideImage extends StatelessWidget {
  const _FeaturedGuideImage({required this.isWide});

  final bool isWide;

  @override
  Widget build(BuildContext context) {
    final height = isWide ? 240.0 : 180.0;

    return SizedBox(
      height: height,
      child: Padding(
        padding: EdgeInsets.fromLTRB(
          isWide ? 0 : 18,
          isWide ? 18 : 0,
          18,
          18,
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(DashboardDesign.compactRadius),
          child: Image.asset(
            'assets/images/guides/preparedness_guide.png',
            fit: BoxFit.cover,
            errorBuilder: (context, error, stackTrace) {
              return ColoredBox(
                color: Colors.white.withValues(alpha: 0.12),
                child: const Center(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      Icon(
                        Icons.image_not_supported_outlined,
                        color: Colors.white,
                        size: 34,
                      ),
                      SizedBox(height: 8),
                      Text(
                        'Image unavailable',
                        style: TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                    ],
                  ),
                ),
              );
            },
          ),
        ),
      ),
    );
  }
}

class _EmptyGuidesCard extends StatelessWidget {
  const _EmptyGuidesCard();

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
      child: Column(
        children: [
          Icon(
            Icons.menu_book_outlined,
            color: DashboardDesign.mutedText(context),
            size: 40,
          ),
          const SizedBox(height: 12),
          Text(
            'No preparedness guides available.',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
                  color: DashboardDesign.mutedText(context),
                  fontWeight: FontWeight.w700,
                ),
          ),
        ],
      ),
    );
  }
}

class _CategoryVisual {
  const _CategoryVisual({
    required this.icon,
    required this.accent,
  });

  final IconData icon;
  final Color accent;

  static _CategoryVisual forCategory(String category) {
    final normalized = category.toLowerCase();
    if (normalized.contains('typhoon')) {
      return const _CategoryVisual(
        icon: Icons.air,
        accent: DashboardDesign.warning,
      );
    }
    if (normalized.contains('first aid') ||
        normalized.contains('medical') ||
        normalized.contains('health')) {
      return const _CategoryVisual(
        icon: Icons.medical_services_outlined,
        accent: DashboardDesign.success,
      );
    }
    if (normalized.contains('earthquake')) {
      return const _CategoryVisual(
        icon: Icons.warning_amber_rounded,
        accent: DashboardDesign.danger,
      );
    }
    if (normalized.contains('flood')) {
      return const _CategoryVisual(
        icon: Icons.water_drop_outlined,
        accent: DashboardDesign.info,
      );
    }
    if (normalized.contains('evacuation')) {
      return const _CategoryVisual(
        icon: Icons.directions_walk_outlined,
        accent: DashboardDesign.slate,
      );
    }
    if (normalized.contains('family') || normalized.contains('readiness')) {
      return const _CategoryVisual(
        icon: Icons.inventory_2_outlined,
        accent: DashboardDesign.deepNavy,
      );
    }
    return const _CategoryVisual(
      icon: Icons.menu_book_outlined,
      accent: DashboardDesign.info,
    );
  }
}
