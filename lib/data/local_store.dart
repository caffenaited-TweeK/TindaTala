import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';

import 'models.dart';

abstract interface class StoreRepository {
  Future<StoreData> load();
  Future<void> save(StoreData data);
}

class LocalStoreRepository implements StoreRepository {
  LocalStoreRepository({SharedPreferencesAsync? preferences})
    : _preferences = preferences ?? SharedPreferencesAsync();

  static const _storageKey = 'tindatala.store.snapshot.v1';

  final SharedPreferencesAsync _preferences;

  @override
  Future<StoreData> load() async {
    final savedData = await _preferences.getString(_storageKey);
    if (savedData == null) return const StoreData();

    try {
      final decoded = jsonDecode(savedData) as Map<String, Object?>;
      return StoreData.fromJson(decoded);
    } on FormatException catch (error) {
      throw FormatException(
        'Saved TindaTala data could not be read. Your saved data has not been overwritten. $error',
      );
    } on TypeError catch (error) {
      throw FormatException(
        'Saved TindaTala data has an unexpected format. Your saved data has not been overwritten. $error',
      );
    }
  }

  @override
  Future<void> save(StoreData data) async {
    await _preferences.setString(_storageKey, jsonEncode(data.toJson()));
  }
}
