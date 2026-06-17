import 'package:flutter/material.dart';
import 'widgets/forum_tab.dart';

class CommunityScreen extends StatelessWidget {
  const CommunityScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return DefaultTabController(
      length: 2,
      child: Scaffold(
        // Background lebih clean biar kontennya menonjol
        backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
        appBar: AppBar(
          backgroundColor: isDark ? const Color(0xFF121212) : const Color(0xFFF8F9FA),
          elevation: 0,
          toolbarHeight: 100, // Kasih ruang napas yang luas di atas
          title: Padding(
            padding: const EdgeInsets.only(top: 24.0, left: 8.0, right: 8.0),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Ruang Diskusi',
                  style: theme.textTheme.headlineSmall?.copyWith(
                    fontWeight: FontWeight.w900,
                    letterSpacing: -0.5,
                    color: isDark ? Colors.white : Colors.black87,
                  ),
                ),
                const SizedBox(height: 6),
                Text(
                  'Tanya AI atau ngobrol bareng komunitas',
                  style: theme.textTheme.bodyMedium?.copyWith(
                    color: isDark ? Colors.grey.shade400 : Colors.grey.shade600,
                    fontWeight: FontWeight.w500,
                  ),
                ),
              ],
            ),
          ),
          bottom: PreferredSize(
            preferredSize: const Size.fromHeight(80),
            child: Container(
              height: 50,
              margin: const EdgeInsets.fromLTRB(20, 16, 20, 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222222) : Colors.white,
                borderRadius: BorderRadius.circular(25),
                boxShadow: [
                  if (!isDark)
                    BoxShadow(
                      color: Colors.black.withOpacity(0.04),
                      blurRadius: 10,
                      offset: const Offset(0, 4),
                    ),
                ],
              ),
              child: TabBar(
                indicatorSize: TabBarIndicatorSize.tab,
                dividerColor: Colors.transparent,
                indicator: BoxDecoration(
                  color: isDark ? theme.primaryColor.withOpacity(0.2) : theme.primaryColor.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(25),
                  border: Border.all(
                    color: theme.primaryColor.withOpacity(0.5),
                    width: 1,
                  ),
                ),
                labelColor: theme.primaryColor,
                unselectedLabelColor: isDark ? Colors.grey.shade500 : Colors.grey.shade400,
                labelStyle: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14),
                unselectedLabelStyle: const TextStyle(fontWeight: FontWeight.w600, fontSize: 14),
                tabs: const [
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.forum_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('Forum'),
                      ],
                    ),
                  ),
                  Tab(
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.auto_awesome_rounded, size: 20),
                        SizedBox(width: 8),
                        Text('AI Chat'),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ),
        body: const TabBarView(
          physics: BouncingScrollPhysics(),
          children: [
            ForumTab(),
            AIChatTab(),
          ],
        ),
      ),
    );
  }
}

class AIChatTab extends StatefulWidget {
  const AIChatTab({super.key});

  @override
  State<AIChatTab> createState() => _AIChatTabState();
}

class _AIChatTabState extends State<AIChatTab> {
  final TextEditingController _messageController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  // Dummy data chat untuk simulasi UI
  final List<Map<String, dynamic>> _messages = [
    {
      'role': 'assistant',
      'content': 'Halo! Saya asisten HealthTrack. Ada yang bisa saya bantu terkait kesehatan atau progres targetmu hari ini?',
    },
  ];

  bool _isTyping = false;

