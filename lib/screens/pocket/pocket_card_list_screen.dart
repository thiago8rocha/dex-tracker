import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:pokedex_tracker/services/tcg_pocket_service.dart';
import 'package:pokedex_tracker/screens/pocket/pocket_card_detail_screen.dart';
import 'package:pokedex_tracker/screens/pocket/pocket_rarity_widget.dart';

// ─── FILTRO DE COLEÇÃO ────────────────────────────────────────────

enum _CollectionFilter { all, owned, missing }

// ─── TELA DE LISTA ────────────────────────────────────────────────

class PocketCardListScreen extends StatefulWidget {
  final String setId;
  final String setName;

  const PocketCardListScreen({
    super.key,
    required this.setId,
    required this.setName,
  });

  @override
  State<PocketCardListScreen> createState() => _PocketCardListScreenState();
}

class _PocketCardListScreenState extends State<PocketCardListScreen> {
  PocketSet? _set;
  bool    _loading = true;
  String? _error;

  // Estado local de coleção: cardId → true/false
  final Map<String, bool> _owned = {};

  // View e filtros
  bool              _isGrid    = true;
  _CollectionFilter _filter    = _CollectionFilter.all;
  String            _search    = '';
  final _searchCtrl = TextEditingController();

  // Chave SharedPreferences: pocket_owned_{setId}_{cardId}
  String _prefKey(String cardId) => 'pocket_owned_${widget.setId}_$cardId';

  @override
  void initState() {
    super.initState();
    _loadSet();
  }

  @override
  void dispose() {
    _searchCtrl.dispose();
    super.dispose();
  }

  Future<void> _loadSet() async {
    setState(() { _loading = true; _error = null; });
    try {
      final set = await TcgPocketService.fetchSet(widget.setId);
      if (mounted) {
        setState(() {
          _set     = set;
          _loading = false;
          if (set == null) _error = 'Erro ao carregar coleção';
        });
        if (set != null) await _loadOwned(set.cards);
      }
    } catch (_) {
      if (mounted) setState(() { _error = 'Erro ao carregar coleção'; _loading = false; });
    }
  }

  Future<void> _loadOwned(List<PocketCardBrief> cards) async {
    final prefs = await SharedPreferences.getInstance();
    final map   = <String, bool>{};
    for (final c in cards) {
      map[c.id] = prefs.getBool(_prefKey(c.id)) ?? false;
    }
    if (mounted) setState(() => _owned.addAll(map));
  }

  Future<void> _toggleOwned(String cardId) async {
    final next  = !(_owned[cardId] ?? false);
    setState(() => _owned[cardId] = next);
    final prefs = await SharedPreferences.getInstance();
    await prefs.setBool(_prefKey(cardId), next);
  }

  List<PocketCardBrief> get _filteredCards {
    if (_set == null) return [];
    var list = _set!.cards;

    // Filtro de coleção
    if (_filter == _CollectionFilter.owned) {
      list = list.where((c) => _owned[c.id] == true).toList();
    } else if (_filter == _CollectionFilter.missing) {
      list = list.where((c) => _owned[c.id] != true).toList();
    }

    // Busca por nome ou número
    final q = _search.trim().toLowerCase();
    if (q.isNotEmpty) {
      list = list.where((c) =>
        c.name.toLowerCase().contains(q) ||
        c.localId.toLowerCase().contains(q)
      ).toList();
    }

    return list;
  }

