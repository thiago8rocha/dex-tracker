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
import 'package:pokedex_tracker/screens/menu/abilities_list_screen.dart'
    show AbilityEntry;

class AbilityDetailScreen extends StatefulWidget {
  final AbilityEntry entry;
  const AbilityDetailScreen({super.key, required this.entry});
  @override State<AbilityDetailScreen> createState() => _AbilityDetailScreenState();
}

class _AbilityDetailScreenState extends State<AbilityDetailScreen>
    with SingleTickerProviderStateMixin {

  Map<String, dynamic>? _detail;
  bool                  _loading = true;
  late TabController    _tab;

  @override
  void initState() {
    super.initState();
    _tab = TabController(length: 2, vsync: this);
    _loadDetail();
  }

  @override
  void dispose() { _tab.dispose(); super.dispose(); }

  Future<void> _loadDetail() async {
    try {
      final res = await http.get(
        Uri.parse('$kApiBase/ability/${widget.entry.nameEn}'),
      ).timeout(const Duration(seconds: 10));
      if (res.statusCode == 200 && mounted) {
        setState(() { _detail = jsonDecode(res.body); _loading = false; });
        return;
      }
    } catch (_) {}
    if (mounted) setState(() => _loading = false);
  }

  // ── Textos extraídos da API ────────────────────────────────────
  String get _effect {
    final entries = _detail?['effect_entries'] as List<dynamic>? ?? [];
    for (final e in entries) {
      if (e['language']['name'] == 'en') {
        return (e['effect'] as String? ?? '').replaceAll('\n', ' ').trim();
      }
    }
    return widget.entry.description;
  }

  String get _shortEffect {
    final entries = _detail?['effect_entries'] as List<dynamic>? ?? [];
    for (final e in entries) {
      if (e['language']['name'] == 'en') {
        return (e['short_effect'] as String? ?? '').trim();
      }
    }
    return widget.entry.description;
  }

  String get _flavorText {
    final entries = _detail?['flavor_text_entries'] as List<dynamic>? ?? [];
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

  // ── Navegar para detalhe do pokémon ───────────────────────────
  Future<void> _openPokemon(int id) async {
    final svc   = PokedexDataService.instance;
    final name  = svc.getName(id);
    final types = svc.getTypes(id);

    final poke = Pokemon(
      id: id, name: name, types: types,
      baseHp: 0, baseAttack: 0, baseDefense: 0,
      baseSpAttack: 0, baseSpDefense: 0, baseSpeed: 0,
      spriteUrl:     'assets/sprites/artwork/$id.webp',
      spritePixelUrl:'assets/sprites/pixel/$id.webp',
      spriteHomeUrl: 'assets/sprites/home/$id.webp',
    );

    final lastDex = await StorageService().getLastPokedexId() ?? 'nacional';
    final isNac   = lastDex == 'nacional';
    final isCaught = await StorageService().isCaught(lastDex, id);

    if (!mounted) return;
    Navigator.push(context, MaterialPageRoute(
      builder: (_) => isNac
          ? NacionalDetailScreen(
              pokemon: poke, caught: isCaught,
              onToggleCaught: () async {
                final cur = await StorageService().isCaught(lastDex, id);
                await StorageService().setCaught(lastDex, id, !cur);
              })
          : SwitchDetailScreen(
              pokemon: poke, caught: isCaught,
              pokedexId: lastDex,
              onToggleCaught: () async {
                final cur = await StorageService().isCaught(lastDex, id);
                await StorageService().setCaught(lastDex, id, !cur);
              }),
    ));
  }

  @override
  Widget build(BuildContext context) {
    final scheme  = Theme.of(context).colorScheme;
    final namePt  = translateAbility(widget.entry.nameEn);
    final mainIds   = widget.entry.mainIds;
    final hiddenIds = widget.entry.hiddenIds;

    return Scaffold(
      appBar: AppBar(
        title: Text(namePt),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: Column(children: [
        // ── Informações da habilidade ────────────────────────────
        Padding(
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 0),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [

            // Efeito curto
            if (_loading)
              Container(
                height: 48,
                decoration: BoxDecoration(color: neutralBg(context),
                    borderRadius: BorderRadius.circular(10)),
                child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
              )
            else ...[
              // Efeito curto (como resumo)
              if (_shortEffect.isNotEmpty)
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: neutralBg(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Text(_shortEffect, style: TextStyle(
                      fontSize: 13, color: scheme.onSurface, height: 1.5)),
                ),

              // Descrição completa (flavor text do jogo)
              if (_flavorText.isNotEmpty) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: neutralBg(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Descrição no jogo',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant, letterSpacing: 0.6)),
                    const SizedBox(height: 6),
                    Text(_flavorText, style: TextStyle(fontSize: 13,
                        color: scheme.onSurface, height: 1.5,
                        fontStyle: FontStyle.italic)),
                  ]),
                ),
              ],

              // Efeito detalhado
              if (_effect.isNotEmpty && _effect != _shortEffect) ...[
                const SizedBox(height: 10),
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: neutralBg(context),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
                    Text('Efeito detalhado',
                        style: TextStyle(fontSize: 10, fontWeight: FontWeight.w700,
                            color: scheme.onSurfaceVariant, letterSpacing: 0.6)),
                    const SizedBox(height: 6),
                    Text(_effect, style: TextStyle(fontSize: 13,
                        color: scheme.onSurface, height: 1.5)),
                  ]),
                ),
              ],
            ],

            const SizedBox(height: 12),
          ]),
        ),

        // ── Abas: Principal / Oculta ─────────────────────────────
        TabBar(
          controller: _tab,
          tabs: [
            Tab(text: 'Principal (${mainIds.length})'),
            Tab(text: 'Oculta (${hiddenIds.length})'),
          ],
          labelColor: scheme.primary,
          unselectedLabelColor: scheme.onSurfaceVariant,
          indicatorColor: scheme.primary,
        ),

        // ── Listas de pokémon ─────────────────────────────────────
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
  final List<int>          ids;
  final Future<void> Function(int) onTap;
  const _PokemonList({required this.ids, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    if (ids.isEmpty) {
      return Center(
        child: Text('Nenhum Pokémon com esta habilidade.',
            style: TextStyle(color: scheme.onSurfaceVariant)));
    }

    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
      itemCount: ids.length,
      itemBuilder: (ctx, i) => _PokemonTile(id: ids[i], scheme: scheme, onTap: onTap),
    );
  }
}

