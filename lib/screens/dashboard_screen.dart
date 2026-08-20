// import 'package:flutter/material.dart';
// import 'package:firebase_auth/firebase_auth.dart';
// import 'package:cloud_firestore/cloud_firestore.dart';
// import '../services/recurring_service.dart';
// import '../services/budget_service.dart';
// import 'budget_screen.dart';
// import 'recurring_screen.dart';
// import 'goals_screen.dart';
// import 'payment_analytics_screen.dart';
//
// class DashboardScreen extends StatefulWidget {
//   const DashboardScreen({Key? key}) : super(key: key);
//
//   @override
//   State<DashboardScreen> createState() => _DashboardScreenState();
// }
//
// class _DashboardScreenState extends State<DashboardScreen> {
//   int _selectedIndex = 0;
//
//   // All data loaded from Firebase directly — no local DB needed
//   double _totalIncome = 0;
//   double _totalExpense = 0;
//   double _balance = 0;
//   String _username = 'User';
//   List<Map<String, dynamic>> _recentTransactions = [];
//   bool _isLoading = true;
//
//   // ✅ NEW: budget alerts shown on dashboard
//   List<String> _exceededBudgetCategories = [];
//
//   @override
//   void initState() {
//     super.initState();
//     _loadData();
//   }
//
//   Future<void> _loadData() async {
//     setState(() => _isLoading = true);
//
//     final user = FirebaseAuth.instance.currentUser;
//     if (user == null) {
//       setState(() => _isLoading = false);
//       return;
//     }
//
//     try {
//       //  NEW: auto-add any due recurring transactions before loading stats
//       await RecurringService.instance.processDueRecurring();
//
//       // Load username from Firestore users collection
//       final userDoc = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .get();
//
//       if (userDoc.exists) {
//         _username = userDoc.data()?['username'] ??
//             userDoc.data()?['name'] ??
//             user.displayName ??
//             'User';
//       }
//
//       // Load all transactions and compute stats
//       final txSnapshot = await FirebaseFirestore.instance
//           .collection('users')
//           .doc(user.uid)
//           .collection('transactions')
//           .orderBy('date', descending: true)
//           .get();
//
//       double income = 0;
//       double expense = 0;
//       final List<Map<String, dynamic>> transactions = [];
//
//       for (var doc in txSnapshot.docs) {
//         final data = doc.data();
//         final double amount = (data['amount'] as num).toDouble();
//         final String type = data['type'] ?? '';
//
//         if (type == 'income') {
//           income += amount;
//         } else {
//           expense += amount;
//         }
//
//         transactions.add({
//           'id': doc.id,
//           'type': type,
//           'amount': amount,
//           'category': data['category'] ?? 'Other',
//           'description': data['description'] ?? '',
//           'date': data['date'],
//           'paymentMethod': data['paymentMethod'] ?? 'Cash',
//         });
//       }
//
//       // ✅ NEW: check for budgets exceeded this month
//       final now = DateTime.now();
//       final monthKey =
//           '${now.year}-${now.month.toString().padLeft(2, '0')}';
//       final exceeded = await BudgetService.instance.getExceededCategories(monthKey);
//
//       setState(() {
//         _totalIncome = income;
//         _totalExpense = expense;
//         _balance = income - expense;
//         _recentTransactions = transactions; // already sorted by date desc
//         _exceededBudgetCategories = exceeded;
//         _isLoading = false;
//       });
//     } catch (e) {
//       debugPrint('Error loading dashboard: $e');
//       setState(() => _isLoading = false);
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       appBar: AppBar(
//         title: const Text(
//           'Dashboard',
//           style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
//         ),
//         backgroundColor: const Color(0xFF667eea),
//         elevation: 0,
//         automaticallyImplyLeading: false,
//         actions: [
//           IconButton(
//             icon: const Icon(Icons.refresh, color: Colors.white),
//             onPressed: _loadData,
//           ),
//           IconButton(
//             icon: const Icon(Icons.person, color: Colors.white),
//             onPressed: () {
//               Navigator.pushNamed(context, '/profile').then((_) => _loadData());
//             },
//           ),
//         ],
//       ),
//       body: _isLoading
//           ? const Center(child: CircularProgressIndicator())
//           : RefreshIndicator(
//         onRefresh: _loadData,
//         child: SingleChildScrollView(
//           physics: const AlwaysScrollableScrollPhysics(),
//           child: Column(
//             children: [
//               _buildHeader(),
//               if (_exceededBudgetCategories.isNotEmpty) _buildBudgetAlert(),
//               _buildStatsCards(),
//               _buildQuickActions(),
//               _buildRecentTransactions(),
//               const SizedBox(height: 80), // space for FAB
//             ],
//           ),
//         ),
//       ),
//       floatingActionButton: FloatingActionButton.extended(
//         onPressed: () async {
//           await Navigator.pushNamed(context, '/add-transaction');
//           _loadData();
//         },
//         backgroundColor: const Color(0xFF667eea),
//         icon: const Icon(Icons.add),
//         label: const Text('Add Transaction'),
//       ),
//       bottomNavigationBar: BottomNavigationBar(
//         currentIndex: _selectedIndex,
//         selectedItemColor: const Color(0xFF667eea),
//         unselectedItemColor: Colors.grey,
//         type: BottomNavigationBarType.fixed,
//         onTap: (index) {
//           setState(() => _selectedIndex = index);
//           switch (index) {
//             case 0:
//               break;
//             case 1:
//               Navigator.pushNamed(context, '/transactions')
//                   .then((_) => _loadData());
//               break;
//             case 2:
//               Navigator.pushNamed(context, '/reports')
//                   .then((_) => _loadData());
//               break;
//             case 3:
//               Navigator.pushNamed(context, '/profile')
//                   .then((_) => _loadData());
//               break;
//           }
//         },
//         items: const [
//           BottomNavigationBarItem(
//             icon: Icon(Icons.dashboard),
//             label: 'Dashboard',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.list),
//             label: 'Transactions',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.bar_chart),
//             label: 'Reports',
//           ),
//           BottomNavigationBarItem(
//             icon: Icon(Icons.person),
//             label: 'Profile',
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildHeader() {
//     return Container(
//       width: double.infinity,
//       padding: const EdgeInsets.all(20),
//       decoration: const BoxDecoration(
//         gradient: LinearGradient(
//           begin: Alignment.topLeft,
//           end: Alignment.bottomRight,
//           colors: [Color(0xFF667eea), Color(0xFF764ba2)],
//         ),
//       ),
//       child: Column(
//         crossAxisAlignment: CrossAxisAlignment.start,
//         children: [
//           Text(
//             'Welcome back, $_username!',
//             style: const TextStyle(
//               color: Colors.white,
//               fontSize: 24,
//               fontWeight: FontWeight.bold,
//             ),
//           ),
//           const SizedBox(height: 8),
//           const Text(
//             'Here\'s your financial overview',
//             style: TextStyle(color: Colors.white70, fontSize: 16),
//           ),
//         ],
//       ),
//     );
//   }
//
//   // ✅ NEW: banner shown when one or more budgets are exceeded this month
//   Widget _buildBudgetAlert() {
//     return Container(
//       margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
//       padding: const EdgeInsets.all(14),
//       decoration: BoxDecoration(
//         color: Colors.red.withOpacity(0.1),
//         borderRadius: BorderRadius.circular(12),
//         border: Border.all(color: Colors.red.withOpacity(0.3)),
//       ),
//       child: Row(
//         children: [
//           const Icon(Icons.warning_amber_rounded, color: Colors.red),
//           const SizedBox(width: 10),
//           Expanded(
//             child: Text(
//               'Budget exceeded for: ${_exceededBudgetCategories.join(', ')}',
//               style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
//             ),
//           ),
//           TextButton(
//             onPressed: () {
//               Navigator.push(
//                 context,
//                 MaterialPageRoute(builder: (context) => const BudgetScreen()),
//               ).then((_) => _loadData());
//             },
//             child: const Text('View'),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatsCards() {
//     return Padding(
//       padding: const EdgeInsets.all(16.0),
//       child: Column(
//         children: [
//           Row(
//             children: [
//               Expanded(
//                 child: _buildStatCard(
//                   'Income',
//                   '₹${_totalIncome.toStringAsFixed(2)}',
//                   Icons.arrow_downward,
//                   Colors.green,
//                 ),
//               ),
//               const SizedBox(width: 16),
//               Expanded(
//                 child: _buildStatCard(
//                   'Expense',
//                   '₹${_totalExpense.toStringAsFixed(2)}',
//                   Icons.arrow_upward,
//                   Colors.red,
//                 ),
//               ),
//             ],
//           ),
//           const SizedBox(height: 16),
//           _buildStatCard(
//             'Balance',
//             '₹${_balance.toStringAsFixed(2)}',
//             Icons.account_balance_wallet,
//             _balance >= 0 ? Colors.blue : Colors.orange,
//             isLarge: true,
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildStatCard(
//       String title,
//       String amount,
//       IconData icon,
//       Color color, {
//         bool isLarge = false,
//       }) {
//     return Card(
//       elevation: 4,
//       shape: RoundedRectangleBorder(
//         borderRadius: BorderRadius.circular(15),
//       ),
//       child: Container(
//         padding: EdgeInsets.all(isLarge ? 24 : 16),
//         decoration: BoxDecoration(
//           borderRadius: BorderRadius.circular(15),
//           gradient: LinearGradient(
//             begin: Alignment.topLeft,
//             end: Alignment.bottomRight,
//             colors: [color.withOpacity(0.7), color],
//           ),
//         ),
//         child: Column(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             Row(
//               mainAxisAlignment: MainAxisAlignment.spaceBetween,
//               children: [
//                 Text(
//                   title,
//                   style: const TextStyle(
//                     color: Colors.white,
//                     fontSize: 16,
//                     fontWeight: FontWeight.w500,
//                   ),
//                 ),
//                 Icon(icon, color: Colors.white, size: isLarge ? 32 : 24),
//               ],
//             ),
//             SizedBox(height: isLarge ? 16 : 12),
//             Text(
//               amount,
//               style: TextStyle(
//                 color: Colors.white,
//                 fontSize: isLarge ? 32 : 24,
//                 fontWeight: FontWeight.bold,
//               ),
//             ),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _buildQuickActions() {
//     return Padding(
//       padding: const EdgeInsets.symmetric(horizontal: 16),
//       child: Card(
//         elevation: 4,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(15),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               const Text(
//                 'Quick Actions',
//                 style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   _buildQuickActionButton(
//                     'Add Income',
//                     Icons.add_circle,
//                     Colors.green,
//                         () {
//                       Navigator.pushNamed(
//                         context,
//                         '/add-transaction',
//                         arguments: 'income',
//                       ).then((_) => _loadData());
//                     },
//                   ),
//                   _buildQuickActionButton(
//                     'Add Expense',
//                     Icons.remove_circle,
//                     Colors.red,
//                         () {
//                       Navigator.pushNamed(
//                         context,
//                         '/add-transaction',
//                         arguments: 'expense',
//                       ).then((_) => _loadData());
//                     },
//                   ),
//                   _buildQuickActionButton(
//                     'View Reports',
//                     Icons.bar_chart,
//                     Colors.blue,
//                         () {
//                       Navigator.pushNamed(context, '/reports')
//                           .then((_) => _loadData());
//                     },
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 20),
//               // ✅ NEW: second row for the newly added feature areas
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceAround,
//                 children: [
//                   _buildQuickActionButton(
//                     'Budgets',
//                     Icons.pie_chart,
//                     Colors.deepPurple,
//                         () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => const BudgetScreen()),
//                       ).then((_) => _loadData());
//                     },
//                   ),
//                   _buildQuickActionButton(
//                     'Recurring',
//                     Icons.autorenew,
//                     Colors.teal,
//                         () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => const RecurringScreen()),
//                       ).then((_) => _loadData());
//                     },
//                   ),
//                   _buildQuickActionButton(
//                     'Goals',
//                     Icons.flag,
//                     Colors.orange,
//                         () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(builder: (context) => const GoalsScreen()),
//                       ).then((_) => _loadData());
//                     },
//                   ),
//                   _buildQuickActionButton(
//                     'Payments',
//                     Icons.credit_card,
//                     Colors.indigo,
//                         () {
//                       Navigator.push(
//                         context,
//                         MaterialPageRoute(
//                             builder: (context) => const PaymentAnalyticsScreen()),
//                       ).then((_) => _loadData());
//                     },
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   Widget _buildQuickActionButton(
//       String label,
//       IconData icon,
//       Color color,
//       VoidCallback onTap,
//       ) {
//     return InkWell(
//       onTap: onTap,
//       borderRadius: BorderRadius.circular(12),
//       child: Column(
//         children: [
//           Container(
//             padding: const EdgeInsets.all(16),
//             decoration: BoxDecoration(
//               color: color.withOpacity(0.1),
//               shape: BoxShape.circle,
//             ),
//             child: Icon(icon, color: color, size: 32),
//           ),
//           const SizedBox(height: 8),
//           Text(
//             label,
//             style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRecentTransactions() {
//     return Padding(
//       padding: const EdgeInsets.all(16),
//       child: Card(
//         elevation: 4,
//         shape: RoundedRectangleBorder(
//           borderRadius: BorderRadius.circular(15),
//         ),
//         child: Padding(
//           padding: const EdgeInsets.all(16),
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Row(
//                 mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                 children: [
//                   const Text(
//                     'Recent Transactions',
//                     style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
//                   ),
//                   TextButton(
//                     onPressed: () {
//                       Navigator.pushNamed(context, '/transactions')
//                           .then((_) => _loadData());
//                     },
//                     child: const Text('View All'),
//                   ),
//                 ],
//               ),
//               const SizedBox(height: 10),
//               if (_recentTransactions.isEmpty)
//                 const Padding(
//                   padding: EdgeInsets.all(20),
//                   child: Center(
//                     child: Text(
//                       'No transactions yet',
//                       style: TextStyle(color: Colors.grey),
//                     ),
//                   ),
//                 )
//               else
//                 ..._recentTransactions.take(5).map((tx) {
//                   final isIncome = tx['type'] == 'income';
//                   return ListTile(
//                     leading: CircleAvatar(
//                       backgroundColor: isIncome
//                           ? Colors.green.withOpacity(0.2)
//                           : Colors.red.withOpacity(0.2),
//                       child: Icon(
//                         isIncome ? Icons.arrow_downward : Icons.arrow_upward,
//                         color: isIncome ? Colors.green : Colors.red,
//                       ),
//                     ),
//                     title: Text(tx['category'] ?? 'Unknown'),
//                     subtitle: Text(
//                       [
//                         if ((tx['description'] ?? '').toString().isNotEmpty)
//                           tx['description'],
//                         tx['paymentMethod'] ?? 'Cash',
//                       ].join(' • '),
//                     ),
//                     trailing: Text(
//                       '₹${(tx['amount'] as double).toStringAsFixed(2)}',
//                       style: TextStyle(
//                         color: isIncome ? Colors.green : Colors.red,
//                         fontWeight: FontWeight.bold,
//                         fontSize: 16,
//                       ),
//                     ),
//                   );
//                 }),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
// }
import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';
import '../services/recurring_service.dart';
import '../services/budget_service.dart';
import 'budget_screen.dart';
import 'recurring_screen.dart';
import 'goals_screen.dart';
import 'payment_analytics_screen.dart';

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int _selectedIndex = 0;

  // All data loaded from Firebase directly — no local DB needed
  double _totalIncome = 0;
  double _totalExpense = 0;
  double _balance = 0;
  String _username = 'User';
  List<Map<String, dynamic>> _recentTransactions = [];
  bool _isLoading = true;

  // ✅ NEW: budget alerts shown on dashboard
  List<String> _exceededBudgetCategories = [];

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    setState(() => _isLoading = true);

    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      setState(() => _isLoading = false);
      return;
    }

    // ✅ NEW: auto-add any due recurring transactions before loading stats.
    // Wrapped in its own try/catch so a permissions or query issue here
    // (e.g. Firestore rules not yet updated for the 'recurring' collection)
    // never blocks the core income/expense/balance display below.
    try {
      await RecurringService.instance.processDueRecurring();
    } catch (e) {
      debugPrint('Recurring processing skipped: $e');
    }

    try {
      // Load username from Firestore users collection
      final userDoc = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .get();

      if (userDoc.exists) {
        _username = userDoc.data()?['username'] ??
            userDoc.data()?['name'] ??
            user.displayName ??
            'User';
      }

      // Load all transactions and compute stats
      final txSnapshot = await FirebaseFirestore.instance
          .collection('users')
          .doc(user.uid)
          .collection('transactions')
          .orderBy('date', descending: true)
          .get();

      double income = 0;
      double expense = 0;
      final List<Map<String, dynamic>> transactions = [];

      for (var doc in txSnapshot.docs) {
        final data = doc.data();
        final double amount = (data['amount'] as num).toDouble();
        final String type = data['type'] ?? '';

        if (type == 'income') {
          income += amount;
        } else {
          expense += amount;
        }

        transactions.add({
          'id': doc.id,
          'type': type,
          'amount': amount,
          'category': data['category'] ?? 'Other',
          'description': data['description'] ?? '',
          'date': data['date'],
          'paymentMethod': data['paymentMethod'] ?? 'Cash',
        });
      }

      // Set the core stats immediately — this is the important part that
      // must not be skipped just because a secondary feature call fails.
      setState(() {
        _totalIncome = income;
        _totalExpense = expense;
        _balance = income - expense;
        _recentTransactions = transactions; // already sorted by date desc
        _isLoading = false;
      });
    } catch (e) {
      debugPrint('Error loading dashboard: $e');
      setState(() => _isLoading = false);
    }

    // ✅ NEW: check for budgets exceeded this month — separate try/catch so
    // this optional feature can never blank out the stats above.
    try {
      final now = DateTime.now();
      final monthKey =
          '${now.year}-${now.month.toString().padLeft(2, '0')}';
      final exceeded = await BudgetService.instance.getExceededCategories(monthKey);
      if (mounted) {
        setState(() => _exceededBudgetCategories = exceeded);
      }
    } catch (e) {
      debugPrint('Budget check skipped: $e');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Dashboard',
          style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold),
        ),
        backgroundColor: const Color(0xFF667eea),
        elevation: 0,
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
          IconButton(
            icon: const Icon(Icons.person, color: Colors.white),
            onPressed: () {
              Navigator.pushNamed(context, '/profile').then((_) => _loadData());
            },
          ),
        ],
      ),
      body: _isLoading
          ? const Center(child: CircularProgressIndicator())
          : RefreshIndicator(
        onRefresh: _loadData,
        child: SingleChildScrollView(
          physics: const AlwaysScrollableScrollPhysics(),
          child: Column(
            children: [
              _buildHeader(),
              if (_exceededBudgetCategories.isNotEmpty) _buildBudgetAlert(),
              _buildStatsCards(),
              _buildQuickActions(),
              _buildRecentTransactions(),
              const SizedBox(height: 80), // space for FAB
            ],
          ),
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () async {
          await Navigator.pushNamed(context, '/add-transaction');
          _loadData();
        },
        backgroundColor: const Color(0xFF667eea),
        icon: const Icon(Icons.add),
        label: const Text('Add Transaction'),
      ),
      bottomNavigationBar: BottomNavigationBar(
        currentIndex: _selectedIndex,
        selectedItemColor: const Color(0xFF667eea),
        unselectedItemColor: Colors.grey,
        type: BottomNavigationBarType.fixed,
        onTap: (index) {
          setState(() => _selectedIndex = index);
          switch (index) {
            case 0:
              break;
            case 1:
              Navigator.pushNamed(context, '/transactions')
                  .then((_) => _loadData());
              break;
            case 2:
              Navigator.pushNamed(context, '/reports')
                  .then((_) => _loadData());
              break;
            case 3:
              Navigator.pushNamed(context, '/profile')
                  .then((_) => _loadData());
              break;
          }
        },
        items: const [
          BottomNavigationBarItem(
            icon: Icon(Icons.dashboard),
            label: 'Dashboard',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.list),
            label: 'Transactions',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.bar_chart),
            label: 'Reports',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.person),
            label: 'Profile',
          ),
        ],
      ),
    );
  }

  Widget _buildHeader() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: [Color(0xFF667eea), Color(0xFF764ba2)],
        ),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(
            'Welcome back, $_username!',
            style: const TextStyle(
              color: Colors.white,
              fontSize: 24,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          const Text(
            'Here\'s your financial overview',
            style: TextStyle(color: Colors.white70, fontSize: 16),
          ),
        ],
      ),
    );
  }

  // ✅ NEW: banner shown when one or more budgets are exceeded this month
  Widget _buildBudgetAlert() {
    return Container(
      margin: const EdgeInsets.fromLTRB(16, 16, 16, 0),
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.red.withOpacity(0.1),
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: Colors.red.withOpacity(0.3)),
      ),
      child: Row(
        children: [
          const Icon(Icons.warning_amber_rounded, color: Colors.red),
          const SizedBox(width: 10),
          Expanded(
            child: Text(
              'Budget exceeded for: ${_exceededBudgetCategories.join(', ')}',
              style: const TextStyle(color: Colors.red, fontWeight: FontWeight.w600),
            ),
          ),
          TextButton(
            onPressed: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => const BudgetScreen()),
              ).then((_) => _loadData());
            },
            child: const Text('View'),
          ),
        ],
      ),
    );
  }

  Widget _buildStatsCards() {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        children: [
          Row(
            children: [
              Expanded(
                child: _buildStatCard(
                  'Income',
                  '₹${_totalIncome.toStringAsFixed(2)}',
                  Icons.arrow_downward,
                  Colors.green,
                ),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: _buildStatCard(
                  'Expense',
                  '₹${_totalExpense.toStringAsFixed(2)}',
                  Icons.arrow_upward,
                  Colors.red,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          _buildStatCard(
            'Balance',
            '₹${_balance.toStringAsFixed(2)}',
            Icons.account_balance_wallet,
            _balance >= 0 ? Colors.blue : Colors.orange,
            isLarge: true,
          ),
        ],
      ),
    );
  }

  Widget _buildStatCard(
      String title,
      String amount,
      IconData icon,
      Color color, {
        bool isLarge = false,
      }) {
    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(15),
      ),
      child: Container(
        padding: EdgeInsets.all(isLarge ? 24 : 16),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(15),
          gradient: LinearGradient(
            begin: Alignment.topLeft,
            end: Alignment.bottomRight,
            colors: [color.withOpacity(0.7), color],
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 16,
                    fontWeight: FontWeight.w500,
                  ),
                ),
                Icon(icon, color: Colors.white, size: isLarge ? 32 : 24),
              ],
            ),
            SizedBox(height: isLarge ? 16 : 12),
            Text(
              amount,
              style: TextStyle(
                color: Colors.white,
                fontSize: isLarge ? 32 : 24,
                fontWeight: FontWeight.bold,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildQuickActions() {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              const Text(
                'Quick Actions',
                style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickActionButton(
                    'Add Income',
                    Icons.add_circle,
                    Colors.green,
                        () {
                      Navigator.pushNamed(
                        context,
                        '/add-transaction',
                        arguments: 'income',
                      ).then((_) => _loadData());
                    },
                  ),
                  _buildQuickActionButton(
                    'Add Expense',
                    Icons.remove_circle,
                    Colors.red,
                        () {
                      Navigator.pushNamed(
                        context,
                        '/add-transaction',
                        arguments: 'expense',
                      ).then((_) => _loadData());
                    },
                  ),
                  _buildQuickActionButton(
                    'View Reports',
                    Icons.bar_chart,
                    Colors.blue,
                        () {
                      Navigator.pushNamed(context, '/reports')
                          .then((_) => _loadData());
                    },
                  ),
                ],
              ),
              const SizedBox(height: 20),
              // ✅ NEW: second row for the newly added feature areas
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceAround,
                children: [
                  _buildQuickActionButton(
                    'Budgets',
                    Icons.pie_chart,
                    Colors.deepPurple,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const BudgetScreen()),
                      ).then((_) => _loadData());
                    },
                  ),
                  _buildQuickActionButton(
                    'Recurring',
                    Icons.autorenew,
                    Colors.teal,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const RecurringScreen()),
                      ).then((_) => _loadData());
                    },
                  ),
                  _buildQuickActionButton(
                    'Goals',
                    Icons.flag,
                    Colors.orange,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (context) => const GoalsScreen()),
                      ).then((_) => _loadData());
                    },
                  ),
                  _buildQuickActionButton(
                    'Payments',
                    Icons.credit_card,
                    Colors.indigo,
                        () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                            builder: (context) => const PaymentAnalyticsScreen()),
                      ).then((_) => _loadData());
                    },
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildQuickActionButton(
      String label,
      IconData icon,
      Color color,
      VoidCallback onTap,
      ) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Column(
        children: [
          Container(
            padding: const EdgeInsets.all(16),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 32),
          ),
          const SizedBox(height: 8),
          Text(
            label,
            style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
          ),
        ],
      ),
    );
  }

  Widget _buildRecentTransactions() {
    return Padding(
      padding: const EdgeInsets.all(16),
      child: Card(
        elevation: 4,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(15),
        ),
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Recent Transactions',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  TextButton(
                    onPressed: () {
                      Navigator.pushNamed(context, '/transactions')
                          .then((_) => _loadData());
                    },
                    child: const Text('View All'),
                  ),
                ],
              ),
              const SizedBox(height: 10),
              if (_recentTransactions.isEmpty)
                const Padding(
                  padding: EdgeInsets.all(20),
                  child: Center(
                    child: Text(
                      'No transactions yet',
                      style: TextStyle(color: Colors.grey),
                    ),
                  ),
                )
              else
                ..._recentTransactions.take(5).map((tx) {
                  final isIncome = tx['type'] == 'income';
                  return ListTile(
                    leading: CircleAvatar(
                      backgroundColor: isIncome
                          ? Colors.green.withOpacity(0.2)
                          : Colors.red.withOpacity(0.2),
                      child: Icon(
                        isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                        color: isIncome ? Colors.green : Colors.red,
                      ),
                    ),
                    title: Text(tx['category'] ?? 'Unknown'),
                    subtitle: Text(
                      [
                        if ((tx['description'] ?? '').toString().isNotEmpty)
                          tx['description'],
                        tx['paymentMethod'] ?? 'Cash',
                      ].join(' • '),
                    ),
                    trailing: Text(
                      '₹${(tx['amount'] as double).toStringAsFixed(2)}',
                      style: TextStyle(
                        color: isIncome ? Colors.green : Colors.red,
                        fontWeight: FontWeight.bold,
                        fontSize: 16,
                      ),
                    ),
                  );
                }),
            ],
          ),
        ),
      ),
    );
  }
}