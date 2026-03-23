import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:pokedex_tracker/models/pokemon.dart';
import 'package:pokedex_tracker/screens/detail/detail_shared.dart'
    show neutralBg, kApiBase;
import 'package:pokedex_tracker/screens/detail/mainline_detail_screen.dart';
import 'package:pokedex_tracker/screens/detail/nacional_detail_screen.dart';
import 'package:pokedex_tracker/services/pokedex_data_service.dart';
import 'package:pokedex_tracker/services/storage_service.dart';
import 'package:pokedex_tracker/translations.dart';
import 'package:pokedex_tracker/screens/menu/abilities_list_screen.dart' show AbilityEntry;

class AbilityDetailScreen extends StatefulWidget {
  final AbilityEntry entry;
  const AbilityDetailScreen({super.key, required this.entry});
  @override State<AbilityDetailScreen> createState() => _AbilityDetailScreenState();
}

class _AbilityDetailScreenState extends State<AbilityDetailScreen>
    with SingleTickerProviderStateMixin {

  late TabController    _tab;
  // Dados da API — só buscados se o JSON local não tiver os campos expandidos
  Map<String, dynamic>? _apiDetail;
  bool                  _loadingApi = false;

  // Os campos expandidos existem quando o script já rodou
  bool get _hasExpandedData =>
      widget.entry.effectLong.isNotEmpty || widget.entry.flavor.isNotEmpty;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    // Só busca da API se o JSON local não tiver os dados detalhados
    if (!_hasExpandedData) _loadFromApi();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _loadFromApi() async {
    setState(() => _loadingApi = true);
    try {
      final res = await http.get(
        Uri.parse('$kApiBase/ability/${widget.entry.nameEn}'),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && mounted) {
        setState(() { _apiDetail = jsonDecode(res.body); _loadingApi = false; });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loadingApi = false);
  }

  // ── Textos: prefere JSON local, usa API como fallback ────────────
  String get _shortEffect {
    // JSON expandido
    if (widget.entry.description.isNotEmpty) return widget.entry.description;
    // API
    for (final e in _apiDetail?['effect_entries'] as List<dynamic>? ?? []) {
      if (e['language']['name'] == 'en')
        return (e['short_effect'] as String? ?? '').trim();
    }
    return '';
  }

  String get _effectLong {
    // JSON expandido
    if (widget.entry.effectLong.isNotEmpty) return widget.entry.effectLong;
    // API
    for (final e in _apiDetail?['effect_entries'] as List<dynamic>? ?? []) {
      if (e['language']['name'] == 'en') {
        final full  = (e['effect'] as String? ?? '').replaceAll('\n', ' ').trim();
        final short = _shortEffect;
        return full != short ? full : '';
      }
    }
    return '';
  }

  String get _flavor {
    // JSON expandido
    if (widget.entry.flavor.isNotEmpty) return widget.entry.flavor;
    // API — pegar a mais recente em PT-BR ou EN
    final entries = _apiDetail?['flavor_text_entries'] as List<dynamic>? ?? [];
    String pt = '', en = '';
    for (final e in entries) {
      final lang = e['language']['name'] as String;
      if (lang == 'pt-BR' && pt.isEmpty)
        pt = (e['flavor_text'] as String? ?? '').replaceAll('\n', ' ').trim();
      else if (lang == 'en' && en.isEmpty)
        en = (e['flavor_text'] as String? ?? '').replaceAll('\n', ' ').trim();
    }
    return pt.isNotEmpty ? pt : en;
  }

  Future<void> _openPokemon(int id) async {
    final svc  = PokedexDataService.instance;
    final poke = Pokemon(
      id: id, name: svc.getName(id), types: svc.getTypes(id),
      baseHp: 0, baseAttack: 0, baseDefense: 0,
      baseSpAttack: 0, baseSpDefense: 0, baseSpeed: 0,
      spriteUrl:      'assets/sprites/artwork/$id.webp',
      spritePixelUrl: 'assets/sprites/pixel/$id.webp',
      spriteHomeUrl:  'assets/sprites/home/$id.webp',
    );
    final lastDex  = await StorageService().getLastPokedexId() ?? 'nacional';
    final isCaught = await StorageService().isCaught(lastDex, id);
    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => lastDex == 'nacional'
          ? NacionalDetailScreen(
              pokemon: poke, caught: isCaught,
              onToggleCaught: () async {
                final cur = await StorageService().isCaught(lastDex, id);
                await StorageService().setCaught(lastDex, id, !cur);
              })
          : SwitchDetailScreen(
              pokemon: poke, caught: isCaught, pokedexId: lastDex,
              onToggleCaught: () async {
                final cur = await StorageService().isCaught(lastDex, id);
                await StorageService().setCaught(lastDex, id, !cur);
              }),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme    = Theme.of(context).colorScheme;
    final namePt    = translateAbility(widget.entry.nameEn);
    final mainIds   = widget.entry.mainIds;
    final hiddenIds = widget.entry.hiddenIds;
    final short     = _shortEffect;
    final long      = _effectLong;
    final flavor    = _flavor;

    return Scaffold(
      appBar: AppBar(
        title: Text(namePt),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(children: [

        // ── Informações da habilidade ─────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Loading spinner enquanto busca da API (só quando não tem JSON expandido)
            if (_loadingApi)
              Container(
                height: 52,
                decoration: BoxDecoration(color: neutralBg(context),
                    borderRadius: BorderRadius.circular(10)),
                child: const Center(
                    child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else ...[

              // Efeito curto
              if (short.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: neutralBg(context),
                      borderRadius: BorderRadius.circular(10)),
                  child: Text(short, style: TextStyle(
                      fontSize: 13, color: scheme.onSurface, height: 1.5)),
                ),

              // Flavor text
              if (flavor.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: neutralBg(context),
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Descrição no jogo',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant, letterSpacing: 0.6)),
                    const SizedBox(height: 6),
                    Text(flavor, style: TextStyle(fontSize: 13,
                        color: scheme.onSurface, height: 1.5,
                        fontStyle: FontStyle.italic)),
                  ]),
                ),
              ],

              // Efeito detalhado
              if (long.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(color: neutralBg(context),
                      borderRadius: BorderRadius.circular(10)),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                    Text('Efeito detalhado',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant, letterSpacing: 0.6)),
                    const SizedBox(height: 6),
                    Text(long, style: TextStyle(fontSize: 13,
                        color: scheme.onSurface, height: 1.5)),
                  ]),
                ),
              ],
            ],

            const SizedBox(height: 12),
          ]),
        ),

        // ── Abas ─────────────────────────────────────────────────
        TabBar(
          controller: _tab,
          tabs: const [Tab(text: 'Principal'), Tab(text: 'Oculta')],
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant,
          indicatorColor: scheme.primary,
        ),

        Expanded(child: TabBarView(
          controller: _tab,
          children: [
            _PokemonList(ids: mainIds,   onTap: _openPokemon),
            _PokemonList(ids: hiddenIds, onTap: _openPokemon),
          ],
        )),
      ]),
    );
  }
}

