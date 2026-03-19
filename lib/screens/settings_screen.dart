import 'package:flutter/material.dart';
import 'package:pokedex_tracker/services/storage_service.dart';

// ─── MODELO DE POKEDEX DISPONÍVEL ────────────────────────────────

class _PokedexOption {
  final String id;
  final String name;
  final String year;
  final String generation; // para agrupar por geração
  final bool isFixed;      // Nacional não pode ser desativada

  const _PokedexOption({
    required this.id,
    required this.name,
    required this.year,
    required this.generation,
    this.isFixed = false,
  });
}

// ─── TELA PRINCIPAL DE CONFIGURAÇÕES ─────────────────────────────

class SettingsScreen extends StatelessWidget {
  const SettingsScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Configurações'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: ListView(
        children: [
          // ── 6.1 Aparência ──────────────────────────────────────
          _SectionHeader(label: 'APARÊNCIA'),
          _SettingsTile(
            icon: Icons.palette_outlined,
            title: 'Tema',
            subtitle: 'Sistema',
            onTap: () => _showThemePicker(context),
          ),

          // ── 6.2 Idioma e exibição ──────────────────────────────
          _SectionHeader(label: 'IDIOMA E EXIBIÇÃO'),
          _SettingsTile(
            icon: Icons.language_outlined,
            title: 'Idioma',
            subtitle: 'Português (BR)',
            onTap: null, // v2.0
          ),
          _SettingsTile(
            icon: Icons.translate_outlined,
            title: 'Termos bilíngues',
            subtitle: 'Configurar o que aparece em PT / EN',
            onTap: () => _showComingSoon(context),
          ),

          // ── 6.3 Pokedex ────────────────────────────────────────
          _SectionHeader(label: 'POKEDEX'),
          _SettingsTile(
            icon: Icons.catching_pokemon_outlined,
            title: 'Gerenciar Pokedex',
            subtitle: 'Ativar ou desativar Pokedex exibidas',
            onTap: () => Navigator.push(context,
              MaterialPageRoute(builder: (_) => const ManagePokedexScreen())),
          ),

          // ── 6.4 Dados ──────────────────────────────────────────
          _SectionHeader(label: 'DADOS'),
          _SettingsTile(
            icon: Icons.upload_outlined,
            title: 'Exportar backup',
            subtitle: 'Salvar arquivo local com todos os dados',
            onTap: () => _showComingSoon(context),
          ),
          _SettingsTile(
            icon: Icons.download_outlined,
            title: 'Importar backup',
            subtitle: 'Restaurar de um arquivo',
            onTap: () => _showComingSoon(context),
          ),
          _SettingsTile(
            icon: Icons.schedule_outlined,
            title: 'Backup automático',
            subtitle: 'Diário',
            onTap: () => _showComingSoon(context),
          ),
          _SettingsTile(
            icon: Icons.delete_outline,
            title: 'Limpar dados do app',
            subtitle: 'Remove capturas e times salvos',
            titleColor: Theme.of(context).colorScheme.error,
            onTap: () => _confirmClearData(context),
          ),

          const SizedBox(height: 32),
          Center(child: Text('Pokedex Tracker',
            style: TextStyle(fontSize: 11,
              color: Theme.of(context).colorScheme.onSurfaceVariant))),
          const SizedBox(height: 24),
        ],
      ),
    );
  }

  void _showThemePicker(BuildContext context) {
    showModalBottomSheet(
      context: context,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20))),
      builder: (_) => const _ThemePicker(),
    );
  }

  void _showComingSoon(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
      content: Text('Em breve'),
      behavior: SnackBarBehavior.floating,
      duration: Duration(seconds: 2),
    ));
  }

  void _confirmClearData(BuildContext context) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Limpar dados'),
        content: const Text(
          'Esta ação remove todas as capturas e times salvos. Não pode ser desfeita.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          TextButton(
            onPressed: () async {
              Navigator.pop(ctx);
              await StorageService().clearAll();
              if (context.mounted) {
                ScaffoldMessenger.of(context).showSnackBar(const SnackBar(
                  content: Text('Dados removidos'),
                  behavior: SnackBarBehavior.floating,
                ));
              }
            },
            child: Text('Limpar',
              style: TextStyle(color: Theme.of(context).colorScheme.error)),
          ),
        ],
      ),
    );
  }
}

// ─── SELETOR DE TEMA ─────────────────────────────────────────────

class _ThemePicker extends StatelessWidget {
  const _ThemePicker();

