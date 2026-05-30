import 'package:flutter/material.dart';

class PomodoroPage extends StatelessWidget {
  const PomodoroPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('番茄钟'), centerTitle: true),
      body: const Center(
          child: Text('番茄钟 - 即将实现', style: TextStyle(color: Colors.grey))),
    );
  }
}