  int get _ownedCount => _owned.values.where((v) => v).length;
  int get _totalCount => _set?.cards.length ?? 0;

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final cards  = _filteredCards;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.setName),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
        actions: [
          // Toggle lista/grid
          IconButton(
            icon: Icon(_isGrid ? Icons.view_list_outlined : Icons.grid_view_outlined),
            tooltip: _isGrid ? 'Ver em lista' : 'Ver em grid',
            onPressed: () => setState(() => _isGrid = !_isGrid),
          ),
        ],
      ),
      body: _loading
          ? const _ListSkeleton()
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadSet)
              : Column(
                  children: [
                    // ── Barra de busca ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 0),
                      child: TextField(
                        controller: _searchCtrl,
                        onChanged: (v) => setState(() => _search = v),
                        decoration: InputDecoration(
                          hintText: 'Buscar por nome ou número...',
                          prefixIcon: const Icon(Icons.search, size: 20),
                          suffixIcon: _search.isNotEmpty
                              ? IconButton(
                                  icon: const Icon(Icons.close, size: 18),
                                  onPressed: () {
                                    _searchCtrl.clear();
                                    setState(() => _search = '');
                                  },
                                )
                              : null,
                          contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                          isDense: true,
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: scheme.outlineVariant),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(8),
                            borderSide: BorderSide(color: scheme.outlineVariant),
                          ),
                        ),
                      ),
                    ),

                    // ── Filtros de coleção ──
                    Padding(
                      padding: const EdgeInsets.fromLTRB(12, 8, 12, 4),
                      child: Row(
                        children: [
                          _FilterBtn(
                            label: 'Todas',
                            count: _totalCount,
                            active: _filter == _CollectionFilter.all,
                            onTap: () => setState(() => _filter = _CollectionFilter.all),
                          ),
                          const SizedBox(width: 8),
                          _FilterBtn(
                            label: 'Tenho',
                            count: _ownedCount,
                            active: _filter == _CollectionFilter.owned,
                            onTap: () => setState(() => _filter = _CollectionFilter.owned),
                          ),
                          const SizedBox(width: 8),
                          _FilterBtn(
                            label: 'Faltam',
                            count: _totalCount - _ownedCount,
                            active: _filter == _CollectionFilter.missing,
                            onTap: () => setState(() => _filter = _CollectionFilter.missing),
                          ),
                          const Spacer(),
                          // Progresso
                          Text(
                            '$_ownedCount/$_totalCount',
                            style: TextStyle(
                              fontSize: 12,
                              fontWeight: FontWeight.w600,
                              color: scheme.onSurfaceVariant,
                            ),
                          ),
                        ],
                      ),
                    ),

                    // ── Lista ou Grid ──
                    Expanded(
                      child: cards.isEmpty
                          ? Center(
                              child: Text(
                                _search.isNotEmpty
                                    ? 'Nenhuma carta encontrada'
                                    : _filter == _CollectionFilter.owned
                                        ? 'Nenhuma carta registrada ainda'
                                        : 'Coleção completa!',
                                style: TextStyle(color: scheme.onSurfaceVariant),
                              ),
                            )
                          : _isGrid
                              ? _CardGrid(
                                  cards:     cards,
                                  setId:     widget.setId,
                                  owned:     _owned,
                                  onToggle:  _toggleOwned,
                                )
                              : _CardList(
                                  cards:     cards,
                                  setId:     widget.setId,
                                  owned:     _owned,
                                  onToggle:  _toggleOwned,
                                ),
                    ),
                  ],
                ),
    );
  }
}

// ─── Botão de filtro ─────────────────────────────────────────────

class _FilterBtn extends StatelessWidget {
  final String label;
  final int    count;
  final bool   active;
  final VoidCallback onTap;

  const _FilterBtn({
    required this.label,
    required this.count,
    required this.active,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final color  = active ? scheme.primary : scheme.onSurfaceVariant;

    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 5),
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          border: Border.all(
            color: active ? scheme.primary : scheme.outlineVariant,
            width: active ? 2 : 1,
          ),
          color: active ? scheme.primary.withOpacity(0.08) : Colors.transparent,
        ),
        child: Text(
          '$label ($count)',
          style: TextStyle(
            fontSize: 11,
            fontWeight: active ? FontWeight.w700 : FontWeight.w400,
            color: color,
          ),
        ),
      ),
    );
  }
}

// ─── Grid 3 colunas ──────────────────────────────────────────────

class _CardGrid extends StatelessWidget {
  final List<PocketCardBrief>    cards;
  final String                   setId;
  final Map<String, bool>        owned;
  final void Function(String id) onToggle;

  const _CardGrid({
    required this.cards,
    required this.setId,
    required this.owned,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(12, 8, 12, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount:   3,
        childAspectRatio: 0.6,
        crossAxisSpacing: 8,
        mainAxisSpacing:  8,
      ),
      itemCount: cards.length,
      itemBuilder: (context, i) => _CardGridTile(
        card:     cards[i],
        setId:    setId,
        isOwned:  owned[cards[i].id] ?? false,
        onToggle: () => onToggle(cards[i].id),
      ),
    );
  }
}

