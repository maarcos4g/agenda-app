import 'package:flutter/material.dart';
import 'package:test_app/modules/favorites/favorites_contacts_view.dart';
import 'package:test_app/modules/list_contacts/list_contacts_view.dart';

class HomeView extends StatefulWidget {
  const HomeView({super.key});

  @override
  State<HomeView> createState() => _HomeViewState();
}

class _HomeViewState extends State<HomeView> {
  var currentPage = 0;

  void setPage(int index) {
    currentPage = index;
  }

  final pages = [
    ListContactsView(),
    FavoritesContactsView(),
    Center(child: Text('Configurações')),
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        elevation: 0,
        title: Text(
          'Lista de Contatos',
          style: TextStyle(fontSize: 16, color: Colors.black87),
        ),
        centerTitle: true,
        bottom: PreferredSize(preferredSize: Size.fromHeight(1), child: Container(
          color: Colors.grey.shade300,
          height: 1,
        ))
      ),
      body: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16.0, vertical: 24.0),
        child: pages[currentPage],
      ),
      bottomNavigationBar: Container(
        height: 60,
        decoration: BoxDecoration(
          border: Border(top: BorderSide(color: Colors.grey, width: 0.5)),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            GestureDetector(
              onTap: () {
                setPage(0);
                setState(() {});
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    currentPage == 0 ? Icons.home : Icons.home_outlined,
                    color: currentPage == 0 ? Colors.red : Colors.grey,
                  ),
                  Text(
                    'Home',
                    style: TextStyle(
                      color: currentPage == 0 ? Colors.red : Colors.grey,
                      fontWeight: .w500
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setPage(1);
                setState(() {});
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    currentPage == 1 ? Icons.star : Icons.star_outline,
                    color: currentPage == 1 ? Colors.red : Colors.grey,
                  ),
                  Text(
                    'Favoritos',
                    style: TextStyle(
                      color: currentPage == 1 ? Colors.red : Colors.grey,
                      fontWeight: .w500
                    ),
                  ),
                ],
              ),
            ),
            GestureDetector(
              onTap: () {
                setPage(2);
                setState(() {});
              },
              child: Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Icon(
                    currentPage == 2 ? Icons.settings : Icons.settings_outlined,
                    color: currentPage == 2 ? Colors.red : Colors.grey,
                  ),
                  Text(
                    'Configurações',
                    style: TextStyle(
                      color: currentPage == 2 ? Colors.red : Colors.grey,
                      fontWeight: .w500
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }
}
