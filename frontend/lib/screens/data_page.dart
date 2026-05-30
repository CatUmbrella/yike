import 'package:flutter/material.dart';

class DataPage extends StatelessWidget {
  const DataPage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('数据'), centerTitle: true),
      body: const Center(
          child: Text('数据 - 即将实现', style: TextStyle(color: Colors.grey))),
    );
  }
}
