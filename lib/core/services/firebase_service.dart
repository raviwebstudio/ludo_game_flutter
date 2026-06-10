import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:google_sign_in/google_sign_in.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of User Auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user UID
  String? get currentUid => _auth.currentUser?.uid;

  // Get current user display name
  String? get currentDisplayName => _auth.currentUser?.displayName;

  // Get current User
  User? get currentUser => _auth.currentUser;

  // Sign In
  Future<UserCredential> signIn(String email, String password) async {
    debugPrint('[AUTH] Attempting Email Login for $email');
    final cred = await _auth.signInWithEmailAndPassword(email: email, password: password);
    debugPrint('[AUTH] Email Login successful for ${cred.user?.email}');
    return cred;
  }

  // Sign Up
  Future<UserCredential> signUp(String email, String password, String name) async {
    debugPrint('[AUTH] Attempting signup for email: $email');
    try {
      final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
      debugPrint('[AUTH] createUserWithEmailAndPassword succeeded. UID: ${cred.user?.uid}');
      
      if (cred.user != null) {
        try {
          await cred.user!.updateDisplayName(name);
          debugPrint('[AUTH] Display name updated to: $name');
        } catch (e) {
          debugPrint('[AUTH] Warning: Failed to update display name: $e');
        }
        
        debugPrint('[FIRESTORE] Creating Firestore user record for UID: ${cred.user!.uid}');
        try {
          // Timeout the firestore write after 10 seconds to avoid infinite loading if offline or syncing issues
          await _db.collection('users').doc(cred.user!.uid).set({
            'uid': cred.user!.uid,
            'name': name,
            'email': email,
            'coins': 1000,
            'wins': 0,
            'gamesPlayed': 0,
            'winStreak': 0,
            'createdAt': FieldValue.serverTimestamp(),
          }).timeout(const Duration(seconds: 10), onTimeout: () {
            debugPrint('[FIRESTORE] Firestore write timed out. Continuing signup flow.');
          });
          debugPrint('[FIRESTORE] Firestore user record created successfully.');
        } catch (e) {
          debugPrint('[FIRESTORE] Failed to create Firestore user record: $e');
          rethrow;
        }
      }
      
      debugPrint('[AUTH] Signup flow completed successfully for $email');
      return cred;
    } on FirebaseAuthException catch (e) {
      debugPrint('[AUTH] FirebaseAuthException: [${e.code}] ${e.message}');
      rethrow;
    } catch (e) {
      debugPrint('[AUTH] Unexpected signup error: $e');
      rethrow;
    }
  }

  // Sign Out
  Future<void> signOut() async {
    debugPrint('[Auth] Signing out');
    await _auth.signOut();
    try {
      await GoogleSignIn.instance.signOut();
    } catch (e) {
      debugPrint('[Auth] Google Sign-Out error: $e');
    }
  }

  // Retrieve user statistics from Firestore
  Stream<DocumentSnapshot<Map<String, dynamic>>> userDocStream() {
    final uid = currentUid;
    if (uid == null) throw Exception('No user logged in');
    return _db.collection('users').doc(uid).snapshots();
  }

  // Matchmaking: Stream open lobbies waiting for players
  Stream<List<Map<String, dynamic>>> getOpenLobbies() {
    return _db
        .collection('lobbies')
        .where('status', isEqualTo: 'waiting')
        .snapshots()
        .map((snapshot) => snapshot.docs.map((doc) {
              final data = doc.data();
              data['id'] = doc.id;
              return data;
            }).toList());
  }

  // Matchmaking: Create a new lobby
  Future<String> createLobby(String hostName, int playerCount, Color hostColor) async {
    final uid = currentUid;
    if (uid == null) throw Exception('No user logged in');

    final docRef = _db.collection('lobbies').doc();
    await docRef.set({
      'hostId': uid,
      'hostName': hostName,
      'playerCount': playerCount,
      'status': 'waiting',
      'players': [
        {
          'uid': uid,
          'name': hostName,
          'colorValue': hostColor.toARGB32(),
          'isReady': true,
        }
      ],
      'lastUpdateTime': FieldValue.serverTimestamp(),
    });
    return docRef.id;
  }

  // Matchmaking: Join an existing lobby
  Future<void> joinLobby(String lobbyId, String playerName, Color playerColor) async {
    final uid = currentUid;
    if (uid == null) throw Exception('No user logged in');

    final docRef = _db.collection('lobbies').doc(lobbyId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) throw Exception('Lobby does not exist');

      final data = snapshot.data() as Map<String, dynamic>;
      final players = List<Map<String, dynamic>>.from(data['players'] as List);
      final playerCount = data['playerCount'] as int;

      if (players.length >= playerCount) throw Exception('Lobby is full');
      if (players.any((p) => p['uid'] == uid)) return; // Already joined

      players.add({
        'uid': uid,
        'name': playerName,
        'colorValue': playerColor.toARGB32(),
        'isReady': false,
      });

      transaction.update(docRef, {
        'players': players,
        'lastUpdateTime': FieldValue.serverTimestamp(),
      });
    });
  }

  // Matchmaking: Leave a lobby
  Future<void> leaveLobby(String lobbyId) async {
    final uid = currentUid;
    if (uid == null) return;

    final docRef = _db.collection('lobbies').doc(lobbyId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final players = List<Map<String, dynamic>>.from(data['players'] as List);
      final hostId = data['hostId'] as String;

      players.removeWhere((p) => p['uid'] == uid);

      if (players.isEmpty) {
        transaction.delete(docRef);
      } else {
        final newHostId = (hostId == uid) ? players.first['uid'] as String : hostId;
        final newHostName = (hostId == uid) ? players.first['name'] as String : data['hostName'] as String;
        transaction.update(docRef, {
          'hostId': newHostId,
          'hostName': newHostName,
          'players': players,
          'lastUpdateTime': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // Matchmaking: Toggle player ready status
  Future<void> toggleReady(String lobbyId, bool isReady) async {
    final uid = currentUid;
    if (uid == null) return;

    final docRef = _db.collection('lobbies').doc(lobbyId);
    await _db.runTransaction((transaction) async {
      final snapshot = await transaction.get(docRef);
      if (!snapshot.exists) return;

      final data = snapshot.data() as Map<String, dynamic>;
      final players = List<Map<String, dynamic>>.from(data['players'] as List);

      final idx = players.indexWhere((p) => p['uid'] == uid);
      if (idx != -1) {
        players[idx]['isReady'] = isReady;
        transaction.update(docRef, {
          'players': players,
          'lastUpdateTime': FieldValue.serverTimestamp(),
        });
      }
    });
  }

  // Matchmaking: Start game
  Future<void> startLobbyGame(String lobbyId, Map<String, dynamic> initialGameState) async {
    await _db.collection('lobbies').doc(lobbyId).update({
      'status': 'playing',
      'gameState': initialGameState,
      'lastUpdateTime': FieldValue.serverTimestamp(),
    });
  }

  // Game Syncer: Stream specific lobby state
  Stream<DocumentSnapshot<Map<String, dynamic>>> streamLobby(String lobbyId) {
    return _db.collection('lobbies').doc(lobbyId).snapshots();
  }

  // Game Syncer: Write state updates
  Future<void> updateGameState(String lobbyId, Map<String, dynamic> gameState) async {
    await _db.collection('lobbies').doc(lobbyId).update({
      'gameState': gameState,
      'lastUpdateTime': FieldValue.serverTimestamp(),
    });
  }

  // Sign In with Google
  Future<UserCredential?> signInWithGoogle() async {
    debugPrint('[Google Sign-In] Attempting Google Sign-In');
    try {
      await GoogleSignIn.instance.initialize();
      final googleUser = await GoogleSignIn.instance.authenticate();
      debugPrint('[Google Sign-In] Google user authenticated. Email: ${googleUser.email}');

      final googleAuth = googleUser.authentication;
      debugPrint('[Google Sign-In] Authentication tokens retrieved.');

      final AuthCredential credential = GoogleAuthProvider.credential(
        idToken: googleAuth.idToken,
      );

      debugPrint('[Google Sign-In] Exchanging credentials with Firebase.');
      final cred = await _auth.signInWithCredential(credential);
      debugPrint('[Google Sign-In] Firebase authentication successful. UID: ${cred.user?.uid}');

      if (cred.user != null) {
        final userDoc = await _db.collection('users').doc(cred.user!.uid).get();
        if (!userDoc.exists) {
          debugPrint('[FIRESTORE] Creating new user record for Google user UID: ${cred.user!.uid}');
          await _db.collection('users').doc(cred.user!.uid).set({
            'uid': cred.user!.uid,
            'name': cred.user!.displayName ?? 'Player',
            'email': cred.user!.email ?? '',
            'coins': 1000,
            'wins': 0,
            'gamesPlayed': 0,
            'winStreak': 0,
            'createdAt': FieldValue.serverTimestamp(),
          });
          debugPrint('[FIRESTORE] Firestore user record created successfully.');
        } else {
          debugPrint('[FIRESTORE] User record already exists. Merging/updating profile info.');
          await _db.collection('users').doc(cred.user!.uid).update({
            if (cred.user!.displayName != null) 'name': cred.user!.displayName,
            if (cred.user!.photoURL != null) 'photoUrl': cred.user!.photoURL,
          });
          debugPrint('[FIRESTORE] User record updated successfully.');
        }
      }
      return cred;
    } catch (e) {
      debugPrint('[Google Sign-In] Google Sign-In FAILED: $e');
      rethrow;
    }
  }

  // Token refresh for Google Sign-In
  Future<GoogleSignInAuthentication?> refreshGoogleToken() async {
    debugPrint('[Google Sign-In] Refreshing Google Token');
    try {
      await GoogleSignIn.instance.initialize();
      final googleUser = await GoogleSignIn.instance.attemptLightweightAuthentication();
      if (googleUser != null) {
        final auth = googleUser.authentication;
        debugPrint('[Google Sign-In] Google Token refreshed successfully.');
        return auth;
      }
    } catch (e) {
      debugPrint('[Google Sign-In] Google Token refresh failed: $e');
    }
    return null;
  }

  // Update user statistics in Firestore after a game ends
  Future<void> updateUserStats({required bool isWin}) async {
    final uid = currentUid;
    if (uid == null) return;

    final docRef = _db.collection('users').doc(uid);
    try {
      await _db.runTransaction((transaction) async {
        final snapshot = await transaction.get(docRef);
        if (!snapshot.exists) return;

        final data = snapshot.data() as Map<String, dynamic>;
        final int totalGames = (data['totalGames'] as int? ?? 0) + 1;
        final int gamesPlayed = (data['gamesPlayed'] as int? ?? 0) + 1;
        final int wins = (data['wins'] as int? ?? 0) + (isWin ? 1 : 0);
        final int losses = (data['losses'] as int? ?? 0) + (isWin ? 0 : 1);
        final int winStreak = isWin ? ((data['winStreak'] as int? ?? 0) + 1) : 0;
        final int coins = (data['coins'] as int? ?? 0) + (isWin ? 500 : 100);

        transaction.update(docRef, {
          'totalGames': totalGames,
          'gamesPlayed': gamesPlayed,
          'wins': wins,
          'losses': losses,
          'winStreak': winStreak,
          'coins': coins,
        });
      });
    } catch (_) {}
  }
}

