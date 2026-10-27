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
    if (contacts.any((item) => item.email.toLowerCase() == contact.email.toLowerCase())) {
      throw StateError('Já existe contato com esse email');
    }
    contacts.add(contact);
    await _saveContacts(contacts);
  }

  Future<void> update(ContactModel contact, {String? oldEmail}) async {
    final contacts = await get();

    final targetEmail = (oldEmail != null && oldEmail.isNotEmpty) ? oldEmail : contact.email;
    final index = contacts.indexWhere(
      (item) => item.email.toLowerCase() == targetEmail.toLowerCase(),
    );

    if (index.isNegative) {
      throw StateError('Contato não encontrado');
    }

    contacts[index] = contact;
    await _saveContacts(contacts);
  }

  Future<void> delete(ContactModel contact) async {
    final contacts = await get();

    contacts.removeWhere((item) => item.email.toLowerCase() == contact.email.toLowerCase());
    await _saveContacts(contacts);
  }

  Future<List<ContactModel>> search(String query) async {
    final contacts = await get();
    if (query.trim().isEmpty) return contacts;

    final q = query.toLowerCase().trim();
    return contacts.where((contact) {
      final nameMatches = contact.name.toLowerCase().contains(q);
      final emailMatches = contact.email.toLowerCase().contains(q);
      final phoneMatches = contact.phone.replaceAll(RegExp(r'\D'), '').contains(q.replaceAll(RegExp(r'\D'), '')) ||
          contact.phone.toLowerCase().contains(q);
      return nameMatches || emailMatches || phoneMatches;
    }).toList();
  }

  Future<List<ContactModel>> getFavorites() async {
    final contacts = await get();
    return contacts.where((c) => c.isFavorite == true).toList();
  }

  Future<List<ContactModel>> getByCategory(String category) async {
    final contacts = await get();
    return contacts.where((c) => c.categories.contains(category)).toList();
  }

  Future<List<ContactModel>> getByGroup(String group) async {
    final contacts = await get();
    return contacts.where((c) => c.groups.contains(group)).toList();
  }

  Future<List<ContactModel>> getBirthdaysOfMonth(int month) async {
    final contacts = await get();
    return contacts.where((c) {
      if (c.birthDate == null || c.birthDate!.isEmpty) return false;
      try {
        final parts = c.birthDate!.split('-');
        if (parts.length >= 2) {
          final m = int.tryParse(parts[1]);
          return m == month;
        }
      } catch (_) {}
      return false;
    }).toList();
  }

  Future<List<Map<String, dynamic>>> getUpcomingBirthdays({int daysAhead = 7}) async {
    final contacts = await get();
    final now = DateTime.now();
    final today = DateTime(now.year, now.month, now.day);
    final results = <Map<String, dynamic>>[];

    for (var contact in contacts) {
      if (contact.birthDate == null || contact.birthDate!.isEmpty) continue;
      try {
        final parts = contact.birthDate!.split('-');
        if (parts.length >= 3) {
          final month = int.tryParse(parts[1]);
          final day = int.tryParse(parts[2]);
          if (month == null || day == null) continue;

          var bdayThisYear = DateTime(today.year, month, day);
          if (bdayThisYear.isBefore(today)) {
            bdayThisYear = DateTime(today.year + 1, month, day);
          }

          final diffDays = bdayThisYear.difference(today).inDays;
          if (diffDays >= 0 && diffDays <= daysAhead) {
            results.add({
              'contact': contact,
              'daysRemaining': diffDays,
              'date': bdayThisYear,
            });
          }
        }
      } catch (_) {}
    }

    results.sort((a, b) => (a['daysRemaining'] as int).compareTo(b['daysRemaining'] as int));
    return results;
  }

  Future<List<ContactModel>> advancedSearch({
    String? category,
    String? city,
    String? company,
    bool? onlyFavorites,
    DateTime? createdAfter,
    DateTime? createdBefore,
  }) async {
    final contacts = await get();

    return contacts.where((c) {
      if (category != null && category.isNotEmpty) {
        if (!c.categories.contains(category)) return false;
      }
      if (city != null && city.trim().isNotEmpty) {
        if (c.city == null || !c.city!.toLowerCase().contains(city.trim().toLowerCase())) {
          return false;
        }
      }
      if (company != null && company.trim().isNotEmpty) {
        if (c.company == null || !c.company!.toLowerCase().contains(company.trim().toLowerCase())) {
          return false;
        }
      }
      if (onlyFavorites == true) {
        if (c.isFavorite != true) return false;
      }
      if (createdAfter != null && c.createdAt != null && c.createdAt!.isNotEmpty) {
        final dt = DateTime.tryParse(c.createdAt!);
        if (dt != null && dt.isBefore(createdAfter)) return false;
      }
      if (createdBefore != null && c.createdAt != null && c.createdAt!.isNotEmpty) {
        final dt = DateTime.tryParse(c.createdAt!);
        if (dt != null && dt.isAfter(createdBefore)) return false;
      }
      return true;
    }).toList();
  }

  Future<String> exportJson() async {
    final contacts = await get();
    final list = contacts.map((c) => c.toMap()).toList();
    return const JsonEncoder.withIndent('  ').convert(list);
  }

  Future<String> exportCsv() async {
    final contacts = await get();
    final buffer = StringBuffer();
    buffer.writeln('Nome,Email,Telefone,Favorito,Notas,Categorias,Grupos,Aniversario,Cidade,Empresa,DataCadastro');

    for (var c in contacts) {
      final safeName = '"${c.name.replaceAll('"', '""')}"';
      final safeEmail = '"${c.email.replaceAll('"', '""')}"';
      final safePhone = '"${c.phone.replaceAll('"', '""')}"';
      final safeNotes = '"${(c.notes ?? '').replaceAll('"', '""')}"';
      final safeCat = '"${c.categories.join(';').replaceAll('"', '""')}"';
      final safeGroups = '"${c.groups.join(';').replaceAll('"', '""')}"';
      final safeBday = '"${(c.birthDate ?? '').replaceAll('"', '""')}"';
      final safeCity = '"${(c.city ?? '').replaceAll('"', '""')}"';
      final safeComp = '"${(c.company ?? '').replaceAll('"', '""')}"';
      final safeCreated = '"${(c.createdAt ?? '').replaceAll('"', '""')}"';

      buffer.writeln(
        '$safeName,$safeEmail,$safePhone,${c.isFavorite == true},$safeNotes,$safeCat,$safeGroups,$safeBday,$safeCity,$safeComp,$safeCreated',
      );
    }
    return buffer.toString();
  }

  Future<int> importJson(String jsonStr) async {
    final dynamic decoded = jsonDecode(jsonStr);
    if (decoded is! List) return 0;

    final contacts = await get();
    var count = 0;

    for (var item in decoded) {
      if (item is Map<String, dynamic>) {
        final contact = ContactModel.fromMap(item);
        final index = contacts.indexWhere(
          (c) => c.email.toLowerCase() == contact.email.toLowerCase(),
        );
        if (index >= 0) {
          contacts[index] = contact;
        } else {
          contacts.add(contact);
        }
        count++;
      }
    }

    await _saveContacts(contacts);
    return count;
  }

  Future<int> importCsv(String csvStr) async {
    final lines = const LineSplitter().convert(csvStr);
    if (lines.length <= 1) return 0;

    final contacts = await get();
    var count = 0;

    for (var i = 1; i < lines.length; i++) {
      final line = lines[i].trim();
      if (line.isEmpty) continue;

      final cols = _parseCsvLine(line);
      if (cols.length < 3) continue;

      final name = cols.isNotEmpty ? cols[0] : '';
      final email = cols.length > 1 ? cols[1] : '';
      final phone = cols.length > 2 ? cols[2] : '';
      final isFav = cols.length > 3 ? cols[3].toLowerCase() == 'true' : false;
      final notes = cols.length > 4 ? cols[4] : '';
      final categories = cols.length > 5 && cols[5].isNotEmpty ? cols[5].split(';') : <String>[];
      final groups = cols.length > 6 && cols[6].isNotEmpty ? cols[6].split(';') : <String>[];
      final birthDate = cols.length > 7 ? cols[7] : '';
      final city = cols.length > 8 ? cols[8] : '';
      final company = cols.length > 9 ? cols[9] : '';

      if (name.isEmpty || email.isEmpty) continue;

      final contact = ContactModel(
        name: name,
        email: email,
        phone: phone,
        isFavorite: isFav,
        notes: notes,
        categories: categories,
        groups: groups,
        birthDate: birthDate,
        city: city,
        company: company,
        createdAt: DateTime.now().toIso8601String(),
      );

      final index = contacts.indexWhere((c) => c.email.toLowerCase() == email.toLowerCase());
      if (index >= 0) {
        contacts[index] = contact;
      } else {
        contacts.add(contact);
      }
      count++;
    }

    await _saveContacts(contacts);
    return count;
  }

  List<String> _parseCsvLine(String line) {
    final result = <String>[];
    final sb = StringBuffer();
    var inQuotes = false;

    for (var i = 0; i < line.length; i++) {
      final char = line[i];
      if (char == '"') {
        if (inQuotes && i + 1 < line.length && line[i + 1] == '"') {
          sb.write('"');
          i++;
        } else {
          inQuotes = !inQuotes;
        }
      } else if (char == ',' && !inQuotes) {
        result.add(sb.toString().trim());
        sb.clear();
      } else {
        sb.write(char);
      }
    }
    result.add(sb.toString().trim());
    return result;
  }

  Future<void> clearAll() async {
    await _storage.remove(_contactsKey);
  }

  Future<void> loadDemoContacts() async {
    final now = DateTime.now();
    final currentMonth = now.month.toString().padLeft(2, '0');
    final nextMonth = ((now.month % 12) + 1).toString().padLeft(2, '0');
    final todayDay = now.day.toString().padLeft(2, '0');

    final demo = [
      ContactModel(
        name: 'Ana Carolina Silva',
        email: 'ana.silva@email.com',
        phone: '(11) 98765-4321',
        isFavorite: true,
        imagePath: 'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
        notes: 'Coordenadora de Projetos. Melhor contato no período da tarde.',
        categories: ['Trabalho', 'Amigos'],
        groups: ['Projeto Mobile', 'Faculdade'],
        birthDate: '1992-$currentMonth-$todayDay', // Aniversário hoje!
        city: 'São Paulo',
        company: 'Tech Solutions',
        createdAt: DateTime.now().subtract(const Duration(days: 45)).toIso8601String(),
      ),
      ContactModel(
        name: 'Carlos Eduardo Santos',
        email: 'carlos.eduardo@gmail.com',
        phone: '(21) 99887-6655',
        isFavorite: true,
        imagePath: 'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
        notes: 'Primo. Mora no Rio de Janeiro.',
        categories: ['Família'],
        groups: ['Família Silva'],
        birthDate: '1988-$currentMonth-28',
        city: 'Rio de Janeiro',
        company: 'Autônomo',
        createdAt: DateTime.now().subtract(const Duration(days: 30)).toIso8601String(),
      ),
      ContactModel(
        name: 'Beatriz Martins',
        email: 'beatriz.martins@cliente.com',
        phone: '(31) 97654-3210',
        isFavorite: false,
        imagePath: 'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
        notes: 'Cliente chave da conta corporativa de Belo Horizonte.',
        categories: ['Clientes', 'Trabalho'],
        groups: ['Clientes Corporativos'],
        birthDate: '1995-$nextMonth-15',
        city: 'Belo Horizonte',
        company: 'Inovação Minas',
        createdAt: DateTime.now().subtract(const Duration(days: 20)).toIso8601String(),
      ),
      ContactModel(
        name: 'Danilo Alcantara',
        email: 'danilo.alcantara@futebol.com',
        phone: '(19) 98112-3344',
        isFavorite: false,
        imagePath: 'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
        notes: 'Goleiro do time de futebol de quinta-feira.',
        categories: ['Amigos'],
        groups: ['Futebol Quinta'],
        birthDate: '1990-05-12',
        city: 'Campinas',
        company: 'Agência Digital',
        createdAt: DateTime.now().subtract(const Duration(days: 10)).toIso8601String(),
      ),
      ContactModel(
        name: 'Fernanda Lima Souza',
        email: 'fernanda.lima@advocacia.com',
        phone: '(41) 99223-4455',
        isFavorite: true,
        imagePath: 'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
        notes: 'Consultora jurídica para novos contratos.',
        categories: ['Trabalho', 'Clientes'],
        groups: ['Projeto Mobile'],
        birthDate: '1986-$currentMonth-30',
        city: 'Curitiba',
        company: 'Lima Advocacia',
        createdAt: DateTime.now().subtract(const Duration(days: 5)).toIso8601String(),
      ),
    ];

    await _saveContacts(demo);
  }
}
