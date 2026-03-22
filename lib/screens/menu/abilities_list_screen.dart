import 'package:flutter/material.dart';

class AbilitiesListScreen extends StatelessWidget {
  const AbilitiesListScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Habilidades')),
      body: const Center(
        child: Column(mainAxisSize: MainAxisSize.min, children: [
          Icon(Icons.auto_awesome_outlined, size: 48, color: Colors.grey),
          SizedBox(height: 12),
          Text('Lista completa de Habilidades', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
          SizedBox(height: 6),
          Text('Em breve', style: TextStyle(color: Colors.grey)),
        ]),
      ),
    );
  }
}