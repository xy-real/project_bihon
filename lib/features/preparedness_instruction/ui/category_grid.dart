import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';
import 'package:hive_flutter/hive_flutter.dart';
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

  void _openGuide(InstructionGuide guide) {
    Navigator.of(context).pushNamed(
      PreparednessGuideViewerPage.routeName,
      arguments: guide.id,
    );
  }

  Widget _buildCategoryGrid(
    BuildContext context,
    Map<String, List<InstructionGuide>> grouped,
  ) {
    final categories = grouped.keys.toList()..sort();

    if (categories.isEmpty) {
      return const Center(child: Text('No preparedness guides available.'));
    }

    return LayoutBuilder(
      builder: (context, constraints) {
        final width = constraints.maxWidth;
        final columns = width >= 1000 ? 3 : width >= 640 ? 2 : 1;
        final gap = 12.0;
        final cardWidth = (width - (gap * (columns - 1))) / columns;

        return SingleChildScrollView(
          padding: const EdgeInsets.all(16),
          child: Wrap(
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
            ],
          ),
        );
      },
    );
  }

  Widget _buildGuideList(
    BuildContext context,
    String category,
    List<InstructionGuide> guides,
  ) {
    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      itemCount: guides.length,
      separatorBuilder: (_, _) => const SizedBox(height: 10),
      itemBuilder: (context, index) {
        final guide = guides[index];

        return Card(
          child: ListTile(
            contentPadding: const EdgeInsets.symmetric(
              horizontal: 16,
              vertical: 8,
            ),
            leading: Icon(
              guide.isRead
                  ? Icons.check_circle_outline
                  : Icons.radio_button_unchecked,
              color: guide.isRead ? Colors.green.shade700 : null,
            ),
            title: Text(guide.title),
            subtitle: Text(
              '${guide.contentSteps.length} steps'
              '${guide.isRead ? ' • Read' : ' • Unread'}',
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

    return Scaffold(
      appBar: AppBar(
        title: Text(selectedCategory ?? 'Preparedness Guides'),
        leading: selectedCategory == null
            ? null
            : IconButton(
                tooltip: 'Back to categories',
                onPressed: () {
                  setState(() {
                    _selectedCategory = null;
                  });
                },
                icon: const Icon(Icons.arrow_back),
              ),
      ),
      body: selectedCategory == null
          ? _buildCategoryGrid(context, grouped)
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
    final unreadCount = guides.where((guide) => !guide.isRead).length;
    final totalCount = guides.length;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  const Icon(Icons.menu_book_outlined),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      category,
                      style: Theme.of(context).textTheme.titleMedium,
                    ),
                  ),
                  const Icon(Icons.chevron_right),
                ],
              ),
              const SizedBox(height: 14),
              Text(
                '$totalCount ${totalCount == 1 ? 'guide' : 'guides'}',
                style: Theme.of(context).textTheme.bodyMedium,
              ),
              const SizedBox(height: 4),
              Text(
                unreadCount == 0
                    ? 'All read'
                    : '$unreadCount unread',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                      color: unreadCount == 0
                          ? Colors.green.shade700
                          : Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w600,
                    ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
