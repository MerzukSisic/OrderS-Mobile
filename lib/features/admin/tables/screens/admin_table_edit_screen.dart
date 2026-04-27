import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:orders_mobile/core/theme/app_colors.dart';
import 'package:orders_mobile/core/utils/app_notification.dart';
import 'package:orders_mobile/core/widgets/admin_scaffold.dart';
import 'package:orders_mobile/models/tables/table_model.dart';
import 'package:orders_mobile/providers/tables_provider.dart';
import 'package:orders_mobile/routes/app_router.dart';

class AdminTableEditScreen extends StatefulWidget {
  final TableModel table;
  const AdminTableEditScreen({super.key, required this.table});

  @override
  State<AdminTableEditScreen> createState() => _AdminTableEditScreenState();
}

class _AdminTableEditScreenState extends State<AdminTableEditScreen> {
  final _formKey = GlobalKey<FormState>();
  late final TextEditingController _tableNumberCtrl;
  late final TextEditingController _capacityCtrl;
  late String? _selectedLocation;
  late String _selectedStatus;
  bool _isSaving = false;

  static const _locations = ['Indoor', 'Outdoor', 'Terrace', 'VIP', 'Bar Area'];
  static const _statuses = ['Available', 'Occupied', 'Reserved'];

  @override
  void initState() {
    super.initState();
    _tableNumberCtrl = TextEditingController(text: widget.table.tableNumber);
    _capacityCtrl =
        TextEditingController(text: widget.table.capacity.toString());
    final loc = widget.table.location;
    _selectedLocation = (loc != null && _locations.contains(loc)) ? loc : null;
    _selectedStatus = widget.table.status;
  }

  @override
  void dispose() {
    _tableNumberCtrl.dispose();
    _capacityCtrl.dispose();
    super.dispose();
  }

  Color _statusColor(String status) {
    switch (status) {
      case 'Available':
        return AppColors.success;
      case 'Occupied':
        return AppColors.error;
      default:
        return AppColors.warning;
    }
  }

