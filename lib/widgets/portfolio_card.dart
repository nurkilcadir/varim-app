import 'package:flutter/material.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:varim_app/theme/app_theme.dart';
import 'package:varim_app/theme/design_system.dart';

/// Portfolio card showing bet information with live event data
class PortfolioCard extends StatelessWidget {
  final String title;
  final String position; // 'VARIM' or 'YOKUM'
  final double invested;
  final double potentialWin;
  final String? eventId; // Required for live data
  final double? entryRatio; // Entry probability (from position document)
  final bool isHistory;
  final String? result; // 'Won' or 'Lost' for history
  final VoidCallback? onTap;

  const PortfolioCard({
    super.key,
    required this.title,
    required this.position,
    required this.invested,
    required this.potentialWin,
    this.eventId,
    this.entryRatio,
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

    // For active bets, wrap in StreamBuilder to get live event data
    if (!isHistory && eventId != null) {
      return StreamBuilder<DocumentSnapshot>(
        stream: FirebaseFirestore.instance
            .collection('events')
            .doc(eventId)
            .snapshots(),
        builder: (context, eventSnapshot) {
          // Get live event data
          double? liveYesRatio;
          double? liveNoRatio;
          
          if (eventSnapshot.hasData && eventSnapshot.data!.exists) {
            final eventData = eventSnapshot.data!.data() as Map<String, dynamic>?;
            liveYesRatio = (eventData?['yesRatio'] as num?)?.toDouble();
            liveNoRatio = (eventData?['noRatio'] as num?)?.toDouble();
            
            // If noRatio is not set, calculate it from yesRatio
            if (liveNoRatio == null && liveYesRatio != null) {
              liveNoRatio = 1.0 - liveYesRatio;
            }
          }

          // Calculate current probability based on bet side
          final currentRatio = isVarim ? liveYesRatio : liveNoRatio;
          
          return _buildCardContent(
            context,
            theme,
            varimColors,
            isVarim,
            positionColor,
            textColor,
            currentRatio,
          );
        },
      );
    }

    // For history bets, show static content
    return _buildCardContent(
      context,
      theme,
      varimColors,
      isVarim,
      positionColor,
      textColor,
      null,
    );
  }

  Widget _buildCardContent(
    BuildContext context,
    ThemeData theme,
    VarimColors varimColors,
    bool isVarim,
    Color positionColor,
    Color textColor,
    double? currentRatio,
  ) {
    // Calculate entry percentage
    final entryPercentage = entryRatio != null ? (entryRatio! * 100) : null;
    
    // Calculate current percentage
    final currentPercentage = currentRatio != null ? (currentRatio * 100) : null;

    // Determine color for footer bar based on profit/loss
    // Logic: If current probability is higher than entry, it's profit (green)
    // If current probability is lower than entry, it's loss (red)
    Color footerTextColor = DesignSystem.textBody; // Default to grey
    if (currentPercentage != null && entryPercentage != null) {
      if (currentPercentage > entryPercentage) {
        // Current probability is higher → Profit (Green)
        footerTextColor = DesignSystem.successGreen;
      } else if (currentPercentage < entryPercentage) {
        // Current probability is lower → Loss (Red)
        footerTextColor = DesignSystem.errorRose;
      } else {
        // Equal → Neutral (Grey)
        footerTextColor = DesignSystem.textBody;
      }
    }

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
              color: DesignSystem.surfaceLight,
              borderRadius: BorderRadius.circular(16),
              border: Border.all(
                color: Colors.white.withValues(alpha: 0.1),
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
                              color: DesignSystem.textHeading,
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
                                  color: DesignSystem.textBody,
                                  fontSize: 11,
                                ),
                          ),
                          const SizedBox(height: 4),
                          Text(
                            '${invested.toStringAsFixed(0)} VP',
                            style: theme.textTheme.titleSmall?.copyWith(
                                  color: DesignSystem.textHeading,
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
                                  color: DesignSystem.textBody,
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

                // Footer Bar (ALWAYS show for active bets)
                if (!isHistory) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                    decoration: BoxDecoration(
                      color: DesignSystem.backgroundDeep,
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(
                        color: Colors.white.withValues(alpha: 0.1),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        // Left: Entry Ratio
                        Row(
                          children: [
                            Icon(
                              Icons.trending_up,
                              size: 14,
                              color: DesignSystem.textBody,
                            ),
                            const SizedBox(width: 6),
                            Text(
                              entryPercentage != null
                                  ? 'Giriş Oranı: ${entryPercentage.toStringAsFixed(0)}%'
                                  : 'Giriş Oranı: --',
                              style: theme.textTheme.bodySmall?.copyWith(
                                    color: DesignSystem.textBody,
                                    fontSize: 11,
                                  ),
                            ),
                          ],
                        ),
                        // Right: Current Ratio
                        Text(
                          currentPercentage != null
                              ? 'Güncel: ${currentPercentage.toStringAsFixed(0)}%'
                              : 'Güncel: --',
                          style: theme.textTheme.bodySmall?.copyWith(
                                color: footerTextColor,
                                fontSize: 11,
                                fontWeight: FontWeight.w600,
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

