import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class GoalsListScreen extends StatelessWidget {
  const GoalsListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Target Harian')),
      body: const Center(
        child: Text('Daftar target harian akan tampil di sini'),
      ),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/goals/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
