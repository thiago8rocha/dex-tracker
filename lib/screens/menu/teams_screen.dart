import 'package:flutter/material.dart';

class TeamsScreen extends StatelessWidget {
  const TeamsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Times')),
      body: const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.groups_2_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text('Criação de Times', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Em breve', style: TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }
}