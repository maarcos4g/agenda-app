import 'package:flutter/material.dart';
import 'package:test_app/modules/advanced_search/advanced_search_view.dart';
import 'package:test_app/modules/birthdays/birthdays_view.dart';
import 'package:test_app/modules/categories/categories_view.dart';
import 'package:test_app/modules/favorites/favorites_contacts_view.dart';
import 'package:test_app/modules/groups/groups_view.dart';
import 'package:test_app/modules/import_export/import_export_view.dart';
import 'package:test_app/modules/list_contacts/list_contacts_view.dart';
import 'package:test_app/modules/settings/settings_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  int _currentPage = 0;

  final List<String> _titles = [
    'Contatos',
    'Favoritos',
    'Categorias',
    'Configurações',
  ];

  final List<Widget> _pages = const [
    ListContactsView(),
    FavoritesContactsView(),
    CategoriesView(),
    SettingsView(),
  ];

  void _setPage(int index) {
    setState(() {
      _currentPage = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          _titles[_currentPage],
          style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
        ),
        centerTitle: true,
        bottom: PreferredSize(
          preferredSize: const Size.fromHeight(1),
          child: Container(color: Colors.grey.shade300, height: 1),
        ),
      ),
      drawer: Drawer(
        child: ListView(
          padding: EdgeInsets.zero,
          children: [
            DrawerHeader(
              decoration: const BoxDecoration(
                color: Colors.blue,
              ),
              child: const Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisAlignment: MainAxisAlignment.end,
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: Colors.white,
                    child: Icon(Icons.contacts, size: 30, color: Colors.blue),
                  ),
                  SizedBox(height: 10),
                  Text(
                    'Agenda de Contatos',
                    style: TextStyle(color: Colors.white, fontSize: 18, fontWeight: FontWeight.bold),
                  ),
                  Text(
                    'Seus contatos e organização',
                    style: TextStyle(color: Colors.white70, fontSize: 12),
                  ),
                ],
              ),
            ),
            ListTile(
              leading: const Icon(Icons.people_outline, color: Colors.blue),
              title: const Text('Todos os Contatos'),
              selected: _currentPage == 0,
              onTap: () {
                Navigator.pop(context);
                _setPage(0);
              },
            ),
            ListTile(
              leading: const Icon(Icons.star_outline, color: Colors.amber),
              title: const Text('Favoritos'),
              selected: _currentPage == 1,
              onTap: () {
                Navigator.pop(context);
                _setPage(1);
              },
            ),
            ListTile(
              leading: const Icon(Icons.label_outline, color: Colors.blue),
              title: const Text('Categorias'),
              selected: _currentPage == 2,
              onTap: () {
                Navigator.pop(context);
                _setPage(2);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group_outlined, color: Colors.blueGrey),
              title: const Text('Grupos'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (context) => Scaffold(
                      appBar: AppBar(
                        title: const Text('Grupos', style: TextStyle(fontSize: 16)),
                        centerTitle: true,
                        bottom: PreferredSize(
                          preferredSize: const Size.fromHeight(1),
                          child: Container(color: Colors.grey.shade300, height: 1),
                        ),
                      ),
                      body: const Padding(
                        padding: EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
                        child: GroupsView(),
                      ),
                    ),
                  ),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.cake_outlined, color: Colors.pinkAccent),
              title: const Text('Aniversários'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const BirthdaysView()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.search, color: Colors.blue),
              title: const Text('Pesquisa Avançada'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const AdvancedSearchView()),
                );
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.backup_outlined, color: Colors.teal),
              title: const Text('Backup (Importar / Exportar)'),
              onTap: () {
                Navigator.pop(context);
                Navigator.push(
                  context,
                  MaterialPageRoute(builder: (context) => const ImportExportView()),
                );
              },
            ),
            ListTile(
              leading: const Icon(Icons.settings_outlined, color: Colors.grey),
              title: const Text('Configurações'),
              selected: _currentPage == 3,
              onTap: () {
                Navigator.pop(context);
                _setPage(3);
              },
            ),
          ],
        ),
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 16.0),
        child: _pages[_currentPage],
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey.shade300, width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            _buildNavItem(
              index: 0,
              icon: Icons.contacts,
              unselectedIcon: Icons.contacts_outlined,
              label: 'Contatos',
            ),
            _buildNavItem(
              index: 1,
              icon: Icons.star,
              unselectedIcon: Icons.star_outline,
              label: 'Favoritos',
            ),
            _buildNavItem(
              index: 2,
              icon: Icons.label,
              unselectedIcon: Icons.label_outline,
              label: 'Categorias',
            ),
            _buildNavItem(
              index: 3,
              icon: Icons.settings,
              unselectedIcon: Icons.settings_outlined,
              label: 'Ajustes',
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildNavItem({
    required int index,
    required IconData icon,
    required IconData unselectedIcon,
    required String label,
  }) {
    final isSelected = _currentPage == index;
    return GestureDetector(
      behavior: HitTestBehavior.opaque,
      onTap: () => _setPage(index),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(
            isSelected ? icon : unselectedIcon,
            color: isSelected ? Colors.blue : Colors.grey,
            size: 24,
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              color: isSelected ? Colors.blue : Colors.grey,
              fontSize: 11,
              fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }
}
