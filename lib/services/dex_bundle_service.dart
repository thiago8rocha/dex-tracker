import 'dart:convert';
import 'package:flutter/services.dart';

/// Lê as listas de pokémon de cada pokedex diretamente do bundle local
/// (assets/data/dex/dex_*.json) sem precisar de rede.
///
/// Formato dos arquivos:
/// {
///   "apiName": "galar",
///   "pokedexId": "sword___shield",
///   "displayName": "Sword / Shield",
///   "entries": [{"entryNumber": 1, "speciesId": 810}, ...]
/// }
class DexBundleService {
  static const String _basePath = 'assets/data/dex';

  static DexBundleService? _instance;
  static DexBundleService get instance =>
      _instance ??= DexBundleService._();
  DexBundleService._();

  // Cache em memória: apiName → lista de entries
  final Map<String, List<Map<String, int>>> _cache = {};

  /// Tenta carregar a dex do bundle para um dado apiName.
  /// Retorna null se o arquivo não existir no bundle.
  Future<List<Map<String, int>>?> loadSection(String apiName) async {
    if (_cache.containsKey(apiName)) return _cache[apiName];

    try {
      final raw = await rootBundle.loadString('$_basePath/dex_$apiName.json');
      final decoded = json.decode(raw) as Map<String, dynamic>;
      final rawEntries = decoded['entries'] as List<dynamic>;
      final entries = rawEntries.map((e) {
        final m = Map<String, dynamic>.from(e as Map);
        return {
          'entryNumber': m['entryNumber'] as int,
          'speciesId':   m['speciesId']   as int,
        };
      }).toList();
      _cache[apiName] = entries;
      return entries;
    } catch (_) {
      return null;
    }
  }

  /// Limpa o cache em memória (raramente necessário).
  void clearCache() => _cache.clear();
}