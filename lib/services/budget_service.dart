import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';

/// Handles per-category monthly budgets stored at:
/// users/{uid}/budgets/{month_category}
class BudgetService {
  static final BudgetService instance = BudgetService._();
  BudgetService._();

  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _budgetsRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('budgets');
  }

  /// month format: 'yyyy-MM'
  Future<void> setBudget({
    required String category,
    required double limit,
    required String month,
  }) async {
    final ref = _budgetsRef;
    if (ref == null) return;
    final docId = '${month}_$category';
    await ref.doc(docId).set({
      'category': category,
      'limit': limit,
      'month': month,
    });
  }

  Future<void> deleteBudget(String category, String month) async {
    final ref = _budgetsRef;
    if (ref == null) return;
    await ref.doc('${month}_$category').delete();
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamBudgets(String month) {
    final ref = _budgetsRef;
    if (ref == null) return const Stream.empty();
    return ref.where('month', isEqualTo: month).snapshots();
  }

  /// Computes total spent per category for the given month ('yyyy-MM')
  /// by scanning the user's expense transactions.
  Future<Map<String, double>> getSpentByCategory(String month) async {
    final uid = _uid;
    if (uid == null) return {};

    final snapshot = await _db
        .collection('users')
        .doc(uid)
        .collection('transactions')
        .where('type', isEqualTo: 'expense')
        .get();

    final Map<String, double> spentMap = {};
    for (var doc in snapshot.docs) {
      final data = doc.data();
      final dateStr = data['date']?.toString() ?? '';
      if (!dateStr.startsWith(month)) continue;
      final category = data['category'] ?? 'Other';
      final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
      spentMap[category] = (spentMap[category] ?? 0) + amount;
    }
    return spentMap;
  }

  /// Returns categories that are currently over budget for the given month.
  /// Useful for showing alerts (e.g. on the dashboard).
  Future<List<String>> getExceededCategories(String month) async {
    final ref = _budgetsRef;
    if (ref == null) return [];

    final budgetsSnap = await ref.where('month', isEqualTo: month).get();
    if (budgetsSnap.docs.isEmpty) return [];

    final spentMap = await getSpentByCategory(month);
    final exceeded = <String>[];

    for (var doc in budgetsSnap.docs) {
      final data = doc.data();
      final category = data['category'] as String;
      final limit = (data['limit'] as num).toDouble();
      final spent = spentMap[category] ?? 0.0;
      if (spent > limit) exceeded.add(category);
    }
    return exceeded;
  }
}