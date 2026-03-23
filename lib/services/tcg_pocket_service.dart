import 'dart:convert';
import 'package:http/http.dart' as http;

// ─── CONSTANTES ──────────────────────────────────────────────────

const String _kBase   = 'https://api.tcgdex.net/v2/en';
const String _kAssets = 'https://assets.tcgdex.net/en';

// Ordem de exibição dos sets Pocket (mais recentes por último no fallback)
const List<String> kPocketSetOrder = [
  'A1', 'A1a',
  'A2', 'A2a', 'A2b',
  'A3', 'A3a', 'A3b',
  'A4', 'A4a', 'A4b',
  'B1',
  'P-A',
];

// Metadados estáticos — nomes em PT-BR + cores da caixa + booster principal
const Map<String, PocketSetMeta> kPocketSetMeta = {
  'A1':  PocketSetMeta(id: 'A1',  namePt: 'Dominação Genética',     nameEn: 'Genetic Apex',            releaseDate: '2024-10-30', color1: 0xFF7038F8, color2: 0xFFF08030),
  'A1a': PocketSetMeta(id: 'A1a', namePt: 'Ilha Mítica',            nameEn: 'Mythical Island',          releaseDate: '2024-12-17', color1: 0xFF78C850, color2: 0xFF29B6F6),
  'A2':  PocketSetMeta(id: 'A2',  namePt: 'Embate do Tempo e Espaço', nameEn: 'Space-Time Smackdown', releaseDate: '2025-01-30', color1: 0xFF29B6F6, color2: 0xFFB8A038),
  'A2a': PocketSetMeta(id: 'A2a', namePt: 'Luz Triunfante',         nameEn: 'Triumphant Light',        releaseDate: '2025-03-27', color1: 0xFFF8D030, color2: 0xFFFFFFFF),
  'A2b': PocketSetMeta(id: 'A2b', namePt: 'Brilho Deslumbrante',    nameEn: 'Shining Revelry',         releaseDate: '2025-04-30', color1: 0xFFEE99AC, color2: 0xFF98D8D8),
  'A3':  PocketSetMeta(id: 'A3',  namePt: 'Guardiões Celestiais',   nameEn: 'Celestial Guardians',     releaseDate: '2025-03-06', color1: 0xFFF8D030, color2: 0xFF7038F8),
  'A3a': PocketSetMeta(id: 'A3a', namePt: 'Bosque de Eevee',        nameEn: 'Eevee Grove',             releaseDate: '2025-05-29', color1: 0xFF78C850, color2: 0xFFE0C068),
  'A3b': PocketSetMeta(id: 'A3b', namePt: 'Bosque de Eevee',        nameEn: 'Eevee Grove',             releaseDate: '2025-05-29', color1: 0xFF78C850, color2: 0xFFEE99AC),
  'A4':  PocketSetMeta(id: 'A4',  namePt: 'Sabedoria do Mar e do Céu', nameEn: 'Wisdom of Sea and Sky', releaseDate: '2025-07-03', color1: 0xFF6890F0, color2: 0xFF98D8D8),
  'A4a': PocketSetMeta(id: 'A4a', namePt: 'Fontes Isoladas',        nameEn: 'Secluded Springs',        releaseDate: '2025-08-21', color1: 0xFF78C850, color2: 0xFF6890F0),
  'A4b': PocketSetMeta(id: 'A4b', namePt: 'Pack Deluxe ex',         nameEn: 'Deluxe Pack ex',          releaseDate: '2025-09-18', color1: 0xFFF08030, color2: 0xFFF8D030),
  'B1':  PocketSetMeta(id: 'B1',  namePt: 'Ascensão Mega',          nameEn: 'Mega Rising',             releaseDate: '2025-10-16', color1: 0xFFC03028, color2: 0xFF7038F8),
  'P-A': PocketSetMeta(id: 'P-A', namePt: 'Promos-A',               nameEn: 'Promo-A Cards',           releaseDate: '2024-10-30', color1: 0xFF705898, color2: 0xFFA8A878),
};

// ─── META ─────────────────────────────────────────────────────────

class PocketSetMeta {
  final String id;
  final String namePt;
  final String nameEn;
  final String releaseDate;
  final int    color1; // cor primária da caixa
  final int    color2; // cor secundária da caixa

  const PocketSetMeta({
    required this.id,
    required this.namePt,
    required this.nameEn,
    required this.releaseDate,
    required this.color1,
    required this.color2,
  });
}

// ─── MODELOS ──────────────────────────────────────────────────────

