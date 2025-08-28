import 'package:flutter/material.dart';
import 'package:vietmall/models/category_model.dart';
import 'package:vietmall/models/product_model.dart';
import 'package:vietmall/services/database_service.dart';

class EditProductScreen extends StatefulWidget {
  final ProductModel product;
  const EditProductScreen({super.key, required this.product});

  @override
  State<EditProductScreen> createState() => _EditProductScreenState();
}

class _EditProductScreenState extends State<EditProductScreen> {
  final _formKey = GlobalKey<FormState>();
  late TextEditingController _titleController;
  late TextEditingController _descriptionController;
  late TextEditingController _priceController;

  final DatabaseService _databaseService = DatabaseService();
  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _isLoading = false;
  bool _isCategoriesLoading = true;

  @override
  void initState() {
    super.initState();
    _titleController = TextEditingController(text: widget.product.title);
    _descriptionController = TextEditingController(text: widget.product.description);
    _priceController = TextEditingController(text: widget.product.price.toStringAsFixed(0));
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    _categories = await _databaseService.getCategoriesList();
    setState(() {
      _selectedCategory = _categories.firstWhere((cat) => cat.id == widget.product.categoryId, orElse: () => _categories.first);
      _isCategoriesLoading = false;
    });
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    super.dispose();
  }

  Future<void> _submitUpdate() async {
    if (_formKey.currentState!.validate() && _selectedCategory != null) {
      setState(() { _isLoading = true; });

      String? result = await _databaseService.updateProduct(
        productId: widget.product.id,
        title: _titleController.text,
        description: _descriptionController.text,
        price: double.parse(_priceController.text),
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
      );

      if (mounted) {
        setState(() { _isLoading = false; });
        if (result == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Cập nhật thành công!")),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi: $result")),
          );
        }
      }
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Sửa tin đăng',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE53935),
      ),
      body: Form(
        key: _formKey,
        child: ListView(
          padding: const EdgeInsets.all(16.0),
          children: [
            // Lưu ý: Phần sửa ảnh sẽ phức tạp hơn, tạm thời chỉ cho sửa thông tin
            _isCategoriesLoading
                ? const Center(child: CircularProgressIndicator())
                : DropdownButtonFormField<CategoryModel>(
              value: _selectedCategory,
              items: _categories.map((CategoryModel category) {
                return DropdownMenuItem<CategoryModel>(
                  value: category,
                  child: Text(category.name),
                );
              }).toList(),
              onChanged: (CategoryModel? newValue) {
                setState(() {
                  _selectedCategory = newValue;
                });
              },
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _titleController,
              decoration: const InputDecoration(labelText: "Tiêu đề"),
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _descriptionController,
              decoration: const InputDecoration(labelText: "Mô tả"),
              maxLines: 5,
            ),
            const SizedBox(height: 16),
            TextFormField(
              controller: _priceController,
              decoration: const InputDecoration(labelText: "Giá"),
              keyboardType: TextInputType.number,
            ),
            const SizedBox(height: 32),
            _isLoading
                ? const Center(child: CircularProgressIndicator())
                : ElevatedButton(
              onPressed: _submitUpdate,
              child: const Text("CẬP NHẬT"),
            ),
          ],
        ),
      ),
    );
  }
}