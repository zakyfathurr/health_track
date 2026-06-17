import 'dart:math' as math;
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../../core/services/auth_notifier.dart';
import '../../../core/services/notification_service.dart';
import '../domain/goal_model.dart';
import '../domain/goal_usecases.dart';

class GoalsListScreen extends StatelessWidget {
  const GoalsListScreen({super.key});

  static String fmt(double v) =>
      v == v.roundToDouble() ? v.toInt().toString() : v.toString();

  @override
  Widget build(BuildContext context) {
    final uid = authNotifier.uid;
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
              'Target Harian',
              style: theme.textTheme.headlineSmall?.copyWith(
                fontWeight: FontWeight.w900,
                letterSpacing: -0.5,
                color: isDark ? Colors.white : Colors.black87,
              ),
            ),
            const SizedBox(height: 4),
            Text(
              'Fokus pada progres, bukan kesempurnaan.',
              style: theme.textTheme.bodyMedium?.copyWith(
                color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
              ),
            ),
          ],
        ),
        actions: const [_ReminderButton(), SizedBox(width: 8)],
      ),
      body: uid == null
          ? Center(
              child: Text(
                'Silakan login terlebih dahulu',
                style: TextStyle(
                  color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                ),
              ),
            )
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
                  return _EmptyState(theme: theme);
                }

                return ListView(
                  physics: const BouncingScrollPhysics(),
                  padding: const EdgeInsets.fromLTRB(20, 8, 20, 100),
                  children: [
                    _SummaryHeader(goals: goals, theme: theme, isDark: isDark),
                    const SizedBox(height: 16),
                    _WeeklyChart(goals: goals, theme: theme, isDark: isDark),
                    const SizedBox(height: 24),
                    for (final goal in goals) ...[
                      _GoalCard(
                        key: ValueKey(goal.id),
                        goal: goal,
                        isDark: isDark,
                        theme: theme,
                      ),
                      const SizedBox(height: 16),
                    ],
                  ],
                );
              },
            ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => context.push('/goals/add'),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.add_task_rounded),
        label: const Text('Buat Target', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

// ============================================================
// EMPTY STATE
// ============================================================
class _EmptyState extends StatelessWidget {
  const _EmptyState({required this.theme});
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
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
            child: const Text('🎯', style: TextStyle(fontSize: 56)),
          ),
          const SizedBox(height: 24),
          Text(
            'Belum ada target',
            style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          Text(
            'Mulai bangun kebiasaan sehatmu hari ini.',
            style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// SUMMARY HEADER — today completion ring + best streak
// ============================================================
class _SummaryHeader extends StatelessWidget {
  const _SummaryHeader({
    required this.goals,
    required this.theme,
    required this.isDark,
  });

  final List<GoalModel> goals;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final total = goals.length;
    final doneToday = goals.where((g) => g.isCompletedToday).length;
    final ratio = total > 0 ? doneToday / total : 0.0;
    final bestStreak =
        goals.map((g) => g.streak).fold<int>(0, (a, b) => math.max(a, b));
    final allDone = doneToday == total && total > 0;

    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
          colors: allDone
              ? [Colors.green.shade400, Colors.teal.shade400]
              : [theme.primaryColor, theme.primaryColor.withOpacity(0.7)],
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: (allDone ? Colors.green : theme.primaryColor).withOpacity(0.3),
            blurRadius: 20,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Row(
        children: [
          SizedBox(
            height: 64,
            width: 64,
            child: Stack(
              alignment: Alignment.center,
              children: [
                SizedBox(
                  height: 64,
                  width: 64,
                  child: TweenAnimationBuilder<double>(
                    tween: Tween(begin: 0, end: ratio),
                    duration: const Duration(milliseconds: 600),
                    curve: Curves.easeOutCubic,
                    builder: (_, value, __) => CircularProgressIndicator(
                      value: value,
                      strokeWidth: 7,
                      backgroundColor: Colors.white.withOpacity(0.25),
                      valueColor: const AlwaysStoppedAnimation(Colors.white),
                    ),
                  ),
                ),
                Text(
                  '$doneToday/$total',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w900,
                    fontSize: 16,
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(width: 18),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  allDone ? 'Semua target selesai! 🎉' : 'Progres hari ini',
                  style: const TextStyle(
                    color: Colors.white,
                    fontWeight: FontWeight.w800,
                    fontSize: 17,
                  ),
                ),
                const SizedBox(height: 6),
                Row(
                  children: [
                    const Text('🔥', style: TextStyle(fontSize: 16)),
                    const SizedBox(width: 4),
                    Text(
                      bestStreak > 0
                          ? 'Streak terbaik: $bestStreak hari'
                          : 'Belum ada streak — mulai hari ini!',
                      style: TextStyle(
                        color: Colors.white.withOpacity(0.9),
                        fontWeight: FontWeight.w600,
                        fontSize: 13,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// WEEKLY CHART — average completion % per day, last 7 days
// ============================================================
class _WeeklyChart extends StatelessWidget {
  const _WeeklyChart({
    required this.goals,
    required this.theme,
    required this.isDark,
  });

  final List<GoalModel> goals;
  final ThemeData theme;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);

    // Rata-rata persen seluruh target untuk tiap hari (7 hari terakhir).
    final daily = List.generate(7, (i) {
      final day = today.subtract(Duration(days: 6 - i));
      if (goals.isEmpty) return 0.0;
      final sum = goals.fold<double>(0, (a, g) => a + g.percentOn(day));
      return sum / goals.length;
    });

    const weekdayInitials = ['Sn', 'Sl', 'Rb', 'Km', 'Jm', 'Sb', 'Mg'];

    return Container(
      padding: const EdgeInsets.fromLTRB(20, 18, 20, 14),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.04),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.insights_rounded, size: 18, color: theme.primaryColor),
              const SizedBox(width: 8),
              Text(
                '7 Hari Terakhir',
                style: theme.textTheme.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                  color: isDark ? Colors.white : Colors.black87,
                ),
              ),
            ],
          ),
          const SizedBox(height: 16),
          SizedBox(
            height: 110,
            child: Row(
              crossAxisAlignment: CrossAxisAlignment.end,
              children: List.generate(7, (i) {
                final day = today.subtract(Duration(days: 6 - i));
                final pct = daily[i];
                final isToday = i == 6;
                final barColor = pct >= 1.0
                    ? Colors.green
                    : theme.primaryColor;
                return Expanded(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      Text(
                        '${(pct * 100).round()}%',
                        style: TextStyle(
                          fontSize: 9,
                          fontWeight: FontWeight.w600,
                          color: isDark ? Colors.grey.shade500 : Colors.grey.shade500,
                        ),
                      ),
                      const SizedBox(height: 4),
                      TweenAnimationBuilder<double>(
                        tween: Tween(begin: 0, end: pct),
                        duration: const Duration(milliseconds: 600),
                        curve: Curves.easeOutCubic,
                        builder: (_, value, __) => Container(
                          height: math.max(6, value * 64),
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            color: barColor.withOpacity(value < 0.05 ? 0.15 : 1),
                            borderRadius: BorderRadius.circular(6),
                          ),
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text(
                        weekdayInitials[day.weekday - 1],
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: isToday ? FontWeight.w900 : FontWeight.w500,
                          color: isToday
                              ? theme.primaryColor
                              : (isDark ? Colors.grey.shade500 : Colors.grey.shade500),
                        ),
                      ),
                    ],
                  ),
                );
              }),
            ),
          ),
        ],
      ),
    );
  }
}

// ============================================================
// GOAL CARD — stateful so it can celebrate on completion
// ============================================================
class _GoalCard extends StatefulWidget {
  const _GoalCard({
    super.key,
    required this.goal,
    required this.isDark,
    required this.theme,
  });

  final GoalModel goal;
  final bool isDark;
  final ThemeData theme;

  @override
  State<_GoalCard> createState() => _GoalCardState();
}

class _GoalCardState extends State<_GoalCard> {
  late bool _wasCompleted = widget.goal.isCompletedToday;

  @override
  void didUpdateWidget(covariant _GoalCard old) {
    super.didUpdateWidget(old);
    final nowDone = widget.goal.isCompletedToday;
    if (!_wasCompleted && nowDone) {
      HapticFeedback.mediumImpact();
      _celebrate();
    }
    _wasCompleted = nowDone;
  }

  void _celebrate() {
    // Dipanggil dari didUpdateWidget (fase update). Menyisipkan OverlayEntry
    // atau memanggil ScaffoldMessenger saat itu juga = memutasi tree di build
    // scope yang salah → "wrong build scope"/"!_doingMountOrUpdate". Tunda ke
    // frame berikutnya.
    WidgetsBinding.instance.addPostFrameCallback((_) {
      if (!mounted) return;
      final overlay = Overlay.of(context);
      late OverlayEntry entry;
      entry = OverlayEntry(
        builder: (_) => _CelebrationBurst(
          color: widget.goal.category.color,
          onDone: () => entry.remove(),
        ),
      );
      overlay.insert(entry);
      ScaffoldMessenger.of(context)
        ..hideCurrentSnackBar()
        ..showSnackBar(
        SnackBar(
          behavior: SnackBarBehavior.floating,
          backgroundColor: Colors.green,
          duration: const Duration(seconds: 2),
          content: Text(
            '🎉 "${widget.goal.title}" tercapai hari ini!',
            style: const TextStyle(fontWeight: FontWeight.bold),
          ),
        ),
      );
    });
  }

  Future<void> _bump(double delta) async {
    final goal = widget.goal;
    try {
      await SetTodayProgressUseCase()(goal.id, goal.todayProgress + delta);
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Gagal memperbarui progres: $e')),
      );
    }
  }

  Future<void> _openProgressDialog() async {
    final goal = widget.goal;
    final isDark = widget.isDark;
    final cat = goal.category;
    final ctrl = TextEditingController();

    final amount = await showDialog<double>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF222222) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
        title: Text(
          'Update ${goal.title}',
          style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 18),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
              decoration: BoxDecoration(
                color: cat.color.withOpacity(0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Text(
                'Hari ini: ${GoalsListScreen.fmt(goal.todayProgress)} / ${GoalsListScreen.fmt(goal.targetValue)} ${goal.unit}',
                style: TextStyle(color: cat.color, fontWeight: FontWeight.w600),
              ),
            ),
            const SizedBox(height: 20),
            TextField(
              controller: ctrl,
              autofocus: true,
              keyboardType: const TextInputType.numberWithOptions(decimal: true),
              style: const TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
              decoration: InputDecoration(
                labelText: 'Tambah pencapaian (${goal.unit})',
                alignLabelWithHint: true,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(
                    color: isDark ? Colors.grey.shade800 : Colors.grey.shade300,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(16),
                  borderSide: BorderSide(color: cat.color, width: 2),
                ),
                filled: true,
                fillColor: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade50,
              ),
            ),
          ],
        ),
        actionsPadding: const EdgeInsets.only(right: 16, bottom: 16),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, double.tryParse(ctrl.text.trim())),
            style: ElevatedButton.styleFrom(
              backgroundColor: cat.color,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
          ),
        ],
      ),
    );

    if (amount == null || amount == 0) return;
    _bump(amount);
  }

  /// Hanya menanyakan konfirmasi — TIDAK menghapus di sini. Penghapusan
  /// dilakukan setelah gesture Dismissible selesai (lihat confirmDismiss),
  /// supaya stream tidak memutasi ListView saat swipe masih berlangsung
  /// (penyebab assertion sliver 'indexOf(child) > index').
  Future<bool> _confirmDelete() async {
    final goal = widget.goal;
    final isDark = widget.isDark;
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        backgroundColor: isDark ? const Color(0xFF222222) : Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        title: const Text('Hapus Target?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: Text(
          'Target "${goal.title}" akan dihapus permanen beserta seluruh riwayat progresnya.',
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
    return confirmed == true;
  }

  @override
  Widget build(BuildContext context) {
    final goal = widget.goal;
    final theme = widget.theme;
    final isDark = widget.isDark;
    final cat = goal.category;
    final completed = goal.isCompletedToday;
    final accent = completed ? Colors.green : cat.color;
    final progressPercent = goal.todayPercent;
    final canDecrement = goal.todayProgress > 0;

    return Dismissible(
      key: ValueKey(goal.id),
      direction: DismissDirection.endToStart,
      confirmDismiss: (_) async {
        final messenger = ScaffoldMessenger.of(context);
        final confirmed = await _confirmDelete();
        if (confirmed) {
          // Tunda hapus sampai frame berikutnya: confirmDismiss sudah
          // mengembalikan false & gesture selesai, jadi stream menghapus
          // kartu dari ListView tanpa balapan dengan animasi swipe.
          WidgetsBinding.instance.addPostFrameCallback((_) async {
            try {
              await DeleteGoalUseCase()(widget.goal.id);
            } catch (e) {
              messenger.showSnackBar(
                SnackBar(content: Text('Gagal menghapus target: $e')),
              );
            }
          });
        }
        return false;
      },
      background: Container(
        alignment: Alignment.centerRight,
        padding: const EdgeInsets.symmetric(horizontal: 24),
        decoration: BoxDecoration(
          color: Colors.redAccent,
          borderRadius: BorderRadius.circular(24),
        ),
        child: const Icon(Icons.delete_sweep_rounded, color: Colors.white, size: 32),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222222) : Colors.white,
          borderRadius: BorderRadius.circular(24),
          boxShadow: [
            BoxShadow(
              color: isDark
                  ? Colors.black.withOpacity(0.2)
                  : Colors.black.withOpacity(0.04),
              blurRadius: 15,
              offset: const Offset(0, 4),
            ),
          ],
        ),
        child: Material(
          color: Colors.transparent,
          borderRadius: BorderRadius.circular(24),
          child: InkWell(
            onTap: _openProgressDialog,
            borderRadius: BorderRadius.circular(24),
            child: Padding(
              padding: const EdgeInsets.all(20),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      // CATEGORY ICON
                      Container(
                        padding: const EdgeInsets.all(10),
                        decoration: BoxDecoration(
                          color: cat.color.withOpacity(isDark ? 0.2 : 0.12),
                          borderRadius: BorderRadius.circular(14),
                        ),
                        child: Icon(cat.icon, color: cat.color, size: 22),
                      ),
                      const SizedBox(width: 14),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              goal.title,
                              style: theme.textTheme.titleMedium?.copyWith(
                                fontWeight: FontWeight.w800,
                                fontSize: 18,
                                color: isDark ? Colors.white : Colors.black87,
                              ),
                            ),
                            const SizedBox(height: 2),
                            Text(
                              cat.label,
                              style: TextStyle(
                                fontSize: 12,
                                fontWeight: FontWeight.w600,
                                color: cat.color,
                              ),
                            ),
                          ],
                        ),
                      ),
                      // STREAK CHIP
                      if (goal.streak > 0)
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                          decoration: BoxDecoration(
                            color: Colors.orange.withOpacity(0.15),
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              const Text('🔥', style: TextStyle(fontSize: 13)),
                              const SizedBox(width: 3),
                              Text(
                                '${goal.streak}',
                                style: const TextStyle(
                                  color: Colors.deepOrange,
                                  fontSize: 13,
                                  fontWeight: FontWeight.w900,
                                ),
                              ),
                            ],
                          ),
                        ),
                    ],
                  ),
                  const SizedBox(height: 18),

                  // PROGRESS BAR (today)
                  LayoutBuilder(
                    builder: (context, constraints) => Stack(
                      children: [
                        Container(
                          height: 12,
                          width: double.infinity,
                          decoration: BoxDecoration(
                            color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                        AnimatedContainer(
                          duration: const Duration(milliseconds: 500),
                          curve: Curves.easeOutCubic,
                          height: 12,
                          width: constraints.maxWidth * progressPercent,
                          decoration: BoxDecoration(
                            color: accent,
                            borderRadius: BorderRadius.circular(10),
                          ),
                        ),
                      ],
                    ),
                  ),
                  const SizedBox(height: 16),

                  // FOOTER: today value + decrement/increment controls
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      Expanded(
                        child: Row(
                          children: [
                            if (completed) ...[
                              const Icon(Icons.check_circle_rounded, size: 18, color: Colors.green),
                              const SizedBox(width: 6),
                            ],
                            Flexible(
                              child: Text(
                                '${GoalsListScreen.fmt(goal.todayProgress)} / ${GoalsListScreen.fmt(goal.targetValue)} ${goal.unit}',
                                style: theme.textTheme.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: completed
                                      ? Colors.green
                                      : (isDark ? Colors.grey.shade300 : Colors.grey.shade700),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      // DECREMENT
                      _StepButton(
                        icon: Icons.remove_rounded,
                        color: accent,
                        isDark: isDark,
                        enabled: canDecrement,
                        onTap: () => _bump(-1),
                      ),
                      const SizedBox(width: 8),
                      // INCREMENT +1
                      Material(
                        color: accent.withOpacity(isDark ? 0.2 : 0.12),
                        borderRadius: BorderRadius.circular(12),
                        child: InkWell(
                          onTap: () => _bump(1),
                          borderRadius: BorderRadius.circular(12),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                            child: Row(
                              children: [
                                Icon(Icons.add_rounded, size: 16, color: accent),
                                const SizedBox(width: 4),
                                Text(
                                  '1 ${goal.unit}',
                                  style: TextStyle(
                                    color: accent,
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _StepButton extends StatelessWidget {
  const _StepButton({
    required this.icon,
    required this.color,
    required this.isDark,
    required this.enabled,
    required this.onTap,
  });

  final IconData icon;
  final Color color;
  final bool isDark;
  final bool enabled;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final c = enabled ? color : Colors.grey;
    return Material(
      color: c.withOpacity(isDark ? 0.15 : 0.08),
      borderRadius: BorderRadius.circular(12),
      child: InkWell(
        onTap: enabled ? onTap : null,
        borderRadius: BorderRadius.circular(12),
        child: Padding(
          padding: const EdgeInsets.all(8),
          child: Icon(icon, size: 16, color: c),
        ),
      ),
    );
  }
}

// ============================================================
// REMINDER BUTTON — bell icon in AppBar to set/cancel daily reminder
// ============================================================
class _ReminderButton extends StatefulWidget {
  const _ReminderButton();

  @override
  State<_ReminderButton> createState() => _ReminderButtonState();
}

class _ReminderButtonState extends State<_ReminderButton> {
  TimeOfDay? _reminderTime;

  static const _keyHour = 'goal_reminder_hour';
  static const _keyMinute = 'goal_reminder_minute';

  @override
  void initState() {
    super.initState();
    _loadTime();
  }

  Future<void> _loadTime() async {
    final prefs = await SharedPreferences.getInstance();
    final hour = prefs.getInt(_keyHour);
    final minute = prefs.getInt(_keyMinute);
    if (hour != null && minute != null && mounted) {
      setState(() => _reminderTime = TimeOfDay(hour: hour, minute: minute));
    }
  }

  Future<void> _pickTime() async {
    final picked = await showTimePicker(
      context: context,
      initialTime: _reminderTime ?? const TimeOfDay(hour: 8, minute: 0),
      helpText: 'Pilih jam reminder target harian',
    );
    if (picked == null || !mounted) return;

    final granted = await NotificationService().scheduleGoalReminder(picked.hour, picked.minute);
    if (!mounted) return;
    if (!granted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Izin alarm diperlukan. Aktifkan di Pengaturan > Aplikasi > Izin Khusus.'),
          duration: Duration(seconds: 4),
        ),
      );
      return;
    }

    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_keyHour, picked.hour);
    await prefs.setInt(_keyMinute, picked.minute);
    setState(() => _reminderTime = picked);

    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Reminder diset setiap hari pukul ${picked.format(context)}')),
      );
    }
  }

  Future<void> _cancelReminder() async {
    await NotificationService().cancelGoalReminder();
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyHour);
    await prefs.remove(_keyMinute);
    setState(() => _reminderTime = null);
    if (mounted) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Reminder dibatalkan')),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    final isSet = _reminderTime != null;
    return IconButton(
      icon: Icon(isSet ? Icons.notifications_active_rounded : Icons.notifications_none_rounded),
      tooltip: isSet
          ? 'Reminder: ${_reminderTime!.format(context)} (tahan untuk hapus)'
          : 'Set reminder harian',
      color: isSet ? Theme.of(context).primaryColor : null,
      onPressed: _pickTime,
      onLongPress: isSet ? _cancelReminder : null,
    );
  }
}

// ============================================================
// CELEBRATION BURST — dependency-free particle burst overlay
// ============================================================
class _CelebrationBurst extends StatefulWidget {
  const _CelebrationBurst({required this.color, required this.onDone});
  final Color color;
  final VoidCallback onDone;

  @override
  State<_CelebrationBurst> createState() => _CelebrationBurstState();
}

class _CelebrationBurstState extends State<_CelebrationBurst>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 1100),
  );
  late final List<_Particle> _particles;

  @override
  void initState() {
    super.initState();
    final rnd = math.Random();
    final palette = [
      widget.color,
      Colors.amber,
      Colors.pinkAccent,
      Colors.lightGreen,
      Colors.lightBlueAccent,
    ];
    _particles = List.generate(26, (_) {
      final angle = rnd.nextDouble() * 2 * math.pi;
      final speed = 120 + rnd.nextDouble() * 160;
      return _Particle(
        dx: math.cos(angle) * speed,
        dy: math.sin(angle) * speed,
        color: palette[rnd.nextInt(palette.length)],
        size: 6 + rnd.nextDouble() * 8,
        rotation: rnd.nextDouble() * 6,
      );
    });
    _ctrl.forward().whenComplete(widget.onDone);
  }

  @override
  void dispose() {
    _ctrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final size = MediaQuery.of(context).size;
    final origin = Offset(size.width / 2, size.height * 0.4);
    return IgnorePointer(
      child: AnimatedBuilder(
        animation: _ctrl,
        builder: (context, _) {
          final t = Curves.easeOut.transform(_ctrl.value);
          return Stack(
            children: _particles.map((p) {
              final gravity = 60 * t * t;
              return Positioned(
                left: origin.dx + p.dx * t,
                top: origin.dy + p.dy * t + gravity,
                child: Transform.rotate(
                  angle: p.rotation * t,
                  child: Opacity(
                    opacity: (1 - t).clamp(0.0, 1.0),
                    child: Container(
                      width: p.size,
                      height: p.size,
                      decoration: BoxDecoration(
                        color: p.color,
                        borderRadius: BorderRadius.circular(2),
                      ),
                    ),
                  ),
                ),
              );
            }).toList(),
          );
        },
      ),
    );
  }
}

class _Particle {
  final double dx;
  final double dy;
  final Color color;
  final double size;
  final double rotation;
  const _Particle({
    required this.dx,
    required this.dy,
    required this.color,
    required this.size,
    required this.rotation,
  });
}
