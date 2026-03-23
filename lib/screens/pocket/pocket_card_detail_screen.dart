import 'package:flutter/material.dart';
import 'package:pokedex_tracker/services/tcg_pocket_service.dart';
import 'package:pokedex_tracker/screens/pocket/pocket_rarity_widget.dart';

class PocketCardDetailScreen extends StatefulWidget {
  final PocketCardBrief card;
  final String          setId;

  const PocketCardDetailScreen({
    super.key,
    required this.card,
    required this.setId,
  });

  @override
  State<PocketCardDetailScreen> createState() => _PocketCardDetailScreenState();
}

class _PocketCardDetailScreenState extends State<PocketCardDetailScreen> {
  PocketCardDetail? _detail;
  bool _loadingDetail = true;
  String? _fetchError;

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      // Extrair localId da imageUrlLow que já funciona na lista
      // Ex: "https://assets.tcgdex.net/en/tcgp/A1/1/low.webp" → localId="1"
      String? localFromUrl;
      final imgUrl = widget.card.imageUrlLow;
      if (imgUrl != null) {
        final parts = imgUrl.split('/');
        // Estrutura: .../tcgp/{setId}/{localId}/low.webp
        // low.webp é o último, localId é o penúltimo
        if (parts.length >= 2) {
          localFromUrl = parts[parts.length - 2]; // ex: "1"
        }
      }

      final localId = localFromUrl ?? widget.card.localId;

