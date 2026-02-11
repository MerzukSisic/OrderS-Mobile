import 'package:flutter/material.dart';
import 'package:orders_mobile/core/theme/app_colors.dart';
import 'package:orders_mobile/core/utils/formatters.dart';
import 'package:orders_mobile/core/widgets/admin_scaffold.dart';
import 'package:orders_mobile/features/orders/widgets/order_status_badge.dart';
import 'package:orders_mobile/models/orders/order_model.dart';
import 'package:orders_mobile/providers/orders_provider.dart';
import 'package:orders_mobile/routes/app_router.dart';
import 'package:provider/provider.dart';


class AdminOrdersScreen extends StatefulWidget {
  const AdminOrdersScreen({super.key});

  @override
  State<AdminOrdersScreen> createState() => _AdminOrdersScreenState();
}

class _AdminOrdersScreenState extends State<AdminOrdersScreen> {
  final TextEditingController _searchController = TextEditingController();
  String _selectedStatus = 'All';
  String _selectedType = 'All';
  String _selectedWaiter = 'All'; // ✅ DODANO
  DateTimeRange? _dateRange;
  bool _showFilters = false;

  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<OrdersProvider>().fetchOrders();
    });
  }

  @override
  void dispose() {
    _searchController.dispose();
    super.dispose();
  }

  // ✅ Get unique waiters from orders
  List<String> _getUniqueWaiters(List<OrderModel> orders) {
    final waiters = orders.map((o) => o.waiterName).toSet().toList();
    waiters.sort();
    return waiters;
  }

  List<OrderModel> _filterOrders(List<OrderModel> orders) {
    var filtered = orders;

    // Search filter
    if (_searchController.text.isNotEmpty) {
      final query = _searchController.text.toLowerCase();
      filtered = filtered.where((order) {
        return order.id.toLowerCase().contains(query) ||
            order.waiterName.toLowerCase().contains(query) ||
            (order.tableNumber?.toString().contains(query) ?? false);
      }).toList();
    }

    // Status filter
    if (_selectedStatus != 'All') {
      filtered = filtered.where((order) => order.status == _selectedStatus).toList();
    }

    // Type filter
    if (_selectedType != 'All') {
      filtered = filtered.where((order) => order.type == _selectedType).toList();
    }

    // ✅ Waiter filter
    if (_selectedWaiter != 'All') {
      filtered = filtered.where((order) => order.waiterName == _selectedWaiter).toList();
    }

    // Date range filter
    if (_dateRange != null) {
      filtered = filtered.where((order) {
        return order.createdAt.isAfter(_dateRange!.start) &&
            order.createdAt.isBefore(_dateRange!.end.add(const Duration(days: 1)));
      }).toList();
    }

    return filtered;
  }

  Future<void> _selectDateRange() async {
    final picked = await showModalBottomSheet<DateTimeRange>(
      context: context,
      backgroundColor: Colors.transparent,
      isScrollControlled: true,
      builder: (context) => _DateRangeBottomSheet(
        initialDateRange: _dateRange,
      ),
    );

    if (picked != null) {
      setState(() => _dateRange = picked);
    }
  }

  void _clearFilters() {
    setState(() {
      _searchController.clear();
      _selectedStatus = 'All';
      _selectedType = 'All';
      _selectedWaiter = 'All'; // ✅ DODANO
      _dateRange = null;
    });
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Orders Management',
      currentRoute: AppRouter.adminOrders,
      body: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // Header with stats and actions
          Padding(
            padding: const EdgeInsets.all(24),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Consumer<OrdersProvider>(
                  builder: (context, provider, _) {
                    final filtered = _filterOrders(provider.orders);
                    return Text(
                      '${filtered.length} ${filtered.length == 1 ? 'order' : 'orders'} found',
                      style: const TextStyle(
                        color: AppColors.textSecondary,
                        fontSize: 14,
                        fontWeight: FontWeight.w500,
                      ),
                    );
                  },
                ),
                Row(
                  children: [
                    IconButton(
                      icon: Icon(
                        _showFilters ? Icons.filter_alt : Icons.filter_alt_outlined,
                        color: _showFilters ? AppColors.primary : AppColors.textSecondary,
                      ),
                      onPressed: () => setState(() => _showFilters = !_showFilters),
                      tooltip: 'Toggle Filters',
                    ),
                    const SizedBox(width: 8),
                    IconButton(
                      icon: const Icon(Icons.refresh, color: AppColors.textSecondary),
                      onPressed: () => context.read<OrdersProvider>().fetchOrders(),
                      tooltip: 'Refresh',
                    ),
                  ],
                ),
              ],
            ),
          ),

          // Search Bar
          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: TextField(
              controller: _searchController,
              decoration: InputDecoration(
                hintText: 'Search by Order ID, Waiter, or Table...',
                prefixIcon: const Icon(Icons.search),
                suffixIcon: _searchController.text.isNotEmpty
                    ? IconButton(
                        icon: const Icon(Icons.clear),
                        onPressed: () {
                          _searchController.clear();
                          setState(() {});
                        },
                      )
                    : null,
              ),
              onChanged: (value) => setState(() {}),
            ),
          ),

          // Filters Section
          if (_showFilters) ...[
            const SizedBox(height: 12),
            Container(
              margin: const EdgeInsets.symmetric(horizontal: 24),
              padding: const EdgeInsets.all(16), // ✅ Reduced from 20
              decoration: BoxDecoration(
                color: AppColors.surface,
                borderRadius: BorderRadius.circular(16),
                border: Border.all(
                  color: AppColors.textSecondary.withValues(alpha: 0.1),
                ),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      const Text(
                        'Filters',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      TextButton.icon(
                        onPressed: _clearFilters,
                        icon: const Icon(Icons.clear_all, size: 18),
                        label: const Text('Clear All'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.error,
                          padding: EdgeInsets.zero, // ✅ Remove padding
                          minimumSize: const Size(0, 32), // ✅ Compact size
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 12), // ✅ Reduced from 16
                  
                  // ✅ Use Consumer to get waiters list dynamically
                  Consumer<OrdersProvider>(
                    builder: (context, provider, _) {
                      final waiters = _getUniqueWaiters(provider.orders);
                      
                      return Column(
                        children: [
                          // Status Filter - FULL WIDTH
                          DropdownButtonFormField<String>(
                            value: _selectedStatus,
                            decoration: const InputDecoration(
                              labelText: 'Status',
                              prefixIcon: Icon(Icons.analytics_outlined),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), // ✅ Compact
                            ),
                            items: ['All', 'Pending', 'Preparing', 'Ready', 'Completed', 'Cancelled']
                                .map((status) => DropdownMenuItem(
                                      value: status,
                                      child: Text(status),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedStatus = value ?? 'All');
                            },
                          ),

                          const SizedBox(height: 12), // ✅ Reduced from 16

                          // Type Filter - FULL WIDTH
                          DropdownButtonFormField<String>(
                            value: _selectedType,
                            decoration: const InputDecoration(
                              labelText: 'Order Type',
                              prefixIcon: Icon(Icons.restaurant),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), // ✅ Compact
                            ),
                            items: ['All', 'DineIn', 'TakeAway']
                                .map((type) => DropdownMenuItem(
                                      value: type,
                                      child: Text(type == 'All'
                                          ? 'All'
                                          : type == 'DineIn'
                                              ? 'Dine In'
                                              : 'Take Away'),
                                    ))
                                .toList(),
                            onChanged: (value) {
                              setState(() => _selectedType = value ?? 'All');
                            },
                          ),

                          const SizedBox(height: 12), // ✅ Reduced from 16

                          // Waiter Filter - FULL WIDTH
                          DropdownButtonFormField<String>(
                            value: _selectedWaiter,
                            decoration: const InputDecoration(
                              labelText: 'Waiter',
                              prefixIcon: Icon(Icons.person),
                              contentPadding: EdgeInsets.symmetric(horizontal: 12, vertical: 12), // ✅ Compact
                            ),
                            items: [
                              const DropdownMenuItem(
                                value: 'All',
                                child: Text('All Waiters'),
                              ),
                              ...waiters.map((waiter) => DropdownMenuItem(
                                    value: waiter,
                                    child: Text(waiter),
                                  )),
                            ],
                            onChanged: (value) {
                              setState(() => _selectedWaiter = value ?? 'All');
                            },
                          ),

                          const SizedBox(height: 12), // ✅ Reduced from 16

                          // Date Range Picker - FULL WIDTH
                          OutlinedButton.icon(
                            onPressed: _selectDateRange,
                            icon: const Icon(Icons.date_range),
                            label: Text(
                              _dateRange == null
                                  ? 'Select Date Range'
                                  : '${Formatters.date(_dateRange!.start)} - ${Formatters.date(_dateRange!.end)}',
                              style: const TextStyle(fontSize: 13), // ✅ Smaller text
                            ),
                            style: OutlinedButton.styleFrom(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 16), // ✅ Reduced
                              alignment: Alignment.centerLeft,
                              minimumSize: const Size(double.infinity, 48), // ✅ Reduced from 56
                            ),
                          ),
                        ],
                      );
                    },
                  ),
                ],
              ),
            ),
          ],

          const SizedBox(height: 12), // ✅ Reduced from 16

          // Orders List
          Expanded(
            child: Consumer<OrdersProvider>(
              builder: (context, provider, _) {
                if (provider.isLoading && provider.orders.isEmpty) {
                  return const Center(child: CircularProgressIndicator());
                }

                if (provider.error != null && provider.orders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.error_outline,
                          size: 64,
                          color: AppColors.error.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        Text(
                          provider.error!,
                          style: const TextStyle(color: AppColors.textSecondary),
                          textAlign: TextAlign.center,
                        ),
                        const SizedBox(height: 16),
                        ElevatedButton.icon(
                          onPressed: () => provider.fetchOrders(),
                          icon: const Icon(Icons.refresh),
                          label: const Text('Retry'),
                        ),
                      ],
                    ),
                  );
                }

                final filteredOrders = _filterOrders(provider.orders);

                if (filteredOrders.isEmpty) {
                  return Center(
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(
                          Icons.receipt_long_outlined,
                          size: 64,
                          color: AppColors.textSecondary.withValues(alpha: 0.5),
                        ),
                        const SizedBox(height: 16),
                        const Text(
                          'No orders found',
                          style: TextStyle(
                            color: AppColors.textSecondary,
                            fontSize: 16,
                          ),
                        ),
                        if (_searchController.text.isNotEmpty ||
                            _selectedStatus != 'All' ||
                            _selectedType != 'All' ||
                            _selectedWaiter != 'All' ||
                            _dateRange != null) ...[
                          const SizedBox(height: 8),
                          TextButton.icon(
                            onPressed: _clearFilters,
                            icon: const Icon(Icons.clear_all),
                            label: const Text('Clear Filters'),
                          ),
                        ],
                      ],
                    ),
                  );
                }

                return RefreshIndicator(
                  onRefresh: () => provider.fetchOrders(),
                  child: ListView.separated(
                    padding: const EdgeInsets.all(24),
                    itemCount: filteredOrders.length,
                    separatorBuilder: (context, index) => const SizedBox(height: 16),
                    itemBuilder: (context, index) {
                      final order = filteredOrders[index];
                      return _AdminOrderCard(
                        order: order,
                        onTap: () {
                          Navigator.pushNamed(
                            context,
                            AppRouter.adminOrderDetail,
                            arguments: order,
                          );
                        },
                      );
                    },
                  ),
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}

