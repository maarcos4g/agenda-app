import 'package:flutter/material.dart';
import 'package:test_app/models/contact_model.dart';
import 'package:test_app/modules/contact_details/contact_details_view.dart';
import 'package:test_app/services/category_service.dart';
import 'package:test_app/services/contacts_service.dart';

class CategoriesView extends StatefulWidget {
  const CategoriesView({super.key});

  @override
  State<CategoriesView> createState() => _CategoriesViewState();
}

class _CategoriesViewState extends State<CategoriesView> {
  final categoryService = CategoryService();
  final contactService = ContactService();

  List<String> _categories = [];
  List<ContactModel> _allContacts = [];
  String? _selectedCategory;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final cats = await categoryService.getCategories();
    final contacts = await contactService.get();

    setState(() {
      _categories = cats;
      _allContacts = contacts;
      if (_selectedCategory == null && cats.isNotEmpty) {
        _selectedCategory = cats.first;
      } else if (!cats.contains(_selectedCategory) && cats.isNotEmpty) {
        _selectedCategory = cats.first;
      }
      _isLoading = false;
    });
  }

  Future<void> _createNewCategory() async {
    final controller = TextEditingController();
    final created = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Nova Categoria'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome da Categoria',
            hintText: 'Ex: Parceiros, Vizinhos, Academia',
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text('Cancelar'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (created != null && created.isNotEmpty) {
      await categoryService.addCategory(created);
      setState(() {
        _selectedCategory = created;
      });
      _loadData();
    }
  }

  Future<void> _deleteCategory(String category) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Categoria'),
        content: Text('Deseja excluir a categoria "$category"? Os contatos não serão excluídos.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx, false), child: const Text('Cancelar')),
          ElevatedButton(
            style: ElevatedButton.styleFrom(backgroundColor: Colors.red),
            onPressed: () => Navigator.pop(ctx, true),
            child: const Text('Excluir', style: TextStyle(color: Colors.white)),
          ),
        ],
      ),
    );

    if (confirm == true) {
      await categoryService.deleteCategory(category);
      _selectedCategory = null;
      _loadData();
    }
  }

  Future<void> _manageCategoryContacts(String category) async {
    final contactsInCat = _allContacts.where((c) => c.categories.contains(category)).map((c) => c.email).toSet();
    final selectedEmails = Set<String>.from(contactsInCat);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text('Contatos em "$category"'),
            content: SizedBox(
              width: double.maxFinite,
              height: 350,
              child: _allContacts.isEmpty
                  ? const Center(child: Text('Nenhum contato cadastrado na agenda.'))
                  : ListView.builder(
                      shrinkWrap: true,
                      itemCount: _allContacts.length,
                      itemBuilder: (context, i) {
                        final contact = _allContacts[i];
                        final isSelected = selectedEmails.contains(contact.email);
                        return CheckboxListTile(
                          value: isSelected,
                          title: Text(contact.name),
                          subtitle: Text(contact.phone),
                          onChanged: (val) {
                            setModalState(() {
                              if (val == true) {
                                selectedEmails.add(contact.email);
                              } else {
                                selectedEmails.remove(contact.email);
                              }
                            });
                          },
                        );
                      },
                    ),
            ),
            actions: [
              TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
              ElevatedButton(
                onPressed: () async {
                  for (var contact in _allContacts) {
                    final shouldBeIn = selectedEmails.contains(contact.email);
                    final isCurrentlyIn = contact.categories.contains(category);

                    if (shouldBeIn && !isCurrentlyIn) {
                      final updated = contact.copyWith(categories: [...contact.categories, category]);
                      await contactService.update(updated);
                    } else if (!shouldBeIn && isCurrentlyIn) {
                      final updatedList = List<String>.from(contact.categories)..remove(category);
                      final updated = contact.copyWith(categories: updatedList);
                      await contactService.update(updated);
                    }
                  }
                  if (!mounted || !ctx.mounted) return;
                  Navigator.pop(ctx);
                  _loadData();
                },
                child: const Text('Salvar'),
              ),
            ],
          );
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (_isLoading) {
      return const Center(child: CircularProgressIndicator());
    }

    final categoryContacts = _selectedCategory == null
        ? <ContactModel>[]
        : _allContacts.where((c) => c.categories.contains(_selectedCategory)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Seletor de Categorias
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Categorias', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton.icon(
              icon: const Icon(Icons.add, size: 18),
              label: const Text('Nova Categoria'),
              onPressed: _createNewCategory,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Chips horizontais de categorias
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _categories.map((cat) {
              final isSelected = _selectedCategory == cat;
              final count = _allContacts.where((c) => c.categories.contains(cat)).length;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  label: Text('$cat ($count)'),
                  selected: isSelected,
                  selectedColor: Colors.blue,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedCategory = cat;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Barra de Ação da Categoria Selecionada
        if (_selectedCategory != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.blue.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Contatos em "$_selectedCategory"',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.blue),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.person_add_alt_1, size: 16),
                  label: const Text('Gerenciar', style: TextStyle(fontSize: 12)),
                  onPressed: () => _manageCategoryContacts(_selectedCategory!),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  tooltip: 'Excluir Categoria',
                  onPressed: () => _deleteCategory(_selectedCategory!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Lista de Contatos da Categoria
        Expanded(
          child: categoryContacts.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.label_off_outlined, size: 50, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhum contato associado à categoria "${_selectedCategory ?? ''}".',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.add),
                        label: const Text('Associar Contatos'),
                        onPressed: _selectedCategory == null
                            ? null
                            : () => _manageCategoryContacts(_selectedCategory!),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: categoryContacts.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final contact = categoryContacts[index];
                    final hasImg = contact.imagePath != null && contact.imagePath!.trim().isNotEmpty;

                    return ListTile(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ContactDetailsView(contact: contact),
                          ),
                        );
                        _loadData();
                      },
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: hasImg ? NetworkImage(contact.imagePath!) : null,
                        child: !hasImg
                            ? Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?')
                            : null,
                      ),
                      title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(contact.phone),
                      trailing: IconButton(
                        icon: const Icon(Icons.remove_circle_outline, color: Colors.red, size: 20),
                        tooltip: 'Desassociar desta categoria',
                        onPressed: () async {
                          final updatedList = List<String>.from(contact.categories)..remove(_selectedCategory);
                          await contactService.update(contact.copyWith(categories: updatedList));
                          _loadData();
                        },
                      ),
                    );
                  },
                ),
        ),
      ],
    );
  }
}
