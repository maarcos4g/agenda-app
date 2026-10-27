import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:test_app/models/contact_model.dart';
import 'package:test_app/services/category_service.dart';
import 'package:test_app/services/contacts_service.dart';
import 'package:test_app/services/group_service.dart';

class EditContactView extends StatefulWidget {
  final ContactModel contact;

  const EditContactView({super.key, required this.contact});

  @override
  State<EditContactView> createState() => _EditContactViewState();
}

class _EditContactViewState extends State<EditContactView> {
  final formKey = GlobalKey<FormState>();
  final contactService = ContactService();
  final categoryService = CategoryService();
  final groupService = GroupService();

  late TextEditingController nameController;
  late TextEditingController emailController;
  late MaskedTextController phoneController;
  late TextEditingController notesController;
  late TextEditingController cityController;
  late TextEditingController companyController;
  late TextEditingController imagePathController;
  late MaskedTextController birthDateController;

  String? _birthDate;
  List<String> _selectedCategories = [];
  List<String> _selectedGroups = [];
  List<String> _availableCategories = [];
  List<String> _availableGroups = [];

  static const List<String> _sampleAvatars = [
    'https://images.unsplash.com/photo-1494790108377-be9c29b29330?w=150',
    'https://images.unsplash.com/photo-1507003211169-0a1dd7228f2d?w=150',
    'https://images.unsplash.com/photo-1534528741775-53994a69daeb?w=150',
    'https://images.unsplash.com/photo-1500648767791-00dcc994a43e?w=150',
    'https://images.unsplash.com/photo-1544005313-94ddf0286df2?w=150',
    'https://images.unsplash.com/photo-1522075469751-3a6694fb2f61?w=150',
  ];

  @override
  void initState() {
    super.initState();
    final c = widget.contact;
    nameController = TextEditingController(text: c.name);
    emailController = TextEditingController(text: c.email);
    phoneController = MaskedTextController(mask: '(00) 00000-0000', text: c.phone);
    notesController = TextEditingController(text: c.notes ?? '');
    cityController = TextEditingController(text: c.city ?? '');
    companyController = TextEditingController(text: c.company ?? '');
    imagePathController = TextEditingController(text: c.imagePath ?? '');
    _birthDate = c.birthDate;

    String initialFormattedDate = '';
    if (c.birthDate != null && c.birthDate!.isNotEmpty) {
      final parts = c.birthDate!.split('-');
      if (parts.length == 3) {
        initialFormattedDate = '${parts[2]}/${parts[1]}/${parts[0]}';
      }
    }
    birthDateController = MaskedTextController(mask: '00/00/0000', text: initialFormattedDate);

    _selectedCategories = List<String>.from(c.categories);
    _selectedGroups = List<String>.from(c.groups);

    _loadCategoriesAndGroups();
  }

  Future<void> _loadCategoriesAndGroups() async {
    final cats = await categoryService.getCategories();
    final grps = await groupService.getGroups();
    setState(() {
      _availableCategories = cats;
      _availableGroups = grps;
    });
  }

  Future<void> _pickBirthDate() async {
    DateTime initial = DateTime(2000, 1, 1);
    if (birthDateController.text.isNotEmpty && birthDateController.text.length == 10) {
      try {
        final parts = birthDateController.text.split('/');
        if (parts.length == 3) {
          final d = int.parse(parts[0]);
          final m = int.parse(parts[1]);
          final y = int.parse(parts[2]);
          initial = DateTime(y, m, d);
        }
      } catch (_) {}
    } else if (_birthDate != null && _birthDate!.isNotEmpty) {
      try {
        final parts = _birthDate!.split('-');
        if (parts.length == 3) {
          initial = DateTime(int.parse(parts[0]), int.parse(parts[1]), int.parse(parts[2]));
        }
      } catch (_) {}
    }

    try {
      final picked = await showDatePicker(
        context: context,
        initialDate: initial.isAfter(DateTime.now()) ? DateTime.now() : initial,
        firstDate: DateTime(1900),
        lastDate: DateTime.now(),
      );

      if (picked != null) {
        final day = picked.day.toString().padLeft(2, '0');
        final month = picked.month.toString().padLeft(2, '0');
        final year = picked.year.toString().padLeft(4, '0');
        setState(() {
          birthDateController.text = '$day/$month/$year';
          _birthDate = '$year-$month-$day';
        });
      }
    } catch (e) {
      debugPrint('Erro ao abrir seletor de data: $e');
    }
  }

