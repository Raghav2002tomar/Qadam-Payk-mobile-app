import 'package:flutter/material.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../screens/product_details_screen.dart';

class ProductCard extends StatelessWidget {
  final Product product;

  const ProductCard({Key? key, required this.product}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      color: cs.surface, // adapt card background
      elevation: 1,
      shadowColor: cs.shadow.withOpacity(0.06),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(8),
      ),
      child: InkWell(
        onTap: () {
          Navigator.push(
            context,
            MaterialPageRoute(
              builder: (context) => ProductDetailsScreen(product: product),
            ),
          );
        },
        borderRadius: BorderRadius.circular(8),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // Discount Badge and Image Section
            Stack(
              children: [
                // Product Image container
                Container(
                  height: 160,
                  width: double.infinity,
                  decoration: BoxDecoration(
                    color: cs.surfaceContainerHighest, // adaptive image backdrop
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(8),
                      topRight: Radius.circular(8),
                    ),
                  ),
                  padding: const EdgeInsets.all(12),
                  child: Hero(
                    tag: 'product-${product.id}',
                    child: CachedNetworkImage(
                      imageUrl: product.image,
                      fit: BoxFit.contain,
                      placeholder: (context, url) => Container(
                        color: cs.surfaceContainerHigh,
                        child: Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        ),
                      ),
                      errorWidget: (context, url, error) => Container(
                        color: cs.surfaceContainerHigh,
                        child: Icon(
                          Icons.image_not_supported,
                          color: cs.onSurfaceVariant,
                          size: 40,
                        ),
                      ),
                    ),
                  ),
                ),
                // Discount Badge (use tertiary for promo)
                Positioned(
                  top: 8,
                  left: 8,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 2),
                    decoration: BoxDecoration(
                      color: cs.tertiary,
                      borderRadius: BorderRadius.circular(3),
                    ),
                    child: Text(
                      '18% off',
                      style: tt.labelSmall?.copyWith(
                        color: cs.onTertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ],
            ),

            // Product Details
            Expanded(
              child: Padding(
                padding: const EdgeInsets.all(12),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    // Product Title
                    Text(
                      product.title,
                      style: tt.bodyMedium?.copyWith(
                        fontSize: 13,
                        color: cs.onSurface,
                        height: 1.3,
                        fontWeight: FontWeight.w500,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 4),

                    // Product Descriptor
                    Text(
                      'High quality, premium material with excellent finishing',
                      style: tt.bodySmall?.copyWith(
                        fontSize: 11,
                        color: cs.onSurfaceVariant,
                      ),
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),

                    const SizedBox(height: 6),

                    // Rating
                    Row(
                      children: [
                        ...List.generate(5, (index) {
                          final filled = index < 4;
                          return Icon(
                            filled ? Icons.star : Icons.star_outline,
                            size: 14,
                            // Use fixed role appropriate for ratings; keep color readable on both themes
                            color: filled ? Colors.amber : cs.onSurfaceVariant,
                          );
                        }),
                        const SizedBox(width: 4),
                        Text(
                          '(${product.rating.count})',
                          style: tt.labelSmall?.copyWith(
                            color: cs.primary,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 8),

                    // Price Section
                    Row(
                      children: [
                        Text(
                          '₹${(product.price * 80).toInt()}',
                          style: tt.titleSmall?.copyWith(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(width: 6),
                        Text(
                          'M.R.P: ',
                          style: tt.bodySmall?.copyWith(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                          ),
                        ),
                        Text(
                          '₹${(product.price * 98).toInt()}',
                          style: tt.bodySmall?.copyWith(
                            fontSize: 11,
                            color: cs.onSurfaceVariant,
                            decoration: TextDecoration.lineThrough,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    Text(
                      '(18% off)',
                      style: tt.bodySmall?.copyWith(
                        fontSize: 11,
                        color: cs.tertiary,
                        fontWeight: FontWeight.w600,
                      ),
                    ),

                    const SizedBox(height: 6),

                    // Prime and Delivery
                    Row(
                      children: [
                        Icon(
                          Icons.verified,
                          size: 14,
                          color: cs.primary,
                        ),
                        const SizedBox(width: 4),
                        Text(
                          'prime DELIVERY',
                          style: tt.labelSmall?.copyWith(
                            fontSize: 11,
                            color: cs.primary,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),

                    const SizedBox(height: 2),

                    Text(
                      'FREE delivery Tomorrow',
                      style: tt.bodySmall?.copyWith(
                        fontSize: 11,
                        color: cs.onSurface,
                      ),
                    ),

                    SizedBox(height: 4,),
                    // Add to Cart Button
                    SizedBox(
                      height: 40,
                      width: double.infinity,
                      child: ElevatedButton(
                        onPressed: () {
                          ScaffoldMessenger.of(context).showSnackBar(
                            SnackBar(
                              content: Text('Added ${product.title} to cart'),
                              duration: const Duration(seconds: 2),
                              backgroundColor: cs.inverseSurface,
                              behavior: SnackBarBehavior.floating,
                            ),
                          );
                        },
                        style: ElevatedButton.styleFrom(
                          backgroundColor: Color(0xFFFF9800),
                          foregroundColor: Color(0xFFFF9800),
                          elevation: 0,
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(4),
                          ),
                        ),
                        child: Text(
                          'Add to cart',
                          style: tt.labelLarge?.copyWith(
                            fontSize: 12,
                            fontWeight: FontWeight.w600,
                          ),
                        ),
                      ),
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
}
