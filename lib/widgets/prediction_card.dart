import 'package:flutter/material.dart';
import 'package:varim_app/theme/app_theme.dart';

/// Premium prediction card widget with enhanced visual design
class PredictionCard extends StatelessWidget {
  final String title;
  final double varimPercentage; // 0.0 to 1.0 (YES percentage)
  final double yokumPercentage; // 0.0 to 1.0 (NO percentage)
  final int poolSize; // Total virtual points in the pool
  final String? timeLabel; // e.g., "Son 24 Saat"
  final VoidCallback? onTap;

  const PredictionCard({
    super.key,
    required this.title,
    required this.varimPercentage,
    required this.yokumPercentage,
    required this.poolSize,
    this.timeLabel = 'Son 24 Saat',
    this.onTap,
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
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 10),
      decoration: BoxDecoration(
        color: theme.colorScheme.surfaceContainer, // Darker card background
        borderRadius: BorderRadius.circular(24), // More rounded
        boxShadow: [
          // Outer shadow
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.5),
            blurRadius: 16,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
          // Subtle neon glow effect
          BoxShadow(
            color: varimColors.varimColor.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 0),
            spreadRadius: -2,
          ),
          BoxShadow(
            color: varimColors.yokumColor.withValues(alpha: 0.08),
            blurRadius: 24,
            offset: const Offset(0, 0),
            spreadRadius: -2,
          ),
        ],
        border: Border.all(
          color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.15),
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(24),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header Row: Title and Time Label
                Row(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Title
                    Expanded(
                      child: Text(
                        title,
                        style: Theme.of(context).textTheme.titleLarge?.copyWith(
                              fontWeight: FontWeight.w700,
                              height: 1.3,
                              letterSpacing: -0.5,
                              fontSize: 18,
                            ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                    ),
                    const SizedBox(width: 12),
                    // Time Label with Clock Icon
                    Container(
                      padding: const EdgeInsets.symmetric(
                        horizontal: 10,
                        vertical: 6,
                      ),
                    decoration: BoxDecoration(
                      color: theme.colorScheme.surfaceContainerHighest.withValues(alpha: 0.3),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Icon(
                          Icons.access_time,
                          size: 14,
                          color: theme.colorScheme.onSurfaceVariant,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          timeLabel ?? 'Son 24 Saat',
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: theme.colorScheme.onSurfaceVariant,
                                fontSize: 11,
                                fontWeight: FontWeight.w500,
                              ),
                        ),
                      ],
                    ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                
                // Premium Glowing Neon Bar Chart
                _PremiumNeonBarChart(
                  varimPercentage: varimPercentage,
                  yokumPercentage: yokumPercentage,
                ),
                const SizedBox(height: 18),
                
                // Pool Size Footer with Person Icon
                Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(
                      Icons.person,
                      size: 16,
                      color: theme.colorScheme.onSurfaceVariant.withValues(alpha: 0.7),
                    ),
                    const SizedBox(width: 6),
                    Text(
                      'Havuz: ',
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: theme.colorScheme.onSurfaceVariant,
                            fontSize: 13,
                            fontWeight: FontWeight.w500,
                          ),
                    ),
                    Text(
                      '${_formatPoolSize(poolSize)} VP',
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: varimColors.varimColor,
                            fontWeight: FontWeight.w700,
                            fontSize: 13,
                            letterSpacing: 0.5,
                          ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

/// Premium glowing neon bar chart with enhanced visual design
class _PremiumNeonBarChart extends StatelessWidget {
  final double varimPercentage;
  final double yokumPercentage;

  const _PremiumNeonBarChart({
    required this.varimPercentage,
    required this.yokumPercentage,
  });

  @override
  Widget build(BuildContext context) {
    final varimColors = AppTheme.varimColors(context);
    final theme = Theme.of(context);
    
    return Container(
      height: 52,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(14),
        boxShadow: [
          BoxShadow(
            color: theme.colorScheme.shadow.withValues(alpha: 0.6),
            blurRadius: 12,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      clipBehavior: Clip.antiAlias,
      child: Row(
        children: [
          // VARIM (YES) section with neon glow
          Expanded(
            flex: (varimPercentage * 100).round().clamp(1, 100),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    varimColors.varimColor,
                    varimColors.varimColor.withValues(alpha: 0.9),
                    varimColors.varimColor.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  // Inner glow
                  BoxShadow(
                    color: varimColors.varimColor.withValues(alpha: 0.6),
                    blurRadius: 16,
                    spreadRadius: -4,
                  ),
                  // Outer glow
                  BoxShadow(
                    color: varimColors.varimColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: varimPercentage > 0.12
                  ? Center(
                      child: Text(
                        'VARIM %${(varimPercentage * 100).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.black,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.8,
                          shadows: [
                            Shadow(
                              color: Colors.black26,
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
            ),
          ),
          // YOKUM (NO) section with neon glow
          Expanded(
            flex: (yokumPercentage * 100).round().clamp(1, 100),
            child: Container(
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                  colors: [
                    varimColors.yokumColor,
                    varimColors.yokumColor.withValues(alpha: 0.9),
                    varimColors.yokumColor.withValues(alpha: 0.85),
                  ],
                  stops: const [0.0, 0.5, 1.0],
                ),
                boxShadow: [
                  // Inner glow
                  BoxShadow(
                    color: varimColors.yokumColor.withValues(alpha: 0.6),
                    blurRadius: 16,
                    spreadRadius: -4,
                  ),
                  // Outer glow
                  BoxShadow(
                    color: varimColors.yokumColor.withValues(alpha: 0.3),
                    blurRadius: 20,
                    spreadRadius: 2,
                  ),
                ],
              ),
              child: yokumPercentage > 0.12
                  ? Center(
                      child: Text(
                        'YOKUM %${(yokumPercentage * 100).toStringAsFixed(0)}',
                        style: const TextStyle(
                          color: Colors.white,
                          fontWeight: FontWeight.w900,
                          fontSize: 14,
                          letterSpacing: 0.8,
                          shadows: [
                            Shadow(
                              color: Colors.black54,
                              blurRadius: 2,
                            ),
                          ],
                        ),
                      ),
                    )
                  : null,
            ),
          ),
        ],
      ),
    );
  }
}
