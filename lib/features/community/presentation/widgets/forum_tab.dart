import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../../data/forum_repository.dart';
import '../../domain/post_model.dart';
import '../../domain/comment_model.dart';

class ForumTab extends StatefulWidget {
  const ForumTab({super.key});

  @override
  State<ForumTab> createState() => _ForumTabState();
}

class _ForumTabState extends State<ForumTab> {
  final ForumRepository _repository = ForumRepository();
  final TextEditingController _postController = TextEditingController();

  // BUKAN ALERT DIALOG LAGI. UI Modern pakai Bottom Sheet untuk Compose.
  void _showCreatePostSheet(BuildContext context) {
    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      backgroundColor: Colors.transparent,
      builder: (context) {
        final theme = Theme.of(context);
        final isDark = theme.brightness == Brightness.dark;

        return Container(
          height: MediaQuery.of(context).size.height * 0.85,
          decoration: BoxDecoration(
            color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
            borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
          ),
          child: Column(
            children: [
              // Header Sheet
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    TextButton(
                      onPressed: () {
                        _postController.clear();
                        Navigator.pop(context);
                      },
                      style: TextButton.styleFrom(foregroundColor: Colors.grey),
                      child: const Text('Batal'),
                    ),
                    const Text('Buat Postingan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                    ElevatedButton(
                      onPressed: () async {
                        if (_postController.text.trim().isEmpty) return;

                        final user = FirebaseAuth.instance.currentUser;
                        final name = user?.displayName;
                        final emailPrefix = user?.email?.split('@')[0];

                        final authorName = (name != null && name.trim().isNotEmpty)
                            ? name
                            : (emailPrefix != null && emailPrefix.isNotEmpty ? emailPrefix : 'Anonim');

                        await _repository.createPost(_postController.text, authorName);
                        _postController.clear();
                        if (context.mounted) Navigator.pop(context);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: theme.primaryColor,
                        foregroundColor: Colors.white,
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                        elevation: 0,
                      ),
                      child: const Text('Posting', style: TextStyle(fontWeight: FontWeight.bold)),
                    ),
                  ],
                ),
              ),
              const Divider(height: 1),

              // Area Text Input yang Luas
              Expanded(
                child: Padding(
                  padding: const EdgeInsets.all(20.0),
                  child: TextField(
                    controller: _postController,
                    maxLines: null,
                    autofocus: true,
                    textInputAction: TextInputAction.newline,
                    style: const TextStyle(fontSize: 18, height: 1.5),
                    decoration: const InputDecoration(
                      hintText: 'Apa yang sedang kamu pikirkan hari ini?',
                      border: InputBorder.none,
                      hintStyle: TextStyle(color: Colors.grey, fontSize: 18),
                    ),
                  ),
                ),
              ),
            ],
          ),
        );
      },
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final isDark = theme.brightness == Brightness.dark;

    return Scaffold(
      backgroundColor: Colors.transparent,
      body: StreamBuilder<List<PostModel>>(
        stream: _repository.getPostsStream(),
        builder: (context, snapshot) {
          if (snapshot.connectionState == ConnectionState.waiting) {
            return const Center(child: CircularProgressIndicator());
          }

          if (snapshot.hasError) {
            return Center(child: Text('Error: ${snapshot.error}'));
          }

          final posts = snapshot.data ?? [];

          // EMPTY STATE MODERN
          if (posts.isEmpty) {
            return Center(
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(Icons.forum_rounded, size: 80, color: theme.primaryColor.withOpacity(0.3)),
                  const SizedBox(height: 16),
                  Text(
                    'Belum ada obrolan',
                    style: theme.textTheme.titleLarge?.copyWith(fontWeight: FontWeight.bold),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Jadilah yang pertama memulai diskusi hari ini!',
                    style: theme.textTheme.bodyMedium?.copyWith(color: Colors.grey),
                  ),
                ],
              ),
            );
          }

          return ListView.separated(
            padding: const EdgeInsets.only(top: 16, left: 16, right: 16, bottom: 80), // Bottom padding biar gak ketutup FAB
            itemCount: posts.length,
            separatorBuilder: (context, index) => const SizedBox(height: 16),
            itemBuilder: (context, index) {
              return _PostCard(post: posts[index], isDark: isDark, theme: theme);
            },
          );
        },
      ),
      floatingActionButton: FloatingActionButton.extended(
        onPressed: () => _showCreatePostSheet(context),
        backgroundColor: theme.primaryColor,
        foregroundColor: Colors.white,
        elevation: 4,
        icon: const Icon(Icons.edit_rounded),
        label: const Text('Post', style: TextStyle(fontWeight: FontWeight.bold)),
      ),
    );
  }
}

