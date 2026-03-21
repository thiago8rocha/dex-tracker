import 'package:flutter/material.dart';
import 'package:pokedex_tracker/data/pokopia_habitat_data.dart';
import 'package:pokedex_tracker/screens/pokopia/pokopia_habitat_detail_screen.dart';

class PokopiaHabitatsScreen extends StatefulWidget {
  const PokopiaHabitatsScreen({super.key});

  @override
  State<PokopiaHabitatsScreen> createState() =>
      _PokopiaHabitatsScreenState();
}

class _PokopiaHabitatsScreenState extends State<PokopiaHabitatsScreen>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(() => setState(() {}));
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Habitats'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [
            Tab(text: 'Standard'),
            Tab(text: 'Evento'),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: const [
          _StandardHabitatsTab(),
          _EventHabitatsTab(),
        ],
      ),
    );
  }
}

// --- TAB STANDARD -------------------------------------------------------------

class _StandardHabitatsTab extends StatefulWidget {
  const _StandardHabitatsTab();

  @override
  State<_StandardHabitatsTab> createState() => _StandardHabitatsTabState();
}

class _StandardHabitatsTabState extends State<_StandardHabitatsTab>
    with AutomaticKeepAliveClientMixin {
  String _search = '';
  String? _selectedBiome;

  @override
  bool get wantKeepAlive => true;

  // Todos os biomas presentes nos dados
  List<String> get _biomes {
    final all = <String>{};
    for (final h in pokopiaHabitats) {
      all.addAll(h.biomes);
    }
    final sorted = all.toList()..sort();
    return ['Todos', ...sorted];
  }

  List<PokopiaHabitat> get _filtered {
    return pokopiaHabitats.where((h) {
      final q = _search.toLowerCase();
      final matchSearch = _search.isEmpty ||
          h.name.toLowerCase().contains(q) ||
          h.items.any((i) => i.toLowerCase().contains(q)) ||
          h.pokemon.any((p) => p.name.toLowerCase().contains(q));
      final matchBiome = _selectedBiome == null ||
          _selectedBiome == 'Todos' ||
          h.biomes.contains(_selectedBiome);
      return matchSearch && matchBiome;
    }).toList()
      ..sort((a, b) => a.id.compareTo(b.id));
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(children: [
      // Info
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
            Expanded(
              child: Text(
                'Habitats sao criados posicionando objetos e mobiliario '
                'proximos entre si. Pokemon diferentes aparecem dependendo '
                'do horario e clima.',
                style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                    height: 1.4),
              ),
            ),
          ]),
        ),
      ),

      // Busca
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: InputDecoration(
            hintText: 'Buscar habitat, item ou Pokemon...',
            prefixIcon: const Icon(Icons.search, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      ),

      // Filtro por bioma
      SizedBox(
        height: 44,
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          scrollDirection: Axis.horizontal,
          itemCount: _biomes.length,
          separatorBuilder: (_, __) => const SizedBox(width: 8),
          itemBuilder: (ctx, i) {
            final biome = _biomes[i];
            final selected = (_selectedBiome ?? 'Todos') == biome;
            return GestureDetector(
              onTap: () => setState(
                  () => _selectedBiome = biome == 'Todos' ? null : biome),
              child: Container(
                padding: const EdgeInsets.symmetric(
                    horizontal: 12, vertical: 4),
                decoration: BoxDecoration(
                  color: selected
                      ? scheme.primary
                      : scheme.surfaceContainer,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(
                    color: selected
                        ? scheme.primary
                        : scheme.outlineVariant,
                  ),
                ),
                child: Text(
                  biome,
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.w500,
                    color: selected
                        ? scheme.onPrimary
                        : scheme.onSurfaceVariant,
                  ),
                ),
              ),
            );
          },
        ),
      ),

      // Lista
      Expanded(
        child: _filtered.isEmpty
            ? Center(
                child: Text('Nenhum habitat encontrado.',
                    style: TextStyle(color: scheme.onSurfaceVariant)))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 16),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) => _StandardHabitatTile(
                  habitat: _filtered[i],
                ),
              ),
      ),
    ]);
  }
}

// --- TILE STANDARD ------------------------------------------------------------

class _StandardHabitatTile extends StatefulWidget {
  final PokopiaHabitat habitat;
  const _StandardHabitatTile({required this.habitat});

  @override
  State<_StandardHabitatTile> createState() => _StandardHabitatTileState();
}

