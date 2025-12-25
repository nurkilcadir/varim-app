import 'package:flutter/material.dart';

class Category {
  final String id;
  final String label;
  final IconData icon;
  final Color glowColor;

  const Category({
    required this.id,
    required this.label,
    required this.icon,
    required this.glowColor,
  });
}

/// Horizontal category filter bar with glow effects
class CategoryFilter extends StatefulWidget {
  final Function(String)? onCategorySelected;

  const CategoryFilter({
    super.key,
    this.onCategorySelected,
  });

  @override
  State<CategoryFilter> createState() => _CategoryFilterState();
}

class _CategoryFilterState extends State<CategoryFilter> {
  String _selectedCategory = 'trend';

  final List<Category> _categories = const [
    Category(
      id: 'trend',
      label: 'Trend',
      icon: Icons.local_fire_department,
      glowColor: Color(0xFFFF6B35), // Orange
    ),
    Category(
      id: 'ekonomi',
      label: 'Ekonomi',
      icon: Icons.account_balance_wallet,
      glowColor: Color(0xFFFFD700), // Gold/Yellow
    ),
    Category(
      id: 'spor',
      label: 'Spor',
      icon: Icons.sports_soccer,
      glowColor: Color(0xFF00FF94), // Green
    ),
    Category(
      id: 'tv_magazin',
      label: 'TV & Magazin',
      icon: Icons.tv,
      glowColor: Color(0xFFFF0055), // Pink
    ),
  ];

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(vertical: 12),
      child: ListView.builder(
        scrollDirection: Axis.horizontal,
        padding: const EdgeInsets.symmetric(horizontal: 16),
        itemCount: _categories.length,
        itemBuilder: (context, index) {
          final category = _categories[index];
          final isSelected = _selectedCategory == category.id;

          return GestureDetector(
            onTap: () {
              setState(() {
                _selectedCategory = category.id;
              });
              widget.onCategorySelected?.call(category.id);
            },
            child: Container(
              margin: const EdgeInsets.only(right: 16),
              child: Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  // Icon with glow effect
                  Container(
                    width: 44,
                    height: 44,
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: isSelected
                          ? category.glowColor.withValues(alpha: 0.2)
                          : Theme.of(context).colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      boxShadow: isSelected
                          ? [
                              BoxShadow(
                                color: category.glowColor.withValues(alpha: 0.5),
                                blurRadius: 12,
                                spreadRadius: 2,
                              ),
                            ]
                          : null,
                      border: isSelected
                          ? Border.all(
                              color: category.glowColor.withValues(alpha: 0.6),
                              width: 2,
                            )
                          : null,
                    ),
                    child: Icon(
                      category.icon,
                      color: isSelected
                          ? category.glowColor
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      size: 24,
                    ),
                  ),
                  const SizedBox(height: 6),
                  // Label
                  Text(
                    category.label,
                    style: TextStyle(
                      color: isSelected
                          ? category.glowColor
                          : Theme.of(context).colorScheme.onSurfaceVariant,
                      fontSize: 12,
                      fontWeight: isSelected ? FontWeight.w700 : FontWeight.w500,
                    ),
                  ),
                ],
              ),
            ),
          );
        },
      ),
    );
  }
}

