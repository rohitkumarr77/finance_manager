import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class PaymentAnalyticsScreen extends StatelessWidget {
  const PaymentAnalyticsScreen({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;
    if (user == null) {
      return const Scaffold(body: Center(child: Text('User not logged in')));
    }

    final txRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions');

    return Scaffold(
      appBar: AppBar(
        title: const Text('Payment Analytics', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF667eea),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<QuerySnapshot>(
        stream: txRef.snapshots(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }

          final Map<String, double> methodTotals = {};
          final Map<String, int> methodCounts = {};

          for (var doc in snapshot.data!.docs) {
            final data = doc.data() as Map<String, dynamic>;
            final method = data['paymentMethod'] ?? 'Cash';
            final amount = (data['amount'] as num?)?.toDouble() ?? 0.0;
            methodTotals[method] = (methodTotals[method] ?? 0) + amount;
            methodCounts[method] = (methodCounts[method] ?? 0) + 1;
          }

          if (methodTotals.isEmpty) {
            return const Center(
                child: Text('No transactions yet', style: TextStyle(color: Colors.grey)));
          }

          final colors = {
            'Cash': Colors.green,
            'Card': Colors.blue,
            'UPI': Colors.purple,
          };

          final mostUsed =
          methodCounts.entries.reduce((a, b) => a.value >= b.value ? a : b);

          return SingleChildScrollView(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Card(
                  color: const Color(0xFF667eea),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  child: Padding(
                    padding: const EdgeInsets.all(16),
                    child: Row(
                      children: [
                        const Icon(Icons.insights, color: Colors.white, size: 32),
                        const SizedBox(width: 16),
                        Expanded(
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              const Text('Most-used method',
                                  style: TextStyle(color: Colors.white70)),
                              Text(
                                '${mostUsed.key} (${mostUsed.value} transactions)',
                                style: const TextStyle(
                                    color: Colors.white,
                                    fontSize: 18,
                                    fontWeight: FontWeight.bold),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
                const Text('Spending by Payment Method',
                    style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
                const SizedBox(height: 16),
                SizedBox(
                  height: 220,
                  child: PieChart(
                    PieChartData(
                      sections: methodTotals.entries.map((e) {
                        return PieChartSectionData(
                          value: e.value,
                          title: e.key,
                          color: colors[e.key] ?? Colors.grey,
                          radius: 90,
                          titleStyle: const TextStyle(
                              color: Colors.white, fontWeight: FontWeight.bold, fontSize: 12),
                        );
                      }).toList(),
                      sectionsSpace: 2,
                      centerSpaceRadius: 30,
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                ...methodTotals.entries.map((e) {
                  return Card(
                    margin: const EdgeInsets.only(bottom: 10),
                    child: ListTile(
                      leading: CircleAvatar(
                        backgroundColor: (colors[e.key] ?? Colors.grey).withOpacity(0.2),
                        child: Icon(Icons.payment, color: colors[e.key] ?? Colors.grey),
                      ),
                      title: Text(e.key, style: const TextStyle(fontWeight: FontWeight.bold)),
                      subtitle: Text('${methodCounts[e.key]} transactions'),
                      trailing: Text('₹${e.value.toStringAsFixed(2)}',
                          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ),
                  );
                }),
              ],
            ),
          );
        },
      ),
    );
  }
}