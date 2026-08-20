import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/budget_service.dart';

class BudgetScreen extends StatefulWidget {
  const BudgetScreen({Key? key}) : super(key: key);

  @override
  State<BudgetScreen> createState() => _BudgetScreenState();
}

class _BudgetScreenState extends State<BudgetScreen> {
  final List<String> _expenseCategories = [
    'Food', 'Transport', 'Shopping', 'Bills',
    'Entertainment', 'Health', 'Education', 'Other',
  ];

  late String _selectedMonth;
  Map<String, double> _spentMap = {};
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _selectedMonth = DateFormat('yyyy-MM').format(DateTime.now());
    _loadSpent();
  }

  Future<void> _loadSpent() async {
    setState(() => _isLoading = true);
    final spent = await BudgetService.instance.getSpentByCategory(_selectedMonth);
    if (mounted) {
      setState(() {
        _spentMap = spent;
        _isLoading = false;
      });
    }
  }

  void _changeMonth(int offset) {
    final current = DateFormat('yyyy-MM').parse(_selectedMonth);
    final newDate = DateTime(current.year, current.month + offset, 1);
    setState(() => _selectedMonth = DateFormat('yyyy-MM').format(newDate));
    _loadSpent();
  }

  Future<void> _showBudgetDialog(String category, double? existingLimit) async {
    final controller = TextEditingController(
      text: existingLimit != null ? existingLimit.toStringAsFixed(0) : '',
    );

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: Text('Set Budget for $category'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(
            labelText: 'Monthly Limit',
            prefixText: '₹ ',
            border: OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () async {
              final value = double.tryParse(controller.text);
              if (value != null && value > 0) {
                await BudgetService.instance.setBudget(
                  category: category,
                  limit: value,
                  month: _selectedMonth,
                );
                if (mounted) Navigator.pop(context);
              }
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final monthLabel =
    DateFormat('MMMM yyyy').format(DateFormat('yyyy-MM').parse(_selectedMonth));

    return Scaffold(
      appBar: AppBar(
        title: const Text('Budgets', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF667eea),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: Column(
        children: [
          Container(
            padding: const EdgeInsets.symmetric(vertical: 8, horizontal: 8),
            color: const Color(0xFF667eea).withOpacity(0.08),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                IconButton(
                  icon: const Icon(Icons.chevron_left),
                  onPressed: () => _changeMonth(-1),
                ),
                Text(
                  monthLabel,
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
                ),
                IconButton(
                  icon: const Icon(Icons.chevron_right),
                  onPressed: () => _changeMonth(1),
                ),
              ],
            ),
          ),
          Expanded(
            child: _isLoading
                ? const Center(child: CircularProgressIndicator())
                : RefreshIndicator(
              onRefresh: _loadSpent,
              child: StreamBuilder<dynamic>(
                stream: BudgetService.instance.streamBudgets(_selectedMonth),
                builder: (context, snapshot) {
                  final Map<String, double> budgetMap = {};
                  if (snapshot.hasData) {
                    for (var doc in snapshot.data.docs) {
                      final data = doc.data() as Map<String, dynamic>;
                      budgetMap[data['category']] =
                          (data['limit'] as num).toDouble();
                    }
                  }

                  return ListView.builder(
                    physics: const AlwaysScrollableScrollPhysics(),
                    padding: const EdgeInsets.all(16),
                    itemCount: _expenseCategories.length,
                    itemBuilder: (context, index) {
                      final category = _expenseCategories[index];
                      final limit = budgetMap[category];
                      final spent = _spentMap[category] ?? 0.0;
                      final hasBudget = limit != null && limit > 0;
                      final progress =
                      hasBudget ? (spent / limit).clamp(0.0, 1.0) : 0.0;
                      final isOver = hasBudget && spent > limit;

                      return Card(
                        margin: const EdgeInsets.only(bottom: 12),
                        elevation: 3,
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        child: Padding(
                          padding: const EdgeInsets.all(16),
                          child: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: [
                              Row(
                                mainAxisAlignment:
                                MainAxisAlignment.spaceBetween,
                                children: [
                                  Text(category,
                                      style: const TextStyle(
                                          fontSize: 16,
                                          fontWeight: FontWeight.bold)),
                                  GestureDetector(
                                    onTap: () =>
                                        _showBudgetDialog(category, limit),
                                    child: Icon(
                                      hasBudget
                                          ? Icons.edit
                                          : Icons.add_circle_outline,
                                      color: const Color(0xFF667eea),
                                    ),
                                  ),
                                ],
                              ),
                              const SizedBox(height: 8),
                              if (hasBudget) ...[
                                ClipRRect(
                                  borderRadius: BorderRadius.circular(8),
                                  child: LinearProgressIndicator(
                                    value: progress,
                                    minHeight: 10,
                                    backgroundColor: Colors.grey[300],
                                    valueColor: AlwaysStoppedAnimation(
                                      isOver
                                          ? Colors.red
                                          : (progress > 0.8
                                          ? Colors.orange
                                          : Colors.green),
                                    ),
                                  ),
                                ),
                                const SizedBox(height: 6),
                                Row(
                                  mainAxisAlignment:
                                  MainAxisAlignment.spaceBetween,
                                  children: [
                                    Text('₹${spent.toStringAsFixed(0)} spent',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                    Text('of ₹${limit.toStringAsFixed(0)}',
                                        style: const TextStyle(
                                            fontSize: 12, color: Colors.grey)),
                                  ],
                                ),
                                if (isOver)
                                  Padding(
                                    padding: const EdgeInsets.only(top: 6),
                                    child: Row(
                                      children: const [
                                        Icon(Icons.warning_amber_rounded,
                                            color: Colors.red, size: 16),
                                        SizedBox(width: 4),
                                        Text('Budget exceeded!',
                                            style: TextStyle(
                                                color: Colors.red,
                                                fontSize: 12,
                                                fontWeight: FontWeight.bold)),
                                      ],
                                    ),
                                  ),
                              ] else
                                const Text('No budget set',
                                    style: TextStyle(
                                        color: Colors.grey, fontSize: 13)),
                            ],
                          ),
                        ),
                      );
                    },
                  );
                },
              ),
            ),
          ),
        ],
      ),
    );
  }
}