  static const _themes = [
    ('Sistema', Icons.brightness_auto_outlined),
    ('Claro', Icons.light_mode_outlined),
    ('Escuro', Icons.dark_mode_outlined),
    ('Pokébola', Icons.catching_pokemon),
    ('Floresta', Icons.forest_outlined),
    ('Psíquico', Icons.psychology_outlined),
    ('Fogo', Icons.local_fire_department_outlined),
    ('Oceano', Icons.water_outlined),
  ];

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        Container(width: 36, height: 4,
          margin: const EdgeInsets.only(bottom: 16),
          decoration: BoxDecoration(
            color: Theme.of(context).colorScheme.outlineVariant,
            borderRadius: BorderRadius.circular(2))),
        const Align(
          alignment: Alignment.centerLeft,
          child: Text('Tema', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w600)),
        ),
        const SizedBox(height: 12),
        GridView.count(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          crossAxisCount: 4,
          mainAxisSpacing: 10,
          crossAxisSpacing: 10,
          childAspectRatio: 0.9,
          children: _themes.map((t) {
            final isActive = t.$1 == 'Sistema'; // TODO: ler do storage
            return GestureDetector(
              onTap: () => Navigator.pop(context),
              child: Container(
                decoration: BoxDecoration(
                  color: isActive
                      ? Theme.of(context).colorScheme.primaryContainer
                      : Theme.of(context).colorScheme.surfaceContainerHighest,
                  borderRadius: BorderRadius.circular(12),
                  border: isActive ? Border.all(
                    color: Theme.of(context).colorScheme.primary, width: 2) : null,
                ),
                child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [
                  Icon(t.$2, size: 22,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant),
                  const SizedBox(height: 4),
                  Text(t.$1, style: TextStyle(fontSize: 10,
                    fontWeight: isActive ? FontWeight.w600 : FontWeight.w400,
                    color: isActive
                        ? Theme.of(context).colorScheme.primary
                        : Theme.of(context).colorScheme.onSurfaceVariant),
                    textAlign: TextAlign.center),
                ]),
              ),
            );
          }).toList(),
        ),
      ]),
    );
  }
}

// ─── GERENCIAR POKEDEX ───────────────────────────────────────────

class ManagePokedexScreen extends StatefulWidget {
  const ManagePokedexScreen({super.key});

  @override
  State<ManagePokedexScreen> createState() => _ManagePokedexScreenState();
}

class _ManagePokedexScreenState extends State<ManagePokedexScreen> {
  final _storage = StorageService();
  final _searchController = TextEditingController();

  // Todas as Pokedex disponíveis, agrupadas por geração
  static const _allPokedex = [
    _PokedexOption(id: 'lets_go_pikachu___eevee',           name: "Let's Go Pikachu / Eevee",      year: '2018', generation: 'Geração I'),
    _PokedexOption(id: 'firered___leafgreen',               name: 'FireRed / LeafGreen',            year: '2026', generation: 'Geração I'),
    _PokedexOption(id: 'sword___shield',                    name: 'Sword / Shield',                 year: '2019', generation: 'Geração VIII'),
    _PokedexOption(id: 'brilliant_diamond___shining_pearl', name: 'Brilliant Diamond / Shining Pearl', year: '2021', generation: 'Geração IV'),
    _PokedexOption(id: 'legends:_arceus',                   name: 'Legends: Arceus',                year: '2022', generation: 'Geração IV'),
    _PokedexOption(id: 'scarlet___violet',                  name: 'Scarlet / Violet',               year: '2022', generation: 'Geração IX'),
    _PokedexOption(id: 'legends:_z-a',                      name: 'Legends: Z-A',                   year: '2025', generation: 'Especial'),
    _PokedexOption(id: 'pokémon_go',                        name: 'Pokémon GO',                     year: '2016', generation: 'Mobile'),
    _PokedexOption(id: 'pokopia',                           name: 'Pokopia',                        year: '2026', generation: 'Mobile'),
    _PokedexOption(id: 'nacional', name: 'Nacional', year: '', generation: 'Fixa', isFixed: true),
  ];

  Set<String> _activeIds = {};
  bool _loading = true;
  String _filter = 'todas'; // 'todas', 'ativas', 'inativas'
  String _search = '';

