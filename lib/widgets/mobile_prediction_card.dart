import 'package:flutter/material.dart';
import 'package:varim_app/theme/app_theme.dart';

/// Mobile-first prediction card matching Kalshi-style layout
class MobilePredictionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final double varimPercentage; // 0.0 to 1.0 (YES percentage)
  final double yokumPercentage; // 0.0 to 1.0 (NO percentage)
  final int poolSize; // Total virtual points in the pool
  final VoidCallback? onVarimTap;
  final VoidCallback? onYokumTap;
  final VoidCallback? onCardTap;

  const MobilePredictionCard({
    super.key,
    required this.title,
    this.icon,
    required this.varimPercentage,
    required this.yokumPercentage,
    required this.poolSize,
    this.onVarimTap,
    this.onYokumTap,
    this.onCardTap,
  });

  String _formatPoolSize(int size) {
    if (size >= 1000000) {
      return '${(size / 1000000).toStringAsFixed(1)}M';
    } else if (size >= 1000) {
      return '${(size / 1000).toStringAsFixed(0)}K';
    }
    return size.toString();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final varimColors = AppTheme.varimColors(context);
    
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: theme.colorScheme.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
          width: 1,
        ),
      ),
      child: InkWell(
        onTap: onCardTap,
        borderRadius: BorderRadius.circular(16),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Row 1: Icon + Title
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                if (icon != null) ...[
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Icon(
                      icon,
                      size: 20,
                      color: theme.colorScheme.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(width: 12),
                ],
                Expanded(
                  child: Text(
                    title,
                    style: theme.textTheme.titleMedium?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: theme.colorScheme.onSurface,
                          height: 1.3,
                        ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),

            // Row 2: Two Large Buttons - Full Width with Gap
            Row(
              children: [
                // Left Button - VARIM (proportional width based on percentage)
                Expanded(
                  flex: (varimPercentage * 100).round().clamp(1, 100),
                  child: _BetButton(
                    label: 'VARIM',
                    percentage: (varimPercentage * 100).toStringAsFixed(0),
                    color: varimColors.varimColor,
                    textColor: theme.colorScheme.onPrimary,
                    onTap: onVarimTap,
                  ),
                ),
                const SizedBox(width: 8), // Gap between buttons
                // Right Button - YOKUM (proportional width based on percentage)
                Expanded(
                  flex: (yokumPercentage * 100).round().clamp(1, 100),
                  child: _BetButton(
                    label: 'YOKUM',
                    percentage: (yokumPercentage * 100).toStringAsFixed(0),
                    color: varimColors.yokumColor,
                    textColor: theme.colorScheme.onSecondary,
                    onTap: onYokumTap,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 12),

            // Row 3: Meta - Pool Size
            Text(
              'Pool: ${_formatPoolSize(poolSize)} VP',
              style: theme.textTheme.bodySmall?.copyWith(
                    color: theme.colorScheme.onSurfaceVariant,
                    fontSize: 12,
                  ),
            ),
          ],
        ),
      ),
    );
  }
}

/// Bet button widget with neon styling
class _BetButton extends StatelessWidget {
  final String label;
  final String percentage;
  final Color color;
  final Color textColor;
  final VoidCallback? onTap;

  const _BetButton({
    required this.label,
    required this.percentage,
    required this.color,
    required this.textColor,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(12),
          child: Container(
          padding: const EdgeInsets.symmetric(vertical: 18, horizontal: 12),
          decoration: BoxDecoration(
            color: color,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: color.withValues(alpha: 0.4),
                blurRadius: 12,
                spreadRadius: 1,
              ),
            ],
          ),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                label,
                style: TextStyle(
                  color: textColor,
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  letterSpacing: 0.8,
                ),
              ),
              const SizedBox(height: 6),
              Text(
                '$percentage%',
                style: TextStyle(
                  color: textColor.withValues(alpha: 0.95),
                  fontSize: 15,
                  fontWeight: FontWeight.w800,
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

