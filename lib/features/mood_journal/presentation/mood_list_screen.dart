import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../domain/mood_model.dart';
import '../domain/mood_usecases.dart';

const _moodMeta = {
  'happy':   ('😊', 'Senang'),
  'calm':    ('😌', 'Tenang'),
  'sad':     ('😢', 'Sedih'),
  'angry':   ('😠', 'Marah'),
  'anxious': ('😰', 'Cemas'),
  'tired':   ('😴', 'Lelah'),
};

String _emoji(String mood) => _moodMeta[mood]?.$1 ?? '🙂';
String _label(String mood) => _moodMeta[mood]?.$2 ?? mood;

class MoodListScreen extends StatefulWidget {
  const MoodListScreen({super.key});

  @override
  State<MoodListScreen> createState() => _MoodListScreenState();
}

class _MoodListScreenState extends State<MoodListScreen> {
  final _getMoods = GetMoodsUseCase();
  final _deleteMood = DeleteMoodUseCase();

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _confirmDelete(MoodModel entry) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Hapus Entry?'),
        content: Text(
          'Entry mood "${_label(entry.mood)}" pada '
          '${DateFormat('d MMMM yyyy', 'id').format(entry.date)} '
          'akan dihapus permanen.',
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal'),
          ),
          TextButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: TextButton.styleFrom(
              foregroundColor: Theme.of(ctx).colorScheme.error,
            ),
            child: const Text('Hapus'),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _deleteMood(entry.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menghapus: $e')));
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _userId;

    return Scaffold(
      appBar: AppBar(title: const Text('Mood Journal')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/mood/add'),
        child: const Icon(Icons.add),
      ),
      body: uid == null
          ? const Center(child: Text('Silakan login terlebih dahulu'))
          : StreamBuilder<List<MoodModel>>(
              stream: _getMoods(uid),
              builder: (context, snap) {
                if (snap.connectionState == ConnectionState.waiting) {
                  return const Center(child: CircularProgressIndicator());
                }
                if (snap.hasError) {
                  return Center(child: Text('Error: ${snap.error}'));
                }
                final moods = snap.data ?? [];
                if (moods.isEmpty) {
                  return const Center(
                    child: Column(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Text('😶', style: TextStyle(fontSize: 48)),
                        SizedBox(height: 12),
                        Text('Belum ada catatan mood'),
                        SizedBox(height: 4),
                        Text(
                          'Tap + untuk mulai mencatat',
                          style: TextStyle(fontSize: 12),
                        ),
                      ],
                    ),
                  );
                }
                return ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 16, 16, 80),
                  itemCount: moods.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (context, i) => _MoodTile(
                    mood: moods[i],
                    onEdit: () =>
                        context.push('/mood/edit', extra: moods[i]),
                    onDelete: () => _confirmDelete(moods[i]),
                  ),
                );
              },
            ),
    );
  }
}

class _MoodTile extends StatelessWidget {
  const _MoodTile({
    required this.mood,
    required this.onEdit,
    required this.onDelete,
  });

  final MoodModel mood;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Card(
      elevation: 0,
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(16),
        side: BorderSide(color: colorScheme.outlineVariant),
      ),
      child: InkWell(
        onTap: onEdit,
        borderRadius: BorderRadius.circular(16),
        child: Padding(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          child: Row(
            children: [
              Text(_emoji(mood.mood), style: const TextStyle(fontSize: 36)),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      _label(mood.mood),
                      style: Theme.of(context).textTheme.titleSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      DateFormat('EEE, d MMM yyyy', 'id').format(mood.date),
                      style: Theme.of(context).textTheme.bodySmall?.copyWith(
                        color: colorScheme.onSurfaceVariant,
                      ),
                    ),
                    if (mood.note.isNotEmpty) ...[
                      const SizedBox(height: 4),
                      Text(
                        mood.note,
                        maxLines: 2,
                        overflow: TextOverflow.ellipsis,
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ],
                  ],
                ),
              ),
              IconButton(
                onPressed: onDelete,
                icon: Icon(
                  Icons.delete_outline,
                  color: colorScheme.error,
                  size: 20,
                ),
                tooltip: 'Hapus',
              ),
            ],
          ),
        ),
      ),
    );
  }
}
