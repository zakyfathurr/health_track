import 'package:flutter/material.dart';

class MoodAddScreen extends StatelessWidget {
  const MoodAddScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Catat Mood')),
      body: const Center(child: Text('Form tambah mood')),
    );
  }
}
