import 'package:flutter/material.dart';
import 'widgets/forum_tab.dart';
import 'dart:convert';
import 'dart:developer' as developer;
import 'package:flutter_markdown/flutter_markdown.dart';
import 'package:http/http.dart' as http;

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

  // Naikkan client ke level class supaya bisa di-cancel (abort) secara manual
  http.Client? _streamingClient;

  List<Map<String, String>> _messages = [];
  bool _isTyping = false;

  @override
  void initState() {
    super.initState();
    _initWelcomeMessage();
  }

  @override
  void dispose() {
    _messageController.dispose();
    _scrollController.dispose();
    _streamingClient?.close(); // Pastikan memory leak gak terjadi pas tab ditutup
    super.dispose();
  }

  void _initWelcomeMessage() {
    _messages = [
      {
        'role': 'assistant',
        'content': 'Halo Nafiz! Saya asisten HealthTrack. Ada yang bisa saya bantu terkait kesehatan atau targetmu hari ini?',
      },
    ];
  }

  // LOGIKA RESET CHAT YANG BENAR
  void _resetChat() {
    // 1. Bunuh koneksi stream yang lagi jalan (kalau ada)
    _streamingClient?.close();

    // 2. Reset UI ke state awal
    setState(() {
      _isTyping = false;
      _initWelcomeMessage();
    });
  }

  Future<void> _sendMessage() async {
    final text = _messageController.text.trim();
    if (text.isEmpty) return;

    setState(() {
      _messages.add({
        'role': 'user',
        'content': text,
      });
      _isTyping = true;
    });

    _messageController.clear();
    _scrollToBottom();

    final cleanMessages = _messages.where((m) {
      final content = m['content'] ?? '';
      return !content.startsWith('⚠️');
    }).toList();

    const groqApiKey = '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';
    const groqModel = 'llama-3.1-8b-instant';

    final payload = {
      "model": groqModel,
      "messages": cleanMessages,
      "temperature": 0.7,
      "stream": true
    };

    final request = http.Request('POST', Uri.parse('https://api.groq.com/openai/v1/chat/completions'));
    request.headers.addAll({
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $groqApiKey',
    });
    request.body = jsonEncode(payload);

    // Inisialisasi client baru setiap kali kirim pesan
    _streamingClient = http.Client();

    try {
      final streamedResponse = await _streamingClient!.send(request).timeout(const Duration(seconds: 15));

      if (streamedResponse.statusCode != 200) {
        final errorBody = await streamedResponse.stream.bytesToString();
        throw Exception('HTTP ${streamedResponse.statusCode}\nBody: $errorBody');
      }

      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': '',
          });
          _isTyping = false;
        });
      }

      streamedResponse.stream
          .transform(utf8.decoder)
          .transform(const LineSplitter())
          .listen(
            (line) {
          if (line.isEmpty) return;

          if (line.startsWith('data: ')) {
            final dataStr = line.replaceFirst('data: ', '').trim();
            if (dataStr == '[DONE]') return;

            try {
              final data = jsonDecode(dataStr);
              final choices = data['choices'] as List<dynamic>?;
              if (choices != null && choices.isNotEmpty) {
                final delta = choices[0]['delta'] as Map<String, dynamic>?;
                final contentChunk = delta?['content'] as String?;

                if (contentChunk != null && contentChunk.isNotEmpty) {
                  if (mounted) {
                    setState(() {
                      _messages.last['content'] = _messages.last['content']! + contentChunk;
                    });
                    _scrollToBottom();
                  }
                }
              }
            } catch (e) {
              // Ignore parse errors per chunk
            }
          }
        },
        onDone: () => _streamingClient?.close(),
        onError: (error) => _streamingClient?.close(),
        cancelOnError: true,
      );

    } catch (e) {
      if (mounted) {
        setState(() {
          _messages.add({
            'role': 'assistant',
            'content': '⚠️ Asisten gagal terhubung ke server.\nDetail: ${e.toString()}',
          });
          _isTyping = false;
        });
        _scrollToBottom();
      }
      _streamingClient?.close();
    }
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
        // HEADER KECIL UNTUK RESET CHAT
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 8),
          decoration: BoxDecoration(
            border: Border(bottom: BorderSide(color: isDark ? Colors.grey.shade900 : Colors.grey.shade200)),
          ),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  Container(
                    width: 8,
                    height: 8,
                    decoration: const BoxDecoration(color: Colors.green, shape: BoxShape.circle),
                  ),
                  const SizedBox(width: 8),
                  Text(
                    'Online',
                    style: TextStyle(color: isDark ? Colors.grey.shade400 : Colors.grey.shade600, fontSize: 13, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
              TextButton.icon(
                onPressed: _resetChat,
                icon: const Icon(Icons.refresh_rounded, size: 16),
                label: const Text('Reset Obrolan', style: TextStyle(fontSize: 13, fontWeight: FontWeight.bold)),
                style: TextButton.styleFrom(
                  foregroundColor: Colors.redAccent,
                  padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
                  minimumSize: Size.zero,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                  backgroundColor: Colors.redAccent.withOpacity(0.1),
                ),
              ),
            ],
          ),
        ),

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
              return _buildChatBubble(msg['role'] == 'user', msg['content']!, theme, isDark);
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
            'Asisten kesehatan pribadimu yang ditenagai Llama 3',
            textAlign: TextAlign.center,
            style: TextStyle(color: Colors.grey),
          ),
          const SizedBox(height: 40),

          _buildSuggestedPrompt("Berapa target protein harian untuk workout?"),
          _buildSuggestedPrompt("Bantu aku merencanakan jadwal istirahat."),
          _buildSuggestedPrompt("Jelaskan manfaat kalori defisit."),
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
        // Lebarkan sedikit batasnya karena Markdown butuh ruang untuk list dan blockquote
        constraints: BoxConstraints(maxWidth: MediaQuery.of(context).size.width * 0.85),
        decoration: BoxDecoration(
          color: isUser
              ? theme.primaryColor
              : (isDark ? const Color(0xFF222222) : Colors.white),
          borderRadius: BorderRadius.only(
            topLeft: const Radius.circular(20),
            topRight: const Radius.circular(20),
            bottomLeft: Radius.circular(isUser ? 20 : 0),
            bottomRight: Radius.circular(isUser ? 0 : 20),
          ),
          // Tambahkan shadow halus khusus buat bubble AI biar lebih pop-out
          boxShadow: isUser ? [] : [
            BoxShadow(
              color: Colors.black.withOpacity(isDark ? 0.2 : 0.05),
              blurRadius: 10,
              offset: const Offset(0, 4),
            )
          ],
          border: isUser ? null : Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
        ),
        child: isUser
            ? Text(
          content,
          style: const TextStyle(color: Colors.white, height: 1.4, fontSize: 15),
        )
            : MarkdownBody(
          data: content,
          selectable: true, // Biar user bisa copas teks jawabannya
          styleSheet: MarkdownStyleSheet(
            p: TextStyle(color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87, height: 1.5, fontSize: 15),
            h1: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.w900, fontSize: 22),
            h2: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 18),
            h3: TextStyle(color: isDark ? Colors.white : Colors.black87, fontWeight: FontWeight.bold, fontSize: 16),
            strong: TextStyle(fontWeight: FontWeight.bold, color: isDark ? Colors.white : Colors.black),
            em: const TextStyle(fontStyle: FontStyle.italic),
            listBullet: TextStyle(color: theme.primaryColor, fontSize: 16),
            blockquoteDecoration: BoxDecoration(
              color: isDark ? Colors.grey.shade800.withOpacity(0.5) : theme.primaryColor.withOpacity(0.05),
              border: Border(left: BorderSide(color: theme.primaryColor, width: 4)),
              borderRadius: BorderRadius.circular(4),
            ),
            blockquotePadding: const EdgeInsets.all(12),
            code: TextStyle(
              backgroundColor: Colors.transparent,
              color: isDark ? Colors.orange.shade300 : Colors.pink.shade700,
              fontFamily: 'monospace',
              fontWeight: FontWeight.w600,
            ),
            codeblockDecoration: BoxDecoration(
              color: isDark ? const Color(0xFF1A1A1A) : Colors.grey.shade100,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(color: isDark ? Colors.grey.shade800 : Colors.grey.shade300),
            ),
            codeblockPadding: const EdgeInsets.all(16),
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
        child: const Text('Healti sedang mengetik...', style: TextStyle(fontStyle: FontStyle.italic, fontSize: 12, color: Colors.grey)),
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
                onSubmitted: (_) => _isTyping ? null : _sendMessage(),
              ),
            ),
          ),
          const SizedBox(width: 12),
          GestureDetector(
            onTap: _isTyping ? null : _sendMessage,
            child: CircleAvatar(
              backgroundColor: _isTyping ? Colors.grey : theme.primaryColor,
              child: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
            ),
          ),
        ],
      ),
    );
  }
}