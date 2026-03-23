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

  @override
  void initState() {
    super.initState();
    _fetchDetail();
  }

  Future<void> _fetchDetail() async {
    try {
      final localId0 = widget.card.localId;
      final n        = int.tryParse(localId0);
      final localId1 = n != null ? n.toString() : localId0;

      PocketCardDetail? detail;

      detail = await TcgPocketService.fetchCard(
        widget.card.id,
        setId: widget.setId,
        localId: localId0,
      );

      if (detail == null && localId0 != localId1) {
        detail = await TcgPocketService.fetchCard(
          '${widget.setId}-$localId1',
          setId: widget.setId,
          localId: localId1,
        );
      }

      if (mounted) setState(() { _detail = detail; _loadingDetail = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  // Imagem alta qualidade: troca /low.webp → /high.webp
  String? get _highImageUrl {
    final low = widget.card.imageUrlLow;
    if (low == null) return null;
    return low.replaceAll('/low.webp', '/high.webp');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

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

            // ── Imagem da carta ──────────────────────────────────
            _CardHero(imageUrl: _highImageUrl ?? widget.card.imageUrlLow),

            Padding(
              padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [

                  // ── Nome + tipo(s) ─────────────────────────────
                  Row(
                    crossAxisAlignment: CrossAxisAlignment.center,
                    children: [
                      Expanded(
                        child: Text(
                          widget.card.name,
                          style: const TextStyle(
                            fontSize: 22, fontWeight: FontWeight.w800),
                        ),
                      ),
                      if (_detail != null && _detail!.types.isNotEmpty)
                        ..._detail!.types.map<Widget>((t) => Padding(
                          padding: const EdgeInsets.only(left: 6),
                          child: _TypeIcon(typeName: t, size: 26),
                        )),
                    ],
                  ),
                  const SizedBox(height: 4),

                  // ── Set name ──────────────────────────────────
                  Text(
                    kPocketSetMeta[widget.setId]?.namePt ?? widget.setId,
                    style: TextStyle(fontSize: 13, color: scheme.onSurfaceVariant),
                  ),

                  // ── Raridade ──────────────────────────────────
                  if (widget.card.rarity != null) ...[
                    const SizedBox(height: 6),
                    Row(children: [
                      PocketRarityBadge(rarity: widget.card.rarity!, expanded: true),
                      const SizedBox(width: 6),
                      Text(widget.card.rarity!,
                          style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
                    ]),
                  ],
                  const SizedBox(height: 16),

                  // ── Tabela de stats ───────────────────────────
                  _StatsTable(
                    localId: widget.card.localId,
                    detail: _detail,
                    loading: _loadingDetail,
                    scheme: scheme,
                    isDark: isDark,
                  ),
                  const SizedBox(height: 16),

                  // ── Descrição ─────────────────────────────────
                  if (_detail?.description != null &&
                      _detail!.description!.isNotEmpty) ...[
                    Text(
                      _detail!.description!,
                      style: TextStyle(
                        fontSize: 13, fontStyle: FontStyle.italic,
                        color: scheme.onSurfaceVariant, height: 1.5),
                    ),
                    const SizedBox(height: 16),
                  ],

                  // ── Habilidades ───────────────────────────────
                  if (_detail != null && _detail!.abilities.isNotEmpty) ...[
                    _AbilitiesSection(abilities: _detail!.abilities, scheme: scheme),
                    const SizedBox(height: 16),
                  ],

                  // ── Ataques ───────────────────────────────────
                  if (_detail != null && _detail!.attacks.isNotEmpty) ...[
                    _AttacksSection(attacks: _detail!.attacks, scheme: scheme, isDark: isDark),
                    const SizedBox(height: 16),
                  ],

                  // ── Efeito Trainer ────────────────────────────
                  if (_detail != null &&
                      _detail!.category == 'Trainer' &&
                      _detail!.trainerEffect != null &&
                      _detail!.trainerEffect!.isNotEmpty) ...[
                    _TrainerSection(
                      effect: _detail!.trainerEffect!,
                      trainerType: _detail!.trainerType,
                      scheme: scheme,
                    ),
                    const SizedBox(height: 16),
                  ],
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// ─── Imagem da carta (topo, full-width com padding lateral) ──────

class _CardHero extends StatelessWidget {
  final String? imageUrl;
  const _CardHero({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Container(
      color: scheme.surfaceContainerLow,
      padding: const EdgeInsets.symmetric(vertical: 24),
      child: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 240),
          child: AspectRatio(
            aspectRatio: 0.714, // proporção carta TCG
            child: Container(
              decoration: BoxDecoration(
                borderRadius: BorderRadius.circular(12),
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 8),
                  ),
                ],
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(12),
                child: imageUrl != null
                    ? Image.network(
                        imageUrl!,
                        fit: BoxFit.cover,
                        loadingBuilder: (_, child, p) => p == null
                            ? child
                            : Container(
                                color: scheme.surfaceContainerHigh,
                                child: const Center(
                                    child: CircularProgressIndicator(strokeWidth: 2)),
                              ),
                        errorBuilder: (_, __, ___) => Container(
                          color: scheme.surfaceContainerHigh,
                          child: Icon(Icons.style_outlined, size: 64,
                              color: scheme.onSurfaceVariant.withOpacity(0.3)),
                        ),
                      )
                    : Container(
                        color: scheme.surfaceContainerHigh,
                        child: Icon(Icons.style_outlined, size: 64,
                            color: scheme.onSurfaceVariant.withOpacity(0.3)),
                      ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Ícone circular de tipo ───────────────────────────────────────

class _TypeIcon extends StatelessWidget {
  final String typeName;
  final double size;
  const _TypeIcon({required this.typeName, this.size = 24});

  static const Map<String, Color> _colors = {
    'Normal': Color(0xFFA8A878), 'Fire': Color(0xFFF08030),
    'Water': Color(0xFF6890F0), 'Grass': Color(0xFF78C850),
    'Electric': Color(0xFFF8D030), 'Lightning': Color(0xFFF8D030),
    'Ice': Color(0xFF98D8D8), 'Fighting': Color(0xFFC03028),
    'Poison': Color(0xFFA040A0), 'Ground': Color(0xFFE0C068),
    'Flying': Color(0xFFA890F0), 'Psychic': Color(0xFFF85888),
    'Bug': Color(0xFFA8B820), 'Rock': Color(0xFFB8A038),
    'Ghost': Color(0xFF705898), 'Dragon': Color(0xFF7038F8),
    'Dark': Color(0xFF705848), 'Darkness': Color(0xFF705848),
    'Steel': Color(0xFFB8B8D0), 'Metal': Color(0xFFB8B8D0),
    'Fairy': Color(0xFFEE99AC), 'Colorless': Color(0xFFA8A878),
  };

  static const Map<String, String> _namePt = {
    'Fire': 'Fogo', 'Water': 'Água', 'Grass': 'Planta',
    'Electric': 'Elétrico', 'Lightning': 'Elétrico', 'Ice': 'Gelo',
    'Fighting': 'Lutador', 'Poison': 'Veneno', 'Ground': 'Terra',
    'Flying': 'Voador', 'Psychic': 'Psíquico', 'Bug': 'Inseto',
    'Rock': 'Pedra', 'Ghost': 'Fantasma', 'Dragon': 'Dragão',
    'Dark': 'Sombrio', 'Darkness': 'Sombrio', 'Steel': 'Aço',
    'Metal': 'Aço', 'Fairy': 'Fada', 'Colorless': 'Incolor', 'Normal': 'Normal',
  };

  String get labelPt => _namePt[typeName] ?? typeName;
  Color  get color    => _colors[typeName] ?? const Color(0xFFA8A878);

  @override
  Widget build(BuildContext context) {
    return Tooltip(
      message: labelPt,
      child: Container(
        width: size, height: size,
        decoration: BoxDecoration(color: color, shape: BoxShape.circle),
        child: ClipOval(
          child: Image.asset(
            'assets/types/${typeName.toLowerCase()}.png',
            fit: BoxFit.cover,
            errorBuilder: (_, __, ___) => Center(
              child: Text(typeName.substring(0, 1),
                style: const TextStyle(color: Colors.white,
                    fontSize: 10, fontWeight: FontWeight.w800)),
            ),
          ),
        ),
      ),
    );
  }
}

// ─── Tabela de stats estilo referência ────────────────────────────

class _StatsTable extends StatelessWidget {
  final String           localId;
  final PocketCardDetail? detail;
  final bool             loading;
  final ColorScheme      scheme;
  final bool             isDark;

  const _StatsTable({
    required this.localId,
    required this.detail,
    required this.loading,
    required this.scheme,
    required this.isDark,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      child: loading && detail == null
          ? const Padding(
              padding: EdgeInsets.all(16),
              child: Center(child: SizedBox(
                width: 16, height: 16,
                child: CircularProgressIndicator(strokeWidth: 2))),
            )
          : Column(
              children: [
                // Linha 1: Número | Estágio | HP | Tipo
                IntrinsicHeight(
                  child: Row(
                    children: [
                      _StatCell(
                        label: 'Número',
                        value: '#$localId',
                        scheme: scheme,
                      ),
                      if (detail?.stage != null) ...[
                        _Divider(scheme: scheme),
                        _StatCell(
                          label: 'Evolução',
                          value: _stageLabel(detail!.stage!),
                          scheme: scheme,
                        ),
                      ],
                      if (detail?.hp != null) ...[
                        _Divider(scheme: scheme),
                        _StatCell(
                          label: 'HP',
                          value: '${detail!.hp}',
                          scheme: scheme,
                        ),
                      ],
                      if (detail != null && detail!.types.isNotEmpty) ...[
                        _Divider(scheme: scheme),
                        _StatCell(
                          label: 'Tipo',
                          valueWidget: Row(
                            mainAxisSize: MainAxisSize.min,
                            children: detail!.types.map<Widget>((t) => Padding(
                              padding: const EdgeInsets.only(right: 4),
                              child: _TypeIcon(typeName: t, size: 20),
                            )).toList(),
                          ),
                          scheme: scheme,
                        ),
                      ],
                    ],
                  ),
                ),

                // Linha 2: Fraqueza | Recuo (se disponíveis)
                if (detail?.weaknessType != null || detail?.retreat != null) ...[
                  Divider(height: 1, color: scheme.outlineVariant),
                  IntrinsicHeight(
                    child: Row(
                      children: [
                        if (detail?.weaknessType != null)
                          _StatCell(
                            label: 'Fraqueza',
                            valueWidget: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: [
                                _TypeIcon(typeName: detail!.weaknessType!, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  detail!.weaknessValue != null
                                      ? '+${detail!.weaknessValue}'
                                      : '',
                                  style: const TextStyle(
                                      fontSize: 13, fontWeight: FontWeight.w600),
                                ),
                              ],
                            ),
                            scheme: scheme,
                          ),
                        if (detail?.weaknessType != null && detail?.retreat != null)
                          _Divider(scheme: scheme),
                        if (detail?.retreat != null)
                          _StatCell(
                            label: 'Recuo',
                            valueWidget: Row(
                              mainAxisSize: MainAxisSize.min,
                              children: List.generate(
                                detail!.retreat!.clamp(0, 5),
                                (_) => const Padding(
                                  padding: EdgeInsets.only(right: 2),
                                  child: _TypeIcon(typeName: 'Colorless', size: 16),
                                ),
                              ),
                            ),
                            scheme: scheme,
                          ),
                      ],
                    ),
                  ),
                ],
              ],
            ),
    );
  }

  String _stageLabel(String stage) {
    switch (stage.toLowerCase()) {
      case 'basic':  return 'Básico';
      case 'stage1': return 'Estágio 1';
      case 'stage2': return 'Estágio 2';
      default:       return stage;
    }
  }
}

class _StatCell extends StatelessWidget {
  final String       label;
  final String?      value;
  final Widget?      valueWidget;
  final ColorScheme  scheme;

  const _StatCell({
    required this.label,
    required this.scheme,
    this.value,
    this.valueWidget,
  });

  @override
  Widget build(BuildContext context) {
    return Expanded(
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 8),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            if (valueWidget != null)
              valueWidget!
            else
              Text(value ?? '', style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700)),
            const SizedBox(height: 3),
            Text(label, style: TextStyle(
                fontSize: 10, color: scheme.onSurfaceVariant)),
          ],
        ),
      ),
    );
  }
}

class _Divider extends StatelessWidget {
  final ColorScheme scheme;
  const _Divider({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return VerticalDivider(
      width: 1, thickness: 0.5, color: scheme.outlineVariant);
  }
}

// ─── Habilidades ─────────────────────────────────────────────────

class _AbilitiesSection extends StatelessWidget {
  final List<PocketAbility> abilities;
  final ColorScheme         scheme;
  const _AbilitiesSection({required this.abilities, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Habilidade${abilities.length > 1 ? 's' : ''}',
            style: TextStyle(fontSize: 13, fontWeight: FontWeight.w700,
                color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        ...abilities.map<Widget>((a) => Container(
          margin: const EdgeInsets.only(bottom: 8),
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.purple.withOpacity(0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.purple.withOpacity(0.25), width: 1),
          ),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.purple.shade600,
                    borderRadius: BorderRadius.circular(4)),
                child: Text(a.type ?? 'Habilidade',
                    style: const TextStyle(color: Colors.white,
                        fontSize: 10, fontWeight: FontWeight.w700)),
              ),
              const SizedBox(width: 8),
              Expanded(child: Text(a.name, style: const TextStyle(
                  fontSize: 14, fontWeight: FontWeight.w700))),
            ]),
            if (a.effect != null && a.effect!.isNotEmpty) ...[
              const SizedBox(height: 6),
              Text(a.effect!, style: TextStyle(
                  fontSize: 13, color: scheme.onSurface.withOpacity(0.8), height: 1.4)),
            ],
          ]),
        )),
      ],
    );
  }
}

