import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class GroupService {
  final SharedPreferencesAsync _storage = SharedPreferencesAsync();
  static const String _groupsKey = 'groups_list';

  static const List<String> defaultGroups = [
    'Projeto Mobile',
    'Família Silva',
    'Futebol Quinta',
    'Faculdade',
    'Clientes Corporativos',
  ];

  Future<List<String>> getGroups() async {
    final json = await _storage.getString(_groupsKey);
    if (json == null) {
      await _save(defaultGroups);
      return List<String>.from(defaultGroups);
    }
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => e.toString()).toList();
  }

  Future<void> _save(List<String> list) async {
    await _storage.setString(_groupsKey, jsonEncode(list));
  }

  Future<void> addGroup(String group) async {
    final trimmed = group.trim();
    if (trimmed.isEmpty) return;

    final groups = await getGroups();
    if (!groups.any((g) => g.toLowerCase() == trimmed.toLowerCase())) {
      groups.add(trimmed);
      await _save(groups);
    }
  }

  Future<void> deleteGroup(String group) async {
    final groups = await getGroups();
    groups.removeWhere((g) => g.toLowerCase() == group.toLowerCase());
    await _save(groups);
  }
}
