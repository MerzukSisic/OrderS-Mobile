import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:flutter_stripe/flutter_stripe.dart' as stripe;

import 'package:orders_mobile/core/theme/app_colors.dart';
import 'package:orders_mobile/core/widgets/admin_scaffold.dart';
import 'package:orders_mobile/providers/procurement_payments_providers.dart';
import 'package:orders_mobile/routes/app_router.dart';

class ProcurementCheckoutScreen extends StatefulWidget {
  final Map<String, dynamic> arguments;

  const ProcurementCheckoutScreen({
    Key? key,
    required this.arguments,
  }) : super(key: key);

  @override
  State<ProcurementCheckoutScreen> createState() => _ProcurementCheckoutScreenState();
}

class _ProcurementCheckoutScreenState extends State<ProcurementCheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _supplierController = TextEditingController();
  final _notesController = TextEditingController();

  bool _isProcessing = false;
  int _currentStep = 0;

  String? _procurementOrderId;

  String? get _storeId => widget.arguments['storeId'] as String?;
  String? get _sourceStoreId => widget.arguments['sourceStoreId'] as String?;
  List<Map<String, dynamic>> get _items {
    final raw = widget.arguments['items'];
    if (raw == null) return [];
    return (raw as List).cast<Map<String, dynamic>>();
  }

  @override
  void initState() {
    super.initState();
    final existingId = widget.arguments['existingOrderId'] as String?;
    if (existingId != null && existingId.isNotEmpty) {
      _procurementOrderId = existingId;
      _currentStep = 1;
    }
  }

  double _calculateTotal() {
    double total = 0;
    for (final item in _items) {
      final qty = (item['quantity'] as num).toInt();
      final unitCost = (item['unitCost'] as num).toDouble();
      total += qty * unitCost;
    }
    return total;
  }

  Future<void> _createProcurementOrder() async {
    if (_storeId == null || (_storeId?.isEmpty ?? true)) {
      _showError('Store ID missing (store not selected)');
      return;
    }
    if (!_formKey.currentState!.validate()) return;

    setState(() => _isProcessing = true);

    try {
      final procurementProvider = context.read<ProcurementProvider>();

      final success = await procurementProvider.createProcurementOrder(
        storeId: _storeId!,
        sourceStoreId: _sourceStoreId,
        supplier: _supplierController.text.trim(),
        notes: _notesController.text.trim().isEmpty ? null : _notesController.text.trim(),
        items: _items.map((x) {
          return {
            'storeProductId': x['storeProductId'],
            'quantity': x['quantity'],
            'unitCost': x['unitCost'],
          };
        }).toList(),
      );

      if (success && procurementProvider.selectedOrder != null) {
        setState(() {
          _procurementOrderId = procurementProvider.selectedOrder!.id;
          _currentStep = 1;
        });
      } else {
        _showError(procurementProvider.error ?? 'Error creating order');
      }
    } catch (e) {
      debugPrint('❌ Error creating procurement order: $e');
      _showError('Failed to create order. Please try again.');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _initiatePayment() async {
    if (_procurementOrderId == null) return;

    setState(() => _isProcessing = true);

    try {
      final procurementProvider = context.read<ProcurementProvider>();

      final intentData = await procurementProvider.createPaymentIntent(_procurementOrderId!);
      if (intentData == null) {
        _showError(procurementProvider.error ?? 'Failed to create payment intent');
        return;
      }

      final clientSecret = intentData['clientSecret'] as String?;
      final paymentIntentId = intentData['paymentIntentId'] as String?;

      if (clientSecret == null || !clientSecret.contains('_secret_')) {
        _showError('Invalid clientSecret returned from API');
        return;
      }

      await stripe.Stripe.instance.initPaymentSheet(
        paymentSheetParameters: stripe.SetupPaymentSheetParameters(
          merchantDisplayName: 'OrderS Procurement',
          paymentIntentClientSecret: clientSecret,
          style: ThemeMode.dark,
          appearance: stripe.PaymentSheetAppearance(
            colors: stripe.PaymentSheetAppearanceColors(
              primary: AppColors.primary,
              background: AppColors.surface,
            ),
          ),
        ),
      );

      await stripe.Stripe.instance.presentPaymentSheet();

      if (paymentIntentId != null && paymentIntentId.isNotEmpty) {
        await procurementProvider.confirmPayment(
          procurementOrderId: _procurementOrderId!,
          paymentIntentId: paymentIntentId,
        );
      }

      await _confirmPayment();
    } on stripe.StripeException catch (e) {
      if (e.error.code == stripe.FailureCode.Canceled) {
        _showError('Payment canceled');
      } else {
        _showError(e.error.localizedMessage ?? e.error.message ?? 'Payment failed');
      }
    } catch (e) {
      debugPrint('❌ Error during payment: $e');
      _showError('Payment failed. Please try again.');
    } finally {
      setState(() => _isProcessing = false);
    }
  }

  Future<void> _confirmPayment() async {
    setState(() => _currentStep = 2);

    await Future.delayed(const Duration(seconds: 2));

    if (mounted) {
      Navigator.pop(context, true);
    }
  }

  void _showError(String message) {
    if (!mounted) return;
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: AppColors.error,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Checkout',
      currentRoute: AppRouter.procurementCheckout,
      backgroundColor: AppColors.background,
      body: Column(
        children: [
          _buildStepperIndicator(),
          const SizedBox(height: 24),
          Expanded(child: _buildStepContent()),
        ],
      ),
    );
  }

  Widget _buildStepperIndicator() {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
      color: AppColors.surface,
      child: Row(
        children: [
          _buildStepCircle(0, 'Details', Icons.edit_note),
          _buildStepLine(0),
          _buildStepCircle(1, 'Payment', Icons.payment),
          _buildStepLine(1),
          _buildStepCircle(2, 'Complete', Icons.check_circle),
        ],
      ),
    );
  }

  Widget _buildStepCircle(int step, String label, IconData icon) {
    final isActive = _currentStep == step;
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Column(
        children: [
          Container(
            width: 40,
            height: 40,
            decoration: BoxDecoration(
              color: isCompleted || isActive ? AppColors.primary : AppColors.surface,
              border: Border.all(
                color: isCompleted || isActive
                    ? AppColors.primary
                    : AppColors.textSecondary.withValues(alpha: 0.3),
                width: 2,
              ),
              shape: BoxShape.circle,
            ),
            child: Icon(
              isCompleted ? Icons.check : icon,
              color: isCompleted || isActive
                  ? AppColors.white
                  : AppColors.textSecondary.withValues(alpha: 0.5),
              size: 20,
            ),
          ),
          const SizedBox(height: 4),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: isActive
                  ? AppColors.primary
                  : AppColors.textSecondary.withValues(alpha: 0.7),
              fontWeight: isActive ? FontWeight.w600 : FontWeight.normal,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildStepLine(int step) {
    final isCompleted = _currentStep > step;

    return Expanded(
      child: Container(
        height: 2,
        margin: const EdgeInsets.only(bottom: 20),
        color: isCompleted ? AppColors.primary : AppColors.textSecondary.withValues(alpha: 0.2),
      ),
    );
  }

  Widget _buildStepContent() {
    switch (_currentStep) {
      case 0:
        return _buildOrderDetailsStep();
      case 1:
        return _buildPaymentStep();
      case 2:
        return _buildSuccessStep();
      default:
        return const SizedBox();
    }
  }

  Widget _buildOrderDetailsStep() {
    return SingleChildScrollView(
      padding: const EdgeInsets.all(24),
      child: Form(
        key: _formKey,
        autovalidateMode: AutovalidateMode.onUserInteraction,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text('Supplier', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _supplierController,
              decoration: InputDecoration(
                hintText: 'Enter supplier name',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
              ),
              validator: (v) => (v == null || v.trim().isEmpty) ? 'Required field' : null,
            ),
            const SizedBox(height: 20),

            const Text('Notes (optional)', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
            const SizedBox(height: 8),
            TextFormField(
              controller: _notesController,
              maxLines: 3,
              decoration: InputDecoration(
                hintText: 'Additional notes...',
                filled: true,
                fillColor: AppColors.surface,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(12),
                  borderSide: BorderSide.none,
                ),
                contentPadding: const EdgeInsets.all(16),
              ),
            ),
            const SizedBox(height: 24),

            _buildOrderSummary(),
            const SizedBox(height: 18),

            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: _isProcessing ? null : _createProcurementOrder,
                style: ElevatedButton.styleFrom(
                  backgroundColor: AppColors.primary,
                  padding: const EdgeInsets.symmetric(vertical: 16),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                  disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
                ),
                child: _isProcessing
                    ? const SizedBox(
                        height: 20,
                        width: 20,
                        child: CircularProgressIndicator(
                          strokeWidth: 2,
                          valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                        ),
                      )
                    : const Text(
                        'Continue to payment',
                        style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white),
                      ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentStep() {
    final total = _calculateTotal();

    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        children: [
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Container(
                  width: 80,
                  height: 80,
                  decoration: BoxDecoration(
                    color: AppColors.primary.withValues(alpha: 0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(Icons.payment, size: 40, color: AppColors.primary),
                ),
                const SizedBox(height: 24),
                const Text('Ready for payment', style: TextStyle(fontSize: 24, fontWeight: FontWeight.bold)),
                const SizedBox(height: 8),
                Text('Total amount: ${total.toStringAsFixed(2)} KM',
                    style: const TextStyle(fontSize: 18, color: AppColors.textSecondary)),
                const SizedBox(height: 24),
                _buildOrderSummary(),
              ],
            ),
          ),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _isProcessing ? null : _initiatePayment,
              style: ElevatedButton.styleFrom(
                backgroundColor: AppColors.primary,
                padding: const EdgeInsets.symmetric(vertical: 16),
                shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
                disabledBackgroundColor: AppColors.primary.withValues(alpha: 0.5),
              ),
              child: _isProcessing
                  ? const SizedBox(
                      height: 20,
                      width: 20,
                      child: CircularProgressIndicator(
                        strokeWidth: 2,
                        valueColor: AlwaysStoppedAnimation<Color>(AppColors.white),
                      ),
                    )
                  : const Text('Pay now', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700, color: AppColors.white)),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildSuccessStep() {
    return Padding(
      padding: const EdgeInsets.all(24),
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Container(
            width: 100,
            height: 100,
            decoration: BoxDecoration(
              color: AppColors.success.withValues(alpha: 0.1),
              shape: BoxShape.circle,
            ),
            child: const Icon(Icons.check_circle, size: 60, color: AppColors.success),
          ),
          const SizedBox(height: 24),
          const Text('Payment successful!', style: TextStyle(fontSize: 26, fontWeight: FontWeight.bold)),
          const SizedBox(height: 10),
          Text('Your procurement has been created and paid.',
              textAlign: TextAlign.center, style: TextStyle(color: AppColors.textSecondary.withValues(alpha: 0.9))),
          const SizedBox(height: 32),
          const CircularProgressIndicator(color: AppColors.primary, strokeWidth: 2),
        ],
      ),
    );
  }

  Widget _buildOrderSummary() {
    final total = _calculateTotal();

    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(color: AppColors.textSecondary.withValues(alpha: 0.1)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('Order summary', style: TextStyle(fontSize: 16, fontWeight: FontWeight.w700)),
              Text('${_items.length} product(s)', style: const TextStyle(fontSize: 14, color: AppColors.textSecondary)),
            ],
          ),
          const Divider(height: 24),

          ..._items.map((x) {
            final name = (x['productName'] ?? 'Item') as String;
            final qty = (x['quantity'] as num).toInt();
            final unitCost = (x['unitCost'] as num).toDouble();
            final subtotal = qty * unitCost;

            return Padding(
              padding: const EdgeInsets.only(bottom: 8),
              child: Row(
                mainAxisAlignment: MainAxisAlignment.spaceBetween,
                children: [
                  Expanded(child: Text('$name × $qty', style: const TextStyle(fontSize: 14))),
                  Text('${subtotal.toStringAsFixed(2)} KM', style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w700)),
                ],
              ),
            );
          }),

          const Divider(height: 24),
          Row(
            mainAxisAlignment: MainAxisAlignment.spaceBetween,
            children: [
              const Text('TOTAL', style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
              Text('${total.toStringAsFixed(2)} KM',
                  style: const TextStyle(fontSize: 18, fontWeight: FontWeight.bold, color: AppColors.primary)),
            ],
          ),
        ],
      ),
    );
  }

  @override
  void dispose() {
    _supplierController.dispose();
    _notesController.dispose();
    super.dispose();
  }
}
