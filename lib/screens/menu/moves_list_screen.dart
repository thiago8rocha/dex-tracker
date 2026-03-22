import 'package:flutter/material.dart';

class MovesListScreen extends StatelessWidget {
  const MovesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Golpes')),
      body: const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.sports_martial_arts_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text('Lista completa de Golpes', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Em breve', style: TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }
}