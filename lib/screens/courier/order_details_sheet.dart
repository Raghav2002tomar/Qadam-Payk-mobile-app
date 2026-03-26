import 'package:flutter/material.dart';

const Color kPrimaryColor = Color(0xFF008955);

class OrderDetailsSheet extends StatefulWidget {
  final String pickupAddress;
  final String dropAddress;
  final double distanceKm;
  final double durationMin;
  final String rideType;

  const OrderDetailsSheet({
    super.key,
    required this.pickupAddress,
    required this.dropAddress,
    required this.distanceKm,
    required this.durationMin,
    required this.rideType,
  });

  @override
  State<OrderDetailsSheet> createState() => _OrderDetailsSheetState();
}

class _OrderDetailsSheetState extends State<OrderDetailsSheet>
    with SingleTickerProviderStateMixin {
  final senderPhoneController = TextEditingController();
  final receiverPhoneController = TextEditingController();
  final senderNameController = TextEditingController();
  final receiverNameController = TextEditingController();
  final senderLandmarkController = TextEditingController();
  final receiverLandmarkController = TextEditingController();
  final packageController = TextEditingController();
  final commentController = TextEditingController();
  final priceController = TextEditingController();

  String paymentMethod = "Cash";
  String paidBy = "Sender";
  String packageSize = "Small";

  late TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 3, vsync: this);
    _calculateSuggestedPrice();
  }

  @override
  void dispose() {
    _tabController.dispose();
    senderPhoneController.dispose();
    receiverPhoneController.dispose();
    senderNameController.dispose();
    receiverNameController.dispose();
    senderLandmarkController.dispose();
    receiverLandmarkController.dispose();
    packageController.dispose();
    commentController.dispose();
    priceController.dispose();
    super.dispose();
  }

  void _calculateSuggestedPrice() {
    double basePrice = widget.rideType == "Intercity" ? 200 : 50;
    double distancePrice = widget.distanceKm * (widget.rideType == "Intercity" ? 15 : 10);
    double suggestedPrice = basePrice + distancePrice;

    priceController.text = suggestedPrice.toStringAsFixed(0);
  }

  void createOrder() {
    if (senderPhoneController.text.isEmpty ||
        receiverPhoneController.text.isEmpty) {
      _showSnackBar("Please enter sender and receiver phone");
      return;
    }

    if (packageController.text.isEmpty) {
      _showSnackBar("Please enter package description");
      return;
    }

    final orderData = {
      "pickup_address": widget.pickupAddress,
      "drop_address": widget.dropAddress,
      "sender_name": senderNameController.text,
      "sender_phone": senderPhoneController.text,
      "receiver_name": receiverNameController.text,
      "receiver_phone": receiverPhoneController.text,
      "sender_landmark": senderLandmarkController.text,
      "receiver_landmark": receiverLandmarkController.text,
      "package": packageController.text,
      "package_size": packageSize,
      "comment": commentController.text,
      "price": priceController.text,
      "payment_method": paymentMethod,
      "paid_by": paidBy,
      "distance": widget.distanceKm,
      "duration": widget.durationMin,
      "ride_type": widget.rideType,
      "status": "Searching"
    };

    print(orderData);

    Navigator.pop(context);

    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: const Text("🎉 Courier Request Created!"),
        backgroundColor: kPrimaryColor,
        behavior: SnackBarBehavior.floating,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(8)),
      ),
    );
  }

  void _showSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      height: MediaQuery.of(context).size.height * 0.9,
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
      ),
      child: Column(
        children: [
          // Compact Handle
          Container(
            margin: const EdgeInsets.only(top: 8),
            width: 36,
            height: 3,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(2),
            ),
          ),

          // Compact Header
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: Column(
              children: [
                const Text(
                  "Courier Details",
                  style: TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.bold,
                  ),
                ),
                const SizedBox(height: 8),
                _buildCompactBanner(),
              ],
            ),
          ),

          // Compact Tab Bar
          Container(
            height: 44,
            decoration: BoxDecoration(
              color: Colors.grey.shade50,
              border: Border(
                bottom: BorderSide(color: Colors.grey.shade200),
              ),
            ),
            child: TabBar(
              controller: _tabController,
              labelColor: kPrimaryColor,
              unselectedLabelColor: Colors.grey,
              indicatorColor: kPrimaryColor,
              indicatorWeight: 2.5,
              labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
              tabs: const [
                Tab(icon: Icon(Icons.people, size: 18), text: "Contact"),
                Tab(icon: Icon(Icons.inventory, size: 18), text: "Package"),
                Tab(icon: Icon(Icons.payment, size: 18), text: "Payment"),
              ],
            ),
          ),

          // Tab Content
          Expanded(
            child: TabBarView(
              controller: _tabController,
              children: [
                _buildContactTab(),
                _buildPackageTab(),
                _buildPaymentTab(),
              ],
            ),
          ),

          // Compact Continue Button
          Container(
            padding: const EdgeInsets.all(12),
            decoration: BoxDecoration(
              color: Colors.white,
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.05),
                  blurRadius: 8,
                  offset: const Offset(0, -2),
                ),
              ],
            ),
            child: SafeArea(
              child: SizedBox(
                width: double.infinity,
                child: ElevatedButton(
                  onPressed: createOrder,
                  style: ElevatedButton.styleFrom(
                    padding: const EdgeInsets.symmetric(vertical: 12),
                    backgroundColor: kPrimaryColor,
                    foregroundColor: Colors.white,
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(8),
                    ),
                  ),
                  child: const Text(
                    "Create Request",
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildCompactBanner() {
    return Container(
      padding: const EdgeInsets.all(8),
      decoration: BoxDecoration(
        color: widget.rideType == "Intercity"
            ? Colors.orange.shade50
            : kPrimaryColor.withOpacity(0.1),
        borderRadius: BorderRadius.circular(8),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _buildBannerItem(
            Icons.straighten,
            "${widget.distanceKm.toStringAsFixed(1)} km",
          ),
          Container(width: 1, height: 20, color: Colors.grey.shade300),
          _buildBannerItem(
            Icons.access_time,
            "${widget.durationMin.toStringAsFixed(0)} min",
          ),
          Container(width: 1, height: 20, color: Colors.grey.shade300),
          _buildBannerItem(
            widget.rideType == "Intercity" ? Icons.train : Icons.directions_car,
            widget.rideType,
          ),
        ],
      ),
    );
  }

  Widget _buildBannerItem(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 16, color: kPrimaryColor),
        const SizedBox(width: 4),
        Text(
          text,
          style: const TextStyle(
            fontWeight: FontWeight.w600,
            fontSize: 11,
          ),
        ),
      ],
    );
  }

  Widget _buildContactTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildCompactSection(
          title: "Sender",
          icon: Icons.person_outline,
          color: kPrimaryColor,
          children: [
            _buildCompactTextField(
              "Name (Optional)",
              senderNameController,
              Icons.person,
            ),
            const SizedBox(height: 8),
            _buildCompactTextField(
              "Phone *",
              senderPhoneController,
              Icons.phone,
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            _buildCompactTextField(
              "Landmark",
              senderLandmarkController,
              Icons.location_on,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCompactSection(
          title: "Receiver",
          icon: Icons.person,
          color: Colors.red.shade600,
          children: [
            _buildCompactTextField(
              "Name (Optional)",
              receiverNameController,
              Icons.person,
            ),
            const SizedBox(height: 8),
            _buildCompactTextField(
              "Phone *",
              receiverPhoneController,
              Icons.phone,
              keyboard: TextInputType.phone,
            ),
            const SizedBox(height: 8),
            _buildCompactTextField(
              "Landmark",
              receiverLandmarkController,
              Icons.location_on,
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildAddressInfo(),
        SizedBox(height: 100,)
      ],
    );
  }

  Widget _buildPackageTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildCompactSection(
          title: "Package",
          icon: Icons.inventory_2_outlined,
          color: Colors.orange,
          children: [
            _buildCompactTextField(
              "Description *",
              packageController,
              Icons.description,
              hint: "Documents, Electronics, Food",
            ),
            const SizedBox(height: 10),
            const Text(
              "Size",
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            _buildPackageSizeSelector(),
            const SizedBox(height: 10),
            _buildCompactTextField(
              "Instructions (Optional)",
              commentController,
              Icons.note,
              maxLines: 2,
              hint: "Handle with care, Fragile",
            ),
          ],
        ),
        const SizedBox(height: 12),
        if (widget.rideType == "Intercity")
          _buildIntercityWarning(),
      ],
    );
  }

  Widget _buildPaymentTab() {
    return ListView(
      padding: const EdgeInsets.all(12),
      children: [
        _buildCompactSection(
          title: "Price",
          icon: Icons.attach_money,
          color: Colors.purple,
          children: [
            _buildCompactTextField(
              "Your Offer",
              priceController,
              Icons.currency_rupee,
              keyboard: TextInputType.number,
              suffix: "TJS",
            ),
            const SizedBox(height: 4),
            Text(
              "Suggested: TJS ${priceController.text}",
              style: TextStyle(
                fontSize: 11,
                color: Colors.grey.shade600,
              ),
            ),
          ],
        ),
        const SizedBox(height: 12),
        _buildCompactSection(
          title: "Payment Method",
          icon: Icons.payment,
          color: kPrimaryColor,
          children: [
            _buildPaymentMethodSelector(),
          ],
        ),
        const SizedBox(height: 12),
        _buildCompactSection(
          title: "Paid By",
          icon: Icons.person_pin,
          color: Colors.teal,
          children: [
            _buildPaidBySelector(),
          ],
        ),
      ],
    );
  }

  Widget _buildCompactSection({
    required String title,
    required IconData icon,
    required Color color,
    required List<Widget> children,
  }) {
    return Container(
      padding: const EdgeInsets.all(12),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                padding: const EdgeInsets.all(6),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  borderRadius: BorderRadius.circular(6),
                ),
                child: Icon(icon, color: color, size: 16),
              ),
              const SizedBox(width: 8),
              Text(
                title,
                style: const TextStyle(
                  fontSize: 13,
                  fontWeight: FontWeight.bold,
                ),
              ),
            ],
          ),
          const SizedBox(height: 10),
          ...children,
        ],
      ),
    );
  }

  Widget _buildCompactTextField(
      String label,
      TextEditingController controller,
      IconData icon, {
        TextInputType keyboard = TextInputType.text,
        int maxLines = 1,
        String? hint,
        String? suffix,
      }) {
    return TextField(
      controller: controller,
      keyboardType: keyboard,
      maxLines: maxLines,
      style: const TextStyle(fontSize: 13),
      decoration: InputDecoration(
        labelText: label,
        labelStyle: const TextStyle(fontSize: 12),
        hintText: hint,
        hintStyle: const TextStyle(fontSize: 12),
        prefixIcon: Icon(icon, size: 18),
        suffixText: suffix,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(8),
          borderSide: const BorderSide(color: kPrimaryColor),
        ),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 12,
          vertical: 10,
        ),
        isDense: true,
      ),
    );
  }

  Widget _buildPackageSizeSelector() {
    final sizes = [
      {"label": "Small", "icon": Icons.inventory, "desc": "<2kg"},
      {"label": "Medium", "icon": Icons.inventory_2, "desc": "2-10kg"},
      {"label": "Large", "icon": Icons.luggage, "desc": ">10kg"},
    ];

    return Row(
      children: sizes.map((size) {
        final isSelected = packageSize == size["label"];
        return Expanded(
          child: GestureDetector(
            onTap: () => setState(() => packageSize = size["label"] as String),
            child: Container(
              margin: const EdgeInsets.symmetric(horizontal: 3),
              padding: const EdgeInsets.symmetric(vertical: 8),
              decoration: BoxDecoration(
                color: isSelected
                    ? kPrimaryColor
                    : Colors.grey.shade100,
                borderRadius: BorderRadius.circular(8),
                border: Border.all(
                  color: isSelected
                      ? kPrimaryColor
                      : Colors.grey.shade300,
                ),
              ),
              child: Column(
                children: [
                  Icon(
                    size["icon"] as IconData,
                    size: 20,
                    color: isSelected ? Colors.white : Colors.grey.shade700,
                  ),
                  const SizedBox(height: 3),
                  Text(
                    size["label"] as String,
                    style: TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: isSelected ? Colors.white : Colors.grey.shade700,
                    ),
                  ),
                  Text(
                    size["desc"] as String,
                    style: TextStyle(
                      fontSize: 9,
                      color: isSelected ? Colors.white70 : Colors.grey.shade600,
                    ),
                  ),
                ],
              ),
            ),
          ),
        );
      }).toList(),
    );
  }

  Widget _buildPaymentMethodSelector() {
    return Row(
      children: [
        Expanded(
          child: _buildCompactRadio(
            "Cash",
            paymentMethod == "Cash",
            Icons.money,
                () => setState(() => paymentMethod = "Cash"),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactRadio(
            "Card",
            paymentMethod == "Card",
            Icons.credit_card,
                () => setState(() => paymentMethod = "Card"),
          ),
        ),
      ],
    );
  }

  Widget _buildPaidBySelector() {
    return Row(
      children: [
        Expanded(
          child: _buildCompactRadio(
            "Sender",
            paidBy == "Sender",
            Icons.person,
                () => setState(() => paidBy = "Sender"),
          ),
        ),
        const SizedBox(width: 8),
        Expanded(
          child: _buildCompactRadio(
            "Receiver",
            paidBy == "Receiver",
            Icons.person_outline,
                () => setState(() => paidBy = "Receiver"),
          ),
        ),
      ],
    );
  }

  Widget _buildCompactRadio(
      String label,
      bool isSelected,
      IconData icon,
      VoidCallback onTap,
      ) {
    return GestureDetector(
      onTap: onTap,
      child: Container(
        padding: const EdgeInsets.symmetric(vertical: 10),
        decoration: BoxDecoration(
          color: isSelected ? kPrimaryColor : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(8),
          border: Border.all(
            color: isSelected ? kPrimaryColor : Colors.grey.shade300,
          ),
        ),
        child: Row(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Icon(
              icon,
              color: isSelected ? Colors.white : Colors.grey.shade700,
              size: 16,
            ),
            const SizedBox(width: 6),
            Text(
              label,
              style: TextStyle(
                fontSize: 12,
                fontWeight: FontWeight.w600,
                color: isSelected ? Colors.white : Colors.grey.shade700,
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildAddressInfo() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.grey.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.grey.shade200),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Text(
            "Route",
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.bold,
            ),
          ),
          const SizedBox(height: 8),
          _buildAddressRow(
            Icons.circle,
            kPrimaryColor,
            "Pickup",
            widget.pickupAddress,
          ),
          const SizedBox(height: 6),
          _buildAddressRow(
            Icons.location_on,
            Colors.red.shade600,
            "Drop",
            widget.dropAddress,
          ),
        ],
      ),
    );
  }

  Widget _buildAddressRow(
      IconData icon,
      Color color,
      String label,
      String address,
      ) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                  fontSize: 10,
                  color: Colors.grey.shade600,
                ),
              ),
              Text(
                address,
                style: const TextStyle(fontSize: 11),
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildIntercityWarning() {
    return Container(
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: Colors.orange.shade50,
        borderRadius: BorderRadius.circular(8),
        border: Border.all(color: Colors.orange.shade200),
      ),
      child: Row(
        children: [
          Icon(Icons.info_outline, color: Colors.orange.shade700, size: 20),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  "Intercity Delivery",
                  style: TextStyle(
                    fontWeight: FontWeight.bold,
                    color: Colors.orange.shade700,
                    fontSize: 12,
                  ),
                ),
                const SizedBox(height: 3),
                Text(
                  "Long distance may take longer. Ensure package details are accurate.",
                  style: TextStyle(
                    fontSize: 11,
                    color: Colors.orange.shade800,
                  ),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}