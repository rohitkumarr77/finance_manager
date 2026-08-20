import 'package:flutter/material.dart';
import '../services/goals_service.dart';

class GoalsScreen extends StatefulWidget {
  const GoalsScreen({Key? key}) : super(key: key);

  @override
  State<GoalsScreen> createState() => _GoalsScreenState();
}

class _GoalsScreenState extends State<GoalsScreen> {
  Future<void> _showAddGoalDialog() async {
    final nameController = TextEditingController();
    final targetController = TextEditingController();
    int priority = 2;

    await showDialog(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('New Savings Goal'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              TextField(
                controller: nameController,
                decoration: const InputDecoration(labelText: 'Goal Name'),
              ),
              const SizedBox(height: 10),
              TextField(
                controller: targetController,
                keyboardType: TextInputType.number,
                decoration:
                const InputDecoration(labelText: 'Target Amount', prefixText: '₹ '),
              ),
              const SizedBox(height: 10),
              DropdownButtonFormField<int>(
                value: priority,
                decoration: const InputDecoration(labelText: 'Priority'),
                items: const [
                  DropdownMenuItem(value: 1, child: Text('High')),
                  DropdownMenuItem(value: 2, child: Text('Medium')),
                  DropdownMenuItem(value: 3, child: Text('Low')),
                ],
                onChanged: (v) => setDialogState(() => priority = v!),
              ),
            ],
          ),
          actions: [
            TextButton(
                onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
            ElevatedButton(
              onPressed: () async {
                final target = double.tryParse(targetController.text);
                if (nameController.text.isEmpty || target == null || target <= 0) return;
                await GoalsService.instance.addGoal(
                  name: nameController.text.trim(),
                  targetAmount: target,
                  priority: priority,
                );
                if (mounted) Navigator.pop(context);
              },
              child: const Text('Create'),
            ),
          ],
        ),
      ),
    );
  }

  Future<void> _showContributeDialog(String id, double saved, double target) async {
    final controller = TextEditingController();

    await showDialog(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Add Contribution'),
        content: TextField(
          controller: controller,
          keyboardType: TextInputType.number,
          decoration: const InputDecoration(labelText: 'Amount', prefixText: '₹ '),
        ),
        actions: [
          TextButton(
              onPressed: () => Navigator.pop(context), child: const Text('Cancel')),
          ElevatedButton(
            onPressed: () async {
              final amount = double.tryParse(controller.text);
              if (amount == null || amount <= 0) return;
              final completed =
              await GoalsService.instance.addContribution(id, saved, target, amount);
              if (mounted) {
                Navigator.pop(context);
                if (completed) {
                  ScaffoldMessenger.of(context).showSnackBar(
                    const SnackBar(
                      content: Text('🎉 Goal completed! Congratulations!'),
                      backgroundColor: Colors.green,
                    ),
                  );
                }
              }
            },
            child: const Text('Add'),
          ),
        ],
      ),
    );
  }

  String _priorityLabel(int p) {
    switch (p) {
      case 1:
        return 'High';
      case 3:
        return 'Low';
      default:
        return 'Medium';
    }
  }

  Color _priorityColor(int p) {
    switch (p) {
      case 1:
        return Colors.red;
      case 3:
        return Colors.grey;
      default:
        return Colors.orange;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Savings Goals', style: TextStyle(color: Colors.white)),
        backgroundColor: const Color(0xFF667eea),
        iconTheme: const IconThemeData(color: Colors.white),
      ),
      body: StreamBuilder<dynamic>(
        stream: GoalsService.instance.streamGoals(),
        builder: (context, snapshot) {
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final docs = snapshot.data.docs;
          if (docs.isEmpty) {
            return const Center(
                child: Text('No savings goals yet', style: TextStyle(color: Colors.grey)));
          }

          return ListView.builder(
            padding: const EdgeInsets.all(16),
            itemCount: docs.length,
            itemBuilder: (context, index) {
              final doc = docs[index];
              final data = doc.data() as Map<String, dynamic>;
              final target = (data['targetAmount'] as num).toDouble();
              final saved = (data['savedAmount'] as num).toDouble();
              final progress = (saved / target).clamp(0.0, 1.0);
              final isCompleted = data['isCompleted'] == true || saved >= target;
              final priority = (data['priority'] ?? 2) as int;

              return Card(
                margin: const EdgeInsets.only(bottom: 12),
                elevation: 3,
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        children: [
                          Expanded(
                            child: Text(data['name'] ?? '',
                                style: const TextStyle(
                                    fontSize: 16, fontWeight: FontWeight.bold)),
                          ),
                          Container(
                            padding:
                            const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                            decoration: BoxDecoration(
                              color: _priorityColor(priority).withOpacity(0.15),
                              borderRadius: BorderRadius.circular(8),
                            ),
                            child: Text(_priorityLabel(priority),
                                style: TextStyle(
                                    color: _priorityColor(priority),
                                    fontSize: 12,
                                    fontWeight: FontWeight.bold)),
                          ),
                          if (isCompleted)
                            const Padding(
                              padding: EdgeInsets.only(left: 6),
                              child: Icon(Icons.check_circle, color: Colors.green, size: 20),
                            ),
                          IconButton(
                            icon: const Icon(Icons.delete, color: Colors.red, size: 20),
                            onPressed: () => GoalsService.instance.deleteGoal(doc.id),
                          ),
                        ],
                      ),
                      const SizedBox(height: 8),
                      ClipRRect(
                        borderRadius: BorderRadius.circular(8),
                        child: LinearProgressIndicator(
                          value: progress,
                          minHeight: 10,
                          backgroundColor: Colors.grey[300],
                          valueColor: AlwaysStoppedAnimation(
                              isCompleted ? Colors.green : const Color(0xFF667eea)),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text('₹${saved.toStringAsFixed(0)} saved',
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                          Text('of ₹${target.toStringAsFixed(0)}',
                              style: const TextStyle(fontSize: 12, color: Colors.grey)),
                        ],
                      ),
                      if (!isCompleted) ...[
                        const SizedBox(height: 8),
                        SizedBox(
                          width: double.infinity,
                          child: OutlinedButton(
                            onPressed: () => _showContributeDialog(doc.id, saved, target),
                            child: const Text('Add Contribution'),
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: _showAddGoalDialog,
        backgroundColor: const Color(0xFF667eea),
        child: const Icon(Icons.add),
      ),
    );
  }
}