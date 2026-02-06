import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import 'package:orders_mobile/providers/auth_provider.dart';
import 'package:orders_mobile/routes/app_router.dart';
import 'package:orders_mobile/core/theme/app_colors.dart';

class AdminDrawer extends StatelessWidget {
  final String currentRoute;

  const AdminDrawer({
    super.key,
    required this.currentRoute,
  });

  Future<void> _handleLogout(BuildContext context) async {
    final confirm = await showDialog<bool>(
      context: context,
      barrierDismissible: false,
      builder: (dialogContext) => AlertDialog(
        backgroundColor: AppColors.surface,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: AppColors.error.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(Icons.logout, color: AppColors.error, size: 24),
            ),
            const SizedBox(width: 12),
            const Text(
              'Odjava',
              style: TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
        content: const Text(
          'Da li ste sigurni da želite da se odjavite?',
          style: TextStyle(
            fontSize: 15,
            color: AppColors.textSecondary,
          ),
        ),
        actionsPadding: const EdgeInsets.all(16),
        actions: [
          TextButton(
            onPressed: () => Navigator.of(dialogContext).pop(false),
            style: TextButton.styleFrom(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
            ),
            child: Text(
              'Otkaži',
              style: TextStyle(
                color: AppColors.textSecondary,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
          ElevatedButton(
            onPressed: () => Navigator.of(dialogContext).pop(true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
              foregroundColor: AppColors.white,
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(12),
              ),
            ),
            child: const Text(
              'Odjavi se',
              style: TextStyle(fontWeight: FontWeight.w600),
            ),
          ),
        ],
      ),
    );

    if (confirm == true && context.mounted) {
      // ✅ FIX: Koristi navigator context, ne dialog context
      final navigator = Navigator.of(context);
      await context.read<AuthProvider>().logout();
      
      if (context.mounted) {
        navigator.pushNamedAndRemoveUntil(
          AppRouter.login,
          (route) => false,
        );
      }
    }
  }

  String _getInitial(String? fullName) {
    final name = (fullName ?? '').trim();
    if (name.isEmpty) return 'A';
    return name.characters.first.toUpperCase();
  }

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    return Drawer(
      backgroundColor: AppColors.background,
      child: SafeArea(
        child: Column(
          children: [
            // ✅ Compact Premium Header
            Container(
              padding: const EdgeInsets.all(20),
              decoration: BoxDecoration(
                gradient: LinearGradient(
                  colors: [
                    AppColors.primary,
                    AppColors.primary.withValues(alpha: 0.8),
                  ],
                  begin: Alignment.topLeft,
                  end: Alignment.bottomRight,
                ),
                boxShadow: [
                  BoxShadow(
                    color: AppColors.primary.withValues(alpha: 0.3),
                    blurRadius: 20,
                    offset: const Offset(0, 4),
                  ),
                ],
              ),
              child: Row(
                children: [
                  // Avatar (Compact)
                  Container(
                    width: 48,
                    height: 48,
                    decoration: BoxDecoration(
                      color: AppColors.white,
                      shape: BoxShape.circle,
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withValues(alpha: 0.15),
                          blurRadius: 8,
                          offset: const Offset(0, 2),
                        ),
                      ],
                    ),
                    child: Center(
                      child: Text(
                        _getInitial(user?.fullName),
                        style: const TextStyle(
                          fontSize: 20,
                          fontWeight: FontWeight.bold,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  ),
                  
                  const SizedBox(width: 12),
                  
                  // User Info (Right Side)
                  Expanded(
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        // Name
                        Text(
                          user?.fullName ?? 'Admin',
                          style: const TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: AppColors.white,
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 2),
                        // Email
                        Text(
                          user?.email ?? '',
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.white.withValues(alpha: 0.85),
                            height: 1.2,
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                        const SizedBox(height: 6),
                        // Role Badge (Inline)
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
                              decoration: BoxDecoration(
                                color: AppColors.white.withValues(alpha: 0.2),
                                borderRadius: BorderRadius.circular(12),
                                border: Border.all(
                                  color: AppColors.white.withValues(alpha: 0.3),
                                  width: 1,
                                ),
                              ),
                              child: Row(
                                mainAxisSize: MainAxisSize.min,
                                children: [
                                  const Icon(
                                    Icons.admin_panel_settings_rounded,
                                    size: 12,
                                    color: AppColors.white,
                                  ),
                                  const SizedBox(width: 4),
                                  Text(
                                    user?.role ?? 'Admin',
                                    style: const TextStyle(
                                      fontSize: 10,
                                      color: AppColors.white,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                                ],
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),

            // ✅ Menu Items
            Expanded(
              child: ListView(
                padding: const EdgeInsets.symmetric(vertical: 8),
                children: [
                  // Admin Section Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'ADMIN',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  
                  _DrawerMenuItem(
                    icon: Icons.dashboard_rounded,
                    title: 'Dashboard',
                    subtitle: 'View statistics and analytics',
                    route: AppRouter.adminDashboard,
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != AppRouter.adminDashboard) {
                        Navigator.pushReplacementNamed(context, AppRouter.adminDashboard);
                      }
                    },
                  ),
                  
                  _DrawerMenuItem(
                    icon: Icons.inventory_2_rounded,
                    title: 'Products',
                    subtitle: 'Manage menu items',
                    route: AppRouter.adminProducts,
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != AppRouter.adminProducts) {
                        Navigator.pushReplacementNamed(context, AppRouter.adminProducts);
                      }
                    },
                  ),
                  
                  _DrawerMenuItem(
                    icon: Icons.warehouse_rounded,
                    title: 'Inventory',
                    subtitle: 'Track stock and supplies',
                    route: AppRouter.inventory,
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != AppRouter.inventory) {
                        Navigator.pushReplacementNamed(context, AppRouter.inventory);
                      }
                    },
                  ),
                  
                  _DrawerMenuItem(
                    icon: Icons.shopping_cart_rounded,
                    title: 'Procurement',
                    subtitle: 'Order supplies from stores',
                    route: AppRouter.procurementList,
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != AppRouter.procurementList) {
                        Navigator.pushReplacementNamed(context, AppRouter.procurementList);
                      }
                    },
                  ),
                  
                  _DrawerMenuItem(
                    icon: Icons.people_rounded,
                    title: 'Users',
                    subtitle: 'Manage staff accounts',
                    route: AppRouter.usersList,
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pushReplacementNamed(context, AppRouter.usersList);
                    },
                  ),
                  
                  _DrawerMenuItem(
                    icon: Icons.category_rounded,
                    title: 'Categories',
                    subtitle: 'Organize menu categories',
                    route: AppRouter.categoriesList, 
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pushReplacementNamed(context, AppRouter.categoriesList);
                    },
                  ),
                  
                  const SizedBox(height: 8),
                  
                  // Common Section Header
                  Padding(
                    padding: const EdgeInsets.fromLTRB(16, 8, 16, 8),
                    child: Text(
                      'GENERAL',
                      style: TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                        letterSpacing: 1.2,
                      ),
                    ),
                  ),
                  
                  _DrawerMenuItem(
                    icon: Icons.receipt_long_rounded,
                    title: 'Orders',
                    subtitle: 'View all orders',
                    route: AppRouter.orders,
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != AppRouter.orders) {
                        Navigator.pushReplacementNamed(context, AppRouter.orders);
                      }
                    },
                  ),
                  
                  _DrawerMenuItem(
                    icon: Icons.bar_chart_rounded,
                    title: 'Statistics',
                    subtitle: 'Business analytics',
                    route: AppRouter.adminStatistics,
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != AppRouter.adminStatistics) {
                        Navigator.pushReplacementNamed(context, AppRouter.adminStatistics);
                      }
                    },
                  ),
                  
                  const Padding(
                    padding: EdgeInsets.symmetric(horizontal: 16, vertical: 8),
                    child: Divider(height: 1),
                  ),
                  
                  _DrawerMenuItem(
                    icon: Icons.person_rounded,
                    title: 'Profile',
                    subtitle: 'Account settings',
                    route: AppRouter.profile,
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pop(context);
                      if (currentRoute != AppRouter.profile) {
                        Navigator.pushReplacementNamed(context, AppRouter.profile);
                      }
                    },
                  ),
                  
                  _DrawerMenuItem(
                    icon: Icons.info_rounded,
                    title: 'About',
                    subtitle: 'OrderS v1.0.0',
                    route: '/about',
                    currentRoute: currentRoute,
                    onTap: () {
                      Navigator.pop(context);
                      showAboutDialog(
                        context: context,
                        applicationName: 'OrderS',
                        applicationVersion: '1.0.0',
                        applicationLegalese: '© 2025 OrderS - Café Management System',
                        children: [
                          const SizedBox(height: 16),
                          const Text(
                            'A comprehensive café/restaurant management system.',
                            textAlign: TextAlign.center,
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),

            // ✅ Logout Button (Premium Design)
            Padding(
              padding: const EdgeInsets.all(16),
              child: Material(
                color: Colors.transparent,
                child: InkWell(
                  onTap: () {
                    Navigator.pop(context); // ✅ Zatvori drawer prije dialoga
                    _handleLogout(context);
                  },
                  borderRadius: BorderRadius.circular(16),
                  child: Container(
                    padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 16),
                    decoration: BoxDecoration(
                      color: AppColors.error.withValues(alpha: 0.1),
                      borderRadius: BorderRadius.circular(16),
                      border: Border.all(
                        color: AppColors.error.withValues(alpha: 0.3),
                        width: 1.5,
                      ),
                    ),
                    child: Row(
                      children: [
                        Container(
                          padding: const EdgeInsets.all(8),
                          decoration: BoxDecoration(
                            color: AppColors.error.withValues(alpha: 0.15),
                            borderRadius: BorderRadius.circular(10),
                          ),
                          child: const Icon(
                            Icons.logout_rounded,
                            color: AppColors.error,
                            size: 20,
                          ),
                        ),
                        const SizedBox(width: 12),
                        const Text(
                          'Odjavi se',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.w600,
                            color: AppColors.error,
                          ),
                        ),
                        const Spacer(),
                        Icon(
                          Icons.arrow_forward_ios_rounded,
                          size: 16,
                          color: AppColors.error.withValues(alpha: 0.5),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
            ),

            const SizedBox(height: 8),
          ],
        ),
      ),
    );
  }
}

class _DrawerMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String? subtitle;
  final String route;
  final String currentRoute;
  final VoidCallback onTap;

  const _DrawerMenuItem({
    required this.icon,
    required this.title,
    this.subtitle,
    required this.route,
    required this.currentRoute,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    final isSelected = currentRoute == route;

    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 2),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Container(
            padding: const EdgeInsets.symmetric(vertical: 12, horizontal: 12),
            decoration: BoxDecoration(
              color: isSelected
                  ? AppColors.primary.withValues(alpha: 0.12)
                  : Colors.transparent,
              borderRadius: BorderRadius.circular(12),
              border: isSelected
                  ? Border.all(
                      color: AppColors.primary.withValues(alpha: 0.3),
                      width: 1.5,
                    )
                  : null,
            ),
            child: Row(
              children: [
                Container(
                  padding: const EdgeInsets.all(8),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary.withValues(alpha: 0.15)
                        : AppColors.textSecondary.withValues(alpha: 0.08),
                    borderRadius: BorderRadius.circular(10),
                  ),
                  child: Icon(
                    icon,
                    size: 20,
                    color: isSelected ? AppColors.primary : AppColors.textSecondary,
                  ),
                ),
                const SizedBox(width: 12),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        title,
                        style: TextStyle(
                          fontSize: 15,
                          fontWeight: isSelected ? FontWeight.w600 : FontWeight.w500,
                          color: isSelected ? AppColors.primary : AppColors.textPrimary,
                        ),
                      ),
                      if (subtitle != null) ...[
                        const SizedBox(height: 2),
                        Text(
                          subtitle!,
                          style: TextStyle(
                            fontSize: 11,
                            color: AppColors.textSecondary.withValues(alpha: 0.7),
                          ),
                          maxLines: 1,
                          overflow: TextOverflow.ellipsis,
                        ),
                      ],
                    ],
                  ),
                ),
                if (isSelected)
                  Container(
                    width: 6,
                    height: 6,
                    decoration: const BoxDecoration(
                      color: AppColors.primary,
                      shape: BoxShape.circle,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}