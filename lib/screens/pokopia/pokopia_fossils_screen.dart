import 'package:flutter/material.dart';

class PokopiaFossilsScreen extends StatefulWidget {
  const PokopiaFossilsScreen({super.key});

  @override
  State<PokopiaFossilsScreen> createState() => _PokopiaFossilsScreenState();
}

class _PokopiaFossilsScreenState extends State<PokopiaFossilsScreen> {
  String _search = '';

  List<_FossilData> get _filtered {
    if (_search.isEmpty) return _fossils;
    final q = _search.toLowerCase();
    return _fossils.where((f) =>
      f.pokemon.toLowerCase().contains(q) ||
      f.parts.any((p) => p.toLowerCase().contains(q))
    ).toList();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final filtered = _filtered;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Fósseis'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(children: [
        // Busca
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Buscar fóssil ou Pokémon...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.outlineVariant),
              ),
              contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ),

        // Lista
        Expanded(
          child: filtered.isEmpty
              ? Center(child: Text('Nenhum fóssil encontrado.',
                  style: TextStyle(color: scheme.onSurfaceVariant)))
              : ListView.separated(
                  padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                  itemCount: filtered.length,
                  separatorBuilder: (_, __) => const SizedBox(height: 8),
                  itemBuilder: (ctx, i) => _FossilTile(data: filtered[i]),
                ),
        ),
      ]),
    );
  }
}

// ─── TILE ─────────────────────────────────────────────────────────

class _FossilTile extends StatelessWidget {
  final _FossilData data;
  const _FossilTile({required this.data});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: scheme.outlineVariant, width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Nome do Pokémon
          Text(data.pokemon,
            style: Theme.of(context).textTheme.titleSmall?.copyWith(
              fontWeight: FontWeight.w600)),
          const SizedBox(height: 6),
          // Peças necessárias
          ...data.parts.map((part) => Padding(
            padding: const EdgeInsets.only(bottom: 3),
            child: Text(
              part,
              style: TextStyle(
                fontSize: 12,
                color: scheme.onSurfaceVariant,
              ),
            ),
          )),
        ],
      ),
    );
  }
}

// ─── DADOS ─────────────────────────────────────────────────────────
// Fonte: Nintendo Life, Game8, Dexerto, GFinityEsports (Março 2026)
// 9 Pokémon fósseis, 22 partes no total

class _FossilData {
  final String pokemon;
  final List<String> parts;
  const _FossilData({required this.pokemon, required this.parts});
}

const _fossils = [
  _FossilData(
    pokemon: 'Aerodactyl',
    parts: [
      'Wing Fossil (Head)',
      'Wing Fossil (Body)',
      'Wing Fossil (Tail)',
      'Wing Fossil (Left Wing)',
      'Wing Fossil (Right Wing)',
    ],
  ),
  _FossilData(
    pokemon: 'Cranidos',
    parts: ['Skull Fossil'],
  ),
  _FossilData(
    pokemon: 'Rampardos',
    parts: [
      'Headbutt Fossil (Head)',
      'Headbutt Fossil (Body)',
      'Headbutt Fossil (Tail)',
    ],
  ),
  _FossilData(
    pokemon: 'Shieldon',
    parts: ['Armor Fossil'],
  ),
  _FossilData(
    pokemon: 'Bastiodon',
    parts: [
      'Shield Fossil (Left)',
      'Shield Fossil (Right)',
      'Shield Fossil (Top)',
    ],
  ),
  _FossilData(
    pokemon: 'Tyrunt',
    parts: ['Jaw Fossil'],
  ),
  _FossilData(
    pokemon: 'Tyrantrum',
    parts: [
      'Despot Fossil (Head)',
      'Despot Fossil (Body)',
      'Despot Fossil (Tail)',
      'Despot Fossil (Legs)',
    ],
  ),
  _FossilData(
    pokemon: 'Amaura',
    parts: ['Sail Fossil'],
  ),
  _FossilData(
    pokemon: 'Aurorus',
    parts: [
      'Tundra Fossil (Head)',
      'Tundra Fossil (Body)',
      'Tundra Fossil (Tail)',
    ],
  ),
];
