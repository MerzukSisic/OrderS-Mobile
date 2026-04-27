import 'package:flutter/material.dart';
import 'package:orders_mobile/core/theme/app_colors.dart';
import 'package:orders_mobile/models/products/accompaniment.dart';
import 'package:orders_mobile/models/products/accompaniment_group.dart';

/// Widget for managing Accompaniment Groups
/// Used during product creation/editing
class AccompanimentGroupManager extends StatefulWidget {
  final List<AccompanimentGroup> initialGroups;
  final Function(List<AccompanimentGroup>) onGroupsChanged;

  const AccompanimentGroupManager({
    super.key,
    required this.initialGroups,
    required this.onGroupsChanged,
  });

  @override
  State<AccompanimentGroupManager> createState() =>
      _AccompanimentGroupManagerState();
}

class _AccompanimentGroupManagerState extends State<AccompanimentGroupManager> {
  late List<AccompanimentGroup> _groups;

  @override
  void initState() {
    super.initState();
    _groups = List.from(widget.initialGroups);
  }

  void _addNewGroup() {
    setState(() {
      _groups.add(AccompanimentGroup(
        id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
        name: '',
        productId: '',
        selectionType: 'Multiple',
        isRequired: false,
        displayOrder: _groups.length,
        accompaniments: [],
        createdAt: DateTime.now(),
      ));
    });
    widget.onGroupsChanged(_groups);
  }

  void _removeGroup(int index) {
    setState(() {
      _groups.removeAt(index);
    });
    widget.onGroupsChanged(_groups);
  }

  void _updateGroup(int index, AccompanimentGroup updatedGroup) {
    setState(() {
      _groups[index] = updatedGroup;
    });
    widget.onGroupsChanged(_groups);
  }

  @override
  Widget build(BuildContext context) {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // Header
        Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: [
            const Text(
              'Accompaniment Groups',
              style: TextStyle(
                fontSize: 16,
                fontWeight: FontWeight.w600,
                color: AppColors.textPrimary,
              ),
            ),
            TextButton.icon(
              onPressed: _addNewGroup,
              icon: const Icon(Icons.add_circle_outline, size: 18),
              label: const Text('Add Group'),
              style: TextButton.styleFrom(
                foregroundColor: AppColors.primary,
              ),
            ),
          ],
        ),

        const SizedBox(height: 8),

        // Info text
        Text(
          'Define extras for the product (e.g. milk type for coffee, toppings for sandwich)',
          style: TextStyle(
            fontSize: 12,
            color: AppColors.textSecondary.withValues(alpha: 0.7),
          ),
        ),

        const SizedBox(height: 16),

        // Groups list
        if (_groups.isEmpty)
          Container(
            padding: const EdgeInsets.all(20),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: AppColors.textSecondary.withValues(alpha: 0.2),
              ),
            ),
            child: Center(
              child: Column(
                children: [
                  Icon(
                    Icons.restaurant_menu_outlined,
                    size: 40,
                    color: AppColors.textSecondary.withValues(alpha: 0.3),
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'No accompaniments',
                    style: TextStyle(
                      color: AppColors.textSecondary.withValues(alpha: 0.5),
                    ),
                  ),
                ],
              ),
            ),
          )
        else
          ListView.separated(
            shrinkWrap: true,
            physics: const NeverScrollableScrollPhysics(),
            itemCount: _groups.length,
            separatorBuilder: (_, __) => const SizedBox(height: 12),
            itemBuilder: (context, index) {
              return _AccompanimentGroupCard(
                group: _groups[index],
                onUpdate: (updatedGroup) => _updateGroup(index, updatedGroup),
                onRemove: () => _removeGroup(index),
              );
            },
          ),
      ],
    );
  }
}

/// Card for displaying and editing individual accompaniment group
class _AccompanimentGroupCard extends StatefulWidget {
  final AccompanimentGroup group;
  final Function(AccompanimentGroup) onUpdate;
  final VoidCallback onRemove;

