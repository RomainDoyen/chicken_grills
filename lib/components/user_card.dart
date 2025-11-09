import 'package:flutter/material.dart';
import 'package:chicken_grills/theme/app_theme.dart';

class UserCard extends StatelessWidget {
  final String name;
  final String email;
  final String role;
  final String? phone;
  final String? siret;
  final VoidCallback? onTap;
  final VoidCallback? onEdit;
  final VoidCallback? onDelete;
  final bool isActive;

  const UserCard({
    Key? key,
    required this.name,
    required this.email,
    required this.role,
    this.phone,
    this.siret,
    this.onTap,
    this.onEdit,
    this.onDelete,
    this.isActive = true,
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
        return Colors.grey;
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
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    CircleAvatar(
                      backgroundColor: _getRoleColor().withOpacity(0.1),
                      child: Icon(
                        Icons.person,
                        color: _getRoleColor(),
                        size: 24,
                      ),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            name,
                            style: const TextStyle(
                              fontSize: 16,
                              fontWeight: FontWeight.bold,
                              color: Colors.black87,
                            ),
                          ),
                          Text(
                            email,
                            style: const TextStyle(
                              fontSize: 14,
                              color: Colors.grey,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                  ],
                ),
                if (phone != null || siret != null) ...[
                  const SizedBox(height: 12),
                  if (phone != null) _buildInfoRow(Icons.phone, phone!),
                  if (siret != null) ...[
                    const SizedBox(height: 4),
                    _buildInfoRow(Icons.business, siret!),
                  ],
                ],
                if (onEdit != null || onDelete != null) ...[
                  const SizedBox(height: 12),
                  Row(
                    mainAxisAlignment: MainAxisAlignment.end,
                    children: [
                      if (onEdit != null)
                        IconButton(
                          onPressed: onEdit,
                          icon: Icon(
                            Icons.edit,
                            color: AppTheme.primaryOrange,
                            size: 20,
                          ),
                        ),
                      if (onDelete != null)
                        IconButton(
                          onPressed: onDelete,
                          icon: Icon(Icons.delete, color: Colors.red, size: 20),
                        ),
                    ],
                  ),
                ],
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildInfoRow(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: Colors.grey),
        const SizedBox(width: 8),
        Expanded(
          child: Text(
            text,
            style: const TextStyle(fontSize: 14, color: Colors.grey),
          ),
        ),
      ],
    );
  }
}
