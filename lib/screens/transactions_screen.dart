import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class TransactionsScreen extends StatefulWidget {
  const TransactionsScreen({Key? key}) : super(key: key);

  @override
  State<TransactionsScreen> createState() => _TransactionsScreenState();
}

class _TransactionsScreenState extends State<TransactionsScreen> {
  List<Map<String, dynamic>> _transactions = [];
  bool _isLoading = true;
  String _filterType = 'all';

  @override
  void initState() {
    super.initState();
    _loadTransactions();
  }

  Future<void> _loadTransactions() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;

    if (user != null) {
      try {
        //  Fix 1: Correct Firestore path users/{uid}/transactions
        final snapshot = await FirebaseFirestore.instance
            .collection('users')
            .doc(user.uid)
            .collection('transactions')
            .orderBy('date', descending: true)
            .get();

        _transactions = snapshot.docs.map((doc) {
          final data = doc.data();

          //  Fix 2: Handle Firestore Timestamp OR String for date
          DateTime parsedDate;
          final rawDate = data['date'];
          if (rawDate is Timestamp) {
            parsedDate = rawDate.toDate();
          } else if (rawDate is String) {
            parsedDate = DateTime.tryParse(rawDate) ?? DateTime.now();
          } else {
            parsedDate = DateTime.now();
          }

          return {
            'id': doc.id,
            'type': data['type'] ?? '',
            'amount': (data['amount'] as num?)?.toDouble() ?? 0.0,
            'category': data['category'] ?? 'Other',
            'description': data['description'] ?? '',
            'date': parsedDate,
          };
        }).toList();
      } catch (e) {
        debugPrint('Error loading transactions: $e');
      }
    }

    setState(() => _isLoading = false);
  }

  List<Map<String, dynamic>> get _filteredTransactions {
    if (_filterType == 'all') return _transactions;
    return _transactions.where((t) => t['type'] == _filterType).toList();
  }

  //  Fix 3: Delete from Firebase using doc ID (string), not SQLite int ID
  Future<void> _deleteTransaction(String docId) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Delete Transaction'),
        content: const Text('Are you sure you want to delete this transaction?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('Delete', style: TextStyle(color: Colors.red)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      try {
        final user = FirebaseAuth.instance.currentUser;
        if (user != null) {
          //  Delete from correct Firestore path
          await FirebaseFirestore.instance
              .collection('users')
              .doc(user.uid)
              .collection('transactions')
              .doc(docId)
              .delete();

          await _loadTransactions();

          if (mounted) {
            ScaffoldMessenger.of(context).showSnackBar(
              const SnackBar(
                content: Text('Transaction deleted'),
                backgroundColor: Colors.green,
              ),
            );
          }
        }
      } catch (e) {
        debugPrint('Error deleting transaction: $e');
        if (mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text('Failed to delete transaction'),
              backgroundColor: Colors.red,
            ),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Transactions',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF667eea),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          PopupMenuButton<String>(
            icon: const Icon(Icons.filter_list, color: Colors.white),
            onSelected: (value) {
              setState(() => _filterType = value);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'all', child: Text('All')),
              const PopupMenuItem(value: 'income', child: Text('Income')),
              const PopupMenuItem(value: 'expense', child: Text('Expense')),
            ],
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadTransactions,
        child: _filteredTransactions.isEmpty
            ? ListView(
          //  Wrap in ListView so RefreshIndicator works on empty state
          physics: const AlwaysScrollableScrollPhysics(),
          children: [
            SizedBox(
              height: MediaQuery.of(context).size.height * 0.6,
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    Icons.inbox,
                    size: 100,
                    color: Colors.grey[300],
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'No transactions found',
                    style: TextStyle(
                      fontSize: 18,
                      color: Colors.grey[600],
                    ),
                  ),
                ],
              ),
            ),
          ],
        )
            : ListView.builder(
          physics: const AlwaysScrollableScrollPhysics(),
          itemCount: _filteredTransactions.length,
          itemBuilder: (context, index) {
            final tx = _filteredTransactions[index];
            final isIncome = tx['type'] == 'income';

            //  Fix 4: date is already DateTime — no need to parse again
            final DateTime date = tx['date'] as DateTime;

            return Card(
              margin: const EdgeInsets.symmetric(
                horizontal: 16,
                vertical: 8,
              ),
              elevation: 3,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
              child: ListTile(
                leading: CircleAvatar(
                  backgroundColor: isIncome
                      ? Colors.green.withOpacity(0.2)
                      : Colors.red.withOpacity(0.2),
                  child: Icon(
                    isIncome
                        ? Icons.arrow_downward
                        : Icons.arrow_upward,
                    color: isIncome ? Colors.green : Colors.red,
                  ),
                ),
                title: Text(
                  tx['category'],
                  style:
                  const TextStyle(fontWeight: FontWeight.bold),
                ),
                subtitle: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    if ((tx['description'] as String).isNotEmpty)
                      Text(tx['description']),
                    const SizedBox(height: 4),
                    Text(
                      DateFormat('dd MMM yyyy').format(date),
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey[600],
                      ),
                    ),
                  ],
                ),
                trailing: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    //  Fix 5: Proper amount formatting
                    Text(
                      '₹${(tx['amount'] as double).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                    IconButton(
                      icon: const Icon(Icons.delete,
                          color: Colors.red),
                      //  Fix 6: Pass string doc ID not int
                      onPressed: () =>
                          _deleteTransaction(tx['id'] as String),
                    ),
                  ],
                ),
                isThreeLine: true,
              ),
            );
          },
        ),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () async {
          await Navigator.pushNamed(context, '/add-transaction');
          _loadTransactions();
        },
        backgroundColor: const Color(0xFF667eea),
        child: const Icon(Icons.add),
      ),
    );
  }
}