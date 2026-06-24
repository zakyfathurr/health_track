import 'package:flutter/material.dart';

/// Kategori target — dipakai untuk ikon + warna kartu dan filter.
///
/// Disimpan di Firestore sebagai `categoryId` (string `id` di bawah), jadi
/// menambah/mengubah label atau warna di sini aman tanpa migrasi data.
class GoalCategory {
  final String id;
  final String label;
  final IconData icon;
  final Color color;

  const GoalCategory({
    required this.id,
    required this.label,
    required this.icon,
    required this.color,
  });

  static const List<GoalCategory> all = [
    GoalCategory(
      id: 'hidrasi',
      label: 'Hidrasi',
      icon: Icons.water_drop_rounded,
      color: Color(0xFF2196F3),
    ),
    GoalCategory(
      id: 'olahraga',
      label: 'Olahraga',
      icon: Icons.fitness_center_rounded,
      color: Color(0xFFFF7043),
    ),
    GoalCategory(
      id: 'tidur',
      label: 'Tidur',
      icon: Icons.bedtime_rounded,
      color: Color(0xFF5C6BC0),
    ),
    GoalCategory(
      id: 'mindfulness',
      label: 'Mindfulness',
      icon: Icons.self_improvement_rounded,
      color: Color(0xFFAB47BC),
    ),
    GoalCategory(
      id: 'nutrisi',
      label: 'Nutrisi',
      icon: Icons.restaurant_rounded,
      color: Color(0xFF66BB6A),
    ),
    GoalCategory(
      id: 'produktivitas',
      label: 'Produktivitas',
      icon: Icons.bolt_rounded,
      color: Color(0xFFFFB300),
    ),
    GoalCategory(
      id: 'lainnya',
      label: 'Lainnya',
      icon: Icons.flag_rounded,
      color: Color(0xFF26A69A),
    ),
    
    
  ];

  static const GoalCategory fallback = GoalCategory(
    id: 'lainnya',
    label: 'Lainnya',
    icon: Icons.flag_rounded,
    color: Color(0xFF26A69A),
  );

  /// Cari kategori by id; kalau tidak ketemu pakai [fallback] (data lama).
  static GoalCategory byId(String? id) =>
      all.firstWhere((c) => c.id == id, orElse: () => fallback);
}

/// Template siap-pakai supaya user tidak mengetik dari nol.
class GoalTemplate {
  final String title;
  final double targetValue;
  final String unit;
  final String categoryId;

  const GoalTemplate({
    required this.title,
    required this.targetValue,
    required this.unit,
    required this.categoryId,
  });

  static const List<GoalTemplate> presets = [
    GoalTemplate(title: 'Minum Air', targetValue: 8, unit: 'gelas', categoryId: 'hidrasi'),
    GoalTemplate(title: 'Jalan Kaki', targetValue: 8000, unit: 'langkah', categoryId: 'olahraga'),
    GoalTemplate(title: 'Olahraga', targetValue: 30, unit: 'menit', categoryId: 'olahraga'),
    GoalTemplate(title: 'Tidur Cukup', targetValue: 8, unit: 'jam', categoryId: 'tidur'),
    GoalTemplate(title: 'Meditasi', targetValue: 10, unit: 'menit', categoryId: 'mindfulness'),
    GoalTemplate(title: 'Baca Buku', targetValue: 20, unit: 'halaman', categoryId: 'produktivitas'),
    GoalTemplate(title: 'Makan Buah & Sayur', targetValue: 3, unit: 'porsi', categoryId: 'nutrisi'),
  ];
}
