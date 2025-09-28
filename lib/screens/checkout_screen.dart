import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../providers/cart_provider.dart';
import '../providers/translate_provider.dart';
import '../models/user_details.dart';

class CheckoutScreen extends StatefulWidget {
  const CheckoutScreen({super.key});
  @override
  State<CheckoutScreen> createState() => _CheckoutScreenState();
}

class _CheckoutScreenState extends State<CheckoutScreen> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _phoneController = TextEditingController();
  final _addressController = TextEditingController();
  final _pincodeController = TextEditingController();

  String _selectedPayment = 'cod';

  @override
  void dispose() {
    _nameController.dispose();
    _phoneController.dispose();
    _addressController.dispose();
    _pincodeController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = context.watch<TranslateProvider>().t;

    return Scaffold(
      backgroundColor: Theme.of(context).scaffoldBackgroundColor,
      appBar: AppBar(
        title: Text(
          t('checkout'),
          style: tt.titleLarge?.copyWith(
            fontWeight: FontWeight.w600,
            color: cs.onSurface,
            fontSize: 18,
          ),
        ),
        backgroundColor: cs.surface,
        elevation: 0,
        surfaceTintColor: cs.surface,
        leading: IconButton(
          icon: Icon(Icons.arrow_back_ios, color: cs.onSurface, size: 20),
          onPressed: () => Navigator.pop(context),
        ),
      ),
      body: Form(
        key: _formKey,
        child: Column(
          children: [
            Expanded(
              child: SingleChildScrollView(
                child: Column(
                  children: [
                    _buildOrderSummaryCard(context, cs, tt),
                    const SizedBox(height: 16),
                    _buildDeliveryAddressCard(context, cs, tt),
                    const SizedBox(height: 16),
                    _buildPaymentMethodCard(context, cs, tt),
                    const SizedBox(height: 100),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
      bottomNavigationBar: _buildCheckoutBottomBar(context, cs, tt),
    );
  }

  Widget _buildOrderSummaryCard(BuildContext context, ColorScheme cs, TextTheme tt) {
    final t = context.watch<TranslateProvider>().t;
    return Consumer<CartProvider>(
      builder: (context, cart, child) {
        return Container(
          margin: const EdgeInsets.fromLTRB(16, 8, 16, 0),
          decoration: BoxDecoration(
            color: cs.surface,
            borderRadius: BorderRadius.circular(12),
            boxShadow: [
              BoxShadow(
                color: cs.shadow.withOpacity(0.08),
                blurRadius: 8,
                offset: const Offset(0, 2),
              ),
            ],
          ),
          child: Padding(
            padding: const EdgeInsets.all(20),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Row(
                  children: [
                    Container(
                      width: 6,
                      height: 24,
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(3),
                      ),
                    ),
                    const SizedBox(width: 12),
                    Text(
                      t('order_summary'),
                      style: tt.titleMedium?.copyWith(
                        fontSize: 18,
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    const Spacer(),
                    Container(
                      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                      decoration: BoxDecoration(
                        color: cs.secondaryContainer,
                        borderRadius: BorderRadius.circular(12),
                      ),
                      child: Text(
                        '${cart.itemCount} ${t('items')}',
                        style: tt.labelSmall?.copyWith(
                          fontWeight: FontWeight.w600,
                          color: cs.onSecondaryContainer,
                        ),
                      ),
                    ),
                  ],
                ),
                const SizedBox(height: 20),
                _buildPriceRow(context, t('subtotal'), '\$${cart.totalAmount.toStringAsFixed(2)}', cs, tt),
                _buildPriceRow(context, t('delivery'), t('free').toUpperCase(), cs, tt, isGreen: true),
                _buildPriceRow(context, t('service_fee'), t('free').toUpperCase(), cs, tt, isGreen: true),
                const SizedBox(height: 12),
                Divider(height: 1, color: cs.outlineVariant),
                const SizedBox(height: 12),
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      t('total_amount'),
                      style: tt.titleMedium?.copyWith(
                        fontWeight: FontWeight.w600,
                        color: cs.onSurface,
                      ),
                    ),
                    Text(
                      '\$${cart.totalAmount.toStringAsFixed(2)}',
                      style: tt.headlineSmall?.copyWith(
                        fontWeight: FontWeight.bold,
                        color: cs.primary,
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  Widget _buildDeliveryAddressCard(BuildContext context, ColorScheme cs, TextTheme tt) {
    final t = context.watch<TranslateProvider>().t;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 24,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  t('delivery_address'),
                  style: tt.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 24),
            _buildTextField(
              context: context,
              controller: _nameController,
              label: t('full_name'),
              hint: t('enter_full_name'),
              icon: Icons.person_outline,
              validator: (value) => (value == null || value.trim().isEmpty) ? t('full_name_required') : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context: context,
              controller: _phoneController,
              label: t('phone_number'),
              hint: t('enter_phone'),
              icon: Icons.phone_outlined,
              keyboardType: TextInputType.phone,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return t('phone_required');
                if (value.length < 10) return t('invalid_phone');
                return null;
              },
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context: context,
              controller: _addressController,
              label: t('address'),
              hint: t('enter_address'),
              icon: Icons.location_on_outlined,
              maxLines: 3,
              validator: (value) => (value == null || value.trim().isEmpty) ? t('address_required') : null,
            ),
            const SizedBox(height: 16),
            _buildTextField(
              context: context,
              controller: _pincodeController,
              label: t('pincode'),
              hint: t('enter_pincode'),
              icon: Icons.pin_drop_outlined,
              keyboardType: TextInputType.number,
              validator: (value) {
                if (value == null || value.trim().isEmpty) return t('pincode_required');
                if (value.length != 6) return t('invalid_pincode');
                return null;
              },
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildPaymentMethodCard(BuildContext context, ColorScheme cs, TextTheme tt) {
    final t = context.watch<TranslateProvider>().t;
    return Container(
      margin: const EdgeInsets.symmetric(horizontal: 16),
      decoration: BoxDecoration(
        color: cs.surface,
        borderRadius: BorderRadius.circular(12),
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Container(
                  width: 6,
                  height: 24,
                  decoration: BoxDecoration(
                    color: cs.primary,
                    borderRadius: BorderRadius.circular(3),
                  ),
                ),
                const SizedBox(width: 12),
                Text(
                  t('payment_method'),
                  style: tt.titleMedium?.copyWith(
                    fontSize: 18,
                    fontWeight: FontWeight.w600,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 20),
            // COD
            GestureDetector(
              onTap: () => setState(() => _selectedPayment = 'cod'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedPayment == 'cod' ? cs.primary : cs.outlineVariant,
                    width: _selectedPayment == 'cod' ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _selectedPayment == 'cod' ? cs.surfaceContainerHigh : cs.surface,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.local_shipping_outlined, color: cs.onPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('cash_on_delivery'),
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t('pay_on_delivery'),
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: 'cod',
                      groupValue: _selectedPayment,
                      onChanged: (value) => setState(() => _selectedPayment = value!),
                      activeColor: cs.primary,
                    ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 12),
            // Online
            GestureDetector(
              onTap: () => setState(() => _selectedPayment = 'online'),
              child: Container(
                padding: const EdgeInsets.all(16),
                decoration: BoxDecoration(
                  border: Border.all(
                    color: _selectedPayment == 'online' ? cs.primary : cs.outlineVariant,
                    width: _selectedPayment == 'online' ? 2 : 1,
                  ),
                  borderRadius: BorderRadius.circular(8),
                  color: _selectedPayment == 'online' ? cs.surfaceContainerHigh : cs.surface,
                ),
                child: Row(
                  children: [
                    Container(
                      padding: const EdgeInsets.all(8),
                      decoration: BoxDecoration(
                        color: cs.primary,
                        borderRadius: BorderRadius.circular(6),
                      ),
                      child: Icon(Icons.credit_card_outlined, color: cs.onPrimary, size: 20),
                    ),
                    const SizedBox(width: 12),
                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            t('pay_now_online'),
                            style: tt.titleSmall?.copyWith(
                              fontWeight: FontWeight.w600,
                              color: cs.onSurface,
                            ),
                          ),
                          const SizedBox(height: 2),
                          Text(
                            t('upi_cards'),
                            style: tt.bodySmall?.copyWith(color: cs.onSurfaceVariant),
                          ),
                        ],
                      ),
                    ),
                    Radio<String>(
                      value: 'online',
                      groupValue: _selectedPayment,
                      onChanged: (value) => setState(() => _selectedPayment = value!),
                      activeColor: cs.primary,
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

  Widget _buildTextField({
    required BuildContext context,
    required TextEditingController controller,
    required String label,
    required String hint,
    IconData? icon,
    int maxLines = 1,
    TextInputType? keyboardType,
    String? Function(String?)? validator,
  }) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(
          label,
          style: tt.labelLarge?.copyWith(
            fontWeight: FontWeight.w500,
            color: cs.onSurface,
          ),
        ),
        const SizedBox(height: 8),
        TextFormField(
          controller: controller,
          maxLines: maxLines,
          keyboardType: keyboardType,
          validator: validator,
          style: tt.bodyMedium?.copyWith(color: cs.onSurface),
          decoration: InputDecoration(
            hintText: hint,
            hintStyle: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant, fontSize: 14),
            prefixIcon: icon != null ? Icon(icon, color: cs.onSurfaceVariant, size: 20) : null,
            border: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            enabledBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.outlineVariant),
            ),
            focusedBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.primary, width: 2),
            ),
            errorBorder: OutlineInputBorder(
              borderRadius: BorderRadius.circular(8),
              borderSide: BorderSide(color: cs.error),
            ),
            contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
            filled: true,
            fillColor: cs.surfaceContainerHighest,
          ),
        ),
      ],
    );
  }

  Widget _buildPriceRow(BuildContext context, String label, String value, ColorScheme cs, TextTheme tt, {bool isGreen = false}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 8),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceBetween,
        children: [
          Text(label, style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant)),
          Text(
            value,
            style: tt.bodyMedium?.copyWith(
              fontWeight: FontWeight.w600,
              color: isGreen ? Colors.green : cs.onSurface,
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCheckoutBottomBar(BuildContext context, ColorScheme cs, TextTheme tt) {
    final cart = context.watch<CartProvider>();
    final t = context.watch<TranslateProvider>().t;
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: BoxDecoration(
        color: cs.surface,
        boxShadow: [
          BoxShadow(
            color: cs.shadow.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, -4),
          ),
        ],
      ),
      child: SafeArea(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Text(t('total_amount'),
                  style: tt.titleSmall?.copyWith(
                    fontWeight: FontWeight.w500,
                    color: cs.onSurfaceVariant,
                  ),
                ),
                Text(
                  '\$${cart.totalAmount.toStringAsFixed(2)}',
                  style: tt.headlineSmall?.copyWith(
                    fontWeight: FontWeight.bold,
                    color: cs.onSurface,
                  ),
                ),
              ],
            ),
            const SizedBox(height: 16),
            SizedBox(
              width: double.infinity,
              height: 50,
              child: ElevatedButton(
                onPressed: cart.itemCount > 0 ? () => _placeOrder(context, cart) : null,
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  disabledBackgroundColor: cs.surfaceContainerHigh,
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                  elevation: 0,
                ),
                child: Text(
                  _selectedPayment == 'cod' ? context.watch<TranslateProvider>().t('place_order') : context.watch<TranslateProvider>().t('proceed_payment'),
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _placeOrder(BuildContext context, CartProvider cart) {
    if (_formKey.currentState!.validate()) {
      cart.clearCart();
      _showOrderSuccessDialog(context);
    }
  }

  void _showOrderSuccessDialog(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final tt = Theme.of(context).textTheme;
    final t = context.watch<TranslateProvider>().t;

    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (context) => AlertDialog(
        backgroundColor: cs.surface,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
        contentPadding: const EdgeInsets.all(24),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 80,
              height: 80,
              decoration: BoxDecoration(
                color: cs.secondaryContainer,
                borderRadius: BorderRadius.circular(40),
              ),
              child: Icon(Icons.check, color: cs.onSecondaryContainer, size: 40),
            ),
            const SizedBox(height: 20),
            Text(
              t('order_success'),
              style: tt.titleLarge?.copyWith(
                fontWeight: FontWeight.bold,
                color: cs.onSurface,
              ),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            Text(
              t('order_thanks'),
              style: tt.bodyMedium?.copyWith(color: cs.onSurfaceVariant),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 24),
            SizedBox(
              width: double.infinity,
              child: ElevatedButton(
                onPressed: () {
                  Navigator.of(context).pop();
                  Navigator.of(context).popUntil((route) => route.isFirst);
                },
                style: ElevatedButton.styleFrom(
                  backgroundColor: cs.primary,
                  foregroundColor: cs.onPrimary,
                  elevation: 0,
                  padding: const EdgeInsets.symmetric(vertical: 12),
                  shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
                ),
                child: Text(
                  t('continue_shopping'),
                  style: tt.titleSmall?.copyWith(fontWeight: FontWeight.w600),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
