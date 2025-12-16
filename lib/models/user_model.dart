import 'package:flutter/foundation.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

/// User model for Firestore
class UserModel {
  final String uid;
  final String email;
  final String username;
  final int balance;
  final DateTime createdAt;
  final String role;

  UserModel({
    required this.uid,
    required this.email,
    required this.username,
    required this.balance,
    required this.createdAt,
    this.role = 'user',
  });

  /// Convert UserModel to Map for Firestore
  Map<String, dynamic> toMap() {
    return {
      'uid': uid,
      'email': email,
      'username': username,
      'balance': balance,
      'createdAt': createdAt.toIso8601String(),
      'role': role,
    };
  }

  /// Create UserModel from Firestore document
  factory UserModel.fromMap(Map<String, dynamic> map) {
    // Handle createdAt field - can be String, Timestamp, or DateTime
    DateTime parseCreatedAt(dynamic value) {
      if (value == null) return DateTime.now();
      
      if (value is DateTime) {
        return value;
      } else if (value is String) {
        try {
          return DateTime.parse(value);
        } catch (e) {
          debugPrint('Error parsing createdAt string: $value, error: $e');
          return DateTime.now();
        }
      } else if (value is Timestamp) {
        return value.toDate();
      } else {
        debugPrint('Unknown createdAt type: ${value.runtimeType}');
        return DateTime.now();
      }
    }

    return UserModel(
      uid: map['uid'] as String? ?? '',
      email: map['email'] as String? ?? '',
      username: map['username'] as String? ?? 'Yeni Üye',
      balance: (map['balance'] as num?)?.toInt() ?? 0,
      createdAt: parseCreatedAt(map['createdAt']),
      role: map['role'] as String? ?? 'user',
    );
  }

  /// Create a copy of UserModel with updated fields
  UserModel copyWith({
    String? uid,
    String? email,
    String? username,
    int? balance,
    DateTime? createdAt,
    String? role,
  }) {
    return UserModel(
      uid: uid ?? this.uid,
      email: email ?? this.email,
      username: username ?? this.username,
      balance: balance ?? this.balance,
      createdAt: createdAt ?? this.createdAt,
      role: role ?? this.role,
    );
  }
}

