import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:intl/intl.dart';

import '../../daily_goals/domain/goal_usecases.dart';
import '../../mood_journal/domain/mood_model.dart';
import '../../mood_journal/domain/mood_usecases.dart';
import '../domain/home_usecases.dart';
import '../domain/quote.dart';
import '../domain/weather.dart';

const _moodLabel = {
  'happy':   ('😊', 'Senang'),
  'calm':    ('😌', 'Tenang'),
  'sad':     ('😢', 'Sedih'),
  'angry':   ('😠', 'Marah'),
  'anxious': ('😰', 'Cemas'),
  'tired':   ('😴', 'Lelah'),
};

String _weatherEmoji(String icon) {
  final code = icon.length >= 2 ? icon.substring(0, 2) : icon;
  return switch (code) {
    '01' => '☀️',
    '02' => '⛅',
    '03' || '04' => '☁️',
    '09' => '🌧️',
    '10' => '🌦️',
    '11' => '⛈️',
    '13' => '❄️',
    '50' => '🌫️',
    _ => '🌤️',
  };
}

String _dominantMood(List<MoodModel> moods) {
  if (moods.isEmpty) return '-';
  final cutoff = DateTime.now().subtract(const Duration(days: 7));
  final recent = moods.where((m) => m.date.isAfter(cutoff)).toList();
  final source = recent.isEmpty ? moods : recent;
  final freq = <String, int>{};
  for (final m in source) {
    freq[m.mood] = (freq[m.mood] ?? 0) + 1;
  }
  return freq.entries.reduce((a, b) => a.value >= b.value ? a : b).key;
}

class DashboardScreen extends StatefulWidget {
  const DashboardScreen({super.key});

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  final _getWeather = GetWeatherUseCase();
  final _getQuote = GetTodayQuoteUseCase();
  final _getGoals = GetGoalsUseCase();
  final _getMoods = GetMoodsUseCase();

  late final Future<WeatherData> _weatherFuture;
  late final Future<QuoteData> _quoteFuture;

  String? get _userId => FirebaseAuth.instance.currentUser?.uid;

  String get _displayName {
    final user = FirebaseAuth.instance.currentUser;
    final name = user?.displayName;
    if (name != null && name.trim().isNotEmpty) return name.trim();
    final email = user?.email;
    if (email != null) return email.split('@')[0];
    return 'Kamu';
  }

