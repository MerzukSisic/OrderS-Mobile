import 'package:flutter/material.dart';
import 'package:orders_mobile/core/utils/app_notification.dart';
import 'package:orders_mobile/models/products/accompaniment_group.dart';
import 'package:orders_mobile/core/theme/app_colors.dart';

class AccompanimentSelector extends StatefulWidget {
  final List<AccompanimentGroup> groups;
  final Function(List<String>) onSelectionChanged;
  final Function(double) onTotalChargeChanged;

  const AccompanimentSelector({
    super.key,
    required this.groups,
    required this.onSelectionChanged,
    required this.onTotalChargeChanged,
  });

  @override
  State<AccompanimentSelector> createState() => _AccompanimentSelectorState();
}

class _AccompanimentSelectorState extends State<AccompanimentSelector> {
  final Map<String, List<String>> _selectedAccompaniments = {};

  @override
  void initState() {
    super.initState();
    _initializeSelections();
  }

  @override
  void didUpdateWidget(AccompanimentSelector oldWidget) {
    super.didUpdateWidget(oldWidget);
    // Reset selections when groups change
    if (oldWidget.groups != widget.groups) {
      _initializeSelections();
    }
  }

  void _initializeSelections() {
    _selectedAccompaniments.clear();
    for (var group in widget.groups) {
      _selectedAccompaniments[group.id] = [];
    }
  }

  void _handleSingleSelection(AccompanimentGroup group, String? accompanimentId) {
    setState(() {
      if (accompanimentId == null || accompanimentId == 'none') {
        _selectedAccompaniments[group.id] = [];
      } else {
        _selectedAccompaniments[group.id] = [accompanimentId];
      }
      _notifyChanges();
    });
  }

  void _handleMultipleToggle(AccompanimentGroup group, String accompanimentId, bool selected) {
    setState(() {
      if (selected) {
        if (group.maxSelections != null &&
            _selectedAccompaniments[group.id]!.length >= group.maxSelections!) {
          AppNotification.error(context, 'Maksimum ${group.maxSelections} izbora za ${group.name}');
          return;
        }
        _selectedAccompaniments[group.id]!.add(accompanimentId);
      } else {
        _selectedAccompaniments[group.id]!.remove(accompanimentId);
      }
      _notifyChanges();
    });
  }

  void _notifyChanges() {
    List<String> allSelected = [];
    for (var list in _selectedAccompaniments.values) {
      allSelected.addAll(list);
    }
    widget.onSelectionChanged(allSelected);

    double totalCharge = 0.0;
    for (var group in widget.groups) {
      final selectedIds = _selectedAccompaniments[group.id] ?? [];
      for (var accompaniment in group.accompaniments) {
        if (selectedIds.contains(accompaniment.id)) {
          totalCharge += accompaniment.extraCharge;
        }
      }
    }
    widget.onTotalChargeChanged(totalCharge);
  }