class PocketSet {
  final String id;
  final String name;       // nome PT se disponível, senão EN
  final String? logoUrl;
  final String? releaseDate;
  final int     totalCards;
  final List<PocketCardBrief> cards;

  const PocketSet({
    required this.id,
    required this.name,
    this.logoUrl,
    this.releaseDate,
    required this.totalCards,
    required this.cards,
  });

  factory PocketSet.fromJson(Map<String, dynamic> json, {String? overrideName}) {
    final cardCount = json['cardCount'] as Map<String, dynamic>?;
    final cardList  = (json['cards'] as List<dynamic>?) ?? [];

    final cards = cardList
        .map((c) => PocketCardBrief.fromJson(c as Map<String, dynamic>))
        .toList()
      ..sort((a, b) {
          final an = int.tryParse(a.localId) ?? 9999;
          final bn = int.tryParse(b.localId) ?? 9999;
          return an.compareTo(bn);
        });

    return PocketSet(
      id:          json['id'] as String,
      name:        overrideName ?? (json['name'] as String),
      logoUrl:     json['logo'] as String?,
      releaseDate: json['releaseDate'] as String?,
      totalCards:  cardCount?['official'] as int? ?? cards.length,
      cards:       cards,
    );
  }
}

// ─── Card brief (listagem) ────────────────────────────────────────

class PocketCardBrief {
  final String  id;
  final String  localId;
  final String  name;
  final String? imageUrlLow;
  final String? rarity;

  const PocketCardBrief({
    required this.id,
    required this.localId,
    required this.name,
    this.imageUrlLow,
    this.rarity,
  });

  factory PocketCardBrief.fromJson(Map<String, dynamic> json) {
    final raw = json['image'] as String?;
    return PocketCardBrief(
      id:          json['id'] as String,
      localId:     json['localId']?.toString() ?? '',
      name:        json['name'] as String,
      imageUrlLow: raw != null ? '$raw/low.webp' : null,
      rarity:      json['rarity'] as String?,
    );
  }
}

// ─── Card detail (detalhe) ───────────────────────────────────────

class PocketAttack {
  final String       name;
  final String?      damage;
  final String?      effect;
  final List<String> cost;

  const PocketAttack({
    required this.name,
    this.damage,
    this.effect,
    required this.cost,
  });

  factory PocketAttack.fromJson(Map<String, dynamic> json) {
    final costRaw = (json['cost'] as List<dynamic>?) ?? [];
    return PocketAttack(
      name:   json['name'] as String,
      damage: json['damage']?.toString(),
      effect: json['effect'] as String?,
      cost:   costRaw.map((e) => e.toString()).toList(),
    );
  }
}

class PocketAbility {
  final String  name;
  final String? effect;
  final String? type;

  const PocketAbility({
    required this.name,
    this.effect,
    this.type,
  });

  factory PocketAbility.fromJson(Map<String, dynamic> json) {
    return PocketAbility(
      name:   json['name'] as String,
      effect: json['effect'] as String?,
      type:   json['type'] as String?,
    );
  }
}

class PocketCardDetail {
  final String              id;
  final String              localId;
  final String              name;
  final String?             imageUrlHigh;
  final String?             rarity;
  final String?             category;
  final int?                hp;
  final List<String>        types;
  final String?             stage;
  final String?             evolveFrom;
  final String?             description;
  final List<PocketAttack>  attacks;
  final List<PocketAbility> abilities;
  final String?             weaknessType;
  final int?                weaknessValue;
  final int?                retreat;
  final String?             trainerEffect;
  final String?             trainerType;

  const PocketCardDetail({
    required this.id,
    required this.localId,
    required this.name,
    this.imageUrlHigh,
    this.rarity,
    this.category,
    this.hp,
    required this.types,
    this.stage,
    this.evolveFrom,
    this.description,
    required this.attacks,
    required this.abilities,
    this.weaknessType,
    this.weaknessValue,
    this.retreat,
    this.trainerEffect,
    this.trainerType,
  });

