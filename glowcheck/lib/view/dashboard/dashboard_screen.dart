import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/activity/activity_screen.dart';
import 'package:fitnessapp/view/camera/camera_screen.dart';
import 'package:fitnessapp/view/profile/user_profile.dart';
import 'package:flutter/foundation.dart';
import 'package:flutter/material.dart';

import '../home/home_screen.dart';

class DashboardScope extends InheritedWidget {
  const DashboardScope({
    super.key,
    required this.goTab,
    required super.child,
  });

  final void Function(int index) goTab;

  static DashboardScope? of(BuildContext context) {
    return context.dependOnInheritedWidgetOfExactType<DashboardScope>();
  }

  @override
  bool updateShouldNotify(DashboardScope oldWidget) => goTab != oldWidget.goTab;
}

class DashboardScreen extends StatefulWidget {
  static String routeName = "/DashboardScreen";

  const DashboardScreen({Key? key}) : super(key: key);

  @override
  State<DashboardScreen> createState() => _DashboardScreenState();
}

class _DashboardScreenState extends State<DashboardScreen> {
  int selectTab = 0;

  final List<Widget> _widgetOptions = const [
    HomeScreen(),
    ActivityScreen(),
    CameraScreen(),
    UserProfile(),
  ];

  void goTab(int index) {
    if (mounted) setState(() => selectTab = index);
  }

  @override
  Widget build(BuildContext context) {
    final bottom = MediaQuery.paddingOf(context).bottom;
    final double dockBottom = kIsWeb ? 16.0 : 12.0 + (bottom > 0 ? bottom : 8.0);

    return DashboardScope(
      goTab: goTab,
      child: Scaffold(
        backgroundColor: AppColors.canvas,
        extendBody: true,
        body: Stack(
          children: [
            IndexedStack(
              index: selectTab,
              children: _widgetOptions,
            ),
            Positioned(
              left: 22,
              right: 22,
              bottom: dockBottom,
              child: _GlowDock(
                selected: selectTab,
                onSelect: goTab,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _GlowDock extends StatelessWidget {
  const _GlowDock({required this.selected, required this.onSelect});

  final int selected;
  final ValueChanged<int> onSelect;

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 68,
      padding: const EdgeInsets.symmetric(horizontal: 10),
      decoration: BoxDecoration(
        color: AppColors.inkSoft,
        borderRadius: BorderRadius.circular(36),
        boxShadow: GlowStyle.dock,
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _DockItem(icon: Icons.home_rounded, active: selected == 0, onTap: () => onSelect(0)),
          _DockItem(icon: Icons.grid_view_rounded, active: selected == 1, onTap: () => onSelect(1)),
          _DockItem(icon: Icons.photo_camera_rounded, active: selected == 2, onTap: () => onSelect(2)),
          _DockItem(icon: Icons.person_rounded, active: selected == 3, onTap: () => onSelect(3)),
        ],
      ),
    );
  }
}

class _DockItem extends StatelessWidget {
  const _DockItem({
    required this.icon,
    required this.active,
    required this.onTap,
  });

  final IconData icon;
  final bool active;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      customBorder: const CircleBorder(),
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        width: 48,
        height: 48,
        decoration: BoxDecoration(
          color: active ? AppColors.card : Colors.transparent,
          shape: BoxShape.circle,
        ),
        child: Icon(
          icon,
          size: 24,
          color: active ? AppColors.ink : const Color(0xFFB8B4AE),
        ),
      ),
    );
  }
}
