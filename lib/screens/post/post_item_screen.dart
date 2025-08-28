import 'package:flutter/material.dart';
import 'package:vietmall/common/app_colors.dart';
import 'package:vietmall/models/category_model.dart';
import 'package:vietmall/services/auth_service.dart';
import 'package:vietmall/services/database_service.dart';

class PostItemScreen extends StatefulWidget {
  const PostItemScreen({super.key});

  @override
  State<PostItemScreen> createState() => _PostItemScreenState();
}

class _PostItemScreenState extends State<PostItemScreen> {
  final _formKey = GlobalKey<FormState>();
  final _titleController = TextEditingController();
  final _descriptionController = TextEditingController();
  final _priceController = TextEditingController();
  final List<TextEditingController> _imageUrlControllers = [TextEditingController()];

  final DatabaseService _databaseService = DatabaseService();
  List<CategoryModel> _categories = [];
  CategoryModel? _selectedCategory;
  bool _isLoading = false;
  bool _isCategoriesLoading = true;
  bool _postToFeed = false;

  @override
  void initState() {
    super.initState();
    _fetchCategories();
  }

  Future<void> _fetchCategories() async {
    try {
      List<CategoryModel> categories = await _databaseService.getCategoriesList();
      setState(() {
        _categories = categories;
        _isCategoriesLoading = false;
      });
    } catch (e) {
      setState(() {
        _isCategoriesLoading = false;
      });
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi tải danh mục: $e")),
      );
    }
  }

  @override
  void dispose() {
    _titleController.dispose();
    _descriptionController.dispose();
    _priceController.dispose();
    for (var controller in _imageUrlControllers) {
      controller.dispose();
    }
    super.dispose();
  }

  Future<void> _submitPost() async {
    final List<String> imageUrls = _imageUrlControllers
        .map((controller) => controller.text.trim())
        .where((url) => url.isNotEmpty)
        .toList();

    if (!_formKey.currentState!.validate()) return;
    if (_selectedCategory == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng chọn danh mục.")),
      );
      return;
    }
    if (imageUrls.isEmpty) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng nhập ít nhất 1 URL hình ảnh.")),
      );
      return;
    }

    double? price;
    try {
      price = double.parse(_priceController.text);
      if (price <= 0) throw FormatException("Giá phải lớn hơn 0");
    } catch (e) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Giá không hợp lệ. Vui lòng nhập số.")),
      );
      return;
    }

    setState(() => _isLoading = true);

    final authService = AuthService();
    final currentUser = authService.currentUser;

    if (currentUser == null) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text("Vui lòng đăng nhập để đăng tin.")),
      );
      setState(() => _isLoading = false);
      return;
    }

    try {
      String? result = await _databaseService.createProduct(
        title: _titleController.text,
        description: _descriptionController.text,
        price: price,
        imageUrls: imageUrls,
        sellerId: currentUser.uid,
        sellerName: currentUser.displayName ?? "Người dùng VietMall",
        categoryId: _selectedCategory!.id,
        categoryName: _selectedCategory!.name,
        postToFeed: _postToFeed,
      );

      if (mounted) {
        setState(() => _isLoading = false);
        if (result == null) {
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(content: Text("Đăng tin thành công Đang chờ để xét duyệt!")),
          );
          Navigator.of(context).pop();
        } else {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(content: Text("Lỗi: $result")),
          );
        }
      }
    } catch (e) {
      if (mounted) setState(() => _isLoading = false);
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text("Lỗi khi đăng tin: $e")),
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tạo tin đăng mới',
          style: TextStyle(color: Colors.white),
        ),
        backgroundColor: const Color(0xFFE53935),
        centerTitle: true,
      ),
      body: Form(
        key: _formKey,
        child: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              _buildImageUrlInputs(),
              const SizedBox(height: 24),
              _isCategoriesLoading
                  ? const Center(child: CircularProgressIndicator())
                  : DropdownButtonFormField<CategoryModel>(
                value: _selectedCategory,
                hint: const Text("Chọn danh mục *"),
                items: _categories
                    .map((CategoryModel category) => DropdownMenuItem<CategoryModel>(
                  value: category,
                  child: Text(category.name),
                ))
                    .toList(),
                onChanged: (CategoryModel? newValue) {
                  setState(() => _selectedCategory = newValue);
                },
                validator: (value) => value == null ? 'Vui lòng chọn danh mục' : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _titleController,
                decoration: const InputDecoration(labelText: "Tiêu đề tin đăng *"),
                validator: (v) => v!.isEmpty ? "Vui lòng nhập tiêu đề" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _descriptionController,
                decoration: const InputDecoration(labelText: "Mô tả chi tiết *"),
                maxLines: 5,
                validator: (v) => v!.isEmpty ? "Vui lòng nhập mô tả" : null,
              ),
              const SizedBox(height: 16),
              TextFormField(
                controller: _priceController,
                decoration: const InputDecoration(labelText: "Giá bán *", suffixText: "₫"),
                keyboardType: TextInputType.number,
                validator: (v) {
                  if (v == null || v.isEmpty) return 'Vui lòng nhập giá';
                  if (double.tryParse(v) == null) return 'Giá không hợp lệ';
                  if (double.parse(v) <= 0) return 'Giá phải lớn hơn 0';
                  return null;
                },
              ),
              const SizedBox(height: 16),
              SwitchListTile(
                title: const Text("Đăng lên Dạo"),
                subtitle: const Text("Sản phẩm của bạn sẽ xuất hiện trên trang Dạo của mọi người."),
                value: _postToFeed,
                onChanged: (bool value) => setState(() => _postToFeed = value),
              ),
              const SizedBox(height: 32),
              _isLoading
                  ? const Center(child: CircularProgressIndicator())
                  : ElevatedButton.icon(
                onPressed: _submitPost,
                icon: const Icon(Icons.post_add),
                label: const Text("ĐĂNG TIN"),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildImageUrlInputs() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text("URL Hình ảnh sản phẩm *",
            style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold)),
        const SizedBox(height: 8),
        ListView.builder(
          shrinkWrap: true,
          physics: const NeverScrollableScrollPhysics(),
          itemCount: _imageUrlControllers.length,
          itemBuilder: (context, index) {
            return Padding(
              padding: const EdgeInsets.only(bottom: 8.0),
              child: Row(
                children: [
                  Expanded(
                    child: TextFormField(
                      controller: _imageUrlControllers[index],
                      decoration: InputDecoration(labelText: 'URL hình ảnh ${index + 1}'),
                      keyboardType: TextInputType.url,
                    ),
                  ),
                  if (index > 0)
                    IconButton(
                      icon: const Icon(Icons.remove_circle_outline, color: AppColors.primaryRed),
                      onPressed: () {
                        setState(() {
                          _imageUrlControllers[index].dispose();
                          _imageUrlControllers.removeAt(index);
                        });
                      },
                    ),
                ],
              ),
            );
          },
        ),
        if (_imageUrlControllers.length < 6)
          TextButton.icon(
            onPressed: () {
              setState(() {
                _imageUrlControllers.add(TextEditingController());
              });
            },
            icon: const Icon(Icons.add),
            label: const Text("Thêm URL khác"),
          ),
      ],
    );
  }
}
