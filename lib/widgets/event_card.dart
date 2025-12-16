import 'package:flutter/material.dart';
import 'package:varim_app/models/event.dart';
import 'package:varim_app/widgets/parimutuel_chart.dart';
import 'package:varim_app/theme/app_theme.dart';

/// Event card widget displaying event information and parimutuel chart
class EventCard extends StatelessWidget {
  final Event event;
  final VoidCallback? onTap;

  const EventCard({
    super.key,
    required this.event,
    this.onTap,
  });

  String _formatTimeRemaining() {
    if (event.daysRemaining > 0) {
      return '${event.daysRemaining}d remaining';
    } else if (event.hoursRemaining > 0) {
      return '${event.hoursRemaining}h remaining';
    } else {
      return 'Ending soon';
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final varimColors = AppTheme.varimColors(context);
    
    return Card(
      margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Header: Title and Status
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: Text(
                      event.title,
                      style: Theme.of(context).textTheme.titleLarge,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ),
                  const SizedBox(width: 8),
                  // Status Badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 4,
                    ),
                    decoration: BoxDecoration(
                      color: event.isResolved
                          ? theme.colorScheme.surfaceContainerHighest
                          : event.isActive
                              ? varimColors.varimColor.withValues(alpha: 0.2)
                              : theme.colorScheme.error.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(6),
                    ),
                    child: Text(
                      event.isResolved
                          ? 'Resolved'
                          : event.isActive
                              ? 'Active'
                              : 'Expired',
                      style: theme.textTheme.bodySmall?.copyWith(
                            color: event.isResolved
                                ? theme.colorScheme.onSurfaceVariant
                                : event.isActive
                                    ? varimColors.varimColor
                                    : theme.colorScheme.error,
                            fontWeight: FontWeight.w600,
                            fontSize: 10,
                          ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 8),
              
              // Description
              Text(
                event.description,
                style: Theme.of(context).textTheme.bodyMedium,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
              const SizedBox(height: 16),
              
              // Parimutuel Chart
              ParimutuelChart(
                varimPercentage: event.varimPercentage,
                yokumPercentage: event.yokumPercentage,
                totalVarimPoints: event.totalVarimPoints,
                totalYokumPoints: event.totalYokumPoints,
              ),
              const SizedBox(height: 16),
              
              // Footer: Time and Total Points
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  // Time remaining
                  Row(
                    children: [
                      Icon(
                        Icons.access_time,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        _formatTimeRemaining(),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ),
                  // Total points
                  Row(
                    children: [
                      Icon(
                        Icons.attach_money,
                        size: 16,
                        color: theme.colorScheme.onSurfaceVariant,
                      ),
                      const SizedBox(width: 4),
                      Text(
                        '${event.totalPoints} VP',
                        style: Theme.of(context).textTheme.bodySmall?.copyWith(
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ],
              ),
              
              // Outcome indicator (if resolved)
              if (event.isResolved && event.outcome != null) ...[
                const SizedBox(height: 12),
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: event.outcome!
                        ? varimColors.varimColor.withValues(alpha: 0.2)
                        : varimColors.yokumColor.withValues(alpha: 0.2),
                    borderRadius: BorderRadius.circular(8),
                  ),
                  child: Row(
                    children: [
                      Icon(
                        event.outcome! ? Icons.check_circle : Icons.cancel,
                        size: 16,
                        color: event.outcome!
                            ? varimColors.varimColor
                            : varimColors.yokumColor,
                      ),
                      const SizedBox(width: 8),
                      Text(
                        event.outcome!
                            ? 'VARIM (YES) won!'
                            : 'YOKUM (NO) won!',
                        style: theme.textTheme.bodySmall?.copyWith(
                              color: event.outcome!
                                  ? varimColors.varimColor
                                  : varimColors.yokumColor,
                              fontWeight: FontWeight.w600,
                            ),
                      ),
                    ],
                  ),
                ),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

