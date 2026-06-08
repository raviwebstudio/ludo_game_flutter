import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class FirebaseService {
  final FirebaseAuth _auth = FirebaseAuth.instance;
  final FirebaseFirestore _db = FirebaseFirestore.instance;

  // Stream of User Auth state
  Stream<User?> get authStateChanges => _auth.authStateChanges();

  // Get current user UID
  String? get currentUid => _auth.currentUser?.uid;

  // Get current user display name
  String? get currentDisplayName => _auth.currentUser?.displayName;

  // Sign In
  Future<UserCredential> signIn(String email, String password) async {
    return await _auth.signInWithEmailAndPassword(email: email, password: password);
  }

  // Sign Up
  Future<UserCredential> signUp(String email, String password, String name) async {
    final cred = await _auth.createUserWithEmailAndPassword(email: email, password: password);
    if (cred.user != null) {
      await cred.user!.updateDisplayName(name);
      // Create user record in Firestore
      await _db.collection('users').doc(cred.user!.uid).set({
        'uid': cred.user!.uid,
        'name': name,
        'email': email,
        'coins': 1000,
        'totalGames': 0,
        'wins': 0,
        'winStreak': 0,
        'createdAt': FieldValue.serverTimestamp(),
      });
    }
    return cred;
  }

  // Sign Out
  Future<void> signOut() async {
    await _auth.signOut();
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
}
