import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../../../providers/auth_provider.dart';
import '../../../core/theme/app_colors.dart';
import '../../../routes/app_router.dart';

class CustomBottomNavBar extends StatelessWidget {
  final int currentIndex;

  const CustomBottomNavBar({
    super.key,
    required this.currentIndex,
  });

  @override
  Widget build(BuildContext context) {
    final authProvider = context.watch<AuthProvider>();
    final user = authProvider.currentUser;

    // ✅ ROLE-BASED NAV ITEMS
    List<BottomNavigationBarItem> items;
    
    if (user?.isBartender == true) {
      items = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.local_bar),
          label: 'Bar Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else if (user?.isKitchen == true) {
      items = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant),
          label: 'Kitchen Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    } else {
      // Default Waiter nav
      items = const [
        BottomNavigationBarItem(
          icon: Icon(Icons.table_restaurant),
          label: 'Tables',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.restaurant_menu),
          label: 'Products',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.receipt_long),
          label: 'Orders',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.shopping_cart),
          label: 'Cart',
        ),
        BottomNavigationBarItem(
          icon: Icon(Icons.person),
          label: 'Profile',
        ),
      ];
    }

    return BottomNavigationBar(
      currentIndex: currentIndex,
      type: BottomNavigationBarType.fixed,
      backgroundColor: AppColors.surface,
      selectedItemColor: AppColors.primary,
      unselectedItemColor: AppColors.textSecondary,
      onTap: (index) => _onItemTapped(context, index, user),
      items: items,
    );
  }

  void _onItemTapped(BuildContext context, int index, user) {
    if (index == currentIndex) return;

    // ✅ ROLE-BASED ROUTING
    if (user?.isBartender == true) {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, AppRouter.barOrders);
          break;
        case 1:
          Navigator.pushReplacementNamed(context, AppRouter.profile);
          break;
      }
    } else if (user?.isKitchen == true) {
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, AppRouter.kitchenOrders);
          break;
        case 1:
          Navigator.pushReplacementNamed(context, AppRouter.profile);
          break;
      }
    } else {
      // Default Waiter routing
      switch (index) {
        case 0:
          Navigator.pushReplacementNamed(context, AppRouter.tables);
          break;
        case 1:
          Navigator.pushReplacementNamed(context, AppRouter.products);
          break;
        case 2:
          Navigator.pushReplacementNamed(context, AppRouter.orders);
          break;
        case 3:
          Navigator.pushReplacementNamed(context, AppRouter.checkout);
          break;
        case 4:
          Navigator.pushReplacementNamed(context, AppRouter.profile);
          break;
      }
    }
  }
}