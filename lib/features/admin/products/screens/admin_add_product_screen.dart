import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:orders_mobile/core/constants/api_constants.dart';
import 'package:orders_mobile/core/services/api/api_service.dart';
import 'package:orders_mobile/core/theme/app_colors.dart';
import 'package:orders_mobile/core/utils/app_notification.dart';
import 'package:orders_mobile/core/widgets/accompaniment_group_manager.dart';
import 'package:orders_mobile/core/widgets/admin_scaffold.dart';
import 'package:orders_mobile/models/products/accompaniment_group.dart';
import 'package:orders_mobile/providers/business_providers.dart';
import 'package:orders_mobile/providers/products_provider.dart';
import 'package:orders_mobile/routes/app_router.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:convert';
import 'dart:io';

class AddProductScreen extends StatefulWidget {
  const AddProductScreen({super.key});

  @override
  State<AddProductScreen> createState() => _AddProductScreenState();
}

class _AddProductScreenState extends State<AddProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _purchasePriceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prepTimeController = TextEditingController(text: '15');

  String? _selectedCategoryId;
  String? _selectedIngredientId;
  String _selectedLocation = 'Kitchen';

  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _storeProducts = [];
  List<AccompanimentGroup> _accompanimentGroups = [];
  bool _isLoadingData = true;

  File? _selectedImage;
  String? _selectedImageDataUrl;
  bool _isSaving = false;

  void _showNotification(String message, {bool isError = false}) {
    AppNotification.show(context, message, isError: isError);
  }

  @override
  void initState() {
    super.initState();
    SchedulerBinding.instance.addPostFrameCallback((_) {
      _loadFormData();
    });
  }

  @override
  void dispose() {
    _nameController.dispose();
    _priceController.dispose();
    _purchasePriceController.dispose();
    _quantityController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() => _isLoadingData = true);

    try {
      final api = ApiService();

      // Load categories from backend
      final categoriesResponse = await api.get(ApiConstants.categories);

      if (!mounted) return;

      // Load store products (ingredients) from backend
      final inventoryProvider =
          Provider.of<InventoryProvider>(context, listen: false);
      await inventoryProvider.fetchStoreProducts();

      if (!mounted) return;

      setState(() {
        _categories = (categoriesResponse as List)
            .map((c) => {
                  'id': c['id'],
                  'name': c['name'],
                })
            .toList();

        _storeProducts = inventoryProvider.storeProducts
            .map((sp) => {
                  'id': sp.id,
                  'name': sp.name,
                })
            .toList();

        _isLoadingData = false;
      });
    } catch (e) {
      debugPrint('❌ Error loading product form data: $e');
      if (!mounted) return;
      setState(() => _isLoadingData = false);
      _showNotification('Failed to load form data. Please try again.',
          isError: true);
    }
  }

  Future<void> _setSelectedImage(XFile image) async {
    final bytes = await image.readAsBytes();
    final extension = image.path.split('.').last.toLowerCase();
    final mimeType = switch (extension) {
      'png' => 'image/png',
      'webp' => 'image/webp',
      _ => 'image/jpeg',
    };

    setState(() {
      _selectedImage = File(image.path);
      _selectedImageDataUrl = 'data:$mimeType;base64,${base64Encode(bytes)}';
    });
  }

  Future<void> _pickImage() async {
    final ImagePicker picker = ImagePicker();

    showModalBottomSheet(
      context: context,
      backgroundColor: AppColors.surface,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.vertical(top: Radius.circular(20)),
      ),
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(16),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              ListTile(
                leading:
                    const Icon(Icons.photo_camera, color: AppColors.primary),
                title: const Text('Take a photo'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.camera,
                    maxWidth: 1200,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    await _setSelectedImage(image);
                  }
                },
              ),
              ListTile(
                leading:
                    const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Choose from gallery'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(
                    source: ImageSource.gallery,
                    maxWidth: 1200,
                    imageQuality: 85,
                  );
                  if (image != null) {
                    await _setSelectedImage(image);
                  }
                },
              ),
              if (_selectedImage != null)
                ListTile(
                  leading:
                      const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Remove image'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _selectedImageDataUrl = null;
                    });
                  },
                ),
            ],
          ),
        ),
      ),
    );
  }

  Future<void> _saveProduct() async {
    if (!_formKey.currentState!.validate()) return;

    if (_selectedCategoryId == null) {
      if (!mounted) return;
      _showNotification('Please select a category', isError: true);
      return;
    }

    setState(() => _isSaving = true);

    try {
      final api = ApiService();

      // Step 1: Create product
      final productData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        if (_purchasePriceController.text.trim().isNotEmpty)
          'purchasePrice': double.parse(_purchasePriceController.text.trim()),
        'stock': int.parse(_quantityController.text.trim()),
        'categoryId': _selectedCategoryId,
        'preparationLocation': _selectedLocation,
        'preparationTimeMinutes': int.parse(_prepTimeController.text.trim()),
        'isAvailable': true,
        if (_selectedImageDataUrl != null) 'imageUrl': _selectedImageDataUrl,
        'ingredients': _selectedIngredientId == null
            ? []
            : [
                {
                  'storeProductId': _selectedIngredientId,
                  'quantity': 1,
                }
              ],
      };

      final createdProduct =
          await api.post(ApiConstants.products, body: productData);
      final productId = createdProduct['id'] as String;

      if (!mounted) return;

      // Step 2: Create accompaniment groups if any
      for (final group in _accompanimentGroups) {
        if (group.name.trim().isEmpty) continue;

        final groupData = {
          'productId': productId,
          'name': group.name,
          'selectionType': group.selectionType,
          'isRequired': group.isRequired,
          'minSelections': group.minSelections,
          'maxSelections': group.maxSelections,
          'displayOrder': group.displayOrder,
          'accompaniments': group.accompaniments
              .map((acc) => {
                    'name': acc.name,
                    'extraCharge': acc.extraCharge,
                    'isAvailable': acc.isAvailable,
                    'displayOrder': acc.displayOrder,
                  })
              .toList(),
        };

        await api.createAccompanimentGroup(groupData);
      }

      if (!mounted) return;

      // Refresh products list
      await context.read<ProductsProvider>().fetchProducts();

      if (!mounted) return;

      _showNotification('Product successfully added');
      Navigator.pop(context);
    } catch (e) {
      debugPrint('❌ Error saving product: $e');
      if (!mounted) return;
      _showNotification('Failed to save product. Please try again.',
          isError: true);
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Add product',
      currentRoute: AppRouter.adminAddProduct,
      backgroundColor: AppColors.background,
      body: _isLoadingData
          ? const Center(
              child: CircularProgressIndicator(color: AppColors.primary),
            )
          : Form(
              key: _formKey,
              child: SingleChildScrollView(
                padding: const EdgeInsets.all(16),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Name Field
                    _buildLabel('Product name *'),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'e.g. Pizza Margherita',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter product name';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Category Dropdown
                    _buildLabel('Category *'),
                    _buildCategoryDropdown(),

                    const SizedBox(height: 20),

                    // Price Field
                    _buildLabel('Price *'),
                    _buildTextField(
                      controller: _priceController,
                      hint: 'e.g. 15.50',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      suffixText: 'KM',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter price';
                        }
                        final parsed = double.tryParse(value);
                        if (parsed == null) return 'Enter a valid price';
                        if (parsed < 0) return 'Price cannot be negative';
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Purchase Price Field
                    _buildLabel('Purchase price'),
                    _buildTextField(
                      controller: _purchasePriceController,
                      hint: 'e.g. 8.20',
                      keyboardType:
                          const TextInputType.numberWithOptions(decimal: true),
                      suffixText: 'KM',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return null;
                        }
                        final parsed = double.tryParse(value);
                        if (parsed == null) {
                          return 'Enter a valid purchase price';
                        }
                        if (parsed < 0) {
                          return 'Purchase price cannot be negative';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Quantity Field
                    _buildLabel('Quantity *'),
                    _buildTextField(
                      controller: _quantityController,
                      hint: 'e.g. 50',
                      keyboardType: TextInputType.number,
                      suffixText: 'pcs',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Enter quantity';
                        }
                        final parsed = int.tryParse(value);
                        if (parsed == null) return 'Enter a valid number';
                        if (parsed < 0) return 'Quantity cannot be negative';
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Preparation Location Dropdown
                    _buildLabel('Preparation location *'),
                    _buildLocationDropdown(),

                    const SizedBox(height: 20),

                    // Preparation Time
                    _buildLabel('Preparation time (minutes)'),
                    _buildTextField(
                      controller: _prepTimeController,
                      hint: 'e.g. 15',
                      keyboardType: TextInputType.number,
                      suffixText: 'min',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) return null;
                        final parsed = int.tryParse(value);
                        if (parsed == null) return 'Enter a valid number';
                        if (parsed < 0) {
                          return 'Preparation time cannot be negative';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Description Field
                    _buildLabel('Description'),
                    _buildTextField(
                      controller: _descriptionController,
                      hint: 'Enter product description',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 20),

                    // Image Field
                    _buildLabel('Image'),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color:
                                AppColors.textSecondary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.contain,
                                ),
                              )
                            : _buildImagePlaceholder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Ingredients Dropdown
                    _buildLabel('Main ingredient'),
                    _buildIngredientsDropdown(),

                    const SizedBox(height: 8),
                    Text(
                      'Note: Detailed ingredients are added after the product is created',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // ✅ NOVA SEKCIJA: Accompaniment Groups
                    const Divider(height: 32),
                    AccompanimentGroupManager(
                      initialGroups: _accompanimentGroups,
                      onGroupsChanged: (groups) {
                        setState(() => _accompanimentGroups = groups);
                      },
                    ),

                    const SizedBox(height: 32),

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
                          child: ElevatedButton(
                            onPressed: _isSaving ? null : _saveProduct,
                            style: ElevatedButton.styleFrom(
                              backgroundColor: AppColors.primary,
                              foregroundColor: AppColors.white,
                              disabledBackgroundColor: AppColors.textSecondary
                                  .withValues(alpha: 0.3),
                              padding: const EdgeInsets.symmetric(vertical: 16),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(12),
                              ),
                              elevation: 0,
                            ),
                            child: _isSaving
                                ? const SizedBox(
                                    height: 20,
                                    width: 20,
                                    child: CircularProgressIndicator(
                                      color: AppColors.white,
                                      strokeWidth: 2,
                                    ),
                                  )
                                : const Text(
                                    'Add',
                                    style: TextStyle(
                                      fontSize: 16,
                                      fontWeight: FontWeight.w600,
                                    ),
                                  ),
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 32),
                  ],
                ),
              ),
            ),
    );
  }

  Widget _buildLabel(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 14,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
    );
  }

  Widget _buildTextField({
    required TextEditingController controller,
    required String hint,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
    int maxLines = 1,
    String? suffixText,
  }) {
    return TextFormField(
      controller: controller,
      keyboardType: keyboardType,
      maxLines: maxLines,
      decoration: InputDecoration(
        hintText: hint,
        hintStyle: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.5),
          fontSize: 14,
        ),
        suffixText: suffixText,
        suffixStyle: const TextStyle(
          color: AppColors.textPrimary,
          fontWeight: FontWeight.w600,
        ),
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        errorBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.error,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      validator: validator,
    );
  }

  Widget _buildCategoryDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey(_selectedCategoryId ?? 'no-category'),
      initialValue: _selectedCategoryId,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      hint: Text(
        _categories.isEmpty ? 'Loading...' : 'Please select a category',
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.5),
          fontSize: 14,
        ),
      ),
      items: _categories.map((category) {
        return DropdownMenuItem<String>(
          value: category['id'],
          child: Row(
            children: [
              Container(
                width: 8,
                height: 8,
                decoration: const BoxDecoration(
                  color: AppColors.primary,
                  shape: BoxShape.circle,
                ),
              ),
              const SizedBox(width: 12),
              Text(category['name']),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedCategoryId = value),
    );
  }

  Widget _buildLocationDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey(_selectedLocation),
      initialValue: _selectedLocation,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      items: const [
        DropdownMenuItem(
          value: 'Both',
          child: Row(
            children: [
              Icon(Icons.restaurant_menu, size: 18, color: AppColors.primary),
              SizedBox(width: 12),
              Text('Both'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'Kitchen',
          child: Row(
            children: [
              Icon(Icons.restaurant, size: 18, color: AppColors.primary),
              SizedBox(width: 12),
              Text('Kitchen'),
            ],
          ),
        ),
        DropdownMenuItem(
          value: 'Bar',
          child: Row(
            children: [
              Icon(Icons.local_bar, size: 18, color: AppColors.primary),
              SizedBox(width: 12),
              Text('Bar'),
            ],
          ),
        ),
      ],
      onChanged: (value) => setState(() => _selectedLocation = value!),
    );
  }

  Widget _buildIngredientsDropdown() {
    return DropdownButtonFormField<String>(
      key: ValueKey(_selectedIngredientId ?? 'no-ingredient'),
      initialValue: _selectedIngredientId,
      decoration: InputDecoration(
        filled: true,
        fillColor: AppColors.surface,
        suffixIcon: _selectedIngredientId == null
            ? null
            : IconButton(
                tooltip: 'Remove ingredient',
                icon: const Icon(Icons.close, color: AppColors.textSecondary),
                onPressed: () => setState(() => _selectedIngredientId = null),
              ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(
            color: AppColors.textSecondary.withValues(alpha: 0.2),
          ),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(
            color: AppColors.primary,
            width: 2,
          ),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 16,
          vertical: 14,
        ),
      ),
      hint: Text(
        _storeProducts.isEmpty
            ? 'Loading...'
            : 'Select an ingredient (optional)',
        style: TextStyle(
          color: AppColors.textSecondary.withValues(alpha: 0.5),
          fontSize: 14,
        ),
      ),
      items: _storeProducts.map((product) {
        return DropdownMenuItem<String>(
          value: product['id'],
          child: Row(
            children: [
              Icon(
                Icons.inventory_2_outlined,
                size: 18,
                color: AppColors.primary.withValues(alpha: 0.7),
              ),
              const SizedBox(width: 12),
              Text(product['name']),
            ],
          ),
        );
      }).toList(),
      onChanged: (value) => setState(() => _selectedIngredientId = value),
    );
  }

  Widget _buildImagePlaceholder() {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Icon(
          Icons.add_photo_alternate_outlined,
          size: 48,
          color: AppColors.textSecondary.withValues(alpha: 0.3),
        ),
        const SizedBox(height: 8),
        Text(
          'Click to add an image',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}