  @override
  void initState() {
    super.initState();
    _load();
    _searchController.addListener(() {
      setState(() => _search = _searchController.text.toLowerCase());
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  Future<void> _load() async {
    final active = await _storage.getActivePokedexIds();
    if (mounted) {
      setState(() {
        // null = todas ativas por padrão
        _activeIds = active ?? _allPokedex.map((p) => p.id).toSet();
        _loading = false;
      });
    }
  }

  Future<void> _toggle(String id) async {
    final newSet = Set<String>.from(_activeIds);
    if (newSet.contains(id)) {
      newSet.remove(id);
    } else {
      newSet.add(id);
    }
    setState(() => _activeIds = newSet);
    await _storage.setActivePokedexIds(newSet);
  }

  Future<void> _setAll(List<_PokedexOption> options, bool active) async {
    final newSet = Set<String>.from(_activeIds);
    for (final p in options) {
      if (p.isFixed) continue;
      if (active) newSet.add(p.id); else newSet.remove(p.id);
    }
    setState(() => _activeIds = newSet);
    await _storage.setActivePokedexIds(newSet);
  }

  List<_PokedexOption> get _filtered {
    return _allPokedex.where((p) {
      final matchSearch = _search.isEmpty || p.name.toLowerCase().contains(_search);
      final matchFilter = _filter == 'todas'
          || (_filter == 'ativas' && (_activeIds.contains(p.id) || p.isFixed))
          || (_filter == 'inativas' && !_activeIds.contains(p.id) && !p.isFixed);
      return matchSearch && matchFilter;
    }).toList();
  }

  Map<String, List<_PokedexOption>> get _grouped {
    final map = <String, List<_PokedexOption>>{};
    for (final p in _filtered) {
      map.putIfAbsent(p.generation, () => []).add(p);
    }
    return map;
  }

  @override
  Widget build(BuildContext context) {
    final bg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
    final border = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0);

    return Scaffold(
      appBar: AppBar(
        title: const Text('Gerenciar Pokedex'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const Center(child: CircularProgressIndicator(strokeWidth: 2))
          : Column(children: [
              // Busca
              Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: TextField(
                  controller: _searchController,
                  decoration: InputDecoration(
                    hintText: 'Buscar Pokedex...',
                    prefixIcon: const Icon(Icons.search, size: 20),
                    filled: true,
                    fillColor: bg,
                    border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: border, width: 0.5),
                    ),
                    enabledBorder: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(10),
                      borderSide: BorderSide(color: border, width: 0.5),
                    ),
                    contentPadding: const EdgeInsets.symmetric(vertical: 10),
                  ),
                ),
              ),
              // Pills de filtro
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.fromLTRB(16, 0, 16, 8),
                child: Row(children: [
                  for (final f in [('todas', 'Todas'), ('ativas', 'Ativas'), ('inativas', 'Inativas')])
                    Padding(
                      padding: const EdgeInsets.only(right: 8),
                      child: GestureDetector(
                        onTap: () => setState(() => _filter = f.$1),
                        child: Container(
                          padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: _filter == f.$1
                                ? Theme.of(context).colorScheme.onSurface
                                : bg,
                            borderRadius: BorderRadius.circular(20),
                            border: Border.all(color: border, width: 0.5),
                          ),
                          child: Text(f.$2, style: TextStyle(
                            fontSize: 12, fontWeight: FontWeight.w500,
                            color: _filter == f.$1
                                ? Theme.of(context).colorScheme.surface
                                : Theme.of(context).colorScheme.onSurfaceVariant,
                          )),
                        ),
                      ),
                    ),
                ]),
              ),
              Divider(height: 0.5, color: border),
              // Lista agrupada por geração
              Expanded(child: ListView(
                padding: const EdgeInsets.only(bottom: 32),
                children: _grouped.entries.map((group) =>
                  _GenerationGroup(
                    label: group.key,
                    pokedex: group.value,
                    activeIds: _activeIds,
                    onToggle: _toggle,
                    onSetAll: (active) => _setAll(group.value, active),
                  ),
                ).toList(),
              )),
            ]),
    );
  }
}

// ─── GRUPO POR GERAÇÃO ───────────────────────────────────────────

class _GenerationGroup extends StatefulWidget {
  final String label;
  final List<_PokedexOption> pokedex;
  final Set<String> activeIds;
  final void Function(String id) onToggle;
  final void Function(bool active) onSetAll;

  const _GenerationGroup({
    required this.label, required this.pokedex, required this.activeIds,
    required this.onToggle, required this.onSetAll,
  });

  @override
  State<_GenerationGroup> createState() => _GenerationGroupState();
}

class _GenerationGroupState extends State<_GenerationGroup> {
  bool _expanded = true;

