import 'package:flutter/material.dart';
import '../../../core/theme/app_colors.dart';

class OrderStatusBadge extends StatelessWidget {
  final String status;

  const OrderStatusBadge({
    super.key,
    required this.status,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
      decoration: BoxDecoration(
        color: _getStatusColor().withValues(alpha: 0.2),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Text(
        _getStatusText(),
        style: TextStyle(
          color: _getStatusColor(),
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
      ),
    );
  }

  Color _getStatusColor() {
    switch (status) {
      case 'Pending':
        return AppColors.statusPending;
      case 'Preparing':
        return AppColors.statusPreparing;
      case 'Ready':
        return AppColors.statusReady;
      case 'Completed':
        return AppColors.statusCompleted;
      case 'Cancelled':
        return AppColors.statusCancelled;
      default:
        return AppColors.grey;
    }
  }

  String _getStatusText() {
    switch (status) {
      case 'Pending':
        return 'Pending';
      case 'Preparing':
        return 'In progress';
      case 'Ready':
        return 'Ready';
      case 'Completed':
        return 'Completed';
      case 'Cancelled':
        return 'Cancelled';
      default:
        return status;
    }
  }
}
