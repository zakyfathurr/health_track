import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:intl/intl.dart';
import '../domain/mood_model.dart';
import '../domain/mood_usecases.dart';

const _moodOptions = [
  ('happy', '😊', 'Senang'),
  ('calm', '😌', 'Tenang'),
  ('sad', '😢', 'Sedih'),
  ('angry', '😠', 'Marah'),
  ('anxious', '😰', 'Cemas'),
  ('tired', '😴', 'Lelah'),
];

class MoodEditScreen extends StatefulWidget {
  const MoodEditScreen({super.key, required this.entry});

  final MoodModel entry;

  @override
  State<MoodEditScreen> createState() => _MoodEditScreenState();
}

class _MoodEditScreenState extends State<MoodEditScreen> {
  final _updateMood = UpdateMoodUseCase();
  late final TextEditingController _noteCtrl;

  late String _selectedMood;
  late DateTime _date;
  bool _saving = false;

  @override
  void initState() {
    super.initState();
    _selectedMood = widget.entry.mood;
    _date = widget.entry.date;
    _noteCtrl = TextEditingController(text: widget.entry.note);
  }

  @override
  void dispose() {
    _noteCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime.now(),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _save() async {
    setState(() => _saving = true);
    try {
      await _updateMood(
        widget.entry.copyWith(
          mood: _selectedMood,
          note: _noteCtrl.text.trim(),
          date: _date,
        ),
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan: $e')));
      }
    } finally {
      if (mounted) setState(() => _saving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(title: const Text('Edit Mood')),
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              'Gimana perasaanmu hari ini?',
              style: Theme.of(
                context,
              ).textTheme.titleMedium?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 16),
            GridView.count(
              crossAxisCount: 3,
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              mainAxisSpacing: 12,
              crossAxisSpacing: 12,
              childAspectRatio: 1.1,
              children: _moodOptions.map((m) {
                final (key, emoji, label) = m;
                final selected = _selectedMood == key;
                return GestureDetector(
                  onTap: () => setState(() => _selectedMood = key),
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 150),
                    decoration: BoxDecoration(
                      color: selected
                          ? colorScheme.primaryContainer
                          : colorScheme.surfaceContainerHighest,
                      borderRadius: BorderRadius.circular(16),
                      border: selected
                          ? Border.all(color: colorScheme.primary, width: 2)
                          : Border.all(color: Colors.transparent, width: 2),
                    ),
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Text(emoji, style: const TextStyle(fontSize: 32)),
                        const SizedBox(height: 4),
                        Text(
                          label,
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: selected
                                ? FontWeight.bold
                                : FontWeight.normal,
                            color: selected
                                ? colorScheme.onPrimaryContainer
                                : colorScheme.onSurfaceVariant,
                          ),
                        ),
                      ],
                    ),
                  ),
                );
              }).toList(),
            ),
            const SizedBox(height: 24),
            Text(
              'Tanggal',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            InkWell(
              onTap: _pickDate,
              borderRadius: BorderRadius.circular(12),
              child: Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 14,
                ),
                decoration: BoxDecoration(
                  border: Border.all(color: colorScheme.outline),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  children: [
                    Icon(
                      Icons.calendar_today_outlined,
                      color: colorScheme.primary,
                      size: 20,
                    ),
                    const SizedBox(width: 12),
                    Text(
                      DateFormat('EEEE, d MMMM yyyy', 'id').format(_date),
                      style: Theme.of(context).textTheme.bodyMedium,
                    ),
                    const Spacer(),
                    Icon(
                      Icons.chevron_right,
                      color: colorScheme.onSurfaceVariant,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 24),
            Text(
              'Catatan (opsional)',
              style: Theme.of(
                context,
              ).textTheme.titleSmall?.copyWith(fontWeight: FontWeight.bold),
            ),
            const SizedBox(height: 8),
            TextField(
              controller: _noteCtrl,
              maxLines: 4,
              textCapitalization: TextCapitalization.sentences,
              decoration: InputDecoration(
                hintText: 'Ceritain lebih lanjut...',
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
            ),
            const SizedBox(height: 32),
            ElevatedButton(
              onPressed: _saving ? null : _save,
              style: ElevatedButton.styleFrom(
                minimumSize: const Size(double.infinity, 52),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: _saving
                  ? const SizedBox(
                      height: 22,
                      width: 22,
                      child: CircularProgressIndicator(strokeWidth: 2),
                    )
                  : const Text('Simpan', style: TextStyle(fontSize: 16)),
            ),
          ],
        ),
      ),
    );
  }
}
