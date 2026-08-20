import 'package:cloud_firestore/cloud_firestore.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:intl/intl.dart';

/// Handles recurring transactions (subscriptions, salary, bills) stored at:
/// users/{uid}/recurring/{id}
class RecurringService {
  static final RecurringService instance = RecurringService._();
  RecurringService._();

  final _db = FirebaseFirestore.instance;
  String? get _uid => FirebaseAuth.instance.currentUser?.uid;

  CollectionReference<Map<String, dynamic>>? get _recurringRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('recurring');
  }

  CollectionReference<Map<String, dynamic>>? get _transactionsRef {
    final uid = _uid;
    if (uid == null) return null;
    return _db.collection('users').doc(uid).collection('transactions');
  }

  Future<void> addRecurring({
    required String type, // 'income' | 'expense'
    required double amount,
    required String category,
    required String description,
    required String frequency, // 'weekly' | 'monthly'
    required DateTime startDate,
    String paymentMethod = 'Cash',
  }) async {
    final ref = _recurringRef;
    if (ref == null) return;
    await ref.add({
      'type': type,
      'amount': amount,
      'category': category,
      'description': description,
      'frequency': frequency,
      'paymentMethod': paymentMethod,
      'nextDate': DateFormat('yyyy-MM-dd').format(startDate),
      'isPaused': false,
      'created_at': FieldValue.serverTimestamp(),
    });
  }

  Future<void> updateRecurring(String id, Map<String, dynamic> data) async {
    final ref = _recurringRef;
    if (ref == null) return;
    await ref.doc(id).update(data);
  }

  Future<void> deleteRecurring(String id) async {
    final ref = _recurringRef;
    if (ref == null) return;
    await ref.doc(id).delete();
  }

  Future<void> togglePause(String id, bool isPaused) async {
    await updateRecurring(id, {'isPaused': isPaused});
  }

  Stream<QuerySnapshot<Map<String, dynamic>>> streamRecurring() {
    final ref = _recurringRef;
    if (ref == null) return const Stream.empty();
    return ref.orderBy('nextDate').snapshots();
  }

  DateTime _nextOccurrence(DateTime date, String frequency) {
    switch (frequency) {
      case 'weekly':
        return date.add(const Duration(days: 7));
      case 'monthly':
      default:
        return DateTime(date.year, date.month + 1, date.day);
    }
  }

  /// Scans all active (non-paused) recurring items and auto-creates any
  /// transactions that are due (including catching up on missed ones).
  /// Call this once on app/dashboard load. Returns number of transactions added.
  Future<int> processDueRecurring() async {
    final ref = _recurringRef;
    final txRef = _transactionsRef;
    if (ref == null || txRef == null) return 0;

    final snapshot = await ref.where('isPaused', isEqualTo: false).get();
    final today = DateTime.now();
    int addedCount = 0;

    for (var doc in snapshot.docs) {
      final data = doc.data();
      final nextDateStr = data['nextDate'] as String?;
      if (nextDateStr == null) continue;

      DateTime nextDate = DateTime.tryParse(nextDateStr) ?? today;
      final frequency = data['frequency'] ?? 'monthly';
      bool updated = false;

      // Guard against runaway loops; cap catch-up at 24 occurrences.
      int safety = 0;
      while (!nextDate.isAfter(today) && safety < 24) {
        await txRef.add({
          'type': data['type'],
          'amount': data['amount'],
          'category': data['category'],
          'description': '${data['description']} (auto)',
          'date': DateFormat('yyyy-MM-dd').format(nextDate),
          'paymentMethod': data['paymentMethod'] ?? 'Cash',
          'created_at': FieldValue.serverTimestamp(),
        });
        addedCount++;
        nextDate = _nextOccurrence(nextDate, frequency);
        updated = true;
        safety++;
      }

      if (updated) {
        await ref.doc(doc.id).update({
          'nextDate': DateFormat('yyyy-MM-dd').format(nextDate),
        });
      }
    }

    return addedCount;
  }
}