class _PokemonTile extends StatelessWidget {
  final int              id;
  final ColorScheme      scheme;
  final Future<void> Function(int) onTap;
  const _PokemonTile({required this.id, required this.scheme, required this.onTap});

  @override
  Widget build(BuildContext context) {
    final svc  = PokedexDataService.instance;
    final name = svc.getName(id);

    return GestureDetector(
      onTap: () => onTap(id),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: scheme.surfaceContainerLow,
          borderRadius: BorderRadius.circular(4),
          border: Border.all(color: scheme.outlineVariant, width: 0.5),
        ),
        child: Row(children: [
          Image.asset('assets/sprites/artwork/$id.webp',
            width: 40, height: 40, fit: BoxFit.contain,
            errorBuilder: (_, __, ___) => SizedBox(width: 40, height: 40,
              child: Icon(Icons.catching_pokemon, size: 22,
                  color: scheme.onSurfaceVariant.withOpacity(0.3)))),
          const SizedBox(width: 10),
          Text(
            String.fromCharCode(0x0023) +
            id.toString().padLeft(3, '0'),
            style: TextStyle(fontSize: 11,
                color: scheme.onSurfaceVariant.withOpacity(0.6)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(name,
              style: const TextStyle(
                  fontSize: 13, fontWeight: FontWeight.w500))),
          Icon(Icons.chevron_right, size: 14,
              color: scheme.onSurfaceVariant.withOpacity(0.4)),
        ]),
      ),
    );
  }
}