class _PostCard extends StatelessWidget {
  final PostModel post;
  final bool isDark;
  final ThemeData theme;

  const _PostCard({
    required this.post,
    required this.isDark,
    required this.theme,
  });

  String _formatTimestamp(DateTime time) {
    final now = DateTime.now();
    final diff = now.difference(time);
    final timeString = '${time.hour.toString().padLeft(2, '0')}:${time.minute.toString().padLeft(2, '0')}';

    if (diff.inHours < 24 && now.day == time.day) {
      return timeString;
    } else {
      return '${time.day}/${time.month}/${time.year} $timeString';
    }
  }

  @override
  Widget build(BuildContext context) {
    final dateStr = _formatTimestamp(post.createdAt);
    final ForumRepository repository = ForumRepository();

    final currentUserId = FirebaseAuth.instance.currentUser?.uid ?? '';
    final isLiked = post.likedBy.contains(currentUserId);
    final totalLikes = post.likedBy.length;

    final displayName = post.authorName.trim().isEmpty ? 'Anonim' : post.authorName;
    final initial = displayName[0].toUpperCase();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: isDark ? const Color(0xFF222222) : Colors.white,
        borderRadius: BorderRadius.circular(20),
        border: Border.all(
          color: isDark ? Colors.grey.shade800 : Colors.grey.shade200,
          width: 1,
        ),
        boxShadow: [
          BoxShadow(
            color: isDark ? Colors.black.withOpacity(0.2) : Colors.black.withOpacity(0.03),
            blurRadius: 15,
            offset: const Offset(0, 4),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              CircleAvatar(
                backgroundColor: theme.colorScheme.primaryContainer,
                radius: 22,
                child: Text(
                    initial,
                    style: TextStyle(
                      color: theme.colorScheme.onPrimaryContainer,
                      fontWeight: FontWeight.bold,
                      fontSize: 18,
                    )
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      displayName,
                      style: theme.textTheme.titleMedium?.copyWith(
                        fontWeight: FontWeight.w700,
                        letterSpacing: -0.5,
                      ),
                    ),
                    Text(
                      dateStr,
                      style: theme.textTheme.bodySmall?.copyWith(
                        color: isDark ? Colors.grey.shade500 : Colors.grey.shade600,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ],
                ),
              ),
              // Menu Opsi hanya muncul untuk pemilik post
              if (currentUserId == post.authorId)
                IconButton(
                  icon: const Icon(Icons.more_horiz_rounded, color: Colors.grey),
                  splashRadius: 20,
                  onPressed: () {
                    _showPostOptions(context, post, theme, isDark, repository);
                  },
                ),
            ],
          ),

          Padding(
            padding: const EdgeInsets.only(top: 12, bottom: 16),
            child: Text(
              post.content,
              style: theme.textTheme.bodyLarge?.copyWith(
                height: 1.5,
                color: isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
              ),
            ),
          ),

          Container(
            padding: const EdgeInsets.symmetric(vertical: 4),
            decoration: BoxDecoration(
              border: Border(top: BorderSide(color: isDark ? Colors.grey.shade800 : Colors.grey.shade200)),
            ),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.start,
              children: [
                _buildActionButton(
                  icon: isLiked ? Icons.favorite_rounded : Icons.favorite_outline_rounded,
                  count: totalLikes,
                  isActive: isLiked,
                  activeColor: Colors.redAccent,
                  theme: theme,
                  onTap: () async {
                    try {
                      await repository.toggleLike(post.id, post.likedBy);
                    } catch (_) {
                      if (context.mounted) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          const SnackBar(
                            content: Text('Gagal memberi like, coba lagi'),
                            behavior: SnackBarBehavior.floating,
                          ),
                        );
                      }
                    }
                  },
                ),
                const SizedBox(width: 24),
                _buildActionButton(
                  icon: Icons.chat_bubble_outline_rounded,
                  count: post.commentsCount,
                  isActive: false,
                  activeColor: theme.primaryColor,
                  theme: theme,
                  onTap: () {
                    showModalBottomSheet(
                      context: context,
                      isScrollControlled: true,
                      backgroundColor: Colors.transparent,
                      builder: (context) => _CommentsSheet(
                        postId: post.id,
                        theme: theme,
                        isDark: isDark,
                      ),
                    );
                  },
                ),
                const Spacer(),
                IconButton(
                  icon: const Icon(Icons.ios_share_rounded, size: 20, color: Colors.grey),
                  splashRadius: 20,
                  onPressed: () {},
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildActionButton({
    required IconData icon,
    required int count,
    required bool isActive,
    required Color activeColor,
    required ThemeData theme,
    required VoidCallback onTap,
  }) {
    final color = isActive ? activeColor : Colors.grey.shade600;
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(20),
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 8.0, horizontal: 8.0),
        child: Row(
          children: [
            Icon(icon, size: 22, color: color),
            if (count > 0) ...[
              const SizedBox(width: 6),
              Text(
                '$count',
                style: TextStyle(
                  color: color,
                  fontWeight: isActive ? FontWeight.bold : FontWeight.w600,
                  fontSize: 14,
                ),
              ),
            ]
          ],
        ),
      ),
    );
  }
}

