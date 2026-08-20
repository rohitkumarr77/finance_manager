import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles savings goals stored at: users/{uid}/goals/{id}
class GoalsService {
  static final GoalsService instance = GoalsService._();
  GoalsService._();

  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _goalsRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('goals');
  }

  Future<void> addGoal({
    required String name,
    required double targetAmount,
    double savedAmount = 0,
    int priority = 2, // 1 = High, 2 = Medium, 3 = Low
    DateTime? deadline,
  }) async {
    final ref = _goalsRef;
    if (ref == null) return;
    await ref.add({
      'name': name,
      'targetAmount': targetAmount,
      'savedAmount': savedAmount,
      'priority': priority,
      'deadline': deadline?.toIso8601String(),
      'isCompleted': savedAmount >= targetAmount,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateGoal(String id, Map<String, dynamic> data) async {
    final ref = _goalsRef;
    if (ref == null) return;
    await ref.doc(id).update(data);
  }

  Future<void> deleteGoal(String id) async {
    final ref = _goalsRef;
    if (ref == null) return;
    await ref.doc(id).delete();
  }

  /// Adds a contribution to a goal's saved amount.
  /// Returns true if this contribution just completed the goal.
  Future<bool> addContribution(
      String id,
      double currentSaved,
      double target,
      double amount,
      ) async {
    final ref = _goalsRef;
    if (ref == null) return false;
    final newSaved = currentSaved + amount;
    final justCompleted = currentSaved < target && newSaved >= target;
    await ref.doc(id).update({
      'savedAmount': newSaved,
      'isCompleted': newSaved >= target,
    });
    return justCompleted;
  }

  /// Ordered by priority (1=High first).
  Stream<QuerySnapshot<Map<String, dynamic>>> streamGoals() {
    final ref = _goalsRef;
    if (ref == null) return const Stream.empty();
    return ref.orderBy('priority').snapshots();
  }
}