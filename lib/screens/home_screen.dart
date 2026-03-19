import 'package:flutter/material.dart';
import 'package:pokedex_tracker/services/storage_service.dart';
import 'package:pokedex_tracker/screens/pokedex_screen.dart';
import 'package:pokedex_tracker/screens/settings_screen.dart';

// ─── MODELOS ─────────────────────────────────────────────────────

class _DlcInfo {
  final String name;
  final int total;
  final String sectionApiName;
  const _DlcInfo({required this.name, required this.total, required this.sectionApiName});
}

class _PokedexEntry {
  final String name;
  final String year;
  final int totalBase;
  final List<_DlcInfo> dlcs;
  final String iconBg;
  final bool isPokopiaDex;
  // Habitats do Pokopia — tratado no mesmo nível hierárquico das DLCs
  final int? pokopiaHabitatTotal;

  const _PokedexEntry({
    required this.name,
    required this.year,
    required this.totalBase,
    this.dlcs = const [],
    this.iconBg = '#F1EFE8',
    this.isPokopiaDex = false,
    this.pokopiaHabitatTotal,
  });

  bool get hasDlc => dlcs.isNotEmpty || isPokopiaDex;

  String get pokedexId =>
      name.toLowerCase().replaceAll(' ', '_').replaceAll('/', '_').replaceAll("'", '');
}

// ─── ÍCONES POR JOGO ─────────────────────────────────────────────

IconData _iconForEntry(String name) {
  switch (name) {
    case "Let's Go Pikachu / Eevee":            return Icons.directions_walk;
    case 'Sword / Shield':                       return Icons.shield_outlined;
    case 'Brilliant Diamond / Shining Pearl':    return Icons.diamond_outlined;
    case 'Legends: Arceus':                      return Icons.auto_awesome;
    case 'Scarlet / Violet':                     return Icons.local_florist_outlined;
    case 'Legends: Z-A':                         return Icons.bolt;
    case 'FireRed / LeafGreen':                  return Icons.local_fire_department_outlined;
    case 'Pokopia':                              return Icons.nature_people_outlined;
    default:                                     return Icons.catching_pokemon;
  }
}

// ─── TABS DO BOTTOM NAV ───────────────────────────────────────────

enum _NavTab { home, nacional, times, go, pokopia }

// ─── HOME SCREEN ─────────────────────────────────────────────────

class HomeScreen extends StatefulWidget {
  const HomeScreen({super.key});

  @override
  State<HomeScreen> createState() => _HomeScreenState();
}

class _HomeScreenState extends State<HomeScreen> {
  final StorageService _storage = StorageService();
  final Map<String, int> _caughtCounts = {};
  Set<String>? _activePokedexIds;

  _NavTab _currentTab = _NavTab.home;

  // ── Catálogo de Pokedex ────────────────────────────────────────

  static const List<_PokedexEntry> _gameEntries = [
    _PokedexEntry(name: "Let's Go Pikachu / Eevee", year: '2018', totalBase: 153, iconBg: '#EAF3DE'),
    _PokedexEntry(
      name: 'Sword / Shield', year: '2019', totalBase: 400, iconBg: '#E6F1FB',
      dlcs: [
        _DlcInfo(name: 'Isle of Armor',  total: 210, sectionApiName: 'isle-of-armor'),
        _DlcInfo(name: 'Crown Tundra',   total: 210, sectionApiName: 'crown-tundra'),
      ],
    ),
    _PokedexEntry(name: 'Brilliant Diamond / Shining Pearl', year: '2021', totalBase: 493, iconBg: '#FBEAF0'),
    _PokedexEntry(name: 'Legends: Arceus', year: '2022', totalBase: 242, iconBg: '#EEEDFE'),
    _PokedexEntry(
      name: 'Scarlet / Violet', year: '2022', totalBase: 400, iconBg: '#FAECE7',
      dlcs: [
        _DlcInfo(name: 'Teal Mask',    total: 200, sectionApiName: 'kitakami'),
        _DlcInfo(name: 'Indigo Disk',  total: 243, sectionApiName: 'blueberry'),
      ],
    ),
    _PokedexEntry(
      name: 'Legends: Z-A', year: '2025', totalBase: 132, iconBg: '#F1EFE8',
      dlcs: [_DlcInfo(name: 'Mega Dimension', total: 132, sectionApiName: 'mega-dimension')],
    ),
    _PokedexEntry(name: 'FireRed / LeafGreen', year: '2026', totalBase: 386, iconBg: '#EAF3DE'),
    _PokedexEntry(
      name: 'Pokopia', year: '2026', totalBase: 311, iconBg: '#E1F5EE',
      isPokopiaDex: true,
      pokopiaHabitatTotal: 200,
    ),
  ];

