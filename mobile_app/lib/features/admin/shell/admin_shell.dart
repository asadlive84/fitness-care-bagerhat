import 'package:fitness_care_bagerhat/app/router/routes.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

/// ## AdminShell
///
/// Main layout for Admin users with bottom navigation.
class AdminShell extends StatelessWidget {
  const AdminShell({
    required this.child,
    super.key,
  });

  final Widget child;

  @override
  Widget build(BuildContext context) {
    final location = GoRouterState.of(context).matchedLocation;

    return Scaffold(
      body: child,
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.05),
              blurRadius: 10,
              offset: const Offset(0, -5),
            ),
          ],
        ),
        child: BottomNavigationBar(
          currentIndex: _getSelectedIndex(location),
          onTap: (index) => _onTap(context, index),
          items: [
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.house()),
              activeIcon: Icon(PhosphorIcons.house(PhosphorIconsStyle.fill)),
              label: 'Home',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.users()),
              activeIcon: Icon(PhosphorIcons.users(PhosphorIconsStyle.fill)),
              label: 'Members',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.creditCard()),
              activeIcon: Icon(PhosphorIcons.creditCard(PhosphorIconsStyle.fill)),
              label: 'Payments',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.chatTeardropDots()),
              activeIcon:
                  Icon(PhosphorIcons.chatTeardropDots(PhosphorIconsStyle.fill)),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.gear()),
              activeIcon: Icon(PhosphorIcons.gear(PhosphorIconsStyle.fill)),
              label: 'Settings',
            ),
          ],
          selectedLabelStyle: AppText.labelSmall,
          unselectedLabelStyle: AppText.labelSmall,
          type: BottomNavigationBarType.fixed,
        ),
      ),
    );
  }

  int _getSelectedIndex(String location) {
    if (location.startsWith('/admin/members')) return 1;
    if (location.startsWith('/admin/payments')) return 2;
    if (location.startsWith('/admin/messages')) return 3;
    if (location.startsWith('/admin/settings')) return 4;
    return 0; // Dashboard
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(Routes.adminDashboard);
      case 1:
        context.go(Routes.adminMembers);
      case 2:
        context.go(Routes.adminPayments);
      case 3:
        context.go(Routes.adminMessages);
      case 4:
        context.go(Routes.adminSettings);
    }
  }
}
