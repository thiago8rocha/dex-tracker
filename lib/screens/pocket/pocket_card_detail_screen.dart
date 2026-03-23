import 'package:flutter/material.dart';
import 'package:pokedex_tracker/services/tcg_pocket_service.dart';
import 'package:pokedex_tracker/screens/pocket/pocket_rarity_widget.dart';

// ─── TELA DE DETALHE ─────────────────────────────────────────────
// Recebe o PocketCardBrief da tela de lista (dados já disponíveis, sem fetch).
// A imagem alta qualidade é derivada da imageUrlLow trocando /low.webp → /high.webp.
// Dados extras (HP, ataques etc.) são buscados em background via fetchCard —
// se falhar, a tela ainda funciona mostrando o que já temos.

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
  // Dados extras vindos da API (opcionais — podem ser null se o fetch falhar)
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
        setId:   widget.setId,
        localId: localId0,
      );

      if (detail == null && localId0 != localId1) {
        detail = await TcgPocketService.fetchCard(
          '${widget.setId}-$localId1',
          setId:   widget.setId,
          localId: localId1,
        );
      }

      if (mounted) setState(() { _detail = detail; _loadingDetail = false; });
    } catch (_) {
      if (mounted) setState(() => _loadingDetail = false);
    }
  }

  // Imagem alta qualidade: troca /low.webp por /high.webp
  String? get _highImageUrl {
    final low = widget.card.imageUrlLow;
    if (low == null) return null;
    return low.replaceAll('/low.webp', '/high.webp');
  }

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Scaffold(
      appBar: AppBar(
        title: Text(widget.card.name),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [

            // ── 1. Imagem alta qualidade ──────────────────────────
            _CardImage(imageUrl: _highImageUrl ?? widget.card.imageUrlLow),
            const SizedBox(height: 20),

            // ── 2. Nome + raridade ────────────────────────────────
            _NameRarity(card: widget.card, detail: _detail),
            const SizedBox(height: 16),

            // ── 3. Número + stats (do detail se disponível) ───────
            _StatsRow(
              localId: widget.card.localId,
              detail:  _detail,
            ),
            const SizedBox(height: 16),

            // ── 4. Loading de dados extras ────────────────────────
            if (_loadingDetail)
              Center(
                child: Padding(
                  padding: const EdgeInsets.symmetric(vertical: 8),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      SizedBox(
                        width: 14, height: 14,
                        child: CircularProgressIndicator(strokeWidth: 2,
                            color: scheme.onSurfaceVariant),
                      ),
                      const SizedBox(width: 8),
                      Text('Carregando detalhes...',
                          style: TextStyle(fontSize: 12,
                              color: scheme.onSurfaceVariant)),
                    ],
                  ),
                ),
              ),

            // ── 5. Descrição ──────────────────────────────────────
            if (_detail?.description != null &&
                _detail!.description!.isNotEmpty) ...[
              _DescriptionCard(text: _detail!.description!),
              const SizedBox(height: 16),
            ],

            // ── 6. Habilidades ────────────────────────────────────
            if (_detail != null && _detail!.abilities.isNotEmpty) ...[
              _AbilitiesSection(abilities: _detail!.abilities),
              const SizedBox(height: 16),
            ],

            // ── 7. Ataques ────────────────────────────────────────
            if (_detail != null && _detail!.attacks.isNotEmpty) ...[
              _AttacksSection(attacks: _detail!.attacks),
              const SizedBox(height: 16),
            ],

            // ── 8. Efeito Trainer ─────────────────────────────────
            if (_detail != null &&
                _detail!.category == 'Trainer' &&
                _detail!.trainerEffect != null &&
                _detail!.trainerEffect!.isNotEmpty) ...[
              _TrainerEffectCard(
                effect:      _detail!.trainerEffect!,
                trainerType: _detail!.trainerType,
              ),
              const SizedBox(height: 16),
            ],
          ],
        ),
      ),
    );
  }
}

// ─── Imagem da carta ─────────────────────────────────────────────

class _CardImage extends StatelessWidget {
  final String? imageUrl;
  const _CardImage({this.imageUrl});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Center(
      child: ConstrainedBox(
        constraints: const BoxConstraints(maxWidth: 260),
        child: AspectRatio(
          aspectRatio: 0.714,
          child: Container(
            decoration: BoxDecoration(
              borderRadius: BorderRadius.circular(12),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.25),
                  blurRadius: 16,
                  offset: const Offset(0, 6),
                ),
              ],
            ),
            child: ClipRRect(
              borderRadius: BorderRadius.circular(12),
              child: imageUrl != null
                  ? Image.network(
                      imageUrl!,
                      fit: BoxFit.cover,
                      loadingBuilder: (_, child, progress) {
                        if (progress == null) return child;
                        return Container(
                          color: scheme.surfaceContainerHigh,
                          child: Center(
                            child: CircularProgressIndicator(
                              strokeWidth: 2,
                              value: progress.expectedTotalBytes != null
                                  ? progress.cumulativeBytesLoaded /
                                    progress.expectedTotalBytes!
                                  : null,
                            ),
                          ),
                        );
                      },
                      errorBuilder: (_, __, ___) => _ImagePlaceholder(scheme: scheme),
                    )
                  : _ImagePlaceholder(scheme: scheme),
            ),
          ),
        ),
      ),
    );
  }
}