  Future<void> _saveChanges() async {
    if (!formKey.currentState!.validate()) return;

    String? finalBirthDate = _birthDate;
    final text = birthDateController.text.trim();
    if (text.length == 10) {
      final parts = text.split('/');
      if (parts.length == 3) {
        finalBirthDate = '${parts[2]}-${parts[1]}-${parts[0]}';
      }
    } else if (text.isEmpty) {
      finalBirthDate = null;
    }

    final updated = widget.contact.copyWith(
      name: nameController.text.trim(),
      email: emailController.text.trim(),
      phone: phoneController.text.trim(),
      imagePath: imagePathController.text.trim(),
      notes: notesController.text.trim(),
      categories: _selectedCategories,
      groups: _selectedGroups,
      birthDate: finalBirthDate,
      city: cityController.text.trim(),
      company: companyController.text.trim(),
    );

    try {
      await contactService.update(updated, oldEmail: widget.contact.email);
      if (!mounted) return;
      Navigator.pop(context, updated);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contato atualizado com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro ao atualizar: ${e.toString()}'), backgroundColor: Colors.red),
      );
    }
  }

  void _chooseAvatar(String url) {
    setState(() {
      imagePathController.text = url;
    });
  }

  @override
  Widget build(BuildContext context) {
    final currentAvatar = imagePathController.text.trim();

    return Scaffold(
      appBar: AppBar(
        title: const Text('Editar Contato', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.close),
          tooltip: 'Cancelar',
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            tooltip: 'Salvar Alterações',
            onPressed: _saveChanges,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade300, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 24),
        child: Form(
          key: formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              // Foto e Seletor
              Center(
                child: CircleAvatar(
                  radius: 50,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: currentAvatar.isNotEmpty ? NetworkImage(currentAvatar) : null,
                  child: currentAvatar.isEmpty
                      ? const Icon(Icons.person, size: 50, color: Colors.blue)
                      : null,
                ),
              ),
              const SizedBox(height: 12),
              const Text('Escolha um avatar:', style: TextStyle(fontSize: 13, fontWeight: FontWeight.w500)),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ..._sampleAvatars.map((url) {
                      final isSelected = currentAvatar == url;
                      return GestureDetector(
                        onTap: () => _chooseAvatar(url),
                        child: Container(
                          margin: const EdgeInsets.symmetric(horizontal: 4),
                          decoration: BoxDecoration(
                            shape: BoxShape.circle,
                            border: Border.all(
                              color: isSelected ? Colors.blue : Colors.transparent,
                              width: 3,
                            ),
                          ),
                          child: CircleAvatar(
                            radius: 20,
                            backgroundImage: NetworkImage(url),
                          ),
                        ),
                      );
                    }),
                    IconButton(
                      icon: const Icon(Icons.delete_outline, color: Colors.red),
                      tooltip: 'Remover foto',
                      onPressed: () => _chooseAvatar(''),
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Campos Principais
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nome Completo *',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Nome é obrigatório' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: phoneController,
                keyboardType: TextInputType.phone,
                decoration: InputDecoration(
                  labelText: 'Telefone *',
                  prefixIcon: const Icon(Icons.phone_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Telefone é obrigatório' : null,
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: emailController,
                keyboardType: TextInputType.emailAddress,
                decoration: InputDecoration(
                  labelText: 'E-mail *',
                  prefixIcon: const Icon(Icons.email_outlined),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                validator: (val) {
                  if (val == null || val.trim().isEmpty) return 'E-mail é obrigatório';
                  if (!val.contains('@')) return 'E-mail inválido';
                  return null;
                },
              ),
              const SizedBox(height: 16),

              // Aniversário
              TextFormField(
                controller: birthDateController,
                keyboardType: TextInputType.datetime,
                decoration: InputDecoration(
                  labelText: 'Data de Aniversário (DD/MM/AAAA)',
                  prefixIcon: const Icon(Icons.cake_outlined),
                  suffixIcon: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      IconButton(
                        icon: const Icon(Icons.calendar_month, color: Colors.blue),
                        tooltip: 'Selecionar no calendário',
                        onPressed: _pickBirthDate,
                      ),
                      if (birthDateController.text.isNotEmpty)
                        IconButton(
                          icon: const Icon(Icons.clear, size: 18),
                          tooltip: 'Limpar',
                          onPressed: () {
                            setState(() {
                              birthDateController.clear();
                              _birthDate = null;
                            });
                          },
                        ),
                    ],
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                onChanged: (val) {
                  if (val.length == 10) {
                    final parts = val.split('/');
                    if (parts.length == 3) {
                      _birthDate = '${parts[2]}-${parts[1]}-${parts[0]}';
                    }
                  } else if (val.isEmpty) {
                    _birthDate = null;
                  }
                  setState(() {});
                },
              ),
              const SizedBox(height: 16),

              Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: cityController,
                      decoration: InputDecoration(
                        labelText: 'Cidade',
                        prefixIcon: const Icon(Icons.location_city_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: TextFormField(
                      controller: companyController,
                      decoration: InputDecoration(
                        labelText: 'Empresa',
                        prefixIcon: const Icon(Icons.business_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 16),

              TextFormField(
                controller: notesController,
                maxLines: 3,
                decoration: InputDecoration(
                  labelText: 'Observações / Notas',
                  alignLabelWithHint: true,
                  prefixIcon: const Padding(
                    padding: EdgeInsets.only(bottom: 40),
                    child: Icon(Icons.notes_outlined),
                  ),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
              ),
              const SizedBox(height: 20),

              // Categorias
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Categorias', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _availableCategories.map((cat) {
                  final isSelected = _selectedCategories.contains(cat);
                  return FilterChip(
                    label: Text(cat),
                    selected: isSelected,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedCategories.add(cat);
                        } else {
                          _selectedCategories.remove(cat);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 20),

              // Grupos
              Align(
                alignment: Alignment.centerLeft,
                child: Text('Grupos', style: TextStyle(fontWeight: FontWeight.bold, color: Colors.grey.shade700)),
              ),
              const SizedBox(height: 8),
              Wrap(
                spacing: 8,
                runSpacing: 4,
                children: _availableGroups.map((group) {
                  final isSelected = _selectedGroups.contains(group);
                  return FilterChip(
                    label: Text(group),
                    selected: isSelected,
                    selectedColor: Colors.teal.shade100,
                    onSelected: (selected) {
                      setState(() {
                        if (selected) {
                          _selectedGroups.add(group);
                        } else {
                          _selectedGroups.remove(group);
                        }
                      });
                    },
                  );
                }).toList(),
              ),
              const SizedBox(height: 32),

              // Botões de Ação Inferiores
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: () => Navigator.pop(context),
                      child: const Text('Cancelar'),
                    ),
                  ),
                  const SizedBox(width: 16),
                  Expanded(
                    child: ElevatedButton(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        padding: const EdgeInsets.symmetric(vertical: 14),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      onPressed: _saveChanges,
                      child: const Text('Salvar', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}
