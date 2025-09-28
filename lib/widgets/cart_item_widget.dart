import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/cart_item.dart';
import '../providers/cart_provider.dart';

class CartItemWidget extends StatelessWidget {
  final CartItem cartItem;

  const CartItemWidget({Key? key, required this.cartItem}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Card(
      color: cs.surface, // adaptive card background
      margin: const EdgeInsets.only(bottom: 12),
      elevation: 1.5,
      shadowColor: cs.shadow.withOpacity(0.08),
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Row(
          children: [
            // Product Image
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest, // adaptive container
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outlineVariant),
              ),
              child: ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: CachedNetworkImage(
                  imageUrl: cartItem.product.image,
                  fit: BoxFit.contain,
                  placeholder: (context, url) => Center(
                    child: CircularProgressIndicator(
                      strokeWidth: 2,
                      color: cs.primary,
                    ),
                  ),
                  errorWidget: (context, url, error) => Icon(
                    Icons.image_not_supported,
                    color: cs.onSurfaceVariant,
                  ),
                ),
              ),
            ),

            const SizedBox(width: 12),

            // Product Details
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    cartItem.product.title,
                    style: tt.titleSmall?.copyWith(
                      fontWeight: FontWeight.w600,
                      color: cs.onSurface,
                    ),
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 4),
                  Text(
                    '\$${cartItem.product.price.toStringAsFixed(2)} each',
                    style: tt.bodyMedium?.copyWith(
                      color: cs.onSurfaceVariant,
                    ),
                  ),
                  const SizedBox(height: 12),

                  Row(
                    mainAxisAlignment: MainAxisAlignment.spaceBetween,
                    children: [
                      // Quantity Controls
                      Container(
                        decoration: BoxDecoration(
                          border: Border.all(color: cs.outlineVariant),
                          borderRadius: BorderRadius.circular(8),
                          color: cs.surfaceContainerHigh,
                        ),
                        child: Row(
                          mainAxisSize: MainAxisSize.min,
                          children: [
                            InkWell(
                              onTap: () {
                                context.read<CartProvider>().updateQuantity(
                                  cartItem.product.id,
                                  cartItem.quantity - 1,
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.remove,
                                  size: 16,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                            Padding(
                              padding: const EdgeInsets.symmetric(horizontal: 12),
                              child: Text(
                                cartItem.quantity.toString(),
                                style: tt.titleMedium?.copyWith(
                                  fontWeight: FontWeight.bold,
                                  color: cs.onSurface,
                                ),
                              ),
                            ),
                            InkWell(
                              onTap: () {
                                context.read<CartProvider>().updateQuantity(
                                  cartItem.product.id,
                                  cartItem.quantity + 1,
                                );
                              },
                              borderRadius: BorderRadius.circular(8),
                              child: Padding(
                                padding: const EdgeInsets.all(8),
                                child: Icon(
                                  Icons.add,
                                  size: 16,
                                  color: cs.primary,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),

                      // Total Price
                      Text(
                        '\$${cartItem.totalPrice.toStringAsFixed(2)}',
                        style: tt.titleLarge?.copyWith(
                          fontWeight: FontWeight.bold,
                          color: cs.onSurface,
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),

            // Delete Button
            IconButton(
              onPressed: () {
                context.read<CartProvider>().removeItem(cartItem.product.id);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: const Text('Item removed from cart'),
                    backgroundColor: cs.inverseSurface,
                    behavior: SnackBarBehavior.floating,
                    duration: const Duration(seconds: 2),
                  ),
                );
              },
              icon: Icon(
                Icons.delete_outline,
                color: cs.error, // adaptive destructive color
              ),
              tooltip: 'Remove',
            ),
          ],
        ),
      ),
    );
  }
}
