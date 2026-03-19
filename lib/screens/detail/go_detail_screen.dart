import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

// ─── MODELO ──────────────────────────────────────────────────────

class _PokemonGoData {
  final int id;
  final String name;
  final int goAtk, goDef, goSta;
  final String spriteUrl;
  final List<_EvoTarget> evolutions;

  const _PokemonGoData({
    required this.id, required this.name,
    required this.goAtk, required this.goDef, required this.goSta,
    required this.spriteUrl, this.evolutions = const [],
  });

  // CP máximo nível 40, 15/15/15
  int get maxCp {
    double sqrt(num n) {
      if (n <= 0) return 0;
      double x = n.toDouble();
      for (int i = 0; i < 30; i++) x = (x + n / x) / 2;
      return x;
    }
    const cpm40 = 0.7903;
    final cp = ((goAtk + 15) * sqrt(goDef + 15) * sqrt(goSta + 15) * cpm40 * cpm40 / 10).floor();
    return cp < 10 ? 10 : cp;
  }
}

class _EvoTarget {
  final String name;
  final _PokemonGoData? data; // null = ainda carregando
  const _EvoTarget({required this.name, this.data});
}

// ─── TELA ────────────────────────────────────────────────────────

class GoCpCalculatorScreen extends StatefulWidget {
  const GoCpCalculatorScreen({super.key});
  @override
  State<GoCpCalculatorScreen> createState() => _GoCpCalculatorScreenState();
}

