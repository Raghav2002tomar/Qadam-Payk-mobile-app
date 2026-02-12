import 'package:flutter/material.dart';

class OrderDetailsSheet extends StatefulWidget {
  final String pickupAddress;
  final String dropAddress;
  final double distanceKm;
  final double durationMin;

  const OrderDetailsSheet({
    super.key,
    required this.pickupAddress,
    required this.dropAddress,
    required this.distanceKm,
    required this.durationMin,
  });

  @override
  State<OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<OrderDetailsSheet> {

  final senderPhoneController = TextEditingController();
  final receiverPhoneController = TextEditingController();
  final senderLandmarkController = TextEditingController();
  final receiverLandmarkController = TextEditingController();
  final packageController = TextEditingController();
  final commentController = TextEditingController();
  final priceController = TextEditingController();

  String paymentMethod = "Cash";
  String paidBy = "Sender";

  void createOrder() {

    final orderData = {

      "pickup_address": widget.pickupAddress,
      "drop_address": widget.dropAddress,

      "sender_phone": senderPhoneController.text,
      "receiver_phone": receiverPhoneController.text,

      "sender_landmark": senderLandmarkController.text,
      "receiver_landmark": receiverLandmarkController.text,

      "package": packageController.text,
      "comment": commentController.text,

      "price": priceController.text,
      "payment_method": paymentMethod,
      "paid_by": paidBy,

      "distance": widget.distanceKm,
      "duration": widget.durationMin,

      "status": "Searching"

    };

    print(orderData);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      const SnackBar(content: Text("Courier Request Created")),
    );

  }

  @override
  Widget build(BuildContext context) {

    return Container(
      padding: const EdgeInsets.all(16),
      height: MediaQuery.of(context).size.height * 0.85,
      child: Column(
        children: [

          Container(
            width: 50,
            height: 5,
            decoration: BoxDecoration(
              color: Colors.grey,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 10),

          const Text(
            "Courier Details",
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),

          const SizedBox(height: 15),

          Expanded(
            child: ListView(
              children: [

                _sectionTitle("Route"),

                _infoTile("Pickup", widget.pickupAddress),

                _infoTile("Drop", widget.dropAddress),

                _infoTile(
                    "Distance",
                    "${widget.distanceKm.toStringAsFixed(2)} km"),

                _infoTile(
                    "ETA",
                    "${widget.durationMin.toStringAsFixed(0)} mins"),

                _sectionTitle("Sender"),

                _textField(
                    "Sender Phone", senderPhoneController,
                    keyboard: TextInputType.phone),

                _textField(
                    "Sender Landmark (optional)",
                    senderLandmarkController),

                _sectionTitle("Receiver"),

                _textField(
                    "Receiver Phone", receiverPhoneController,
                    keyboard: TextInputType.phone),

                _textField(
                    "Receiver Landmark (optional)",
                    receiverLandmarkController),

                _sectionTitle("Package"),

                _textField(
                    "Package Description", packageController),

                _textField(
                    "Courier Comment (optional)", commentController),

                _sectionTitle("Payment"),

                _textField(
                    "Propose Price", priceController,
                    keyboard: TextInputType.number),

                const SizedBox(height: 10),

                const Text("Payment Method"),

                Row(
                  children: [
                    Expanded(
                      child: RadioListTile(
                        title: const Text("Cash"),
                        value: "Cash",
                        groupValue: paymentMethod,
                        onChanged: (value) {
                          setState(() {
                            paymentMethod = value!;
                          });
                        },
                      ),
                    ),

                    Expanded(
                      child: RadioListTile(
                        title: const Text("Card"),
                        value: "Card",
                        groupValue: paymentMethod,
                        onChanged: (value) {
                          setState(() {
                            paymentMethod = value!;
                          });
                        },
                      ),
                    ),
                  ],
                ),

                const Text("Paid By"),

                Row(
                  children: [

                    Expanded(
                      child: RadioListTile(
                        title: const Text("Sender"),
                        value: "Sender",
                        groupValue: paidBy,
                        onChanged: (value) {
                          setState(() {
                            paidBy = value!;
                          });
                        },
                      ),
                    ),

                    Expanded(
                      child: RadioListTile(
                        title: const Text("Receiver"),
                        value: "Receiver",
                        groupValue: paidBy,
                        onChanged: (value) {
                          setState(() {
                            paidBy = value!;
                          });
                        },
                      ),
                    ),

                  ],
                ),

                const SizedBox(height: 20),

                ElevatedButton(
                  onPressed: createOrder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.all(16),
                  ),
                  child: const Text("Create Courier Request"),
                ),

              ],
            ),
          ),

        ],
      ),
    );
  }

  Widget _sectionTitle(String title) {
    return Padding(
      padding: const EdgeInsets.only(top: 20, bottom: 10),
      child: Text(
        title,
        style: const TextStyle(
            fontSize: 16,
            fontWeight: FontWeight.bold),
      ),
    );
  }

  Widget _infoTile(String title, String value) {
    return ListTile(
      title: Text(title),
      subtitle: Text(value),
    );
  }

  Widget _textField(
      String hint,
      TextEditingController controller,
      {TextInputType keyboard = TextInputType.text}) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 10),
      child: TextField(
        controller: controller,
        keyboardType: keyboard,
        decoration: InputDecoration(
          hintText: hint,
          border: const OutlineInputBorder(),
        ),
      ),
    );
  }
}
