
import 'package:flutter/material.dart';
import 'package:myapp/screens/home_page.dart';
import 'package:myapp/screens/menu_page.dart';
import 'package:myapp/screens/reading_plan_page.dart';

class MainScaffold extends StatefulWidget {
  const MainScaffold({super.key});

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0; // O índice inicial agora é 0 (Início)

  // Lista de telas disponíveis na navegação (sem a HistoryPage)
  static const List<Widget> _widgetOptions = <Widget>[
    HomePage(),
    ReadingPlanPage(),
    MenuPage(),
  ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Center(
        child: _widgetOptions.elementAt(_selectedIndex),
      ),
      bottomNavigationBar: BottomNavigationBar(
        items: const <BottomNavigationBarItem>[
          BottomNavigationBarItem(
            icon: Icon(Icons.home_outlined),
            activeIcon: Icon(Icons.home),
            label: 'Início',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.calendar_today_outlined),
            activeIcon: Icon(Icons.calendar_today),
            label: 'Plano',
          ),
          BottomNavigationBarItem(
            icon: Icon(Icons.menu_outlined),
            activeIcon: Icon(Icons.menu),
            label: 'Menu',
          ),
        ],
        currentIndex: _selectedIndex,
        selectedItemColor: Theme.of(context).colorScheme.primary,
        unselectedItemColor: Colors.grey[600],
        backgroundColor: Theme.of(context).cardColor,
        type: BottomNavigationBarType.fixed, // Garante que todos os itens apareçam
        onTap: _onItemTapped,
      ),
    );
  }
}
