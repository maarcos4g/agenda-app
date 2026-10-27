import 'package:flutter/material.dart';
import 'package:flutter_masked_text2/flutter_masked_text2.dart';
import 'package:test_app/models/contact_model.dart';
import 'package:test_app/services/category_service.dart';
import 'package:test_app/services/contacts_service.dart';
import 'package:test_app/services/group_service.dart';

class AddContactScreen extends StatefulWidget {
  const AddContactScreen({super.key});

  @override
  State<AddContactScreen> createState() => _AddContactScreenState();
}

class _AddContactScreenState extends State<AddContactScreen> {
  final formKey = GlobalKey<FormState>();
  final contactService = ContactService();
  final categoryService = CategoryService();
  final groupService = GroupService();

  final nameController = TextEditingController();
  final emailController = TextEditingController();
  final phoneController = MaskedTextController(mask: '(00) 00000-0000');
  final notesController = TextEditingController();
  final cityController = TextEditingController();
  final companyController = TextEditingController();
  final imagePathController = TextEditingController();

  final birthDateController = MaskedTextController(mask: '00/00/0000');
  String? _birthDate;
  final List<String> _selectedCategories = [];
  final List<String> _selectedGroups = [];
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

  Future<void> _saveContact() async {
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

    final contact = ContactModel(
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
      createdAt: DateTime.now().toIso8601String(),
    );

    try {
      await contactService.add(contact);
      if (!mounted) return;
      Navigator.pop(context, true);
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Contato salvo com sucesso!')),
      );
    } catch (e) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Erro: ${e.toString()}'), backgroundColor: Colors.red),
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
        title: const Text('Novo Contato', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        leading: IconButton(
          icon: const Icon(Icons.arrow_back),
          onPressed: () => Navigator.pop(context),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.check, color: Colors.green),
            tooltip: 'Salvar Contato',
            onPressed: _saveContact,
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
              // Avatar
              Center(
                child: CircleAvatar(
                  radius: 48,
                  backgroundColor: Colors.blue.shade100,
                  backgroundImage: currentAvatar.isNotEmpty ? NetworkImage(currentAvatar) : null,
                  child: currentAvatar.isEmpty
                      ? const Icon(Icons.add_a_photo, size: 36, color: Colors.blue)
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
                            radius: 18,
                            backgroundImage: NetworkImage(url),
                          ),
                        ),
                      );
                    }),
                    if (currentAvatar.isNotEmpty)
                      IconButton(
                        icon: const Icon(Icons.delete_outline, color: Colors.red),
                        tooltip: 'Remover foto',
                        onPressed: () => _chooseAvatar(''),
                      ),
                  ],
                ),
              ),
              const SizedBox(height: 24),

              // Formulário
              TextFormField(
                controller: nameController,
                decoration: InputDecoration(
                  labelText: 'Nome *',
                  prefixIcon: const Icon(Icons.person_outline),
                  border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                  isDense: true,
                ),
                validator: (val) => val == null || val.trim().isEmpty ? 'Campo obrigatório' : null,
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
                validator: (val) => val == null || val.trim().isEmpty ? 'Campo obrigatório' : null,
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
                  if (val == null || val.trim().isEmpty) return 'Campo obrigatório';
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
                  labelText: 'Observações',
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
              if (_availableCategories.isNotEmpty) ...[
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
              ],

              // Grupos
              if (_availableGroups.isNotEmpty) ...[
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
              ],

              ElevatedButton(
                style: ElevatedButton.styleFrom(
                  backgroundColor: Colors.blue,
                  minimumSize: const Size.fromHeight(48),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                onPressed: _saveContact,
                child: const Text('Salvar Contato', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