class _AdminOrderCard extends StatelessWidget {
  final OrderModel order;
  final VoidCallback onTap;

  const _AdminOrderCard({
    required this.order,
    required this.onTap,
  });

  String _safeCurrency(num value) {
    try {
      final s = Formatters.currency(value.toDouble());
      if (s.trim().isNotEmpty) return s;
    } catch (_) {}
    return '${value.toStringAsFixed(2)} KM';
  }

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: AppColors.surface,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
            color: AppColors.textSecondary.withValues(alpha: 0.1),
          ),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.03),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Header Row
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        'Order #${order.id.substring(0, 8).toUpperCase()}',
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: AppColors.textPrimary,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Text(
                        Formatters.dateTime(order.createdAt),
                        style: TextStyle(
                          fontSize: 13,
                          color: AppColors.textSecondary.withValues(alpha: 0.8),
                        ),
                      ),
                    ],
                  ),
                ),
                OrderStatusBadge(status: order.status),
              ],
            ),

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Order Details Grid
            Row(
              children: [
                Expanded(
                  child: _DetailItem(
                    icon: Icons.person,
                    label: 'Waiter',
                    value: order.waiterName,
                  ),
                ),
                Expanded(
                  child: _DetailItem(
                    icon: order.type == 'DineIn'
                        ? Icons.restaurant
                        : Icons.takeout_dining,
                    label: 'Type',
                    value: order.type == 'DineIn' ? 'Dine In' : 'Take Away',
                  ),
                ),
              ],
            ),

            const SizedBox(height: 12),

            Row(
              children: [
                if (order.tableNumber != null)
                  Expanded(
                    child: _DetailItem(
                      icon: Icons.table_restaurant,
                      label: 'Table',
                      value: order.tableNumber.toString(),
                    ),
                  ),
                Expanded(
                  child: _DetailItem(
                    icon: Icons.shopping_bag,
                    label: 'Items',
                    value: order.items.length.toString(),
                  ),
                ),
              ],
            ),

            if (order.isPartnerOrder) ...[
              const SizedBox(height: 12),
              Container(
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                decoration: BoxDecoration(
                  color: AppColors.info.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(8),
                  border: Border.all(
                    color: AppColors.info.withValues(alpha: 0.3),
                  ),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Icon(
                      Icons.business,
                      size: 16,
                      color: AppColors.info,
                    ),
                    const SizedBox(width: 6),
                    const Text(
                      'Partner Order',
                      style: TextStyle(
                        fontSize: 12,
                        fontWeight: FontWeight.bold,
                        color: AppColors.info,
                      ),
                    ),
                  ],
                ),
              ),
            ],

            const SizedBox(height: 16),
            const Divider(height: 1),
            const SizedBox(height: 16),

            // Total Amount
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                const Text(
                  'Total Amount',
                  style: TextStyle(
                    fontSize: 15,
                    fontWeight: FontWeight.w600,
                    color: AppColors.textSecondary,
                  ),
                ),
                Text(
                  _safeCurrency(order.totalAmount),
                  style: const TextStyle(
                    fontSize: 20,
                    fontWeight: FontWeight.bold,
                    color: AppColors.primary,
                  ),
                ),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _DetailItem extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;

  const _DetailItem({
    required this.icon,
    required this.label,
    required this.value,
  });

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        Icon(
          icon,
          size: 18,
          color: AppColors.textSecondary.withValues(alpha: 0.7),
        ),
        const SizedBox(width: 8),
        Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                color: AppColors.textSecondary.withValues(alpha: 0.7),
              ),
            ),
            const SizedBox(height: 2),
            Text(
              value,
              style: const TextStyle(
                fontSize: 14,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
          ],
        ),
      ],
    );
  }
}