// ─── Ataques ──────────────────────────────────────────────────────

class _AttacksSection extends StatelessWidget {
  final List<PocketAttack> attacks;
  final ColorScheme        scheme;
  final bool               isDark;
  const _AttacksSection({required this.attacks, required this.scheme, required this.isDark});

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text('Ataques', style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Container(
          decoration: BoxDecoration(
            color: isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow,
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: scheme.outlineVariant, width: 0.5),
          ),
          child: Column(
            children: [
              for (int i = 0; i < attacks.length; i++) ...[
                _AttackRow(attack: attacks[i], scheme: scheme),
                if (i < attacks.length - 1)
                  Divider(height: 1, color: scheme.outlineVariant),
              ],
            ],
          ),
        ),
      ],
    );
  }
}

class _AttackRow extends StatelessWidget {
  final PocketAttack attack;
  final ColorScheme  scheme;
  const _AttackRow({required this.attack, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
      child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
        Row(children: [
          // Custo de energia
          if (attack.cost.isNotEmpty) ...[
            ...attack.cost.map<Widget>((c) => Padding(
              padding: const EdgeInsets.only(right: 4),
              child: _EnergyCostIcon(type: c),
            )),
            const SizedBox(width: 8),
          ],
          // Nome
          Expanded(child: Text(attack.name,
              style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
          // Dano
          if (attack.damage != null && attack.damage!.isNotEmpty)
            Text(attack.damage!, style: const TextStyle(
                fontSize: 18, fontWeight: FontWeight.w800)),
        ]),
        // Efeito
        if (attack.effect != null && attack.effect!.isNotEmpty) ...[
          const SizedBox(height: 4),
          Text(attack.effect!, style: TextStyle(
              fontSize: 12, color: scheme.onSurface.withOpacity(0.7), height: 1.4)),
        ],
      ]),
    );
  }
}

