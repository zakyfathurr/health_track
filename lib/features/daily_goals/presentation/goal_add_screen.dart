import 'package:flutter/material.dart';

class GoalAddScreen extends StatelessWidget {
  const GoalAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tambah Target')),
      body: const Center(child: Text('Form tambah target harian')),
    );
  }
}