class _CardGridTile extends StatelessWidget {
  final PocketCardBrief card;
  final String          setId;
  final bool            isOwned;
  final VoidCallback    onToggle;

  const _CardGridTile({
    required this.card,
    required this.setId,
    required this.isOwned,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PocketCardDetailScreen(
            cardId:  card.id,
            setId:   setId,
            localId: card.localId,
          ),
        ),
      ),
      child: Container(
        decoration: BoxDecoration(
          color: isOwned
              ? scheme.primaryContainer.withOpacity(isDark ? 0.3 : 0.25)
              : (isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOwned ? scheme.primary.withOpacity(0.5) : scheme.outlineVariant,
            width: isOwned ? 1.5 : 0.5,
          ),
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            // Imagem
            Expanded(
              child: ClipRRect(
                borderRadius: const BorderRadius.vertical(top: Radius.circular(8)),
                child: Stack(
                  fit: StackFit.expand,
                  children: [
                    card.imageUrlLow != null
                        ? Image.network(
                            card.imageUrlLow!,
                            fit: BoxFit.cover,
                            loadingBuilder: (_, child, p) => p == null ? child
                                : Container(color: scheme.surfaceContainerHighest),
                            errorBuilder: (_, __, ___) => _CardPlaceholder(scheme: scheme),
                          )
                        : _CardPlaceholder(scheme: scheme),
                    // Tick de "tenho"
                    if (isOwned)
                      Positioned(
                        top: 4, right: 4,
                        child: Container(
                          width: 18, height: 18,
                          decoration: BoxDecoration(
                            color: scheme.primary,
                            shape: BoxShape.circle,
                          ),
                          child: const Icon(Icons.check, size: 12, color: Colors.white),
                        ),
                      ),
                  ],
                ),
              ),
            ),
            // Rodapé
            Padding(
              padding: const EdgeInsets.fromLTRB(5, 3, 5, 4),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${card.localId}',
                    style: TextStyle(fontSize: 9, fontWeight: FontWeight.w600,
                        color: scheme.onSurfaceVariant)),
                  Text(card.name,
                    style: const TextStyle(fontSize: 10, fontWeight: FontWeight.w600),
                    maxLines: 1, overflow: TextOverflow.ellipsis),
                  const SizedBox(height: 2),
                  Row(
                    children: [
                      if (card.rarity != null)
                        Expanded(child: PocketRarityBadge(rarity: card.rarity!)),
                      // Botão "tenho"
                      GestureDetector(
                        onTap: onToggle,
                        child: Icon(
                          isOwned ? Icons.catching_pokemon : Icons.catching_pokemon_outlined,
                          size: 16,
                          color: isOwned ? scheme.primary : scheme.onSurfaceVariant.withOpacity(0.5),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Lista linear ────────────────────────────────────────────────

class _CardList extends StatelessWidget {
  final List<PocketCardBrief>    cards;
  final String                   setId;
  final Map<String, bool>        owned;
  final void Function(String id) onToggle;

  const _CardList({
    required this.cards,
    required this.setId,
    required this.owned,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    return ListView.builder(
      padding: const EdgeInsets.fromLTRB(12, 4, 12, 24),
      itemCount: cards.length,
      itemBuilder: (context, i) => _CardListTile(
        card:     cards[i],
        setId:    setId,
        isOwned:  owned[cards[i].id] ?? false,
        onToggle: () => onToggle(cards[i].id),
      ),
    );
  }
}

class _CardListTile extends StatelessWidget {
  final PocketCardBrief card;
  final String          setId;
  final bool            isOwned;
  final VoidCallback    onToggle;

  const _CardListTile({
    required this.card,
    required this.setId,
    required this.isOwned,
    required this.onToggle,
  });

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    return GestureDetector(
      onTap: () => Navigator.push(
        context,
        MaterialPageRoute(
          builder: (_) => PocketCardDetailScreen(
            cardId:  card.id,
            setId:   setId,
            localId: card.localId,
          ),
        ),
      ),
      child: Container(
        margin: const EdgeInsets.only(bottom: 6),
        padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 8),
        decoration: BoxDecoration(
          color: isOwned
              ? scheme.primaryContainer.withOpacity(isDark ? 0.25 : 0.18)
              : (isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow),
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isOwned ? scheme.primary.withOpacity(0.4) : scheme.outlineVariant,
            width: isOwned ? 1.5 : 0.5,
          ),
        ),
        child: Row(
          children: [
            // Miniatura
            ClipRRect(
              borderRadius: BorderRadius.circular(6),
              child: SizedBox(
                width: 52, height: 72,
                child: card.imageUrlLow != null
                    ? Image.network(
                        card.imageUrlLow!,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, p) => p == null
                            ? child
                            : Container(color: scheme.surfaceContainerHighest),
                        errorBuilder: (_, __, ___) => _CardPlaceholder(scheme: scheme),
                      )
                    : _CardPlaceholder(scheme: scheme),
              ),
            ),
            const SizedBox(width: 12),
            // Info
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text('#${card.localId}',
                    style: TextStyle(fontSize: 10, color: scheme.onSurfaceVariant)),
                  Text(card.name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600)),
                  const SizedBox(height: 4),
                  if (card.rarity != null)
                    Row(
                      children: [
                        PocketRarityBadge(rarity: card.rarity!, expanded: true),
                        const SizedBox(width: 6),
                        Text(
                          card.rarity!,
                          style: TextStyle(fontSize: 11, color: scheme.onSurfaceVariant),
                        ),
                      ],
                    ),
                ],
              ),
            ),
            // Botão "tenho"
            GestureDetector(
              onTap: onToggle,
              behavior: HitTestBehavior.opaque,
              child: Padding(
                padding: const EdgeInsets.all(8),
                child: Icon(
                  isOwned ? Icons.catching_pokemon : Icons.catching_pokemon_outlined,
                  size: 26,
                  color: isOwned ? scheme.primary : scheme.onSurfaceVariant.withOpacity(0.4),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Placeholder de carta ─────────────────────────────────────────

class _CardPlaceholder extends StatelessWidget {
  final ColorScheme scheme;
  const _CardPlaceholder({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.surfaceContainerHighest,
      child: Center(
        child: Icon(Icons.style_outlined, size: 22,
            color: scheme.onSurfaceVariant.withOpacity(0.3)),
      ),
    );
  }
}

// ─── Skeleton ─────────────────────────────────────────────────────

class _ListSkeleton extends StatefulWidget {
  const _ListSkeleton();
  @override State<_ListSkeleton> createState() => _ListSkeletonState();
}

class _ListSkeletonState extends State<_ListSkeleton>
    with SingleTickerProviderStateMixin {
  late final AnimationController _ctrl;
  late final Animation<double>    _anim;

  @override
  void initState() {
    super.initState();
    _ctrl = AnimationController(vsync: this, duration: const Duration(milliseconds: 1200))
      ..repeat(reverse: true);
    _anim = Tween<double>(begin: 0.3, end: 0.7).animate(_ctrl);
  }

  @override
  void dispose() { _ctrl.dispose(); super.dispose(); }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return AnimatedBuilder(
      animation: _anim,
      builder: (_, __) => GridView.builder(
        padding: const EdgeInsets.fromLTRB(12, 12, 12, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 3, childAspectRatio: 0.6,
          crossAxisSpacing: 8, mainAxisSpacing: 8,
        ),
        itemCount: 18,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: scheme.onSurface.withOpacity(_anim.value * 0.12),
            borderRadius: BorderRadius.circular(8),
          ),
        ),
      ),
    );
  }
}

// ─── Error view ──────────────────────────────────────────────────

class _ErrorView extends StatelessWidget {
  final String message; final VoidCallback onRetry;
  const _ErrorView({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.error_outline, size: 48, color: Colors.grey.shade400),
          const SizedBox(height: 12),
          Text(message),
          const SizedBox(height: 16),
          OutlinedButton(
            style: OutlinedButton.styleFrom(
              shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(4))),
            onPressed: onRetry,
            child: const Text('Tentar novamente'),
          ),
        ],
      ),
    );
  }
}
