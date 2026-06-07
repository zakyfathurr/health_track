import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../domain/mood_model.dart';
import '../domain/mood_usecases.dart';

const _moodMeta = {
  'happy':   ('😊', 'Senang', Color(0xFFFFB74D)),
  'calm':    ('😌', 'Tenang', Color(0xFF4DB6AC)),
  'sad':     ('😢', 'Sedih', Color(0xFF64B5F6)),
  'angry':   ('😠', 'Marah', Color(0xFFE57373)),
  'anxious': ('😰', 'Cemas', Color(0xFFBA68C8)),
  'tired':   ('😴', 'Lelah', Color(0xFF7986CB)),
};

String _emoji(String mood) => _moodMeta[mood]?.$1 ?? '🙂';
String _label(String mood) => _moodMeta[mood]?.$2 ?? mood;
Color _color(String mood) => _moodMeta[mood]?.$3 as Color? ?? Colors.grey;

class MoodListScreen extends StatefulWidget {
  const MoodListScreen({super.key});

  @override
  State<MoodListScreen> createState() => _MoodListScreenState();
}

class _MoodListScreenState extends State<MoodListScreen> {
  final _getMoods = GetMoodsUseCase();
  final _deleteMood = DeleteMoodUseCase();

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  Future<void> _confirmDelete(MoodModel entry, bool isDark) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF222222) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Catatan?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Catatan mood "${_label(entry.mood)}" pada '
              '${DateFormat('d MMMM yyyy', 'id').format(entry.date)} '
              'akan dihapus permanen. Yakin?',
          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade700, height: 1.5),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Hapus', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (confirmed != true) return;
    try {
      await _deleteMood(entry.id);
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text('Gagal menghapus: $e'), behavior: SnackBarBehavior.floating),
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final uid = _userId;
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        elevation: 0,
        toolbarHeight: 90,
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Jurnal Mood',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Bagaimana perasaanmu belakangan ini?',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/mood/add'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_reaction_rounded),
        label: const Text('Catat Mood', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
      body: uid == null
          ? Center(
        child: Text(
          'Silakan login terlebih dahulu',
          style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600),
        ),
      )
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

          // EMPTY STATE MODERN
          if (moods.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Container(
                    padding: const EdgeInsets.all(24),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      color: theme.primaryColor.withOpacity(0.1),
                    ),
                    child: const Text('😶', style: TextStyle(fontSize: 56)),
                  ),
                  const SizedBox(height: 24),
                  Text(
                    'Jurnal masih kosong',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Mulai catat perjalanan emosimu hari ini.',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            physics: const BouncingScrollPhysics(),
            padding: const EdgeInsets.fromLTRB(20, 8, 20, 100), // Padding bawah untuk FAB
            itemCount: moods.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, i) => _MoodTile(
              mood: moods[i],
              isDark: isDark,
              theme: theme,
              onEdit: () => context.push('/mood/edit', extra: moods[i]),
              onDelete: () => _confirmDelete(moods[i], isDark),
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
    required this.isDark,
    required this.theme,
    required this.onEdit,
    required this.onDelete,
  });

  final MoodModel mood;
  final bool isDark;
  final ThemeData theme;
  final VoidCallback onEdit;
  final VoidCallback onDelete;

  @override
  Widget build(BuildContext context) {
    final moodColor = _color(mood.mood);

    return Container(
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        borderRadius: BorderRadius.circular(20),
        child: InkWell(
          onTap: onEdit,
          borderRadius: BorderRadius.circular(20),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // EMOJI CONTAINER
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: moodColor.withOpacity(isDark ? 0.2 : 0.15),
                    borderRadius: BorderRadius.circular(16),
                  ),
                  child: Text(_emoji(mood.mood), style: const TextStyle(fontSize: 32)),
                ),
                const SizedBox(width: 16),

                // CONTENT
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Text(
                            _label(mood.mood),
                            style: theme.textTheme.titleMedium?.copyWith(
                              fontWeight: FontWeight.bold,
                              color: isDark ? moodColor.withOpacity(0.9) : moodColor.withOpacity(1.0),
                            ),
                          ),
                          Text(
                            DateFormat('d MMM yyyy', 'id').format(mood.date),
                            style: theme.textTheme.bodySmall?.copyWith(
                              color: Colors.grey,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                      if (mood.note.isNotEmpty) ...[
                        const SizedBox(height: 8),
                        Text(
                          mood.note,
                          maxLines: 2,
                          overflow: TextOverflow.ellipsis,
                          style: theme.textTheme.bodyMedium?.copyWith(
                            height: 1.4,
                            color: isDark ? Colors.grey.shade400 : Colors.grey.shade700,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),

                const SizedBox(width: 8),
                InkWell(
                  onTap: onDelete,
                  borderRadius: BorderRadius.circular(12),
                  child: Padding(
                    padding: const EdgeInsets.all(4.0),
                    child: Icon(
                      Icons.delete_outline_rounded,
                      color: isDark ? Colors.redAccent.withOpacity(0.7) : Colors.redAccent.withOpacity(0.5),
                      size: 22,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}