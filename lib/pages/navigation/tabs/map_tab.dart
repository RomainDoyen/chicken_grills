import 'package:chicken_grills/pages/home/map_widget.dart';
import 'package:chicken_grills/theme/app_theme.dart';
import 'package:flutter/material.dart';

class MapTab extends StatelessWidget {
  const MapTab({super.key});

  @override
  Widget build(BuildContext context) {
    final padding = MediaQuery.of(context).padding;

    return Stack(
      children: [
        const Positioned.fill(child: MapWidget()),
        Positioned(
          top: 0,
          left: 0,
          right: 0,
          child: _MapHeader(topInset: padding.top),
        ),
      ],
    );
  }
}

class _MapHeader extends StatelessWidget {
  const _MapHeader({required this.topInset});

  final double topInset;

  @override
  Widget build(BuildContext context) {
    return Container(
      width: double.infinity,
      padding: EdgeInsets.fromLTRB(24, topInset + 24, 24, 24),
      decoration: const BoxDecoration(
        color: AppTheme.primaryOrange,
        borderRadius: BorderRadius.vertical(bottom: Radius.circular(24)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: const [
          SizedBox(height: 4),
          Text(
            'Chicken Grills',
            style: TextStyle(
              color: AppTheme.white,
              fontSize: 26,
              fontWeight: FontWeight.w700,
            ),
          ),
          SizedBox(height: 8),
          Text(
            'Découvrez les points de vente certifiés à proximité.',
            style: TextStyle(color: AppTheme.white, fontSize: 14),
          ),
        ],
      ),
    );
  }
}
