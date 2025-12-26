import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../routes/app_router.dart';
import '../../../core/theme/app_colors.dart';

class AdminDrawer extends StatelessWidget {
  final String currentRoute;

  const AdminDrawer({
    super.key,
    required this.currentRoute,
  });

  Future<void> _handleLogout(BuildContext context) async {
    final authProvider = context.read<AuthProvider>();

    final confirm = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Odlogiraj se'),
        content: const Text('Da li ste sigurni da želite da se odlogirate?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(context).pop(false),
            child: const Text('Otkaži'),
          ),
          TextButton(
            onPressed: () => Navigator.of(context).pop(true),
            child: const Text(
              'Odlogiraj se',
              style: TextStyle(color: AppColors.error),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      await authProvider.logout();
      if (context.mounted) {
        AppRouter.navigateAndRemoveUntil(context, AppRouter.login);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.user;

    return Drawer(
      backgroundColor: AppColors.surface,
      child: SafeArea(
        child: Column(
          children: [
            // User Info Header
            Container(
              width: double.infinity,
              padding: const EdgeInsets.all(24),
              decoration: const BoxDecoration(
                gradient: LinearGradient(
                  colors: [AppColors.primary, AppColors.primaryDark],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  CircleAvatar(
                    radius: 30,
                    backgroundColor: AppColors.white,
                    child: Text(
                      user?.fullName.substring(0, 1).toUpperCase() ?? 'A',
                      style: const TextStyle(
                        fontSize: 24,
                        fontWeight: FontWeight.bold,
                        color: AppColors.primary,
                      ),
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    user?.fullName ?? 'Admin',
                    style: const TextStyle(
                      fontSize: 18,
                      fontWeight: FontWeight.bold,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    user?.email ?? '',
                    style: const TextStyle(
                      fontSize: 14,
                      color: AppColors.white,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                    decoration: BoxDecoration(
                      color: AppColors.white.withValues(alpha: 0.2),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      user?.role ?? 'Admin',
                      style: const TextStyle(
                        fontSize: 12,
                        color: AppColors.white,
                        fontWeight: FontWeight.w500,
                      ),
                    ),
                  ),
                ],
              ),
            ),

            // Menu Items
            Expanded(
              child: ListView(
                padding: EdgeInsets.zero,
                children: [
                  _DrawerMenuItem(
                    icon: Icons.dashboard_outlined,
                    title: 'Dashboard',
                    route: AppRouter.adminDashboard,
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != AppRouter.adminDashboard) {
                        AppRouter.navigateTo(context, AppRouter.adminDashboard);
                      }
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.shopping_bag_outlined,
                    title: 'Proizvodi',
                    route: AppRouter.adminProducts,
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != AppRouter.adminProducts) {
                        AppRouter.navigateTo(context, AppRouter.adminProducts);
                      }
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.inventory_2_outlined,
                    title: 'Skladište',
                    route: AppRouter.inventory,
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != AppRouter.inventory) {
                        AppRouter.navigateTo(context, AppRouter.inventory);
                      }
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.shopping_cart_outlined,
                    title: 'Nabavka',
                    route: AppRouter.procurement,
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != AppRouter.procurement) {
                        AppRouter.navigateTo(context, AppRouter.procurement);
                      }
                    },
                  ),
                  _DrawerMenuItem(
                    icon: Icons.bar_chart_outlined,
                    title: 'Statistika',
                    route: AppRouter.statistics,
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != AppRouter.statistics) {
                        AppRouter.navigateTo(context, AppRouter.statistics);
                      }
                    },
                  ),
                  const Divider(),
                  _DrawerMenuItem(
                    icon: Icons.person_outline,
                    title: 'Profil',
                    route: AppRouter.profile,
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != AppRouter.profile) {
                        AppRouter.navigateTo(context, AppRouter.profile);
                      }
                    },
                  ),
                ],
              ),
            ),

            // Logout Button
            Padding(
              padding: const EdgeInsets.all(16),
              child: ListTile(
                leading: const Icon(Icons.logout, color: AppColors.error),
                title: const Text(
                  'Odlogiraj se',
                  style: TextStyle(color: AppColors.error),
                ),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                  side: const BorderSide(color: AppColors.error),
                ),
                onTap: () {
                  Navigator.pop(context);
                  _handleLogout(context);
                },
              ),
            ),
          ],
        ),
      ),
    );
  }
}

// Private Drawer Menu Item Widget
class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String route;
  final String currentRoute;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    required this.route,
    required this.currentRoute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentRoute == route;

    return ListTile(
      leading: Icon(
        icon,
        color: isSelected ? AppColors.primary : AppColors.textPrimary,
      ),
      title: Text(
        title,
        style: TextStyle(
          color: isSelected ? AppColors.primary : AppColors.textPrimary,
          fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
        ),
      ),
      selected: isSelected,
      selectedTileColor: AppColors.primary.withValues(alpha: 0.1),
      onTap: onTap,
    );
  }
}