class _GoCpCalculatorScreenState extends State<GoCpCalculatorScreen>
    with SingleTickerProviderStateMixin {

  late TabController _tabController;

  // ── Estado compartilhado ──────────────────────────────────────
  final _searchCtrl = TextEditingController();
  _PokemonGoData? _pokemon;
  bool _loadingPokemon = false;
  String? _pokemonError;
  // Resultados da busca (dropdown)
  List<Map<String, dynamic>> _searchResults = [];
  bool _showDropdown = false;
  bool _searching    = false;

  // Cache de stats GO (evita refetch)
  final Map<int, _PokemonGoData> _cache = {};
  // Lista completa de Pokémon do GO para autocomplete
  List<Map<String, dynamic>> _allPokemon = [];

  // ── Estado aba Evolução ───────────────────────────────────────
  final _cpController = TextEditingController(text: '500');

  // ── Estado aba IVs ────────────────────────────────────────────
  double _level = 25;
  int _ivAtk = 15, _ivDef = 15, _ivHp = 15;

  static const List<double> _cpm = [
    0.094,0.1351,0.1663,0.192,0.2126,0.2295,0.2436,0.2557,0.2663,0.2756,
    0.2839,0.2913,0.298,0.3041,0.3096,0.3145,0.319,0.323,0.3267,0.33,
    0.3331,0.3359,0.3385,0.3408,0.343,0.345,0.3469,0.3486,0.3502,0.3517,
    0.3531,0.3544,0.3556,0.3567,0.3578,0.3587,0.3596,0.3604,0.3612,0.3619,
    0.3625,0.3631,0.3637,0.3642,0.3647,0.3652,0.3657,0.3661,0.3665,0.3669,
    0.37,
  ];

  double _sqrtN(num n) {
    if (n <= 0) return 0;
    double x = n.toDouble();
    for (int i = 0; i < 30; i++) x = (x + n / x) / 2;
    return x;
  }

  int _calcCp(int ba, int bd, int bs, double lvl, int ia, int id, int is_) {
    final idx = ((lvl - 1) * 2).round().clamp(0, _cpm.length - 1);
    final cp = ((ba + ia) * _sqrtN(bd + id) * _sqrtN(bs + is_) * _cpm[idx] * _cpm[idx] / 10).floor();
    return cp < 10 ? 10 : cp;
  }

  int get _cpResult {
    if (_pokemon == null) return 0;
    return _calcCp(_pokemon!.goAtk, _pokemon!.goDef, _pokemon!.goSta,
        _level, _ivAtk, _ivDef, _ivHp);
  }

  // ── Fórmula de evolução correta ───────────────────────────────
  // CP_evo = floor(CP_atual × sqrt( produto_stats_evo / produto_stats_base ))
  // Cancela o CPM e os IVs — resultado independente do nível/IVs do Pokémon atual
  int _calcEvoCp(int cpAtual, _PokemonGoData base, _PokemonGoData evo) {
    final numAtk = (evo.goAtk + 15).toDouble();
    final numDef = _sqrtN(evo.goDef + 15);
    final numSta = _sqrtN(evo.goSta + 15);
    final denAtk = (base.goAtk + 15).toDouble();
    final denDef = _sqrtN(base.goDef + 15);
    final denSta = _sqrtN(base.goSta + 15);
    final mult = (numAtk * numDef * numSta) / (denAtk * denDef * denSta);
    return (cpAtual * mult).floor();
  }

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _loadPokemonList();
  }

  @override
  void dispose() {
    _tabController.dispose();
    _cpController.dispose();
    _searchCtrl.dispose();
    super.dispose();
  }

  // ── Carrega a lista de Pokémon GO para autocomplete ───────────
  Future<void> _loadPokemonList() async {
    try {
      final r = await http.get(
        Uri.parse('https://pogoapi.net/api/v1/pokemon_stats.json'));
      if (r.statusCode == 200 && mounted) {
        final body = json.decode(r.body);
        if (body is List) {
          setState(() => _allPokemon = List<Map<String, dynamic>>.from(body));
        }
      }
    } catch (_) {}
  }

  // ── Busca Pokémon por nome parcial ────────────────────────────
  void _onSearchChanged(String query) {
    if (query.trim().isEmpty) {
      setState(() { _searchResults = []; _showDropdown = false; });
      return;
    }
    final q = query.trim().toLowerCase();
    final results = _allPokemon.where((p) {
      final name = (p['pokemon_name'] ?? p['name'] ?? '').toString().toLowerCase();
      return name.contains(q);
    }).take(8).toList();
    setState(() {
      _searchResults = results;
      _showDropdown = results.isNotEmpty;
    });
  }

  // ── Busca stats GO de um Pokémon específico ───────────────────
  Future<_PokemonGoData?> _fetchGoData(int id, String name) async {
    if (_cache.containsKey(id)) return _cache[id];

    try {
      // 1. Tentar pogoapi.net (stats GO precisos)
      if (_allPokemon.isNotEmpty) {
        for (final p in _allPokemon) {
          final pid = (p['pokemon_id'] ?? p['id']);
          if (pid != null && (pid as num).toInt() == id) {
            final atk = (p['base_attack'] ?? p['attack'] ?? 0) as num;
            final def = (p['base_defense'] ?? p['defense'] ?? 0) as num;
            final sta = (p['base_stamina'] ?? p['stamina'] ?? 0) as num;
            if (atk.toInt() > 0) {
              final data = _PokemonGoData(
                id: id, name: name,
                goAtk: atk.toInt(), goDef: def.toInt(), goSta: sta.toInt(),
                spriteUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
              );
              _cache[id] = data;
              return data;
            }
          }
        }
      }

      // 2. Fallback: PokeAPI stats principais com escala ×2
      final r = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/$id'));
      if (r.statusCode == 200) {
        final d = json.decode(r.body) as Map<String, dynamic>;
        final stats = d['stats'] as List<dynamic>;
        int atk = 0, spatk = 0, def = 0, spdef = 0, hp = 0, spd = 0;
        for (final s in stats) {
          switch (s['stat']['name'] as String) {
            case 'attack':          atk   = (s['base_stat'] as num).toInt(); break;
            case 'special-attack':  spatk = (s['base_stat'] as num).toInt(); break;
            case 'defense':         def   = (s['base_stat'] as num).toInt(); break;
            case 'special-defense': spdef = (s['base_stat'] as num).toInt(); break;
            case 'hp':              hp    = (s['base_stat'] as num).toInt(); break;
            case 'speed':           spd   = (s['base_stat'] as num).toInt(); break;
          }
        }
        final speedMod = 1 + (spd - 75) / 500;
        const scale = 2.0;
        final goAtk = ((7 * (atk >= spatk ? atk : spatk) + (atk >= spatk ? spatk : atk)) / 8 * speedMod * scale).round().clamp(1, 999);
        final goDef = ((5 * (def >= spdef ? def : spdef) + 3 * (def >= spdef ? spdef : def)) / 8 * speedMod * scale).round().clamp(1, 999);
        final goSta = (hp * 1.75 + 50).floor().clamp(20, 9999);
        final data = _PokemonGoData(
          id: id, name: name,
          goAtk: goAtk, goDef: goDef, goSta: goSta,
          spriteUrl: 'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$id.png',
        );
        _cache[id] = data;
        return data;
      }
    } catch (_) {}
    return null;
  }

  // ── Seleciona Pokémon do dropdown ─────────────────────────────
  Future<void> _selectPokemon(Map<String, dynamic> p) async {
    setState(() {
      _showDropdown = false;
      _searching    = true;
      _loadingPokemon = true;
      _pokemonError = null;
    });
    final pid  = ((p['pokemon_id'] ?? p['id']) as num).toInt();
    final name = (p['pokemon_name'] ?? p['name'] ?? '').toString();

    final baseData = await _fetchGoData(pid, name);
    if (baseData == null) {
      if (mounted) setState(() { _loadingPokemon = false; _pokemonError = 'Erro ao buscar stats'; });
      return;
    }

    // Buscar evoluções
    List<_EvoTarget> evos = [];
    try {
      final rs = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon-species/$pid'));
      if (rs.statusCode == 200) {
        final sd = json.decode(rs.body) as Map<String, dynamic>;
        final chainUrl = sd['evolution_chain']['url'] as String;
        final rc = await http.get(Uri.parse(chainUrl));
        if (rc.statusCode == 200) {
          final cd = json.decode(rc.body) as Map<String, dynamic>;
          evos = await _collectEvolutions(cd['chain'] as Map<String, dynamic>, name.toLowerCase());
        }
      }
    } catch (_) {}

    // Buscar stats GO de cada evolução
    final evosWithData = <_EvoTarget>[];
    for (final evo in evos) {
      try {
        final re = await http.get(Uri.parse('https://pokeapi.co/api/v2/pokemon/${evo.name}'));
        if (re.statusCode == 200) {
          final ed = json.decode(re.body) as Map<String, dynamic>;
          final eid = (ed['id'] as num).toInt();
          final eData = await _fetchGoData(eid, evo.name);
          if (eData != null) {
            evosWithData.add(_EvoTarget(name: evo.name, data: eData));
            continue;
          }
        }
      } catch (_) {}
      evosWithData.add(_EvoTarget(name: evo.name));
    }

    // Montar Pokémon final com evoluções
    final finalData = _PokemonGoData(
      id: baseData.id, name: baseData.name,
      goAtk: baseData.goAtk, goDef: baseData.goDef, goSta: baseData.goSta,
      spriteUrl: baseData.spriteUrl,
      evolutions: evosWithData,
    );

    if (mounted) setState(() {
      _pokemon = finalData;
      _loadingPokemon = false;
      _searching = false;
      _searchCtrl.clear();
    });
  }

  Future<List<_EvoTarget>> _collectEvolutions(
      Map<String, dynamic> node, String currentName) async {
    final name = (node['species']['name'] as String).toLowerCase();
    final nexts = node['evolves_to'] as List<dynamic>;
    if (name == currentName) {
      return nexts.map((n) =>
        _EvoTarget(name: (n as Map)['species']['name'] as String)).toList();
    }
    for (final next in nexts) {
      final r = await _collectEvolutions(next as Map<String, dynamic>, currentName);
      if (r.isNotEmpty) return r;
    }
    return [];
  }

  // ── Build ─────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Scaffold(
      appBar: AppBar(
        title: const Text('Calculadora de CP'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        bottom: TabBar(
          controller: _tabController,
          tabs: const [Tab(text: 'Evolução'), Tab(text: 'IVs / Nível')],
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant,
          indicatorColor: scheme.primary,
        ),
      ),
      body: Column(children: [
        _buildSelector(context),
        Expanded(child: TabBarView(
          controller: _tabController,
          children: [
            _buildEvoTab(context),
            _buildIvTab(context),
          ],
        )),
      ]),
    );
  }

  // ── Seletor de Pokémon ────────────────────────────────────────
  Widget _buildSelector(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final border = scheme.outlineVariant;

    return Container(
      decoration: BoxDecoration(
        color: scheme.surface,
        border: Border(bottom: BorderSide(color: border, width: 0.5)),
      ),
      child: Column(mainAxisSize: MainAxisSize.min, children: [
        // Campo de busca
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
          child: Row(children: [
            Expanded(child: TextField(
              controller: _searchCtrl,
              decoration: InputDecoration(
                hintText: 'Buscar Pokémon... (ex: pika)',
                prefixIcon: const Icon(Icons.search, size: 20),
                isDense: true,
                contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                border: OutlineInputBorder(borderRadius: BorderRadius.circular(10)),
                suffixIcon: _searchCtrl.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.close, size: 18),
                        onPressed: () {
                          _searchCtrl.clear();
                          setState(() { _showDropdown = false; _searchResults = []; });
                        })
                    : null,
              ),
              onChanged: _onSearchChanged,
            )),
          ]),
        ),
        // Dropdown de resultados
        if (_showDropdown)
          Container(
            margin: const EdgeInsets.fromLTRB(16, 4, 16, 0),
            decoration: BoxDecoration(
              color: scheme.surfaceContainerLow,
              borderRadius: BorderRadius.circular(10),
              border: Border.all(color: scheme.outlineVariant, width: 0.5),
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: _searchResults.asMap().entries.map((e) {
                final isLast = e.key == _searchResults.length - 1;
                final p = e.value;
                final name = (p['pokemon_name'] ?? p['name'] ?? '').toString();
                final pid = ((p['pokemon_id'] ?? p['id']) as num).toInt();
                return InkWell(
                  onTap: () => _selectPokemon(p),
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 10),
                    decoration: isLast ? null : BoxDecoration(
                      border: Border(bottom: BorderSide(color: scheme.outlineVariant, width: 0.5))),
                    child: Row(children: [
                      Image.network(
                        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/$pid.png',
                        width: 32, height: 32,
                        errorBuilder: (_, __, ___) => const SizedBox(width: 32, height: 32),
                      ),
                      const SizedBox(width: 10),
                      Text(name[0].toUpperCase() + name.substring(1),
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w500)),
                      const Spacer(),
                      Text('#${pid.toString().padLeft(3, '0')}',
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                    ]),
                  ),
                );
              }).toList(),
            ),
          ),
        // Pokémon selecionado
        if (_loadingPokemon)
          const Padding(
            padding: EdgeInsets.symmetric(vertical: 12),
            child: LinearProgressIndicator(),
          )
        else if (_pokemon != null && !_showDropdown)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 12),
            child: Row(children: [
              // Sprite do GO (pixel art que é o sprite usado no GO)
              Image.network(
                'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${_pokemon!.id}.png',
                width: 48, height: 48,
                errorBuilder: (_, __, ___) => const SizedBox(width: 48, height: 48),
              ),
              const SizedBox(width: 10),
              Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                Text(
                  _pokemon!.name[0].toUpperCase() + _pokemon!.name.substring(1),
                  style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                Text(
                  'ATK ${_pokemon!.goAtk} · DEF ${_pokemon!.goDef} · STA ${_pokemon!.goSta}',
                  style: TextStyle(fontSize: 11, color: Theme.of(context).colorScheme.onSurfaceVariant)),
              ])),
            ]),
          ),
        if (!_showDropdown && _pokemon == null && !_loadingPokemon)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 6, 16, 12),
            child: Text('Busque um Pokémon para calcular o CP',
              style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
          ),
        if (_pokemonError != null)
          Padding(
            padding: const EdgeInsets.fromLTRB(16, 4, 16, 8),
            child: Text(_pokemonError!, style: TextStyle(fontSize: 12, color: scheme.error)),
          ),
        if (!_showDropdown && _pokemon == null && !_loadingPokemon && _pokemonError == null)
          const SizedBox(height: 4),
      ]),
    );
  }

  // ── Aba Evolução ──────────────────────────────────────────────
  Widget _buildEvoTab(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);
    final cpAtual = int.tryParse(_cpController.text) ?? 500;

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Text('Insira o CP atual para estimar o CP após evolução.',
          style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 16),
        TextField(
          controller: _cpController,
          keyboardType: TextInputType.number,
          decoration: InputDecoration(
            labelText: 'CP atual',
            hintText: 'Ex: 500',
            border: OutlineInputBorder(borderRadius: BorderRadius.circular(12)),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
          ),
          onChanged: (_) => setState(() {}),
        ),
        const SizedBox(height: 20),
        if (_pokemon == null)
          _infoBox(context, 'Selecione um Pokémon acima para calcular.')
        else if (_pokemon!.evolutions.isEmpty)
          _infoBox(context, 'Este Pokémon não possui evoluções no Pokémon GO.')
        else
          Container(
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Column(children: _pokemon!.evolutions.asMap().entries.map((e) {
              final idx = e.key;
              final evo  = e.value;
              final isLast = idx == _pokemon!.evolutions.length - 1;
              final cpEvo = evo.data != null
                  ? _calcEvoCp(cpAtual, _pokemon!, evo.data!)
                  : null;
              final evoName = evo.name[0].toUpperCase() + evo.name.substring(1);
              return Column(children: [
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
                  child: Row(children: [
                    if (evo.data != null)
                      Image.network(
                        'https://raw.githubusercontent.com/PokeAPI/sprites/master/sprites/pokemon/${evo.data!.id}.png',
                        width: 44, height: 44,
                        errorBuilder: (_, __, ___) => const SizedBox(width: 44, height: 44),
                      ),
                    const SizedBox(width: 10),
                    Expanded(child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                      Text(evoName, style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                      Text('Evolução ${idx + 1}',
                        style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
                    ])),
                    Text(cpEvo != null ? '$cpEvo CP' : '...',
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700,
                        color: cpEvo != null ? scheme.primary : scheme.onSurfaceVariant)),
                  ]),
                ),
                if (!isLast) Divider(height: 0.5, color: scheme.outlineVariant),
              ]);
            }).toList()),
          ),
        const SizedBox(height: 12),
        _infoBox(context, 'Resultado baseado nos stats GO reais. '
          'A variação de ±5% ocorre por causa dos IVs do Pokémon.'),
      ]),
    );
  }

  // ── Aba IVs / Nível ───────────────────────────────────────────
  Widget _buildIvTab(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final bg = Theme.of(context).brightness == Brightness.dark
        ? const Color(0xFF2A2A2A) : const Color(0xFFF5F5F5);

    return SingleChildScrollView(
      padding: const EdgeInsets.all(16),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        if (_pokemon == null)
          _infoBox(context, 'Selecione um Pokémon acima para calcular.')
        else ...[
          Text('Nível e IVs',
            style: TextStyle(fontSize: 11, fontWeight: FontWeight.w600,
              letterSpacing: 0.8, color: scheme.onSurfaceVariant)),
          const SizedBox(height: 8),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            decoration: BoxDecoration(color: bg, borderRadius: BorderRadius.circular(12)),
            child: Column(children: [
              _sliderRow(context, 'Nível',
                _level.toStringAsFixed(_level % 1 == 0 ? 0 : 1),
                1, 50, _level, (v) => setState(() => _level = (v * 2).round() / 2)),
              Divider(height: 1, color: scheme.outlineVariant),
              _sliderRow(context, 'IV Ataque', '$_ivAtk', 0, 15, _ivAtk.toDouble(),
                (v) => setState(() => _ivAtk = v.round())),
              Divider(height: 1, color: scheme.outlineVariant),
              _sliderRow(context, 'IV Defesa', '$_ivDef', 0, 15, _ivDef.toDouble(),
                (v) => setState(() => _ivDef = v.round())),
              Divider(height: 1, color: scheme.outlineVariant),
              _sliderRow(context, 'IV HP', '$_ivHp', 0, 15, _ivHp.toDouble(),
                (v) => setState(() => _ivHp = v.round())),
            ]),
          ),
          const SizedBox(height: 20),
          Container(
            width: double.infinity,
            padding: const EdgeInsets.symmetric(vertical: 24),
            decoration: BoxDecoration(
              color: scheme.primaryContainer.withOpacity(0.3),
              borderRadius: BorderRadius.circular(16),
              border: Border.all(color: scheme.primary.withOpacity(0.3)),
            ),
            child: Column(children: [
              Text('$_cpResult',
                style: TextStyle(fontSize: 48, fontWeight: FontWeight.w700,
                  color: scheme.primary)),
              Text('Combat Power',
                style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
              const SizedBox(height: 8),
              Text('CP Máximo (Nível 40, 15/15/15): ${_pokemon!.maxCp}',
                style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant)),
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _infoBox(BuildContext context, String text) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      child: Row(children: [
        Icon(Icons.info_outline, size: 16, color: scheme.onSurfaceVariant),
        const SizedBox(width: 8),
        Expanded(child: Text(text,
          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant))),
      ]),
    );
  }

  Widget _sliderRow(BuildContext context, String label, String valStr,
      num min, num max, double val, ValueChanged<double> onChanged) =>
    Padding(
      padding: const EdgeInsets.symmetric(vertical: 4),
      child: Column(children: [
        Row(mainAxisAlignment: MainAxisAlignment.spaceBetween, children: [
          Text(label, style: TextStyle(fontSize: 12,
            color: Theme.of(context).colorScheme.onSurfaceVariant)),
          Text(valStr, style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600)),
        ]),
        Slider(value: val, min: min.toDouble(), max: max.toDouble(),
          divisions: (max - min).round(), onChanged: onChanged),
      ]),
    );
}