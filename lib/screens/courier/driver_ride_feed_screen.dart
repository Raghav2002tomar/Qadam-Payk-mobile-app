// // import 'dart:convert';
// // import 'package:flutter/material.dart';
// // import 'package:http/http.dart' as http;
// //
// // import '../../api_service/app_constocter.dart';
// // import '../../service/local_cache.dart';
// // import 'model/CourierModel.dart';
// // import 'driver_courier_detail_screen.dart';
// //
// // const Color kPrimaryColor = Color(0xFF008955);
// // const Color kPriceColor = Color(0xFFFF6B00);
// //
// // // ⚠️ Set your storage base URL here (trailing slash required)
// // const String kStorageBaseUrl = "https://qadampayk.com/assets/profile_image/";
// //
// // /// Filter model — keeps label, API type value, and UI status value in one place
// // class _Filter {
// //   final String label;   // shown in bottom sheet
// //   final String type;    // sent to API as ?type=  (empty = All)
// //   const _Filter(this.label, this.type);
// // }
// //
// // const List<_Filter> _filters = [
// //   _Filter("All", ""),
// //   _Filter("Pending", "pending"),
// //   _Filter("Accepted", "accepted"),
// //   _Filter("In Transit", "in_transit"),
// //   _Filter("Completed", "completed"),
// // ];
// //
// // class DriverRideFeedScreen extends StatefulWidget {
// //   const DriverRideFeedScreen({super.key});
// //
// //   @override
// //   State<DriverRideFeedScreen> createState() => _DriverRideFeedScreenState();
// // }
// //
// // class _DriverRideFeedScreenState extends State<DriverRideFeedScreen> {
// //   bool isLoading = false;
// //   List<CourierModel> orders = [];
// //
// //   /// Currently selected filter (matched by type string: "", "pending", etc.)
// //   _Filter _selectedFilter = _filters.first;
// //
// //   @override
// //   void initState() {
// //     super.initState();
// //     fetchOrders();
// //   }
// //
// //   Future<void> fetchOrders() async {
// //     setState(() => isLoading = true);
// //
// //     try {
// //       final token = await LocalCache.getToken();
// //
// //       if (token == null || token.isEmpty) {
// //         debugPrint("Token is null");
// //         setState(() {
// //           orders = [];
// //           isLoading = false;
// //         });
// //         return;
// //       }
// //
// //       final baseUrl = "${App_Constructor().BaseURL}/api/driver/couriers";
// //       // Only append ?type= when a specific filter is selected
// //       final url = _selectedFilter.type.isNotEmpty
// //           ? "$baseUrl?type=${_selectedFilter.type}"
// //           : baseUrl;
// //
// //       debugPrint("REQUEST URL: $url");
// //
// //       final response = await http.get(
// //         Uri.parse(url),
// //         headers: {
// //           "Authorization": "Bearer $token",
// //           "Accept": "application/json",
// //         },
// //       );
// //
// //       debugPrint("STATUS CODE: ${response.statusCode}");
// //       debugPrint("BODY: ${response.body}");
// //
// //       if (response.statusCode == 200) {
// //         final decoded = jsonDecode(response.body);
// //         if (decoded["status"] == true && decoded["data"] != null) {
// //           final List list = decoded["data"];
// //           setState(() {
// //             orders = list.map((e) => CourierModel.fromJson(e)).toList();
// //           });
// //         } else {
// //           setState(() => orders = []);
// //         }
// //       } else {
// //         setState(() => orders = []);
// //       }
// //     } catch (e) {
// //       debugPrint("FETCH ERROR: $e");
// //       setState(() => orders = []);
// //     }
// //
// //     setState(() => isLoading = false);
// //   }
// //
// //   @override
// //   Widget build(BuildContext context) {
// //     return Scaffold(
// //       backgroundColor: Colors.white,
// //       appBar: AppBar(
// //         elevation: 0,
// //         backgroundColor: Colors.white,
// //         title: const Text(
// //           "Ride Feed",
// //           style: TextStyle(
// //             color: Colors.black,
// //             fontWeight: FontWeight.bold,
// //             fontSize: 18,
// //           ),
// //         ),
// //         actions: [
// //           // Show active filter label next to icon so user knows what's applied
// //           if (_selectedFilter.type.isNotEmpty)
// //             Center(
// //               child: Container(
// //                 margin: const EdgeInsets.only(right: 4),
// //                 padding:
// //                 const EdgeInsets.symmetric(horizontal: 8, vertical: 3),
// //                 decoration: BoxDecoration(
// //                   color: kPrimaryColor.withOpacity(0.12),
// //                   borderRadius: BorderRadius.circular(12),
// //                 ),
// //                 child: Text(
// //                   _selectedFilter.label,
// //                   style: const TextStyle(
// //                     color: kPrimaryColor,
// //                     fontSize: 12,
// //                     fontWeight: FontWeight.w600,
// //                   ),
// //                 ),
// //               ),
// //             ),
// //           IconButton(
// //             icon: Icon(
// //               Icons.filter_alt,
// //               // Highlight icon when a filter is active
// //               color: _selectedFilter.type.isNotEmpty
// //                   ? kPrimaryColor
// //                   : Colors.black87,
// //             ),
// //             onPressed: _showFilterSheet,
// //           ),
// //         ],
// //       ),
// //       body: isLoading
// //           ? const Center(
// //           child: CircularProgressIndicator(color: kPrimaryColor))
// //           : orders.isEmpty
// //           ? _emptyState()
// //           : RefreshIndicator(
// //         color: kPrimaryColor,
// //         onRefresh: fetchOrders,
// //         child: Padding(
// //           padding: const EdgeInsets.only(bottom: 50),
// //           child: ListView.separated(
// //             padding: const EdgeInsets.symmetric(vertical: 8),
// //             itemCount: orders.length,
// //             separatorBuilder: (_, __) => const Divider(
// //               height: 1,
// //               thickness: 1,
// //               color: Color(0xFFF0F0F0),
// //               indent: 16,
// //               endIndent: 16,
// //             ),
// //             itemBuilder: (context, index) =>
// //                 _buildRideCard(orders[index]),
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _emptyState() {
// //     return Center(
// //       child: Column(
// //         mainAxisSize: MainAxisSize.min,
// //         children: [
// //           Icon(Icons.inbox_outlined, size: 54, color: Colors.grey.shade300),
// //           const SizedBox(height: 12),
// //           Text(
// //             _selectedFilter.type.isNotEmpty
// //                 ? "No \"${_selectedFilter.label}\" orders found"
// //                 : "No orders available",
// //             style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
// //           ),
// //           if (_selectedFilter.type.isNotEmpty) ...[
// //             const SizedBox(height: 8),
// //             TextButton(
// //               onPressed: () {
// //                 setState(() => _selectedFilter = _filters.first);
// //                 fetchOrders();
// //               },
// //               child: const Text("Clear filter",
// //                   style: TextStyle(color: kPrimaryColor)),
// //             ),
// //           ],
// //         ],
// //       ),
// //     );
// //   }
// //
// //   Widget _buildRideCard(CourierModel ride) {
// //     final imageUrl = ride.senderImageUrl(kStorageBaseUrl);
// //     final displayName = ride.senderFullName ?? ride.senderName;
// //
// //     return InkWell(
// //       onTap: () async {
// //         final result = await Navigator.push(
// //           context,
// //           MaterialPageRoute(
// //             builder: (_) => DriverCourierDetailScreen(ride: ride),
// //           ),
// //         );
// //         // Refresh list if driver accepted
// //         if (result == true) fetchOrders();
// //       },
// //       splashColor: kPrimaryColor.withOpacity(0.05),
// //       child: Padding(
// //         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
// //         child: Row(
// //           crossAxisAlignment: CrossAxisAlignment.start,
// //           children: [
// //             // ── LEFT: Avatar + Name + Time ──
// //             SizedBox(
// //               width: 68,
// //               child: Column(
// //                 children: [
// //                   CircleAvatar(
// //                     radius: 26,
// //                     backgroundColor: kPrimaryColor.withOpacity(0.15),
// //                     backgroundImage:
// //                     imageUrl != null ? NetworkImage(imageUrl) : null,
// //                     child: imageUrl == null
// //                         ? Text(
// //                       displayName.isNotEmpty
// //                           ? displayName[0].toUpperCase()
// //                           : "?",
// //                       style: TextStyle(
// //                         fontSize: 20,
// //                         fontWeight: FontWeight.bold,
// //                         color: kPrimaryColor,
// //                       ),
// //                     )
// //                         : null,
// //                   ),
// //                   const SizedBox(height: 5),
// //                   Text(
// //                     displayName,
// //                     style: const TextStyle(
// //                       fontSize: 11,
// //                       fontWeight: FontWeight.w600,
// //                       color: Colors.black87,
// //                     ),
// //                     textAlign: TextAlign.center,
// //                     maxLines: 2,
// //                     overflow: TextOverflow.ellipsis,
// //                   ),
// //                   const SizedBox(height: 2),
// //                   Text(
// //                     ride.timeAgo,
// //                     style:
// //                     TextStyle(fontSize: 10, color: Colors.grey.shade500),
// //                     textAlign: TextAlign.center,
// //                   ),
// //                 ],
// //               ),
// //             ),
// //
// //             const SizedBox(width: 12),
// //
// //             // ── RIGHT: Pickup / Drop / Price ──
// //             Expanded(
// //               child: Column(
// //                 crossAxisAlignment: CrossAxisAlignment.start,
// //                 children: [
// //                   Text(
// //                     ride.pickupLocation,
// //                     style: const TextStyle(
// //                       fontSize: 14,
// //                       fontWeight: FontWeight.w700,
// //                       color: Colors.black,
// //                       height: 1.3,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 3),
// //                   Text(
// //                     ride.dropLocation,
// //                     style: TextStyle(
// //                       fontSize: 13,
// //                       color: Colors.grey.shade600,
// //                       height: 1.3,
// //                     ),
// //                   ),
// //                   const SizedBox(height: 8),
// //                   Wrap(
// //                     spacing: 8,
// //                     runSpacing: 4,
// //                     crossAxisAlignment: WrapCrossAlignment.center,
// //                     children: [
// //                       Text(
// //                         "₹${ride.suggestedPrice}",
// //                         style: const TextStyle(
// //                           fontSize: 14,
// //                           fontWeight: FontWeight.w700,
// //                           color: kPriceColor,
// //                         ),
// //                       ),
// //                       Text(
// //                         "~${ride.distance}",
// //                         style: TextStyle(
// //                             fontSize: 13, color: Colors.grey.shade600),
// //                       ),
// //                       if (ride.paymentMethod.isNotEmpty)
// //                         _badge(
// //                           ride.paymentMethod.toUpperCase(),
// //                           ride.paymentMethod.toLowerCase() == "cash"
// //                               ? const Color(0xFF2E7D32)
// //                               : Colors.red,
// //                         ),
// //                       _badge(ride.tripType, Colors.blueGrey.shade400),
// //                       if (ride.status == "Accepted")
// //                         _badge("READY TO START", Colors.orange),
// //
// //                       if (ride.status == "In Transit")
// //                         _badge("STARTED", Colors.green),
// //
// //                       if (ride.status == "Delivered")
// //                         _badge("COMPLETED", Colors.green),
// //
// //                     ],
// //                   ),
// //                   if (ride.packageDescription.isNotEmpty) ...[
// //                     const SizedBox(height: 5),
// //                     Text(
// //                       ride.packageDescription,
// //                       style: TextStyle(
// //                         fontSize: 12,
// //                         color: Colors.grey.shade500,
// //                         height: 1.4,
// //                       ),
// //                       maxLines: 2,
// //                       overflow: TextOverflow.ellipsis,
// //                     ),
// //                   ],
// //                 ],
// //               ),
// //             ),
// //
// //             const SizedBox(width: 4),
// //             Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
// //           ],
// //         ),
// //       ),
// //     );
// //   }
// //
// //   Widget _badge(String label, Color color) {
// //     return Container(
// //       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
// //       decoration: BoxDecoration(
// //         color: color,
// //         borderRadius: BorderRadius.circular(4),
// //       ),
// //       child: Text(
// //         label,
// //         style: const TextStyle(
// //           color: Colors.white,
// //           fontSize: 10,
// //           fontWeight: FontWeight.w700,
// //           letterSpacing: 0.3,
// //         ),
// //       ),
// //     );
// //   }
// //
// //   // Navigation handled in _buildRideCard onTap
// //
// //   void _showFilterSheet() {
// //     showModalBottomSheet(
// //       context: context,
// //       shape: const RoundedRectangleBorder(
// //         borderRadius: BorderRadius.vertical(top: Radius.circular(16)),
// //       ),
// //       builder: (ctx) => StatefulBuilder(
// //         builder: (ctx, setSheetState) => Padding(
// //           padding: const EdgeInsets.fromLTRB(16, 12, 16, 24),
// //           child: Column(
// //             mainAxisSize: MainAxisSize.min,
// //             children: [
// //               // Handle bar
// //               Container(
// //                 width: 40,
// //                 height: 4,
// //                 margin: const EdgeInsets.only(bottom: 16),
// //                 decoration: BoxDecoration(
// //                   color: Colors.grey.shade300,
// //                   borderRadius: BorderRadius.circular(2),
// //                 ),
// //               ),
// //               const Align(
// //                 alignment: Alignment.centerLeft,
// //                 child: Text(
// //                   "Filter by status",
// //                   style: TextStyle(
// //                     fontWeight: FontWeight.bold,
// //                     fontSize: 15,
// //                   ),
// //                 ),
// //               ),
// //               const SizedBox(height: 8),
// //               ..._filters.map((f) => ListTile(
// //                 contentPadding: EdgeInsets.zero,
// //                 title: Text(f.label),
// //                 trailing: _selectedFilter.type == f.type
// //                     ? const Icon(Icons.check_circle,
// //                     color: kPrimaryColor)
// //                     : const Icon(Icons.radio_button_unchecked,
// //                     color: Colors.grey),
// //                 onTap: () {
// //                   setState(() => _selectedFilter = f);
// //                   Navigator.pop(context);
// //                   fetchOrders(); // re-fetch with new ?type= param
// //                 },
// //               )),
// //             ],
// //           ),
// //         ),
// //       ),
// //     );
// //   }
// // }
//
//
// import 'dart:convert';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
//
// import '../../api_service/app_constocter.dart';
// import '../../service/local_cache.dart';
// import 'model/CourierModel.dart';
// import 'driver_courier_detail_screen.dart';
//
// const Color kPrimaryColor = Color(0xFF008955);
// const Color kPriceColor = Color(0xFFFF6B00);
//
// // ⚠️ Set your storage base URL here (trailing slash required)
// const String kStorageBaseUrl = "https://qadampayk.com/assets/profile_image/";
//
// /// Filter model — keeps label, API type value, and UI status value in one place
// class _Filter {
//   final String label;   // shown in filter chips
//   final String type;    // sent to API as ?type=
//   const _Filter(this.label, this.type);
// }
//
// const List<_Filter> _filters = [
//   _Filter("Pending", "pending"),    // Default filter
//   _Filter("Accepted", "accepted"),
//   _Filter("In Transit", "in_transit"),
//   _Filter("Completed", "completed"),
// ];
//
// class DriverRideFeedScreen extends StatefulWidget {
//   const DriverRideFeedScreen({super.key});
//
//   @override
//   State<DriverRideFeedScreen> createState() => _DriverRideFeedScreenState();
// }
//
// class _DriverRideFeedScreenState extends State<DriverRideFeedScreen> {
//   bool isLoading = false;
//   List<CourierModel> orders = [];
//
//   /// Currently selected filter - default to "pending"
//   _Filter _selectedFilter = _filters.first; // Now defaults to "Pending"
//
//   @override
//   void initState() {
//     super.initState();
//     fetchOrders();
//   }
//
//   Future<void> fetchOrders() async {
//     setState(() => isLoading = true);
//
//     try {
//       final token = await LocalCache.getToken();
//
//       if (token == null || token.isEmpty) {
//         debugPrint("Token is null");
//         setState(() {
//           orders = [];
//           isLoading = false;
//         });
//         return;
//       }
//
//       final baseUrl = "${App_Constructor().BaseURL}/api/driver/couriers";
//       // Always append ?type= since we always have a selected filter
//       final url = "$baseUrl?type=${_selectedFilter.type}";
//
//       debugPrint("REQUEST URL: $url");
//
//       final response = await http.get(
//         Uri.parse(url),
//         headers: {
//           "Authorization": "Bearer $token",
//           "Accept": "application/json",
//         },
//       );
//
//       debugPrint("STATUS CODE: ${response.statusCode}");
//       debugPrint("BODY: ${response.body}");
//
//       if (response.statusCode == 200) {
//         final decoded = jsonDecode(response.body);
//         if (decoded["status"] == true && decoded["data"] != null) {
//           final List list = decoded["data"];
//           setState(() {
//             orders = list.map((e) => CourierModel.fromJson(e)).toList();
//           });
//         } else {
//           setState(() => orders = []);
//         }
//       } else {
//         setState(() => orders = []);
//       }
//     } catch (e) {
//       debugPrint("FETCH ERROR: $e");
//       setState(() => orders = []);
//     }
//
//     setState(() => isLoading = false);
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return Scaffold(
//       backgroundColor: Colors.white,
//       appBar: AppBar(
//         elevation: 0,
//         backgroundColor: Colors.white,
//         title: const Text(
//           "Ride Feed",
//           style: TextStyle(
//             color: Colors.black,
//             fontWeight: FontWeight.bold,
//             fontSize: 18,
//           ),
//         ),
//         // Removed filter icon from actions
//       ),
//       body: Column(
//         children: [
//           // Horizontal filter chips
//           Container(
//             height: 50,
//             padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
//             child: ListView.separated(
//               scrollDirection: Axis.horizontal,
//               itemCount: _filters.length,
//               separatorBuilder: (_, __) => const SizedBox(width: 8),
//               itemBuilder: (context, index) {
//                 final filter = _filters[index];
//                 final isSelected = _selectedFilter.type == filter.type;
//
//                 return FilterChip(
//                   label: Text(filter.label),
//                   selected: isSelected,
//                   onSelected: (selected) {
//                     if (selected) {
//                       setState(() {
//                         _selectedFilter = filter;
//                       });
//                       fetchOrders(); // Re-fetch with new filter
//                     }
//                   },
//                   backgroundColor: Colors.grey.shade100,
//                   selectedColor: kPrimaryColor,
//                   checkmarkColor: Colors.white,
//                   labelStyle: TextStyle(
//                     color: isSelected ? Colors.white : Colors.black87,
//                     fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
//                   ),
//                   padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
//                   shape: RoundedRectangleBorder(
//                     borderRadius: BorderRadius.circular(20),
//                     side: BorderSide(
//                       color: isSelected ? kPrimaryColor : Colors.grey.shade300,
//                       width: 1,
//                     ),
//                   ),
//                 );
//               },
//             ),
//           ),
//
//           // Content
//           Expanded(
//             child: isLoading
//                 ? const Center(
//                 child: CircularProgressIndicator(color: kPrimaryColor))
//                 : orders.isEmpty
//                 ? _emptyState()
//                 : RefreshIndicator(
//               color: kPrimaryColor,
//               onRefresh: fetchOrders,
//               child: Padding(
//                 padding: const EdgeInsets.only(bottom: 50),
//                 child: ListView.separated(
//                   padding: const EdgeInsets.symmetric(vertical: 8),
//                   itemCount: orders.length,
//                   separatorBuilder: (_, __) => const Divider(
//                     height: 1,
//                     thickness: 1,
//                     color: Color(0xFFF0F0F0),
//                     indent: 16,
//                     endIndent: 16,
//                   ),
//                   itemBuilder: (context, index) =>
//                       _buildRideCard(orders[index]),
//                 ),
//               ),
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _emptyState() {
//     return Center(
//       child: Column(
//         mainAxisSize: MainAxisSize.min,
//         children: [
//           Icon(Icons.inbox_outlined, size: 54, color: Colors.grey.shade300),
//           const SizedBox(height: 12),
//           Text(
//             "No \"${_selectedFilter.label}\" orders found",
//             style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
//           ),
//           if (_selectedFilter.type != "pending") ...[
//             const SizedBox(height: 8),
//             TextButton(
//               onPressed: () {
//                 setState(() => _selectedFilter = _filters.first);
//                 fetchOrders();
//               },
//               child: const Text("Show pending orders",
//                   style: TextStyle(color: kPrimaryColor)),
//             ),
//           ],
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRideCard(CourierModel ride) {
//     final imageUrl = ride.senderImageUrl(kStorageBaseUrl);
//     final displayName = ride.senderFullName ?? ride.senderName;
//
//     return InkWell(
//       // In your DriverRideFeedScreen or wherever you navigate from:
//       onTap: () async {
//         final result = await Navigator.push(
//           context,
//           MaterialPageRoute(
//             builder: (_) => DriverCourierDetailScreen(
//               courierId: ride.id.toString(), // Pass only the ID
//             ),
//           ),
//         );
//         if (result == true) fetchOrders();
//       },
//       splashColor: kPrimaryColor.withOpacity(0.05),
//       child: Padding(
//         padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
//         child: Row(
//           crossAxisAlignment: CrossAxisAlignment.start,
//           children: [
//             // ── LEFT: Avatar + Name + Time ──
//             SizedBox(
//               width: 68,
//               child: Column(
//                 children: [
//                   CircleAvatar(
//                     radius: 26,
//                     backgroundColor: kPrimaryColor.withOpacity(0.15),
//                     backgroundImage:
//                     imageUrl != null ? NetworkImage(imageUrl) : null,
//                     child: imageUrl == null
//                         ? Text(
//                       displayName.isNotEmpty
//                           ? displayName[0].toUpperCase()
//                           : "?",
//                       style: TextStyle(
//                         fontSize: 20,
//                         fontWeight: FontWeight.bold,
//                         color: kPrimaryColor,
//                       ),
//                     )
//                         : null,
//                   ),
//                   const SizedBox(height: 5),
//                   Text(
//                     displayName,
//                     style: const TextStyle(
//                       fontSize: 11,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black87,
//                     ),
//                     textAlign: TextAlign.center,
//                     maxLines: 2,
//                     overflow: TextOverflow.ellipsis,
//                   ),
//                   const SizedBox(height: 2),
//                   Text(
//                     ride.timeAgo,
//                     style:
//                     TextStyle(fontSize: 10, color: Colors.grey.shade500),
//                     textAlign: TextAlign.center,
//                   ),
//                 ],
//               ),
//             ),
//
//             const SizedBox(width: 12),
//
//             // ── RIGHT: Pickup / Drop / Price ──
//             Expanded(
//               child: Column(
//                 crossAxisAlignment: CrossAxisAlignment.start,
//                 children: [
//                   Text(
//                     ride.pickupLocation,
//                     style: const TextStyle(
//                       fontSize: 14,
//                       fontWeight: FontWeight.w700,
//                       color: Colors.black,
//                       height: 1.3,
//                     ),
//                   ),
//                   const SizedBox(height: 3),
//                   Text(
//                     ride.dropLocation,
//                     style: TextStyle(
//                       fontSize: 13,
//                       color: Colors.grey.shade600,
//                       height: 1.3,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Wrap(
//                     spacing: 8,
//                     runSpacing: 4,
//                     crossAxisAlignment: WrapCrossAlignment.center,
//                     children: [
//                       Text(
//                         "TJS ${ride.suggestedPrice}",
//                         style: const TextStyle(
//                           fontSize: 14,
//                           fontWeight: FontWeight.w700,
//                           color: kPriceColor,
//                         ),
//                       ),
//                       Text(
//                         "~${ride.distance}",
//                         style: TextStyle(
//                             fontSize: 13, color: Colors.grey.shade600),
//                       ),
//                       if (ride.paymentMethod.isNotEmpty)
//                         _badge(
//                           ride.paymentMethod.toUpperCase(),
//                           ride.paymentMethod.toLowerCase() == "cash"
//                               ? const Color(0xFF2E7D32)
//                               : Colors.red,
//                         ),
//                       _badge(ride.tripType, Colors.blueGrey.shade400),
//                       if (ride.status == "Accepted")
//                         _badge("READY TO START", Colors.orange),
//                       if (ride.status == "In Transit")
//                         _badge("STARTED", Colors.green),
//                       if (ride.status == "Delivered")
//                         _badge("COMPLETED", Colors.green),
//                     ],
//                   ),
//                   if (ride.packageDescription.isNotEmpty) ...[
//                     const SizedBox(height: 5),
//                     Text(
//                       ride.packageDescription,
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey.shade500,
//                         height: 1.4,
//                       ),
//                       maxLines: 2,
//                       overflow: TextOverflow.ellipsis,
//                     ),
//                   ],
//                 ],
//               ),
//             ),
//
//             const SizedBox(width: 4),
//             Icon(Icons.more_vert, color: Colors.grey.shade400, size: 20),
//           ],
//         ),
//       ),
//     );
//   }
//
//   Widget _badge(String label, Color color) {
//     return Container(
//       padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
//       decoration: BoxDecoration(
//         color: color,
//         borderRadius: BorderRadius.circular(4),
//       ),
//       child: Text(
//         label,
//         style: const TextStyle(
//           color: Colors.white,
//           fontSize: 10,
//           fontWeight: FontWeight.w700,
//           letterSpacing: 0.3,
//         ),
//       ),
//     );
//   }
// }

import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;

import '../../api_service/app_constocter.dart';
import '../../service/local_cache.dart';
import 'model/CourierModel.dart';
import 'driver_courier_detail_screen.dart';

const Color kPrimaryColor = Color(0xFF008955);
const Color kPriceColor = Color(0xFFFF6B00);

// ⚠️ Set your storage base URL here (trailing slash required)
const String kStorageBaseUrl = "https://qadampayk.com/assets/profile_image/";

// Filter options for My Orders tab
enum MyOrderFilter {
  all("All", ""),
  accepted("Accepted", "accepted"),
  inTransit("In Transit", "in_transit"),
  completed("Completed", "completed");

  final String label;
  final String type;

  const MyOrderFilter(this.label, this.type);
}

class DriverRideFeedScreen extends StatefulWidget {
  const DriverRideFeedScreen({super.key});

  @override
  State<DriverRideFeedScreen> createState() => _DriverRideFeedScreenState();
}

class _DriverRideFeedScreenState extends State<DriverRideFeedScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  bool isLoadingSearching = false;
  bool isLoadingMyOrders = false;

  List<CourierModel> searchingOrders = []; // Only Pending orders
  List<CourierModel> allMyOrders = []; // All accepted, in transit, completed
  List<CourierModel> filteredMyOrders = []; // Filtered based on selected filter

  // Filter for My Orders tab
  MyOrderFilter _selectedMyOrderFilter = MyOrderFilter.all;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    _tabController.addListener(_handleTabSelection);

    // Load initial data for both tabs
    fetchSearchingOrders();
    fetchMyOrders();
  }

  @override
  void dispose() {
    _tabController.removeListener(_handleTabSelection);
    _tabController.dispose();
    super.dispose();
  }

  void _handleTabSelection() {
    if (_tabController.indexIsChanging) {
      // Refresh data when switching tabs if needed
      if (_tabController.index == 0 && searchingOrders.isEmpty) {
        fetchSearchingOrders();
      } else if (_tabController.index == 1 && allMyOrders.isEmpty) {
        fetchMyOrders();
      }
    }
  }

  // Apply filter to my orders
  void _applyMyOrderFilter() {
    if (_selectedMyOrderFilter == MyOrderFilter.all) {
      setState(() {
        filteredMyOrders = List.from(allMyOrders);
      });
    } else {
      setState(() {
        filteredMyOrders = allMyOrders.where((order) {
          final orderStatus = order.status.toLowerCase();
          final filterType = _selectedMyOrderFilter.type.toLowerCase();

          // Handle different status formats
          if (filterType == 'completed') {
            return orderStatus == 'delivered' ||
                orderStatus == 'completed';
          } else if (filterType == 'in_transit') {
            return orderStatus == 'in transit' ||
                orderStatus == 'in_transit';
          } else {
            return orderStatus == filterType;
          }
        }).toList();
      });
    }
  }

  // Fetch ONLY pending orders for "Searching for Order" tab
  Future<void> fetchSearchingOrders() async {
    setState(() => isLoadingSearching = true);

    try {
      final token = await LocalCache.getToken();

      if (token == null || token.isEmpty) {
        debugPrint("Token is null");
        setState(() {
          searchingOrders = [];
          isLoadingSearching = false;
        });
        return;
      }

      final url = "${App_Constructor().BaseURL}/api/driver/couriers?type=pending";

      debugPrint("SEARCHING ORDERS URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded["status"] == true && decoded["data"] != null) {
          final List list = decoded["data"];

          // Additional client-side filter to ensure only pending orders
          final pendingOrders = list.where((item) {
            final status = item['status']?.toString().toLowerCase() ?? '';
            return status == 'pending';
          }).toList();

          setState(() {
            searchingOrders = pendingOrders.map((e) => CourierModel.fromJson(e)).toList();
          });

          debugPrint("Filtered Pending Orders Count: ${searchingOrders.length}");
        } else {
          setState(() => searchingOrders = []);
        }
      } else {
        setState(() => searchingOrders = []);
      }
    } catch (e) {
      debugPrint("FETCH SEARCHING ORDERS ERROR: $e");
      setState(() => searchingOrders = []);
    }

    setState(() => isLoadingSearching = false);
  }

  // Fetch accepted, in transit, completed orders for "My Order" tab
  Future<void> fetchMyOrders() async {
    setState(() => isLoadingMyOrders = true);

    try {
      final token = await LocalCache.getToken();

      if (token == null || token.isEmpty) {
        debugPrint("Token is null");
        setState(() {
          allMyOrders = [];
          filteredMyOrders = [];
          isLoadingMyOrders = false;
        });
        return;
      }

      // Fetch all three status types
      final List<CourierModel> tempOrders = [];

      // Fetch accepted
      await _fetchOrdersByType("accepted", tempOrders);
      // Fetch in_transit
      await _fetchOrdersByType("in_transit", tempOrders);
      // Fetch completed
      await _fetchOrdersByType("completed", tempOrders);

      // Remove any duplicates
      final uniqueOrders = <int, CourierModel>{};
      for (var order in tempOrders) {
        uniqueOrders[order.id] = order;
      }

      // Sort by date (newest first)
      final sortedOrders = uniqueOrders.values.toList()
        ..sort((a, b) => b.id.compareTo(a.id));

      setState(() {
        allMyOrders = sortedOrders;
        // Apply current filter
        _applyMyOrderFilter();
      });

      debugPrint("Total My Orders Count: ${allMyOrders.length}");

    } catch (e) {
      debugPrint("FETCH MY ORDERS ERROR: $e");
      setState(() {
        allMyOrders = [];
        filteredMyOrders = [];
      });
    }

    setState(() => isLoadingMyOrders = false);
  }

  Future<void> _fetchOrdersByType(String type, List<CourierModel> collection) async {
    try {
      final token = await LocalCache.getToken();
      if (token == null) return;

      final url = "${App_Constructor().BaseURL}/api/driver/couriers?type=$type";

      debugPrint("FETCHING $type URL: $url");

      final response = await http.get(
        Uri.parse(url),
        headers: {
          "Authorization": "Bearer $token",
          "Accept": "application/json",
        },
      );

      if (response.statusCode == 200) {
        final decoded = jsonDecode(response.body);
        if (decoded["status"] == true && decoded["data"] != null) {
          final List list = decoded["data"];

          // Filter to ensure correct status
          final filteredList = list.where((item) {
            final status = item['status']?.toString().toLowerCase() ?? '';
            if (type == 'completed') {
              return status == 'delivered' || status == 'completed';
            } else if (type == 'in_transit') {
              return status == 'in transit' || status == 'in_transit';
            } else {
              return status == type.toLowerCase();
            }
          }).toList();

          collection.addAll(filteredList.map((e) => CourierModel.fromJson(e)).toList());

          debugPrint("$type Orders Count: ${filteredList.length}");
        }
      }
    } catch (e) {
      debugPrint("FETCH $type ORDERS ERROR: $e");
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        elevation: 0,
        backgroundColor: Colors.white,
        title: const Text(
          "Ride Feed",
          style: TextStyle(
            color: Colors.black,
            fontWeight: FontWeight.bold,
            fontSize: 18,
          ),
        ),
        bottom: TabBar(
          controller: _tabController,
          labelColor: kPrimaryColor,
          unselectedLabelColor: Colors.grey,
          indicatorColor: kPrimaryColor,
          indicatorWeight: 3,
          tabs: const [
            Tab(text: "Searching for Order"),
            Tab(text: "My Order"),
          ],
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          // Searching for Order Tab (Only Pending)
          _buildSearchingOrdersTab(),

          // My Order Tab with Filters
          _buildMyOrdersTab(),
        ],
      ),
    );
  }

  Widget _buildSearchingOrdersTab() {
    return RefreshIndicator(
      color: kPrimaryColor,
      onRefresh: fetchSearchingOrders,
      child: isLoadingSearching
          ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
          : searchingOrders.isEmpty
          ? _buildEmptyState("No pending orders available", "pending")
          : Padding(
        padding: const EdgeInsets.only(bottom: 50),
        child: ListView.separated(
          padding: const EdgeInsets.symmetric(vertical: 8),
          itemCount: searchingOrders.length,
          separatorBuilder: (_, __) => const Divider(
            height: 1,
            thickness: 1,
            color: Color(0xFFF0F0F0),
            indent: 16,
            endIndent: 16,
          ),
          itemBuilder: (context, index) =>
              _buildRideCard(searchingOrders[index], isSearchingTab: true),
        ),
      ),
    );
  }

  Widget _buildMyOrdersTab() {
    return Column(
      children: [
        // Filter Chips for My Orders
        Container(
          height: 50,
          padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 8),
          child: ListView.separated(
            scrollDirection: Axis.horizontal,
            itemCount: MyOrderFilter.values.length,
            separatorBuilder: (_, __) => const SizedBox(width: 8),
            itemBuilder: (context, index) {
              final filter = MyOrderFilter.values[index];
              final isSelected = _selectedMyOrderFilter == filter;

              return FilterChip(
                label: Text(filter.label),
                selected: isSelected,
                onSelected: (selected) {
                  if (selected) {
                    setState(() {
                      _selectedMyOrderFilter = filter;
                    });
                    _applyMyOrderFilter();
                  }
                },
                backgroundColor: Colors.grey.shade100,
                selectedColor: kPrimaryColor,
                checkmarkColor: Colors.white,
                labelStyle: TextStyle(
                  color: isSelected ? Colors.white : Colors.black87,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.normal,
                ),
                padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                  side: BorderSide(
                    color: isSelected ? kPrimaryColor : Colors.grey.shade300,
                    width: 1,
                  ),
                ),
              );
            },
          ),
        ),

        // Orders List
        Expanded(
          child: RefreshIndicator(
            color: kPrimaryColor,
            onRefresh: fetchMyOrders,
            child: isLoadingMyOrders
                ? const Center(child: CircularProgressIndicator(color: kPrimaryColor))
                : filteredMyOrders.isEmpty
                ? _buildMyOrdersEmptyState()
                : Padding(
              padding: const EdgeInsets.only(bottom: 50),
              child: ListView.separated(
                padding: const EdgeInsets.symmetric(vertical: 8),
                itemCount: filteredMyOrders.length,
                separatorBuilder: (_, __) => const Divider(
                  height: 1,
                  thickness: 1,
                  color: Color(0xFFF0F0F0),
                  indent: 16,
                  endIndent: 16,
                ),
                itemBuilder: (context, index) =>
                    _buildRideCard(filteredMyOrders[index], isSearchingTab: false),
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildMyOrdersEmptyState() {
    String message = "No ${_selectedMyOrderFilter.label.toLowerCase()} orders found";
    if (_selectedMyOrderFilter == MyOrderFilter.all) {
      message = "No active orders found";
    }

    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 54, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
          if (_selectedMyOrderFilter != MyOrderFilter.all) ...[
            const SizedBox(height: 8),
            TextButton(
              onPressed: () {
                setState(() {
                  _selectedMyOrderFilter = MyOrderFilter.all;
                });
                _applyMyOrderFilter();
              },
              child: const Text("Show all orders",
                  style: TextStyle(color: kPrimaryColor)),
            ),
          ],
        ],
      ),
    );
  }

  Widget _buildEmptyState(String message, String type) {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.inbox_outlined, size: 54, color: Colors.grey.shade300),
          const SizedBox(height: 12),
          Text(
            message,
            style: TextStyle(color: Colors.grey.shade500, fontSize: 14),
          ),
        ],
      ),
    );
  }

  Widget _buildRideCard(CourierModel ride, {required bool isSearchingTab}) {
    final imageUrl = ride.senderImageUrl(kStorageBaseUrl);
    final displayName = ride.senderFullName ?? ride.senderName;

    return InkWell(
      onTap: () async {
        final result = await Navigator.push(
          context,
          MaterialPageRoute(
            builder: (_) => DriverCourierDetailScreen(
              courierId: ride.id.toString(),
            ),
          ),
        );
        // Refresh appropriate list based on result and current tab
        if (result == true) {
          if (_tabController.index == 0) {
            await fetchSearchingOrders();
          } else {
            await fetchMyOrders();
          }
        }
      },
      splashColor: kPrimaryColor.withOpacity(0.05),
      child: Padding(
        padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        child: Row(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            // LEFT: Avatar + Name + Time
            SizedBox(
              width: 68,
              child: Column(
                children: [
                  CircleAvatar(
                    radius: 26,
                    backgroundColor: kPrimaryColor.withOpacity(0.15),
                    backgroundImage:
                    imageUrl != null ? NetworkImage(imageUrl) : null,
                    child: imageUrl == null
                        ? Text(
                      displayName.isNotEmpty
                          ? displayName[0].toUpperCase()
                          : "?",
                      style: TextStyle(
                        fontSize: 20,
                        fontWeight: FontWeight.bold,
                        color: kPrimaryColor,
                      ),
                    )
                        : null,
                  ),
                  const SizedBox(height: 5),
                  Text(
                    displayName,
                    style: const TextStyle(
                      fontSize: 11,
                      fontWeight: FontWeight.w600,
                      color: Colors.black87,
                    ),
                    textAlign: TextAlign.center,
                    maxLines: 2,
                    overflow: TextOverflow.ellipsis,
                  ),
                  const SizedBox(height: 2),
                  Text(
                    ride.timeAgo,
                    style:
                    TextStyle(fontSize: 10, color: Colors.grey.shade500),
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),

            const SizedBox(width: 12),

            // RIGHT: Pickup / Drop / Price
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    ride.pickupLocation,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w700,
                      color: Colors.black,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 3),
                  Text(
                    ride.dropLocation,
                    style: TextStyle(
                      fontSize: 13,
                      color: Colors.grey.shade600,
                      height: 1.3,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Wrap(
                    spacing: 8,
                    runSpacing: 4,
                    crossAxisAlignment: WrapCrossAlignment.center,
                    children: [
                      Text(
                        "TJS ${ride.suggestedPrice}",
                        style: const TextStyle(
                          fontSize: 14,
                          fontWeight: FontWeight.w700,
                          color: kPriceColor,
                        ),
                      ),
                      Text(
                        "~${ride.distance}",
                        style: TextStyle(
                            fontSize: 13, color: Colors.grey.shade600),
                      ),
                      if (ride.paymentMethod.isNotEmpty)
                        _badge(
                          ride.paymentMethod.toUpperCase(),
                          ride.paymentMethod.toLowerCase() == "cash"
                              ? const Color(0xFF2E7D32)
                              : Colors.red,
                        ),
                      _badge(ride.tripType, Colors.blueGrey.shade400),

                      // Status badges
                      if (ride.status.toLowerCase() == "pending")
                        _badge("PENDING", Colors.orange),
                      if (ride.status.toLowerCase() == "accepted")
                        _badge("ACCEPTED", Colors.blue),
                      if (ride.status.toLowerCase() == "in transit" ||
                          ride.status.toLowerCase() == "in_transit")
                        _badge("IN TRANSIT", Colors.green),
                      if (ride.status.toLowerCase() == "delivered" ||
                          ride.status.toLowerCase() == "completed")
                        _badge("COMPLETED", Colors.grey.shade700),
                    ],
                  ),
                  if (ride.packageDescription.isNotEmpty) ...[
                    const SizedBox(height: 5),
                    Text(
                      ride.packageDescription,
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade500,
                        height: 1.4,
                      ),
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                  ],
                ],
              ),
            ),

            const SizedBox(width: 4),
            Icon(Icons.chevron_right, color: Colors.grey.shade400, size: 20),
          ],
        ),
      ),
    );
  }

  Widget _badge(String label, Color color) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 2),
      decoration: BoxDecoration(
        color: color,
        borderRadius: BorderRadius.circular(4),
      ),
      child: Text(
        label,
        style: const TextStyle(
          color: Colors.white,
          fontSize: 10,
          fontWeight: FontWeight.w700,
          letterSpacing: 0.3,
        ),
      ),
    );
  }
}