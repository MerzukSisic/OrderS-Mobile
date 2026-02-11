import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_router.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  String _getRoleIcon(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return '👑';
      case 'waiter':
        return '🍽️';
      case 'bartender':
        return '🍺';
      case 'kitchen':
        return '👨‍🍳';
      default:
        return '👤';
    }
  }

  Color _getRoleBadgeColor(String role) {
    switch (role.toLowerCase()) {
      case 'admin':
        return const Color(0xFFFF6B6B); // Red for Admin
      case 'waiter':
        return AppColors.primary; // Primary color for Waiter
      case 'bartender':
        return const Color(0xFF4ECDC4); // Teal for Bartender
      case 'kitchen':
        return AppColors.warning; // Orange for Kitchen
      default:
        return AppColors.textSecondary;
    }
  }

  Future<void> _handleLogout(BuildContext context) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Logout'),
        content: const Text('Are you sure you want to logout?'),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('Cancel'),
          ),
          ElevatedButton(
            onPressed: () => Navigator.pop(context, true),
            style: ElevatedButton.styleFrom(
              backgroundColor: AppColors.error,
            ),
            child: const Text(
              'Logout',
              style: TextStyle(color: AppColors.white),
            ),
          ),
        ],
      ),
    );

    if (confirmed == true && context.mounted) {
      await context.read<AuthProvider>().logout();
      if (context.mounted) {
        Navigator.pushNamedAndRemoveUntil(
          context,
          AppRouter.login,
          (route) => false,
        );
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: AppColors.background,
      appBar: AppBar(
        title: const Text('Profile'),
        automaticallyImplyLeading: false,
        actions: [
          IconButton(
            icon: const Icon(Icons.settings_outlined),
            onPressed: () {
              ScaffoldMessenger.of(context).showSnackBar(
                const SnackBar(
                  content: Text('Settings - Coming soon'),
                  duration: Duration(seconds: 2),
                ),
              );
            },
          ),
        ],
      ),
      body: Consumer<AuthProvider>(
        builder: (context, authProvider, _) {
          final user = authProvider.currentUser;

          if (user == null) {
            return const Center(
              child: Text('Not logged in'),
            );
          }

          return SingleChildScrollView(
            child: Column(
              children: [
                const SizedBox(height: 24),

                // Profile Header
                Container(
                  margin: const EdgeInsets.symmetric(horizontal: 16),
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    color: AppColors.surface,
                    borderRadius: BorderRadius.circular(24),
                    boxShadow: [
                      BoxShadow(
                        color: Colors.black.withValues(alpha: 0.05),
                        blurRadius: 10,
                        offset: const Offset(0, 4),
                      ),
                    ],
                  ),
                  child: Column(
                    children: [
                      // Avatar
                      Container(
                        width: 100,
                        height: 100,
                        decoration: BoxDecoration(
                          gradient: LinearGradient(
                            begin: Alignment.topLeft,
                            end: Alignment.bottomRight,
                            colors: [
                              _getRoleBadgeColor(user.role).withValues(alpha: 0.8),
                              _getRoleBadgeColor(user.role),
                            ],
                          ),
                          shape: BoxShape.circle,
                          boxShadow: [
                            BoxShadow(
                              color: _getRoleBadgeColor(user.role).withValues(alpha: 0.3),
                              blurRadius: 12,
                              offset: const Offset(0, 4),
                            ),
                          ],
                        ),
                        child: Center(
                          child: Text(
                            user.fullName.isNotEmpty
                                ? user.fullName[0].toUpperCase()
                                : '?',
                            style: const TextStyle(
                              fontSize: 48,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Name
                      Text(
                        user.fullName,
                        style: const TextStyle(
                          fontSize: 24,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 8),

                      // Email
                      Text(
                        user.email,
                        style: TextStyle(
                          fontSize: 14,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Role Badge
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 20,
                          vertical: 10,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleBadgeColor(user.role).withValues(alpha: 0.15),
                          borderRadius: BorderRadius.circular(20),
                          border: Border.all(
                            color: _getRoleBadgeColor(user.role).withValues(alpha: 0.3),
                            width: 1.5,
                          ),
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            Text(
                              _getRoleIcon(user.role),
                              style: const TextStyle(fontSize: 18),
                            ),
                            const SizedBox(width: 8),
                            Text(
                              user.role,
                              style: TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.bold,
                                color: _getRoleBadgeColor(user.role),
                              ),
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 32),

                // Menu Options
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      const Padding(
                        padding: EdgeInsets.only(left: 4, bottom: 12),
                        child: Text(
                          'MENU',
                          style: TextStyle(
                            fontSize: 13,
                            fontWeight: FontWeight.w700,
                            color: AppColors.textSecondary,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),

                      // ============================================
                      // 👑 ADMIN SECTION
                      // ============================================
                      if (authProvider.isAdmin) ...[
                        _ProfileMenuItem(
                          icon: Icons.dashboard_outlined,
                          title: 'Dashboard',
                          subtitle: 'View statistics and analytics',
                          onTap: () {
                             Navigator.pushNamed(context, AppRouter.adminDashboard);
                          },
                        ),
                        const SizedBox(height: 12),

                        _ProfileMenuItem(
                          icon: Icons.inventory_2_outlined,
                          title: 'Products',
                          subtitle: 'Manage menu items',
                          onTap: () {
                            Navigator.pushNamed(context, AppRouter.adminProducts);
                          },
                        ),
                        const SizedBox(height: 12),

                        _ProfileMenuItem(
                          icon: Icons.warehouse_outlined,
                          title: 'Inventory',
                          subtitle: 'Track stock and supplies',
                          onTap: () {
                               Navigator.pushNamed(context, AppRouter.inventory);
                          },
                        ),
                        const SizedBox(height: 12),

                        _ProfileMenuItem(
                          icon: Icons.shopping_cart_outlined,
                          title: 'Procurement',
                          subtitle: 'Order supplies from stores',
                           onTap: () {
                               Navigator.pushNamed(context, AppRouter.procurementList);
                          },
                        ),
                        const SizedBox(height: 12),

                        _ProfileMenuItem(
                          icon: Icons.people_outline,
                          title: 'Users',
                          subtitle: 'Manage staff accounts',
                          onTap: () {
                               Navigator.pushNamed(context, AppRouter.usersList);
                          },
                        ),
                        const SizedBox(height: 12),

                        _ProfileMenuItem(
                          icon: Icons.category_outlined,
                          title: 'Categories',
                          subtitle: 'Organize menu categories',
                          onTap: () {
                               Navigator.pushNamed(context, AppRouter.categoriesList);
                          },
                        ),
                        const SizedBox(height: 12),

                        _ProfileMenuItem(
                          icon: Icons.receipt_long_outlined,
                          title: 'Orders',
                          subtitle: 'View all orders',
                          onTap: () {
                            Navigator.pushNamed(context, AppRouter.adminOrders);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ============================================
                      // 🍽️ WAITER SECTION
                      // ============================================
                      if (authProvider.isWaiter) ...[
                        _ProfileMenuItem(
                          icon: Icons.table_restaurant,
                          title: 'Tables',
                          subtitle: 'View and manage tables',
                          onTap: () {
                            Navigator.pushNamed(context, AppRouter.tables);
                          },
                        ),
                        const SizedBox(height: 12),

                        _ProfileMenuItem(
                          icon: Icons.restaurant_menu,
                          title: 'Menu',
                          subtitle: 'Browse products and create orders',
                          onTap: () {
                            Navigator.pushNamed(context, AppRouter.products);
                          },
                        ),
                        const SizedBox(height: 12),

                        _ProfileMenuItem(
                          icon: Icons.receipt_long_outlined,
                          title: 'My Orders',
                          subtitle: 'View your order history',
                          onTap: () {
                            Navigator.pushNamed(context, AppRouter.orders);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ============================================
                      // 🍺 BARTENDER SECTION
                      // ============================================
                      if (authProvider.isBartender) ...[
                        _ProfileMenuItem(
                          icon: Icons.local_bar,
                          title: 'Bar Orders',
                          subtitle: 'View and manage drink orders',
                          iconColor: AppColors.info,
                          onTap: () {
                            Navigator.pushNamed(context, AppRouter.barOrders);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],

                      // ============================================
                      // 👨‍🍳 KITCHEN SECTION
                      // ============================================
                      if (authProvider.isKitchen) ...[
                        _ProfileMenuItem(
                          icon: Icons.restaurant,
                          title: 'Kitchen Orders',
                          subtitle: 'View and manage food orders',
                          iconColor: AppColors.warning,
                          onTap: () {
                            Navigator.pushNamed(context, AppRouter.kitchenOrders);
                          },
                        ),
                        const SizedBox(height: 12),
                      ],
                      
                      // ============================================
                      // 📖 ABOUT (ALL ROLES)
                      // ============================================
                      _ProfileMenuItem(
                        icon: Icons.info_outline,
                        title: 'About',
                        subtitle: 'OrderS v1.0.0',
                        onTap: () {
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

                const SizedBox(height: 32),

                // Logout Button
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: SizedBox(
                    width: double.infinity,
                    height: 56,
                    child: ElevatedButton(
                      onPressed: () => _handleLogout(context),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.error,
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(16),
                        ),
                        elevation: 2,
                      ),
                      child: const Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(
                            Icons.logout,
                            color: AppColors.white,
                            size: 20,
                          ),
                          SizedBox(width: 12),
                          Text(
                            'Log out',
                            style: TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: AppColors.white,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),

                const SizedBox(height: 32),
              ],
            ),
          );
        },
      ),
    );
  }
}

// Profile Menu Item Widget
class _ProfileMenuItem extends StatelessWidget {
  final IconData icon;
  final String title;
  final String subtitle;
  final VoidCallback onTap;
  final Color? iconColor;

  const _ProfileMenuItem({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.onTap,
    this.iconColor,
  });

  @override
  Widget build(BuildContext context) {
    final effectiveIconColor = iconColor ?? AppColors.primary;

    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(16),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
            width: 1,
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.02),
              blurRadius: 4,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 48,
              height: 48,
              decoration: BoxDecoration(
                color: effectiveIconColor.withValues(alpha: 0.1),
                borderRadius: BorderRadius.circular(12),
              ),
              child: Icon(
                icon,
                color: effectiveIconColor,
                size: 24,
              ),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    title,
                    style: const TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  const SizedBox(height: 4),
                  Text(
                    subtitle,
                    style: TextStyle(
                      fontSize: 13,
                      color: AppColors.textSecondary.withValues(alpha: 0.8),
                    ),
                  ),
                ],
              ),
            ),
            Icon(
              Icons.arrow_forward_ios,
              size: 16,
              color: AppColors.textSecondary.withValues(alpha: 0.5),
            ),
          ],
        ),
      ),
    );
  }
}