class _StandardHabitatTileState extends State<_StandardHabitatTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final h = widget.habitat;
    final colorVal =
        biomeColor[h.biomes.isNotEmpty ? h.biomes.first : ''] ?? 0xFF607D8B;
    final color = Color(colorVal);

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PokopiaHabitatDetailScreen(habitat: h),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant, width: 1),
        ),
        child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          // Preview da imagem
          ClipRRect(
            borderRadius:
                const BorderRadius.vertical(top: Radius.circular(12)),
            child: SizedBox(
              height: 80,
              width: double.infinity,
              child: Image.asset(
                h.imageAsset,
                fit: BoxFit.cover,
                errorBuilder: (_, __, ___) => Container(
                  color: color.withOpacity(0.08),
                  child: Center(
                    child: Icon(Icons.landscape_outlined,
                        size: 28, color: color.withOpacity(0.3)),
                  ),
                ),
              ),
            ),
          ),

          // Info
          Padding(
            padding: const EdgeInsets.fromLTRB(12, 10, 12, 10),
            child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(children: [
                    Text(
                      '#${h.id.toString().padLeft(3, '0')}',
                      style: TextStyle(
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                          color: scheme.onSurfaceVariant),
                    ),
                    const SizedBox(width: 8),
                    Expanded(
                      child: Text(
                        h.name,
                        style: Theme.of(context)
                            .textTheme
                            .titleSmall
                            ?.copyWith(fontWeight: FontWeight.w600),
                      ),
                    ),
                    GestureDetector(
                      onTap: () => setState(() => _expanded = !_expanded),
                      child: Icon(
                        _expanded
                            ? Icons.expand_less
                            : Icons.expand_more,
                        size: 18,
                        color: scheme.onSurfaceVariant,
                      ),
                    ),
                  ]),
                  const SizedBox(height: 6),

                  // Biomas
                  Wrap(
                    spacing: 4,
                    runSpacing: 4,
                    children: h.biomes
                        .map((b) => Container(
                              padding: const EdgeInsets.symmetric(
                                  horizontal: 6, vertical: 2),
                              decoration: BoxDecoration(
                                color: color.withOpacity(0.12),
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(b,
                                  style: TextStyle(
                                      fontSize: 9,
                                      fontWeight: FontWeight.w600,
                                      color: color)),
                            ))
                        .toList(),
                  ),

                  if (_expanded) ...[
                    const SizedBox(height: 8),

                    // Itens
                    if (h.items.isNotEmpty) ...[
                      Text('Itens necessarios',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: h.items
                            .map((item) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceContainer,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                    border: Border.all(
                                        color: scheme.outlineVariant,
                                        width: 0.5),
                                  ),
                                  child: Text(item,
                                      style: TextStyle(
                                          fontSize: 10,
                                          color: scheme.onSurface)),
                                ))
                            .toList(),
                      ),
                      const SizedBox(height: 8),
                    ],

                    // Pokemon
                    if (h.pokemon.isNotEmpty) ...[
                      Text('Pokemon possiveis',
                          style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant)),
                      const SizedBox(height: 4),
                      Wrap(
                        spacing: 5,
                        runSpacing: 4,
                        children: h.pokemon
                            .map((p) => Container(
                                  padding: const EdgeInsets.symmetric(
                                      horizontal: 7, vertical: 3),
                                  decoration: BoxDecoration(
                                    color: scheme.surfaceContainerHigh,
                                    borderRadius:
                                        BorderRadius.circular(8),
                                  ),
                                  child: Text(
                                    '${p.name} - ${p.rarity}',
                                    style: TextStyle(
                                        fontSize: 10,
                                        color: scheme.onSurface),
                                  ),
                                ))
                            .toList(),
                      ),
                    ],
                  ],
                ]),
          ),
        ]),
      ),
    );
  }
}

// --- TAB EVENTO ---------------------------------------------------------------

class _EventHabitatsTab extends StatefulWidget {
  const _EventHabitatsTab();

  @override
  State<_EventHabitatsTab> createState() => _EventHabitatsTabState();
}

