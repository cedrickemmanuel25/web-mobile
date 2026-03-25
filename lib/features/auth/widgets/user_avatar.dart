import 'package:flutter/material.dart';

class UserAvatar extends StatelessWidget {
  final String? name;
  final String? imageUrl;
  final double size;

  const UserAvatar({
    super.key,
    this.name,
    this.imageUrl,
    this.size = 80,
  });

  @override
  Widget build(BuildContext context) {
    return Column(
      children: [
        CircleAvatar(
          radius: size / 2,
          backgroundColor: const Color(0xFF1B4332).withOpacity(0.1),
          backgroundImage: imageUrl != null ? NetworkImage(imageUrl!) : null,
          child: imageUrl == null 
              ? Text(
                  name != null && name!.isNotEmpty ? name![0].toUpperCase() : 'U',
                  style: TextStyle(
                    fontSize: size * 0.4,
                    fontWeight: FontWeight.bold,
                    color: const Color(0xFF1B4332),
                  ),
                )
              : null,
        ),
        if (name != null) ...[
          const SizedBox(height: 12),
          Text(
            name!,
            style: const TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.bold,
              color: Colors.black,
            ),
          ),
        ],
      ],
    );
  }
}
