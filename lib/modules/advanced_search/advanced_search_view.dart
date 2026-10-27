import 'package:flutter/material.dart';
import 'package:test_app/models/contact_model.dart';
import 'package:test_app/modules/contact_details/contact_details_view.dart';
import 'package:test_app/services/category_service.dart';
import 'package:test_app/services/contacts_service.dart';

class AdvancedSearchView extends StatefulWidget {
  const AdvancedSearchView({super.key});

  @override
  State<AdvancedSearchView> createState() => _AdvancedSearchViewState();
}

class _AdvancedSearchViewState extends State<AdvancedSearchView> {
  final contactService = ContactService();
  final categoryService = CategoryService();

  final cityController = TextEditingController();
  final companyController = TextEditingController();

  List<String> _categories = [];
  String? _selectedCategory;
  bool _onlyFavorites = false;
  DateTime? _createdAfter;

  List<ContactModel>? _searchResults;
  bool _isSearching = false;

  @override
  void initState() {
    super.initState();
    _loadCategories();
  }

  Future<void> _loadCategories() async {
    final cats = await categoryService.getCategories();
    setState(() {
      _categories = cats;
    });
  }

  Future<void> _performSearch() async {
    setState(() {
      _isSearching = true;
    });

    final results = await contactService.advancedSearch(
      category: _selectedCategory,
      city: cityController.text.trim(),
      company: companyController.text.trim(),
      onlyFavorites: _onlyFavorites,
      createdAfter: _createdAfter,
    );

    setState(() {
      _searchResults = results;
      _isSearching = false;
    });
  }

