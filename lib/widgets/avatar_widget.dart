import 'package:flutter/material.dart';

/// Circular avatar with image URL fallback to initials.
class AvatarWidget extends StatelessWidget {
  const AvatarWidget({
    super.key,
    this.imageUrl,
    this.name,
    this.radius = 20,
  });

  final String? imageUrl;
  final String? name;
  final double radius;

  @override
  Widget build(BuildContext context) {
    final colors = Theme.of(context).colorScheme;
    return CircleAvatar(
      radius: radius,
      backgroundColor: colors.primaryContainer,
      backgroundImage:
          imageUrl != null ? NetworkImage(imageUrl!) : null,
      child: imageUrl == null
          ? Text(
              _initials,
              style: TextStyle(
                fontSize: radius * 0.8,
                fontWeight: FontWeight.w600,
                color: colors.primary,
              ),
            )
          : null,
    );
  }

  String get _initials {
    if (name == null || name!.isEmpty) return '?';
    final parts = name!.trim().split(' ');
    if (parts.length >= 2) {
      return '${parts[0][0]}${parts[1][0]}'.toUpperCase();
    }
    return parts[0][0].toUpperCase();
  }
}
