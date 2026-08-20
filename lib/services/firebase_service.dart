import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

class FirebaseService {
  final _db = FirebaseFirestore.instance;
  final _auth = FirebaseAuth.instance;

  String get userId => _auth.currentUser!.uid;

  static get instance => null;

  // ADD TRANSACTION
  Future<void> addTransaction({
    required String type,
    required double amount,
    required String category,
    required String description,
    required String date,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .add({
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  // REALTIME READ
  Stream<QuerySnapshot> streamTransactions() {
    return _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .orderBy('created_at', descending: true)
        .snapshots();
  }

  // UPDATE
  Future<void> updateTransaction({
    required String id,
    required String type,
    required double amount,
    required String category,
    required String description,
    required String date,
  }) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(id)
        .update({
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'date': date,
    });
  }

  // DELETE
  Future<void> deleteTransaction(String id) async {
    await _db
        .collection('users')
        .doc(userId)
        .collection('transactions')
        .doc(id)
        .delete();
  }
}