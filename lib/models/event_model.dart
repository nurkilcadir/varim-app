import 'package:cloud_firestore/cloud_firestore.dart';

/// Event model for Firestore events collection
class EventModel {
  final String id;
  final String title;
  final String category; // e.g., 'Spor', 'Siyaset'
  final String imageUrl;
  final double yesRatio; // e.g., 1.85
  final double noRatio; // e.g., 1.85
  final Timestamp endDate;
  final int volume; // Total money bet
  final String? rule; // Settlement rule/source of truth

  EventModel({
    required this.id,
    required this.title,
    required this.category,
    required this.imageUrl,
    required this.yesRatio,
    required this.noRatio,
    required this.endDate,
    required this.volume,
    this.rule,
  });

  /// Create EventModel from Firestore document
  factory EventModel.fromMap(Map<String, dynamic> map, String id) {
    return EventModel(
      id: id,
      title: map['title'] as String? ?? '',
      category: map['category'] as String? ?? 'Genel',
      imageUrl: map['imageUrl'] as String? ?? '',
      yesRatio: (map['yesRatio'] as num?)?.toDouble() ?? 1.85,
      noRatio: (map['noRatio'] as num?)?.toDouble() ?? 1.85,
      endDate: map['endDate'] as Timestamp? ?? Timestamp.now(),
      volume: (map['volume'] as num?)?.toInt() ?? 0,
      rule: map['rule'] as String?,
    );
  }

  /// Convert EventModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'title': title,
      'category': category,
      'imageUrl': imageUrl,
      'yesRatio': yesRatio,
      'noRatio': noRatio,
      'endDate': endDate,
      'volume': volume,
      if (rule != null) 'rule': rule,
    };
  }

  /// Calculate VARIM percentage from yesRatio
  /// If yesRatio is 1.85, that means 1.85x return, so implied probability is 1/1.85
  /// We normalize so that varimPercentage + yokumPercentage = 1.0
  double get varimPercentage {
    if (yesRatio <= 0 || noRatio <= 0) return 0.5;
    final yesImplied = 1.0 / yesRatio;
    final noImplied = 1.0 / noRatio;
    final total = yesImplied + noImplied;
    return total > 0 ? yesImplied / total : 0.5;
  }

  /// Calculate YOKUM percentage from noRatio
  /// If noRatio is 1.85, that means 1.85x return, so implied probability is 1/1.85
  /// We normalize so that varimPercentage + yokumPercentage = 1.0
  double get yokumPercentage {
    if (yesRatio <= 0 || noRatio <= 0) return 0.5;
    final yesImplied = 1.0 / yesRatio;
    final noImplied = 1.0 / noRatio;
    final total = yesImplied + noImplied;
    return total > 0 ? noImplied / total : 0.5;
  }

  /// Get pool size (same as volume)
  int get poolSize => volume;
}
