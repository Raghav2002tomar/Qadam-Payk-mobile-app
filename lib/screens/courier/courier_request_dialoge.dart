//
//
// import 'dart:async';
// import 'dart:convert';
// import 'package:audioplayers/audioplayers.dart';
// import 'package:flutter/material.dart';
// import 'package:http/http.dart' as http;
// import '../../api_service/app_constocter.dart';
// import '../../main.dart';
// import '../../notification_handler.dart';
// import '../../service/colors.dart';
// import '../../service/local_cache.dart';
// import 'driver_courier_detail_screen.dart';
// import 'order_detail_screen.dart';
//
// // ==================== USER SIDE DIALOG (Driver Interest) ====================
//
// class UserDriverInterestDialog extends StatefulWidget {
//   final ValueNotifier<List<DriverInterest>> queueNotifier;
//
//   const UserDriverInterestDialog({
//     super.key,
//     required this.queueNotifier,
//   });
//
//   @override
//   State<UserDriverInterestDialog> createState() => _UserDriverInterestDialogState();
// }
//
// class _UserDriverInterestDialogState extends State<UserDriverInterestDialog> {
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   int _previousCount = 0;
//
//   static const primaryColor = Color(0xFF00A651);
//
//   @override
//   void initState() {
//     super.initState();
//     _previousCount = widget.queueNotifier.value.length;
//     widget.queueNotifier.addListener(_onQueueChanged);
//     if (_previousCount > 0) _playSound();
//   }
//
//   void _onQueueChanged() {
//     final newCount = widget.queueNotifier.value.length;
//     if (newCount > _previousCount) {
//       _playSound();
//     }
//     _previousCount = newCount;
//   }
//
//   Future<void> _playSound() async {
//     try {
//       await _audioPlayer.stop();
//       await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
//     } catch (_) {}
//   }
//
//   @override
//   void dispose() {
//     widget.queueNotifier.removeListener(_onQueueChanged);
//     _audioPlayer.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Align(
//         alignment: Alignment.topCenter,
//         child: Padding(
//           padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
//           child: Material(
//             color: Colors.transparent,
//             child: ValueListenableBuilder<List<DriverInterest>>(
//               valueListenable: widget.queueNotifier,
//               builder: (context, queue, _) {
//                 if (queue.isEmpty) return const SizedBox.shrink();
//
//                 return ConstrainedBox(
//                   constraints: BoxConstraints(
//                     maxHeight: MediaQuery.of(context).size.height * 0.78,
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       if (queue.length > 1)
//                         Container(
//                           margin: const EdgeInsets.only(bottom: 6),
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 14, vertical: 6),
//                           decoration: BoxDecoration(
//                             color: Colors.amber,
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Text(
//                             "${queue.length} Drivers Interested",
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 13,
//                               color: Colors.black87,
//                             ),
//                           ),
//                         ),
//
//                       Flexible(
//                         child: ListView.builder(
//                           shrinkWrap: true,
//                           padding: EdgeInsets.zero,
//                           itemCount: queue.length,
//                           itemBuilder: (_, index) {
//                             final interest = queue[index];
//                             return _UserDriverInterestCard(
//                               interest: interest,
//                               index: index,
//                               queueNotifier: widget.queueNotifier,
//                               isTop: index == 0,
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _UserDriverInterestCard extends StatefulWidget {
//   final DriverInterest interest;
//   final int index;
//   final ValueNotifier<List<DriverInterest>> queueNotifier;
//   final bool isTop;
//
//   const _UserDriverInterestCard({
//     required this.interest,
//     required this.index,
//     required this.queueNotifier,
//     required this.isTop,
//   });
//
//   @override
//   State<_UserDriverInterestCard> createState() => _UserDriverInterestCardState();
// }
//
// class _UserDriverInterestCardState extends State<_UserDriverInterestCard> {
//   bool _isAccepting = false;
//
//   static const primaryColor = Color(0xFF00A651);
//
//   void _removeInterest() {
//     final updated = List<DriverInterest>.from(widget.queueNotifier.value);
//     updated.removeAt(widget.index);
//     widget.queueNotifier.value = updated;
//   }
//
//   Future<void> _acceptDriver() async {
//     setState(() => _isAccepting = true);
//
//     try {
//       final token = await LocalCache.getToken();
//       final response = await http.post(
//         Uri.parse(
//             "${App_Constructor().BaseURL}/api/courier/request/${widget.interest.courierId}/accept-driver"),
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json",
//         },
//         body: jsonEncode({
//           "driver_id": widget.interest.driverId.toString(),
//         }),
//       );
//       final data = jsonDecode(response.body);
//       if (response.statusCode == 200 && data["status"] == true) {
//         _removeInterest();
//
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(
//                   "Driver accepted • ${widget.interest.driverName}"),
//               backgroundColor: AppTheme.activeGreen,
//             ),
//           );
//           Navigator.of(navigatorKey.currentContext!).push(
//             MaterialPageRoute(
//               builder: (_) => CourierDetailScreen(orderId: widget.interest.courierId,),
//             ),
//           );
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(data["message"] ?? "Failed to accept driver"),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint("Accept driver error: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Network error occurred"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isAccepting = false);
//       }
//     }
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final double timerProgress = widget.interest.remainingSeconds / 15.0;
//     final Color timerColor = widget.interest.remainingSeconds > 8
//         ? primaryColor
//         : widget.interest.remainingSeconds > 4
//         ? Colors.amber
//         : Colors.red;
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: widget.isTop
//                 ? primaryColor.withOpacity(0.25)
//                 : Colors.black.withOpacity(0.12),
//             blurRadius: widget.isTop ? 20 : 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//         border: widget.isTop
//             ? Border.all(color: primaryColor.withOpacity(0.4), width: 1.5)
//             : null,
//       ),
//       child: Column(
//         children: [
//           ClipRRect(
//             borderRadius:
//             const BorderRadius.vertical(top: Radius.circular(20)),
//             child: LinearProgressIndicator(
//               value: timerProgress.clamp(0.0, 1.0),
//               minHeight: 5,
//               backgroundColor: Colors.grey.shade200,
//               valueColor: AlwaysStoppedAnimation<Color>(timerColor),
//             ),
//           ),
//
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header with driver info
//                 Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 24,
//                       backgroundColor: primaryColor.withOpacity(0.12),
//                       backgroundImage: widget.interest.driverImage.isNotEmpty
//                           ? NetworkImage(widget.interest.driverImage)
//                           : null,
//                       child: widget.interest.driverImage.isEmpty
//                           ? Text(
//                         widget.interest.driverName.isNotEmpty
//                             ? widget.interest.driverName[0].toUpperCase()
//                             : "?",
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 20,
//                           color: primaryColor,
//                         ),
//                       )
//                           : null,
//                     ),
//                     const SizedBox(width: 12),
//
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             widget.interest.driverName,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.w700,
//                               fontSize: 15,
//                               color: Color(0xFF1A1A1A),
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           Row(
//                             children: [
//                               Icon(Icons.phone,
//                                   size: 12, color: Colors.grey.shade500),
//                               const SizedBox(width: 4),
//                               Text(
//                                 widget.interest.driverPhone,
//                                 style: TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.grey.shade600),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 10, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: primaryColor,
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Text(
//                             "₹${widget.interest.driverPrice.toStringAsFixed(0)}",
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Row(
//                           children: [
//                             Icon(Icons.timer,
//                                 size: 12, color: timerColor),
//                             const SizedBox(width: 3),
//                             Text(
//                               "${widget.interest.remainingSeconds}s",
//                               style: TextStyle(
//                                 color: timerColor,
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 10),
//
//                 // Driver message
//                 if (widget.interest.driverMessage.isNotEmpty)
//                   Container(
//                     padding: const EdgeInsets.all(12),
//                     decoration: BoxDecoration(
//                       color: const Color(0xFFF6F9F7),
//                       borderRadius: BorderRadius.circular(14),
//                     ),
//                     child: Row(
//                       children: [
//                         Icon(Icons.message,
//                             size: 16, color: Colors.grey.shade600),
//                         const SizedBox(width: 8),
//                         Expanded(
//                           child: Text(
//                             widget.interest.driverMessage,
//                             style: const TextStyle(
//                               fontSize: 13,
//                               color: Color(0xFF333333),
//                             ),
//                           ),
//                         ),
//                       ],
//                     ),
//                   ),
//
//                 const SizedBox(height: 10),
//
//                 // Price comparison
//                 Row(
//                   mainAxisAlignment: MainAxisAlignment.spaceBetween,
//                   children: [
//                     Text(
//                       "Suggested: ₹${widget.interest.suggestedPrice.toStringAsFixed(0)}",
//                       style: TextStyle(
//                         fontSize: 12,
//                         color: Colors.grey.shade600,
//                         decoration: TextDecoration.lineThrough,
//                       ),
//                     ),
//                     Container(
//                       padding: const EdgeInsets.symmetric(
//                           horizontal: 8, vertical: 2),
//                       decoration: BoxDecoration(
//                         color: Colors.green.shade50,
//                         borderRadius: BorderRadius.circular(4),
//                       ),
//                       child: Text(
//                         widget.interest.driverPrice < widget.interest.suggestedPrice
//                             ? "₹${(widget.interest.suggestedPrice - widget.interest.driverPrice).toStringAsFixed(0)} less"
//                             : "₹${(widget.interest.driverPrice - widget.interest.suggestedPrice).toStringAsFixed(0)} more",
//                         style: TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w600,
//                           color: widget.interest.driverPrice < widget.interest.suggestedPrice
//                               ? Colors.green
//                               : Colors.orange,
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 14),
//
//                 // Action buttons
//                 Row(
//                   children: [
//                     Expanded(
//                       child: GestureDetector(
//                         onTap: _isAccepting ? null : _removeInterest,
//                         child: Container(
//                           height: 48,
//                           decoration: BoxDecoration(
//                             color: _isAccepting
//                                 ? Colors.grey.shade300
//                                 : const Color(0xFFF0F0F0),
//                             borderRadius: BorderRadius.circular(14),
//                           ),
//                           child: Center(
//                             child: Text(
//                               "✕  Decline",
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 14,
//                                 color: _isAccepting
//                                     ? Colors.grey.shade500
//                                     : const Color(0xFF666666),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       flex: 2,
//                       child: GestureDetector(
//                         onTap: _isAccepting ? null : _acceptDriver,
//                         child: Container(
//                           height: 48,
//                           decoration: BoxDecoration(
//                             gradient: _isAccepting
//                                 ? null
//                                 : const LinearGradient(
//                               colors: [Color(0xFF00A651), Color(0xFF007A3D)],
//                             ),
//                             color: _isAccepting ? Colors.grey : null,
//                             borderRadius: BorderRadius.circular(14),
//                             boxShadow: _isAccepting
//                                 ? []
//                                 : [
//                               BoxShadow(
//                                 color: primaryColor.withOpacity(0.35),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           child: Center(
//                             child: _isAccepting
//                                 ? const SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(
//                                 color: Colors.white,
//                                 strokeWidth: 2,
//                               ),
//                             )
//                                 : const Text(
//                               "✓  Accept Driver",
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w800,
//                                 fontSize: 15,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
// }
//
// // ==================== DRIVER SIDE DIALOG (New Courier Requests) ====================
//
// class DriverRideRequestDialog extends StatefulWidget {
//   final ValueNotifier<List<CourierRequest>> queueNotifier;
//
//   const DriverRideRequestDialog({
//     super.key,
//     required this.queueNotifier,
//   });
//
//   @override
//   State<DriverRideRequestDialog> createState() => _DriverRideRequestDialogState();
// }
//
// class _DriverRideRequestDialogState extends State<DriverRideRequestDialog> {
//   final AudioPlayer _audioPlayer = AudioPlayer();
//   int _previousCount = 0;
//
//   static const primaryColor = Color(0xFF00A651);
//
//   @override
//   void initState() {
//     super.initState();
//     _previousCount = widget.queueNotifier.value.length;
//     widget.queueNotifier.addListener(_onQueueChanged);
//     if (_previousCount > 0) _playSound();
//   }
//
//   void _onQueueChanged() {
//     final newCount = widget.queueNotifier.value.length;
//     if (newCount > _previousCount) {
//       _playSound();
//     }
//     _previousCount = newCount;
//   }
//
//   Future<void> _playSound() async {
//     try {
//       await _audioPlayer.stop();
//       await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
//     } catch (_) {}
//   }
//
//   @override
//   void dispose() {
//     widget.queueNotifier.removeListener(_onQueueChanged);
//     _audioPlayer.dispose();
//     super.dispose();
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     return SafeArea(
//       child: Align(
//         alignment: Alignment.topCenter,
//         child: Padding(
//           padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
//           child: Material(
//             color: Colors.transparent,
//             child: ValueListenableBuilder<List<CourierRequest>>(
//               valueListenable: widget.queueNotifier,
//               builder: (context, queue, _) {
//                 if (queue.isEmpty) return const SizedBox.shrink();
//
//                 return ConstrainedBox(
//                   constraints: BoxConstraints(
//                     maxHeight: MediaQuery.of(context).size.height * 0.78,
//                   ),
//                   child: Column(
//                     mainAxisSize: MainAxisSize.min,
//                     children: [
//                       if (queue.length > 1)
//                         Container(
//                           margin: const EdgeInsets.only(bottom: 6),
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 14, vertical: 6),
//                           decoration: BoxDecoration(
//                             color: Colors.amber,
//                             borderRadius: BorderRadius.circular(20),
//                           ),
//                           child: Text(
//                             "${queue.length} New Requests",
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 13,
//                               color: Colors.black87,
//                             ),
//                           ),
//                         ),
//
//                       Flexible(
//                         child: ListView.builder(
//                           shrinkWrap: true,
//                           padding: EdgeInsets.zero,
//                           itemCount: queue.length,
//                           itemBuilder: (_, index) {
//                             final request = queue[index];
//                             return _DriverRequestCard(
//                               request: request,
//                               index: index,
//                               queueNotifier: widget.queueNotifier,
//                               isTop: index == 0,
//                             );
//                           },
//                         ),
//                       ),
//                     ],
//                   ),
//                 );
//               },
//             ),
//           ),
//         ),
//       ),
//     );
//   }
// }
//
// class _DriverRequestCard extends StatefulWidget {
//   final CourierRequest request;
//   final int index;
//   final ValueNotifier<List<CourierRequest>> queueNotifier;
//   final bool isTop;
//
//   const _DriverRequestCard({
//     required this.request,
//     required this.index,
//     required this.queueNotifier,
//     required this.isTop,
//   });
//
//   @override
//   State<_DriverRequestCard> createState() => _DriverRequestCardState();
// }
//
// class _DriverRequestCardState extends State<_DriverRequestCard> {
//   bool _isSubmitting = false;
//   String? _customPrice;
//   String? _customMessage;
//
//   static const primaryColor = Color(0xFF00A651);
//
//   void _removeRequest() {
//     final updated = List<CourierRequest>.from(widget.queueNotifier.value);
//     updated.removeAt(widget.index);
//     widget.queueNotifier.value = updated;
//   }
//
//   Future<void> _sendOffer(String price, String message) async {
//     setState(() => _isSubmitting = true);
//
//     try {
//       final token = await LocalCache.getToken();
//       final response = await http.post(
//         Uri.parse(
//             "${App_Constructor().BaseURL}/api/courier/request/${widget.request.courierId}/interest"),
//         headers: {
//           "Authorization": "Bearer $token",
//           "Content-Type": "application/json",
//         },
//         body: jsonEncode({
//           "driver_price": double.tryParse(price) ?? 0,
//           "message": message,
//         }),
//       );
//
//       final data = jsonDecode(response.body);
//       if (response.statusCode == 200 && data["status"] == true) {
//         _removeRequest();
//
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text("Offer submitted • ₹$price"),
//               backgroundColor: primaryColor,
//             ),
//           );
//
//           // Navigate to detail screen after successful offer
//           final courier = CourierModel(
//             id: int.tryParse(widget.request.courierId) ?? 0,
//             userId: 0,
//             pickupLocation: widget.request.pickup,
//             dropLocation: widget.request.drop,
//             dropLatitude: widget.request.dropLatitude,
//             dropLongitude: widget.request.dropLongitude,
//             distance: widget.request.distance,
//             time: widget.request.time,
//             tripType: widget.request.tripType,
//             senderName: widget.request.senderName,
//             senderPhone: widget.request.senderPhone,
//             receiverName: widget.request.receiverName,
//             receiverPhone: widget.request.receiverPhone,
//             packageDescription: '',
//             packageSize: widget.request.packageSize,
//             suggestedPrice: widget.request.fare.toString(),
//             paymentMethod: widget.request.paymentMethod,
//             status: 'pending',
//             senderImage: widget.request.userImage,
//           );
//           //
//           Navigator.of(navigatorKey.currentContext!).push(
//             MaterialPageRoute(
//               builder: (_) => DriverCourierDetailScreen(courierId: widget.request.courierId.toString(),),
//             ),
//           );
//         }
//       } else {
//         if (mounted) {
//           ScaffoldMessenger.of(context).showSnackBar(
//             SnackBar(
//               content: Text(data["message"] ?? "Failed to submit offer"),
//               backgroundColor: Colors.red,
//             ),
//           );
//         }
//       }
//     } catch (e) {
//       debugPrint("Send offer error: $e");
//       if (mounted) {
//         ScaffoldMessenger.of(context).showSnackBar(
//           const SnackBar(
//             content: Text("Network error occurred"),
//             backgroundColor: Colors.red,
//           ),
//         );
//       }
//     } finally {
//       if (mounted) {
//         setState(() => _isSubmitting = false);
//       }
//     }
//   }
//
//   void _showCustomOfferSheet() {
//     final priceController = TextEditingController(
//         text: _customPrice ?? widget.request.fare.toString());
//     final messageController = TextEditingController(
//         text: _customMessage ?? "I can deliver it safely and on time.");
//
//     showModalBottomSheet(
//       context: context,
//       isScrollControlled: true,
//       shape: const RoundedRectangleBorder(
//           borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
//       builder: (_) => Padding(
//         padding: EdgeInsets.only(
//             bottom: MediaQuery.of(context).viewInsets.bottom),
//         child: Container(
//           padding: const EdgeInsets.all(20),
//           child: Column(
//             mainAxisSize: MainAxisSize.min,
//             children: [
//               const Icon(Icons.local_offer,
//                   size: 48, color: primaryColor),
//               const SizedBox(height: 12),
//               const Text("Send Your Offer",
//                   style: TextStyle(
//                       fontSize: 18, fontWeight: FontWeight.bold)),
//               const SizedBox(height: 16),
//               TextField(
//                 controller: priceController,
//                 keyboardType: TextInputType.number,
//                 decoration: InputDecoration(
//                   prefixText: "₹ ",
//                   labelText: "Your Offer Price",
//                   border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8)),
//                 ),
//               ),
//               const SizedBox(height: 12),
//               TextField(
//                 controller: messageController,
//                 maxLines: 2,
//                 decoration: InputDecoration(
//                   labelText: "Message (optional)",
//                   border: OutlineInputBorder(
//                       borderRadius: BorderRadius.circular(8)),
//                 ),
//               ),
//               const SizedBox(height: 16),
//               Row(
//                 children: [
//                   Expanded(
//                     child: TextButton(
//                       onPressed: () => Navigator.pop(context),
//                       child: const Text("Cancel"),
//                     ),
//                   ),
//                   const SizedBox(width: 12),
//                   Expanded(
//                     flex: 2,
//                     child: ElevatedButton(
//                       onPressed: () {
//                         setState(() {
//                           _customPrice = priceController.text;
//                           _customMessage = messageController.text;
//                         });
//                         Navigator.pop(context);
//                         _sendOffer(priceController.text, messageController.text);
//                       },
//                       style: ElevatedButton.styleFrom(
//                         backgroundColor: primaryColor,
//                         foregroundColor: Colors.white,
//                         padding: const EdgeInsets.symmetric(vertical: 12),
//                         shape: RoundedRectangleBorder(
//                             borderRadius: BorderRadius.circular(8)),
//                       ),
//                       child: const Text("Submit Offer",
//                           style: TextStyle(
//                               fontSize: 15,
//                               fontWeight: FontWeight.bold)),
//                     ),
//                   ),
//                 ],
//               ),
//             ],
//           ),
//         ),
//       ),
//     );
//   }
//
//   List<String> get quickOffers {
//     final base = widget.request.fare;
//     return [
//       (base).toStringAsFixed(0),
//       (base + (base * 0.10)).toStringAsFixed(0),
//       (base + (base * 0.20)).toStringAsFixed(0),
//     ];
//   }
//
//   @override
//   Widget build(BuildContext context) {
//     final double timerProgress = widget.request.remainingSeconds / 15.0;
//     final Color timerColor = widget.request.remainingSeconds > 8
//         ? primaryColor
//         : widget.request.remainingSeconds > 4
//         ? Colors.amber
//         : Colors.red;
//
//     return Container(
//       margin: const EdgeInsets.only(bottom: 10),
//       decoration: BoxDecoration(
//         color: Colors.white,
//         borderRadius: BorderRadius.circular(20),
//         boxShadow: [
//           BoxShadow(
//             color: widget.isTop
//                 ? primaryColor.withOpacity(0.25)
//                 : Colors.black.withOpacity(0.12),
//             blurRadius: widget.isTop ? 20 : 10,
//             offset: const Offset(0, 4),
//           ),
//         ],
//         border: widget.isTop
//             ? Border.all(color: primaryColor.withOpacity(0.4), width: 1.5)
//             : null,
//       ),
//       child: Column(
//         children: [
//           ClipRRect(
//             borderRadius:
//             const BorderRadius.vertical(top: Radius.circular(20)),
//             child: LinearProgressIndicator(
//               value: timerProgress.clamp(0.0, 1.0),
//               minHeight: 5,
//               backgroundColor: Colors.grey.shade200,
//               valueColor: AlwaysStoppedAnimation<Color>(timerColor),
//             ),
//           ),
//
//           Padding(
//             padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
//             child: Column(
//               crossAxisAlignment: CrossAxisAlignment.start,
//               children: [
//                 // Header with user info
//                 Row(
//                   children: [
//                     CircleAvatar(
//                       radius: 24,
//                       backgroundColor: primaryColor.withOpacity(0.12),
//                       backgroundImage: widget.request.userImage.isNotEmpty
//                           ? NetworkImage(widget.request.userImage)
//                           : null,
//                       child: widget.request.userImage.isEmpty
//                           ? Text(
//                         widget.request.senderName.isNotEmpty
//                             ? widget.request.senderName[0].toUpperCase()
//                             : "?",
//                         style: TextStyle(
//                           fontWeight: FontWeight.bold,
//                           fontSize: 20,
//                           color: primaryColor,
//                         ),
//                       )
//                           : null,
//                     ),
//                     const SizedBox(width: 12),
//
//                     Expanded(
//                       child: Column(
//                         crossAxisAlignment: CrossAxisAlignment.start,
//                         children: [
//                           Text(
//                             widget.request.senderName,
//                             style: const TextStyle(
//                               fontWeight: FontWeight.w700,
//                               fontSize: 15,
//                               color: Color(0xFF1A1A1A),
//                             ),
//                           ),
//                           const SizedBox(height: 2),
//                           Row(
//                             children: [
//                               Icon(Icons.phone,
//                                   size: 12, color: Colors.grey.shade500),
//                               const SizedBox(width: 4),
//                               Text(
//                                 widget.request.senderPhone,
//                                 style: TextStyle(
//                                     fontSize: 12,
//                                     color: Colors.grey.shade600),
//                               ),
//                             ],
//                           ),
//                         ],
//                       ),
//                     ),
//
//                     Column(
//                       crossAxisAlignment: CrossAxisAlignment.end,
//                       children: [
//                         Container(
//                           padding: const EdgeInsets.symmetric(
//                               horizontal: 10, vertical: 4),
//                           decoration: BoxDecoration(
//                             color: primaryColor,
//                             borderRadius: BorderRadius.circular(8),
//                           ),
//                           child: Text(
//                             "₹${widget.request.fare.toStringAsFixed(0)}",
//                             style: const TextStyle(
//                               fontWeight: FontWeight.bold,
//                               fontSize: 16,
//                               color: Colors.white,
//                             ),
//                           ),
//                         ),
//                         const SizedBox(height: 4),
//                         Row(
//                           children: [
//                             Icon(Icons.timer,
//                                 size: 12, color: timerColor),
//                             const SizedBox(width: 3),
//                             Text(
//                               "${widget.request.remainingSeconds}s",
//                               style: TextStyle(
//                                 color: timerColor,
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 12,
//                               ),
//                             ),
//                           ],
//                         ),
//                       ],
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 14),
//
//                 // Route info
//                 Container(
//                   padding: const EdgeInsets.all(12),
//                   decoration: BoxDecoration(
//                     color: const Color(0xFFF6F9F7),
//                     borderRadius: BorderRadius.circular(14),
//                   ),
//                   child: Column(
//                     children: [
//                       _buildRouteRow(
//                         icon: Icons.my_location,
//                         iconColor: primaryColor,
//                         label: "Pickup",
//                         address: widget.request.pickup,
//                       ),
//                       Padding(
//                         padding: const EdgeInsets.only(left: 10),
//                         child: Row(
//                           children: [
//                             Container(
//                               width: 1.5,
//                               height: 20,
//                               color: Colors.grey.shade300,
//                             ),
//                           ],
//                         ),
//                       ),
//                       _buildRouteRow(
//                         icon: Icons.location_on,
//                         iconColor: Colors.red,
//                         label: "Drop",
//                         address: widget.request.drop,
//                       ),
//                     ],
//                   ),
//                 ),
//
//                 const SizedBox(height: 10),
//
//                 // Package info
//                 Row(
//                   children: [
//                     Icon(Icons.inventory_2,
//                         size: 12, color: Colors.grey.shade400),
//                     const SizedBox(width: 4),
//                     Text(
//                       widget.request.packageSize.toUpperCase(),
//                       style: TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.grey.shade600),
//                     ),
//                     const SizedBox(width: 12),
//                     Icon(Icons.directions_car,
//                         size: 12, color: Colors.grey.shade400),
//                     const SizedBox(width: 4),
//                     Text(
//                       widget.request.tripType.toUpperCase(),
//                       style: TextStyle(
//                           fontSize: 11,
//                           fontWeight: FontWeight.w600,
//                           color: Colors.grey.shade600),
//                     ),
//                   ],
//                 ),
//
//                 const SizedBox(height: 10),
//
//                 // Quick offers section
//                 if (!_isSubmitting) ...[
//                   const Text(
//                     "Quick offers:",
//                     style: TextStyle(
//                       fontSize: 12,
//                       fontWeight: FontWeight.w600,
//                       color: Colors.black54,
//                     ),
//                   ),
//                   const SizedBox(height: 8),
//                   Row(
//                     children: [
//                       ...quickOffers.map((price) => Expanded(
//                         child: Padding(
//                           padding: const EdgeInsets.only(right: 6),
//                           child: GestureDetector(
//                             onTap: () => _sendOffer(price, "I can deliver it safely and on time."),
//                             child: Container(
//                               height: 40,
//                               decoration: BoxDecoration(
//                                 color: primaryColor.withOpacity(0.1),
//                                 borderRadius: BorderRadius.circular(8),
//                                 border: Border.all(color: primaryColor.withOpacity(0.3)),
//                               ),
//                               child: Center(
//                                 child: Text(
//                                   "₹$price",
//                                   style: TextStyle(
//                                     fontWeight: FontWeight.bold,
//                                     fontSize: 13,
//                                     color: primaryColor,
//                                   ),
//                                 ),
//                               ),
//                             ),
//                           ),
//                         ),
//                       )),
//                       const SizedBox(width: 6),
//                       GestureDetector(
//                         onTap: _showCustomOfferSheet,
//                         child: Container(
//                           width: 40,
//                           height: 40,
//                           decoration: BoxDecoration(
//                             color: Colors.grey.shade100,
//                             borderRadius: BorderRadius.circular(8),
//                             border: Border.all(color: Colors.grey.shade300),
//                           ),
//                           child: Icon(Icons.edit,
//                               color: primaryColor, size: 20),
//                         ),
//                       ),
//                     ],
//                   ),
//                 ],
//
//                 const SizedBox(height: 14),
//
//                 // Action buttons
//                 Row(
//                   children: [
//                     Expanded(
//                       child: GestureDetector(
//                         onTap: _isSubmitting ? null : _removeRequest,
//                         child: Container(
//                           height: 48,
//                           decoration: BoxDecoration(
//                             color: _isSubmitting
//                                 ? Colors.grey.shade300
//                                 : const Color(0xFFF0F0F0),
//                             borderRadius: BorderRadius.circular(14),
//                           ),
//                           child: Center(
//                             child: Text(
//                               "✕  Decline",
//                               style: TextStyle(
//                                 fontWeight: FontWeight.w700,
//                                 fontSize: 14,
//                                 color: _isSubmitting
//                                     ? Colors.grey.shade500
//                                     : const Color(0xFF666666),
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                     const SizedBox(width: 10),
//                     Expanded(
//                       flex: 2,
//                       child: GestureDetector(
//                         onTap: _isSubmitting ? null : () => _sendOffer(
//                           widget.request.fare.toString(),
//                           "I can deliver it safely and on time.",
//                         ),
//                         child: Container(
//                           height: 48,
//                           decoration: BoxDecoration(
//                             gradient: _isSubmitting
//                                 ? null
//                                 : const LinearGradient(
//                               colors: [Color(0xFF00A651), Color(0xFF007A3D)],
//                             ),
//                             color: _isSubmitting ? Colors.grey : null,
//                             borderRadius: BorderRadius.circular(14),
//                             boxShadow: _isSubmitting
//                                 ? []
//                                 : [
//                               BoxShadow(
//                                 color: primaryColor.withOpacity(0.35),
//                                 blurRadius: 10,
//                                 offset: const Offset(0, 4),
//                               ),
//                             ],
//                           ),
//                           child: Center(
//                             child: _isSubmitting
//                                 ? const SizedBox(
//                               width: 20,
//                               height: 20,
//                               child: CircularProgressIndicator(
//                                 color: Colors.white,
//                                 strokeWidth: 2,
//                               ),
//                             )
//                                 : Text(
//                               "✓  Accept ₹${widget.request.fare.toStringAsFixed(0)}",
//                               style: const TextStyle(
//                                 fontWeight: FontWeight.w800,
//                                 fontSize: 14,
//                                 color: Colors.white,
//                               ),
//                             ),
//                           ),
//                         ),
//                       ),
//                     ),
//                   ],
//                 ),
//               ],
//             ),
//           ),
//         ],
//       ),
//     );
//   }
//
//   Widget _buildRouteRow({
//     required IconData icon,
//     required Color iconColor,
//     required String label,
//     required String address,
//   }) {
//     return Row(
//       crossAxisAlignment: CrossAxisAlignment.center,
//       children: [
//         Icon(icon, size: 18, color: iconColor),
//         const SizedBox(width: 10),
//         Expanded(
//           child: Column(
//             crossAxisAlignment: CrossAxisAlignment.start,
//             children: [
//               Text(
//                 label,
//                 style: TextStyle(
//                     fontSize: 10,
//                     color: Colors.grey.shade500,
//                     fontWeight: FontWeight.w500),
//               ),
//               Text(
//                 address,
//                 style: const TextStyle(
//                     fontSize: 13,
//                     fontWeight: FontWeight.w600,
//                     color: Color(0xFF222222)),
//                 maxLines: 1,
//                 overflow: TextOverflow.ellipsis,
//               ),
//             ],
//           ),
//         ),
//       ],
//     );
//   }
// }


import 'dart:async';
import 'dart:convert';
import 'package:audioplayers/audioplayers.dart';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import '../../api_service/app_constocter.dart';
import '../../main.dart';
import '../../notification_handler.dart';
import '../../service/colors.dart';
import '../../service/local_cache.dart';
import 'driver_courier_detail_screen.dart';
import 'order_detail_screen.dart';

// ==================== USER SIDE DIALOG (Driver Interest) ====================

class UserDriverInterestDialog extends StatefulWidget {
  final ValueNotifier<List<DriverInterest>> queueNotifier;

  const UserDriverInterestDialog({
    super.key,
    required this.queueNotifier,
  });

  @override
  State<UserDriverInterestDialog> createState() => _UserDriverInterestDialogState();
}

class _UserDriverInterestDialogState extends State<UserDriverInterestDialog> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _previousCount = 0;
  bool _isDisposed = false;

  static const primaryColor = Color(0xFF00A651);

  @override
  void initState() {
    super.initState();
    _previousCount = widget.queueNotifier.value.length;
    widget.queueNotifier.addListener(_onQueueChanged);
    if (_previousCount > 0) _playSound();
  }

  void _onQueueChanged() {
    if (_isDisposed) return;
    final newCount = widget.queueNotifier.value.length;
    if (newCount > _previousCount) {
      _playSound();
    }
    _previousCount = newCount;
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (_) {}
  }

  @override
  void dispose() {
    _isDisposed = true;
    widget.queueNotifier.removeListener(_onQueueChanged);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
          child: Material(
            color: Colors.transparent,
            child: ValueListenableBuilder<List<DriverInterest>>(
              valueListenable: widget.queueNotifier,
              builder: (context, queue, _) {
                if (queue.isEmpty) return const SizedBox.shrink();

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.78,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (queue.length > 1)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${queue.length} Drivers Interested",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: queue.length,
                          itemBuilder: (_, index) {
                            final interest = queue[index];
                            return _UserDriverInterestCard(
                              interest: interest,
                              index: index,
                              queueNotifier: widget.queueNotifier,
                              isTop: index == 0,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _UserDriverInterestCard extends StatefulWidget {
  final DriverInterest interest;
  final int index;
  final ValueNotifier<List<DriverInterest>> queueNotifier;
  final bool isTop;

  const _UserDriverInterestCard({
    required this.interest,
    required this.index,
    required this.queueNotifier,
    required this.isTop,
  });

  @override
  State<_UserDriverInterestCard> createState() => _UserDriverInterestCardState();
}

class _UserDriverInterestCardState extends State<_UserDriverInterestCard> {
  bool _isAccepting = false;
  bool _isDisposed = false;

  static const primaryColor = Color(0xFF00A651);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _removeInterest() {
    if (_isDisposed) return;
    final updated = List<DriverInterest>.from(widget.queueNotifier.value);
    updated.removeAt(widget.index);
    widget.queueNotifier.value = updated;
  }

// In _UserDriverInterestCardState class, update the _acceptDriver method:

  Future<void> _acceptDriver() async {
    if (_isAccepting) return;

    setState(() => _isAccepting = true);

    try {
      final token = await LocalCache.getToken();
      final response = await http.post(
        Uri.parse(
            "${App_Constructor().BaseURL}/api/courier/request/${widget.interest.courierId}/accept-driver"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "driver_id": widget.interest.driverId.toString(),
        }),
      );

      final data = jsonDecode(response.body);

      if (response.statusCode == 200 && data["status"] == true) {
        if (_isDisposed) return;

        _removeInterest();

        // First pop the dialog
        if (mounted) {
          Navigator.of(context).pop();

          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Driver accepted • ${widget.interest.driverName}"),
              backgroundColor: AppTheme.activeGreen,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Navigate to USER detail screen after a short delay
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && navigatorKey.currentContext != null) {
              Navigator.of(navigatorKey.currentContext!).push(
                MaterialPageRoute(
                  builder: (_) => CourierDetailScreen(  // ← Changed to CourierDetailScreen
                    orderId: widget.interest.courierId,
                  ),
                ),
              );
            }
          });
        }
      } else {
        if (!_isDisposed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data["message"] ?? "Failed to accept driver"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Accept driver error: $e");
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Network error occurred"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (!_isDisposed && mounted) {
        setState(() => _isAccepting = false);
      }
    }
  }
  @override
  Widget build(BuildContext context) {
    final double timerProgress = widget.interest.remainingSeconds / 15.0;
    final Color timerColor = widget.interest.remainingSeconds > 8
        ? primaryColor
        : widget.interest.remainingSeconds > 4
        ? Colors.amber
        : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.isTop
                ? primaryColor.withOpacity(0.25)
                : Colors.black.withOpacity(0.12),
            blurRadius: widget.isTop ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: widget.isTop
            ? Border.all(color: primaryColor.withOpacity(0.4), width: 1.5)
            : null,
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
            child: LinearProgressIndicator(
              value: timerProgress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(timerColor),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with driver info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: primaryColor.withOpacity(0.12),
                      backgroundImage: widget.interest.driverImage.isNotEmpty
                          ? NetworkImage(widget.interest.driverImage)
                          : null,
                      child: widget.interest.driverImage.isEmpty
                          ? Text(
                        widget.interest.driverName.isNotEmpty
                            ? widget.interest.driverName[0].toUpperCase()
                            : "?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: primaryColor,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.interest.driverName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Row(
                          //   children: [
                          //     Icon(Icons.phone,
                          //         size: 12, color: Colors.grey.shade500),
                          //     const SizedBox(width: 4),
                          //     Text(
                          //       widget.interest.driverPhone,
                          //       style: TextStyle(
                          //           fontSize: 12,
                          //           color: Colors.grey.shade600),
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "TJS ${widget.interest.driverPrice.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.timer,
                                size: 12, color: timerColor),
                            const SizedBox(width: 3),
                            Text(
                              "${widget.interest.remainingSeconds}s",
                              style: TextStyle(
                                color: timerColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Driver message
                if (widget.interest.driverMessage.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: const Color(0xFFF6F9F7),
                      borderRadius: BorderRadius.circular(14),
                    ),
                    child: Row(
                      children: [
                        Icon(Icons.message,
                            size: 16, color: Colors.grey.shade600),
                        const SizedBox(width: 8),
                        Expanded(
                          child: Text(
                            widget.interest.driverMessage,
                            style: const TextStyle(
                              fontSize: 13,
                              color: Color(0xFF333333),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),

                const SizedBox(height: 10),

                // Price comparison
                Row(
                  mainAxisAlignment: MainAxisAlignment.spaceBetween,
                  children: [
                    Text(
                      "Suggested: TJS ${widget.interest.suggestedPrice.toStringAsFixed(0)}",
                      style: TextStyle(
                        fontSize: 12,
                        color: Colors.grey.shade600,
                        decoration: TextDecoration.lineThrough,
                      ),
                    ),
                    Container(
                      padding: const EdgeInsets.symmetric(
                          horizontal: 8, vertical: 2),
                      decoration: BoxDecoration(
                        color: Colors.green.shade50,
                        borderRadius: BorderRadius.circular(4),
                      ),
                      child: Text(
                        widget.interest.driverPrice < widget.interest.suggestedPrice
                            ? "TJS ${(widget.interest.suggestedPrice - widget.interest.driverPrice).toStringAsFixed(0)} less"
                            : "TJS ${(widget.interest.driverPrice - widget.interest.suggestedPrice).toStringAsFixed(0)} more",
                        style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: widget.interest.driverPrice < widget.interest.suggestedPrice
                              ? Colors.green
                              : Colors.orange,
                        ),
                      ),
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: (_isAccepting || _isDisposed) ? null : _removeInterest,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: (_isAccepting || _isDisposed)
                                ? Colors.grey.shade300
                                : const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              "✕  Decline",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: (_isAccepting || _isDisposed)
                                    ? Colors.grey.shade500
                                    : const Color(0xFF666666),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: (_isAccepting || _isDisposed) ? null : _acceptDriver,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: (_isAccepting || _isDisposed)
                                ? null
                                : const LinearGradient(
                              colors: [Color(0xFF00A651), Color(0xFF007A3D)],
                            ),
                            color: (_isAccepting || _isDisposed) ? Colors.grey : null,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: (_isAccepting || _isDisposed)
                                ? []
                                : [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isAccepting
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : const Text(
                              "✓  Accept Driver",
                              style: TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 15,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ==================== DRIVER SIDE DIALOG (New Courier Requests) ====================

class DriverRideRequestDialog extends StatefulWidget {
  final ValueNotifier<List<CourierRequest>> queueNotifier;

  const DriverRideRequestDialog({
    super.key,
    required this.queueNotifier,
  });

  @override
  State<DriverRideRequestDialog> createState() => _DriverRideRequestDialogState();
}

class _DriverRideRequestDialogState extends State<DriverRideRequestDialog> {
  final AudioPlayer _audioPlayer = AudioPlayer();
  int _previousCount = 0;
  bool _isDisposed = false;

  static const primaryColor = Color(0xFF00A651);

  @override
  void initState() {
    super.initState();
    _previousCount = widget.queueNotifier.value.length;
    widget.queueNotifier.addListener(_onQueueChanged);
    if (_previousCount > 0) _playSound();
  }

  void _onQueueChanged() {
    if (_isDisposed) return;
    final newCount = widget.queueNotifier.value.length;
    if (newCount > _previousCount) {
      _playSound();
    }
    _previousCount = newCount;
  }

  Future<void> _playSound() async {
    try {
      await _audioPlayer.stop();
      await _audioPlayer.play(AssetSource('sounds/notification.mp3'));
    } catch (_) {}
  }

  @override
  void dispose() {
    _isDisposed = true;
    widget.queueNotifier.removeListener(_onQueueChanged);
    _audioPlayer.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      child: Align(
        alignment: Alignment.topCenter,
        child: Padding(
          padding: const EdgeInsets.only(top: 12, left: 12, right: 12),
          child: Material(
            color: Colors.transparent,
            child: ValueListenableBuilder<List<CourierRequest>>(
              valueListenable: widget.queueNotifier,
              builder: (context, queue, _) {
                if (queue.isEmpty) return const SizedBox.shrink();

                return ConstrainedBox(
                  constraints: BoxConstraints(
                    maxHeight: MediaQuery.of(context).size.height * 0.78,
                  ),
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      if (queue.length > 1)
                        Container(
                          margin: const EdgeInsets.only(bottom: 6),
                          padding: const EdgeInsets.symmetric(
                              horizontal: 14, vertical: 6),
                          decoration: BoxDecoration(
                            color: Colors.amber,
                            borderRadius: BorderRadius.circular(20),
                          ),
                          child: Text(
                            "${queue.length} New Requests",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 13,
                              color: Colors.black87,
                            ),
                          ),
                        ),

                      Flexible(
                        child: ListView.builder(
                          shrinkWrap: true,
                          padding: EdgeInsets.zero,
                          itemCount: queue.length,
                          itemBuilder: (_, index) {
                            final request = queue[index];
                            return _DriverRequestCard(
                              request: request,
                              index: index,
                              queueNotifier: widget.queueNotifier,
                              isTop: index == 0,
                            );
                          },
                        ),
                      ),
                    ],
                  ),
                );
              },
            ),
          ),
        ),
      ),
    );
  }
}

class _DriverRequestCard extends StatefulWidget {
  final CourierRequest request;
  final int index;
  final ValueNotifier<List<CourierRequest>> queueNotifier;
  final bool isTop;

  const _DriverRequestCard({
    required this.request,
    required this.index,
    required this.queueNotifier,
    required this.isTop,
  });

  @override
  State<_DriverRequestCard> createState() => _DriverRequestCardState();
}

class _DriverRequestCardState extends State<_DriverRequestCard> {
  bool _isSubmitting = false;
  bool _isDisposed = false;
  String? _customPrice;
  String? _customMessage;

  static const primaryColor = Color(0xFF00A651);

  @override
  void dispose() {
    _isDisposed = true;
    super.dispose();
  }

  void _removeRequest() {
    if (_isDisposed) return;
    final updated = List<CourierRequest>.from(widget.queueNotifier.value);
    updated.removeAt(widget.index);
    widget.queueNotifier.value = updated;
  }

  Future<void> _sendOffer(String price, String message) async {
    if (_isSubmitting) return;

    setState(() => _isSubmitting = true);

    try {
      final token = await LocalCache.getToken();
      final response = await http.post(
        Uri.parse(
            "${App_Constructor().BaseURL}/api/courier/request/${widget.request.courierId}/interest"),
        headers: {
          "Authorization": "Bearer $token",
          "Content-Type": "application/json",
        },
        body: jsonEncode({
          "driver_price": double.tryParse(price) ?? 0,
          "message": message,
        }),
      );

      final data = jsonDecode(response.body);

      // In _DriverRequestCardState class, update the navigation after successful offer:

      if (response.statusCode == 200 && data["status"] == true) {
        if (_isDisposed) return;

        _removeRequest();

        if (mounted) {
          // Show success message
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text("Offer submitted • TJS $price"),
              backgroundColor: primaryColor,
              behavior: SnackBarBehavior.floating,
            ),
          );

          // Pop the dialog
          Navigator.of(context).pop();

          // Navigate to DRIVER detail screen after short delay
          Future.delayed(const Duration(milliseconds: 300), () {
            if (mounted && navigatorKey.currentContext != null) {
              Navigator.of(navigatorKey.currentContext!).push(
                MaterialPageRoute(
                  builder: (_) => DriverCourierDetailScreen(  // ← Driver screen
                    courierId: widget.request.courierId.toString(),
                  ),
                ),
              );
            }
          });
        }
      }else {
        if (!_isDisposed && mounted) {
          ScaffoldMessenger.of(context).showSnackBar(
            SnackBar(
              content: Text(data["message"] ?? "Failed to submit offer"),
              backgroundColor: Colors.red,
              behavior: SnackBarBehavior.floating,
            ),
          );
        }
      }
    } catch (e) {
      debugPrint("Send offer error: $e");
      if (!_isDisposed && mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(
            content: Text("Network error occurred"),
            backgroundColor: Colors.red,
            behavior: SnackBarBehavior.floating,
          ),
        );
      }
    } finally {
      if (!_isDisposed && mounted) {
        setState(() => _isSubmitting = false);
      }
    }
  }

  void _showCustomOfferSheet() {
    final priceController = TextEditingController(
        text: _customPrice ?? widget.request.fare.toString());
    final messageController = TextEditingController(
        text: _customMessage ?? "I can deliver it safely and on time.");

    showModalBottomSheet(
      context: context,
      isScrollControlled: true,
      shape: const RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(16))),
      builder: (_) => Padding(
        padding: EdgeInsets.only(
            bottom: MediaQuery.of(context).viewInsets.bottom),
        child: Container(
          padding: const EdgeInsets.all(20),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              const Icon(Icons.local_offer,
                  size: 48, color: primaryColor),
              const SizedBox(height: 12),
              const Text("Send Your Offer",
                  style: TextStyle(
                      fontSize: 18, fontWeight: FontWeight.bold)),
              const SizedBox(height: 16),
              TextField(
                controller: priceController,
                keyboardType: TextInputType.number,
                decoration: InputDecoration(
                  prefixText: "TJS ",
                  labelText: "Your Offer Price",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 12),
              TextField(
                controller: messageController,
                maxLines: 2,
                decoration: InputDecoration(
                  labelText: "Message (optional)",
                  border: OutlineInputBorder(
                      borderRadius: BorderRadius.circular(8)),
                ),
              ),
              const SizedBox(height: 16),
              Row(
                children: [
                  Expanded(
                    child: TextButton(
                      onPressed: () => Navigator.pop(context),
                      child: const Text("Cancel"),
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    flex: 2,
                    child: ElevatedButton(
                      onPressed: () {
                        setState(() {
                          _customPrice = priceController.text;
                          _customMessage = messageController.text;
                        });
                        Navigator.pop(context);
                        _sendOffer(priceController.text, messageController.text);
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: primaryColor,
                        foregroundColor: Colors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.circular(8)),
                      ),
                      child: const Text("Submit Offer",
                          style: TextStyle(
                              fontSize: 15,
                              fontWeight: FontWeight.bold)),
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }

  List<String> get quickOffers {
    final base = widget.request.fare;
    return [
      (base).toStringAsFixed(0),
      (base + (base * 0.10)).toStringAsFixed(0),
      (base + (base * 0.20)).toStringAsFixed(0),
    ];
  }

  @override
  Widget build(BuildContext context) {
    final double timerProgress = widget.request.remainingSeconds / 15.0;
    final Color timerColor = widget.request.remainingSeconds > 8
        ? primaryColor
        : widget.request.remainingSeconds > 4
        ? Colors.amber
        : Colors.red;

    return Container(
      margin: const EdgeInsets.only(bottom: 10),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20),
        boxShadow: [
          BoxShadow(
            color: widget.isTop
                ? primaryColor.withOpacity(0.25)
                : Colors.black.withOpacity(0.12),
            blurRadius: widget.isTop ? 20 : 10,
            offset: const Offset(0, 4),
          ),
        ],
        border: widget.isTop
            ? Border.all(color: primaryColor.withOpacity(0.4), width: 1.5)
            : null,
      ),
      child: Column(
        children: [
          ClipRRect(
            borderRadius:
            const BorderRadius.vertical(top: Radius.circular(20)),
            child: LinearProgressIndicator(
              value: timerProgress.clamp(0.0, 1.0),
              minHeight: 5,
              backgroundColor: Colors.grey.shade200,
              valueColor: AlwaysStoppedAnimation<Color>(timerColor),
            ),
          ),

          Padding(
            padding: const EdgeInsets.fromLTRB(16, 14, 16, 16),
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                // Header with user info
                Row(
                  children: [
                    CircleAvatar(
                      radius: 24,
                      backgroundColor: primaryColor.withOpacity(0.12),
                      backgroundImage: widget.request.userImage.isNotEmpty
                          ? NetworkImage(widget.request.userImage)
                          : null,
                      child: widget.request.userImage.isEmpty
                          ? Text(
                        widget.request.senderName.isNotEmpty
                            ? widget.request.senderName[0].toUpperCase()
                            : "?",
                        style: TextStyle(
                          fontWeight: FontWeight.bold,
                          fontSize: 20,
                          color: primaryColor,
                        ),
                      )
                          : null,
                    ),
                    const SizedBox(width: 12),

                    Expanded(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.start,
                        children: [
                          Text(
                            widget.request.senderName,
                            style: const TextStyle(
                              fontWeight: FontWeight.w700,
                              fontSize: 15,
                              color: Color(0xFF1A1A1A),
                            ),
                          ),
                          const SizedBox(height: 2),
                          // Row(
                          //   children: [
                          //     Icon(Icons.phone,
                          //         size: 12, color: Colors.grey.shade500),
                          //     const SizedBox(width: 4),
                          //     Text(
                          //       widget.request.senderPhone,
                          //       style: TextStyle(
                          //           fontSize: 12,
                          //           color: Colors.grey.shade600),
                          //     ),
                          //   ],
                          // ),
                        ],
                      ),
                    ),

                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(
                              horizontal: 10, vertical: 4),
                          decoration: BoxDecoration(
                            color: primaryColor,
                            borderRadius: BorderRadius.circular(8),
                          ),
                          child: Text(
                            "TJS ${widget.request.fare.toStringAsFixed(0)}",
                            style: const TextStyle(
                              fontWeight: FontWeight.bold,
                              fontSize: 16,
                              color: Colors.white,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Row(
                          children: [
                            Icon(Icons.timer,
                                size: 12, color: timerColor),
                            const SizedBox(width: 3),
                            Text(
                              "${widget.request.remainingSeconds}s",
                              style: TextStyle(
                                color: timerColor,
                                fontWeight: FontWeight.w700,
                                fontSize: 12,
                              ),
                            ),
                          ],
                        ),
                      ],
                    ),
                  ],
                ),

                const SizedBox(height: 14),

                // Route info
                Container(
                  padding: const EdgeInsets.all(12),
                  decoration: BoxDecoration(
                    color: const Color(0xFFF6F9F7),
                    borderRadius: BorderRadius.circular(14),
                  ),
                  child: Column(
                    children: [
                      _buildRouteRow(
                        icon: Icons.my_location,
                        iconColor: primaryColor,
                        label: "Pickup",
                        address: widget.request.pickup,
                      ),
                      Padding(
                        padding: const EdgeInsets.only(left: 10),
                        child: Row(
                          children: [
                            Container(
                              width: 1.5,
                              height: 20,
                              color: Colors.grey.shade300,
                            ),
                          ],
                        ),
                      ),
                      _buildRouteRow(
                        icon: Icons.location_on,
                        iconColor: Colors.red,
                        label: "Drop",
                        address: widget.request.drop,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 10),

                // Package info
                Row(
                  children: [
                    Icon(Icons.inventory_2,
                        size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      widget.request.packageSize.toUpperCase(),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600),
                    ),
                    const SizedBox(width: 12),
                    Icon(Icons.directions_car,
                        size: 12, color: Colors.grey.shade400),
                    const SizedBox(width: 4),
                    Text(
                      widget.request.tripType.toUpperCase(),
                      style: TextStyle(
                          fontSize: 11,
                          fontWeight: FontWeight.w600,
                          color: Colors.grey.shade600),
                    ),
                  ],
                ),

                const SizedBox(height: 10),

                // Quick offers section
                if (!_isSubmitting) ...[
                  const Text(
                    "Quick offers:",
                    style: TextStyle(
                      fontSize: 12,
                      fontWeight: FontWeight.w600,
                      color: Colors.black54,
                    ),
                  ),
                  const SizedBox(height: 8),
                  Row(
                    children: [
                      ...quickOffers.map((price) => Expanded(
                        child: Padding(
                          padding: const EdgeInsets.only(right: 6),
                          child: GestureDetector(
                            onTap: () => _sendOffer(price, "I can deliver it safely and on time."),
                            child: Container(
                              height: 40,
                              decoration: BoxDecoration(
                                color: primaryColor.withOpacity(0.1),
                                borderRadius: BorderRadius.circular(8),
                                border: Border.all(color: primaryColor.withOpacity(0.3)),
                              ),
                              child: Center(
                                child: Text(
                                  "TJS $price",
                                  style: TextStyle(
                                    fontWeight: FontWeight.bold,
                                    fontSize: 13,
                                    color: primaryColor,
                                  ),
                                ),
                              ),
                            ),
                          ),
                        ),
                      )),
                      const SizedBox(width: 6),
                      GestureDetector(
                        onTap: _showCustomOfferSheet,
                        child: Container(
                          width: 40,
                          height: 40,
                          decoration: BoxDecoration(
                            color: Colors.grey.shade100,
                            borderRadius: BorderRadius.circular(8),
                            border: Border.all(color: Colors.grey.shade300),
                          ),
                          child: Icon(Icons.edit,
                              color: primaryColor, size: 20),
                        ),
                      ),
                    ],
                  ),
                ],

                const SizedBox(height: 14),

                // Action buttons
                Row(
                  children: [
                    Expanded(
                      child: GestureDetector(
                        onTap: (_isSubmitting || _isDisposed) ? null : _removeRequest,
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            color: (_isSubmitting || _isDisposed)
                                ? Colors.grey.shade300
                                : const Color(0xFFF0F0F0),
                            borderRadius: BorderRadius.circular(14),
                          ),
                          child: Center(
                            child: Text(
                              "✕  Decline",
                              style: TextStyle(
                                fontWeight: FontWeight.w700,
                                fontSize: 14,
                                color: (_isSubmitting || _isDisposed)
                                    ? Colors.grey.shade500
                                    : const Color(0xFF666666),
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                    const SizedBox(width: 10),
                    Expanded(
                      flex: 2,
                      child: GestureDetector(
                        onTap: (_isSubmitting || _isDisposed) ? null : () => _sendOffer(
                          widget.request.fare.toString(),
                          "I can deliver it safely and on time.",
                        ),
                        child: Container(
                          height: 48,
                          decoration: BoxDecoration(
                            gradient: (_isSubmitting || _isDisposed)
                                ? null
                                : const LinearGradient(
                              colors: [Color(0xFF00A651), Color(0xFF007A3D)],
                            ),
                            color: (_isSubmitting || _isDisposed) ? Colors.grey : null,
                            borderRadius: BorderRadius.circular(14),
                            boxShadow: (_isSubmitting || _isDisposed)
                                ? []
                                : [
                              BoxShadow(
                                color: primaryColor.withOpacity(0.35),
                                blurRadius: 10,
                                offset: const Offset(0, 4),
                              ),
                            ],
                          ),
                          child: Center(
                            child: _isSubmitting
                                ? const SizedBox(
                              width: 20,
                              height: 20,
                              child: CircularProgressIndicator(
                                color: Colors.white,
                                strokeWidth: 2,
                              ),
                            )
                                : Text(
                              "✓  Accept TJS ${widget.request.fare.toStringAsFixed(0)}",
                              style: const TextStyle(
                                fontWeight: FontWeight.w800,
                                fontSize: 14,
                                color: Colors.white,
                              ),
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRouteRow({
    required IconData icon,
    required Color iconColor,
    required String label,
    required String address,
  }) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.center,
      children: [
        Icon(icon, size: 18, color: iconColor),
        const SizedBox(width: 10),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: TextStyle(
                    fontSize: 10,
                    color: Colors.grey.shade500,
                    fontWeight: FontWeight.w500),
              ),
              Text(
                address,
                style: const TextStyle(
                    fontSize: 13,
                    fontWeight: FontWeight.w600,
                    color: Color(0xFF222222)),
                maxLines: 1,
                overflow: TextOverflow.ellipsis,
              ),
            ],
          ),
        ),
      ],
    );
  }
}