// ==========================================
// FUNGSI UI UNTUK EDIT & DELETE (Modern Bottom Sheets)
// ==========================================

void _showPostOptions(BuildContext context, PostModel post, ThemeData theme, bool isDark, ForumRepository repo) {
  showModalBottomSheet(
    context: context,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        margin: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF222222) : Colors.white,
          borderRadius: BorderRadius.circular(20),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ListTile(
              leading: Icon(Icons.edit_rounded, color: theme.primaryColor),
              title: const Text('Edit Postingan', style: TextStyle(fontWeight: FontWeight.w600)),
              onTap: () {
                Navigator.pop(context); // Tutup menu opsi
                _showEditPostSheet(context, post, theme, isDark, repo); // Buka sheet edit
              },
            ),
            Divider(height: 1, color: isDark ? Colors.grey.shade800 : Colors.grey.shade200),
            ListTile(
              leading: const Icon(Icons.delete_outline_rounded, color: Colors.redAccent),
              title: const Text('Hapus Postingan', style: TextStyle(fontWeight: FontWeight.w600, color: Colors.redAccent)),
              onTap: () {
                Navigator.pop(context); // Tutup menu opsi
                _showDeleteConfirmation(context, post.id, isDark, repo); // Buka popup konfirmasi
              },
            ),
          ],
        ),
      );
    },
  );
}

void _showEditPostSheet(BuildContext context, PostModel post, ThemeData theme, bool isDark, ForumRepository repo) {
  final TextEditingController editCtrl = TextEditingController(text: post.content);

  showModalBottomSheet(
    context: context,
    isScrollControlled: true,
    backgroundColor: Colors.transparent,
    builder: (context) {
      return Container(
        height: MediaQuery.of(context).size.height * 0.85,
        decoration: BoxDecoration(
          color: isDark ? const Color(0xFF1A1A1A) : Colors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
        ),
        child: Column(
          children: [
            Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  TextButton(
                    onPressed: () => Navigator.pop(context),
                    style: TextButton.styleFrom(foregroundColor: Colors.grey),
                    child: const Text('Batal'),
                  ),
                  const Text('Edit Postingan', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 16)),
                  ElevatedButton(
                    onPressed: () async {
                      if (editCtrl.text.trim().isEmpty) return;
                      await repo.updatePost(post.id, editCtrl.text.trim());
                      if (context.mounted) Navigator.pop(context);
                    },
                    style: ElevatedButton.styleFrom(
                      backgroundColor: theme.primaryColor,
                      foregroundColor: Colors.white,
                      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
                      elevation: 0,
                    ),
                    child: const Text('Simpan', style: TextStyle(fontWeight: FontWeight.bold)),
                  ),
                ],
              ),
            ),
            const Divider(height: 1),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(20.0),
                child: TextField(
                  controller: editCtrl,
                  maxLines: null,
                  autofocus: true,
                  textInputAction: TextInputAction.newline,
                  style: const TextStyle(fontSize: 18, height: 1.5),
                  decoration: const InputDecoration(
                    border: InputBorder.none,
                  ),
                ),
              ),
            ),
          ],
        ),
      );
    },
  );
}

