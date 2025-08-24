import 'package:flutter/material.dart';

class BadgeIconButton extends StatelessWidget {
  final Widget icon;          // Icon chính (có thể là Image.asset, Icon,...)
  final int badgeCount;       // Số badge
  final VoidCallback onPressed;

  const BadgeIconButton({
    Key? key,
    required this.icon,
    required this.badgeCount,
    required this.onPressed,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Stack(
      clipBehavior: Clip.none,
      children: [
        IconButton(
          icon: icon,
          onPressed: onPressed,
        ),
        if (badgeCount > 0)
          Positioned(
            right: 4,
            top: 4,
            child: Container(
              padding: const EdgeInsets.all(2),
              decoration: const BoxDecoration(
                color: Colors.red,
                shape: BoxShape.circle,
              ),
              constraints: const BoxConstraints(
                minWidth: 18,
                minHeight: 18,
              ),
              child: Text(
                '$badgeCount',
                style: const TextStyle(
                  color: Colors.white,
                  fontSize: 12,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
      ],
    );
  }
}
