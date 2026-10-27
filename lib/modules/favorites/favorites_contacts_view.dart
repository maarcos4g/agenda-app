import 'package:flutter/material.dart';
import 'package:flutter_slidable/flutter_slidable.dart';
import 'package:test_app/models/contact_model.dart';
import 'package:test_app/modules/contact_details/contact_details_view.dart';
import 'package:test_app/services/contacts_service.dart';

class FavoritesContactsView extends StatefulWidget {
  const FavoritesContactsView({super.key});

  @override
  State<FavoritesContactsView> createState() => _FavoritesContactsViewState();
}

class _FavoritesContactsViewState extends State<FavoritesContactsView> {
  final service = ContactService();
  final searchController = TextEditingController();

  List<ContactModel> _favorites = [];
  bool _isLoading = true;
  String _searchQuery = '';

  @override
  void initState() {
    super.initState();
    _loadFavorites();
  }

  Future<void> _loadFavorites() async {
    final allFavorites = await service.getFavorites();
    if (_searchQuery.trim().isEmpty) {
      setState(() {
        _favorites = allFavorites;
        _isLoading = false;
      });
    } else {
      final q = _searchQuery.toLowerCase().trim();
      final filtered = allFavorites.where((c) {
        return c.name.toLowerCase().contains(q) ||
            c.email.toLowerCase().contains(q) ||
            c.phone.contains(q);
      }).toList();
      setState(() {
        _favorites = filtered;
        _isLoading = false;
      });
    }
  }

  Future<void> _removeFavorite(ContactModel contact) async {
    final updated = contact.copyWith(isFavorite: false);
    await service.update(updated);
    _loadFavorites();
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text('${contact.name} removido dos favoritos.'),
        action: SnackBarAction(
          label: 'Desfazer',
          onPressed: () async {
            await service.update(contact.copyWith(isFavorite: true));
            _loadFavorites();
          },
        ),
      ),
    );
  }

  Future<void> _openDetails(ContactModel contact) async {
    await Navigator.push(
      context,
      MaterialPageRoute(
        builder: (context) => ContactDetailsView(contact: contact),
      ),
    );
    _loadFavorites();
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    return Column(
      children: [
        // Barra de Pesquisa em Favoritos
        TextField(
          controller: searchController,
          onChanged: (val) {
            setState(() {
              _searchQuery = val;
            });
            _loadFavorites();
          },
          decoration: InputDecoration(
            isDense: true,
            hintText: 'Pesquisar em favoritos...',
            prefixIcon: const Icon(Icons.search),
            suffixIcon: _searchQuery.isNotEmpty
                ? IconButton(
                    icon: const Icon(Icons.clear, size: 18),
                    onPressed: () {
                      searchController.clear();
                      setState(() {
                        _searchQuery = '';
                      });
                      _loadFavorites();
                    },
                  )
                : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(32.0),
              borderSide: const BorderSide(color: Colors.grey),
            ),
          ),
        ),
        const SizedBox(height: 12),

        Padding(
          padding: const EdgeInsets.symmetric(horizontal: 4, vertical: 4),
          child: Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              Row(
                children: [
                  const Icon(Icons.star, color: Colors.amber, size: 18),
                  const SizedBox(width: 6),
                  Text(
                    '${_favorites.length} contatos favoritos',
                    style: TextStyle(fontSize: 13, color: Colors.grey.shade600, fontWeight: FontWeight.w600),
                  ),
                ],
              ),
            ],
          ),
        ),
        const Divider(height: 12),

        // Listagem
        Expanded(
          child: _favorites.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.star_border, size: 54, color: Colors.amber.shade200),
                      const SizedBox(height: 12),
                      Text(
                        _searchQuery.isEmpty
                            ? 'Você ainda não possui favoritos.'
                            : 'Nenhum favorito para "$_searchQuery"',
                        style: TextStyle(color: Colors.grey.shade600, fontSize: 15),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        'Marque a estrela ao cadastrar ou deslize um contato.',
                        style: TextStyle(color: Colors.grey.shade500, fontSize: 12),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: _favorites.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final contact = _favorites[index];
                    final hasImg = contact.imagePath != null && contact.imagePath!.trim().isNotEmpty;

                    return Slidable(
                      key: ValueKey(contact.email),
                      endActionPane: ActionPane(
                        motion: const DrawerMotion(),
                        children: [
                          SlidableAction(
                            onPressed: (_) => _removeFavorite(contact),
                            backgroundColor: Colors.amber,
                            foregroundColor: Colors.white,
                            icon: Icons.star_border,
                            label: 'Remover',
                          ),
                        ],
                      ),
                      child: ListTile(
                        onTap: () => _openDetails(contact),
                        leading: CircleAvatar(
                          radius: 22,
                          backgroundColor: Colors.amber.shade100,
                          backgroundImage: hasImg ? NetworkImage(contact.imagePath!) : null,
                          child: !hasImg
                              ? Text(
                                  contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?',
                                  style: TextStyle(fontWeight: FontWeight.bold, color: Colors.amber.shade900),
                                )
                              : null,
                        ),
                        title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                        subtitle: Text(contact.phone, style: TextStyle(fontSize: 13, color: Colors.grey.shade600)),
                        trailing: IconButton(
                          icon: const Icon(Icons.star, color: Colors.amber),
                          tooltip: 'Remover dos favoritos',
                          onPressed: () => _removeFavorite(contact),
                        ),
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
