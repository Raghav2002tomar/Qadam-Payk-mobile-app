
import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:intl/intl.dart';

import '../../api_service/app_constocter.dart';
import '../../service/local_cache.dart';
import 'model/CourierModel.dart';
import 'order_detail_screen.dart';

const Color kPrimaryColor = Color(0xFF008955);

class OrderListScreen extends StatefulWidget {
  final bool isDriverMode;

  const OrderListScreen({super.key, required this.isDriverMode});

  @override
  State<OrderListScreen> createState() => _OrderListScreenState();
}

class _OrderListScreenState extends State<OrderListScreen> {
  List<CourierModel> orders = [];
  bool isLoading = false;
  String selectedFilter = "All";

  @override
  void initState() {
    super.initState();
    fetchOrders();
  }

  /// ================= FETCH ORDERS =================
  Future<void> fetchOrders() async {
    setState(() => isLoading = true);

    try {
      final token = await LocalCache.getToken();

      String type = "";
      switch (selectedFilter) {
        case "Searching":
          type = "pending";
          break;
        case "Accepted":
          type = "accepted";
          break;
        case "In Transit":
          type = "in_transit";
          break;
        case "Delivered":
          type = "completed";
          break;
        case "Cancelled":
          type = "cancelled";
          break;
      }

      String baseUrl = widget.isDriverMode
          ? "${App_Constructor().BaseURL}/api/driver/couriers"
          : "${App_Constructor().BaseURL}/api/sender/couriers";

      String url = type.isNotEmpty ? "$baseUrl?type=$type" : baseUrl;

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);

        if (decoded["status"] == true) {
          final List list = decoded["data"];
          orders = list.map((e) => CourierModel.fromJson(e)).toList();
        }
      }
    } catch (e) {
      debugPrint("Error: $e");
    }

    setState(() => isLoading = false);
  }


  Future<void> cancelOrder(int id) async {
    try {

      final token = await LocalCache.getToken();

      final response = await http.post(
        Uri.parse("${App_Constructor().BaseURL}/api/sender/courier/cancel/$id"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
      );

      final data = jsonDecode(response.body);

      if (data["status"] == true) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"])),
        );

        fetchOrders();
      }

    } catch (e) {
      debugPrint(e.toString());
    }
  }


  void showUpdatePriceDialog(CourierModel order) {

    final priceController =
    TextEditingController(text: order.suggestedPrice);

    showDialog(
      context: context,
      builder: (context) {

        return AlertDialog(
          title: const Text("Update Price"),

          content: TextField(
            controller: priceController,
            keyboardType: TextInputType.number,
            decoration: const InputDecoration(
              labelText: "Suggested Price",
            ),
          ),

          actions: [

            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text("Cancel"),
            ),

            ElevatedButton(
              onPressed: () {

                updatePrice(order.id, priceController.text);

                Navigator.pop(context);
              },
              child: const Text("Submit"),
            ),
          ],
        );
      },
    );
  }
  String formatDateTime(String date) {
    try {
      final parsedDate = DateTime.parse(date).toLocal();
      return DateFormat("dd MMM yyyy • hh:mm a").format(parsedDate);
    } catch (e) {
      return date;
    }
  }

  Future<void> updatePrice(int id, String price) async {

    try {

      final token = await LocalCache.getToken();

      final response = await http.post(
        Uri.parse("${App_Constructor().BaseURL}/api/courier/edit-payment"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },

        body: jsonEncode({
          "courier_request_id": id,
          "payment_method": "card",
          "paid_by": "receiver",
          "suggested_price": price
        }),
      );

      final data = jsonDecode(response.body);

      if (data["status"] == true) {

        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(content: Text(data["message"])),
        );

        fetchOrders();
      }

    } catch (e) {
      debugPrint(e.toString());
    }
  }


  /// ================= FILTERED ORDERS =================
  List<CourierModel> get filteredOrders {
    if (selectedFilter == "All") return orders;

    return orders.where((o) =>
    o.status.toLowerCase() == selectedFilter.toLowerCase()).toList();
  }


  /// ================= UI =================
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.grey.shade50,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: Text(
          widget.isDriverMode ? "All Courier Orders" : "My Courier Orders",
          style: const TextStyle(
            color: Colors.black87,
            fontSize: 16,
            fontWeight: FontWeight.bold,
          ),
        ),
        actions: [
          IconButton(
            icon: const Icon(Icons.filter_list,
                color: kPrimaryColor, size: 22),
            onPressed: _showFilterSheet,
          ),
        ],
      ),
      body: Column(
        children: [
          /// FILTER CHIPS (SAME AS OLD UI)
          Container(
            color: Colors.white,
            padding:
            const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
            child: SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  _buildFilterChip("All", orders.length),
                  const SizedBox(width: 8),
                _buildFilterChip(
                    "Searching",
                    orders.where((o) => o.status.toLowerCase() == "pending").length
                ),
                  const SizedBox(width: 8),
                  _buildFilterChip("Accepted",
                      orders.where((o) => o.status == "Accepted").length),
                  const SizedBox(width: 8),
                  _buildFilterChip("In Transit",
                      orders.where((o) => o.status == "In Transit").length),
                  const SizedBox(width: 8),
                  _buildFilterChip("Delivered",
                      orders.where((o) => o.status == "Delivered").length),
                  const SizedBox(width: 8),
                  _buildFilterChip(
                      "Cancelled",
                      orders.where((o) => o.status.toLowerCase() == "cancelled").length
                  ),               ],
              ),
            ),
          ),

          /// LIST
          Expanded(
            child: isLoading
                ? const Center(child: CircularProgressIndicator())
                : filteredOrders.isEmpty
                ? _buildEmptyState()
                : ListView.builder(
              padding: const EdgeInsets.all(12),
              itemCount: filteredOrders.length,
              itemBuilder: (context, index) {
                return _buildOrderCard(filteredOrders[index]);
              },
            ),
          ),
        ],
      ),
    );
  }

  /// ================= ORDER CARD (UNCHANGED UI STYLE) =================
  Widget _buildOrderCard(CourierModel order) {
    return GestureDetector(
      onTap: () {
        // In OrderListScreen._buildOrderCard(), change the Navigator.push to:
        // In your OrderListScreen._buildOrderCard()
        Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => CourierDetailScreen(
              orderId: order.id.toString(), // Pass only the ID
            ),
          ),
        );
      },
      child: Container(
        margin: const EdgeInsets.only(bottom: 12),
        padding: const EdgeInsets.all(12),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(10),
          border: Border.all(color: Colors.grey.shade200),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.04),
              blurRadius: 8,
              offset: const Offset(0, 2),
            ),
          ],
        ),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [

            /// HEADER
            Row(
              mainAxisAlignment: MainAxisAlignment.spaceBetween,
              children: [
                Row(
                  children: [
                    Text(
                      order.id.toString(),
                      style: const TextStyle(
                          fontSize: 13,
                          fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(width: 8),
                    _buildStatusBadge(order.status),
                  ],
                ),

                Row(
                  children: [

                    Text(
                      formatDateTime(order.createdAt),
                      style: TextStyle(
                        fontSize: 11,
                        color: Colors.grey.shade600,
                      ),
                    ),

                    if (order.status == "Searching")
                      PopupMenuButton<String>(
                        icon: const Icon(Icons.more_vert, size: 18),
                        onSelected: (value) {
                          if (value == "cancel") {
                            cancelOrder(order.id);
                          }

                          if (value == "price") {
                            showUpdatePriceDialog(order);
                          }
                        },
                        itemBuilder: (context) => [
                          const PopupMenuItem(
                            value: "cancel",
                            child: Text("Cancel Order"),
                          ),
                          const PopupMenuItem(
                            value: "price",
                            child: Text("Update Price"),
                          ),
                        ],
                      ),                  ],
                )
              ],
            ),
            const SizedBox(height: 10),

            _buildLocationRow(
                Icons.circle, kPrimaryColor, order.pickupLocation),

            Container(
              margin: const EdgeInsets.symmetric(vertical: 4),
              height: 20,
              width: 2,
              color: Colors.grey.shade300,
            ),

            _buildLocationRow(Icons.location_on,
                Colors.red.shade600, order.dropLocation),

            const SizedBox(height: 10),

            Row(
              children: [
                _buildInfoChip(
                    Icons.straighten, order.distance),
                const SizedBox(width: 8),
                _buildInfoChip(
                    Icons.access_time, order.time),
                const Spacer(),
                Text(
                  "TJS ${order.suggestedPrice}",
                  style: const TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.bold,
                      color: kPrimaryColor),
                ),
              ],
            ),

            const SizedBox(height: 16),

            if (widget.isDriverMode && order.status.toLowerCase() == "pending")
              Align(
                alignment: Alignment.centerRight,
                child: ElevatedButton(
                  onPressed: () {
                    sendInterest(order.id);
                  },
                  style: ElevatedButton.styleFrom(
                    backgroundColor: kPrimaryColor,
                    shape: RoundedRectangleBorder(
                        borderRadius:
                        BorderRadius.circular(8)),
                  ),
                  child: const Text("Accept Order",
                      style: TextStyle(fontSize: 12)),
                ),
              ),
          ],
        ),
      ),
    );
  }

  /// ================= REST SAME AS OLD =================

  Widget _buildFilterChip(String label, int count) {
    final isSelected = selectedFilter == label;

    return GestureDetector(
      onTap: () {
        setState(() => selectedFilter = label);
        fetchOrders();
      },
      child: Container(
        padding:
        const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
        decoration: BoxDecoration(
          color: isSelected
              ? kPrimaryColor
              : Colors.grey.shade100,
          borderRadius: BorderRadius.circular(16),
          border: Border.all(
              color: isSelected
                  ? kPrimaryColor
                  : Colors.grey.shade300),
        ),
        child: Row(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text(label,
                style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                    color: isSelected
                        ? Colors.white
                        : Colors.grey.shade700)),
            const SizedBox(width: 4),
            Text(count.toString(),
                style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.bold,
                    color: isSelected
                        ? Colors.white
                        : kPrimaryColor)),
          ],
        ),
      ),
    );
  }

  Widget _buildEmptyState() {
    return const Center(child: Text("No Orders"));
  }

  Future<void> sendInterest(int id) async {
    debugPrint("Accept order $id");
    debugPrint("Accept order $id");
  }

  void _showFilterSheet() {}
  Widget _buildInfoChip(IconData icon, String text) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 4),
      decoration: BoxDecoration(color: Colors.grey.shade100, borderRadius: BorderRadius.circular(6)),
      child: Row(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(icon, size: 12, color: Colors.grey.shade700),
          const SizedBox(width: 3),
          Text(text, style: TextStyle(fontSize: 10, fontWeight: FontWeight.w600, color: Colors.grey.shade700)),
        ],
      ),
    );
  }
  Widget _buildStatusBadge(String status) {
    Color color;
    Color bgColor;
    String label;

    switch (status.toLowerCase()) {
      case "pending":
        label = "Searching";
        color = Colors.orange.shade700;
        bgColor = Colors.orange.shade50;
        break;

      case "accepted":
        label = "Accepted";
        color = Colors.blue.shade700;
        bgColor = Colors.blue.shade50;
        break;

      case "in_transit":
        label = "In Transit";
        color = kPrimaryColor;
        bgColor = kPrimaryColor.withOpacity(0.1);
        break;

      case "completed":
        label = "Delivered";
        color = Colors.purple.shade700;
        bgColor = Colors.purple.shade50;
        break;

      case "cancelled":
        label = "Cancelled";
        color = Colors.red.shade700;
        bgColor = Colors.red.shade50;
        break;

      default:
        label = status;
        color = Colors.grey.shade700;
        bgColor = Colors.grey.shade100;
    }

    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
      decoration: BoxDecoration(
        color: bgColor,
        borderRadius: BorderRadius.circular(10),
      ),
      child: Text(
        label,
        style: TextStyle(
          fontSize: 10,
          fontWeight: FontWeight.bold,
          color: color,
        ),
      ),
    );
  }
  Widget _buildLocationRow(IconData icon, Color color, String address) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Icon(icon, color: color, size: 14),
        const SizedBox(width: 6),
        Expanded(
          child: Text(
            address,
            style: const TextStyle(fontSize: 12, height: 1.3),
            maxLines: 1,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ],
    );
  }
}