  factory PocketCardDetail.fromJson(Map<String, dynamic> json) {
    final raw        = json['image'] as String?;
    final typesRaw   = (json['types']     as List<dynamic>?) ?? [];
    final attacksRaw = (json['attacks']   as List<dynamic>?) ?? [];
    final abilitRaw  = (json['abilities'] as List<dynamic>?) ?? [];
    final weaknesses = (json['weaknesses'] as List<dynamic>?) ?? [];

    String? weakType;
    int?    weakVal;
    if (weaknesses.isNotEmpty) {
      final w = weaknesses.first as Map<String, dynamic>;
      weakType = w['type'] as String?;
      weakVal  = w['value'] as int?;
    }

    return PocketCardDetail(
      id:           json['id'] as String,
      localId:      json['localId']?.toString() ?? '',
      name:         json['name'] as String,
      imageUrlHigh: raw != null ? '$raw/high.webp' : null,
      rarity:       json['rarity'] as String?,
      category:     json['category'] as String?,
      hp:           json['hp'] as int?,
      types:        typesRaw.map((e) => e.toString()).toList(),
      stage:        json['stage'] as String?,
      evolveFrom:   json['evolveFrom'] as String?,
      description:  json['description'] as String?,
      attacks:      attacksRaw.map((a) => PocketAttack.fromJson(a as Map<String, dynamic>)).toList(),
      abilities:    abilitRaw.map((a)  => PocketAbility.fromJson(a as Map<String, dynamic>)).toList(),
      weaknessType:  weakType,
      weaknessValue: weakVal,
      retreat:       json['retreat'] as int?,
      trainerEffect: json['effect'] as String?,
      trainerType:   json['trainerType'] as String?,
    );
  }
}

// ─── SERVIÇO ──────────────────────────────────────────────────────

class TcgPocketService {
  static const Duration _timeout = Duration(seconds: 12);

  static List<PocketSet>?                    _seriesCache;
  static final Map<String, PocketSet>        _setCache  = {};
  static final Map<String, PocketCardDetail> _cardCache = {};

  /// Busca todos os sets da série tcgp
  static Future<List<PocketSet>> fetchSeries() async {
    if (_seriesCache != null) return _seriesCache!;

    try {
      final res = await http
          .get(Uri.parse('$_kBase/series/tcgp'))
          .timeout(_timeout);

      if (res.statusCode != 200) return _fallbackSeries();

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final raw  = (json['sets'] as List<dynamic>?) ?? [];

      final sets = <PocketSet>[];
      for (final s in raw) {
        final map  = s as Map<String, dynamic>;
        final id   = map['id'] as String;
        final meta = kPocketSetMeta[id];
        sets.add(PocketSet(
          id:          id,
          name:        meta?.namePt ?? (map['name'] as String),
          logoUrl:     map['logo'] as String?,
          releaseDate: meta?.releaseDate,
          totalCards:  0,
          cards:       [],
        ));
      }

      // Deduplicar por id (a API às vezes retorna duplicatas)
      final seen = <String>{};
      final deduped = sets.where((s) => seen.add(s.id)).toList();

      // Ordenar pela lista definida
      deduped.sort((a, b) {
        int ai = kPocketSetOrder.indexOf(a.id);
        int bi = kPocketSetOrder.indexOf(b.id);
        if (ai == -1) ai = 999;
        if (bi == -1) bi = 999;
        return ai.compareTo(bi);
      });

      _seriesCache = deduped;
      return deduped;
    } catch (_) {
      return _fallbackSeries();
    }
  }

  static List<PocketSet> _fallbackSeries() {
    return kPocketSetOrder
        .where(kPocketSetMeta.containsKey)
        .map((id) {
          final meta = kPocketSetMeta[id]!;
          return PocketSet(
            id:          meta.id,
            name:        meta.namePt,
            releaseDate: meta.releaseDate,
            totalCards:  0,
            cards:       [],
          );
        })
        .toList();
  }

  /// Busca um set completo com lista de cartas
  static Future<PocketSet?> fetchSet(String setId) async {
    if (_setCache.containsKey(setId)) return _setCache[setId];

    try {
      final res = await http
          .get(Uri.parse('$_kBase/sets/$setId'))
          .timeout(_timeout);

      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final set  = PocketSet.fromJson(
        json,
        overrideName: kPocketSetMeta[setId]?.namePt,
      );
      _setCache[setId] = set;
      return set;
    } catch (_) {
      return null;
    }
  }

  /// Busca detalhes completos de uma carta
  static Future<PocketCardDetail?> fetchCard(String cardId) async {
    if (_cardCache.containsKey(cardId)) return _cardCache[cardId];

    try {
      final res = await http
          .get(Uri.parse('$_kBase/cards/$cardId'))
          .timeout(_timeout);

      if (res.statusCode != 200) return null;

      final json = jsonDecode(res.body) as Map<String, dynamic>;
      final card = PocketCardDetail.fromJson(json);
      _cardCache[cardId] = card;
      return card;
    } catch (_) {
      return null;
    }
  }

  /// URL do booster/logo do set para imagem de fundo
  static String boosterImageUrl(String setId) =>
      '$_kAssets/tcgp/$setId/logo.png';

  static void clearCache() {
    _seriesCache = null;
    _setCache.clear();
    _cardCache.clear();
  }
}
