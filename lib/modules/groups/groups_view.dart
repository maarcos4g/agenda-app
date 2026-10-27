import 'package:flutter/material.dart';
import 'package:test_app/models/contact_model.dart';
import 'package:test_app/modules/contact_details/contact_details_view.dart';
import 'package:test_app/services/contacts_service.dart';
import 'package:test_app/services/group_service.dart';

class GroupsView extends StatefulWidget {
  const GroupsView({super.key});

  @override
  State<GroupsView> createState() => _GroupsViewState();
}

class _GroupsViewState extends State<GroupsView> {
  final groupService = GroupService();
  final contactService = ContactService();

  List<String> _groups = [];
  List<ContactModel> _allContacts = [];
  String? _selectedGroup;
  bool _isLoading = true;

  @override
  void initState() {
    super.initState();
    _loadData();
  }

  Future<void> _loadData() async {
    final grps = await groupService.getGroups();
    final contacts = await contactService.get();

    setState(() {
      _groups = grps;
      _allContacts = contacts;
      if (_selectedGroup == null && grps.isNotEmpty) {
        _selectedGroup = grps.first;
      } else if (!grps.contains(_selectedGroup) && grps.isNotEmpty) {
        _selectedGroup = grps.first;
      }
      _isLoading = false;
    });
  }

  Future<void> _createNewGroup() async {
    final controller = TextEditingController();
    final created = await showDialog<String>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Novo Grupo'),
        content: TextField(
          controller: controller,
          autofocus: true,
          decoration: const InputDecoration(
            labelText: 'Nome do Grupo',
            hintText: 'Ex: Futebol, Faculdade, Família',
          ),
        ),
        actions: [
          TextButton(onPressed: () => Navigator.pop(ctx), child: const Text('Cancelar')),
          ElevatedButton(
            onPressed: () => Navigator.pop(ctx, controller.text.trim()),
            child: const Text('Criar'),
          ),
        ],
      ),
    );

    if (created != null && created.isNotEmpty) {
      await groupService.addGroup(created);
      setState(() {
        _selectedGroup = created;
      });
      _loadData();
    }
  }

  Future<void> _deleteGroup(String group) async {
    final confirm = await showDialog<bool>(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text('Excluir Grupo'),
        content: Text('Deseja excluir o grupo "$group"? Os contatos não serão excluídos da agenda.'),
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
      await groupService.deleteGroup(group);
      _selectedGroup = null;
      _loadData();
    }
  }

  Future<void> _manageMembers(String group) async {
    final membersInGroup = _allContacts.where((c) => c.groups.contains(group)).map((c) => c.email).toSet();
    final selectedEmails = Set<String>.from(membersInGroup);

    await showDialog(
      context: context,
      builder: (ctx) => StatefulBuilder(
        builder: (context, setModalState) {
          return AlertDialog(
            title: Text('Membros de "$group"'),
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
                    final isCurrentlyIn = contact.groups.contains(group);

                    if (shouldBeIn && !isCurrentlyIn) {
                      final updated = contact.copyWith(groups: [...contact.groups, group]);
                      await contactService.update(updated);
                    } else if (!shouldBeIn && isCurrentlyIn) {
                      final updatedList = List<String>.from(contact.groups)..remove(group);
                      final updated = contact.copyWith(groups: updatedList);
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

    final groupMembers = _selectedGroup == null
        ? <ContactModel>[]
        : _allContacts.where((c) => c.groups.contains(_selectedGroup)).toList();

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Cabeçalho de Grupos
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text('Grupos de Contatos', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
            TextButton.icon(
              icon: const Icon(Icons.group_add, size: 18),
              label: const Text('Novo Grupo'),
              onPressed: _createNewGroup,
            ),
          ],
        ),
        const SizedBox(height: 8),

        // Chips horizontais de grupos
        SingleChildScrollView(
          scrollDirection: Axis.horizontal,
          child: Row(
            children: _groups.map((group) {
              final isSelected = _selectedGroup == group;
              final count = _allContacts.where((c) => c.groups.contains(group)).length;

              return Padding(
                padding: const EdgeInsets.only(right: 8),
                child: ChoiceChip(
                  avatar: Icon(Icons.group, size: 16, color: isSelected ? Colors.white : Colors.teal),
                  label: Text('$group ($count)'),
                  selected: isSelected,
                  selectedColor: Colors.teal,
                  labelStyle: TextStyle(
                    color: isSelected ? Colors.white : null,
                    fontWeight: isSelected ? FontWeight.bold : FontWeight.normal,
                  ),
                  onSelected: (selected) {
                    if (selected) {
                      setState(() {
                        _selectedGroup = group;
                      });
                    }
                  },
                ),
              );
            }).toList(),
          ),
        ),
        const SizedBox(height: 16),

        // Barra do Grupo Selecionado
        if (_selectedGroup != null) ...[
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 8),
            decoration: BoxDecoration(
              color: Colors.teal.shade50,
              borderRadius: BorderRadius.circular(10),
            ),
            child: Row(
              children: [
                Expanded(
                  child: Text(
                    'Membros de "$_selectedGroup"',
                    style: const TextStyle(fontWeight: FontWeight.bold, color: Colors.teal),
                  ),
                ),
                TextButton.icon(
                  icon: const Icon(Icons.person_add, size: 16),
                  label: const Text('Membros', style: TextStyle(fontSize: 12)),
                  onPressed: () => _manageMembers(_selectedGroup!),
                ),
                IconButton(
                  icon: const Icon(Icons.delete_outline, color: Colors.red, size: 20),
                  tooltip: 'Excluir Grupo',
                  onPressed: () => _deleteGroup(_selectedGroup!),
                ),
              ],
            ),
          ),
          const SizedBox(height: 12),
        ],

        // Lista de Membros
        Expanded(
          child: groupMembers.isEmpty
              ? Center(
                  child: Column(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.groups_outlined, size: 50, color: Colors.grey.shade400),
                      const SizedBox(height: 12),
                      Text(
                        'Nenhum membro no grupo "${_selectedGroup ?? ''}".',
                        style: TextStyle(color: Colors.grey.shade600),
                      ),
                      const SizedBox(height: 12),
                      ElevatedButton.icon(
                        icon: const Icon(Icons.group_add),
                        label: const Text('Adicionar Membros'),
                        style: ElevatedButton.styleFrom(backgroundColor: Colors.teal),
                        onPressed: _selectedGroup == null
                            ? null
                            : () => _manageMembers(_selectedGroup!),
                      ),
                    ],
                  ),
                )
              : ListView.separated(
                  itemCount: groupMembers.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final contact = groupMembers[index];
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
                        backgroundColor: Colors.teal.shade100,
                        backgroundImage: hasImg ? NetworkImage(contact.imagePath!) : null,
                        child: !hasImg
                            ? Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?')
                            : null,
                      ),
                      title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(contact.phone),
                      trailing: IconButton(
                        icon: const Icon(Icons.person_remove_outlined, color: Colors.red, size: 20),
                        tooltip: 'Remover do grupo',
                        onPressed: () async {
                          final updated = List<String>.from(contact.groups)..remove(_selectedGroup);
                          await contactService.update(contact.copyWith(groups: updated));
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
