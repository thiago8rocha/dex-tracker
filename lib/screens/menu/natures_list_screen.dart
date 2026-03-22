import 'package:flutter/material.dart';

class NaturesListScreen extends StatelessWidget {
  const NaturesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Naturezas')),
      body: const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.psychology_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text('Lista completa de Naturezas', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Em breve', style: TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }
}