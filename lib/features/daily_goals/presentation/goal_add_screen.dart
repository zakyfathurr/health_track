import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import '../../../core/services/auth_notifier.dart';
import '../domain/goal_category.dart';
import '../domain/goal_usecases.dart';

class GoalAddScreen extends StatefulWidget {
  const GoalAddScreen({super.key});

  @override
  State<GoalAddScreen> createState() => _GoalAddScreenState();
}

class _GoalAddScreenState extends State<GoalAddScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleCtrl = TextEditingController();
  final _targetCtrl = TextEditingController();
  final _unitCtrl = TextEditingController();
  final _addGoalUseCase = AddGoalUseCase();

  String _categoryId = GoalCategory.all.first.id;
  bool _loading = false;

  @override
  void dispose() {
    _titleCtrl.dispose();
    _targetCtrl.dispose();
    _unitCtrl.dispose();
    super.dispose();
  }

  void _applyTemplate(GoalTemplate t) {
    setState(() {
      _titleCtrl.text = t.title;
      _targetCtrl.text = _fmt(t.targetValue);
      _unitCtrl.text = t.unit;
      _categoryId = t.categoryId;
    });
    FocusScope.of(context).unfocus();
  }

  static String _fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  Future<void> _save() async {
    if (!_formKey.currentState!.validate()) return;
    final uid = authNotifier.uid;
    if (uid == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Sesi habis. Silakan login ulang.')),
      );
      return;
    }

    setState(() => _loading = true);
    try {
      await _addGoalUseCase(
        userId: uid,
        title: _titleCtrl.text.trim(),
        targetValue: double.parse(_targetCtrl.text.trim()),
        unit: _unitCtrl.text.trim(),
        categoryId: _categoryId,
      );
      if (mounted) context.pop();
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(
          context,
        ).showSnackBar(SnackBar(content: Text('Gagal menyimpan target: $e')));
      }
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Target')),
      body: SafeArea(
        child: Form(
          key: _formKey,
          child: ListView(
            padding: const EdgeInsets.all(24),
            children: [
              // --- PRESET TEMPLATES ---
              Text(
                'Pilih cepat',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              SizedBox(
                height: 40,
                child: ListView.separated(
                  scrollDirection: Axis.horizontal,
                  itemCount: GoalTemplate.presets.length,
                  separatorBuilder: (_, __) => const SizedBox(width: 8),
                  itemBuilder: (context, i) {
                    final t = GoalTemplate.presets[i];
                    final cat = GoalCategory.byId(t.categoryId);
                    return ActionChip(
                      avatar: Icon(cat.icon, size: 18, color: cat.color),
                      label: Text(t.title),
                      onPressed: () => _applyTemplate(t),
                      backgroundColor: cat.color.withOpacity(0.08),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(20),
                        side: BorderSide(color: cat.color.withOpacity(0.3)),
                      ),
                    );
                  },
                ),
              ),
              const SizedBox(height: 24),

              // --- CATEGORY PICKER ---
              Text(
                'Kategori',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
              const SizedBox(height: 12),
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: GoalCategory.all.map((cat) {
                  final selected = cat.id == _categoryId;
                  return ChoiceChip(
                    avatar: Icon(
                      cat.icon,
                      size: 18,
                      color: selected ? Colors.white : cat.color,
                    ),
                    label: Text(cat.label),
                    selected: selected,
                    onSelected: (_) => setState(() => _categoryId = cat.id),
                    selectedColor: cat.color,
                    labelStyle: TextStyle(
                      color: selected ? Colors.white : null,
                      fontWeight: selected ? FontWeight.bold : FontWeight.normal,
                    ),
                    backgroundColor: cat.color.withOpacity(0.08),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(20),
                      side: BorderSide(
                        color: selected
                            ? cat.color
                            : cat.color.withOpacity(0.25),
                      ),
                    ),
                  );
                }).toList(),
              ),
              const SizedBox(height: 24),

              // --- FIELDS ---
              TextFormField(
                controller: _titleCtrl,
                decoration: const InputDecoration(
                  labelText: 'Judul Target',
                  hintText: 'mis. Minum Air',
                ),
                textCapitalization: TextCapitalization.sentences,
                validator: (v) =>
                    v == null || v.trim().isEmpty ? 'Judul wajib diisi' : null,
              ),
              const SizedBox(height: 16),
              Row(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _targetCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Target/hari',
                        hintText: 'mis. 8',
                      ),
                      keyboardType: const TextInputType.numberWithOptions(
                        decimal: true,
                      ),
                      validator: (v) {
                        final parsed = double.tryParse((v ?? '').trim());
                        if (parsed == null) return 'Angka tidak valid';
                        if (parsed <= 0) return 'Harus > 0';
                        return null;
                      },
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: TextFormField(
                      controller: _unitCtrl,
                      decoration: const InputDecoration(
                        labelText: 'Satuan',
                        hintText: 'gelas, km, menit',
                      ),
                      validator: (v) => v == null || v.trim().isEmpty
                          ? 'Wajib diisi'
                          : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),
              ElevatedButton(
                onPressed: _loading ? null : _save,
                child: _loading
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text('Simpan'),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
