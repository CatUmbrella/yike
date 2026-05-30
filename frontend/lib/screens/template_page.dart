import 'package:flutter/material.dart';

class TemplatePage extends StatelessWidget {
  const TemplatePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('模板'), centerTitle: true),
      body: const Center(
          child: Text('模板 - 即将实现', style: TextStyle(color: Colors.grey))),
    );
  }
}