void _showDeleteConfirmation(BuildContext context, String postId, bool isDark, ForumRepository repo) {
  showDialog(
    context: context,
    builder: (context) {
      return AlertDialog(
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
        backgroundColor: isDark ? const Color(0xFF222222) : Colors.white,
        title: const Text('Hapus Postingan?', style: TextStyle(fontWeight: FontWeight.bold)),
        content: const Text('Postingan ini beserta komentarnya tidak dapat dikembalikan lagi setelah dihapus.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Batal', style: TextStyle(color: Colors.grey)),
          ),
          ElevatedButton(
            onPressed: () async {
              await repo.deletePost(postId);
              if (context.mounted) {
                Navigator.pop(context);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(content: Text('Postingan dihapus'), behavior: SnackBarBehavior.floating),
                );
              }
            },
            style: ElevatedButton.styleFrom(
              backgroundColor: Colors.redAccent,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
            ),
            child: const Text('Ya, Hapus'),
          ),
        ],
      );
    },
  );
}

// STATEFUL WIDGET UNTUK BOTTOM SHEET KOMENTAR
class _CommentsSheet extends StatefulWidget {
  final String postId;
  final ThemeData theme;
  final bool isDark;

  const _CommentsSheet({
    required this.postId,
    required this.theme,
    required this.isDark,
  });

  @override
  State<_CommentsSheet> createState() => _CommentsSheetState();
}

class _CommentsSheetState extends State<_CommentsSheet> {
  final TextEditingController _commentCtrl = TextEditingController();
  final FocusNode _focusNode = FocusNode();
  final ForumRepository _repository = ForumRepository();

  @override
  void dispose() {
    _commentCtrl.dispose();
    _focusNode.dispose();
    super.dispose();
  }