class _ImagePlaceholder extends StatelessWidget {
  final ColorScheme scheme;
  const _ImagePlaceholder({required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Container(
      color: scheme.surfaceContainerHigh,
      child: Center(
        child: Icon(Icons.style_outlined, size: 64,
            color: scheme.onSurfaceVariant.withOpacity(0.3)),
      ),
    );
  }
}

// ─── Nome + tipo(s) + raridade ────────────────────────────────────

class _NameRarity extends StatelessWidget {
  final PocketCardBrief  card;
  final PocketCardDetail? detail;
  const _NameRarity({required this.card, this.detail});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;

    return Column(
      children: [
        Text(
          card.name,
          style: const TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
          textAlign: TextAlign.center,
        ),
        const SizedBox(height: 8),

        // Tipos (se disponíveis do detail)
        if (detail != null && detail!.types.isNotEmpty)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: detail!.types.map<Widget>((t) => Padding(
              padding: const EdgeInsets.symmetric(horizontal: 4),
              child: _TypeChip(typeName: t),
            )).toList(),
          ),

        const SizedBox(height: 8),

        // Raridade (disponível no brief)
        if (card.rarity != null)
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              PocketRarityBadge(rarity: card.rarity!, expanded: true),
              const SizedBox(width: 6),
              Text(card.rarity!,
                  style: TextStyle(fontSize: 12, color: scheme.onSurfaceVariant)),
            ],
          ),
      ],
    );
  }
}

// ─── Chip de tipo ─────────────────────────────────────────────────

class _TypeChip extends StatelessWidget {
  final String typeName;
  const _TypeChip({required this.typeName});

  static const Map<String, Color> _typeColors = {
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
    'Metal': 'Aço', 'Fairy': 'Fada', 'Colorless': 'Incolor',
    'Normal': 'Normal',
  };

  @override
  Widget build(BuildContext context) {
    final color = _typeColors[typeName] ?? const Color(0xFFA8A878);
    final label = _namePt[typeName] ?? typeName;
    final iconAsset = 'assets/types/${typeName.toLowerCase()}.png';

    return Container(
      height: 32,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(6),
      ),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Image.asset(iconAsset, width: 18, height: 18, fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => const SizedBox(width: 18)),
          const SizedBox(width: 6),
          Text(label, style: const TextStyle(
            color: Colors.white, fontSize: 13, fontWeight: FontWeight.w700)),
        ],
      ),
    );
  }
}

// ─── Linha de stats ───────────────────────────────────────────────

class _StatsRow extends StatelessWidget {
  final String          localId;
  final PocketCardDetail? detail;
  const _StatsRow({required this.localId, this.detail});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    final isDark = Theme.of(context).brightness == Brightness.dark;

    final items = <_StatItem>[
      _StatItem(label: 'Número', value: '#$localId'),
    ];

    if (detail != null) {
      if (detail!.stage != null)
        items.add(_StatItem(label: 'Estágio', value: _stageLabel(detail!.stage!)));
      if (detail!.hp != null)
        items.add(_StatItem(label: 'HP', value: '${detail!.hp}'));
      if (detail!.weaknessType != null) {
        final val = detail!.weaknessValue != null ? '+${detail!.weaknessValue}' : '';
        items.add(_StatItem(label: 'Fraqueza', value: '${detail!.weaknessType}$val'));
      }
      if (detail!.retreat != null)
        items.add(_StatItem(label: 'Recuo', value: '${detail!.retreat}'));
    }

    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 4),
      decoration: BoxDecoration(
        color: isDark ? scheme.surfaceContainerHigh : scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        children: items.map<Widget>((item) =>
          Column(mainAxisSize: MainAxisSize.min, children: [
            Text(item.value, style: const TextStyle(
                fontSize: 15, fontWeight: FontWeight.w700)),
            const SizedBox(height: 2),
            Text(item.label, style: TextStyle(
                fontSize: 10, color: scheme.onSurfaceVariant)),
          ])
        ).toList(),
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

class _StatItem {
  final String label; final String value;
  const _StatItem({required this.label, required this.value});
}

// ─── Descrição ────────────────────────────────────────────────────

class _DescriptionCard extends StatelessWidget {
  final String text;
  const _DescriptionCard({required this.text});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: scheme.surfaceContainerLow,
        borderRadius: BorderRadius.circular(4),
        border: Border.all(color: scheme.outlineVariant, width: 0.5),
      ),
      child: Text(text,
        style: TextStyle(fontSize: 13, fontStyle: FontStyle.italic,
            color: scheme.onSurfaceVariant, height: 1.5),
        textAlign: TextAlign.center),
    );
  }
}

// ─── Section card local ───────────────────────────────────────────

class _SectionCard extends StatelessWidget {
  final String title; final Color titleColor; final Widget child;
  const _SectionCard({required this.title, required this.titleColor, required this.child});

