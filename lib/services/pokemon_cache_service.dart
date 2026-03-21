import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

/// Cache persistente para dados da PokeAPI.
/// Os dados de Pokémon são essencialmente estáticos — não mudam em tempo real.
/// TTL de 30 dias evita chamadas repetidas e garante que atualizações
/// ocasionais da API ainda sejam buscadas ao longo do tempo.
class PokemonCacheService {
  static const int _ttlDays = 30;

  // Prefixos de chave no SharedPreferences
  static const String _prefixPokemon  = 'pkcache_pokemon_';
  static const String _prefixSpecies  = 'pkcache_species_';
  static const String _prefixAbility  = 'pkcache_ability_';
  static const String _prefixEvo      = 'pkcache_evo_';
  static const String _prefixTranslation = 'pkcache_trans_';

  // Singleton leve
  static PokemonCacheService? _instance;
  static PokemonCacheService get instance =>
      _instance ??= PokemonCacheService._();
  PokemonCacheService._();

  SharedPreferences? _prefs;
  Future<SharedPreferences> get _p async =>
      _prefs ??= await SharedPreferences.getInstance();

  // ─── Helpers internos ───────────────────────────────────────────

  String _tsKey(String dataKey) => '${dataKey}_ts';

  bool _isExpired(int? timestampMs) {
    if (timestampMs == null) return true;
    final age = DateTime.now().millisecondsSinceEpoch - timestampMs;
    return age > _ttlDays * 24 * 60 * 60 * 1000;
  }

  Future<Map<String, dynamic>?> _get(String key) async {
    final p = await _p;
    final ts = p.getInt(_tsKey(key));
    if (_isExpired(ts)) return null;
    final raw = p.getString(key);
    if (raw == null) return null;
    try {
      return json.decode(raw) as Map<String, dynamic>;
    } catch (_) {
      return null;
    }
  }

  Future<void> _set(String key, Map<String, dynamic> data) async {
    final p = await _p;
    await p.setString(key, json.encode(data));
    await p.setInt(_tsKey(key), DateTime.now().millisecondsSinceEpoch);
  }

  // ─── API pública ────────────────────────────────────────────────

  /// Dados de /pokemon/{id}
  Future<Map<String, dynamic>?> getPokemon(int id) =>
      _get('$_prefixPokemon$id');

  Future<void> setPokemon(int id, Map<String, dynamic> data) =>
      _set('$_prefixPokemon$id', data);

  /// Dados de /pokemon-species/{id}
  Future<Map<String, dynamic>?> getSpecies(int id) =>
      _get('$_prefixSpecies$id');

  Future<void> setSpecies(int id, Map<String, dynamic> data) =>
      _set('$_prefixSpecies$id', data);

  /// Dados de /ability/{url} — chave = url completo
  Future<Map<String, dynamic>?> getAbility(String url) =>
      _get('$_prefixAbility${url.hashCode}');

  Future<void> setAbility(String url, Map<String, dynamic> data) =>
      _set('$_prefixAbility${url.hashCode}', data);

  /// Dados de /evolution-chain/{url} — chave = url completo
  Future<Map<String, dynamic>?> getEvoChain(String url) =>
      _get('$_prefixEvo${url.hashCode}');

  Future<void> setEvoChain(String url, Map<String, dynamic> data) =>
      _set('$_prefixEvo${url.hashCode}', data);

  /// Tradução de flavor text — chave = hash do texto original
  Future<String?> getTranslation(String originalText) async {
    final p = await _p;
    final key = '$_prefixTranslation${originalText.hashCode}';
    final ts = p.getInt(_tsKey(key));
    if (_isExpired(ts)) return null;
    return p.getString(key);
  }

  Future<void> setTranslation(String originalText, String translated) async {
    final p = await _p;
    final key = '$_prefixTranslation${originalText.hashCode}';
    await p.setString(key, translated);
    await p.setInt(_tsKey(key), DateTime.now().millisecondsSinceEpoch);
  }

  /// Limpa todo o cache (para debug ou reset manual)
  Future<void> clearAll() async {
    final p = await _p;
    final keys = p.getKeys()
        .where((k) => k.startsWith('pkcache_'))
        .toList();
    for (final k in keys) await p.remove(k);
  }
}