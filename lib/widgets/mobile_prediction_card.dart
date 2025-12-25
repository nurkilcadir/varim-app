import 'package:flutter/material.dart';
import 'package:varim_app/theme/design_system.dart';

/// Compact financial-style prediction card
class MobilePredictionCard extends StatelessWidget {
  final String title;
  final IconData? icon;
  final double varimPercentage; // 0.0 to 1.0 (YES percentage)
  final double yokumPercentage; // 0.0 to 1.0 (NO percentage)
  final int poolSize; // Total virtual points in the pool
  final int volume; // Volume for trend badge
  final double yesRatio; // Yes ratio for opportunity badge
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
    this.volume = 0,
    this.yesRatio = 1.85,
    this.onVarimTap,
    this.onYokumTap,
    this.onCardTap,
  });

  String _formatVolume(int size) {
    if (size >= 1000000) {
      return '${(size / 1000000).toStringAsFixed(1)}M';
    } else if (size >= 1000) {
      final thousands = size / 1000;
      // Show decimal if not a whole number (e.g., 12.5K for 12500, but 12K for 12000)
      if (thousands == thousands.truncateToDouble()) {
        return '${thousands.toInt()}K';
      } else {
        return '${thousands.toStringAsFixed(1)}K';
      }
    }
    return size.toString();
  }

  @override
  Widget build(BuildContext context) {
    // Calculate percentages for button labels
    final yesPercent = (varimPercentage * 100).toInt();
    final noPercent = 100 - yesPercent;

    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      decoration: BoxDecoration(
        color: DesignSystem.surfaceLight,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: DesignSystem.border,
          width: 1,
        ),
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onCardTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.center,
              children: [
                // Left: Image/Icon (40x40) with badges
                Stack(
                  clipBehavior: Clip.none,
                  children: [
                    Container(
                      width: 40,
                      height: 40,
                      decoration: BoxDecoration(
                        color: DesignSystem.backgroundDeep,
                        borderRadius: BorderRadius.circular(8),
                        border: Border.all(
                          color: DesignSystem.border,
                          width: 1,
                        ),
                      ),
                      child: icon != null
                          ? Icon(
                              icon,
                              size: 24,
                              color: DesignSystem.primaryAccent,
                            )
                          : const Icon(
                              Icons.trending_up,
                              size: 24,
                              color: DesignSystem.primaryAccent,
                            ),
                    ),
                    // Badge with strict priority: TREND (Elite) > FIRSAT (High Opportunity) > None
                    if (volume > 50000)
                      // 🔥 TREND Badge (Elite Only: Very High Volume)
                      Positioned(
                        left: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.orange.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.orange,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.orange.withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: const Text(
                            '🔥 TREND',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      )
                    else if ((yesRatio >= 0.80 || yesRatio <= 0.20) && volume < 50000)
                      // ⚡ FIRSAT Badge (High Opportunity: Extreme Ratio, Not Already Trending)
                      Positioned(
                        left: -4,
                        top: -4,
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 2),
                          decoration: BoxDecoration(
                            color: Colors.purple.withValues(alpha: 0.9),
                            borderRadius: BorderRadius.circular(4),
                            border: Border.all(
                              color: Colors.purple,
                              width: 1,
                            ),
                            boxShadow: [
                              BoxShadow(
                                color: Colors.purple.withValues(alpha: 0.5),
                                blurRadius: 4,
                                spreadRadius: 0,
                              ),
                            ],
                          ),
                          child: const Text(
                            '⚡ FIRSAT',
                            style: TextStyle(
                              color: Colors.white,
                              fontSize: 8,
                              fontWeight: FontWeight.w900,
                              letterSpacing: 0.5,
                            ),
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(width: 12),

                // Middle: Title + Volume/Sparkline
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      // Title
                      Text(
                        title,
                        style: const TextStyle(
                          color: DesignSystem.textHeading,
                          fontSize: 14,
                          fontWeight: FontWeight.w600,
                          height: 1.3,
                        ),
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                      ),
                      const SizedBox(height: 4),
                      // Volume + Sparkline
                      Row(
                        children: [
                          // Volume icon
                          const Icon(
                            Icons.bar_chart,
                            size: 14,
                            color: DesignSystem.textBody,
                          ),
                          const SizedBox(width: 4),
                          Text(
                            'Hacim: ${_formatVolume(poolSize)} VP',
                            style: const TextStyle(
                              color: DesignSystem.textBody,
                              fontSize: 12,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
                const SizedBox(width: 8),

                // Right: Compact Pill Buttons (Side-by-Side)
                Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    // Evet Pill
                    _CompactPillButton(
                      label: 'Evet\n$yesPercent%',
                      color: DesignSystem.successGreen,
                      onTap: onVarimTap,
                    ),
                    const SizedBox(width: 6),
                    // Hayır Pill
                    _CompactPillButton(
                      label: 'Hayır\n$noPercent%',
                      color: DesignSystem.errorRose,
                      onTap: onYokumTap,
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

/// Compact pill-shaped button for Evet/Hayır actions
class _CompactPillButton extends StatelessWidget {
  final String label;
  final Color color;
  final VoidCallback? onTap;

  const _CompactPillButton({
    required this.label,
    required this.color,
    this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(8),
        child: Container(
          width: 62,
          height: 46,
          padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 6),
          decoration: BoxDecoration(
            color: color.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
            border: Border.all(
              color: color,
              width: 1.5,
            ),
          ),
          child: Center(
            child: Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                color: color,
                fontSize: 11,
                fontWeight: FontWeight.w600,
                letterSpacing: 0.2,
                height: 1.2,
              ),
            ),
          ),
        ),
      ),
    );
  }
}
