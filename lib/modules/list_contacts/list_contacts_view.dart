import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:test_app/models/contact_model.dart';
import 'package:test_app/modules/add_contact/add_edit_contact_view.dart';
import 'package:test_app/modules/details_contact/details_contact_view.dart';
import 'package:test_app/services/contacts_service.dart';

class ListContactsView extends StatefulWidget {
  const ListContactsView({super.key});

  @override
  State<ListContactsView> createState() => _ListContactsViewState();
}

class _ListContactsViewState extends State<ListContactsView> {
  final service = ContactService();

  List<ContactModel> _rawContacts = [];
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadContacts();
  }

  Future<void> _loadContacts() async {
    final contacts = await service.get();
    setState(() {
      _rawContacts = contacts;
      _isLoading = false;
    });
  }

  Map<String, List<ContactModel>> get _groupedContacts {
    final Map<String, List<ContactModel>> grouped = {};

    for (var contact in _rawContacts) {
      final name = contact.name;
      if (name.isEmpty) continue;

      final firstLetter = name[0].toUpperCase();

      if (!grouped.containsKey(firstLetter)) {
        grouped[firstLetter] = [];
      }
      grouped[firstLetter]!.add(contact);
    }

    grouped.forEach((key, list) {
      list.sort((a, b) => a.name.compareTo(b.name));
    });

    return grouped;
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final groupedData = _groupedContacts;
    final sortedLetters = groupedData.keys.toList()..sort();

    return Column(
      spacing: 24,
      children: [
        Row(
          spacing: 16,
          children: [
            Expanded(
              child: TextField(
                decoration: InputDecoration(
                  isDense: true,
                  hintText: 'Pesquisar',
                  prefixIcon: Icon(Icons.search),
                  border: OutlineInputBorder(
                    borderRadius: BorderRadius.circular(32.0),
                    borderSide: BorderSide(color: Colors.grey),
                  ),
                ),
              ),
            ),
            IconButton.outlined(
              icon: Icon(Icons.add),
              onPressed: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => AddEditContactScreen()),
                );
              },
              style: IconButton.styleFrom(
                side: BorderSide(color: Colors.grey, width: 1.0),
              ),
            ),
          ],
        ),
        Expanded(
          child: sortedLetters.isEmpty
              ? Center(child: Text('Nenhum contato encontrado'))
              : ListView(
                  children: sortedLetters.map((letter) {
                    final contacts = groupedData[letter]!;
                    return Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Padding(
                          padding: EdgeInsets.symmetric(
                            vertical: 8,
                            horizontal: 16,
                          ),
                          child: Text(
                            letter,
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.grey,
                            ),
                          ),
                        ),
                        Divider(height: 1, color: Colors.black12),

                        ...contacts.map((contact) {
                          return Slidable(
                            key: ValueKey(contact.email),
                            endActionPane: ActionPane(
                              motion: DrawerMotion(),
                              children: [
                                SlidableAction(
                                  onPressed: (context) async {
                                    contact.isFavorite == false
                                        ? await service.setFavoriteStatus(contact.id, true)
                                        : await service.setFavoriteStatus(contact.id, false);
                                    _loadContacts();
                                  },
                                  backgroundColor: Colors.blueAccent,
                                  foregroundColor: Colors.white,
                                  icon: contact.isFavorite == false
                                      ? Icons.star
                                      : Icons.star_half_outlined,
                                ),
                                SlidableAction(
                                  onPressed: (context) async {
                                    await service.delete(contact);
                                    _loadContacts();
                                  },
                                  backgroundColor: Colors.red,
                                  foregroundColor: Colors.white,
                                  icon: Icons.delete,
                                ),
                              ],
                            ),
                            child: ListTile(
                              onTap: () {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(
                                    builder: (context) =>
                                        DetailsContactView(contact: contact),
                                  ),
                                );
                              },
                              contentPadding: EdgeInsets.symmetric(
                                horizontal: 16,
                                vertical: 4,
                              ),
                              leading: CircleAvatar(
                                backgroundColor: Colors.grey.shade300,
                                child: Container(
                                  width: 48,
                                  height: 48,
                                  alignment: Alignment.center,
                                  child: Text(
                                    contact.name[0].toString().toUpperCase(),
                                    style: TextStyle(
                                      fontWeight: FontWeight.w500,
                                    ),
                                  ),
                                ),
                              ),
                              trailing: contact.isFavorite == true
                                  ? Icon(Icons.star)
                                  : null,
                              title: Text(contact.name),
                            ),
                          );
                        }),
                      ],
                    );
                  }).toList(),
                ),
        ),
      ],
    );
  }
}