  const _AccompanimentGroupCard({
    required this.group,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_AccompanimentGroupCard> createState() =>
      _AccompanimentGroupCardState();
}

class _AccompanimentGroupCardState extends State<_AccompanimentGroupCard> {
  late TextEditingController _nameController;
  late String _selectionType;
  late bool _isRequired;
  late int? _minSelections;
  late int? _maxSelections;
  late List<Accompaniment> _accompaniments;
  bool _isExpanded = true;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.group.name);
    _selectionType = widget.group.selectionType;
    _isRequired = widget.group.isRequired;
    _minSelections = widget.group.minSelections;
    _maxSelections = widget.group.maxSelections;
    _accompaniments = List.from(widget.group.accompaniments);

    _nameController.addListener(_notifyChanges);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  void _notifyChanges() {
    widget.onUpdate(AccompanimentGroup(
      id: widget.group.id,
      name: _nameController.text,
      productId: widget.group.productId,
      selectionType: _selectionType,
      isRequired: _isRequired,
      minSelections: _minSelections,
      maxSelections: _maxSelections,
      displayOrder: widget.group.displayOrder,
      accompaniments: _accompaniments,
      createdAt: widget.group.createdAt,
    ));
  }

  void _addAccompaniment() {
    final newAccompaniment = Accompaniment(
      id: 'temp-${DateTime.now().millisecondsSinceEpoch}',
      accompanimentGroupId: widget.group.id,
      name: '',
      extraCharge: 0.0,
      isAvailable: true,
      displayOrder: _accompaniments.length,
      createdAt: DateTime.now(),
    );

    setState(() {
      _accompaniments.add(newAccompaniment);
      _notifyChanges();
    });
  }

  void _removeAccompaniment(int index) {
    setState(() {
      _accompaniments.removeAt(index);
      _notifyChanges();
    });
  }

  void _updateAccompaniment(int index, Accompaniment updated) {
    setState(() {
      _accompaniments[index] = updated;
      _notifyChanges();
    });
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: BoxDecoration(
        color: AppColors.surface,
        borderRadius: BorderRadius.circular(12),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.2),
        ),
      ),
      child: Column(
        children: [
          // Header
          InkWell(
            onTap: () => setState(() => _isExpanded = !_isExpanded),
            borderRadius: const BorderRadius.vertical(top: Radius.circular(12)),
            child: Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  Icon(
                    _isExpanded ? Icons.expand_more : Icons.chevron_right,
                    color: AppColors.primary,
                  ),
                  const SizedBox(width: 8),
                  Expanded(
                    child: Text(
                      _nameController.text.isEmpty
                          ? 'New Accompaniment Group'
                          : _nameController.text,
                      style: const TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                        color: AppColors.textPrimary,
                      ),
                    ),
                  ),
                  if (_accompaniments.isNotEmpty)
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: AppColors.primary.withValues(alpha: 0.1),
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${_accompaniments.length}',
                        style: const TextStyle(
                          fontSize: 12,
                          fontWeight: FontWeight.w600,
                          color: AppColors.primary,
                        ),
                      ),
                    ),
                  const SizedBox(width: 8),
                  IconButton(
                    onPressed: widget.onRemove,
                    icon: const Icon(Icons.delete_outline, size: 20),
                    color: AppColors.error,
                    padding: EdgeInsets.zero,
                    constraints: const BoxConstraints(),
                  ),
                ],
              ),
            ),
          ),

          // Content
          if (_isExpanded) ...[
            const Divider(height: 1, color: AppColors.textSecondary),
            Padding(
              padding: const EdgeInsets.all(12),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Group name
                  _buildLabel('Group Name *'),
                  TextFormField(
                    controller: _nameController,
                    decoration: InputDecoration(
                      hintText: 'e.g. Milk Type, Toppings, Sides',
                      hintStyle: TextStyle(
                        color: AppColors.textSecondary.withValues(alpha: 0.5),
                        fontSize: 14,
                      ),
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                  ),

                  const SizedBox(height: 12),

                  // Selection type
                  _buildLabel('Selection Type'),
                  DropdownButtonFormField<String>(
                    initialValue: _selectionType,
                    decoration: InputDecoration(
                      filled: true,
                      fillColor: AppColors.background,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(8),
                        borderSide: BorderSide.none,
                      ),
                      contentPadding: const EdgeInsets.symmetric(
                        horizontal: 12,
                        vertical: 10,
                      ),
                    ),
                    items: const [
                      DropdownMenuItem(
                        value: 'Single',
                        child: Text('Single choice (radio button)'),
                      ),
                      DropdownMenuItem(
                        value: 'Multiple',
                        child: Text('Multiple choice (checkbox)'),
                      ),
                    ],
                    onChanged: (value) {
                      setState(() {
                        _selectionType = value!;
                        _notifyChanges();
                      });
                    },
                  ),

                  const SizedBox(height: 12),

                  // Required checkbox
                  CheckboxListTile(
                    value: _isRequired,
                    onChanged: (value) {
                      setState(() {
                        _isRequired = value ?? false;
                        _notifyChanges();
                      });
                    },
                    title: const Text(
                      'Required selection',
                      style: TextStyle(fontSize: 14),
                    ),
                    controlAffinity: ListTileControlAffinity.leading,
                    contentPadding: EdgeInsets.zero,
                    activeColor: AppColors.primary,
                  ),

                  const SizedBox(height: 12),

                  // Min/Max selections
                  Row(
                    children: [
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Min selections'),
                            TextFormField(
                              initialValue: _minSelections?.toString() ?? '',
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: '0',
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _minSelections = int.tryParse(value);
                                  _notifyChanges();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _buildLabel('Max selections'),
                            TextFormField(
                              initialValue: _maxSelections?.toString() ?? '',
                              keyboardType: TextInputType.number,
                              decoration: InputDecoration(
                                hintText: 'No limit',
                                filled: true,
                                fillColor: AppColors.background,
                                border: OutlineInputBorder(
                                  borderRadius: BorderRadius.circular(8),
                                  borderSide: BorderSide.none,
                                ),
                                contentPadding: const EdgeInsets.symmetric(
                                  horizontal: 12,
                                  vertical: 10,
                                ),
                              ),
                              onChanged: (value) {
                                setState(() {
                                  _maxSelections = int.tryParse(value);
                                  _notifyChanges();
                                });
                              },
                            ),
                          ],
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 16),

                  // Accompaniments section
                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      _buildLabel('Accompaniment Options'),
                      TextButton.icon(
                        onPressed: _addAccompaniment,
                        icon: const Icon(Icons.add, size: 16),
                        label: const Text('Add'),
                        style: TextButton.styleFrom(
                          foregroundColor: AppColors.primary,
                          padding: const EdgeInsets.symmetric(horizontal: 8),
                        ),
                      ),
                    ],
                  ),

                  const SizedBox(height: 8),

                  // Accompaniments list
                  if (_accompaniments.isEmpty)
                    Container(
                      padding: const EdgeInsets.all(16),
                      decoration: BoxDecoration(
                        color: AppColors.background,
                        borderRadius: BorderRadius.circular(8),
                      ),
                      child: Center(
                        child: Text(
                          'No accompaniments',
                          style: TextStyle(
                            fontSize: 12,
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.5),
                          ),
                        ),
                      ),
                    )
                  else
                    ListView.separated(
                      shrinkWrap: true,
                      physics: const NeverScrollableScrollPhysics(),
                      itemCount: _accompaniments.length,
                      separatorBuilder: (_, __) => const SizedBox(height: 8),
                      itemBuilder: (context, index) {
                        return _AccompanimentItem(
                          accompaniment: _accompaniments[index],
                          onUpdate: (updated) =>
                              _updateAccompaniment(index, updated),
                          onRemove: () => _removeAccompaniment(index),
                        );
                      },
                    ),
                ],
              ),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }
}

