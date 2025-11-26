import 'package:bla_bla_car/providers/translate_provider.dart';
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:fluttertoast/fluttertoast.dart';
import 'package:provider/provider.dart';

import '../../../service/colors.dart';
import '../../../service/local_cache.dart';
import '../../auth/SignInScreen.dart';
import '../create/OrderDetailScreen.dart';
import '../mytrip/PassengerOrderDetailScreen.dart';
import '../provide/ChatProvider.dart';
import 'controller/RideListController.dart';
import 'model/ride_model.dart';

class ParcelListScreen extends StatefulWidget {
  final Map<String, dynamic> parcelData;

  const ParcelListScreen({super.key, required this.parcelData});

  @override
  State<ParcelListScreen> createState() => _ParcelListScreenState();
}

class _ParcelListScreenState extends State<ParcelListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final double tabHeight = 48;
  final double pillRadius = 16;

  @override
  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);

    WidgetsBinding.instance.addPostFrameCallback((_) {
      final provider = Provider.of<RideListProvide>(context, listen: false);

      final pickup = widget.parcelData['pickup'] ?? '';
      final destination = widget.parcelData['drop'] ?? '';
      final date = widget.parcelData['date'] ?? '';
      final seats = widget.parcelData['passengers'] ?? 1;

      // 🚀 Call all 3 APIs
      provider.fetchTripList(pickup, destination, date, seats);
      provider.fetchParcelequestlist(pickup, destination, date, seats);
      // provider.fetchRiderequestlist(pickup, destination, date, seats);
    });
  }


  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final cs = Theme.of(context).colorScheme;
    final unselectedColor = cs.surfaceVariant.withOpacity(0.4);
    final translate = context.watch<TranslateProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: AppBar(
        title: Text(context.watch<TranslateProvider>().t('txt_parcel_request')),
        centerTitle: true,
        elevation: 0,
        backgroundColor: Colors.transparent,
        bottom: PreferredSize(
          preferredSize: Size.fromHeight(tabHeight + 24),
          child: Padding(
            padding: const EdgeInsets.symmetric(horizontal: 30, vertical: 8),
            child: Container(
              height: tabHeight,
              decoration: BoxDecoration(
                color: unselectedColor,
                borderRadius: BorderRadius.circular(pillRadius),
              ),
              child: TabBar(
                controller: _tabController,
                indicator: BoxDecoration(
                  color: AppTheme.seedPrimary,
                  borderRadius: BorderRadius.circular(pillRadius - 2),
                ),
                indicatorSize: TabBarIndicatorSize.tab,
                overlayColor: MaterialStateProperty.all(Colors.transparent),
                labelColor: Colors.white,
                unselectedLabelColor: Colors.grey,
                labelStyle: const TextStyle(fontSize: 12, fontWeight: FontWeight.bold),
                unselectedLabelStyle: const TextStyle(fontSize: 14),
                tabs: [
                  Tab(text: context.watch<TranslateProvider>().t('txt_parcel_drivers')),
                  Tab(text: context.watch<TranslateProvider>().t('txt_parcel_senders')),
                ],
                onTap: (index) => setState(() => _tabController.index = index),
              ),
            ),
          ),
        ),
      ),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildDriversList(translate), // Drivers tab - show trips that accept parcels
          _buildSendersList(translate), // Senders tab - show parcel requests
        ],
      ),
    );
  }

  // Drivers Tab - Shows trips that accept parcels (acceptParcel == true)
  Widget _buildDriversList(TranslateProvider translate) {
    return Consumer<RideListProvide>(
      builder: (context, provider, child) {
        if (provider.isLoadingTrips) {
          return const Center(child: CircularProgressIndicator());
        }

        // Filter trips that accept parcels
        final parcelAcceptingTrips = provider.tripList
            .where((trip) => trip.acceptParcel == true)
            .toList();

        if (parcelAcceptingTrips.isEmpty) {
          return _buildEmptyState("${translate.t('txt_no_driver_accepting')}", Icons.local_shipping_outlined);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: parcelAcceptingTrips.length,
          itemBuilder: (context, index) {
            final trip = parcelAcceptingTrips[index];
            return DriverParcelCard(
              trip: trip,
              onTap: () {
                print( widget.parcelData['passengers']);
                  // Navigator.push(
                  //   context,
                  //   MaterialPageRoute(
                  //     builder: (_) => OrderDetailScreen(
                  //       ride: trip,
                  //       parcelData: widget.parcelData, // <-- Pass the parcel data here
                  //       bookingType: "1", // parcel booking
                  //     ),
                  //   ),
                  // );

                // Navigator.push(
                //   context,
                //   MaterialPageRoute(
                //     builder: (_) => OrderDetailScreen(
                //       ride: trip,
                //       passengers: widget.parcelData['passengers'] ?? 1,   // Pass number of seats
                //       services: widget.parcelData['services'] ?? [],      // Pass services if any
                //       bookingType: "1",                                   // Parcel booking
                //     ),
                //   ),
                // );





                // Navigate to parcel booking with this driver
                // ScaffoldMessenger.of(context).showSnackBar(
                //   SnackBar(content: Text('${translate.t('txt_book_parcel_with')} ${trip.driverName ?? 'Driver'}')),
                // );
              },
            );
          },
        );
      },
    );
  }

  // Senders Tab - Shows parcel requests
  Widget _buildSendersList(TranslateProvider translate) {
    return Consumer<RideListProvide>(
      builder: (context, provider, child) {
        if (provider.isLoadingParcels) {   // ✅ use parcel loading flag
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.parcelRequestList.isEmpty) {
          return _buildEmptyState(context.watch<TranslateProvider>().t('txt_no_parcel_request'), Icons.person_outline);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.parcelRequestList.length,
          itemBuilder: (context, index) {
            final request = provider.parcelRequestList[index];
            return SenderParcelCard(
              request: request,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PassengerOrderDetailScreen(
                      request: request, // ✅ pass as 'request', not 'ride'
                    ),
                  ),
                );
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(content: Text('${context.watch<TranslateProvider>().t('txt_parcel_request_from')} ${request.name ?? 'Sender'}')),
                );
              },
            );
          },
        );
      },
    );
  }

  Widget _buildEmptyState(String message, IconData icon) {
    return Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          Icon(icon, size: 80, color: Colors.grey.shade400),
          const SizedBox(height: 16),
          Text(
            message,
            style: TextStyle(
              fontSize: 18,
              fontWeight: FontWeight.w600,
              color: Colors.grey.shade600,
            ),
          ),
          const SizedBox(height: 8),
          Text(
            context.watch<TranslateProvider>().t('txt_adjusting_your_search'),
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade500,
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- DRIVER PARCEL CARD (For Drivers Tab) -----------------
class DriverParcelCard extends StatelessWidget {
  final VoidCallback onTap;
  final RideDataModel trip;

  const DriverParcelCard({
    super.key,
    required this.onTap,
    required this.trip,
  });

  @override
  Widget build(BuildContext context) {
    final translate = context.watch<TranslateProvider>();

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _DriverInfo(trip),
                const SizedBox(height: 12),
                _ParcelRideLocations(trip),
                const SizedBox(height: 12),
                _ParcelDateTime(trip),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- SENDER PARCEL CARD (For Senders Tab) -----------------
class SenderParcelCard extends StatelessWidget {
  final VoidCallback onTap;
  final RideRequestModel request;

  const SenderParcelCard({
    super.key,
    required this.onTap,
    required this.request,
  });

  @override
  Widget build(BuildContext context) {
    final imageUrl = request.image != null
        ? "https://qadampayk.com/assets/profile_image/${request.image}"
        : "https://images.unsplash.com/photo-1595152772835-219674b2a8a6";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(15),
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _SenderInfo(request, imageUrl),
                const SizedBox(height: 12),
                _SenderParcelLocations(request),
                const SizedBox(height: 12),
                _SenderParcelDateTime(request),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- DRIVER INFO (For Drivers Tab) -----------------
class _DriverInfo extends StatelessWidget {
  final RideDataModel trip;
  const _DriverInfo(this.trip);

  @override
  Widget build(BuildContext context) {
    final translate = context.watch<TranslateProvider>();

    return Container(
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(12),
      ),
      padding: const EdgeInsets.all(12),
      child: Column(
        children: [
          Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(
                    "https://qadampayk.com/assets/profile_image/${trip.driverImage}" ?? "https://images.rawpixel.com/image_png_800/cHJpdmF0ZS9sci9pbWFnZXMvd2Vic2l0ZS8yMDI0LTAxL3Jhd3BpeGVsb2ZmaWNlMTFfcGhvdG9fb2ZfYWZyaWNhbl9hbWVyaWNhbl9tYW5faW5fYnVzaW5lc3Nfc3VpdF9iYmEzZjA3MS1iN2JkLTQ3MjctODA4MC1hYjJmOTIxOGY1OTMucG5n.png",
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                trip.driverName ?? "Driver Name",
                      style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
                    ),
                    const SizedBox(height: 4),
                    Row(
                      children: [
                        const Icon(Icons.local_shipping, size: 16, color: Colors.green),
                        const SizedBox(width: 4),
                        Text(translate.t('txt_accept_parcels'), style: TextStyle(color: Colors.green, fontSize: 12)),
                        const SizedBox(width: 8),
                        // const Icon(Icons.star, color: Colors.yellow, size: 16),
                        // const SizedBox(width: 2),
                        // Text(trip.driverRating ?? "4.8", style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                    Text(
                      "${translate.t('txt_available_seats')} ${trip.numberOfSeats ?? 1}",
                      style: const TextStyle(fontSize: 12, color: Colors.grey),
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [

                  InkWell(onTap: ()async {
                    print(trip.driverId);

                    final token = await LocalCache.getToken();
                    if (token == null || token.isEmpty) {
                      Fluttertoast.showToast(
                        msg: context.read<TranslateProvider>().t('txt_login_first'),
                        backgroundColor: Colors.red,
                        textColor: Colors.white,
                      );
                      Navigator.push(
                        context,
                        MaterialPageRoute(builder: (_) => const PhoneNumberScreen()),
                      );
                      return;
                    }

                    // Use ChatProvider to start chat
                    final chatProvider = Provider.of<ChatProvider>(context, listen: false);
                    await chatProvider.startChat(
                      context: context,
                      otherUserId: trip.driverId!,
                      userName: trip.driverName ?? 'Driver',
                    );


                  }, child: SvgPicture.asset('assets/images/chat.svg'))
                  // const SizedBox(height: 4),
                  // Text(
                  //   "SM${trip.price ?? 0}",
                  //   style: const TextStyle(
                  //     fontWeight: FontWeight.bold,
                  //     color: AppTheme.seedPrimary,
                  //     fontSize: 16,
                  //   ),
                  // ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const RideDivider(),
          const SizedBox(height: 12),
          Row(
            children: [
              ClipRRect(
                borderRadius: BorderRadius.circular(8),
                child: trip.vehicleImage != null
                    ? Image.network(
                  "https://qadampayk.com/assets/vehicle_image/${trip.vehicleImage}",
                  width: 80,
                  height: 60,
                  fit: BoxFit.cover,
                  errorBuilder: (context, error, stackTrace) => Container(
                    width: 80,
                    height: 60,
                    color: Colors.grey.shade200,
                    child: const Icon(Icons.directions_car, color: Colors.grey),
                  ),
                )
                    : Container(
                  width: 80,
                  height: 60,
                  color: Colors.grey.shade200,
                  child: const Icon(Icons.directions_car, color: Colors.grey),
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      "${trip.brand ?? 'Honda'} ${trip.model ?? 'City'} 2022",
                      style: const TextStyle(fontSize: 14, color: Colors.black87),
                    ),
                    const SizedBox(height: 2),
                    Text(
                      "${translate.t('txt_plate_no')} ${trip.numberPlate ?? 'MP04AB1234'}",
                      style: const TextStyle(fontSize: 14, color: Colors.grey),
                    ),
                  ],
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

// ---------------- SENDER INFO (For Senders Tab) -----------------
class _SenderInfo extends StatelessWidget {
  final RideRequestModel request;
  final String imageUrl;
  const _SenderInfo(this.request, this.imageUrl);

  @override
  Widget build(BuildContext context) {
    return Row(
      children: [
        // CircleAvatar(
        //   radius: 28,
        //   backgroundImage: NetworkImage(imageUrl),
        // ),
        SizedBox(
          width: 60,
          height: 60,
          child: Stack(
            clipBehavior: Clip.none,
            children: [
              CircleAvatar(
                radius: 28,
                backgroundImage: NetworkImage(imageUrl),
              ),

              // ✅ Verify badge
             if(request.idVerified == 0) Positioned(
                bottom:0,
                right: -5,
                child: Container(
                  width: 25,
                  height: 25,
                  decoration: BoxDecoration(
                    color: Colors.white, // background for contrast
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.white, width: 2),
                  ),
                  padding: const EdgeInsets.all(2),
                  child: ClipOval(
                    child: Image.asset(
                      "assets/images/verify_user.png",
                      fit: BoxFit.cover,
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),

        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                request.displayName,
                style: const TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              ),
              Text(
                "${context.watch<TranslateProvider>().t('txt_parcel_type')} ${request.parcelDetails ?? 'Medium'}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
              Text(
                "${context.watch<TranslateProvider>().t('txt_contact')} ${request.phoneNumber ?? 'N/A'}",
                style: const TextStyle(fontSize: 12, color: Colors.grey),
              ),
            ],
          ),
        ),
        Container(
          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
          decoration: BoxDecoration(
            color: request.isPending ? Colors.orange.shade100 : Colors.green.shade100,
            borderRadius: BorderRadius.circular(12),
          ),
          child: Text(
            request.status?.toUpperCase() ?? 'PENDING',
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.bold,
              color: request.isPending ? Colors.orange.shade800 : Colors.green.shade800,
            ),
          ),
        ),
      ],
    );
  }
}

// ---------------- PARCEL RIDE LOCATIONS (For Drivers) -----------------
class _ParcelRideLocations extends StatelessWidget {
  final RideDataModel trip;
  const _ParcelRideLocations(this.trip);

  @override
  Widget build(BuildContext context) {
    final translate = context.watch<TranslateProvider>();

    return Container(
      height: 130,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                "assets/images/red_icon.svg",
                height: 15,
              ),
              const SizedBox(height: 4),
              const DottedLine(
                dashLength: 3,
                dashGapLength: 3,
                lineThickness: 2,
                dashColor: Colors.grey,
                direction: Axis.vertical,
                lineLength: 40,
              ),
              const SizedBox(height: 4),
              SvgPicture.asset(
                "assets/images/blue_icon.svg",
                height: 15,
              ),            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  trip.pickupLocation ?? "Pickup Location",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const RideDivider(),
                const SizedBox(height: 8),
                Text(
                  trip.destination ?? "Destination",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- SENDER PARCEL LOCATIONS (For Senders) -----------------
class _SenderParcelLocations extends StatelessWidget {
  final RideRequestModel request;
  const _SenderParcelLocations(this.request);

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 130,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SvgPicture.asset(
                "assets/images/red_icon.svg",
                height: 15,
              ),              const SizedBox(height: 4),
              const DottedLine(
                dashLength: 3,
                dashGapLength: 3,
                lineThickness: 2,
                dashColor: Colors.grey,
                direction: Axis.vertical,
                lineLength: 40,
              ),
              const SizedBox(height: 4),
              SvgPicture.asset(
                "assets/images/blue_icon.svg",
                height: 15,
              ),            ],
          ),
          const SizedBox(width: 8),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  request.pickupLocation ?? "Pickup Location",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                const RideDivider(),
                const SizedBox(height: 8),
                Text(
                  request.destination ?? "Destination",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- PARCEL DATE & TIME (For Drivers) -----------------
class _ParcelDateTime extends StatelessWidget {
  final RideDataModel trip;
  const _ParcelDateTime(this.trip);

  @override
  Widget build(BuildContext context) {
    final translate = context.watch<TranslateProvider>();

    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "${translate.t('txt_parcel_date')} ${trip.rideDate ?? '21 Sep 2025'}",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          "${translate.t('txt_parcel_time')} ${trip.rideTime ?? '10:45 AM'}",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

// ---------------- SENDER PARCEL DATE & TIME (For Senders) -----------------
class _SenderParcelDateTime extends StatelessWidget {
  final RideRequestModel request;
  const _SenderParcelDateTime(this.request);

  @override
  Widget build(BuildContext context) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          "${context.watch<TranslateProvider>().t('txt_parcel_date')} ${request.rideDate ?? '21 Sep 2025'}",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
        Text(
          "${context.watch<TranslateProvider>().t('txt_parcel_time')} ${request.rideTime ?? '10:45 AM'}",
          style: const TextStyle(fontSize: 12, color: Colors.grey),
        ),
      ],
    );
  }
}

// ---------------- DOT DIVIDER -----------------
class RideDivider extends StatelessWidget {
  final double height;
  final double dashWidth;
  final double dashSpacing;
  final Color color;

  const RideDivider({
    super.key,
    this.height = 1,
    this.dashWidth = 4,
    this.dashSpacing = 4,
    this.color = Colors.grey,
  });

  @override
  Widget build(BuildContext context) {
    return LayoutBuilder(
      builder: (context, constraints) {
        final dashCount = (constraints.maxWidth / (dashWidth + dashSpacing)).floor();
        return Row(
          mainAxisAlignment: MainAxisAlignment.spaceBetween,
          children: List.generate(
            dashCount,
                (_) => Container(width: dashWidth, height: height, color: color),
          ),
        );
      },
    );
  }
}