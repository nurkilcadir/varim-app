import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:varim_app/models/user_model.dart';

/// Global user provider that manages user state across the app
/// Listens to Firestore user document in real-time
class UserProvider extends ChangeNotifier {
  UserModel? _currentUser;
  StreamSubscription<DocumentSnapshot>? _userSubscription;
  bool _isLoading = true;
  String? _error;

  UserModel? get currentUser => _currentUser;
  bool get isLoading => _isLoading;
  String? get error => _error;
  int get balance => _currentUser?.balance ?? 0;

  UserProvider() {
    // Start listening when provider is created
    _initializeUserListener();
  }

  /// Initialize user listener based on auth state
  void _initializeUserListener() {
    FirebaseAuth.instance.authStateChanges().listen((User? user) {
      if (user != null) {
        _startListening(user.uid);
      } else {
        _stopListening();
        _currentUser = null;
        _isLoading = false;
        notifyListeners();
      }
    });
  }

  /// Start listening to user document in Firestore
  void _startListening(String uid) {
    _isLoading = true;
    _error = null;
    notifyListeners();

    _userSubscription?.cancel();
    
    // First, check if document exists and create if needed
    _ensureUserDocumentExists(uid).then((_) {
      // Then start listening to changes
      _userSubscription = FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .snapshots()
          .listen(
        (DocumentSnapshot snapshot) {
          if (snapshot.exists && snapshot.data() != null) {
            try {
              final data = snapshot.data() as Map<String, dynamic>;
              debugPrint('UserProvider: Raw Firestore data: $data');
              debugPrint('UserProvider: Balance from Firestore: ${data['balance']}');
              _currentUser = UserModel.fromMap(data);
              _error = null;
              debugPrint('UserProvider: Successfully parsed user - Balance: ${_currentUser?.balance} VP, Username: ${_currentUser?.username}');
            } catch (e, stackTrace) {
              _error = 'Error parsing user data: $e';
              debugPrint('UserProvider: $_error');
              debugPrint('UserProvider: Stack trace: $stackTrace');
            }
          } else {
            _currentUser = null;
            _error = 'User document not found';
            debugPrint('UserProvider: $_error');
          }
          _isLoading = false;
          notifyListeners();
        },
        onError: (error) {
          _error = 'Error loading user data: $error';
          _isLoading = false;
          debugPrint('UserProvider error: $error');
          notifyListeners();
        },
      );
    });
  }

  /// Ensure user document exists, create if missing
  Future<void> _ensureUserDocumentExists(String uid) async {
    try {
      final user = FirebaseAuth.instance.currentUser;
      if (user == null) {
        debugPrint('UserProvider: No authenticated user');
        return;
      }

      // Check if document exists
      final doc = await FirebaseFirestore.instance
          .collection('users')
          .doc(uid)
          .get();

      if (!doc.exists) {
        // Create user document with default values
        final email = user.email ?? 'unknown@email.com';
        final username = email.split('@')[0];

        final userModel = UserModel(
          uid: uid,
          email: email,
          username: username,
          balance: 10000, // Welcome bonus for existing users too
          createdAt: user.metadata.creationTime ?? DateTime.now(),
          role: 'user',
        );

        await FirebaseFirestore.instance
            .collection('users')
            .doc(uid)
            .set(userModel.toMap());

        debugPrint('UserProvider: Created Firestore document for user: $uid');
        debugPrint('UserProvider: Initial balance set to: ${userModel.balance} VP');
        
        // Update local state immediately
        _currentUser = userModel;
        _error = null;
        _isLoading = false;
        notifyListeners();
      } else {
        // Document exists, load it immediately
        final data = doc.data();
        if (data != null) {
          _currentUser = UserModel.fromMap(data);
          _error = null;
          debugPrint('UserProvider: Loaded existing user - Balance: ${_currentUser?.balance} VP');
        }
        _isLoading = false;
        notifyListeners();
      }
    } catch (e) {
      _error = 'Error ensuring user document: $e';
      _isLoading = false;
      debugPrint('UserProvider: $_error');
      notifyListeners();
    }
  }

  /// Stop listening to user document
  void _stopListening() {
    _userSubscription?.cancel();
    _userSubscription = null;
  }

  /// Refresh user data manually
  Future<void> refreshUser() async {
    final user = FirebaseAuth.instance.currentUser;
    if (user != null) {
      try {
        final doc = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .get();
        
        if (doc.exists && doc.data() != null) {
          _currentUser = UserModel.fromMap(doc.data()!);
          _error = null;
        } else {
          _error = 'User document not found';
        }
        _isLoading = false;
        notifyListeners();
      } catch (e) {
        _error = 'Error refreshing user: $e';
        _isLoading = false;
        notifyListeners();
      }
    }
  }

  /// Update user balance (for betting, etc.)
  Future<bool> updateBalance(int newBalance) async {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) return false;

    try {
      await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .update({'balance': newBalance});
      // The stream will automatically update _currentUser
      return true;
    } catch (e) {
      _error = 'Error updating balance: $e';
      debugPrint(_error);
      notifyListeners();
      return false;
    }
  }

  @override
  void dispose() {
    _stopListening();
    super.dispose();
  }
}

