/// Event model representing a prediction market event
class Event {
  final String id;
  final String title;
  final String description;
  final DateTime endDate;
  final int totalVarimPoints; // Total VP bet on YES
  final int totalYokumPoints; // Total VP bet on NO
  final bool isResolved;
  final bool? outcome; // null if not resolved, true if YES won, false if NO won

  Event({
    required this.id,
    required this.title,
    required this.description,
    required this.endDate,
    this.totalVarimPoints = 0,
    this.totalYokumPoints = 0,
    this.isResolved = false,
    this.outcome,
  });

  /// Total points in the event
  int get totalPoints => totalVarimPoints + totalYokumPoints;

  /// Percentage of points on VARIM (YES)
  double get varimPercentage {
    if (totalPoints == 0) return 0.5; // 50/50 if no bets
    return totalVarimPoints / totalPoints;
  }

  /// Percentage of points on YOKUM (NO)
  double get yokumPercentage {
    if (totalPoints == 0) return 0.5; // 50/50 if no bets
    return totalYokumPoints / totalPoints;
  }

  /// Days remaining until event ends
  int get daysRemaining {
    final now = DateTime.now();
    final difference = endDate.difference(now);
    return difference.inDays;
  }

  /// Hours remaining until event ends
  int get hoursRemaining {
    final now = DateTime.now();
    final difference = endDate.difference(now);
    return difference.inHours;
  }

  /// Check if event is active (not resolved and not expired)
  bool get isActive => !isResolved && DateTime.now().isBefore(endDate);
}

