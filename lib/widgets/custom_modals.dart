import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import '../models/user_details.dart';
import '../providers/cart_provider.dart';

class CustomModals {
  static void showSuccessModal(BuildContext context, String title, String message) {
    showDialog(
      context: context,
      builder: (context) => AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        title: Row(
          children: [
            Container(
              padding: const EdgeInsets.all(8),
              decoration: BoxDecoration(
                color: const Color(0xFF1976D2),
                borderRadius: BorderRadius.circular(20),
              ),
              child: const Icon(Icons.check, color: Colors.white, size: 20),
            ),
            const SizedBox(width: 12),
            Text(title),
          ],
        ),
        content: Text(message),
        actions: [
          ElevatedButton(
            style: ElevatedButton.styleFrom(
              backgroundColor: const Color(0xFFFF9800),
              foregroundColor: Colors.white,
              elevation: 0,
              disabledBackgroundColor: Colors.grey.shade300,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(8),
              ),
            ),
            onPressed: () => Navigator.pop(context),
            child: const Text('OK'),
          ),
        ],
      ),
    );
  }

  static void showCheckoutModal(BuildContext context) {
    showDialog(
      context: context,
      builder: (context) => CheckoutModal(),
    );
  }
}

class CheckoutModal extends StatefulWidget {
  @override
  _CheckoutModalState createState() => _CheckoutModalState();
}

class _CheckoutModalState extends State<CheckoutModal> {
  final _formKey = GlobalKey<FormState>();
  final _nameController = TextEditingController();
  final _addressController = TextEditingController();
  String _paymentMethod = 'Credit Card';

  final List<String> _paymentMethods = [
    'Credit Card',
    'Debit Card',
    'PayPal',
    'Cash on Delivery',
  ];

