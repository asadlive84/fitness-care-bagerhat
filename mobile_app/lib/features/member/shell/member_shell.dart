import 'package:fitness_care_bagerhat/app/router/routes.dart';
import 'package:fitness_care_bagerhat/app/theme/app_colors.dart';
import 'package:fitness_care_bagerhat/app/theme/app_text.dart';
import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';

class MemberShell extends StatelessWidget {
  const MemberShell({
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
              icon: Icon(PhosphorIcons.barbell()),
              activeIcon: Icon(PhosphorIcons.barbell(PhosphorIconsStyle.fill)),
              label: 'Logs',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.chatTeardropDots()),
              activeIcon:
                  Icon(PhosphorIcons.chatTeardropDots(PhosphorIconsStyle.fill)),
              label: 'Messages',
            ),
            BottomNavigationBarItem(
              icon: Icon(PhosphorIcons.user()),
              activeIcon: Icon(PhosphorIcons.user(PhosphorIconsStyle.fill)),
              label: 'Profile',
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
    if (location.startsWith('/member/logs')) return 1;
    if (location.startsWith('/member/messages')) return 2;
    if (location.startsWith('/member/profile')) return 3;
    return 0; // Home
  }

  void _onTap(BuildContext context, int index) {
    switch (index) {
      case 0:
        context.go(Routes.memberHome);
      case 1:
        context.go(Routes.memberLogs);
      case 2:
        context.go(Routes.memberMessages);
      case 3:
        context.go(Routes.memberProfile);
    }
  }
}
