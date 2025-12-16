import 'package:flutter/material.dart';
import 'package:varim_app/theme/app_theme.dart';

/// Horizontal scrollable category chips
class CategoryChips extends StatefulWidget {
  final Function(String)? onCategorySelected;

  const CategoryChips({
    super.key,
    this.onCategorySelected,
  });

  @override
  State<CategoryChips> createState() => _CategoryChipsState();
}

class _CategoryChipsState extends State<CategoryChips> {
  String _selectedCategory = 'Trending';

  final List<String> _categories = [
    'Trending',
    'New',
    'Politics',
    'Sports',
    'Culture',
    'Crypto',
    'Climate',
    'Economy',
  ];

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final varimColors = AppTheme.varimColors(context);
    
    return Container(
      height: 50,
      padding: const EdgeInsets.symmetric(vertical: 8),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category;
              });
              widget.onCategorySelected?.call(category);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 8),
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? varimColors.varimColor.withValues(alpha: 0.2)
                    : theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                borderRadius: BorderRadius.circular(20),
                border: isSelected
                    ? Border.all(
                        color: varimColors.varimColor.withValues(alpha: 0.6),
                        width: 1.5,
                      )
                    : null,
              ),
              child: Center(
                child: Text(
                  category,
                  style: TextStyle(
                    color: isSelected
                        ? varimColors.varimColor
                        : theme.colorScheme.onSurfaceVariant,
                    fontSize: 14,
                    fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                  ),
                ),
              ),
            ),
          );
        },
      ),
    );
  }
}