  Future<void> _handleSave() async {
    if (!_formKey.currentState!.validate()) return;
    setState(() => _isSaving = true);
    try {
      final success = await context.read<TablesProvider>().updateTable(
            widget.table.id,
            tableNumber: _tableNumberCtrl.text.trim(),
            capacity: int.tryParse(_capacityCtrl.text.trim()),
            location: _selectedLocation,
            status: _selectedStatus,
          );
      if (!mounted) return;
      if (success) {
        AppNotification.success(context, 'Table updated successfully');
        Navigator.pop(context, true);
      } else {
        AppNotification.error(
            context, 'Failed to update table. Please try again.');
      }
    } finally {
      if (mounted) setState(() => _isSaving = false);
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Edit Table ${widget.table.tableNumber}',
      currentRoute: AppRouter.adminTables,
      backgroundColor: AppColors.background,
      body: SingleChildScrollView(
        padding: const EdgeInsets.all(16),
        child: Form(
          key: _formKey,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildCard(children: [
                _buildSectionTitle(
                    'Table Information', Icons.table_restaurant_outlined),
                const SizedBox(height: 20),
                _buildTextField(
                  controller: _tableNumberCtrl,
                  label: 'Table Number *',
                  hint: 'e.g. T1, A3',
                  icon: Icons.tag,
                  validator: (v) =>
                      (v == null || v.isEmpty) ? 'Required' : null,
                ),
                const SizedBox(height: 16),
                _buildTextField(
                  controller: _capacityCtrl,
                  label: 'Capacity *',
                  hint: 'e.g. 4',
                  icon: Icons.people_outline,
                  keyboardType: TextInputType.number,
                  inputFormatters: [FilteringTextInputFormatter.digitsOnly],
                  validator: (v) {
                    if (v == null || v.isEmpty) return 'Required';
                    if ((int.tryParse(v) ?? 0) <= 0) {
                      return 'Must be greater than 0';
                    }
                    return null;
                  },
                ),
                const SizedBox(height: 16),
                _buildLocationDropdown(),
                const SizedBox(height: 20),
                _buildSectionTitle('Status', Icons.toggle_on_outlined),
                const SizedBox(height: 12),
                _buildStatusDropdown(),
              ]),
              const SizedBox(height: 24),
              Row(
                children: [
                  Expanded(
                    child: OutlinedButton(
                      onPressed:
                          _isSaving ? null : () => Navigator.pop(context),
                      style: OutlinedButton.styleFrom(
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(12),
                        ),
                      ),
                      child: const Text('Cancel'),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: ElevatedButton.icon(
                      onPressed: _isSaving ? null : _handleSave,
                      icon: _isSaving
                          ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                  strokeWidth: 2, color: Colors.white),
                            )
                          : const Icon(Icons.save),
                      label: Text(_isSaving ? 'Saving...' : 'Update'),
                      style: ElevatedButton.styleFrom(
                        backgroundColor: AppColors.primary,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 16),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(12)),
                        elevation: 0,
                      ),
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

  Widget _buildCard({required List<Widget> children}) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(16),
        border: Border.all(color: AppColors.primary.withValues(alpha: 0.1)),
      ),
      child: Column(
          crossAxisAlignment: CrossAxisAlignment.start, children: children),
    );
  }

  Widget _buildSectionTitle(String title, IconData icon) {
    return Row(
      children: [
        Container(
          padding: const EdgeInsets.all(8),
          decoration: BoxDecoration(
            color: AppColors.primary.withValues(alpha: 0.15),
            borderRadius: BorderRadius.circular(8),
          ),
          child: Icon(icon, color: AppColors.primary, size: 18),
        ),
        const SizedBox(width: 10),
        Text(title,
            style: const TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.bold,
                color: AppColors.textPrimary)),
        const SizedBox(width: 8),
        Expanded(
            child: Divider(color: AppColors.primary.withValues(alpha: 0.2))),
      ],
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String label,
    required String hint,
    required IconData icon,
    TextInputType? keyboardType,
    List<TextInputFormatter>? inputFormatters,
    String? Function(String?)? validator,
  }) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(label,
            style: const TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        TextFormField(
          controller: controller,
          keyboardType: keyboardType,
          inputFormatters: inputFormatters,
          validator: validator,
          style: const TextStyle(color: AppColors.textPrimary),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: TextStyle(
                color: AppColors.textSecondary.withValues(alpha: 0.5)),
            prefixIcon: Icon(icon, color: AppColors.primary, size: 20),
            filled: true,
            fillColor: AppColors.surfaceVariant,
            border: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: BorderSide.none),
            focusedBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide:
                    const BorderSide(color: AppColors.primary, width: 2)),
            errorBorder: OutlineInputBorder(
                borderRadius: BorderRadius.circular(12),
                borderSide: const BorderSide(color: AppColors.error)),
            isDense: true,
            contentPadding:
                const EdgeInsets.symmetric(vertical: 14, horizontal: 12),
          ),
        ),
      ],
    );
  }

  Widget _buildLocationDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Location',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String?>(
              value: _selectedLocation,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down,
                  color: AppColors.textSecondary),
              dropdownColor: AppColors.surface,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              hint: Text('None',
                  style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.6))),
              items: [
                DropdownMenuItem<String?>(
                  value: null,
                  child: Text('None',
                      style: TextStyle(
                          color:
                              AppColors.textSecondary.withValues(alpha: 0.6))),
                ),
                ..._locations.map((loc) => DropdownMenuItem<String?>(
                      value: loc,
                      child: Row(children: [
                        const Icon(Icons.location_on_outlined,
                            size: 16, color: AppColors.primary),
                        const SizedBox(width: 8),
                        Text(loc),
                      ]),
                    )),
              ],
              onChanged: (v) => setState(() => _selectedLocation = v),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildStatusDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text('Status',
            style: TextStyle(
                fontSize: 13,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary)),
        const SizedBox(height: 6),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 4),
          decoration: BoxDecoration(
            color: AppColors.surfaceVariant,
            borderRadius: BorderRadius.circular(12),
          ),
          child: DropdownButtonHideUnderline(
            child: DropdownButton<String>(
              value: _selectedStatus,
              isExpanded: true,
              icon: const Icon(Icons.arrow_drop_down,
                  color: AppColors.textSecondary),
              dropdownColor: AppColors.surface,
              style:
                  const TextStyle(color: AppColors.textPrimary, fontSize: 15),
              items: _statuses.map((s) {
                final color = _statusColor(s);
                return DropdownMenuItem<String>(
                  value: s,
                  child: Row(children: [
                    Icon(Icons.circle, size: 10, color: color),
                    const SizedBox(width: 10),
                    Text(s),
                  ]),
                );
              }).toList(),
              onChanged: (v) {
                if (v != null) setState(() => _selectedStatus = v);
              },
            ),
          ),
        ),
      ],
    );
  }
}
