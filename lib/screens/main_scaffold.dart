import 'package:flutter/material.dart';
import 'package:myapp/screens/home_page.dart';
import 'package:myapp/screens/menu_page.dart';
import 'package:myapp/screens/reading_plan_page.dart';

class MainScaffold extends StatefulWidget {
  final int initialIndex;
  final bool showConfetti;
  
  const MainScaffold({
    super.key, 
    this.initialIndex = 0,
    this.showConfetti = false,
  });

  @override
  State<MainScaffold> createState() => _MainScaffoldState();
}

class _MainScaffoldState extends State<MainScaffold> {
  int _selectedIndex = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _selectedIndex = widget.initialIndex;
    _pageController = PageController(initialPage: _selectedIndex);
  }

  @override
  void didUpdateWidget(MainScaffold oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (widget.initialIndex != oldWidget.initialIndex) {
      setState(() {
        _selectedIndex = widget.initialIndex;
      });
      _pageController.jumpToPage(widget.initialIndex);
    }
  }

  List<Widget> get _widgetOptions => [
        const HomePage(),
        ReadingPlanPage(showConfetti: widget.showConfetti),
        const MenuPage(),
      ];

  void _onItemTapped(int index) {
    setState(() {
      _selectedIndex = index;
    });
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 250),
      curve: Curves.easeInOut,
    );
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final colorScheme = Theme.of(context).colorScheme;

    return Scaffold(
      body: PageView(
        controller: _pageController,
        physics: const BouncingScrollPhysics(),
        onPageChanged: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        children: _widgetOptions,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.06),
              blurRadius: 20,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: NavigationBar(
          selectedIndex: _selectedIndex,
          onDestinationSelected: _onItemTapped,
          elevation: 0,
          backgroundColor: Colors.white,
          surfaceTintColor: Colors.transparent,
          indicatorColor: colorScheme.primary.withOpacity(0.12),
          labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
          animationDuration: const Duration(milliseconds: 400),
          height: 70,
          destinations: [
            NavigationDestination(
              icon: Icon(Icons.home_outlined, color: Colors.grey.shade600),
              selectedIcon: Icon(Icons.home_rounded, color: colorScheme.primary),
              label: 'Início',
            ),
            NavigationDestination(
              icon: Icon(Icons.local_fire_department_outlined, color: Colors.grey.shade600),
              selectedIcon: Icon(Icons.local_fire_department_rounded, color: colorScheme.primary),
              label: 'Ofensiva',
            ),
            NavigationDestination(
              icon: Icon(Icons.person_outline_rounded, color: Colors.grey.shade600),
              selectedIcon: Icon(Icons.person_rounded, color: colorScheme.primary),
              label: 'Menu',
            ),
          ],
        ),
      ),
    );
  }
}

