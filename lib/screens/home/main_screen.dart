import 'package:flutter/material.dart';
import 'package:amman_tms_mobile/screens/route/routes_screen.dart' as routes;
import 'package:amman_tms_mobile/screens/user/profile_screen.dart' as profile;
import 'home_screen.dart';
import 'package:amman_tms_mobile/screens/map/multi_bus_map_screen.dart'
    as map_screen;

const kPrimaryBlue = Color(0xFF163458);
const kAccentGold = Color(0xFFC88C2C);
const kLightGray = Color(0xFFF4F6F9);

class MainScreen extends StatefulWidget {
  final VoidCallback onLogout;
  final String userRole;
  final String? busName;

  const MainScreen({
    super.key,
    required this.onLogout,
    required this.userRole,
    this.busName,
  });

  @override
  State<MainScreen> createState() => _MainScreenState();
}

class _MainScreenState extends State<MainScreen> {
  int _selectedIndex = 0;
  late final List<Widget> _screens;

  @override
  void initState() {
    super.initState();
    _screens = [
      HomeScreen(userRole: widget.userRole, busName: widget.busName),
      routes.RoutesScreen(
        onLogout: widget.onLogout,
        userRole: widget.userRole,
        busName: widget.busName,
      ),
      map_screen.MultiBusMapScreen(),
      profile.ProfileScreen(onLogout: widget.onLogout),
    ];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: kLightGray,
      body: IndexedStack(index: _selectedIndex, children: _screens),
      bottomNavigationBar: NavigationBar(
        selectedIndex: _selectedIndex,
        onDestinationSelected: (index) {
          setState(() {
            _selectedIndex = index;
          });
        },
        backgroundColor: Colors.white,
        elevation: 8,
        shadowColor: kPrimaryBlue.withOpacity(0.1),
        indicatorColor: kAccentGold.withOpacity(0.1),
        labelBehavior: NavigationDestinationLabelBehavior.onlyShowSelected,
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home, color: kAccentGold),
            label: 'Home',
          ),
          NavigationDestination(
            icon: Icon(Icons.route_outlined),
            selectedIcon: Icon(Icons.route, color: kAccentGold),
            label: 'Route',
          ),
          NavigationDestination(
            icon: Icon(Icons.map_outlined),
            selectedIcon: Icon(Icons.map, color: kAccentGold),
            label: 'Map',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person, color: kAccentGold),
            label: 'Profile',
          ),
        ],
      ),
    );
  }
}