  void _sendMessage() {
    if (_messageController.text.trim().isEmpty) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'content': _messageController.text,
      });
      _isTyping = true; // Simulasi AI mikir
    });

    _messageController.clear();
    _scrollToBottom();

    // Simulasi jawaban AI setelah 2 detik
    Future.delayed(const Duration(seconds: 2), () {
      if (mounted) {
        setState(() {
          _isTyping = false;
          _messages.add({
            'role': 'assistant',
            'content': 'Ini adalah simulasi respon AI. Nanti bagian ini akan terhubung!',
          });
        });
        _scrollToBottom();
      }
    });
  }

  void _scrollToBottom() {
    Future.delayed(const Duration(milliseconds: 300), () {
      if (_scrollController.hasClients) {
        _scrollController.animateTo(
          _scrollController.position.maxScrollExtent,
          duration: const Duration(milliseconds: 300),
          curve: Curves.easeOut,
        );
      }
    });
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Column(
      children: [
        // AREA CHAT
        Expanded(
          child: _messages.length <= 1 && !_isTyping
              ? _buildWelcomeState(theme, isDark)
              : ListView.builder(
            controller: _scrollController,
            padding: const EdgeInsets.all(20),
            itemCount: _messages.length + (_isTyping ? 1 : 0),
            itemBuilder: (context, index) {
              if (index == _messages.length) {
                return _buildTypingIndicator(theme, isDark);
              }
              final msg = _messages[index];
              return _buildChatBubble(msg['role'] == 'user', msg['content'], theme, isDark);
            },
          ),
        ),

        // INPUT AREA
        _buildInputArea(theme, isDark),
      ],
    );
  }

  Widget _buildWelcomeState(ThemeData theme, bool isDark) {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(32),
      child: Column(
        children: [
          const SizedBox(height: 40),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              shape: BoxShape.circle,
              color: theme.primaryColor.withOpacity(0.1),
            ),
            child: Icon(Icons.auto_awesome_rounded, size: 48, color: theme.primaryColor),
          ),
          const SizedBox(height: 24),
          const Text(
            'Tanya Healti',
            style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          const Text(
            'Asisten kesehatan pribadimu yang didukung AI',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),

          // Suggested Prompts
          _buildSuggestedPrompt("Bagaimana cara mengurangi stres?"),
          _buildSuggestedPrompt("Berikan tips tidur lebih nyenyak."),
          _buildSuggestedPrompt("Apa manfaat meditasi pagi?"),
        ],
      ),
    );
  }

  Widget _buildSuggestedPrompt(String text) {
    final isDark = Theme.of(context).brightness == Brightness.dark;
    return Container(
      width: double.infinity,
      margin: const EdgeInsets.only(bottom: 12),
      child: OutlinedButton(
        onPressed: () {
          _messageController.text = text;
          _sendMessage();
        },
        style: OutlinedButton.styleFrom(
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 20),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          side: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
        ),
        child: Text(text, style: TextStyle(color: isDark ? Colors.white70 : Colors.black87)),
      ),
    );
  }

  Widget _buildChatBubble(bool isUser, String content, ThemeData theme, bool isDark) {
    return Align(
      alignment: isUser ? Alignment.centerRight : Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.all(16),
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.75),
        decoration: BoxDecoration(
          color: isUser
              ? theme.primaryColor
              : (isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
        ),
        child: Text(
          content,
          style: TextStyle(
            color: isUser ? Colors.white : (isDark ? Colors.white : Colors.black87),
            height: 1.4,
          ),
        ),
      ),
    );
  }

  Widget _buildTypingIndicator(ThemeData theme, bool isDark) {
    return Align(
      alignment: Alignment.centerLeft,
      child: Container(
        margin: const EdgeInsets.only(bottom: 16),
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade200,
          borderRadius: BorderRadius.circular(20),
        ),
        child: const Text('Healti sedang berpikir...', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey)),
      ),
    );
  }

  Widget _buildInputArea(ThemeData theme, bool isDark) {
    return Container(
      padding: const EdgeInsets.fromLTRB(20, 12, 20, 32),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF121212) : Colors.white,
        border: Border(top: BorderSide(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200)),
      ),
      child: Row(
        children: [
          Expanded(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              decoration: BoxDecoration(
                color: isDark ? const Color(0xFF222222) : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(24),
              ),
              child: TextField(
                controller: _messageController,
                decoration: const InputDecoration(
                  hintText: 'Tanya sesuatu...',
                  border: InputBorder.none,
                ),
                onSubmitted: (_) => _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _sendMessage,
            child: CircleAvatar(
              backgroundColor: theme.primaryColor,
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}