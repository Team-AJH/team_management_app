import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../backend/services/firebase/auth_service.dart';
import '../theme/theme_model.dart';
import 'dashboard_page.dart';
import 'notifications_page.dart';
import 'roster_page.dart';
import 'expenses_page.dart';
import 'messages_page.dart';
import 'admin_dashboard_page.dart';
import 'browse_groups_page.dart';
import 'events_page.dart';
import 'player_ratings_page.dart';
import 'announcements_page.dart';

class MainLayout extends StatefulWidget {
  const MainLayout({super.key});

  @override
  State<MainLayout> createState() => _MainLayoutState();
}

class _MainLayoutState extends State<MainLayout> {
  int _selectedIndex = 0;

  void _navigate(int index) {
    setState(() {
      _selectedIndex = index;
    });
  }

  List<Widget> get _pages => [
    DashboardPage(onNavigate: _navigate), // 0
    const MessagesPage(),                 // 1
    const NotificationsPage(),            // 2
    const RosterPage(),                   // 3
    const ExpensesPage(),                 // 4
    const AdminDashboardPage(),           // 5
    const BrowseGroupsPage(),             // 6
    const EventsPage(),                   // 7
    const PlayerRatingsPage(),            // 8
    const AnnouncementsPage(),            // 9
  ];

  final List<String> _titles = [
    'Dashboard',
    'Messages',
    'Notifications',
    'Roster Management',
    'Team Expenses',
    'Admin Dashboard',
    'Browse Groups',
    'Events',
    'Player Ratings',
    'Announcements',
  ];

  void _selectIndex(int index) {
    setState(() => _selectedIndex = index);
    Navigator.pop(context);
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_titles[_selectedIndex]),
        actions: [
          Consumer<ThemeModel>(
            builder: (context, themeModel, child) {
              return IconButton(
                icon: Icon(
                  themeModel.isDarkMode ? Icons.light_mode : Icons.dark_mode,
                ),
                onPressed: () => themeModel.toggleTheme(),
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

            // ── General ──────────────────────────────────────────────────
            _DrawerItem(
              icon: Icons.dashboard,
              label: 'Dashboard',
              index: 0,
              selected: _selectedIndex,
              onTap: () => _selectIndex(0),
            ),
            _DrawerItem(
              icon: Icons.message,
              label: 'Messages',
              index: 1,
              selected: _selectedIndex,
              onTap: () => _selectIndex(1),
            ),
            _DrawerItem(
              icon: Icons.notifications,
              label: 'Notifications',
              index: 2,
              selected: _selectedIndex,
              onTap: () => _selectIndex(2),
            ),

            const Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'GROUPS & EVENTS',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            _DrawerItem(
              icon: Icons.explore,
              label: 'Browse Groups',
              index: 6,
              selected: _selectedIndex,
              onTap: () => _selectIndex(6),
            ),
            _DrawerItem(
              icon: Icons.event,
              label: 'Events',
              index: 7,
              selected: _selectedIndex,
              onTap: () => _selectIndex(7),
            ),
            _DrawerItem(
              icon: Icons.campaign,
              label: 'Announcements',
              index: 9,
              selected: _selectedIndex,
              onTap: () => _selectIndex(9),
            ),

            const Divider(),
            Padding(
              padding: const EdgeInsets.only(left: 16, top: 4, bottom: 4),
              child: Align(
                alignment: Alignment.centerLeft,
                child: Text(
                  'TEAM',
                  style: TextStyle(
                    fontSize: 11,
                    fontWeight: FontWeight.bold,
                    color: Colors.grey[500],
                    letterSpacing: 1,
                  ),
                ),
              ),
            ),
            _DrawerItem(
              icon: Icons.group,
              label: 'Roster Management',
              index: 3,
              selected: _selectedIndex,
              onTap: () => _selectIndex(3),
            ),
            _DrawerItem(
              icon: Icons.star,
              label: 'Player Ratings',
              index: 8,
              selected: _selectedIndex,
              onTap: () => _selectIndex(8),
            ),
            _DrawerItem(
              icon: Icons.attach_money,
              label: 'Team Expenses',
              index: 4,
              selected: _selectedIndex,
              onTap: () => _selectIndex(4),
            ),

            const Divider(),
            _DrawerItem(
              icon: Icons.admin_panel_settings,
              label: 'Admin Dashboard',
              index: 5,
              selected: _selectedIndex,
              onTap: () => _selectIndex(5),
            ),

            const Spacer(),
            const Divider(),
            ListTile(
              leading: const Icon(Icons.logout, color: Colors.red),
              title: const Text(
                'Logout',
                style: TextStyle(color: Colors.red),
              ),
              onTap: () async {
                Navigator.pop(context);
                await AuthService().signOut();
              },
            ),
            const SizedBox(height: 8),
          ],
        ),
      ),
      body: _pages[_selectedIndex],
    );
  }
}

class _DrawerItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final int index;
  final int selected;
  final VoidCallback onTap;

  const _DrawerItem({
    required this.icon,
    required this.label,
    required this.index,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = selected == index;
    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? Theme.of(context).primaryColor : null,
      ),
      title: Text(
        label,
        style: isSelected
            ? TextStyle(
                color: Theme.of(context).primaryColor,
                fontWeight: FontWeight.bold,
              )
            : null,
      ),
      selected: isSelected,
      selectedTileColor:
          Theme.of(context).primaryColor.withValues(alpha: 0.08),
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      onTap: onTap,
    );
  }
}
