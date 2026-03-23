import 'package:flutter/material.dart';
import 'package:pokedex_tracker/services/tcg_pocket_service.dart';
import 'package:pokedex_tracker/screens/pocket/pocket_card_list_screen.dart';

// Sets que usam logo ao invés de booster vertical
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
    final meta    = kPocketSetMeta[set.id];
    final color1  = Color(meta?.color1 ?? 0xFF1A1A2E);
    final color2  = Color(meta?.color2 ?? 0xFF16213E);
    final isPromo = _kPromoSets.contains(set.id);
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
              if (isPromo)
                _PromoBackground(assetPath: assetPath)
              else
                _BoosterBackground(assetPath: assetPath),

              // ── Overlay para suavizar a imagem (deixá-la sutil) ──
              // + escurece topo (texto) e base (corta borda do pacote)
              Positioned.fill(
                child: DecoratedBox(
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topCenter,
                      end: Alignment.bottomCenter,
                      stops: const [0.0, 0.30, 0.55, 0.80, 1.0],
                      colors: [
                        // Topo — fundo escuro para o texto
                        Colors.black.withOpacity(0.68),
                        // Transição para a imagem
                        Colors.black.withOpacity(0.10),
                        // Centro — overlay sutil que aclara/suaviza
                        Colors.black.withOpacity(0.28),
                        // Base — escurece para cortar o nome do booster
                        Colors.black.withOpacity(0.55),
                        Colors.black.withOpacity(0.75),
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
                          Shadow(color: Colors.black, blurRadius: 14),
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

// ─── Booster vertical: zoom alto + alinhamento para cortar borda ──

class _BoosterBackground extends StatelessWidget {
  final String assetPath;
  const _BoosterBackground({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    // scale baixo = imagem renderizada maior = mais zoom
    // alignment negativo em Y = puxa imagem para cima, corta base
    return Positioned.fill(
      child: Image.asset(
        assetPath,
        fit: BoxFit.cover,
        alignment: const Alignment(0.0, -0.85),
        scale: 0.52, // era 0.72 — mais zoom para sumir com a borda do topo
        // Opacidade reduzida para imagem mais sutil
        opacity: const AlwaysStoppedAnimation(0.55),
        errorBuilder: (_, __, ___) => const SizedBox.shrink(),
      ),
    );
  }
}

// ─── Promo: logo transparente centralizado sobre o degradê ────────
// PNG com canal alpha — renderiza sobre o gradiente, centralizado e grande

class _PromoBackground extends StatelessWidget {
  final String assetPath;
  const _PromoBackground({required this.assetPath});

  @override
  Widget build(BuildContext context) {
    return Positioned.fill(
      child: Padding(
        // Padding negativo simulado via OverflowBox — amplia para fora
        padding: EdgeInsets.zero,
        child: OverflowBox(
          maxWidth: double.infinity,
          maxHeight: double.infinity,
          // widthFactor > 1 = a imagem ocupa mais que 100% da caixa
          // como o logo é horizontal (622x274), 1.6x preenche bem a caixa
          // e recorta as bordas laterais deixando só o emblema central
          child: FractionallySizedBox(
            widthFactor: 1.6,
            heightFactor: 1.6,
            child: Image.asset(
              assetPath,
              fit: BoxFit.contain,
              alignment: Alignment.center,
              // Opacidade sutil — logo transparente sobre o gradiente de cor
              opacity: const AlwaysStoppedAnimation(0.50),
              errorBuilder: (_, __, ___) => const SizedBox.shrink(),
            ),
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
