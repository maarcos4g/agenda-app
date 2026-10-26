import 'dart:convert';

import 'package:shared_preferences/shared_preferences.dart';
import 'package:test_app/models/contact_model.dart';

class ContactService {
  final SharedPreferencesAsync _storage = SharedPreferencesAsync();

  static const String _contactsKey = 'contacts';

  Future<List<ContactModel>> get() async {
    final json = await _storage.getString(_contactsKey);

    if (json == null) return [];

    final list = jsonDecode(json) as List<dynamic>;

    return list
        .map((item) => ContactModel.fromMap(item as Map<String, dynamic>))
        .toList();
  }

  Future<ContactModel> getByEmail(String email) async {
    final contacts = await get();
    final contact = contacts.firstWhere(
      (item) => item.email == email,
      orElse: () => throw StateError('Contato não encontrado'),
    );
    return contact;
  }

  Future<void> _saveContacts(List<ContactModel> contacts) async {
    final list = contacts.map((contact) => contact.toMap()).toList();
    await _storage.setString(_contactsKey, jsonEncode(list));
  }

  Future<void> add(ContactModel contact) async {
    final contacts = await get();
    if (contacts.any((item) => item.email == contact.email)) {
      throw StateError('Já existe contato com esse email');
    }
    contacts.add(contact);
    await _saveContacts(contacts);
  }

  Future<void> update(ContactModel contact) async {
    final contacts = await get();

    final index = contacts.indexWhere(
      (item) => item.email == contact.email
    );

    if (index.isNegative) {
      throw StateError('Contato não encontrado');
    }

    contacts[index] = contact;
    await _saveContacts(contacts);
  }

  Future<void> delete(ContactModel contact) async {
    final contacts = await get();

    contacts.removeWhere((item) => item.email == contact.email);
    await _saveContacts(contacts);
  }
}
