import 'package:flutter/material.dart';
import 'package:varim_app/theme/app_theme.dart';

/// Parimutuel bar chart showing YES vs NO ratio
class ParimutuelChart extends StatelessWidget {
  final double varimPercentage; // 0.0 to 1.0
  final double yokumPercentage; // 0.0 to 1.0
  final int totalVarimPoints;
  final int totalYokumPoints;
  final double height;

  const ParimutuelChart({
    super.key,
    required this.varimPercentage,
    required this.yokumPercentage,
    required this.totalVarimPoints,
    required this.totalYokumPoints,
    this.height = 40,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final varimColors = AppTheme.varimColors(context);
    
    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        // Bar Chart
        Container(
          height: height,
          decoration: BoxDecoration(
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: theme.colorScheme.surfaceContainerHighest,
              width: 1,
            ),
          ),
          clipBehavior: Clip.antiAlias,
          child: Row(
            children: [
              // VARIM (YES) section
              Expanded(
                flex: (varimPercentage * 100).round().clamp(1, 100),
                child: Container(
                  color: varimColors.varimColor,
                  child: varimPercentage > 0.1
                      ? Center(
                          child: Text(
                            'VARIM',
                            style: TextStyle(
                              color: Colors.black,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
              // YOKUM (NO) section
              Expanded(
                flex: (yokumPercentage * 100).round().clamp(1, 100),
                child: Container(
                  color: varimColors.yokumColor,
                  child: yokumPercentage > 0.1
                      ? Center(
                          child: Text(
                            'YOKUM',
                            style: TextStyle(
                              color: Colors.white,
                              fontWeight: FontWeight.bold,
                              fontSize: 12,
                            ),
                          ),
                        )
                      : null,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 8),
        // Stats Row
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            // VARIM stats
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: varimColors.varimColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'VARIM',
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: varimColors.varimColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          '${(varimPercentage * 100).toStringAsFixed(1)}% • $totalVarimPoints VP',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            const SizedBox(width: 16),
            // YOKUM stats
            Expanded(
              child: Row(
                children: [
                  Container(
                    width: 12,
                    height: 12,
                    decoration: BoxDecoration(
                      color: varimColors.yokumColor,
                      shape: BoxShape.circle,
                    ),
                  ),
                  const SizedBox(width: 6),
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'YOKUM',
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: varimColors.yokumColor,
                                fontWeight: FontWeight.w600,
                              ),
                        ),
                        Text(
                          '${(yokumPercentage * 100).toStringAsFixed(1)}% • $totalYokumPoints VP',
                          style: Theme.of(context).textTheme.bodySmall,
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ],
    );
  }
}

