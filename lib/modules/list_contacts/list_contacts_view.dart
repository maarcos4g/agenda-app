import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:test_app/models/contact_model.dart';
import 'package:test_app/modules/add_contact/add_contact_view.dart';
import 'package:test_app/modules/contact_details/contact_details_view.dart';
import 'package:test_app/modules/edit_contact/edit_contact_view.dart';
import 'package:test_app/services/contacts_service.dart';

class ListContactsView extends StatefulWidget {
  const ListContactsView({super.key});

  @override
  State<ListContactsView> createState() => _ListContactsViewState();
}

class _ListContactsViewState extends State<ListContactsView> {
  final service = ContactService();
  final searchController = TextEditingController();

  List<ContactModel> _contacts = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final list = _searchQuery.isEmpty
        ? await service.get()
        : await service.search(_searchQuery);
    setState(() {
      _contacts = list;
      _isLoading = false;
    });
  }

  void _onSearchChanged(String value) {
    setState(() {
      _searchQuery = value;
    });
    _loadContacts();
  }

  Map<String, List<ContactModel>> get _groupedContacts {
    final Map<String, List<ContactModel>> grouped = {};

    for (var contact in _contacts) {
      final name = contact.name.trim();
      if (name.isEmpty) continue;

      final firstLetter = name[0].toUpperCase();
      if (!grouped.containsKey(firstLetter)) {
        grouped[firstLetter] = [];
      }
      grouped[firstLetter]!.add(contact);
    }

    grouped.forEach((key, list) {
      list.sort((a, b) => a.name.toLowerCase().compareTo(b.name.toLowerCase()));
    });

    return grouped;
  }

  Future<void> _openDetails(ContactModel contact) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailsView(contact: contact),
      ),
    );
    _loadContacts();
  }

  Future<void> _openEdit(ContactModel contact) async {
    final updated = await Navigator.push<ContactModel>(
      context,
      MaterialPageRoute(
        builder: (context) => EditContactView(contact: contact),
      ),
    );
    if (updated != null) {
      _loadContacts();
    }
  }

  Future<void> _toggleFavorite(ContactModel contact) async {
    final updated = contact.copyWith(isFavorite: !(contact.isFavorite == true));
    await service.update(updated);
    _loadContacts();
  }

  Future<void> _deleteContact(ContactModel contact) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Contato'),
        content: Text('Tem certeza que deseja remover "${contact.name}"?'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx, false),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await service.delete(contact);
      _loadContacts();
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final groupedData = _groupedContacts;
    final sortedLetters = groupedData.keys.toList()..sort();

    return Column(
      children: [
        // Barra de Pesquisa e Botão Adicionar
        Row(
          children: [
            Expanded(
              child: TextField(
                controller: searchController,
                onChanged: _onSearchChanged,
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Pesquisar nome, e-mail ou telefone...',
                  prefixIcon: const Icon(Icons.search),
                  suffixIcon: _searchQuery.isNotEmpty
                      ? IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          onPressed: () {
                            searchController.clear();
                            _onSearchChanged('');
                          },
                        )
                      : null,
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(32.0),
                    borderSide: const BorderSide(color: Colors.grey),
                  ),
                ),
              ),
            ),
            const SizedBox(width: 12),
            IconButton.filled(
              icon: const Icon(Icons.add),
              tooltip: 'Adicionar Contato',
              style: IconButton.styleFrom(
                backgroundColor: Colors.blue,
                foregroundColor: Colors.white,
              ),
              onPressed: () async {
                final created = await Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AddContactScreen()),
                );
                if (created == true) {
                  _loadContacts();
                }
              },
            ),
          ],
        ),
        const SizedBox(height: 16),

        // Contador de Contatos
        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Text(
                '${_contacts.length} contatos encontrados',
                style: TextStyle(fontSize: 12, color: Colors.grey.shade600, fontWeight: FontWeight.w500),
              ),
              if (_searchQuery.isNotEmpty)
                GestureDetector(
                  onTap: () {
                    searchController.clear();
                    _onSearchChanged('');
                  },
                  child: const Text(
                    'Limpar busca',
                    style: TextStyle(fontSize: 12, color: Colors.blue, fontWeight: FontWeight.bold),
                  ),
                ),
            ],
          ),
        ),
        const Divider(height: 12),

        // Listagem
        Expanded(
          child: sortedLetters.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.person_off_outlined, size: 54, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isEmpty ? 'Nenhum contato cadastrado' : 'Nenhum resultado para "$_searchQuery"',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                      ),
                      if (_searchQuery.isEmpty) ...[
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          icon: const Icon(Icons.add),
                          label: const Text('Cadastrar Primeiro Contato'),
                          onPressed: () async {
                            final created = await Navigator.push(
                              context,
                              MaterialPageRoute(builder: (context) => const AddContactScreen()),
                            );
                            if (created == true) _loadContacts();
                          },
                        ),
                      ],
                    ],
                  ),
                )
              : ListView.builder(
                  itemCount: sortedLetters.length,
                  itemBuilder: (context, letterIndex) {
                    final letter = sortedLetters[letterIndex];
                    final contacts = groupedData[letter]!;

                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(vertical: 6, horizontal: 16),
                          color: Theme.of(context).brightness == Brightness.dark
                              ? Colors.grey.shade900
                              : Colors.grey.shade100,
                          width: double.infinity,
                          child: Text(
                            letter,
                            style: const TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold,
                              color: Colors.blue,
                            ),
                          ),
                        ),
                        ...contacts.map((contact) {
                          final isFav = contact.isFavorite == true;
                          final hasImg = contact.imagePath != null && contact.imagePath!.trim().isNotEmpty;

                          return Slidable(
                            key: ValueKey(contact.email),
                            endActionPane: ActionPane(
                              motion: const DrawerMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (_) => _toggleFavorite(contact),
                                  backgroundColor: Colors.amber,
                                  foregroundColor: Colors.white,
                                  icon: isFav ? Icons.star : Icons.star_border,
                                  label: isFav ? 'Desfavoritar' : 'Favoritar',
                                ),
                                SlidableAction(
                                  onPressed: (_) => _openEdit(contact),
                                  backgroundColor: Colors.blue,
                                  foregroundColor: Colors.white,
                                  icon: Icons.edit,
                                  label: 'Editar',
                                ),
                                SlidableAction(
                                  onPressed: (_) => _deleteContact(contact),
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                  label: 'Excluir',
                                ),
                              ],
                            ),
                            child: ListTile(
                              contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 2),
                              onTap: () => _openDetails(contact),
                              leading: CircleAvatar(
                                radius: 22,
                                backgroundColor: Colors.blue.shade100,
                                backgroundImage: hasImg ? NetworkImage(contact.imagePath!) : null,
                                child: !hasImg
                                    ? Text(
                                        contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                                        style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                                      )
                                    : null,
                              ),
                              title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                              subtitle: Text(
                                contact.phone,
                                style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                              ),
                              trailing: isFav
                                  ? const Icon(Icons.star, color: Colors.amber, size: 20)
                                  : null,
                            ),
                          );
                        }),
                      ],
                    );
                  },
                ),
        ),
      ],
    );
  }
}
