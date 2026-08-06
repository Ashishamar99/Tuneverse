import 'dart:convert';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_secure_storage/flutter_secure_storage.dart';

const _key = 'search_history';
const _maxItems = 20;

class SearchHistoryNotifier extends StateNotifier<List<String>> {
  final FlutterSecureStorage _storage;

  SearchHistoryNotifier(this._storage) : super([]) {
    _load();
  }

  Future<void> _load() async {
    final raw = await _storage.read(key: _key);
    if (raw != null) {
      state = List<String>.from(jsonDecode(raw));
    }
  }

  Future<void> _save() async {
    await _storage.write(key: _key, value: jsonEncode(state));
  }

  Future<void> add(String query) async {
    final trimmed = query.trim();
    if (trimmed.isEmpty) return;
    final updated = [trimmed, ...state.where((q) => q != trimmed)];
    state = updated.take(_maxItems).toList();
    await _save();
  }

  Future<void> remove(String query) async {
    state = state.where((q) => q != query).toList();
    await _save();
  }

  Future<void> clear() async {
    state = [];
    await _storage.delete(key: _key);
  }
}

final searchHistoryProvider =
    StateNotifierProvider<SearchHistoryNotifier, List<String>>(
  (ref) => SearchHistoryNotifier(const FlutterSecureStorage()),
);