  @override
  void initState() {
    super.initState();
    _weatherFuture = _getWeather();
    _quoteFuture = _getQuote();
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;
    final today = DateFormat('EEEE, d MMMM yyyy', 'id').format(DateTime.now());
    final uid = _userId;

    return Scaffold(
      backgroundColor:
          isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
      body: SafeArea(
        child: SingleChildScrollView(
          physics: const BouncingScrollPhysics(),
          padding: const EdgeInsets.all(24.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // HEADER
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        today,
                        style: theme.textTheme.bodyMedium?.copyWith(
                          color: isDark
                              ? Colors.grey.shade400
                              : Colors.grey.shade600,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        'Halo, $_displayName! 👋',
                        style: theme.textTheme.headlineSmall?.copyWith(
                          fontWeight: FontWeight.w900,
                          letterSpacing: -0.5,
                          color: isDark ? Colors.white : Colors.black87,
                        ),
                      ),
                    ],
                  ),
                  Container(
                    padding: const EdgeInsets.all(3),
                    decoration: BoxDecoration(
                      shape: BoxShape.circle,
                      border: Border.all(
                        color: theme.primaryColor.withOpacity(0.3),
                        width: 2,
                      ),
                    ),
                    child: CircleAvatar(
                      radius: 24,
                      backgroundColor: theme.primaryColor.withOpacity(0.1),
                      child: Icon(Icons.person, color: theme.primaryColor),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 32),

              // WEATHER CARD
              FutureBuilder<WeatherData>(
                future: _weatherFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return _WeatherLoading(isDark: isDark);
                  }
                  if (snap.hasError || snap.data == null) {
                    return _WeatherFallback(isDark: isDark);
                  }
                  final w = snap.data!;
                  return _WeatherCard(
                    weather: w,
                    recommendation: healthRecommendation(w),
                    isDark: isDark,
                  );
                },
              ),
              const SizedBox(height: 32),

              // QUOTE
              Text(
                'Inspirasi Hari Ini',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              FutureBuilder<QuoteData>(
                future: _quoteFuture,
                builder: (context, snap) {
                  if (snap.connectionState == ConnectionState.waiting) {
                    return _QuoteLoading(isDark: isDark);
                  }
                  final String text;
                  final String author;
                  if (snap.hasError || snap.data == null) {
                    text =
                        '"Orang yang memindahkan gunung dimulai dengan membawa batu-batu kecil."';
                    author = 'Confucius';
                  } else {
                    text = '"${snap.data!.text}"';
                    author = snap.data!.author;
                  }
                  return _QuoteCard(
                    quote: text,
                    author: author,
                    isDark: isDark,
                    theme: theme,
                  );
                },
              ),
              const SizedBox(height: 32),

              // RINGKASAN
              Text(
                'Ringkasanmu',
                style: theme.textTheme.titleMedium
                    ?.copyWith(fontWeight: FontWeight.bold),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  // TARGET SELESAI
                  Expanded(
                    child: uid == null
                        ? _StatCard(
                            title: 'Target Selesai',
                            value: '-',
                            icon: Icons.task_alt_rounded,
                            color: Colors.green,
                            isDark: isDark,
                          )
                        : StreamBuilder(
                            stream: _getGoals(uid),
                            builder: (context, snap) {
                              final goals = snap.data ?? [];
                              final done =
                                  goals.where((g) => g.isCompleted).length;
                              return _StatCard(
                                title: 'Target Selesai',
                                value: snap.connectionState ==
                                        ConnectionState.waiting
                                    ? '...'
                                    : '$done',
                                icon: Icons.task_alt_rounded,
                                color: Colors.green,
                                isDark: isDark,
                              );
                            },
                          ),
                  ),
                  const SizedBox(width: 16),
                  // MOOD DOMINAN
                  Expanded(
                    child: uid == null
                        ? _StatCard(
                            title: 'Mood Dominan',
                            value: '-',
                            icon: Icons.spa_rounded,
                            color: Colors.teal,
                            isDark: isDark,
                          )
                        : StreamBuilder(
                            stream: _getMoods(uid),
                            builder: (context, snap) {
                              final moods = snap.data ?? [];
                              final dominant = _dominantMood(moods);
                              final meta = _moodLabel[dominant];
                              final label =
                                  meta != null ? '${meta.$1} ${meta.$2}' : '-';
                              return _StatCard(
                                title: 'Mood Dominan',
                                value: snap.connectionState ==
                                        ConnectionState.waiting
                                    ? '...'
                                    : label,
                                icon: Icons.spa_rounded,
                                color: Colors.teal,
                                isDark: isDark,
                              );
                            },
                          ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Weather ──────────────────────────────────────────────────────────────────

class _WeatherCard extends StatelessWidget {
  const _WeatherCard({
    required this.weather,
    required this.recommendation,
    required this.isDark,
  });
  final WeatherData weather;
  final String recommendation;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3C72), const Color(0xFF2A5298)]
              : [Colors.blue.shade400, Colors.blue.shade300],
          begin: Alignment.topLeft,
          end: Alignment.bottomRight,
        ),
        borderRadius: BorderRadius.circular(24),
        boxShadow: [
          BoxShadow(
            color: Colors.blue.withOpacity(isDark ? 0.1 : 0.3),
            blurRadius: 15,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Cuaca Hari Ini',
                    style: TextStyle(
                      color: Colors.white70,
                      fontSize: 14,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    '${weather.temperature.round()}°C',
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 36,
                      fontWeight: FontWeight.bold,
                      height: 1,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    weather.condition,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      const Icon(Icons.location_on,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        weather.city,
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                      const SizedBox(width: 12),
                      const Icon(Icons.water_drop_outlined,
                          color: Colors.white70, size: 16),
                      const SizedBox(width: 4),
                      Text(
                        '${weather.humidity}%',
                        style: const TextStyle(
                          color: Colors.white70,
                          fontWeight: FontWeight.w500,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
              Text(
                _weatherEmoji(weather.icon),
                style: const TextStyle(fontSize: 64),
              ),
            ],
          ),
          const SizedBox(height: 16),
          Container(
            padding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.white.withOpacity(0.15),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Row(
              children: [
                const Icon(Icons.tips_and_updates_rounded,
                    color: Colors.white70, size: 16),
                const SizedBox(width: 8),
                Expanded(
                  child: Text(
                    recommendation,
                    style: const TextStyle(
                      color: Colors.white,
                      fontSize: 13,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

class _WeatherLoading extends StatelessWidget {
  const _WeatherLoading({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 160,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF1E3A6E) : Colors.blue.shade200,
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Center(
        child: CircularProgressIndicator(
          color: Colors.white54,
          strokeWidth: 2,
        ),
      ),
    );
  }
}

class _WeatherFallback extends StatelessWidget {
  const _WeatherFallback({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        gradient: LinearGradient(
          colors: isDark
              ? [const Color(0xFF1E3C72), const Color(0xFF2A5298)]
              : [Colors.blue.shade400, Colors.blue.shade300],
        ),
        borderRadius: BorderRadius.circular(24),
      ),
      child: const Row(
        children: [
          Text('🌤️', style: TextStyle(fontSize: 48)),
          SizedBox(width: 16),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Cuaca Hari Ini',
                  style: TextStyle(color: Colors.white70, fontSize: 14),
                ),
                SizedBox(height: 4),
                Text(
                  'Data tidak tersedia',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 18,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                SizedBox(height: 4),
                Text(
                  'Periksa koneksi atau API key cuaca',
                  style: TextStyle(color: Colors.white60, fontSize: 12),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ─── Quote ────────────────────────────────────────────────────────────────────

class _QuoteCard extends StatelessWidget {
  const _QuoteCard({
    required this.quote,
    required this.author,
    required this.isDark,
    required this.theme,
  });
  final String quote;
  final String author;
  final bool isDark;
  final ThemeData theme;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(
            Icons.format_quote_rounded,
            size: 40,
            color: theme.primaryColor.withOpacity(0.4),
          ),
          const SizedBox(height: 12),
          Text(
            quote,
            textAlign: TextAlign.center,
            style: theme.textTheme.bodyLarge?.copyWith(
              fontStyle: FontStyle.italic,
              height: 1.5,
              color:
                  isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
            ),
          ),
          const SizedBox(height: 16),
          Text(
            '— $author',
            style: theme.textTheme.bodySmall?.copyWith(
              fontWeight: FontWeight.bold,
              color: theme.primaryColor,
            ),
          ),
        ],
      ),
    );
  }
}

class _QuoteLoading extends StatelessWidget {
  const _QuoteLoading({required this.isDark});
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      height: 130,
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
      ),
      child: const Center(
        child: CircularProgressIndicator(strokeWidth: 2),
      ),
    );
  }
}

// ─── Stat Card ────────────────────────────────────────────────────────────────

class _StatCard extends StatelessWidget {
  const _StatCard({
    required this.title,
    required this.value,
    required this.icon,
    required this.color,
    required this.isDark,
  });
  final String title;
  final String value;
  final IconData icon;
  final Color color;
  final bool isDark;

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : Colors.white,
        borderRadius: BorderRadius.circular(24),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark
                ? Colors.black.withOpacity(0.2)
                : Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: color.withOpacity(0.1),
              shape: BoxShape.circle,
            ),
            child: Icon(icon, color: color, size: 24),
          ),
          const SizedBox(height: 16),
          Text(
            value,
            style: theme.textTheme.titleLarge?.copyWith(
              fontWeight: FontWeight.bold,
              color: isDark ? Colors.white : Colors.black87,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            title,
            style: theme.textTheme.bodySmall?.copyWith(
              color: Colors.grey,
              fontWeight: FontWeight.w600,
            ),
          ),
        ],
      ),
    );
  }
}
