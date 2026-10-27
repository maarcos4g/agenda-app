import 'dart:convert';
import 'package:shared_preferences/shared_preferences.dart';

class CategoryService {
  final SharedPreferencesAsync _storage = SharedPreferencesAsync();
  static const String _categoriesKey = 'categories_list';

  static const List<String> defaultCategories = [
    'Família',
    'Amigos',
    'Trabalho',
    'Clientes',
  ];

  Future<List<String>> getCategories() async {
    final json = await _storage.getString(_categoriesKey);
    if (json == null) {
      // Inicializar com categorias padrão se primeira vez
      await _save(defaultCategories);
      return List<String>.from(defaultCategories);
    }
    final list = jsonDecode(json) as List<dynamic>;
    return list.map((e) => e.toString()).toList();
  }

  Future<void> _save(List<String> list) async {
    await _storage.setString(_categoriesKey, jsonEncode(list));
  }

  Future<void> addCategory(String category) async {
    final trimmed = category.trim();
    if (trimmed.isEmpty) return;

    final categories = await getCategories();
    if (!categories.any((c) => c.toLowerCase() == trimmed.toLowerCase())) {
      categories.add(trimmed);
      await _save(categories);
    }
  }

  Future<void> deleteCategory(String category) async {
    final categories = await getCategories();
    categories.removeWhere((c) => c.toLowerCase() == category.toLowerCase());
    await _save(categories);
  }
}