/// Item for displaying and editing individual accompaniment
class _AccompanimentItem extends StatefulWidget {
  final Accompaniment accompaniment;
  final Function(Accompaniment) onUpdate;
  final VoidCallback onRemove;

  const _AccompanimentItem({
    required this.accompaniment,
    required this.onUpdate,
    required this.onRemove,
  });

  @override
  State<_AccompanimentItem> createState() => _AccompanimentItemState();
}

class _AccompanimentItemState extends State<_AccompanimentItem> {
  late TextEditingController _nameController;
  late TextEditingController _priceController;

  @override
  void initState() {
    super.initState();
    _nameController = TextEditingController(text: widget.accompaniment.name);
    _priceController = TextEditingController(
      text: widget.accompaniment.extraCharge > 0
          ? widget.accompaniment.extraCharge.toStringAsFixed(2)
          : '',
    );

    _nameController.addListener(_notifyChanges);
    _priceController.addListener(_notifyChanges);
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  void _notifyChanges() {
    widget.onUpdate(Accompaniment(
      id: widget.accompaniment.id,
      accompanimentGroupId: widget.accompaniment.accompanimentGroupId,
      name: _nameController.text,
      extraCharge: double.tryParse(_priceController.text) ?? 0.0,
      isAvailable: widget.accompaniment.isAvailable,
      displayOrder: widget.accompaniment.displayOrder,
      createdAt: widget.accompaniment.createdAt,
    ));
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: AppColors.background,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(
          color: AppColors.textSecondary.withValues(alpha: 0.1),
        ),
      ),
      child: Row(
        children: [
          // Name field
          Expanded(
            flex: 2,
            child: TextFormField(
              controller: _nameController,
              decoration: InputDecoration(
                hintText: 'Name',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),

          // Price field
          SizedBox(
            width: 80,
            child: TextFormField(
              controller: _priceController,
              keyboardType:
                  const TextInputType.numberWithOptions(decimal: true),
              decoration: InputDecoration(
                hintText: '0.00',
                hintStyle: TextStyle(
                  fontSize: 13,
                  color: AppColors.textSecondary.withValues(alpha: 0.5),
                ),
                suffixText: 'KM',
                suffixStyle:
                    const TextStyle(fontSize: 11, color: AppColors.textPrimary),
                border: InputBorder.none,
                contentPadding: const EdgeInsets.symmetric(horizontal: 8),
              ),
              style: const TextStyle(fontSize: 13),
            ),
          ),

          // Remove button
          IconButton(
            onPressed: widget.onRemove,
            icon: const Icon(Icons.close, size: 18),
            color: AppColors.error,
            padding: EdgeInsets.zero,
            constraints: const BoxConstraints(),
          ),
        ],
      ),
    );
  }
}
