import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_notifier.dart';
import '../domain/goal_model.dart';
import '../domain/goal_usecases.dart';

class GoalsListScreen extends StatelessWidget {
  const GoalsListScreen({super.key});

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _addProgress(BuildContext context, GoalModel goal) async {
    final ctrl = TextEditingController();
    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: Text(goal.title),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Progress sekarang: ${_fmt(goal.currentProgress)}/${_fmt(goal.targetValue)} ${goal.unit}',
            ),
            const SizedBox(height: 12),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                labelText: 'Tambah (${goal.unit})',
              ),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () =>
                Navigator.pop(ctx, double.tryParse(ctrl.text.trim())),
            child: const Text('Simpan'),
          ),
        ],
      ),
    );

    if (amount == null) return;
    await UpdateGoalProgressUseCase()(
      goal.id,
      goal.currentProgress + amount,
    );
  }

  Future<void> _confirmDelete(BuildContext context, GoalModel goal) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Target'),
        content: Text('Hapus "${goal.title}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );
    if (confirmed == true) await DeleteGoalUseCase()(goal.id);
  }

  @override
  Widget build(BuildContext context) {
    final uid = authNotifier.uid;

    return Scaffold(
      appBar: AppBar(title: const Text('Target Harian')),
      body: uid == null
          ? const Center(child: Text('Silakan login terlebih dahulu'))
          : StreamBuilder<List<GoalModel>>(
              stream: GetGoalsUseCase()(uid),
              builder: (context, snapshot) {
                if (snapshot.hasError) {
                  return Center(child: Text('Terjadi kesalahan: ${snapshot.error}'));
                }
                if (!snapshot.hasData) {
                  return const Center(child: CircularProgressIndicator());
                }
                final goals = snapshot.data!;
                if (goals.isEmpty) {
                  return const Center(
                    child: Text('Belum ada target. Tambahkan satu!'),
                  );
                }
                return ListView.builder(
                  padding: const EdgeInsets.all(12),
                  itemCount: goals.length,
                  itemBuilder: (context, i) =>
                      _GoalCard(goal: goals[i], screen: this),
                );
              },
            ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/goals/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}

class _GoalCard extends StatelessWidget {
  const _GoalCard({required this.goal, required this.screen});

  final GoalModel goal;
  final GoalsListScreen screen;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        await screen._confirmDelete(context, goal);
        return false; // delete dilakukan via stream, bukan remove lokal
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 20),
        color: colorScheme.errorContainer,
        child: Icon(Icons.delete, color: colorScheme.onErrorContainer),
      ),
      child: Card(
        child: InkWell(
          onTap: () => screen._addProgress(context, goal),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Expanded(
                      child: Text(
                        goal.title,
                        style: Theme.of(context).textTheme.titleMedium,
                      ),
                    ),
                    if (goal.isCompleted)
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 2,
                        ),
                        decoration: BoxDecoration(
                          color: colorScheme.primaryContainer,
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          'Selesai ✅',
                          style: TextStyle(
                            color: colorScheme.onPrimaryContainer,
                            fontSize: 12,
                          ),
                        ),
                      ),
                  ],
                ),
                const SizedBox(height: 8),
                LinearProgressIndicator(value: goal.progressPercent),
                const SizedBox(height: 8),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      '${GoalsListScreen._fmt(goal.currentProgress)}/${GoalsListScreen._fmt(goal.targetValue)} ${goal.unit}',
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    IconButton(
                      icon: const Icon(Icons.add_circle_outline),
                      tooltip: 'Tambah 1',
                      onPressed: () => UpdateGoalProgressUseCase()(
                        goal.id,
                        goal.currentProgress + 1,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