// ─── Lista de pokémon ─────────────────────────────────────────────
class _PokemonList extends StatelessWidget {
  final List<int>               ids;
  final Future<void> Function(int) onTap;
  const _PokemonList({required this.ids, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    if (ids.isEmpty) return Center(
        child: Text('Nenhum Pokémon com esta habilidade.',
            style: TextStyle(color: scheme.onSurfaceVariant)));
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: ids.length,
      itemBuilder: (ctx, i) =>
          _PokemonTile(id: ids[i], scheme: scheme, onTap: onTap),
    );
  }
}

class _PokemonTile extends StatelessWidget {
  final int                     id;
  final ColorScheme             scheme;
  final Future<void> Function(int) onTap;
  const _PokemonTile({required this.id, required this.scheme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final name = PokedexDataService.instance.getName(id);
    return GestureDetector(
      onTap: () => onTap(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: scheme.outlineVariant, width: 0.5)),
        child: Row(children: [
          Image.asset('assets/sprites/artwork/$id.webp',
              width: 40, height: 40, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => SizedBox(width: 40, height: 40,
                  child: Icon(Icons.catching_pokemon, size: 22,
                      color: scheme.onSurfaceVariant.withOpacity(0.3)))),
          const SizedBox(width: 10),
          Text('#${id.toString().padLeft(3, '0')}',
              style: TextStyle(fontSize: 11,
                  color: scheme.onSurfaceVariant.withOpacity(0.6))),
          const SizedBox(width: 8),
          Expanded(child: Text(name,
              style: const TextStyle(fontSize: 13, fontWeight: FontWeight.w500))),
          Icon(Icons.chevron_right, size: 14,
              color: scheme.onSurfaceVariant.withOpacity(0.4)),
        ]),
      ),
    );
  }
}