class _EnergyCostIcon extends StatelessWidget {
  final String type;
  const _EnergyCostIcon({required this.type});

  static const Map<String, Color> _colors = {
    'Fire': Color(0xFFF08030), 'Water': Color(0xFF6890F0),
    'Grass': Color(0xFF78C850), 'Electric': Color(0xFFF8D030),
    'Lightning': Color(0xFFF8D030), 'Psychic': Color(0xFFF85888),
    'Fighting': Color(0xFFC03028), 'Darkness': Color(0xFF705848),
    'Dark': Color(0xFF705848), 'Metal': Color(0xFFB8B8D0),
    'Steel': Color(0xFFB8B8D0), 'Colorless': Color(0xFFA8A878),
    'Dragon': Color(0xFF7038F8),
  };

  @override
  Widget build(BuildContext context) {
    final color = _colors[type] ?? const Color(0xFFA8A878);
    return Container(
      width: 20, height: 20,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.5), width: 0.5)),
      child: ClipOval(
        child: Image.asset('assets/types/${type.toLowerCase()}.png',
          fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(type.substring(0, 1),
              style: const TextStyle(color: Colors.white,
                  fontSize: 10, fontWeight: FontWeight.w800)))),
      ),
    );
  }
}

// ─── Efeito Trainer ───────────────────────────────────────────────

class _TrainerSection extends StatelessWidget {
  final String  effect;
  final String? trainerType;
  final ColorScheme scheme;
  const _TrainerSection({required this.effect, this.trainerType, required this.scheme});

  @override
  Widget build(BuildContext context) {
    String label;
    switch (trainerType?.toLowerCase()) {
      case 'item':      label = 'Item'; break;
      case 'supporter': label = 'Suporte'; break;
      case 'stadium':   label = 'Estádio'; break;
      case 'tool':      label = 'Ferramenta'; break;
      default:          label = trainerType ?? 'Efeito';
    }
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label, style: TextStyle(fontSize: 13,
            fontWeight: FontWeight.w700, color: scheme.onSurfaceVariant)),
        const SizedBox(height: 8),
        Container(
          width: double.infinity,
          padding: const EdgeInsets.all(12),
          decoration: BoxDecoration(
            color: Colors.teal.withOpacity(0.08),
            borderRadius: BorderRadius.circular(4),
            border: Border.all(color: Colors.teal.withOpacity(0.25), width: 1),
          ),
          child: Text(effect, style: TextStyle(
              fontSize: 13, color: scheme.onSurface.withOpacity(0.85), height: 1.5)),
        ),
      ],
    );
  }
}
