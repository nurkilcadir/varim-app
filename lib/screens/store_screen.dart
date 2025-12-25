import 'package:flutter/material.dart';
import 'package:varim_app/theme/design_system.dart';
import 'package:varim_app/widgets/custom_header.dart';

/// VP Store screen for purchasing virtual points
class StoreScreen extends StatelessWidget {
  const StoreScreen({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: DesignSystem.backgroundDeep,
      body: SafeArea(
        child: Column(
          children: [
            // Custom Header
            const CustomHeader(),

            // Store Title
            Padding(
              padding: const EdgeInsets.all(20),
              child: Row(
                children: [
                  Icon(
                    Icons.store,
                    color: DesignSystem.primaryAccent,
                    size: 32,
                  ),
                  const SizedBox(width: 12),
                  Text(
                    'VP Mağaza',
                    style: DesignSystem.headingLarge.copyWith(
                      fontSize: 28,
                    ),
                  ),
                ],
              ),
            ),

            // Store Packages
            Expanded(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 12),
                child: Column(
                  children: [
                    // Başlangıç Package
                    _StorePackageCard(
                      title: 'Başlangıç',
                      vpAmount: '1.000',
                      price: '29.99 TL',
                      icon: Icons.stars,
                      color: DesignSystem.primaryAccent,
                      onTap: () => _showDemoMessage(context),
                    ),
                    const SizedBox(height: 16),

                    // Pro Package (Best Value)
                    _StorePackageCard(
                      title: 'Pro',
                      vpAmount: '10.000',
                      price: '149.99 TL',
                      icon: Icons.diamond,
                      color: Colors.amber,
                      isBestValue: true,
                      onTap: () => _showDemoMessage(context),
                    ),
                    const SizedBox(height: 16),

                    // Balina Package
                    _StorePackageCard(
                      title: 'Balina',
                      vpAmount: '100.000',
                      price: '999.99 TL',
                      icon: Icons.workspace_premium,
                      color: Colors.purple,
                      onTap: () => _showDemoMessage(context),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _showDemoMessage(BuildContext context) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text('Demo modunda satın alma kapalıdır.'),
        backgroundColor: DesignSystem.textBody,
        behavior: SnackBarBehavior.floating,
        duration: const Duration(seconds: 2),
      ),
    );
  }
}

/// Glassmorphism store package card
class _StorePackageCard extends StatelessWidget {
  final String title;
  final String vpAmount;
  final String price;
  final IconData icon;
  final Color color;
  final bool isBestValue;
  final VoidCallback onTap;

  const _StorePackageCard({
    required this.title,
    required this.vpAmount,
    required this.price,
    required this.icon,
    required this.color,
    this.isBestValue = false,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(20),
        child: Container(
          padding: const EdgeInsets.all(24),
          decoration: BoxDecoration(
            // Glassmorphism effect
            gradient: LinearGradient(
              begin: Alignment.topLeft,
              end: Alignment.bottomRight,
              colors: [
                DesignSystem.surfaceLight.withValues(alpha: 0.8),
                DesignSystem.surfaceLight.withValues(alpha: 0.6),
              ],
            ),
            borderRadius: BorderRadius.circular(20),
            border: Border.all(
              color: isBestValue
                  ? color.withValues(alpha: 0.5)
                  : DesignSystem.border.withValues(alpha: 0.3),
              width: isBestValue ? 2 : 1,
            ),
            boxShadow: [
              BoxShadow(
                color: isBestValue
                    ? color.withValues(alpha: 0.3)
                    : Colors.black.withValues(alpha: 0.2),
                blurRadius: 20,
                spreadRadius: isBestValue ? 2 : 0,
              ),
            ],
          ),
          child: Row(
            children: [
              // Icon
              Container(
                width: 60,
                height: 60,
                decoration: BoxDecoration(
                  gradient: LinearGradient(
                    begin: Alignment.topLeft,
                    end: Alignment.bottomRight,
                    colors: [
                      color.withValues(alpha: 0.3),
                      color.withValues(alpha: 0.1),
                    ],
                  ),
                  shape: BoxShape.circle,
                  border: Border.all(
                    color: color.withValues(alpha: 0.5),
                    width: 2,
                  ),
                ),
                child: Icon(
                  icon,
                  color: color,
                  size: 32,
                ),
              ),
              const SizedBox(width: 20),

              // Content
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Best Value Badge
                    if (isBestValue)
                      Container(
                        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                        decoration: BoxDecoration(
                          color: color.withValues(alpha: 0.3),
                          borderRadius: BorderRadius.circular(6),
                        ),
                        child: Text(
                          'EN İYİ DEĞER',
                          style: TextStyle(
                            color: color,
                            fontSize: 10,
                            fontWeight: FontWeight.w900,
                            letterSpacing: 0.5,
                          ),
                        ),
                      ),
                    if (isBestValue) const SizedBox(height: 8),

                    // Title
                    Text(
                      title,
                      style: DesignSystem.headingMedium.copyWith(
                        fontSize: 22,
                      ),
                    ),
                    const SizedBox(height: 8),

                    // VP Amount
                    Text(
                      '$vpAmount VP',
                      style: TextStyle(
                        color: color,
                        fontSize: 24,
                        fontWeight: FontWeight.w900,
                        letterSpacing: 0.5,
                      ),
                    ),
                    const SizedBox(height: 4),

                    // Price
                    Text(
                      price,
                      style: DesignSystem.bodyLarge.copyWith(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ],
                ),
              ),

              // Arrow Icon
              Icon(
                Icons.arrow_forward_ios,
                color: DesignSystem.textBody,
                size: 20,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
