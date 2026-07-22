import 'package:flutter/material.dart';
import 'package:z_calculator/screens/calculator_screen.dart';
import 'theme.dart';
import 'screens/currency_convertor_screen.dart';

void main() {
  runApp(const SmartCalculatorApp());
}

class SmartCalculatorApp extends StatefulWidget {
  const SmartCalculatorApp({super.key});

  @override
  State<SmartCalculatorApp> createState() => _SmartCalculatorAppState();
}

class _SmartCalculatorAppState extends State<SmartCalculatorApp> {
  ThemeMode _themeMode = ThemeMode.light;

  void _toggleTheme() {
    setState(() {
      _themeMode =
      _themeMode == ThemeMode.light ? ThemeMode.dark : ThemeMode.light;
    });
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Smart Calculator',
      debugShowCheckedModeBanner: false,
      theme: AppTheme.light,
      darkTheme: AppTheme.dark,
      themeMode: _themeMode,
      home: HomeShell(themeMode: _themeMode, onToggleTheme: _toggleTheme),
    );
  }
}

/// Hosts both pages in a swipeable [PageView] synced with a bottom
/// [NavigationBar], giving the user either navigation method.
class HomeShell extends StatefulWidget {
  final ThemeMode themeMode;
  final VoidCallback onToggleTheme;

  const HomeShell({
    super.key,
    required this.themeMode,
    required this.onToggleTheme,
  });

  @override
  State<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends State<HomeShell> {
  int _index = 0;
  late final PageController _pageController;

  @override
  void initState() {
    super.initState();
    _pageController = PageController(initialPage: 0);
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  void _onNavTap(int index) {
    setState(() => _index = index);
    _pageController.animateToPage(
      index,
      duration: const Duration(milliseconds: 300),
      curve: Curves.easeInOut,
    );
  }

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Scaffold(
      body: PageView(
        controller: _pageController,
        onPageChanged: (i) => setState(() => _index = i),
        children: [
          CalculatorScreen(
            themeMode: widget.themeMode,
            onToggleTheme: widget.onToggleTheme,
          ),
          const CurrencyConverterScreen(),
        ],
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _index,
        onDestinationSelected: _onNavTap,
        backgroundColor: theme.colorScheme.surface,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.calculate_outlined),
            selectedIcon: Icon(Icons.calculate),
            label: 'Calculator',
          ),
          NavigationDestination(
            icon: Icon(Icons.currency_exchange_outlined),
            selectedIcon: Icon(Icons.currency_exchange),
            label: 'Converter',
          ),
        ],
      ),
    );
  }
}