// ✅ Custom Inline Date Range Bottom Sheet
class _DateRangeBottomSheet extends StatefulWidget {
  final DateTimeRange? initialDateRange;

  const _DateRangeBottomSheet({this.initialDateRange});

  @override
  State<_DateRangeBottomSheet> createState() => _DateRangeBottomSheetState();
}

class _DateRangeBottomSheetState extends State<_DateRangeBottomSheet> {
  DateTime? _startDate;
  DateTime? _endDate;
  DateTime _focusedDay = DateTime.now();
  bool _selectingStart = true;

  @override
  void initState() {
    super.initState();
    _startDate = widget.initialDateRange?.start;
    _endDate = widget.initialDateRange?.end;
  }

  void _onDaySelected(DateTime selectedDay) {
    setState(() {
      if (_selectingStart) {
        _startDate = selectedDay;
        _endDate = null;
        _selectingStart = false;
      } else {
        if (selectedDay.isBefore(_startDate!)) {
          _endDate = _startDate;
          _startDate = selectedDay;
        } else {
          _endDate = selectedDay;
        }
      }
    });
  }

  bool _isDayInRange(DateTime day) {
    if (_startDate == null || _endDate == null) return false;
    return day.isAfter(_startDate!.subtract(const Duration(days: 1))) &&
        day.isBefore(_endDate!.add(const Duration(days: 1)));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
      ),
      child: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              // Drag Handle
              Container(
                width: 40,
                height: 4,
                decoration: BoxDecoration(
                  color: AppColors.textSecondary.withValues(alpha: 0.3),
                  borderRadius: BorderRadius.circular(2),
                ),
              ),
              
