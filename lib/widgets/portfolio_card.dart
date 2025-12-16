import 'package:flutter/material.dart';
import 'package:varim_app/theme/app_theme.dart';

/// Portfolio card showing bet information
class PortfolioCard extends StatelessWidget {
  final String title;
  final String position; // 'VARIM' or 'YOKUM'
  final double invested;
  final double potentialWin;
  final double? currentOdds;
  final bool isHistory;
  final String? result; // 'Won' or 'Lost' for history
  final VoidCallback? onTap;

  const PortfolioCard({
    super.key,
    required this.title,
    required this.position,
    required this.invested,
    required this.potentialWin,
    this.currentOdds,
    this.isHistory = false,
    this.result,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final varimColors = AppTheme.varimColors(context);
    final isVarim = position == 'VARIM';
    final positionColor = isVarim ? varimColors.varimColor : varimColors.yokumColor;
    final textColor = isVarim ? Colors.black : Colors.white;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(16),
          child: Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: theme.colorScheme.surfaceContainer,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.2),
                width: 1,
              ),
            ),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Title Row
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
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
                    const SizedBox(width: 12),
                    // Position Badge
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 6,
                      ),
                      decoration: BoxDecoration(
                        color: positionColor,
                        borderRadius: BorderRadius.circular(12),
                        boxShadow: [
                          BoxShadow(
                            color: positionColor.withValues(alpha: 0.3),
                            blurRadius: 8,
                            spreadRadius: 0,
                          ),
                        ],
                      ),
                      child: Text(
                        position,
                        style: TextStyle(
                          color: textColor,
                          fontSize: 12,
                          fontWeight: FontWeight.w800,
                          letterSpacing: 0.5,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 16),

                // Stats Row
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    // Invested
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            'Yatırılan',
                            style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${invested.toStringAsFixed(0)} VP',
                            style: theme.textTheme.titleSmall?.copyWith(
                                  color: theme.colorScheme.onSurface,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                    // Potential Win / Payout
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.end,
                        children: [
                          Text(
                            isHistory
                                ? (result == 'Won' ? 'Kazanç' : 'Kayıp')
                                : 'Potansiyel Kazanç',
                            style: theme.textTheme.bodySmall?.copyWith(
                                  color: theme.colorScheme.onSurfaceVariant,
                                  fontSize: 11,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${potentialWin.toStringAsFixed(0)} VP',
                            style: theme.textTheme.titleSmall?.copyWith(
                                  color: isHistory && result == 'Won'
                                      ? varimColors.varimColor
                                      : isHistory && result == 'Lost'
                                          ? varimColors.yokumColor
                                          : varimColors.varimColor,
                                  fontWeight: FontWeight.w700,
                                ),
                          ),
                        ],
                      ),
                    ),
                  ],
                ),

                // Current Odds (for active bets)
                if (!isHistory && currentOdds != null) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Icon(
                          Icons.trending_up,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'Güncel Oran: ${(currentOdds! * 100).toStringAsFixed(0)}%',
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                              ),
                        ),
                      ],
                    ),
                  ),
                ],

                // Result Badge (for history)
                if (isHistory && result != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    children: [
                      Icon(
                        result == 'Won' ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: result == 'Won'
                            ? varimColors.varimColor
                            : varimColors.yokumColor,
                      ),
                      const SizedBox(width: 6),
                      Text(
                        result == 'Won' ? 'Kazandınız!' : 'Kaybettiniz',
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: result == 'Won'
                                  ? varimColors.varimColor
                                  : varimColors.yokumColor,
                              fontWeight: FontWeight.w700,
                              fontSize: 12,
                            ),
                      ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }
}