  @override
  Widget build(BuildContext context) {
    final border = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0);
    final hasToggleable = widget.pokedex.any((p) => !p.isFixed);

    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      // Header do grupo — clicável para colapsar
      InkWell(
        onTap: () => setState(() => _expanded = !_expanded),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 12, 8),
          child: Row(children: [
            Expanded(child: Text(widget.label, style: TextStyle(
              fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8,
              color: Theme.of(context).colorScheme.onSurfaceVariant,
            ))),
            if (hasToggleable) ...[
              GestureDetector(
                onTap: () => widget.onSetAll(true),
                child: Text('Ativar todas', style: TextStyle(
                  fontSize: 11, color: Theme.of(context).colorScheme.primary,
                )),
              ),
              const SizedBox(width: 4),
              Text('·', style: TextStyle(
                fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              const SizedBox(width: 4),
              GestureDetector(
                onTap: () => widget.onSetAll(false),
                child: Text('Desativar todas', style: TextStyle(
                  fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant,
                )),
              ),
              const SizedBox(width: 8),
            ],
            Icon(_expanded ? Icons.expand_less : Icons.expand_more,
              size: 18, color: Theme.of(context).colorScheme.onSurfaceVariant),
          ]),
        ),
      ),
      if (_expanded)
        Container(
          margin: const EdgeInsets.symmetric(horizontal: 16),
          decoration: BoxDecoration(
            border: Border.all(color: border, width: 0.5),
            borderRadius: BorderRadius.circular(12),
          ),
          child: Column(children: widget.pokedex.asMap().entries.map((e) {
            final isLast = e.key == widget.pokedex.length - 1;
            final p = e.value;
            final isActive = p.isFixed || widget.activeIds.contains(p.id);

            return Container(
              decoration: isLast ? null : BoxDecoration(
                border: Border(bottom: BorderSide(color: border, width: 0.5))),
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 12),
              child: Row(children: [
                Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                  Row(children: [
                    Text(p.name, style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: (!isActive && !p.isFixed)
                          ? Theme.of(context).colorScheme.onSurfaceVariant
                          : null,
                    )),
                    if (p.isFixed) ...[
                      const SizedBox(width: 8),
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 7, vertical: 2),
                        decoration: BoxDecoration(
                          color: Theme.of(context).colorScheme.secondaryContainer,
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text('Fixa', style: TextStyle(
                          fontSize: 10, fontWeight: FontWeight.w500,
                          color: Theme.of(context).colorScheme.onSecondaryContainer,
                        )),
                      ),
                    ],
                  ]),
                  if (p.year.isNotEmpty)
                    Text(p.year, style: TextStyle(
                      fontSize: 12, color: Theme.of(context).colorScheme.onSurfaceVariant,
                    )),
                ])),
                if (!p.isFixed)
                  Switch(
                    value: isActive,
                    onChanged: (_) => widget.onToggle(p.id),
                  )
                else
                  Switch(value: true, onChanged: null), // sempre ligado, desabilitado
              ]),
            );
          }).toList()),
        ),
      const SizedBox(height: 4),
    ]);
  }
}

// ─── WIDGETS AUXILIARES ──────────────────────────────────────────

class _SectionHeader extends StatelessWidget {
  final String label;
  const _SectionHeader({required this.label});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 6),
      child: Text(label, style: TextStyle(
        fontSize: 11, fontWeight: FontWeight.w600, letterSpacing: 0.8,
        color: Theme.of(context).colorScheme.onSurfaceVariant,
      )),
    );
  }
}

class _SettingsTile extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback? onTap;
  final Color? titleColor;

  const _SettingsTile({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.titleColor,
  });

  @override
  Widget build(BuildContext context) {
    final border = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF3A3A3A) : const Color(0xFFE0E0E0);

    return InkWell(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 13),
        decoration: BoxDecoration(
          border: Border(bottom: BorderSide(color: border, width: 0.5))),
        child: Row(children: [
          Icon(icon, size: 20, color: titleColor ?? Theme.of(context).colorScheme.onSurfaceVariant),
          const SizedBox(width: 14),
          Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Text(title, style: TextStyle(fontSize: 14, fontWeight: FontWeight.w500,
              color: titleColor)),
            Text(subtitle, style: TextStyle(fontSize: 12,
              color: Theme.of(context).colorScheme.onSurfaceVariant)),
          ])),
          if (onTap != null)
            Icon(Icons.chevron_right, size: 18,
              color: Theme.of(context).colorScheme.onSurfaceVariant),
        ]),
      ),
    );
  }
}