              const SizedBox(height: 20),

              // Title
              Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  const Text(
                    'Select Date Range',
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.bold,
                      color: AppColors.textPrimary,
                    ),
                  ),
                  IconButton(
                    icon: const Icon(Icons.close),
                    onPressed: () => Navigator.pop(context),
                  ),
                ],
              ),

              const SizedBox(height: 16),

              // Selected Range Display
              Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  color: AppColors.primary.withValues(alpha: 0.1),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.spaceAround,
                  children: [
                    _DateBox(
                      label: 'Start Date',
                      date: _startDate,
                      isActive: _selectingStart,
                      onTap: () => setState(() => _selectingStart = true),
                    ),
                    const Icon(Icons.arrow_forward, color: AppColors.primary),
                    _DateBox(
                      label: 'End Date',
                      date: _endDate,
                      isActive: !_selectingStart,
                      onTap: () => setState(() => _selectingStart = false),
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // Calendar
              _SimpleCalendar(
                focusedDay: _focusedDay,
                startDate: _startDate,
                endDate: _endDate,
                onDaySelected: _onDaySelected,
                isDayInRange: _isDayInRange,
              ),

              const SizedBox(height: 24),

              // Buttons
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed: () {
                        setState(() {
                          _startDate = null;
                          _endDate = null;
                          _selectingStart = true;
                        });
                      },
                      child: const Text('Clear'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: _startDate != null && _endDate != null
                          ? () => Navigator.pop(context, DateTimeRange(start: _startDate!, end: _endDate!))
                          : null,
                      child: const Text('Apply'),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _DateBox extends StatelessWidget {
  final String label;
  final DateTime? date;
  final bool isActive;
  final VoidCallback onTap;

  const _DateBox({required this.label, required this.date, required this.isActive, required this.onTap});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
        decoration: BoxDecoration(
          color: isActive ? AppColors.primary : Colors.transparent,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(color: isActive ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.3)),
        ),
        child: Column(
          children: [
            Text(label, style: TextStyle(fontSize: 12, color: isActive ? AppColors.white : AppColors.textSecondary)),
            const SizedBox(height: 4),
            Text(
              date != null ? Formatters.date(date!) : 'Select',
              style: TextStyle(fontSize: 14, fontWeight: FontWeight.bold, color: isActive ? AppColors.white : AppColors.textPrimary),
            ),
          ],
        ),
      ),
    );
  }
}