  Widget _buildSingleSelectionDropdown(AccompanimentGroup group) {
    final selectedId = _selectedAccompaniments[group.id]?.isNotEmpty == true
        ? _selectedAccompaniments[group.id]!.first
        : null;

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.restaurant_menu,
                size: 18,
                color: group.isRequired ? AppColors.error : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Text(
                group.name, // ✅ Prikazuje naziv iz baze (Garnitura, Sos, itd.)
                style: const TextStyle(
                  fontWeight: FontWeight.bold,
                  fontSize: 15,
                  color: AppColors.textPrimary,
                ),
              ),
              if (group.isRequired)
                Container(
                  margin: const EdgeInsets.only(left: 8),
                  padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                  decoration: BoxDecoration(
                    color: AppColors.error.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(4),
                  ),
                  child: const Text(
                    'OBAVEZNO',
                    style: TextStyle(
                      color: AppColors.error,
                      fontWeight: FontWeight.bold,
                      fontSize: 9,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Container(
            padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 4),
            decoration: BoxDecoration(
              color: AppColors.surface,
              borderRadius: BorderRadius.circular(12),
              border: Border.all(
                color: group.isRequired && selectedId == null
                    ? AppColors.error.withValues(alpha: 0.5)
                    : AppColors.textSecondary.withValues(alpha: 0.2),
                width: group.isRequired && selectedId == null ? 2 : 1,
              ),
            ),
            child: DropdownButtonHideUnderline(
              child: DropdownButton<String>(
                key: ValueKey('${group.id}_$selectedId'), // ✅ FIX: Key za refresh
                isExpanded: true,
                value: selectedId,
                hint: Text(
                  group.isRequired ? 'Odaberite...' : 'Opcionalno',
                  style: TextStyle(
                    color: AppColors.textSecondary.withValues(alpha: 0.7),
                    fontSize: 14,
                  ),
                ),
                icon: const Icon(Icons.keyboard_arrow_down, size: 24),
                style: const TextStyle(
                  fontSize: 14,
                  color: AppColors.textPrimary,
                  fontWeight: FontWeight.w600,
                ),
                dropdownColor: AppColors.surface,
                items: [
                  if (!group.isRequired)
                    DropdownMenuItem<String>(
                      value: 'none',
                      child: Text(
                        'Bez ${group.name.toLowerCase()}', // ✅ Dinamički text
                        style: const TextStyle(fontSize: 14, fontWeight: FontWeight.w600),
                      ),
                    ),
                  ...group.accompaniments
                      .where((acc) => acc.isAvailable)
                      .map((accompaniment) {
                    return DropdownMenuItem<String>(
                      value: accompaniment.id,
                      child: Row(
                        mainAxisAlignment: MainAxisAlignment.spaceBetween,
                        children: [
                          Expanded(
                            child: Text(
                              accompaniment.name,
                              style: const TextStyle(
                                fontSize: 14,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          if (accompaniment.extraCharge > 0)
                            Text(
                              accompaniment.priceLabel,
                              style: const TextStyle(
                                color: AppColors.primary,
                                fontWeight: FontWeight.bold,
                                fontSize: 13,
                              ),
                            ),
                        ],
                      ),
                    );
                  }),
                ],
                onChanged: (value) => _handleSingleSelection(group, value),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildMultipleSelectionDropdown(AccompanimentGroup group) {
    final selectedIds = _selectedAccompaniments[group.id] ?? [];

    return Padding(
      padding: const EdgeInsets.only(bottom: 20),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(
                Icons.playlist_add_check,
                size: 18,
                color: group.isRequired ? AppColors.error : AppColors.textSecondary,
              ),
              const SizedBox(width: 8),
              Expanded(
                child: Text(
                  group.name, // ✅ Prikazuje naziv iz baze
                  style: const TextStyle(
                    fontWeight: FontWeight.bold,
                    fontSize: 15,
                    color: AppColors.textPrimary,
                  ),
                ),
              ),
              if (group.maxSelections != null)
                Container(
                  padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                  decoration: BoxDecoration(
                    color: selectedIds.isNotEmpty
                        ? AppColors.primary.withValues(alpha: 0.1)
                        : AppColors.textSecondary.withValues(alpha: 0.1),
                    borderRadius: BorderRadius.circular(6),
                  ),
                  child: Text(
                    'Max ${group.maxSelections}',
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.bold,
                      color: selectedIds.isNotEmpty ? AppColors.primary : AppColors.textSecondary,
                    ),
                  ),
                ),
            ],
          ),
          const SizedBox(height: 10),
          Wrap(
            spacing: 8,
            runSpacing: 8,
            children: group.accompaniments
                .where((acc) => acc.isAvailable)
                .map((accompaniment) {
              final isSelected = selectedIds.contains(accompaniment.id);

              return InkWell(
                onTap: () => _handleMultipleToggle(
                  group,
                  accompaniment.id,
                  !isSelected,
                ),
                borderRadius: BorderRadius.circular(999),
                child: Container(
                  padding: const EdgeInsets.symmetric(horizontal: 14, vertical: 9),
                  decoration: BoxDecoration(
                    color: isSelected
                        ? AppColors.primary
                        : AppColors.surfaceVariant,
                    borderRadius: BorderRadius.circular(999),
                    border: Border.all(
                      color: isSelected
                          ? AppColors.primary
                          : AppColors.textSecondary.withValues(alpha: 0.2),
                      width: 1.5,
                    ),
                  ),
                  child: Row(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (isSelected)
                        const Padding(
                          padding: EdgeInsets.only(right: 6),
                          child: Icon(
                            Icons.check_circle,
                            size: 15,
                            color: AppColors.white,
                          ),
                        ),
                      Text(
                        accompaniment.name,
                        style: TextStyle(
                          color: isSelected ? AppColors.white : AppColors.textPrimary,
                          fontWeight: FontWeight.w700,
                          fontSize: 13,
                        ),
                      ),
                      if (accompaniment.extraCharge > 0) ...[
                        const SizedBox(width: 6),
                        Text(
                          accompaniment.priceLabel,
                          style: TextStyle(
                            color: isSelected
                                ? AppColors.white.withValues(alpha: 0.9)
                                : AppColors.primary,
                            fontWeight: FontWeight.w600,
                            fontSize: 12,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
              );
            }).toList(),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    if (widget.groups.isEmpty) {
      return const SizedBox.shrink();
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        // ✅ NEMA DIVIDER OVDJE - Izbegava duplu liniju
        const Padding(
          padding: EdgeInsets.only(top: 8, bottom: 4, left: 4, right: 4),
          child: Row(
            children: [
              Icon(Icons.add_circle_outline, size: 20, color: AppColors.primary),
              SizedBox(width: 8),
              Text(
                'Prilagodi narudžbu',
                style: TextStyle(
                  fontSize: 17,
                  fontWeight: FontWeight.w900,
                  color: AppColors.textPrimary,
                ),
              ),
            ],
          ),
        ),
        const SizedBox(height: 16),
        ...widget.groups.map((group) {
          if (group.isSingleSelection) {
            return _buildSingleSelectionDropdown(group);
          } else {
            return _buildMultipleSelectionDropdown(group);
          }
        }),
      ],
    );
  }

  bool validate() {
    for (var group in widget.groups) {
      final selectedIds = _selectedAccompaniments[group.id] ?? [];
      if (group.isRequired && selectedIds.isEmpty) {
        AppNotification.error(context, 'Morate izabrati ${group.name}');
        return false;
      }
    }
    return true;
  }
}