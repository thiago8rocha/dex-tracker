import 'package:flutter/material.dart';

class PokopiaRelicsScreen extends StatefulWidget {
  const PokopiaRelicsScreen({super.key});

  @override
  State<PokopiaRelicsScreen> createState() => _PokopiaRelicsScreenState();
}

class _PokopiaRelicsScreenState extends State<PokopiaRelicsScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tab;
  String _search = '';

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _tab.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tab.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Relíquias'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(children: [
        TabBar(
          controller: _tab,
          tabs: const [
            Tab(text: 'Grandes'),
            Tab(text: 'Pequenas'),
          ],
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant,
          indicatorColor: scheme.primary,
        ),
        // Info geral
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Container(
            padding: const EdgeInsets.all(10),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.outlineVariant, width: 0.5),
            ),
            child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Icon(Icons.info_outline, size: 14, color: scheme.onSurfaceVariant),
              const SizedBox(width: 8),
              Expanded(child: Text(
                'Relíquias são encontradas em pontos brilhantes no chão de qualquer bioma. '
                'Quebre com Rock Smash e leve ao Professor Tangrowth para avaliar. '
                'As localizações são aleatórias — você pode encontrar duplicatas.',
                style: TextStyle(fontSize: 11,
                    color: scheme.onSurfaceVariant, height: 1.4))),
            ]),
          ),
        ),

        // Busca
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 10, 16, 8),
          child: TextField(
            onChanged: (v) => setState(() => _search = v),
            decoration: InputDecoration(
              hintText: 'Buscar...',
              prefixIcon: const Icon(Icons.search, size: 20),
              border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.outlineVariant),
              ),
              enabledBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide(color: scheme.outlineVariant),
              ),
              contentPadding: const EdgeInsets.symmetric(
                  horizontal: 12, vertical: 10),
              isDense: true,
            ),
          ),
        ),

        // Conteúdo
        Expanded(
          child: TabBarView(
            controller: _tab,
            children: [
              _RelicList(
                items: _largeRelics
                    .where((r) => r.toLowerCase().contains(_search.toLowerCase()))
                    .toList(),
                icon: Icons.chair_outlined,
                emptyMessage: 'Nenhuma relíquia grande encontrada.',
                isSmall: false,
              ),
              _RelicList(
                items: _smallRelics
                    .where((r) => r.toLowerCase().contains(_search.toLowerCase()))
                    .toList(),
                icon: Icons.diamond_outlined,
                emptyMessage: 'Nenhuma relíquia pequena encontrada.',
                isSmall: true,
              ),
            ],
          ),
        ),
      ]),
    );
  }
}

// ─── LISTAS ───────────────────────────────────────────────────────

class _RelicList extends StatelessWidget {
  final List<String> items;
  final IconData icon;
  final String emptyMessage;
  final bool isSmall;
  const _RelicList({
    required this.items,
    required this.icon,
    required this.emptyMessage,
    required this.isSmall,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return Center(
        child: Text(emptyMessage,
          style: TextStyle(color: scheme.onSurfaceVariant)));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => Container(
        padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant, width: 1),
        ),
        child: Row(children: [
          Icon(icon, size: 18, color: scheme.onSurfaceVariant),
          const SizedBox(width: 12),
          Expanded(child: Text(items[i],
            style: const TextStyle(fontSize: 13))),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
            decoration: BoxDecoration(
              color: scheme.surfaceContainer,
              borderRadius: BorderRadius.circular(6),
            ),
            child: Text(isSmall ? 'Small' : 'Large',
              style: TextStyle(fontSize: 9, color: scheme.onSurfaceVariant)),
          ),
        ]),
      ),
    );
  }
}

class _FossilList extends StatelessWidget {
  final List<_FossilData> items;
  const _FossilList({required this.items});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (items.isEmpty) {
      return Center(
        child: Text('Nenhum fóssil encontrado.',
          style: TextStyle(color: scheme.onSurfaceVariant)));
    }

    return ListView.separated(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
      itemCount: items.length,
      separatorBuilder: (_, __) => const SizedBox(height: 8),
      itemBuilder: (ctx, i) => _FossilTile(data: items[i]),
    );
  }
}

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
      child: Row(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Icon(Icons.pest_control_outlined,
            size: 20, color: scheme.onSurfaceVariant),
        const SizedBox(width: 12),
        Expanded(child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(data.name,
              style: Theme.of(context).textTheme.titleSmall?.copyWith(
                fontWeight: FontWeight.w600)),
            const SizedBox(height: 2),
            Text('Pokémon: ${data.pokemon}',
              style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
            if (data.description != null) ...[
              const SizedBox(height: 5),
              Text(data.description!,
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  color: scheme.onSurfaceVariant, height: 1.4)),
            ],
          ],
        )),
      ]),
    );
  }
}

// ─── DADOS ────────────────────────────────────────────────────────

// ─── DADOS ────────────────────────────────────────────────────────
// Fonte: RankedBoost, Nintendo Life, Game8 (Março 2026)

// 19 relíquias grandes — mobiliário decorativo
const _largeRelics = [
  'Bike',
  'Boo-in-the-Box',
  'Bouncy Blue Bathtub',
  'Charizard Rug',
  'Fiery Magby Statue',
  'Funky Diffuser',
  'Gold Teeth',
  'Gym Emblem Statue',
  'Meteor Lamp',
  'Mysterious Statue',
  'Naptime Bed',
  'Photo Cutout Board',
  'Polygonal Shelf',
  'Seedot Lamp',
  'Spaceship',
  'Team Rocket Wall Hanging',
  'Wobbuffet Wobbler',
];

// 36 relíquias pequenas — itens dos jogos principais da série
const _smallRelics = [
  'Ability Shield',
  'Big Root',
  'Black Belt',
  'Charcoal',
  'Clear Amulet',
  'Destiny Knot',
  'Fairy Feather',
  'Gold Bottle Cap',
  'Hard Stone',
  'Heart Scale',
  'Indigo Meteor Lamp',
  'Iron Ball',
  'Leftovers',
  'Life Orb',
  'Light Clay',
  'Lucky Egg',
  'Metal Coat',
  'Metal Powder',
  'Miracle Seed',
  'Model Space Shuttle',
  'Nugget',
  'Poison Barb',
  'Quick Claw',
  'Red Meteor Lamp',
  'Ring Target',
  'Room Service',
  'Sharp Beak',
  'Silk Scarf',
  'Silver Powder',
  'Soft Sand',
  'Spacesuit',
  'Spell Tag',
  'Sticky Barb',
  'Terrain Extender',
  'Twisted Spoon',
  'Weakness Policy',
];