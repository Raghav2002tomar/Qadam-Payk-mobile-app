import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/product_provider.dart';
import '../providers/cart_provider.dart';
import '../providers/theme_provider.dart';
import '../providers/translate_provider.dart';
import '../widgets/product_card.dart';
import 'cart_screen.dart';

class ProductListScreen extends StatefulWidget {
  const ProductListScreen({super.key});
  @override
  State<ProductListScreen> createState() => _ProductListScreenState();
}

class _ProductListScreenState extends State<ProductListScreen> {
  @override
  void initState() {
    super.initState();
    WidgetsBinding.instance.addPostFrameCallback((_) {
      context.read<ProductProvider>().fetchProducts();
      context.read<CartProvider>().loadCartItems();
    });
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final textTheme = Theme.of(context).textTheme;
    final theme = context.watch<ThemeProvider>();
    final isDark = theme.isDark;

    return Scaffold(
      // Use scaffoldBackground from theme
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          context.watch<TranslateProvider>().t('checkout'), // ✅ use watch
          style: textTheme.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
          ),
        ),
        backgroundColor: cs.surface,
        elevation: 1,
        shadowColor: cs.shadow.withOpacity(0.04),
        actions: [
          PopupMenuButton<String>(
            onSelected: (lang) {
              context.read<TranslateProvider>().setLocale(lang);
            },
            itemBuilder: (context) => [
              const PopupMenuItem(value: 'en', child: Text('English')),
              const PopupMenuItem(value: 'ru', child: Text('Русский')),
              const PopupMenuItem(value: 'tg', child: Text('Тоҷикӣ')),
            ],
            icon: const Icon(Icons.language),
          ),

          IconButton(
            tooltip: isDark ? 'Switch to Light' : 'Switch to Dark',
            icon: Icon(isDark ? Icons.wb_sunny_outlined : Icons.dark_mode_outlined),
            onPressed: () => context.read<ThemeProvider>().toggle(),
            color: cs.onSurfaceVariant,
          ),
          Consumer<CartProvider>(
            builder: (context, cart, child) {
              final hasItems = cart.itemCount > 0;
              return Container(
                margin: const EdgeInsets.only(right: 16, top: 8, bottom: 8),
                height: 40,
                width: 50,
                decoration: BoxDecoration(
                  color: hasItems ? cs.primary : cs.surface,
                  borderRadius: BorderRadius.circular(6),
                  border: Border.all(
                    color: hasItems ? cs.primary : cs.outlineVariant,
                  ),
                ),
                child: Stack(
                  children: [
                    Center(
                      child: IconButton(
                        icon: Icon(
                          Icons.shopping_cart_outlined,
                          size: 22,
                          color: hasItems ? cs.onPrimary : cs.onSurfaceVariant,
                        ),
                        onPressed: () {
                          Navigator.push(
                            context,
                            MaterialPageRoute(builder: (context) =>  CartScreen()),
                          );
                        },
                      ),
                    ),
                    if (hasItems)
                      Positioned(
                        right: 6,
                        top: 6,
                        child: Container(
                          padding: const EdgeInsets.all(4),
                          decoration: BoxDecoration(
                            color: cs.tertiary,
                            borderRadius: const BorderRadius.all(Radius.circular(8)),
                          ),
                          constraints: const BoxConstraints(minWidth: 16, minHeight: 16),
                          child: Text(
                            '${cart.itemCount}',
                            style: textTheme.labelSmall?.copyWith(
                              color: cs.onTertiary,
                              fontWeight: FontWeight.bold,
                            ),
                            textAlign: TextAlign.center,
                          ),
                        ),
                      ),
                  ],
                ),
              );
            },
          ),
        ],
      ),
      body: Column(
        children: [
          // Search Bar
          Container(
            color: cs.surface,
            padding: const EdgeInsets.all(16),
            child: Container(
              decoration: BoxDecoration(
                color: cs.surfaceContainerHighest,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(color: cs.outlineVariant, width: 0.8),
              ),
              child: TextField(
                style: textTheme.bodyMedium?.copyWith(color: cs.onSurface),
                decoration: InputDecoration(
                  hintText: 'Search ShopEase',
                  hintStyle: textTheme.bodyMedium?.copyWith(
                    color: cs.onSurfaceVariant,
                  ),
                  prefixIcon: Icon(Icons.search, color: cs.onSurfaceVariant, size: 20),
                  border: InputBorder.none,
                  contentPadding: const EdgeInsets.symmetric(horizontal: 12, vertical: 10),
                ),
              ),
            ),
          ),

          // Products Grid
          Expanded(
            child: Consumer<ProductProvider>(
              builder: (context, productProvider, child) {
                if (productProvider.isLoading) {
                  return Center(
                    child: CircularProgressIndicator(
                      color: cs.primary,
                      strokeWidth: 2,
                    ),
                  );
                }

                if (productProvider.error != null) {
                  return Center(
                    child: Container(
                      margin: const EdgeInsets.all(20),
                      padding: const EdgeInsets.all(20),
                      decoration: BoxDecoration(
                        color: cs.surface,
                        borderRadius: BorderRadius.circular(12),
                        border: Border.all(color: cs.outlineVariant),
                      ),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          Icon(Icons.error_outline, size: 48, color: cs.onSurfaceVariant),
                          const SizedBox(height: 12),
                          Text(
                            'Something went wrong',
                            style: textTheme.titleMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                          const SizedBox(height: 8),
                          Text(
                            productProvider.error!,
                            textAlign: TextAlign.center,
                            style: textTheme.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
                          ),
                          const SizedBox(height: 16),
                          ElevatedButton(
                            onPressed: () => productProvider.fetchProducts(),
                            child: const Text('Try Again'),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                if (productProvider.products.isEmpty) {
                  return Center(
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: Column(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          Icon(Icons.shopping_bag_outlined, size: 64, color: cs.onSurfaceVariant),
                          const SizedBox(height: 16),
                          Text(
                            'No products found',
                            style: textTheme.titleMedium?.copyWith(
                              color: cs.onSurface,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ],
                      ),
                    ),
                  );
                }

                return GridView.builder(
                  padding: const EdgeInsets.all(8),
                  gridDelegate: const SliverGridDelegateWithFixedCrossAxisCount(
                    crossAxisCount: 2,
                    childAspectRatio: 0.45,
                    crossAxisSpacing: 0,
                    mainAxisSpacing: 2,
                  ),
                  itemCount: productProvider.products.length,
                  itemBuilder: (context, index) {
                    return ProductCard(product: productProvider.products[index]);
                  },
                );
              },
            ),
          ),
        ],
      ),
    );
  }
}
