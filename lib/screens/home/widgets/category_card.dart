// lib/screens/home/widgets/category_card.dart

import 'package:flutter/material.dart';
import 'package:vietmall/common/app_colors.dart';
import 'package:vietmall/models/category_model.dart';
import 'package:vietmall/screens/product/product_list_screen.dart';

class CategoryCard extends StatelessWidget {
  final CategoryModel category;

  const CategoryCard({super.key, required this.category});

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (context) => ProductListScreen(
              categoryId: category.id,
              categoryName: category.name,
            ),
          ),
        );
      },
      borderRadius: BorderRadius.circular(8),
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 4.0),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // ----- BẮT ĐẦU SỬA CODE BO TRÒN GÓC -----
            ClipRRect(
              // Sử dụng ClipRRect để cắt các góc của widget con
              borderRadius: BorderRadius.circular(12.0), // Bạn có thể thay đổi độ bo tròn ở đây
              child: category.iconUrl.isNotEmpty
                  ? Image.network(
                category.iconUrl,
                height: 60,
                width: 60,
                // Thay đổi fit thành cover để ảnh lấp đầy khung bo tròn
                fit: BoxFit.cover,
                errorBuilder: (c, o, s) => const Icon(Icons.category,
                    size: 50, color: AppColors.grey),
              )
                  : const Icon(Icons.category,
                  size: 50, color: AppColors.grey),
            ),
            // ----- KẾT THÚC SỬA CODE BO TRÒN GÓC -----
            const SizedBox(height: 8),
            Text(
              category.name,
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 12, fontWeight: FontWeight.w500),
              maxLines: 2,
              overflow: TextOverflow.ellipsis,
            ),
          ],
        ),
      ),
    );
  }
}