class _SimpleCalendar extends StatelessWidget {
  final DateTime focusedDay;
  final DateTime? startDate;
  final DateTime? endDate;
  final Function(DateTime) onDaySelected;
  final bool Function(DateTime) isDayInRange;

  const _SimpleCalendar({
    required this.focusedDay,
    required this.startDate,
    required this.endDate,
    required this.onDaySelected,
    required this.isDayInRange,
  });

  @override
  Widget build(BuildContext context) {
    final now = DateTime.now();
    final firstDay = DateTime(now.year, now.month, 1);
    final lastDay = DateTime(now.year, now.month + 1, 0);
    final daysInMonth = lastDay.day;
    final firstWeekday = firstDay.weekday % 7;

    return Column(
      children: [
        Text('${_monthName(now.month)} ${now.year}', style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold, color: AppColors.textPrimary)),
        const SizedBox(height: 16),
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceAround,
          children: ['S', 'M', 'T', 'W', 'T', 'F', 'S'].map((d) => SizedBox(width: 40, child: Text(d, textAlign: TextAlign.center, style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600, color: AppColors.textSecondary.withValues(alpha: 0.7))))).toList(),
        ),
        const SizedBox(height: 8),
        ...List.generate((daysInMonth + firstWeekday) ~/ 7 + 1, (week) {
          return Padding(
            padding: const EdgeInsets.symmetric(vertical: 4),
            child: Row(
              mainAxisAlignment: MainAxisAlignment.spaceAround,
              children: List.generate(7, (dayIdx) {
                final dayNum = week * 7 + dayIdx - firstWeekday + 1;
                if (dayNum < 1 || dayNum > daysInMonth) return const SizedBox(width: 40, height: 40);
                
                final day = DateTime(now.year, now.month, dayNum);
                final isStart = startDate != null && day.year == startDate!.year && day.month == startDate!.month && day.day == startDate!.day;
                final isEnd = endDate != null && day.year == endDate!.year && day.month == endDate!.month && day.day == endDate!.day;
                final inRange = isDayInRange(day);
                final isToday = day.year == now.year && day.month == now.month && day.day == now.day;

                return InkWell(
                  onTap: () => onDaySelected(day),
                  borderRadius: BorderRadius.circular(20),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: isStart || isEnd ? AppColors.primary : inRange ? AppColors.primary.withValues(alpha: 0.2) : Colors.transparent,
                      borderRadius: BorderRadius.circular(20),
                      border: isToday ? Border.all(color: AppColors.primary, width: 2) : null,
                    ),
                    alignment: Alignment.center,
                    child: Text('$dayNum', style: TextStyle(fontSize: 14, fontWeight: isStart || isEnd ? FontWeight.bold : FontWeight.normal, color: isStart || isEnd ? AppColors.white : AppColors.textPrimary)),
                  ),
                );
              }),
            ),
          );
        }),
      ],
    );
  }

  String _monthName(int m) => const ['January', 'February', 'March', 'April', 'May', 'June', 'July', 'August', 'September', 'October', 'November', 'December'][m - 1];
}