  static const _PokedexEntry _nacEntry =
      _PokedexEntry(name: 'Nacional', year: '', totalBase: 1025);

  static const _PokedexEntry _goEntry =
      _PokedexEntry(name: 'Pokémon GO', year: '2016', totalBase: 941, iconBg: '#FCEBEB');

  static _PokedexEntry get _pokopiaEntry =>
      _gameEntries.firstWhere((e) => e.isPokopiaDex);

  // ── Lifecycle ─────────────────────────────────────────────────

  @override
  void initState() {
    super.initState();
    _loadCounts();
  }

  Future<void> _loadCounts() async {
    final active = await _storage.getActivePokedexIds();
    if (!mounted) return;
    setState(() => _activePokedexIds = active);

    final all = [..._gameEntries, _goEntry, _nacEntry];
    for (final e in all) {
      final c = await _storage.getCaughtCount(e.pokedexId);
      if (!mounted) return;
      setState(() => _caughtCounts[e.pokedexId] = c);
    }
  }

  bool _isActive(_PokedexEntry entry) {
    if (_activePokedexIds == null) return true;
    return _activePokedexIds!.contains(entry.pokedexId);
  }

  bool get _goActive => _isActive(_goEntry);
  bool get _pokopiaActive => _gameEntries.any((e) => e.isPokopiaDex && _isActive(e));

  // ── Navegação ─────────────────────────────────────────────────