  void _replyTo(String username) {
    setState(() {
      _commentCtrl.text = '@$username ';
    });
    _commentCtrl.selection = TextSelection.fromPosition(
      TextPosition(offset: _commentCtrl.text.length),
    );
    _focusNode.requestFocus();
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: widget.isDark ? const Color(0xFF1A1A1A) : Colors.white,
        borderRadius: const BorderRadius.vertical(top: Radius.circular(24)),
      ),
      padding: EdgeInsets.only(bottom: MediaQuery.of(context).viewInsets.bottom),
      child: SizedBox(
        height: MediaQuery.of(context).size.height * 0.75,
        child: Column(
          children: [
            // Handle Bar (Garis kecil di atas sheet)
            const SizedBox(height: 12),
            Container(
              width: 48,
              height: 5,
              decoration: BoxDecoration(
                color: widget.isDark ? Colors.grey.shade700 : Colors.grey.shade300,
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            const Padding(
              padding: EdgeInsets.all(16.0),
              child: Text('Balasan', style: TextStyle(fontWeight: FontWeight.w800, fontSize: 18)),
            ),
            Divider(height: 1, color: widget.isDark ? Colors.grey.shade800 : Colors.grey.shade200),

            // Stream Komentar
            Expanded(
              child: StreamBuilder<List<CommentModel>>(
                stream: _repository.getCommentsStream(widget.postId),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return const Center(child: CircularProgressIndicator());
                  }
                  final comments = snapshot.data ?? [];
                  if (comments.isEmpty) {
                    return Center(
                        child: Column(
                          mainAxisAlignment: MainAxisAlignment.center,
                          children: [
                            Icon(Icons.chat_bubble_outline_rounded, size: 60, color: Colors.grey.shade400),
                            const SizedBox(height: 16),
                            const Text('Belum ada balasan', style: TextStyle(color: Colors.grey, fontWeight: FontWeight.w600)),
                          ],
                        )
                    );
                  }
                  return ListView.separated(
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
                    itemCount: comments.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 20),
                    itemBuilder: (context, index) {
                      final c = comments[index];
                      final initial = c.authorName.isNotEmpty ? c.authorName[0].toUpperCase() : '?';

                      return Row(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          CircleAvatar(
                            radius: 18,
                            backgroundColor: widget.theme.colorScheme.secondaryContainer,
                            child: Text(
                                initial,
                                style: TextStyle(
                                  color: widget.theme.colorScheme.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                  fontSize: 14,
                                )
                            ),
                          ),
                          const SizedBox(width: 12),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Row(
                                  children: [
                                    Text(
                                        c.authorName,
                                        style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 14)
                                    ),
                                  ],
                                ),
                                const SizedBox(height: 4),
                                Text(
                                    c.content,
                                    style: TextStyle(
                                      fontSize: 14,
                                      height: 1.4,
                                      color: widget.isDark ? Colors.white.withOpacity(0.9) : Colors.black87,
                                    )
                                ),
                                const SizedBox(height: 6),
                                InkWell(
                                  onTap: () => _replyTo(c.authorName),
                                  child: const Text(
                                    'Balas',
                                    style: TextStyle(fontSize: 12, fontWeight: FontWeight.bold, color: Colors.grey),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ],
                      );
                    },
                  );
                },
              ),
            ),

            // Area Input Komentar Modern
            Container(
              padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              decoration: BoxDecoration(
                color: widget.isDark ? const Color(0xFF222222) : Colors.white,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.05),
                    offset: const Offset(0, -4),
                    blurRadius: 10,
                  )
                ],
              ),
              child: Row(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Expanded(
                    child: Container(
                      decoration: BoxDecoration(
                        color: widget.isDark ? const Color(0xFF2A2A2A) : Colors.grey.shade100,
                        borderRadius: BorderRadius.circular(24),
                        border: Border.all(color: widget.isDark ? Colors.grey.shade800 : Colors.transparent),
                      ),
                      child: TextField(
                        controller: _commentCtrl,
                        focusNode: _focusNode,
                        maxLines: 4,
                        minLines: 1,
                        textInputAction: TextInputAction.newline,
                        style: const TextStyle(fontSize: 15),
                        decoration: const InputDecoration(
                          hintText: 'Tambahkan balasan...',
                          border: InputBorder.none,
                          contentPadding: EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                        ),
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Container(
                    decoration: BoxDecoration(
                      color: widget.theme.primaryColor,
                      shape: BoxShape.circle,
                    ),
                    child: IconButton(
                      icon: const Icon(Icons.send_rounded, color: Colors.white, size: 20),
                      onPressed: () async {
                        if (_commentCtrl.text.trim().isEmpty) return;

                        final user = FirebaseAuth.instance.currentUser;
                        final name = user?.displayName;
                        final emailPrefix = user?.email?.split('@')[0];
                        final authorName = (name != null && name.trim().isNotEmpty)
                            ? name
                            : (emailPrefix != null && emailPrefix.isNotEmpty ? emailPrefix : 'Anonim');

                        try {
                          await _repository.addComment(widget.postId, _commentCtrl.text, authorName);
                          _commentCtrl.clear();
                          _focusNode.unfocus();
                        } catch (_) {
                          if (mounted) {
                            ScaffoldMessenger.of(context).showSnackBar(
                              const SnackBar(
                                content: Text('Gagal mengirim balasan, coba lagi'),
                                behavior: SnackBarBehavior.floating,
                              ),
                            );
                          }
                        }
                      },
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}