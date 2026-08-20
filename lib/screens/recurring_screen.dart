import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import '../services/recurring_service.dart';

class RecurringScreen extends StatefulWidget {
  const RecurringScreen({Key? key}) : super(key: key);

  @override
  State<RecurringScreen> createState() => _RecurringScreenState();
}

class _RecurringScreenState extends State<RecurringScreen> {
  final List<String> _expenseCategories = [
    'Food', 'Transport', 'Shopping', 'Bills',
    'Entertainment', 'Health', 'Education', 'Other',
  ];
  final List<String> _incomeCategories = [
    'Salary', 'Business', 'Investment', 'Gift', 'Other',
  ];
  final List<String> _paymentMethods = ['Cash', 'Card', 'UPI'];

  Future<void> _showAddDialog() async {
    final amountController = TextEditingController();
    final descController = TextEditingController();
    String type = 'expense';
    String category = _expenseCategories[0];
    String frequency = 'monthly';
    String paymentMethod = 'Cash';
    DateTime startDate = DateTime.now();

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) {
          final categories = type == 'income' ? _incomeCategories : _expenseCategories;
          if (!categories.contains(category)) category = categories[0];

          return AlertDialog(
            title: const Text('Add Recurring Item'),
            content: SingleChildScrollView(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      Expanded(
                        child: RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Income'),
                          value: 'income',
                          groupValue: type,
                          onChanged: (v) => setDialogState(() => type = v!),
                        ),
                      ),
                      Expanded(
                        child: RadioListTile<String>(
                          contentPadding: EdgeInsets.zero,
                          title: const Text('Expense'),
                          value: 'expense',
                          groupValue: type,
                          onChanged: (v) => setDialogState(() => type = v!),
                        ),
                      ),
                    ],
                  ),
                  TextField(
                    controller: amountController,
                    keyboardType: TextInputType.number,
                    decoration:
                    const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: category,
                    decoration: const InputDecoration(labelText: 'Category'),
                    items: categories
                        .map((c) => DropdownMenuItem(value: c, child: Text(c)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => category = v!),
                  ),
                  const SizedBox(height: 10),
                  TextField(
                    controller: descController,
                    decoration: const InputDecoration(labelText: 'Description'),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: frequency,
                    decoration: const InputDecoration(labelText: 'Frequency'),
                    items: const [
                      DropdownMenuItem(value: 'weekly', child: Text('Weekly')),
                      DropdownMenuItem(value: 'monthly', child: Text('Monthly')),
                    ],
                    onChanged: (v) => setDialogState(() => frequency = v!),
                  ),
                  const SizedBox(height: 10),
                  DropdownButtonFormField<String>(
                    value: paymentMethod,
                    decoration: const InputDecoration(labelText: 'Payment Method'),
                    items: _paymentMethods
                        .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                        .toList(),
                    onChanged: (v) => setDialogState(() => paymentMethod = v!),
                  ),
                  const SizedBox(height: 10),
                  InkWell(
                    onTap: () async {
                      final picked = await showDatePicker(
                        context: context,
                        initialDate: startDate,
                        firstDate: DateTime(2020),
                        lastDate: DateTime(2100),
                      );
                      if (picked != null) setDialogState(() => startDate = picked);
                    },
                    child: InputDecorator(
                      decoration: const InputDecoration(labelText: 'Start Date'),
                      child: Text(DateFormat('dd/MM/yyyy').format(startDate)),
                    ),
                  ),
                ],
              ),
            ),
            actions: [
              TextButton(
                  onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
              ElevatedButton(
                onPressed: () async {
                  final amount = double.tryParse(amountController.text);
                  if (amount == null || amount <= 0) return;
                  await RecurringService.instance.addRecurring(
                    type: type,
                    amount: amount,
                    category: category,
                    description: descController.text,
                    frequency: frequency,
                    startDate: startDate,
                    paymentMethod: paymentMethod,
                  );
                  if (mounted) Navigator.pop(context);
                },
                child: const Text('Save'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Recurring Transactions', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF667eea),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<dynamic>(
        stream: RecurringService.instance.streamRecurring(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data.docs;
          if (docs.isEmpty) {
            return const Center(
              child: Text('No recurring transactions yet',
                  style: TextStyle(color: Colors.grey)),
            );
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final isIncome = data['type'] == 'income';
              final isPaused = data['isPaused'] ?? false;

              return Card(
                margin: const EdgeInsets.only(bottom: 10),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: ListTile(
                  leading: CircleAvatar(
                    backgroundColor:
                    isIncome ? Colors.green.withOpacity(0.2) : Colors.red.withOpacity(0.2),
                    child: Icon(
                      isIncome ? Icons.arrow_downward : Icons.arrow_upward,
                      color: isIncome ? Colors.green : Colors.red,
                    ),
                  ),
                  title: Text(
                      '${data['category']} • ₹${(data['amount'] as num).toStringAsFixed(0)}',
                      style: const TextStyle(fontWeight: FontWeight.bold)),
                  subtitle: Text(
                    '${data['frequency']} • Next: ${data['nextDate']}${isPaused ? ' • Paused' : ''}',
                    style: TextStyle(color: isPaused ? Colors.orange : Colors.grey[600]),
                  ),
                  trailing: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: Icon(isPaused ? Icons.play_circle : Icons.pause_circle,
                            color: const Color(0xFF667eea)),
                        onPressed: () =>
                            RecurringService.instance.togglePause(doc.id, !isPaused),
                      ),
                      IconButton(
                        icon: const Icon(Icons.delete, color: Colors.red),
                        onPressed: () => RecurringService.instance.deleteRecurring(doc.id),
                      ),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddDialog,
        backgroundColor: const Color(0xFF667eea),
        child: const Icon(Icons.add),
      ),
    );
  }
}