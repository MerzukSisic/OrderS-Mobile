import 'package:flutter/material.dart';
import 'package:flutter/scheduler.dart';
import 'package:orders_mobile/core/widgets/admin_scaffold.dart';
import 'package:orders_mobile/models/product_model.dart';
import 'package:provider/provider.dart';
import 'package:image_picker/image_picker.dart';
import 'dart:io';
import '../../../../providers/products_provider.dart';
import '../../../../providers/inventory_provider.dart';
import '../../../../core/theme/app_colors.dart';
import '../../../../routes/app_router.dart';
import '../../../../core/services/api_service.dart';
import '../../../../core/constants/api_constants.dart';

class AdminEditProductScreen extends StatefulWidget {
  final String productId;

  const AdminEditProductScreen({
    super.key,
    required this.productId,
  });

  @override
  State<AdminEditProductScreen> createState() => _AdminEditProductScreenState();
}

class _AdminEditProductScreenState extends State<AdminEditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _priceController = TextEditingController();
  final _quantityController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _prepTimeController = TextEditingController();
  
  String? _selectedCategoryId;
  String? _selectedIngredientId;
  String _selectedLocation = 'Kitchen';
  
  List<Map<String, dynamic>> _categories = [];
  List<Map<String, dynamic>> _storeProducts = [];
  
  File? _selectedImage;
  String? _existingImageUrl;
  bool _isLoadingData = true;
  bool _isSaving = false;

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
    _quantityController.dispose();
    _descriptionController.dispose();
    _prepTimeController.dispose();
    super.dispose();
  }

  Future<void> _loadFormData() async {
    setState(() => _isLoadingData = true);
    
    try {
      final api = ApiService();
      
      // ✅ Load categories from backend
      final categoriesResponse = await api.get(ApiConstants.categories);
      
      // ✅ Load store products (ingredients) from backend
      final inventoryProvider = Provider.of<InventoryProvider>(context, listen: false);
      await inventoryProvider.fetchStoreProducts();
      
      // ✅ Load product data
      final productsProvider = context.read<ProductsProvider>();
      final product = productsProvider.products.firstWhere(
        (p) => p.id == widget.productId,
        orElse: () => ProductModel(
          id: '',
          name: '',
          price: 0,
          categoryId: '',
          categoryName: '',
          isAvailable: true,
          preparationLocation: '',
          preparationTimeMinutes: 0,
          stock: 0,
          ingredients: [],
        ),
      );

      if (!mounted) return;
      
      if (product.id.isEmpty) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proizvod nije pronađen'),
            backgroundColor: AppColors.error,
          ),
        );
        Navigator.pop(context);
        return;
      }
      
      setState(() {
        // Set form data
        _nameController.text = product.name;
        _priceController.text = product.price.toString();
        _quantityController.text = product.stock.toString();
        _descriptionController.text = product.description ?? '';
        _prepTimeController.text = product.preparationTimeMinutes.toString();
        _selectedCategoryId = product.categoryId;
        _selectedLocation = product.preparationLocation.isNotEmpty 
            ? product.preparationLocation 
            : 'Kitchen';
        _existingImageUrl = product.imageUrl;
        
        // Set categories
        _categories = (categoriesResponse as List)
            .map((c) => {
                  'id': c['id'],
                  'name': c['name'],
                })
            .toList();
        
        // Set store products
        _storeProducts = inventoryProvider.storeProducts
            .map((sp) => {
                  'id': sp.id,
                  'name': sp.name,
                })
            .toList();
        
        // Set first ingredient if available
        if (product.ingredients.isNotEmpty) {
          final firstIngredient = product.ingredients.first;
          _selectedIngredientId = _storeProducts.firstWhere(
            (sp) => sp['name'].toLowerCase() == firstIngredient.storeProductName.toLowerCase(),
            orElse: () => _storeProducts.isNotEmpty ? _storeProducts.first : {'id': null},
          )['id'];
        }
        
        _isLoadingData = false;
      });
    } catch (e) {
      if (!mounted) return;
      setState(() => _isLoadingData = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text('Greška pri učitavanju: $e'),
          backgroundColor: AppColors.error,
        ),
      );
    }
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
                leading: const Icon(Icons.photo_camera, color: AppColors.primary),
                title: const Text('Fotografiši'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(source: ImageSource.camera);
                  if (image != null) {
                    setState(() => _selectedImage = File(image.path));
                  }
                },
              ),
              ListTile(
                leading: const Icon(Icons.photo_library, color: AppColors.primary),
                title: const Text('Izaberi iz galerije'),
                onTap: () async {
                  Navigator.pop(context);
                  final XFile? image = await picker.pickImage(source: ImageSource.gallery);
                  if (image != null) {
                    setState(() => _selectedImage = File(image.path));
                  }
                },
              ),
              if (_existingImageUrl != null || _selectedImage != null)
                ListTile(
                  leading: const Icon(Icons.delete_outline, color: AppColors.error),
                  title: const Text('Ukloni sliku'),
                  onTap: () {
                    Navigator.pop(context);
                    setState(() {
                      _selectedImage = null;
                      _existingImageUrl = null;
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
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(
          content: Text('Molimo odaberite kategoriju'),
          backgroundColor: AppColors.error,
        ),
      );
      return;
    }

    setState(() => _isSaving = true);

    try {
      final productsProvider = context.read<ProductsProvider>();
      
      // ✅ Create updated product data
      final updatedData = {
        'name': _nameController.text.trim(),
        'description': _descriptionController.text.trim(),
        'price': double.parse(_priceController.text.trim()),
        'stock': int.parse(_quantityController.text.trim()),
        'categoryId': _selectedCategoryId,
        'preparationLocation': _selectedLocation,
        'preparationTimeMinutes': int.parse(_prepTimeController.text.trim()),
        // TODO: Update image if changed
        // TODO: Update ingredients if changed
      };

      await productsProvider.updateProduct(widget.productId, updatedData);

      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text('Proizvod uspješno ažuriran'),
            backgroundColor: AppColors.success,
          ),
        );
        Navigator.pop(context);
      }
    } catch (e) {
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text('Greška: $e'),
            backgroundColor: AppColors.error,
          ),
        );
      }
    } finally {
      if (mounted) {
        setState(() => _isSaving = false);
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return AdminScaffold(
      title: 'Uredi proizvod',
      currentRoute: AppRouter.adminEditProduct,
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
                    _buildLabel('Naziv proizvoda *'),
                    _buildTextField(
                      controller: _nameController,
                      hint: 'Npr. Pizza Margherita',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Unesite naziv proizvoda';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Category Dropdown
                    _buildLabel('Kategorija *'),
                    _buildCategoryDropdown(),

                    const SizedBox(height: 20),

                    // Price Field
                    _buildLabel('Cijena *'),
                    _buildTextField(
                      controller: _priceController,
                      hint: 'Npr. 15.50',
                      keyboardType: const TextInputType.numberWithOptions(decimal: true),
                      suffixText: 'KM',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Unesite cijenu';
                        }
                        if (double.tryParse(value) == null) {
                          return 'Unesite validnu cijenu';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Quantity Field
                    _buildLabel('Količina *'),
                    _buildTextField(
                      controller: _quantityController,
                      hint: 'Npr. 50',
                      keyboardType: TextInputType.number,
                      suffixText: 'kom',
                      validator: (value) {
                        if (value == null || value.trim().isEmpty) {
                          return 'Unesite količinu';
                        }
                        if (int.tryParse(value) == null) {
                          return 'Unesite validan broj';
                        }
                        return null;
                      },
                    ),

                    const SizedBox(height: 20),

                    // Preparation Location Dropdown
                    _buildLabel('Lokacija pripreme *'),
                    _buildLocationDropdown(),

                    const SizedBox(height: 20),

                    // Preparation Time
                    _buildLabel('Vrijeme pripreme (minute)'),
                    _buildTextField(
                      controller: _prepTimeController,
                      hint: 'Npr. 15',
                      keyboardType: TextInputType.number,
                      suffixText: 'min',
                    ),

                    const SizedBox(height: 20),

                    // Description Field
                    _buildLabel('Opis'),
                    _buildTextField(
                      controller: _descriptionController,
                      hint: 'Unesite opis proizvoda',
                      maxLines: 3,
                    ),

                    const SizedBox(height: 20),

                    // Image Field
                    _buildLabel('Slika'),
                    GestureDetector(
                      onTap: _pickImage,
                      child: Container(
                        width: double.infinity,
                        height: 200,
                        decoration: BoxDecoration(
                          color: AppColors.surface,
                          borderRadius: BorderRadius.circular(12),
                          border: Border.all(
                            color: AppColors.textSecondary.withValues(alpha: 0.2),
                          ),
                        ),
                        child: _selectedImage != null
                            ? ClipRRect(
                                borderRadius: BorderRadius.circular(12),
                                child: Image.file(
                                  _selectedImage!,
                                  fit: BoxFit.cover,
                                ),
                              )
                            : (_existingImageUrl != null && _existingImageUrl!.isNotEmpty)
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(12),
                                    child: Image.network(
                                      _existingImageUrl!,
                                      fit: BoxFit.cover,
                                      errorBuilder: (context, error, stackTrace) {
                                        return _buildImagePlaceholder();
                                      },
                                    ),
                                  )
                                : _buildImagePlaceholder(),
                      ),
                    ),

                    const SizedBox(height: 20),

                    // Ingredients Dropdown
                    _buildLabel('Glavni sastojak'),
                    _buildIngredientsDropdown(),

                    const SizedBox(height: 8),
                    Text(
                      'Napomena: Detaljni sastojci se uređuju u posebnoj sekciji',
                      style: TextStyle(
                        fontSize: 12,
                        color: AppColors.textSecondary.withValues(alpha: 0.6),
                        fontStyle: FontStyle.italic,
                      ),
                    ),

                    const SizedBox(height: 32),

                    // Save Button
                    SizedBox(
                      width: double.infinity,
                      height: 50,
                      child: ElevatedButton(
                        onPressed: _isSaving ? null : _saveProduct,
                        style: ElevatedButton.styleFrom(
                          backgroundColor: AppColors.primary,
                          foregroundColor: AppColors.white,
                          disabledBackgroundColor: AppColors.textSecondary.withValues(alpha: 0.3),
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
                                'Sačuvaj izmjene',
                                style: TextStyle(
                                  fontSize: 16,
                                  fontWeight: FontWeight.w600,
                                ),
                              ),
                      ),
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
        suffixStyle: TextStyle(
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
      value: _selectedCategoryId,
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
        _categories.isEmpty ? 'Učitavanje...' : 'Odaberite kategoriju',
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
                decoration: BoxDecoration(
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
      value: _selectedLocation,
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
          value: 'Kitchen',
          child: Row(
            children: [
              Icon(Icons.restaurant, size: 18, color: AppColors.primary),
              SizedBox(width: 12),
              Text('Kuhinja'),
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
      value: _selectedIngredientId,
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
        _storeProducts.isEmpty ? 'Učitavanje...' : 'Odaberite sastojak (opciono)',
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
          'Kliknite da dodate sliku',
          style: TextStyle(
            fontSize: 14,
            color: AppColors.textSecondary.withValues(alpha: 0.5),
          ),
        ),
      ],
    );
  }
}