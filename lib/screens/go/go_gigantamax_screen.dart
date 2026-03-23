import 'package:flutter/material.dart';

// Gigantamax disponíveis no Pokémon GO (março 2026)
// Fonte: Bulbapedia - List of Pokémon capable of Gigantamaxing in GO
const _goGmax = [
  _GmaxEntry(baseId: 6,   name: 'Charizard',  note: ''),
  _GmaxEntry(baseId: 9,   name: 'Blastoise',  note: ''),
  _GmaxEntry(baseId: 3,   name: 'Venusaur',   note: ''),
  _GmaxEntry(baseId: 25,  name: 'Pikachu',    note: ''),
  _GmaxEntry(baseId: 52,  name: 'Meowth',     note: 'Forma Gigantamax'),
  _GmaxEntry(baseId: 94,  name: 'Gengar',     note: ''),
  _GmaxEntry(baseId: 131, name: 'Lapras',     note: ''),
  _GmaxEntry(baseId: 143, name: 'Snorlax',    note: 'Primeiro Gmax no GO'),
  _GmaxEntry(baseId: 569, name: 'Garbodor',   note: ''),
  _GmaxEntry(baseId: 809, name: 'Melmetal',   note: ''),
  _GmaxEntry(baseId: 812, name: 'Rillaboom',  note: ''),
  _GmaxEntry(baseId: 815, name: 'Cinderace',  note: ''),
  _GmaxEntry(baseId: 818, name: 'Inteleon',   note: ''),
  _GmaxEntry(baseId: 823, name: 'Corviknight', note: ''),
  _GmaxEntry(baseId: 826, name: 'Orbeetle',   note: ''),
  _GmaxEntry(baseId: 834, name: 'Drednaw',    note: ''),
  _GmaxEntry(baseId: 839, name: 'Coalossal',  note: ''),
  _GmaxEntry(baseId: 841, name: 'Flapple',    note: ''),
  _GmaxEntry(baseId: 842, name: 'Appletun',   note: ''),
  _GmaxEntry(baseId: 844, name: 'Sandaconda', note: ''),
  _GmaxEntry(baseId: 849, name: 'Toxtricity', note: ''),
  _GmaxEntry(baseId: 851, name: 'Centiskorch', note: ''),
  _GmaxEntry(baseId: 858, name: 'Hatterene',  note: ''),
  _GmaxEntry(baseId: 861, name: 'Grimmsnarl', note: ''),
  _GmaxEntry(baseId: 869, name: 'Alcremie',   note: ''),
  _GmaxEntry(baseId: 873, name: 'Frosmoth',   note: ''),
  _GmaxEntry(baseId: 879, name: 'Copperajah', note: ''),
  _GmaxEntry(baseId: 884, name: 'Duraludon',  note: ''),
  _GmaxEntry(baseId: 892, name: 'Urshifu',    note: 'Forma Golpe Único / Rápido'),
];

class GoGigantamaxScreen extends StatelessWidget {
  const GoGigantamaxScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gigantamax'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(children: [
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 4),
          child: Text(
            '${_goGmax.length} Pokémon com Gigantamax disponíveis no GO',
            style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant),
          ),
        ),
        Expanded(child: GridView.builder(
          padding: const EdgeInsets.all(12),
          gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
            crossAxisCount:   3,
            childAspectRatio: 0.85,
            crossAxisSpacing: 8,
            mainAxisSpacing:  8,
          ),
          itemCount: _goGmax.length,
          itemBuilder: (context, i) => _GmaxTile(entry: _goGmax[i], scheme: scheme),
        )),
      ]),
    );
  }
}

class _GmaxTile extends StatelessWidget {
  final _GmaxEntry  entry;
  final ColorScheme scheme;
  const _GmaxTile({required this.entry, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
        Image.asset(
          'assets/sprites/artwork/${entry.baseId}.webp',
          width: 64, height: 64, fit: BoxFit.contain,
          errorBuilder: (_, __, ___) => Icon(
              Icons.catching_pokemon, size: 40, color: scheme.onSurfaceVariant),
        ),
        const SizedBox(height: 4),
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4),
          child: Text(
            entry.name,
            style: const TextStyle(fontSize: 11, fontWeight: FontWeight.w600),
            textAlign: TextAlign.center,
            maxLines: 1, overflow: TextOverflow.ellipsis,
          ),
        ),
        if (entry.note.isNotEmpty)
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 4),
            child: Text(entry.note,
              style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant),
              textAlign: TextAlign.center,
              maxLines: 1, overflow: TextOverflow.ellipsis),
          ),
      ]),
    );
  }
}

class _GmaxEntry {
  final int    baseId;
  final String name;
  final String note;
  const _GmaxEntry({required this.baseId, required this.name, required this.note});
}
