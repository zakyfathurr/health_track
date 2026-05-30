import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class MoodListScreen extends StatelessWidget {
  const MoodListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Mood Journal')),
      body: const Center(child: Text('Daftar mood akan tampil di sini')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/mood/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
