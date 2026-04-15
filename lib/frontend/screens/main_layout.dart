import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../theme/theme_model.dart';
import 'dashboard_page.dart';
import 'notifications_page.dart';
import 'roster_page.dart';
import 'expenses_page.dart';
import 'messages_page.dart';
import 'admin_dashboard_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  final List<Widget> _pages = [
    const DashboardPage(),
    const MessagesPage(),
    const NotificationsPage(),
    const RosterPage(),
    const ExpensesPage(),
    const AdminDashboardPage(),
  ];

  final List<String> _titles = [
    'Dashboard',
    'Messages',
    'Notifications',
    'Roster Management',
    'Team Expenses',
    'Admin Dashboard',
  ];

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          Consumer<ThemeModel>(
            builder: (context, themeModel, child) {
              return IconButton(
                icon: Icon(themeModel.isDarkMode ? Icons.light_mode : Icons.dark_mode),
                onPressed: () {
                  themeModel.toggleTheme();
                },
                tooltip: 'Toggle Theme',
              );
            },
          ),
          const SizedBox(width: 16),
        ],
      ),
      drawer: Drawer(
        child: Column(
          children: [
            DrawerHeader(
              decoration: BoxDecoration(
                color: Theme.of(context).primaryColor,
              ),
              child: const Center(
                child: Text(
                  'Sports Management',
                  style: TextStyle(
                    color: Colors.white,
                    fontSize: 24,
                    fontWeight: FontWeight.bold,
                  ),
                ),
              ),
            ),
            ListTile(
              leading: const Icon(Icons.dashboard),
              title: const Text('Dashboard'),
              selected: _selectedIndex == 0,
              onTap: () {
                setState(() {
                  _selectedIndex = 0;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.message),
              title: const Text('Messages'),
              selected: _selectedIndex == 1,
              onTap: () {
                setState(() {
                  _selectedIndex = 1;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.notifications),
              title: const Text('Notifications'),
              selected: _selectedIndex == 2,
              onTap: () {
                setState(() {
                  _selectedIndex = 2;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.group),
              title: const Text('Roster Management'),
              selected: _selectedIndex == 3,
              onTap: () {
                setState(() {
                  _selectedIndex = 3;
                });
                Navigator.pop(context);
              },
            ),
            ListTile(
              leading: const Icon(Icons.attach_money),
              title: const Text('Team Expenses'),
              selected: _selectedIndex == 4,
              onTap: () {
                setState(() {
                  _selectedIndex = 4;
                });
                Navigator.pop(context);
              },
            ),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.admin_panel_settings),
              title: const Text('Admin Dashboard'),
              selected: _selectedIndex == 5,
              onTap: () {
                setState(() {
                  _selectedIndex = 5;
                });
                Navigator.pop(context);
              },
            ),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}