  @override
  Widget build(BuildContext context) {
    return Dialog(
      shape: RoundedRectangleBorder(
        borderRadius: BorderRadius.circular(12),
      ),
      child: Container(
        constraints: BoxConstraints(
          maxHeight: MediaQuery.of(context).size.height * 0.8,
        ),
        child: SingleChildScrollView(
          child: Padding(
            padding: const EdgeInsets.all(24),
            child: Form(
              key: _formKey,
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    'Checkout',
                    style: TextStyle(
                      fontSize: 24,
                      fontWeight: FontWeight.bold,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 24),

                  // Name Field
                  TextFormField(
                    controller: _nameController,
                    decoration: const InputDecoration(
                      labelText: 'Full Name',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.person, color: Color(0xFF1976D2)),
                    ),
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your name';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Address Field
                  TextFormField(
                    controller: _addressController,
                    decoration: const InputDecoration(
                      labelText: 'Delivery Address',
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.location_on, color: Color(0xFF1976D2)),
                    ),
                    maxLines: 3,
                    validator: (value) {
                      if (value == null || value.trim().isEmpty) {
                        return 'Please enter your address';
                      }
                      return null;
                    },
                  ),

                  const SizedBox(height: 16),

                  // Payment Method
                  const Text(
                    'Payment Method',
                    style: TextStyle(
                      fontSize: 16,
                      fontWeight: FontWeight.w600,
                      color: Color(0xFF212121),
                    ),
                  ),
                  const SizedBox(height: 8),
                  DropdownButtonFormField<String>(
                    value: _paymentMethod,
                    decoration: const InputDecoration(
                      border: OutlineInputBorder(),
                      prefixIcon: Icon(Icons.payment, color: Color(0xFF1976D2)),
                    ),
                    items: _paymentMethods.map((method) {
                      return DropdownMenuItem(
                        value: method,
                        child: Text(method),
                      );
                    }).toList(),
                    onChanged: (value) {
                      setState(() {
                        _paymentMethod = value!;
                      });
                    },
                  ),

                  const SizedBox(height: 24),

                  // Order Summary
                  Container(
                    padding: const EdgeInsets.all(16),
                    decoration: BoxDecoration(
                      color: const Color(0xFFFAFAFA),
                      borderRadius: BorderRadius.circular(8),
                      border: Border.all(color: Colors.grey.shade300),
                    ),
                    child: Consumer<CartProvider>(
                      builder: (context, cart, child) {
                        return Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            const Text(
                              'Order Summary',
                              style: TextStyle(
                                fontSize: 16,
                                fontWeight: FontWeight.bold,
                                color: Color(0xFF212121),
                              ),
                            ),
                            const SizedBox(height: 12),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                Text('Items (${cart.itemCount}):'),
                                Text('\$${cart.totalAmount.toStringAsFixed(2)}'),
                              ],
                            ),
                            const Divider(),
                            Row(
                              mainAxisAlignment: MainAxisAlignment.spaceBetween,
                              children: [
                                const Text(
                                  'Total:',
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF212121),
                                  ),
                                ),
                                Text(
                                  '\$${cart.totalAmount.toStringAsFixed(2)}',
                                  style: const TextStyle(
                                    fontWeight: FontWeight.bold,
                                    color: Color(0xFF1976D2),
                                    fontSize: 18,
                                  ),
                                ),
                              ],
                            ),
                          ],
                        );
                      },
                    ),
                  ),

                  const SizedBox(height: 24),

                  // Action Buttons
                  Row(
                    children: [
                      Expanded(
                        child: TextButton(
                          onPressed: () => Navigator.pop(context),
                          child: const Text('Cancel',style: TextStyle(color: const Color(0xFFFF9800),),),
                        ),
                      ),
                      const SizedBox(width: 12),
                      Expanded(
                        child: ElevatedButton(
                          onPressed: () {
                            // if (_formKey.currentState!.validate()) {
                            //   final userDetails = UserDetails(
                            //     name: _nameController.text.trim(),
                            //     address: _addressController.text.trim(),
                            //     paymentMethod: _paymentMethod,
                            //   );
                            //
                            //   _placeOrder(context, userDetails);
                            // }
                          },
                          style: ElevatedButton.styleFrom(
                            backgroundColor: const Color(0xFFFF9800),
                            foregroundColor: Colors.white,
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(8),
                            ),
                          ),
                          child: const Text('Place Order'),
                        ),
                      ),
                    ],
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }

  // void _placeOrder(BuildContext context, UserDetails userDetails) {
  //   Navigator.pop(context);
  //   context.read<CartProvider>().clearCart();
  //
  //   showDialog(
  //     context: context,
  //     barrierDismissible: false,
  //     builder: (context) => AlertDialog(
  //       shape: RoundedRectangleBorder(
  //         borderRadius: BorderRadius.circular(12),
  //       ),
  //       title: Row(
  //         children: [
  //           Container(
  //             padding: const EdgeInsets.all(8),
  //             decoration: BoxDecoration(
  //               color: const Color(0xFF1976D2),
  //               borderRadius: BorderRadius.circular(20),
  //             ),
  //             child: const Icon(Icons.check_circle, color: Colors.white),
  //           ),
  //           const SizedBox(width: 12),
  //           const Text('Order Placed!'),
  //         ],
  //       ),
  //       content: Column(
  //         mainAxisSize: MainAxisSize.min,
  //         crossAxisAlignment: CrossAxisAlignment.start,
  //         children: [
  //           const Text('Your order has been placed successfully.'),
  //           const SizedBox(height: 16),
  //           const Text('Order Details:', style: TextStyle(fontWeight: FontWeight.bold)),
  //           Text('Name: ${userDetails.name}'),
  //           Text('Address: ${userDetails.address}'),
  //           Text('Payment: ${userDetails.paymentMethod}'),
  //         ],
  //       ),
  //       actions: [
  //         ElevatedButton(
  //           onPressed: () {
  //             Navigator.pop(context);
  //             Navigator.pop(context);
  //           },
  //           child: const Text('Continue Shopping'),
  //         ),
  //       ],
  //     ),
  //   );
  // }

  @override
  void dispose() {
    _nameController.dispose();
    _addressController.dispose();
    super.dispose();
  }
}
