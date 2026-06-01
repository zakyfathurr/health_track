import 'package:flutter/material.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2, // Jumlah tab: Forum dan AI Chat
      child: Scaffold(
        backgroundColor: theme.scaffoldBackgroundColor,
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF1F1F1F) : theme.primaryColor,
          elevation: 0,
          title: const Text(
            'Konsultasi & Komunitas',
            style: TextStyle(fontWeight: FontWeight.bold),
          ),
          bottom: TabBar(
            indicatorColor: isDark ? theme.primaryColor : Colors.white,
            indicatorWeight: 3,
            labelColor: isDark ? theme.primaryColor : Colors.white,
            unselectedLabelColor: isDark ? Colors.white54 : Colors.white70,
            tabs: const [
              Tab(
                icon: Icon(Icons.forum_rounded),
                text: 'Forum Diskusi',
              ),
              Tab(
                icon: Icon(Icons.smart_toy_rounded),
                text: 'Chatbot AI',
              ),
            ],
          ),
        ),
        body: const TabBarView(
          children: [
            // Konten Tab 1: Forum
            _ForumTabPlaceholder(),
            // Konten Tab 2: Chatbot AI
            _AIChatTabPlaceholder(),
          ],
        ),
      ),
    );
  }
}

// ==========================================
// PLACEHOLDER KOMPONEN (Nanti pisah ke file sendiri di folder widgets/)
// ==========================================

class _ForumTabPlaceholder extends StatelessWidget {
  const _ForumTabPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.forum_outlined, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Daftar Diskusi Forum\nSedang Dalam Pengerjaan',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}

class _AIChatTabPlaceholder extends StatelessWidget {
  const _AIChatTabPlaceholder();

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(Icons.memory, size: 64, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            'Ruang Chat AI\nSedang Dalam Pengerjaan',
            textAlign: TextAlign.center,
            style: Theme.of(context).textTheme.bodyMedium?.copyWith(
              color: Colors.grey,
            ),
          ),
        ],
      ),
    );
  }
}