  void _openPokedex(_PokedexEntry entry, {String? sectionFilter}) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (_) => PokedexScreen(
          pokedexId: entry.pokedexId,
          pokedexName: entry.name,
          totalPokemon: entry.totalBase,
          initialSectionFilter: sectionFilter,
        ),
      ),
    );
    _loadCounts();
  }

  void _onNavTap(_NavTab tab) {
    if (tab == _NavTab.nacional) {
      _openPokedex(_nacEntry);
      return;
    }
    if (tab == _NavTab.go) {
      _openPokedex(_goEntry);
      return;
    }
    if (tab == _NavTab.pokopia) {
      _openPokedex(_pokopiaEntry);
      return;
    }
    if (tab == _NavTab.times) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Times — em breve')),
      );
      return;
    }
    setState(() => _currentTab = tab);
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pokedex'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () async {
              await Navigator.push(
                context,
                MaterialPageRoute(builder: (_) => const SettingsScreen()),
              );
              _loadCounts();
            },
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _loadCounts,
        child: _buildBody(),
      ),
      bottomNavigationBar: _buildBottomNav(),
    );
  }

  // ── Body ──────────────────────────────────────────────────────

  Widget _buildBody() {
    final nacId = _nacEntry.pokedexId;
    final nacCaught = _caughtCounts[nacId] ?? 0;
    final activeEntries = _gameEntries.where(_isActive).toList();

    return SingleChildScrollView(
      physics: const AlwaysScrollableScrollPhysics(),
      padding: const EdgeInsets.fromLTRB(14, 14, 14, 14),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.stretch,
        children: [
          // Nacional — largura total, sempre visível
          _NacionalCard(
            caught: nacCaught,
            onTap: () => _openPokedex(_nacEntry),
          ),

          // Pokemon GO — logo abaixo do Nacional, some quando desabilitado
          if (_goActive) ...[
            const SizedBox(height: 10),
            _GoCard(
              entry: _goEntry,
              caught: _caughtCounts[_goEntry.pokedexId] ?? 0,
              onTap: () => _openPokedex(_goEntry),
            ),
          ],

          const SizedBox(height: 14),

          // Grid 2×N dos jogos ativos
          if (activeEntries.isEmpty)
            Padding(
              padding: const EdgeInsets.symmetric(vertical: 32),
              child: Center(
                child: Text(
                  'Nenhuma Pokedex ativa.\nAcesse Configurações para ativar.',
                  textAlign: TextAlign.center,
                  style: TextStyle(
                    fontSize: 13,
                    color: Theme.of(context).colorScheme.onSurfaceVariant,
                  ),
                ),
              ),
            )
          else
            GridView.builder(
              shrinkWrap: true,
              physics: const NeverScrollableScrollPhysics(),
              gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                crossAxisCount: 2,
                crossAxisSpacing: 10,
                mainAxisSpacing: 10,
                childAspectRatio: 1.0,
              ),
              itemCount: activeEntries.length,
              itemBuilder: (ctx, i) {
                final e = activeEntries[i];
                return _PokedexCard(
                  entry: e,
                  caught: _caughtCounts[e.pokedexId] ?? 0,
                  onTap: () => _openPokedex(e),
                  onTapDlc: (api) => _openPokedex(e, sectionFilter: api),
                );
              },
            ),

          const SizedBox(height: 8),
        ],
      ),
    );
  }

  // ── Bottom Navigation ─────────────────────────────────────────

  Widget _buildBottomNav() {
    final items = <_NavItem>[
      const _NavItem(tab: _NavTab.home,     icon: Icons.home_outlined,      label: 'Inicio'),
      const _NavItem(tab: _NavTab.nacional,  icon: Icons.menu_book_outlined, label: 'Nacional'),
      const _NavItem(tab: _NavTab.times,    icon: Icons.groups_2_outlined,   label: 'Times'),
      if (_goActive)
        const _NavItem(tab: _NavTab.go,     icon: Icons.public_outlined,     label: 'GO'),
      if (_pokopiaActive)
        const _NavItem(tab: _NavTab.pokopia, icon: Icons.nature_people_outlined, label: 'Pokopia'),
    ];

    return SafeArea(
      child: Container(
        height: 62,
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          border: Border(
            top: BorderSide(
              color: Theme.of(context).colorScheme.outlineVariant,
              width: 0.5,
            ),
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: items.map((item) {
            final isActive = _currentTab == item.tab;
            final color = isActive
                ? Theme.of(context).colorScheme.primary
                : Theme.of(context).colorScheme.onSurfaceVariant;
            return Expanded(
              child: InkWell(
                onTap: () => _onNavTap(item.tab),
                child: Column(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(item.icon, size: 22, color: color),
                    const SizedBox(height: 2),
                    Text(
                      item.label,
                      style: TextStyle(
                        fontSize: 10,
                        fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                        color: color,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }).toList(),
        ),
      ),
    );
  }
}

class _NavItem {
  final _NavTab tab;
  final IconData icon;
  final String label;
  const _NavItem({required this.tab, required this.icon, required this.label});
}

// ─── CARD NACIONAL ────────────────────────────────────────────────
// Sem ícone específico — igual à Nacional, usa ícone de livro/pokedex na barra

class _NacionalCard extends StatelessWidget {
  final int caught;
  final VoidCallback onTap;
  const _NacionalCard({required this.caught, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    // Usa o primaryContainer suavizado — integra com a paleta do tema sem o cinza frio
    final bg = Color.lerp(scheme.primaryContainer, scheme.surface, 0.55)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: scheme.outlineVariant,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  'Nacional',
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$caught / 1025',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ─── CARD POKEMON GO ─────────────────────────────────────────────
// Sem ícone específico dentro do card — mesma estrutura da Nacional

class _GoCard extends StatelessWidget {
  final _PokedexEntry entry;
  final int caught;
  final VoidCallback onTap;
  const _GoCard({required this.entry, required this.caught, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final complete = caught >= entry.totalBase;
    // Mesma cor da Nacional — primaryContainer suavizado
    final bg = Color.lerp(scheme.primaryContainer, scheme.surface, 0.55)!;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        decoration: BoxDecoration(
          color: bg,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: complete
                ? const Color(0xFF34C759).withOpacity(0.5)
                : scheme.outlineVariant,
            width: 0.5,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  entry.name,
                  style: Theme.of(context).textTheme.titleSmall?.copyWith(
                    fontWeight: FontWeight.w600,
                  ),
                ),
                const SizedBox(height: 2),
                Text(
                  '$caught / ${entry.totalBase}',
                  style: Theme.of(context).textTheme.bodySmall?.copyWith(
                    color: complete ? const Color(0xFF34C759) : scheme.onSurfaceVariant,
                  ),
                ),
              ],
            ),
            Icon(Icons.chevron_right, color: scheme.onSurfaceVariant),
          ],
        ),
      ),
    );
  }
}

// ─── CARD DE POKEDEX DO GRID ──────────────────────────────────────

class _PokedexCard extends StatelessWidget {
  final _PokedexEntry entry;
  final int caught;
  final VoidCallback onTap;
  final void Function(String) onTapDlc;

  const _PokedexCard({
    required this.entry,
    required this.caught,
    required this.onTap,
    required this.onTapDlc,
  });

  Color _hexColor(String hex) {
    try { return Color(int.parse(hex.replaceAll('#', '0xFF'))); }
    catch (_) { return const Color(0xFFF1EFE8); }
  }

  @override
  Widget build(BuildContext context) {
    final complete = caught >= entry.totalBase;
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Theme.of(context).colorScheme.surface,
          borderRadius: BorderRadius.circular(14),
          border: Border.all(
            color: complete
                ? const Color(0xFF34C759).withOpacity(0.4)
                : Theme.of(context).colorScheme.outlineVariant,
            width: 0.5,
          ),
        ),
        child: entry.hasDlc
            ? _buildWithDlc(context, complete)
            : _buildNoDlc(context, complete),
      ),
    );
  }

  // ── Sem DLC: ícone no topo + nome e contador centralizados na metade inferior

  Widget _buildNoDlc(BuildContext context, bool complete) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        // Ícone alinhado ao topo
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: 44, height: 44,
            decoration: BoxDecoration(
              color: _hexColor(entry.iconBg),
              borderRadius: BorderRadius.circular(12),
            ),
            child: Icon(_iconForEntry(entry.name), size: 24),
          ),
        ),
        // Nome e contador centralizados, expandem o espaço restante
        Expanded(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                entry.name,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontWeight: FontWeight.w600,
                  fontSize: 11,
                  height: 1.3,
                ),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                textAlign: TextAlign.center,
              ),
              const SizedBox(height: 2),
              Text(
                '$caught / ${entry.totalBase}',
                style: Theme.of(context).textTheme.bodySmall?.copyWith(
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                  color: complete
                      ? const Color(0xFF34C759)
                      : Theme.of(context).colorScheme.onSurfaceVariant,
                ),
                textAlign: TextAlign.center,
              ),
            ],
          ),
        ),
      ],
    );
  }

  // ── Com DLC / Pokopia: ícone no topo + nome + contador + linhas de DLC/Habitats

  Widget _buildWithDlc(BuildContext context, bool complete) {
    final scheme = Theme.of(context).colorScheme;

    // Linhas de DLC normais
    final dlcRows = entry.dlcs.map((dlc) => _DlcRow(
      name: dlc.name,
      total: dlc.total,
      onTap: () => onTapDlc(dlc.sectionApiName),
      scheme: scheme,
    )).toList();

    // Linha de Habitats do Pokopia — mesmo nível hierárquico das DLCs
    final habitatRow = entry.isPokopiaDex && entry.pokopiaHabitatTotal != null
        ? _DlcRow(
            name: 'Habitats',
            total: entry.pokopiaHabitatTotal!,
            onTap: () => onTapDlc('pokopia-habitats'),
            scheme: scheme,
          )
        : null;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.center,
      mainAxisSize: MainAxisSize.min,
      children: [
        // Ícone alinhado ao topo, centralizado
        Align(
          alignment: Alignment.topCenter,
          child: Container(
            width: 40, height: 40,
            decoration: BoxDecoration(
              color: _hexColor(entry.iconBg),
              borderRadius: BorderRadius.circular(11),
            ),
            child: Icon(_iconForEntry(entry.name), size: 22),
          ),
        ),
        const SizedBox(height: 6),
        // Nome
        Text(
          entry.name,
          style: Theme.of(context).textTheme.labelSmall?.copyWith(
            fontWeight: FontWeight.w600,
            fontSize: 11,
            height: 1.3,
          ),
          maxLines: 2,
          overflow: TextOverflow.ellipsis,
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 2),
        // Contador principal (Amigos X / Y para Pokopia)
        Text(
          entry.isPokopiaDex
              ? 'Amigos $caught / ${entry.totalBase}'
              : '$caught / ${entry.totalBase}',
          style: Theme.of(context).textTheme.bodySmall?.copyWith(
            fontSize: 11,
            fontWeight: FontWeight.w500,
            color: complete
                ? const Color(0xFF34C759)
                : scheme.onSurfaceVariant,
          ),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 6),
        // Separador + linhas de DLC e Habitats (mesmo nível)
        Container(
          width: double.infinity,
          padding: const EdgeInsets.only(top: 6),
          decoration: BoxDecoration(
            border: Border(
              top: BorderSide(color: scheme.outlineVariant, width: 0.5),
            ),
          ),
          child: Column(
            children: [
              ...dlcRows,
              if (habitatRow != null) habitatRow,
            ],
          ),
        ),
      ],
    );
  }
}

// ─── LINHA DE DLC / HABITAT ───────────────────────────────────────

class _DlcRow extends StatelessWidget {
  final String name;
  final int total;
  final VoidCallback onTap;
  final ColorScheme scheme;

  const _DlcRow({
    required this.name,
    required this.total,
    required this.onTap,
    required this.scheme,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 3),
      child: GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            Expanded(
              child: Text(
                name,
                style: Theme.of(context).textTheme.labelSmall?.copyWith(
                  fontSize: 9.5,
                  color: scheme.onSurfaceVariant,
                ),
                overflow: TextOverflow.ellipsis,
              ),
            ),
            Text(
              '— / $total',
              style: Theme.of(context).textTheme.labelSmall?.copyWith(
                fontSize: 9.5,
                fontWeight: FontWeight.w500,
                color: scheme.onSurfaceVariant,
              ),
            ),
          ],
        ),
      ),
    );
  }
}