      final d = await TcgPocketService.fetchCard(
        widget.card.id, setId: widget.setId, localId: localId,
      );
      if (mounted) setState(() { _detail = d; _loadingDetail = false; });
    } catch (e) {
      if (mounted) setState(() {
        _loadingDetail = false;
        _fetchError = e.toString();
      });
    }
  }

  String? get _highUrl {
    final low = widget.card.imageUrlLow;
    if (low == null) return null;
    return low.replaceAll('/low.webp', '/high.webp');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark  = Theme.of(context).brightness == Brightness.dark;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card.name),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── Imagem ────────────────────────────────────────────
            Container(
              color: scheme.surfaceContainerLow,
              padding: const EdgeInsets.symmetric(vertical: 24),
              child: Center(
                child: ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 240),
                  child: AspectRatio(
                    aspectRatio: 0.714,
                    child: ClipRRect(
                      borderRadius: BorderRadius.circular(12),
                      child: _highUrl != null
                          ? Image.network(
                              _highUrl!,
                              fit: BoxFit.cover,
                              loadingBuilder: (_, child, p) =>
                                  p == null ? child : Container(
                                    color: scheme.surfaceContainerHigh,
                                    child: const Center(child: CircularProgressIndicator(strokeWidth: 2)),
                                  ),
                              errorBuilder: (_, __, ___) => Container(
                                color: scheme.surfaceContainerHigh,
                                child: Icon(Icons.style_outlined, size: 48,
                                    color: scheme.onSurfaceVariant.withOpacity(0.3)),
                              ),
                            )
                          : Container(
                              color: scheme.surfaceContainerHigh,
                              child: Icon(Icons.style_outlined, size: 48,
                                  color: scheme.onSurfaceVariant.withOpacity(0.3)),
                            ),
                    ),
                  ),
                ),
              ),
            ),

            Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Nome ────────────────────────────────────────
                  Text(widget.card.name,
                    style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w800)),
                  const SizedBox(height: 4),

                  // ── Set name ────────────────────────────────────
                  Text(
                    kPocketSetMeta[widget.setId]?.namePt ?? widget.setId,
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),

                  // ── Raridade ────────────────────────────────────
                  if (widget.card.rarity != null) ...[
                    const SizedBox(height: 8),
                    Row(children: [
                      PocketRarityBadge(rarity: widget.card.rarity!, expanded: true),
                      const SizedBox(width: 6),
                      Text(widget.card.rarity!,
                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ]),
                  ],

                  const SizedBox(height: 16),

                  // ── Tabela de stats ─────────────────────────────
                  _buildStatsTable(context, scheme, isDark),

                  const SizedBox(height: 16),

                  // ── Loading extras ──────────────────────────────
                  if (_loadingDetail)
                    Padding(
                      padding: const EdgeInsets.only(bottom: 8),
                      child: Row(mainAxisSize: MainAxisSize.min, children: [
                        SizedBox(width: 14, height: 14,
                          child: CircularProgressIndicator(strokeWidth: 2,
                              color: scheme.onSurfaceVariant)),
                        const SizedBox(width: 8),
                        Text('Carregando detalhes...',
                            style: TextStyle(fontSize: 12,
                                color: scheme.onSurfaceVariant)),
                      ]),
                    ),
                  if (!_loadingDetail && _fetchError != null)
                    Container(
                      width: double.infinity,
                      padding: const EdgeInsets.all(8),
                      margin: const EdgeInsets.only(bottom: 8),
                      decoration: BoxDecoration(
                        color: Colors.red.withOpacity(0.1),
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        'Erro: ${_fetchError ?? ""}',
                        style: const TextStyle(fontSize: 11),
                      ),
                    ),

                  // ── Descrição ───────────────────────────────────
                  if (_detail?.description != null &&
                      _detail!.description!.isNotEmpty) ...[
                    Text(_detail!.description!,
                      style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic,
                          color: scheme.onSurfaceVariant, height: 1.5)),
                    const SizedBox(height: 16),
                  ],

                  // ── Habilidades ─────────────────────────────────
                  if (_detail != null && _detail!.abilities.isNotEmpty) ...[
                    _buildSectionTitle('Habilidades', scheme),
                    const SizedBox(height: 8),
                    ..._detail!.abilities.map((a) => _buildAbilityCard(a, scheme)),
                    const SizedBox(height: 8),
                  ],

                  // ── Ataques ─────────────────────────────────────
                  if (_detail != null && _detail!.attacks.isNotEmpty) ...[
                    _buildSectionTitle('Ataques', scheme),
                    const SizedBox(height: 8),
                    _buildAttacksTable(_detail!.attacks, scheme, isDark),
                    const SizedBox(height: 8),
                  ],

                  // ── Trainer ─────────────────────────────────────
                  if (_detail != null &&
                      _detail!.category == 'Trainer' &&
                      _detail!.trainerEffect != null &&
                      _detail!.trainerEffect!.isNotEmpty) ...[
                    _buildSectionTitle(_trainerLabel(_detail!.trainerType), scheme),
                    const SizedBox(height: 8),
                    Container(
                      padding: const EdgeInsets.all(12),
                      decoration: BoxDecoration(
                        color: Colors.teal.withOpacity(0.08),
                        borderRadius: BorderRadius.circular(4),
                        border: Border.all(color: Colors.teal.withOpacity(0.3)),
                      ),
                      child: Text(_detail!.trainerEffect!,
                          style: TextStyle(fontSize: 13, height: 1.5,
                              color: scheme.onSurface.withOpacity(0.85))),
                    ),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // ── Stats table ────────────────────────────────────────────────
  Widget _buildStatsTable(BuildContext ctx, ColorScheme scheme, bool isDark) {
    final cells = <_Cell>[];
    cells.add(_Cell(label: 'Número', value: '#${widget.card.localId}'));

    if (_detail?.stage != null) {
      cells.add(_Cell(label: 'Evolução', value: _stageLabel(_detail!.stage!)));
    }
    if (_detail?.hp != null) {
      cells.add(_Cell(label: 'HP', value: '${_detail!.hp}'));
    }
    if (_detail?.weaknessType != null) {
      final v = _detail!.weaknessValue != null ? '+${_detail!.weaknessValue}' : '';
      cells.add(_Cell(label: 'Fraqueza', value: '${_detail!.weaknessType}$v'));
    }

    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      child: Row(
        children: cells.map((c) {
          final isLast = c == cells.last;
          return Expanded(
            child: Container(
              decoration: !isLast
                  ? BoxDecoration(border: Border(
                      right: BorderSide(color: scheme.outlineVariant, width: 0.5)))
                  : null,
              padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 6),
              child: Column(mainAxisSize: MainAxisSize.min, children: [
                Text(c.value, style: const TextStyle(
                    fontSize: 13, fontWeight: FontWeight.w700),
                  textAlign: TextAlign.center,
                  maxLines: 1, overflow: TextOverflow.ellipsis),
                const SizedBox(height: 2),
                Text(c.label, style: TextStyle(
                    fontSize: 10, color: scheme.onSurfaceVariant),
                  textAlign: TextAlign.center),
              ]),
            ),
          );
        }).toList(),
      ),
    );
  }

  // ── Habilidade ────────────────────────────────────────────────
  Widget _buildAbilityCard(PocketAbility a, ColorScheme scheme) {
    return Container(
      margin: const EdgeInsets.only(bottom: 8),
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.purple.withOpacity(0.08),
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: Colors.purple.withOpacity(0.25)),
      ),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
            decoration: BoxDecoration(
              color: Colors.purple.shade600,
              borderRadius: BorderRadius.circular(4),
            ),
            child: Text(a.type ?? 'Habilidade',
              style: const TextStyle(color: Colors.white,
                  fontSize: 10, fontWeight: FontWeight.w700)),
          ),
          const SizedBox(width: 8),
          Expanded(child: Text(a.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
        ]),
        if (a.effect != null && a.effect!.isNotEmpty) ...[
          const SizedBox(height: 6),
          Text(a.effect!, style: TextStyle(fontSize: 13, height: 1.4,
              color: scheme.onSurface.withOpacity(0.8))),
        ],
      ]),
    );
  }

  // ── Ataques ───────────────────────────────────────────────────
  Widget _buildAttacksTable(
      List<PocketAttack> attacks, ColorScheme scheme, bool isDark) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      child: Column(children: [
        for (int i = 0; i < attacks.length; i++) ...[
          if (i > 0) Divider(height: 1, color: scheme.outlineVariant),
          Padding(
            padding: const EdgeInsets.all(12),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              Row(children: [
                // Energia
                if (attacks[i].cost.isNotEmpty) ...[
                  ...attacks[i].cost.map((c) => Padding(
                    padding: const EdgeInsets.only(right: 4),
                    child: _energyIcon(c),
                  )),
                  const SizedBox(width: 6),
                ],
                // Nome
                Expanded(child: Text(attacks[i].name,
                    style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
                // Dano
                if (attacks[i].damage != null && attacks[i].damage!.isNotEmpty)
                  Text(attacks[i].damage!,
                      style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
              ]),
              // Efeito
              if (attacks[i].effect != null && attacks[i].effect!.isNotEmpty) ...[
                const SizedBox(height: 4),
                Text(attacks[i].effect!, style: TextStyle(fontSize: 12, height: 1.4,
                    color: scheme.onSurface.withOpacity(0.7))),
              ],
            ]),
          ),
        ],
      ]),
    );
  }

  Widget _energyIcon(String type) {
    const colors = {
      'Fire': Color(0xFFF08030), 'Water': Color(0xFF6890F0),
      'Grass': Color(0xFF78C850), 'Electric': Color(0xFFF8D030),
      'Lightning': Color(0xFFF8D030), 'Psychic': Color(0xFFF85888),
      'Fighting': Color(0xFFC03028), 'Darkness': Color(0xFF705848),
      'Dark': Color(0xFF705848), 'Metal': Color(0xFFB8B8D0),
      'Steel': Color(0xFFB8B8D0), 'Colorless': Color(0xFFA8A878),
      'Dragon': Color(0xFF7038F8),
    };
    final color = colors[type] ?? const Color(0xFFA8A878);
    return Container(
      width: 20, height: 20,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle),
      child: ClipOval(
        child: Image.asset('assets/types/${type.toLowerCase()}.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(type.isNotEmpty ? type[0] : '?',
              style: const TextStyle(color: Colors.white, fontSize: 10,
                  fontWeight: FontWeight.w800))),
        ),
      ),
    );
  }

  Widget _buildSectionTitle(String title, ColorScheme scheme) {
    return Text(title, style: TextStyle(fontSize: 13,
        fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant));
  }

  String _stageLabel(String s) {
    switch (s.toLowerCase()) {
      case 'basic':  return 'Básico';
      case 'stage1': return 'Estágio 1';
      case 'stage2': return 'Estágio 2';
      default:       return s;
    }
  }

  String _trainerLabel(String? t) {
    switch (t?.toLowerCase()) {
      case 'item':      return 'Item';
      case 'supporter': return 'Suporte';
      case 'stadium':   return 'Estádio';
      case 'tool':      return 'Ferramenta';
      default:          return t ?? 'Efeito';
    }
  }
}

class _Cell {
  final String label;
  final String value;
  const _Cell({required this.label, required this.value});
}
