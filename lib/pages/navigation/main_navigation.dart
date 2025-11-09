import 'package:chicken_grills/pages/navigation/tabs/account_tab.dart';
import 'package:chicken_grills/pages/navigation/tabs/discover_tab.dart';
import 'package:chicken_grills/pages/navigation/tabs/map_tab.dart';
import 'package:chicken_grills/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key, this.initialIndex = 0});

  final int initialIndex;

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  late int _currentIndex = widget.initialIndex;

  late final List<Widget> _pages = const [
    MapTab(),
    AboutTab(),
    AccountTab(),
  ];

  static const List<_NavItem> _items = [
    _NavItem(
      label: 'Carte',
      assetPath: 'assets/images/home.png',
    ),
    _NavItem(
      label: 'À propos',
      assetPath: 'assets/images/tools.png',
    ),
    _NavItem(
      label: 'Espace pro',
      assetPath: 'assets/images/history.png',
    ),
  ];

  void _onItemTapped(int index) {
    if (_currentIndex == index) {
      return;
    }
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppTheme.backgroundPeach,
      extendBody: true,
      body: IndexedStack(
        index: _currentIndex,
        children: _pages,
      ),
      bottomNavigationBar: _BottomNavigationBar(
        items: _items,
        currentIndex: _currentIndex,
        onTap: _onItemTapped,
      ),
    );
  }
}

class _BottomNavigationBar extends StatelessWidget {
  const _BottomNavigationBar({
    required this.items,
    required this.currentIndex,
    required this.onTap,
  });

  final List<_NavItem> items;
  final int currentIndex;
  final ValueChanged<int> onTap;

  @override
  Widget build(BuildContext context) {
    return SizedBox(
      height: 80,
      child: Container(
        decoration: const BoxDecoration(
          color: AppTheme.primaryOrange,
          borderRadius: BorderRadius.only(
            topLeft: Radius.circular(24),
            topRight: Radius.circular(24),
          ),
        ),
        padding: const EdgeInsets.only(bottom: 12, top: 10),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.spaceEvenly,
          children: [
            for (int i = 0; i < items.length; i++)
              _NavButton(
                item: items[i],
                isSelected: currentIndex == i,
                onTap: () => onTap(i),
              ),
          ],
        ),
      ),
    );
  }
}

class _NavButton extends StatelessWidget {
  const _NavButton({
    required this.item,
    required this.isSelected,
    required this.onTap,
  });

  final _NavItem item;
  final bool isSelected;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    final Color selectedColor = AppTheme.secondaryOrange;

    return GestureDetector(
      onTap: onTap,
      child: SizedBox(
        width: 80,
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              item.assetPath,
              width: 28,
              height: 28,
              fit: BoxFit.contain,
              color: isSelected ? selectedColor : Colors.white,
            ),
            const SizedBox(height: 6),
            Text(
              item.label,
              style: TextStyle(
                color: isSelected ? selectedColor : Colors.white,
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _NavItem {
  const _NavItem({required this.label, required this.assetPath});

  final String label;
  final String assetPath;
}

