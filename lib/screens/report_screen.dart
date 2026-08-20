import 'package:flutter/material.dart';
import 'package:fl_chart/fl_chart.dart';
import 'package:intl/intl.dart';
import 'package:firebase_auth/firebase_auth.dart';
import 'package:cloud_firestore/cloud_firestore.dart';

class ReportsScreen extends StatefulWidget {
  const ReportsScreen({Key? key}) : super(key: key);

  @override
  State<ReportsScreen> createState() => _ReportsScreenState();
}

class _ReportsScreenState extends State<ReportsScreen> {
  // Used to force StreamBuilder to re-trigger on manual refresh
  int _refreshKey = 0;

  void _loadData() {
    setState(() => _refreshKey++);
  }

  @override
  Widget build(BuildContext context) {
    final user = FirebaseAuth.instance.currentUser;

    if (user == null) {
      return const Scaffold(
        body: Center(child: Text("User not logged in")),
      );
    }

    final transactionsRef = FirebaseFirestore.instance
        .collection('users')
        .doc(user.uid)
        .collection('transactions');

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Reports',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFF667eea),
        iconTheme: const IconThemeData(color: Colors.white),
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh, color: Colors.white),
            onPressed: _loadData,
          ),
        ],
      ),
      body: StreamBuilder<QuerySnapshot>(
        key: ValueKey(_refreshKey),
        stream: transactionsRef.snapshots(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          final docs = snapshot.data?.docs ?? [];

          double income = 0;
          double expense = 0;
          Map<String, double> expenseCategoryMap = {};
          Map<String, double> incomeCategoryMap = {};

          // month (yyyy-MM) -> totals, for trend/comparison charts
          final Map<String, double> monthlyIncome = {};
          final Map<String, double> monthlyExpense = {};

          // For "Top expenses" list
          final List<Map<String, dynamic>> allExpenses = [];

          for (var doc in docs) {
            final data = doc.data() as Map<String, dynamic>;
            final double amount = (data['amount'] as num).toDouble();
            final String type = data['type'] ?? '';
            final String category = data['category'] ?? 'Other';
            final String dateStr = data['date']?.toString() ?? '';
            final String monthKey =
            dateStr.length >= 7 ? dateStr.substring(0, 7) : '';

            if (type == 'income') {
              income += amount;
              incomeCategoryMap[category] =
                  (incomeCategoryMap[category] ?? 0) + amount;
              if (monthKey.isNotEmpty) {
                monthlyIncome[monthKey] = (monthlyIncome[monthKey] ?? 0) + amount;
              }
            } else {
              expense += amount;
              expenseCategoryMap[category] =
                  (expenseCategoryMap[category] ?? 0) + amount;
              if (monthKey.isNotEmpty) {
                monthlyExpense[monthKey] = (monthlyExpense[monthKey] ?? 0) + amount;
              }
              allExpenses.add({
                'category': category,
                'description': data['description'] ?? '',
                'amount': amount,
                'date': dateStr,
              });
            }
          }

          final double balance = income - expense;

          // Build last 6 months (including current) as ordered month keys
          final now = DateTime.now();
          final List<String> last6Months = List.generate(6, (i) {
            final d = DateTime(now.year, now.month - (5 - i), 1);
            return DateFormat('yyyy-MM').format(d);
          });

          // Top 5 expenses by amount
          final topExpenses = List<Map<String, dynamic>>.from(allExpenses)
            ..sort((a, b) => (b['amount'] as double).compareTo(a['amount'] as double));
          final top5 = topExpenses.take(5).toList();

          return RefreshIndicator(
            onRefresh: () async => _loadData(),
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Financial Summary',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 20),

                  _buildSummaryCard(
                    'Total Income',
                    income,
                    Colors.green,
                    Icons.trending_up,
                  ),
                  _buildSummaryCard(
                    'Total Expense',
                    expense,
                    Colors.red,
                    Icons.trending_down,
                  ),
                  _buildSummaryCard(
                    'Net Balance',
                    balance,
                    Colors.blue,
                    Icons.account_balance,
                  ),

                  const SizedBox(height: 30),

                  // ✅ NEW: Monthly trend line chart
                  const Text(
                    'Monthly Trend',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildTrendLineChart(last6Months, monthlyIncome, monthlyExpense),

                  const SizedBox(height: 30),

                  // ✅ NEW: Income vs Expense bar chart comparison
                  const Text(
                    'Income vs Expense (by month)',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildComparisonBarChart(last6Months, monthlyIncome, monthlyExpense),

                  const SizedBox(height: 30),

                  const Text(
                    'Expense Breakdown',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildPieChart(expenseCategoryMap),

                  const SizedBox(height: 30),

                  // ✅ NEW: Top expenses list
                  const Text(
                    'Top Expenses',
                    style: TextStyle(fontSize: 20, fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 10),
                  _buildTopExpensesList(top5),

                  const SizedBox(height: 30),

                  const Text(
                    'Category Breakdown',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  const SizedBox(height: 10),

                  _buildCategoryList(incomeCategoryMap, expenseCategoryMap),
                ],
              ),
            ),
          );
        },
      ),
    );
  }

  Widget _buildSummaryCard(
      String title, double value, Color color, IconData icon) {
    return Card(
      margin: const EdgeInsets.only(bottom: 16),
      elevation: 4,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(12),
          gradient: LinearGradient(
            colors: [color.withOpacity(0.7), color],
          ),
        ),
        child: Row(
          children: [
            Icon(icon, size: 40, color: Colors.white),
            const SizedBox(width: 20),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  title,
                  style: const TextStyle(
                    color: Colors.white70,
                    fontSize: 14,
                  ),
                ),
                const SizedBox(height: 4),
                Text(
                  '₹${value.toStringAsFixed(2)}',
                  style: const TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Line chart showing income & expense trend over last 6 months
  Widget _buildTrendLineChart(
      List<String> months,
      Map<String, double> monthlyIncome,
      Map<String, double> monthlyExpense,
      ) {
    final incomeSpots = <FlSpot>[];
    final expenseSpots = <FlSpot>[];
    double maxY = 1;

    for (int i = 0; i < months.length; i++) {
      final inc = monthlyIncome[months[i]] ?? 0;
      final exp = monthlyExpense[months[i]] ?? 0;
      incomeSpots.add(FlSpot(i.toDouble(), inc));
      expenseSpots.add(FlSpot(i.toDouble(), exp));
      if (inc > maxY) maxY = inc;
      if (exp > maxY) maxY = exp;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: LineChart(
                LineChartData(
                  minY: 0,
                  maxY: maxY * 1.2,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= months.length) {
                            return const SizedBox.shrink();
                          }
                          final label = DateFormat('MMM')
                              .format(DateFormat('yyyy-MM').parse(months[idx]));
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(label, style: const TextStyle(fontSize: 11)),
                          );
                        },
                      ),
                    ),
                  ),
                  borderData: FlBorderData(show: false),
                  lineBarsData: [
                    LineChartBarData(
                      spots: incomeSpots,
                      isCurved: true,
                      color: Colors.green,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData:
                      BarAreaData(show: true, color: Colors.green.withOpacity(0.1)),
                    ),
                    LineChartBarData(
                      spots: expenseSpots,
                      isCurved: true,
                      color: Colors.red,
                      barWidth: 3,
                      dotData: const FlDotData(show: true),
                      belowBarData:
                      BarAreaData(show: true, color: Colors.red.withOpacity(0.1)),
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(Colors.green, 'Income'),
                const SizedBox(width: 20),
                _legendDot(Colors.red, 'Expense'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  // ✅ NEW: Grouped bar chart comparing income vs expense per month
  Widget _buildComparisonBarChart(
      List<String> months,
      Map<String, double> monthlyIncome,
      Map<String, double> monthlyExpense,
      ) {
    double maxY = 1;
    for (final m in months) {
      final inc = monthlyIncome[m] ?? 0;
      final exp = monthlyExpense[m] ?? 0;
      if (inc > maxY) maxY = inc;
      if (exp > maxY) maxY = exp;
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.fromLTRB(8, 20, 20, 12),
        child: Column(
          children: [
            SizedBox(
              height: 220,
              child: BarChart(
                BarChartData(
                  maxY: maxY * 1.2,
                  gridData: const FlGridData(show: true, drawVerticalLine: false),
                  borderData: FlBorderData(show: false),
                  titlesData: FlTitlesData(
                    leftTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    rightTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    topTitles: const AxisTitles(
                      sideTitles: SideTitles(showTitles: false),
                    ),
                    bottomTitles: AxisTitles(
                      sideTitles: SideTitles(
                        showTitles: true,
                        getTitlesWidget: (value, meta) {
                          final idx = value.toInt();
                          if (idx < 0 || idx >= months.length) {
                            return const SizedBox.shrink();
                          }
                          final label = DateFormat('MMM')
                              .format(DateFormat('yyyy-MM').parse(months[idx]));
                          return Padding(
                            padding: const EdgeInsets.only(top: 6),
                            child: Text(label, style: const TextStyle(fontSize: 11)),
                          );
                        },
                      ),
                    ),
                  ),
                  barGroups: List.generate(months.length, (i) {
                    final inc = monthlyIncome[months[i]] ?? 0;
                    final exp = monthlyExpense[months[i]] ?? 0;
                    return BarChartGroupData(
                      x: i,
                      barRods: [
                        BarChartRodData(
                            toY: inc, color: Colors.green, width: 8,
                            borderRadius: BorderRadius.circular(4)),
                        BarChartRodData(
                            toY: exp, color: Colors.red, width: 8,
                            borderRadius: BorderRadius.circular(4)),
                      ],
                      barsSpace: 4,
                    );
                  }),
                ),
              ),
            ),
            const SizedBox(height: 12),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                _legendDot(Colors.green, 'Income'),
                const SizedBox(width: 20),
                _legendDot(Colors.red, 'Expense'),
              ],
            ),
          ],
        ),
      ),
    );
  }

  Widget _legendDot(Color color, String label) {
    return Row(
      mainAxisSize: MainAxisSize.min,
      children: [
        Container(
          width: 10,
          height: 10,
          decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        ),
        const SizedBox(width: 6),
        Text(label, style: const TextStyle(fontSize: 12)),
      ],
    );
  }

  // ✅ NEW: Top 5 highest expenses
  Widget _buildTopExpensesList(List<Map<String, dynamic>> top5) {
    if (top5.isEmpty) {
      return Card(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
          child: const Text('No expenses yet', style: TextStyle(color: Colors.grey)),
        ),
      );
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(
        children: top5.asMap().entries.map((entry) {
          final rank = entry.key + 1;
          final item = entry.value;
          return ListTile(
            leading: CircleAvatar(
              backgroundColor: Colors.red.withOpacity(0.15),
              child: Text('#$rank',
                  style: const TextStyle(color: Colors.red, fontWeight: FontWeight.bold)),
            ),
            title: Text(item['category'], style: const TextStyle(fontWeight: FontWeight.bold)),
            subtitle: Text(
              (item['description'] as String).isNotEmpty
                  ? '${item['description']} • ${item['date']}'
                  : item['date'],
            ),
            trailing: Text(
              '₹${(item['amount'] as double).toStringAsFixed(2)}',
              style: const TextStyle(
                  color: Colors.red, fontWeight: FontWeight.bold, fontSize: 16),
            ),
          );
        }).toList(),
      ),
    );
  }

  Widget _buildPieChart(Map<String, double> data) {
    if (data.isEmpty) {
      return Card(
        elevation: 4,
        child: Container(
          height: 200,
          alignment: Alignment.center,
          child: const Text(
            'No expense data',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final colors = [
      Colors.blue,
      Colors.red,
      Colors.green,
      Colors.orange,
      Colors.purple,
      Colors.teal,
      Colors.pink,
      Colors.amber,
    ];

    final entries = data.entries.toList();

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          children: [
            SizedBox(
              height: 250,
              child: PieChart(
                PieChartData(
                  sections: entries.asMap().entries.map((entry) {
                    final i = entry.key;
                    final e = entry.value;
                    return PieChartSectionData(
                      value: e.value,
                      title: '',
                      color: colors[i % colors.length],
                      radius: 100,
                    );
                  }).toList(),
                  sectionsSpace: 2,
                  centerSpaceRadius: 40,
                ),
              ),
            ),
            const SizedBox(height: 20),
            Wrap(
              spacing: 16,
              runSpacing: 8,
              children: entries.asMap().entries.map((entry) {
                final i = entry.key;
                final e = entry.value;
                return Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Container(
                      width: 14,
                      height: 14,
                      decoration: BoxDecoration(
                        color: colors[i % colors.length],
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 4),
                    Text(
                      '${e.key}: ₹${e.value.toStringAsFixed(0)}',
                      style: const TextStyle(fontSize: 12),
                    ),
                  ],
                );
              }).toList(),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildCategoryList(
      Map<String, double> incomeMap, Map<String, double> expenseMap) {
    final bool allEmpty = incomeMap.isEmpty && expenseMap.isEmpty;

    if (allEmpty) {
      return Card(
        elevation: 4,
        child: Container(
          padding: const EdgeInsets.all(20),
          alignment: Alignment.center,
          child: const Text(
            'No transactions yet',
            style: TextStyle(color: Colors.grey),
          ),
        ),
      );
    }

    final List<Widget> tiles = [];

    for (final e in incomeMap.entries) {
      tiles.add(_categoryTile(e.key, e.value, isIncome: true));
    }
    for (final e in expenseMap.entries) {
      tiles.add(_categoryTile(e.key, e.value, isIncome: false));
    }

    return Card(
      elevation: 4,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
      child: Column(children: tiles),
    );
  }

  Widget _categoryTile(String category, double amount,
      {required bool isIncome}) {
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
      title: Text(
        category,
        style: const TextStyle(fontWeight: FontWeight.bold),
      ),
      subtitle: Text(isIncome ? 'Income' : 'Expense'),
      trailing: Text(
        '₹${amount.toStringAsFixed(2)}',
        style: TextStyle(
          color: isIncome ? Colors.green : Colors.red,
          fontWeight: FontWeight.bold,
          fontSize: 16,
        ),
      ),
    );
  }
}