class _EventHabitatsTabState extends State<_EventHabitatsTab>
    with AutomaticKeepAliveClientMixin {
  String _search = '';

  @override
  bool get wantKeepAlive => true;

  List<PokopiaEventHabitat> get _filtered {
    if (_search.isEmpty) return pokopiaEventHabitats;
    final q = _search.toLowerCase();
    return pokopiaEventHabitats.where((h) {
      return h.name.toLowerCase().contains(q) ||
          h.eventName.toLowerCase().contains(q) ||
          h.pokemon.any((p) => p.name.toLowerCase().contains(q));
    }).toList();
  }

  @override
  Widget build(BuildContext context) {
    super.build(context);
    final scheme = Theme.of(context).colorScheme;

    return Column(children: [
      // Info
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
            Expanded(
              child: Text(
                'Habitats de evento ficam disponiveis apenas durante eventos '
                'temporarios. Os eventos se repetem anualmente.',
                style: TextStyle(
                    fontSize: 11,
                    color: scheme.onSurfaceVariant,
                    height: 1.4),
              ),
            ),
          ]),
        ),
      ),

      // Busca
      Padding(
        padding: const EdgeInsets.fromLTRB(16, 10, 16, 0),
        child: TextField(
          onChanged: (v) => setState(() => _search = v),
          decoration: InputDecoration(
            hintText: 'Buscar habitat ou Pokemon...',
            prefixIcon: const Icon(Icons.search, size: 20),
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(12),
              borderSide: BorderSide(color: scheme.outlineVariant),
            ),
            contentPadding:
                const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
            isDense: true,
          ),
        ),
      ),

      const SizedBox(height: 8),

      // Lista
      Expanded(
        child: _filtered.isEmpty
            ? Center(
                child: Text('Nenhum habitat encontrado.',
                    style: TextStyle(color: scheme.onSurfaceVariant)))
            : ListView.separated(
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 16),
                itemCount: _filtered.length,
                separatorBuilder: (_, __) => const SizedBox(height: 8),
                itemBuilder: (ctx, i) =>
                    _EventHabitatTile(habitat: _filtered[i]),
              ),
      ),
    ]);
  }
}

// --- TILE EVENTO --------------------------------------------------------------

class _EventHabitatTile extends StatefulWidget {
  final PokopiaEventHabitat habitat;
  const _EventHabitatTile({required this.habitat});

  @override
  State<_EventHabitatTile> createState() => _EventHabitatTileState();
}

class _EventHabitatTileState extends State<_EventHabitatTile> {
  bool _expanded = false;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final h = widget.habitat;

    return GestureDetector(
      onTap: () => setState(() => _expanded = !_expanded),
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(12),
          border: Border.all(color: scheme.outlineVariant, width: 1),
        ),
        child:
            Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
          Row(children: [
            Text(
              '#${h.id.toString().padLeft(3, '0')}',
              style: TextStyle(
                  fontSize: 11,
                  fontWeight: FontWeight.w600,
                  color: scheme.onSurfaceVariant),
            ),
            const SizedBox(width: 10),
            Expanded(
              child: Text(h.name,
                  style: Theme.of(context)
                      .textTheme
                      .titleSmall
                      ?.copyWith(fontWeight: FontWeight.w600)),
            ),
            Icon(
                _expanded ? Icons.expand_less : Icons.expand_more,
                size: 18,
                color: scheme.onSurfaceVariant),
          ]),
          const SizedBox(height: 4),
          Text(h.eventName,
              style:
                  TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
          if (h.items.isNotEmpty) ...[
            const SizedBox(height: 6),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: h.items
                  .map((c) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainer,
                          borderRadius: BorderRadius.circular(8),
                          border: Border.all(
                              color: scheme.outlineVariant, width: 0.5),
                        ),
                        child: Text(c,
                            style: TextStyle(
                                fontSize: 10, color: scheme.onSurface)),
                      ))
                  .toList(),
            ),
          ],
          if (_expanded) ...[
            const SizedBox(height: 8),
            Text('Pokemon possiveis',
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: scheme.onSurfaceVariant)),
            const SizedBox(height: 4),
            Wrap(
              spacing: 5,
              runSpacing: 5,
              children: h.pokemon
                  .map((p) => Container(
                        padding: const EdgeInsets.symmetric(
                            horizontal: 7, vertical: 3),
                        decoration: BoxDecoration(
                          color: scheme.surfaceContainerHigh,
                          borderRadius: BorderRadius.circular(8),
                        ),
                        child: Text(
                          '${p.name} - ${p.rarity}',
                          style: TextStyle(
                              fontSize: 10, color: scheme.onSurface),
                        ),
                      ))
                  .toList(),
            ),
          ],
        ]),
      ),
    );
  }
}