import 'package:flutter/material.dart';
import 'package:chicken_grills/theme/app_theme.dart';

class ProfileCard extends StatelessWidget {
  final String name;
  final String role;
  final String? email;
  final String? avatarUrl;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;

  const ProfileCard({
    Key? key,
    required this.name,
    required this.role,
    this.email,
    this.avatarUrl,
    this.onTap,
    this.onEdit,
  }) : super(key: key);

  Color _getRoleColor() {
    switch (role.toLowerCase()) {
      case 'admin':
        return Colors.red;
      case 'pro':
        return AppTheme.secondaryOrange;
      case 'lambda':
        return Colors.blue;
      default:
        return AppTheme.primaryOrange;
    }
  }

  String _getRoleLabel() {
    switch (role.toLowerCase()) {
      case 'admin':
        return 'Administrateur';
      case 'pro':
        return 'Professionnel';
      case 'lambda':
        return 'Utilisateur';
      default:
        return role;
    }
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      margin: const EdgeInsets.symmetric(vertical: 8, horizontal: 16),
      decoration: BoxDecoration(
        color: AppTheme.white,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.1),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Material(
        color: Colors.transparent,
        child: InkWell(
          onTap: onTap,
          borderRadius: BorderRadius.circular(12),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Row(
              children: [
                CircleAvatar(
                  radius: 30,
                  backgroundColor: _getRoleColor().withOpacity(0.1),
                  backgroundImage:
                      avatarUrl != null ? NetworkImage(avatarUrl!) : null,
                  child:
                      avatarUrl == null
                          ? Icon(Icons.person, color: _getRoleColor(), size: 30)
                          : null,
                ),
                const SizedBox(width: 16),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        name,
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                          color: Colors.black87,
                        ),
                      ),
                      const SizedBox(height: 4),
                      Container(
                        padding: const EdgeInsets.symmetric(
                          horizontal: 8,
                          vertical: 4,
                        ),
                        decoration: BoxDecoration(
                          color: _getRoleColor().withOpacity(0.1),
                          borderRadius: BorderRadius.circular(12),
                        ),
                        child: Text(
                          _getRoleLabel(),
                          style: TextStyle(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                            color: _getRoleColor(),
                          ),
                        ),
                      ),
                      if (email != null) ...[
                        const SizedBox(height: 4),
                        Text(
                          email!,
                          style: const TextStyle(
                            fontSize: 14,
                            color: Colors.grey,
                          ),
                        ),
                      ],
                    ],
                  ),
                ),
                if (onEdit != null)
                  IconButton(
                    onPressed: onEdit,
                    icon: Icon(
                      Icons.edit,
                      color: AppTheme.primaryOrange,
                      size: 20,
                    ),
                  ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}
