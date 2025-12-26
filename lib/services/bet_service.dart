import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Service for handling betting logic with Firebase Transactions
/// Ensures data integrity when placing bets
class BetService {
  final FirebaseFirestore _firestore = FirebaseFirestore.instance;
  final FirebaseAuth _auth = FirebaseAuth.instance;

  /// Places a bet on an event with full transaction safety
  /// 
  /// Returns a map with success status and details:
  /// {
  ///   'success': bool,
  ///   'newBalance': int?,
  ///   'newYesRatio': double?,
  ///   'newNoRatio': double?,
  ///   'message': String?,
  ///   'error': String?,
  /// }
  Future<Map<String, dynamic>> placeBet({
    required String eventId,
    required String eventTitle,
    required bool isVarim, // true for YES/VARIM, false for NO/YOKUM
    required int betAmount, // Amount in VP
  }) async {
    final user = _auth.currentUser;
    if (user == null) {
      return {
        'success': false,
        'error': 'Kullanıcı giriş yapmamış',
      };
    }

    // Validate bet amount
    if (betAmount < 10) {
      return {
        'success': false,
        'error': 'Minimum bahis tutarı: 10 VP',
      };
    }

    try {
      final result = await _firestore.runTransaction(
        (Transaction transaction) async {
          // ========== READS (Must come before writes) ==========
          
          // 1. Get User document
          final userDocRef = _firestore.collection('users').doc(user.uid);
          final userDoc = await transaction.get(userDocRef);

          if (!userDoc.exists) {
            throw Exception('Kullanıcı belgesi bulunamadı');
          }

          final userData = userDoc.data()!;
          final currentBalance = (userData['balance'] as num?)?.toInt() ?? 0;

          // Check balance
          if (currentBalance < betAmount) {
            throw Exception('Yetersiz bakiye! Mevcut bakiye: $currentBalance VP');
          }

          // 2. Get Event document
          final eventDocRef = _firestore.collection('events').doc(eventId);
          final eventDoc = await transaction.get(eventDocRef);

          if (!eventDoc.exists) {
            throw Exception('Etkinlik bulunamadı');
          }

          final eventData = eventDoc.data()!;
          
          // Get current pool values (default to 0 if not set)
          final currentPoolYes = (eventData['poolYes'] as num?)?.toInt() ?? 0;
          final currentPoolNo = (eventData['poolNo'] as num?)?.toInt() ?? 0;
          final currentVolume = (eventData['volume'] as num?)?.toInt() ?? 0;
          final currentYesRatio = (eventData['yesRatio'] as num?)?.toDouble() ?? 0.5; // Fallback to 0.5 if not set

          // Check if event is active
          final status = eventData['status'] as String?;
          if (status != 'active') {
            throw Exception('Bu etkinlik artık aktif değil');
          }

          // ========== CALCULATIONS (The Engine) ==========

          // Calculate new balance
          final newBalance = currentBalance - betAmount;

          // Update pools based on bet side
          int newPoolYes;
          int newPoolNo;
          
          if (isVarim) {
            // Betting YES/VARIM
            newPoolYes = currentPoolYes + betAmount;
            newPoolNo = currentPoolNo; // No change
          } else {
            // Betting NO/YOKUM
            newPoolYes = currentPoolYes; // No change
            newPoolNo = currentPoolNo + betAmount;
          }

          // Update volume
          final newVolume = currentVolume + betAmount;

          // Recalculate odds (Dynamic Ratio)
          final totalPool = newPoolYes + newPoolNo;
          double newYesRatio;
          double newNoRatio;

          if (totalPool == 0) {
            // Edge case: If totalPool is 0 (shouldn't happen, but safety first)
            // Keep existing ratios
            newYesRatio = currentYesRatio;
            newNoRatio = 1.0 - currentYesRatio;
          } else {
            // Calculate new ratios based on pool distribution
            newYesRatio = newPoolYes / totalPool;
            newNoRatio = newPoolNo / totalPool;
          }

          // Calculate entry ratio (probability at moment of betting)
          // This is the probability the user is betting on
          final entryRatio = isVarim ? newYesRatio : newNoRatio;
          
          // Calculate potential win: amount / entryRatio
          // If entryRatio is 0.54 (54%), and bet is 100 VP, potential win = 100 / 0.54 ≈ 185 VP
          final potentialWin = entryRatio > 0 
              ? (betAmount / entryRatio).toInt()
              : betAmount;

          // ========== WRITES (Commit) ==========

          // 1. Update User balance
          transaction.update(
            userDocRef,
            {'balance': newBalance},
          );

          // 2. Update Event pools, volume, and ratios
          transaction.update(
            eventDocRef,
            {
              'poolYes': newPoolYes,
              'poolNo': newPoolNo,
              'volume': newVolume,
              'yesRatio': newYesRatio,
              'noRatio': newNoRatio,
            },
          );

          // 3. Create Position/Ticket document in 'positions' collection
          final positionDocRef = userDocRef.collection('positions').doc();
          transaction.set(
            positionDocRef,
            {
              'eventId': eventId,
              'title': eventTitle,
              'side': isVarim ? 'yes' : 'no',
              'amount': betAmount,
              'entryRatio': entryRatio, // The probability at the moment of betting
              'potentialWin': potentialWin, // Calculated potential win
              'timestamp': FieldValue.serverTimestamp(),
              'status': 'active', // Will be updated to 'won' or 'lost' when event is resolved
            },
          );

          // 4. Also create bet document in 'bets' collection for backward compatibility
          final betDocRef = userDocRef.collection('bets').doc();
          transaction.set(
            betDocRef,
            {
              'eventId': eventId,
              'eventTitle': eventTitle,
              'choice': isVarim ? 'VARIM' : 'YOKUM',
              'amount': betAmount,
              'odds': entryRatio, // Store entry ratio as odds
              'potentialWin': potentialWin,
              'timestamp': FieldValue.serverTimestamp(),
              'status': 'active',
            },
          );

          // Return success data
          return {
            'success': true,
            'newBalance': newBalance,
            'newYesRatio': newYesRatio,
            'newNoRatio': newNoRatio,
            'newVolume': newVolume,
            'entryRatio': entryRatio,
            'potentialWin': potentialWin,
          };
        },
      );

      return result;
    } catch (e) {
      // Handle errors gracefully
      return {
        'success': false,
        'error': e.toString().replaceFirst('Exception: ', ''),
      };
    }
  }

  /// Get user's active positions for an event
  Future<List<Map<String, dynamic>>> getUserPositions(String eventId) async {
    final user = _auth.currentUser;
    if (user == null) return [];

    try {
      final snapshot = await _firestore
          .collection('users')
          .doc(user.uid)
          .collection('positions')
          .where('eventId', isEqualTo: eventId)
          .where('status', isEqualTo: 'active')
          .get();

      return snapshot.docs.map((doc) => {
        'id': doc.id,
        ...doc.data(),
      }).toList();
    } catch (e) {
      return [];
    }
  }
}
