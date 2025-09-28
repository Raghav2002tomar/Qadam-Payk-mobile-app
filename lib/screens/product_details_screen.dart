import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:cached_network_image/cached_network_image.dart';
import '../models/product.dart';
import '../providers/cart_provider.dart';
import '../widgets/custom_modals.dart';

class ProductDetailsScreen extends StatefulWidget {
  final Product product;

  const ProductDetailsScreen({Key? key, required this.product}) : super(key: key);

  @override
  _ProductDetailsScreenState createState() => _ProductDetailsScreenState();
}

class _ProductDetailsScreenState extends State<ProductDetailsScreen> {
  int quantity = 1;

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text('Product Details', style: tt.titleLarge?.copyWith(color: cs.onSurface)),
        backgroundColor: cs.surface,
        elevation: 1,
        iconTheme: IconThemeData(color: cs.onSurface),
      ),
      body: Column(
        children: [
          Expanded(
            child: SingleChildScrollView(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  // Product Image
                  Container(
                    height: 300,
                    width: double.infinity,
                    color: cs.surface,
                    padding: const EdgeInsets.all(20),
                    child: Hero(
                      tag: 'product-${widget.product.id}',
                      child: CachedNetworkImage(
                        imageUrl: widget.product.image,
                        fit: BoxFit.contain,
                        placeholder: (context, url) => Center(
                          child: CircularProgressIndicator(
                            strokeWidth: 2,
                            color: cs.primary,
                          ),
                        ),
                        errorWidget: (context, url, error) => Icon(
                          Icons.error_outline,
                          color: cs.error,
                        ),
                      ),
                    ),
                  ),

                  // Product Info
                  Container(
                    width: double.infinity,
                    color: cs.surface,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          widget.product.title,
                          style: tt.headlineSmall?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                            height: 1.3,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          '\$${widget.product.price.toStringAsFixed(2)}',
                          style: tt.headlineMedium?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.primary,
                          ),
                        ),
                        const SizedBox(height: 16),
                        Row(
                          children: [
                            Container(
                              padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
                              decoration: BoxDecoration(
                                color: cs.secondaryContainer,
                                borderRadius: BorderRadius.circular(6),
                              ),
                              child: Text(
                                widget.product.category.toUpperCase(),
                                style: tt.labelSmall?.copyWith(
                                  color: cs.onSecondaryContainer,
                                  fontWeight: FontWeight.bold,
                                ),
                              ),
                            ),
                            const SizedBox(width: 16),
                            Row(
                              children: [
                                const Icon(Icons.star, color: Colors.amber, size: 20),
                                const SizedBox(width: 4),
                                Text(
                                  '${widget.product.rating.rate} (${widget.product.rating.count} reviews)',
                                  style: tt.bodyMedium?.copyWith(
                                    color: cs.onSurfaceVariant,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Description
                  Container(
                    width: double.infinity,
                    color: cs.surface,
                    padding: const EdgeInsets.all(20),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Description',
                          style: tt.titleLarge?.copyWith(
                            fontWeight: FontWeight.bold,
                            color: cs.onSurface,
                          ),
                        ),
                        const SizedBox(height: 12),
                        Text(
                          widget.product.description,
                          style: tt.bodyLarge?.copyWith(
                            color: cs.onSurface,
                            height: 1.5,
                          ),
                          textAlign: TextAlign.justify,
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 8),

                  // Quantity Selector
                  Container(
                    width: double.infinity,
                    color: cs.surface,
                    padding: const EdgeInsets.all(20),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Text(
                          'Quantity',
                          style: tt.titleMedium?.copyWith(
                            fontWeight: FontWeight.w600,
                            color: cs.onSurface,
                          ),
                        ),
                        Container(
                          decoration: BoxDecoration(
                            border: Border.all(color: cs.outlineVariant),
                            borderRadius: BorderRadius.circular(8),
                            color: cs.surfaceContainerHighest,
                          ),
                          child: Row(
                            children: [
                              IconButton(
                                onPressed: quantity > 1
                                    ? () {
                                  setState(() => quantity--);
                                }
                                    : null,
                                icon: Icon(
                                  Icons.remove,
                                  color: quantity > 1 ? cs.primary : cs.onSurfaceVariant,
                                ),
                              ),
                              Padding(
                                padding: const EdgeInsets.symmetric(horizontal: 16),
                                child: Text(
                                  quantity.toString(),
                                  style: tt.titleMedium?.copyWith(
                                    fontWeight: FontWeight.bold,
                                    color: cs.onSurface,
                                  ),
                                ),
                              ),
                              IconButton(
                                onPressed: () {
                                  setState(() => quantity++);
                                },
                                icon: Icon(Icons.add, color: cs.primary),
                              ),
                            ],
                          ),
                        ),
                      ],
                    ),
                  ),

                  const SizedBox(height: 100), // Space for button
                ],
              ),
            ),
          ),
        ],
      ),
      bottomNavigationBar: Container(
        padding: const EdgeInsets.all(20),
        decoration: BoxDecoration(
          color: cs.surface,
          boxShadow: [
            BoxShadow(
              color: cs.shadow.withOpacity(0.1),
              blurRadius: 10,
              offset: const Offset(0, -2),
            ),
          ],
        ),
        child: SafeArea(
          child: SizedBox(
            width: double.infinity,
            height: 50,
            child: ElevatedButton(
              onPressed: () {
                context.read<CartProvider>().addItem(widget.product, quantity);
                CustomModals.showSuccessModal(
                  context,
                  'Added to Cart',
                  '${widget.product.title} has been added to your cart.',
                );
              },
              style: ElevatedButton.styleFrom(
                backgroundColor: cs.primary,
                foregroundColor: cs.onPrimary,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(8),
                ),
                elevation: 0,
              ),
              child: Text(
                'Add to Cart - \$${(widget.product.price * quantity).toStringAsFixed(2)}',
                style: tt.titleSmall?.copyWith(
                  fontWeight: FontWeight.bold,
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
