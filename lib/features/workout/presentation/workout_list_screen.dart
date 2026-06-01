import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

class WorkoutListScreen extends StatelessWidget {
  const WorkoutListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Workout Tracker')),
      body: const Center(child: Text('Daftar workout akan tampil di sini')),
      floatingActionButton: FloatingActionButton(
        onPressed: () => context.push('/workout/add'),
        child: const Icon(Icons.add),
      ),
    );
  }
}