  @override
  Widget build(BuildContext context) {
    final scaffoldBg = Theme.of(context).scaffoldBackgroundColor;
    final cardBg     = titleColor.withOpacity(0.06);

    return Stack(
      clipBehavior: Clip.none,
      children: [
        Container(
          margin: const EdgeInsets.only(top: 14),
          width: double.infinity,
          padding: const EdgeInsets.fromLTRB(12, 20, 12, 12),
          decoration: BoxDecoration(
            color: cardBg,
            border: Border.all(color: titleColor.withOpacity(0.3), width: 1),
            borderRadius: BorderRadius.circular(4),
          ),
          child: child,
        ),
        Positioned(
          top: 0, left: 0, right: 0,
          child: Center(
            child: Container(
              padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
              decoration: BoxDecoration(
                color: scaffoldBg,
                border: Border.all(color: titleColor, width: 1.5),
                borderRadius: BorderRadius.circular(4),
              ),
              child: Text(title, style: TextStyle(
                fontSize: 13, fontWeight: FontWeight.w700,
                color: titleColor, letterSpacing: 0.3)),
            ),
          ),
        ),
      ],
    );
  }
}

// ─── Habilidades ─────────────────────────────────────────────────

class _AbilitiesSection extends StatelessWidget {
  final List<PocketAbility> abilities;
  const _AbilitiesSection({required this.abilities});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SectionCard(
      title: 'Habilidade${abilities.length > 1 ? 's' : ''}',
      titleColor: Colors.purple.shade400,
      child: Column(
        children: abilities.map<Widget>((a) => Padding(
          padding: const EdgeInsets.only(bottom: 4),
          child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
            Row(children: [
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
                decoration: BoxDecoration(
                    color: Colors.purple.shade400,
                    borderRadius: BorderRadius.circular(4)),
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
              Text(a.effect!, style: TextStyle(
                  fontSize: 13, color: scheme.onSurface.withOpacity(0.85), height: 1.45)),
            ],
          ]),
        )).toList(),
      ),
    );
  }
}

// ─── Ataques ──────────────────────────────────────────────────────

class _AttacksSection extends StatelessWidget {
  final List<PocketAttack> attacks;
  const _AttacksSection({required this.attacks});

  @override
  Widget build(BuildContext context) {
    final scheme = Theme.of(context).colorScheme;
    return _SectionCard(
      title: 'Ataques',
      titleColor: scheme.primary,
      child: Column(
        children: [
          for (int i = 0; i < attacks.length; i++) ...[
            _AttackRow(attack: attacks[i], scheme: scheme),
            if (i < attacks.length - 1)
              Divider(height: 20, color: scheme.outlineVariant),
          ],
        ],
      ),
    );
  }
}

class _AttackRow extends StatelessWidget {
  final PocketAttack attack;
  final ColorScheme  scheme;
  const _AttackRow({required this.attack, required this.scheme});

  @override
  Widget build(BuildContext context) {
    return Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
      Row(crossAxisAlignment: CrossAxisAlignment.center, children: [
        if (attack.cost.isNotEmpty) ...[
          Row(mainAxisSize: MainAxisSize.min,
            children: attack.cost.map<Widget>((c) => Padding(
              padding: const EdgeInsets.only(right: 3),
              child: _EnergyCost(type: c),
            )).toList(),
          ),
          const SizedBox(width: 8),
        ],
        Expanded(child: Text(attack.name,
            style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700))),
        if (attack.damage != null && attack.damage!.isNotEmpty)
          Text(attack.damage!,
              style: const TextStyle(fontSize: 18, fontWeight: FontWeight.w800)),
      ]),
      if (attack.effect != null && attack.effect!.isNotEmpty) ...[
        const SizedBox(height: 6),
        Text(attack.effect!, style: TextStyle(
            fontSize: 13, color: scheme.onSurface.withOpacity(0.8), height: 1.45)),
      ],
    ]);
  }
}

class _EnergyCost extends StatelessWidget {
  final String type;
  const _EnergyCost({required this.type});

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
    final color     = _colors[type] ?? const Color(0xFFA8A878);
    final iconAsset = 'assets/types/${type.toLowerCase()}.png';
    return Container(
      width: 20, height: 20,
      decoration: BoxDecoration(color: color, shape: BoxShape.circle,
          border: Border.all(color: Colors.white.withOpacity(0.6), width: 0.5)),
      child: ClipOval(
        child: Image.asset(iconAsset, fit: BoxFit.cover,
          errorBuilder: (_, __, ___) => Center(
            child: Text(type.substring(0, 1),
              style: const TextStyle(color: Colors.white,
                  fontSize: 10, fontWeight: FontWeight.w800)))),
      ),
    );
  }
}

// ─── Efeito Trainer ───────────────────────────────────────────────

class _TrainerEffectCard extends StatelessWidget {
  final String  effect;
  final String? trainerType;
  const _TrainerEffectCard({required this.effect, this.trainerType});

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
    return _SectionCard(
      title: label,
      titleColor: Colors.teal.shade400,
      child: Text(effect,
        style: TextStyle(fontSize: 13,
            color: Theme.of(context).colorScheme.onSurface.withOpacity(0.85),
            height: 1.5)),
    );
  }
}