  void _clearFilters() {
    setState(() {
      cityController.clear();
      companyController.clear();
      _selectedCategory = null;
      _onlyFavorites = false;
      _createdAfter = null;
      _searchResults = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Pesquisa Avançada', style: TextStyle(fontSize: 16)),
        centerTitle: true,
        actions: [
          IconButton(
            icon: const Icon(Icons.refresh),
            tooltip: 'Limpar Filtros',
            onPressed: _clearFilters,
          ),
        ],
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade300, height: 1),
        ),
      ),
      body: SingleChildScrollView(
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Painel de Filtros
            Card(
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
                side: BorderSide(color: Colors.grey.shade300),
              ),
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    const Row(
                      children: [
                        Icon(Icons.filter_alt_outlined, color: Colors.blue, size: 20),
                        SizedBox(width: 8),
                        Text('Filtros de Busca', style: TextStyle(fontWeight: FontWeight.bold, fontSize: 15)),
                      ],
                    ),
                    const SizedBox(height: 16),

                    // Categoria
                    DropdownButtonFormField<String>(
                      initialValue: _selectedCategory,
                      decoration: InputDecoration(
                        labelText: 'Categoria',
                        prefixIcon: const Icon(Icons.label_outline),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                      items: [
                        const DropdownMenuItem<String>(
                          value: null,
                          child: Text('Todas as categorias'),
                        ),
                        ..._categories.map((cat) {
                          return DropdownMenuItem<String>(
                            value: cat,
                            child: Text(cat),
                          );
                        }),
                      ],
                      onChanged: (val) {
                        setState(() {
                          _selectedCategory = val;
                        });
                      },
                    ),
                    const SizedBox(height: 14),

                    // Cidade
                    TextField(
                      controller: cityController,
                      decoration: InputDecoration(
                        labelText: 'Cidade',
                        prefixIcon: const Icon(Icons.location_city_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Empresa
                    TextField(
                      controller: companyController,
                      decoration: InputDecoration(
                        labelText: 'Empresa',
                        prefixIcon: const Icon(Icons.business_outlined),
                        border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                        isDense: true,
                      ),
                    ),
                    const SizedBox(height: 14),

                    // Data de cadastro mínima
                    InkWell(
                      onTap: () async {
                        try {
                          final picked = await showDatePicker(
                            context: context,
                            initialDate: _createdAfter ?? DateTime.now(),
                            firstDate: DateTime(2020),
                            lastDate: DateTime.now(),
                          );
                          if (picked != null) {
                            setState(() {
                              _createdAfter = picked;
                            });
                          }
                        } catch (e) {
                          debugPrint('Erro ao abrir seletor de data: $e');
                        }
                      },
                      borderRadius: BorderRadius.circular(8),
                      child: InputDecorator(
                        decoration: InputDecoration(
                          labelText: 'Cadastrado a partir de',
                          prefixIcon: const Icon(Icons.calendar_today_outlined),
                          suffixIcon: _createdAfter != null
                              ? IconButton(
                                  icon: const Icon(Icons.clear, size: 18),
                                  onPressed: () {
                                    setState(() {
                                      _createdAfter = null;
                                    });
                                  },
                                )
                              : null,
                          border: OutlineInputBorder(borderRadius: BorderRadius.circular(8)),
                          isDense: true,
                        ),
                        child: Text(
                          _createdAfter != null
                              ? '${_createdAfter!.day.toString().padLeft(2, '0')}/${_createdAfter!.month.toString().padLeft(2, '0')}/${_createdAfter!.year}'
                              : 'Qualquer data',
                          style: TextStyle(
                            color: _createdAfter != null ? null : Colors.grey.shade600,
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(height: 10),

                    // Apenas Favoritos
                    SwitchListTile(
                      contentPadding: EdgeInsets.zero,
                      title: const Text('Apenas contatos favoritos', style: TextStyle(fontSize: 14)),
                      value: _onlyFavorites,
                      onChanged: (val) {
                        setState(() {
                          _onlyFavorites = val;
                        });
                      },
                    ),
                    const SizedBox(height: 10),

                    // Botão Aplicar Filtros
                    ElevatedButton.icon(
                      style: ElevatedButton.styleFrom(
                        backgroundColor: Colors.blue,
                        minimumSize: const Size.fromHeight(46),
                        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                      ),
                      icon: const Icon(Icons.search, color: Colors.white),
                      label: const Text('Aplicar Filtros', style: TextStyle(color: Colors.white, fontWeight: FontWeight.bold)),
                      onPressed: _performSearch,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 20),

            // Exibição dos Resultados
            if (_isSearching)
              const Center(child: CircularProgressIndicator())
            else if (_searchResults != null) ...[
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Text(
                    'Resultados da busca (${_searchResults!.length})',
                    style: const TextStyle(fontSize: 15, fontWeight: FontWeight.bold),
                  ),
                  if (_searchResults!.isNotEmpty)
                    TextButton(
                      onPressed: _clearFilters,
                      child: const Text('Nova busca', style: TextStyle(fontSize: 12)),
                    ),
                ],
              ),
              const SizedBox(height: 8),

              if (_searchResults!.isEmpty)
                Container(
                  padding: const EdgeInsets.all(24),
                  alignment: Alignment.center,
                  child: Column(
                    children: [
                      Icon(Icons.search_off, size: 48, color: Colors.grey.shade400),
                      const SizedBox(height: 8),
                      Text(
                        'Nenhum contato encontrado com os filtros selecionados.',
                        style: TextStyle(color: Colors.grey.shade600),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                )
              else
                ListView.separated(
                  shrinkWrap: true,
                  physics: const NeverScrollableScrollPhysics(),
                  itemCount: _searchResults!.length,
                  separatorBuilder: (_, index) => const Divider(height: 1),
                  itemBuilder: (context, index) {
                    final contact = _searchResults![index];
                    final hasImg = contact.imagePath != null && contact.imagePath!.trim().isNotEmpty;

                    return ListTile(
                      onTap: () async {
                        await Navigator.push(
                          context,
                          MaterialPageRoute(
                            builder: (context) => ContactDetailsView(contact: contact),
                          ),
                        );
                        _performSearch();
                      },
                      leading: CircleAvatar(
                        backgroundColor: Colors.blue.shade100,
                        backgroundImage: hasImg ? NetworkImage(contact.imagePath!) : null,
                        child: !hasImg
                            ? Text(contact.name.isNotEmpty ? contact.name[0].toUpperCase() : '?')
                            : null,
                      ),
                      title: Text(contact.name, style: const TextStyle(fontWeight: FontWeight.w600)),
                      subtitle: Text(
                        '${contact.phone}${contact.city != null && contact.city!.isNotEmpty ? " • ${contact.city}" : ""}',
                        style: TextStyle(fontSize: 13, color: Colors.grey.shade600),
                      ),
                      trailing: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          if (contact.isFavorite == true)
                            const Icon(Icons.star, color: Colors.amber, size: 18),
                          const Icon(Icons.chevron_right, color: Colors.grey, size: 18),
                        ],
                      ),
                    );
                  },
                ),
            ],
          ],
        ),
      ),
    );
  }
}
