import 'package:flutter/material.dart';
import 'package:pokedex_tracker/services/tcg_pocket_service.dart';
import 'package:pokedex_tracker/screens/pocket/pocket_card_list_screen.dart';

// ─── Assets locais dos boosters ──────────────────────────────────
// Localização: assets/pocket/boosters/{setId}.png
// Use o script download_pocket_boosters.py para baixar todos os arquivos.
// Promos: P-A.png e P-B.png (logos dos sets de promo)

// Sets que usam tratamento especial de imagem (logo em vez de booster vertical)
const Set<String> _kPromoSets = {'P-A', 'P-B'};

class PocketHubScreen extends StatefulWidget {
  const PocketHubScreen({super.key});

  @override
  State<PocketHubScreen> createState() => _PocketHubScreenState();
}

class _PocketHubScreenState extends State<PocketHubScreen> {
  List<PocketSet> _sets = [];
  bool    _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _loadSets();
  }

  Future<void> _loadSets() async {
    setState(() { _loading = true; _error = null; });
    try {
      final sets = await TcgPocketService.fetchSeries();
      if (mounted) setState(() { _sets = sets; _loading = false; });
    } catch (_) {
      if (mounted) setState(() { _error = 'Erro ao carregar coleções'; _loading = false; });
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('TCG Pocket'),
        scrolledUnderElevation: 0,
        surfaceTintColor: Colors.transparent,
      ),
      body: _loading
          ? const _HubSkeleton()
          : _error != null
              ? _ErrorView(message: _error!, onRetry: _loadSets)
              : _SetGrid(sets: _sets),
    );
  }
}

// ─── Grid ─────────────────────────────────────────────────────────

class _SetGrid extends StatelessWidget {
  final List<PocketSet> sets;
  const _SetGrid({required this.sets});

  @override
  Widget build(BuildContext context) {
    if (sets.isEmpty) return const Center(child: Text('Nenhuma coleção encontrada'));
    return GridView.builder(
      padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
      gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
        crossAxisCount: 2, childAspectRatio: 0.82,
        crossAxisSpacing: 12, mainAxisSpacing: 12,
      ),
      itemCount: sets.length,
      itemBuilder: (_, i) => _SetBox(set: sets[i]),
    );
  }
}

// ─── Caixa de coleção ─────────────────────────────────────────────

class _SetBox extends StatelessWidget {
  final PocketSet set;
  const _SetBox({required this.set});

  @override
  Widget build(BuildContext context) {
    final meta     = kPocketSetMeta[set.id];
    final color1   = Color(meta?.color1 ?? 0xFF1A1A2E);
    final color2   = Color(meta?.color2 ?? 0xFF16213E);
    final isPromo  = _kPromoSets.contains(set.id);
    final assetPath = 'assets/pocket/boosters/${set.id}.png';

    return GestureDetector(
      onTap: () => Navigator.push(context, MaterialPageRoute(
        builder: (_) => PocketCardListScreen(setId: set.id, setName: set.name),
      )),
      child: Container(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(4),
          gradient: LinearGradient(
            begin: Alignment.topLeft, end: Alignment.bottomRight,
            colors: [color1, color2],
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(4),
          child: Stack(
            fit: StackFit.expand,
            children: [
              // ── Imagem de fundo ──────────────────────────────────
              isPromo
                  ? _PromoBackground(assetPath: assetPath, color1: color1, color2: color2)
                  : _BoosterBackground(assetPath: assetPath),

              // ── Overlay gradiente para legibilidade do texto ─────
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.38, 0.65, 1.0],
                      colors: [
                        Colors.black.withOpacity(0.72),
                        Colors.black.withOpacity(0.05),
                        Colors.black.withOpacity(0.20),
                        Colors.black.withOpacity(0.65),
                      ],
                    ),
                  ),
                ),
              ),

              // ── ID + Nome ─────────────────────────────────────────
              Positioned(
                top: 10, left: 10, right: 10,
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      set.id,
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w900,
                        color: Colors.white,
                        letterSpacing: 0.6,
                        shadows: [
                          Shadow(color: Colors.black, blurRadius: 6),
                          Shadow(color: Colors.black, blurRadius: 12),
                        ],
                      ),
                    ),
                    const SizedBox(height: 3),
                    Text(
                      set.name,
                      style: const TextStyle(
                        fontSize: 15,
                        fontWeight: FontWeight.w800,
                        color: Colors.white,
                        height: 1.2,
                        shadows: [
                          Shadow(color: Colors.black, blurRadius: 4, offset: Offset(0, 1)),
                          Shadow(color: Colors.black, blurRadius: 10),
                        ],
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}

// ─── Background de booster normal (vertical, zoom para cortar borda) ─

class _BoosterBackground extends StatelessWidget {
  final String assetPath;
  const _BoosterBackground({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
        alignment: const Alignment(0.0, -0.55),
        scale: 0.72,
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

// ─── Background de Promo (logo horizontal — foco no centro, zoom alto) ─

class _PromoBackground extends StatelessWidget {
  final String   assetPath;
  final Color    color1;
  final Color    color2;
  const _PromoBackground({
    required this.assetPath,
    required this.color1,
    required this.color2,
  });

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      // Zoom muito alto para recortar tudo exceto o emblema central
      // O logo das promos é horizontal — scale baixo + center = só o ícone
      child: OverflowBox(
        maxWidth: double.infinity,
        maxHeight: double.infinity,
        child: FractionallySizedBox(
          // 280% do tamanho da caixa — recorta completamente as bordas do logo
          widthFactor: 2.8,
          heightFactor: 2.8,
          child: Image.asset(
            assetPath,
            fit: BoxFit.contain,
            alignment: Alignment.center,
            errorBuilder: (_, __, ___) => const SizedBox.shrink(),
          ),
        ),
      ),
    );
  }
}

// ─── Skeleton ────────────────────────────────────────────────────

class _HubSkeleton extends StatefulWidget {
  const _HubSkeleton();
  @override State<_HubSkeleton> createState() => _HubSkeletonState();
}

class _HubSkeletonState extends State<_HubSkeleton>
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
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
        gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
          crossAxisCount: 2, childAspectRatio: 0.82,
          crossAxisSpacing: 12, mainAxisSpacing: 12,
        ),
        itemCount: 8,
        itemBuilder: (_, __) => Container(
          decoration: BoxDecoration(
            color: scheme.onSurface.withOpacity(_anim.value * 0.12),
            borderRadius: BorderRadius.circular(4),
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
  Widget build(BuildContext context) => Center(
    child: Column(mainAxisSize: MainAxisSize.min, children: [
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
    ]),
  );
}
