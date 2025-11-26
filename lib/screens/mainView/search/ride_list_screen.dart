
import 'package:dotted_line/dotted_line.dart';
import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';
import 'package:provider/provider.dart';

import '../../../providers/translate_provider.dart';
import '../../../service/colors.dart';
import '../create/OrderDetailScreen.dart';
import '../mytrip/PassengerOrderDetailScreen.dart';
import 'controller/RideListController.dart';
import 'model/ride_model.dart';

class RideListScreen extends StatefulWidget {
  final Map<String, dynamic> rideData;

  const RideListScreen({super.key, required this.rideData});

  @override
  State<RideListScreen> createState() => _RideListScreenState();
}

class _RideListScreenState extends State<RideListScreen>
    with SingleTickerProviderStateMixin {
  late TabController _tabController;

  final double tabHeight = 48;
  final double pillRadius = 16;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
    Future.microtask(() {
      final provider = Provider.of<RideListProvide>(context, listen: false);
      provider.fetchTripList(
        widget.rideData['from'],
        widget.rideData['to'],
        widget.rideData['date'],
        widget.rideData['passengers'],
      );
      provider.fetchRiderequestlist(
        widget.rideData['from'],
        widget.rideData['to'],
        widget.rideData['date'],
        widget.rideData['passengers'],
      );
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

    return Scaffold(
      backgroundColor: Colors.white,
      appBar: _buildAppBar(cs),
      body: TabBarView(
        controller: _tabController,
        children: [
          _buildTripsList(cs), // Trips tab
          _buildPassengerRequestsList(cs), // Passengers tab
        ],
      ),
    );
  }

  PreferredSizeWidget _buildAppBar(ColorScheme cs) {
    final unselectedColor = cs.surfaceVariant.withOpacity(0.40);

    return AppBar(
      title: Text(context.watch<TranslateProvider>().t('txt_ride_list')),
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
              tabs: [Tab(text: context.watch<TranslateProvider>().t('txt_ride_trips')), Tab(text: context.watch<TranslateProvider>().t('txt_ride_passengers'))],
              onTap: (index) => setState(() => _tabController.index = index),
            ),
          ),
        ),
      ),
    );
  }

  // Trips Tab - Shows available trips with driver info
  Widget _buildTripsList(ColorScheme cs) {
    return Consumer<RideListProvide>(
      builder: (context, provider, child) {
        if (provider.isLoadingTrips) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.tripList.isEmpty) {
          return _buildEmptyState(context.watch<TranslateProvider>().t('txt_no_trips_available'), Icons.directions_car_outlined);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.tripList.length,
          itemBuilder: (context, index) {
            final ride = provider.tripList[index];
            return TripRideCard(
              ride: ride,
              onTap: () {
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => OrderDetailScreen(
                      ride: ride,
                      passengers: widget.rideData['passengers'],   // 👈 Pass seat count
                      services: widget.rideData['services'],       // 👈 Pass selected services if available
                      bookingType: "0", // ride

                    ),
                  ),
                );

              },
            );
          },
        );
      },
    );
  }

  // Passengers Tab - Shows ride requests
  Widget _buildPassengerRequestsList(ColorScheme cs) {
    return Consumer<RideListProvide>(
      builder: (context, provider, child) {
        if (provider.isLoadingRequests) {
          return const Center(child: CircularProgressIndicator());
        }

        if (provider.rideRequestList.isEmpty) {
          return _buildEmptyState(context.watch<TranslateProvider>().t('txt_no_passenger_request'), Icons.person_outline);
        }

        return ListView.builder(
          padding: const EdgeInsets.all(16),
          itemCount: provider.rideRequestList.length,
          itemBuilder: (context, index) {
            final request = provider.rideRequestList[index];
            return PassengerRequestCard(
              request: request,
              onTap: () {
                // Navigate to the same OrderDetailScreen and send request data
                Navigator.push(
                  context,
                  MaterialPageRoute(
                    builder: (_) => PassengerOrderDetailScreen(
                      request: request, // ✅ pass as 'request', not 'ride'
                    ),
                  ),
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
            context.watch<TranslateProvider>().t('txt_trying_adjust_search'),
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

// ---------------- TRIP RIDE CARD (For Trips Tab) -----------------
class TripRideCard extends StatelessWidget {
  final VoidCallback onTap;
  final RideDataModel ride;

  const TripRideCard({
    super.key,
    required this.onTap,
    required this.ride,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                _DriverInfo(ride),
                const SizedBox(height: 12),
                _RideLocations(ride),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- PASSENGER REQUEST CARD (For Passengers Tab) -----------------
class PassengerRequestCard extends StatelessWidget {
  final VoidCallback onTap;
  final RideRequestModel request;

  const PassengerRequestCard({
    super.key,
    required this.onTap,
    required this.request,
  });
  int _calculateAge(String dobString) {
    try {
      DateTime dob;
      if (dobString.contains('-')) {
        // dd-MM-yyyy
        final parts = dobString.split('-');
        dob = DateTime(int.parse(parts[2]), int.parse(parts[1]), int.parse(parts[0]));
      } else {
        dob = DateTime.parse(dobString);
      }

      final today = DateTime.now();
      int age = today.year - dob.year;
      if (today.month < dob.month || (today.month == dob.month && today.day < dob.day)) {
        age--;
      }
      return age;
    } catch (e) {
      return 0;
    }
  }


  @override
  Widget build(BuildContext context) {
    final imageUrl = request.image != null
        ? "https://qadampayk.com/assets/profile_image/${request.image}" // Replace with your actual base URL
        : "https://images.rawpixel.com/image_png_800/cHJpdmF0ZS9sci9pbWFnZXMvd2Vic2l0ZS8yMDI0LTAxL3Jhd3BpeGVsb2ZmaWNlMTFfcGhvdG9fb2ZfYWZyaWNhbl9hbWVyaWNhbl9tYW5faW5fYnVzaW5lc3Nfc3VpdF9iYmEzZjA3MS1iN2JkLTQ3MjctODA4MC1hYjJmOTIxOGY1OTMucG5n.png";

    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 6),
      child: InkWell(
        onTap: onTap,
        child: Card(
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(15)),
          elevation: 2,
          child: Padding(
            padding: const EdgeInsets.all(12),
            child: Column(
              children: [
                // User Info
                Row(
                  children: [
                    SizedBox(
                      width: 55, // slightly bigger to allow space for the badge
                      height: 55,
                      child: Stack(
                        clipBehavior: Clip.none, // 👈 important so badge is not clipped
                        children: [
                          // Main profile image
                          CircleAvatar(
                            radius: 25,
                            backgroundImage: NetworkImage(imageUrl),
                          ),

                          // Verify badge (only if verified)
                          if (request.idVerified.toString() == "1")
                            Positioned(
                              bottom: -2,  // closer to the border
                              right: -10,
                              child: Image.asset(
                                "assets/images/verify_user.png",
                                height: 30,  // balanced size for radius 25
                                width: 30,
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
                            request.name ?? "Passenger",
                            style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                          ),
                          // const SizedBox(height: 4),
                          Text(
                            "${context.watch<TranslateProvider>().t('txt_age')} ${_calculateAge(request.dob ?? DateTime.now().toIso8601String())}",
                            style: const TextStyle(color: Colors.grey, fontSize: 12),
                          ),

                          Row(
                            children: [
                              const Icon(Icons.star, color: Colors.yellow, size: 16),
                              const SizedBox(width: 4),
                              const Text("4.8", style: TextStyle(color: Colors.grey)),
                              const SizedBox(width: 16),
                              Text(
                                "${context.watch<TranslateProvider>().t('txt_seats')} ${request.numberOfSeats ?? 1}",
                                style: const TextStyle(color: Colors.grey, fontSize: 12),
                              ),
                            ],
                          )
                        ],
                      ),
                    ),
                    Column(
                      crossAxisAlignment: CrossAxisAlignment.end,
                      children: [
                        Container(
                          padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 4),
                          decoration: BoxDecoration(
                            color: request.status == 'pending'
                                ? Colors.orange.shade100
                                : Colors.green.shade100,
                            borderRadius: BorderRadius.circular(12),
                          ),
                          child: Text(
                            request.status?.toUpperCase() ?? 'PENDING',
                            style: TextStyle(
                              fontSize: 10,
                              fontWeight: FontWeight.bold,
                              color: request.status == 'pending'
                                  ? Colors.orange.shade800
                                  : Colors.green.shade800,
                            ),
                          ),
                        ),
                        const SizedBox(height: 4),
                        Text(
                          request.rideDate ?? "Date: N/A",
                          style: const TextStyle(color: Colors.grey, fontSize: 11),
                        ),
                      ],
                    ),
                  ],
                ),
                const SizedBox(height: 12),
                // Services Row
                if (request.services != null && request.services!.isNotEmpty)
                  Container(
                    padding: const EdgeInsets.all(8),
                    decoration: BoxDecoration(
                      color: Colors.grey.shade50,
                      borderRadius: BorderRadius.circular(8),
                    ),
                    child: Row(
                      children: [
                        Text(context.watch<TranslateProvider>().t('txt_ride_services'), style: TextStyle(fontWeight: FontWeight.w500)),
                        Expanded(
                          child: Wrap(
                            spacing: 4,
                            children: request.services!.map((service) {
                              return Chip(
                                label: Text(service.trim()),
                                backgroundColor: Colors.blue.shade50,
                                labelStyle: const TextStyle(fontSize: 10),
                                materialTapTargetSize: MaterialTapTargetSize.shrinkWrap,
                                visualDensity: VisualDensity.compact,
                              );
                            }).toList(),
                          ),
                        ),
                      ],
                    ),
                  ),
                const SizedBox(height: 8),
                // Location Info
                _RequestRideLocations(request),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

// ---------------- DRIVER INFO (For Trips Tab) -----------------
class _DriverInfo extends StatelessWidget {
  final RideDataModel ride;
  const _DriverInfo(this.ride, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 200,
      decoration: BoxDecoration(
        border: Border.all(color: Colors.grey.shade300),
        borderRadius: BorderRadius.circular(10),
      ),
      padding: const EdgeInsets.all(16),
      child: Column(
        children: [
          Row(
            children: [
              SizedBox(
                width: 60,
                height: 60,
                child: Stack(
                  children: [
                    // Main profile image
                    CircleAvatar(
                      radius: 30,
                      backgroundImage: NetworkImage(
                        "https://qadampayk.com/assets/profile_image/${ride.driverImage}" ?? "https://images.rawpixel.com/image_png_800/cHJpdmF0ZS9sci9pbWFnZXMvd2Vic2l0ZS8yMDI0LTAxL3Jhd3BpeGVsb2ZmaWNlMTFfcGhvdG9fb2ZfYWZyaWNhbl9hbWVyaWNhbl9tYW5faW5fYnVzaW5lc3Nfc3VpdF9iYmEzZjA3MS1iN2JkLTQ3MjctODA4MC1hYjJmOTIxOGY1OTMucG5n.png",
                      ),
                    ),

                    // Positioned verify badge
                if(ride.driverStatus.toString() =="verified" )    Positioned(
                      bottom: -10,
                      right: -8,
                      child: Image.asset(
                        "assets/images/verify_user.png",
                        height: 35,
                        width: 35,
                      ),
                    ),
                  ],
                ),
              ),

              // Image.asset("assets/images/verify_user.png",height: 25,),
// Text(ride.driverStatus.toString()),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      ride.driverName ?? "Driver Name",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 16),
                    ),
                    const SizedBox(height: 4),
                    Row(mainAxisAlignment: MainAxisAlignment.start,
                      children: [
                        Text("${ride.driverRating }",
                            style: const TextStyle(color: Colors.grey)),
                        Icon(Icons.star,color: Colors.yellow,),
                        const SizedBox(width: 4),
                        // const Text("|", style: TextStyle(color: Colors.grey)),
                        // const SizedBox(width: 4),
                        // const Icon(Icons.star, color: Colors.yellow, size: 16),
                        // const SizedBox(width: 2),
                        // Text(ride.driverRating ?? "4.8",
                        //     style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                children: [
                  Text("${ride.price ?? 243} c",
                      style: const TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.bold,
                          color: AppTheme.seedPrimary)),
                  const SizedBox(height: 4),
                  Row(
                    children: List.generate(
                      ride.numberOfSeats ?? 4,
                          (index) => Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 2.0),
                        child: Icon(Icons.person, color: Colors.grey.shade400, size: 16),
                      ),
                    ),
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 12),
          const RideDivider(),
          const SizedBox(height: 10),
          Row(
            children: [
              CircleAvatar(
                radius: 25,
                backgroundImage: NetworkImage(
                  ride.vehicleImage != null
                      ? "https://qadampayk.com/assets/vehicle_image/${ride.vehicleImage}"
                      : "https://suritours.in/nimg/taxi-service-in-delhi.jpg",
                ),
              ),
              const SizedBox(width: 6),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text("${context.watch<TranslateProvider>().t('txt_ride_id')} ${ride.numberPlate ?? '20435698'}",overflow: TextOverflow.ellipsis,
                        style: const TextStyle(fontWeight: FontWeight.bold)),
                    // const SizedBox(height: 4),
                    Row(
                      children: [
                        Text("${ride.brand ?? 'Honda'}\n ${ride.model ?? 'Car'}",
                            style: const TextStyle(color: Colors.grey,fontSize: 12)),
                        // const SizedBox(width: 4),
                        // const Text("|", style: TextStyle(color: Colors.grey)),
                        // const SizedBox(width: 4),
                        // const Icon(Icons.star, color: Colors.yellow, size: 16),
                        // const SizedBox(width: 2),
                        // Text(ride.driverRating ?? "4.8",
                        //     style: const TextStyle(color: Colors.grey)),
                      ],
                    ),
                  ],
                ),
              ),
              Column(
                crossAxisAlignment: CrossAxisAlignment.end,
                children: [
                  Text("${ride.rideDate ?? '13 Sep 25'}\n${ride.rideTime ?? '10:45 AM'}",
                      style: const TextStyle(fontWeight: FontWeight.bold, fontSize: 10)),
                  const SizedBox(height: 8),
                  buildRideServicesRow(ride.services),
                ],
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget buildRideServicesRow(List<ServiceModel>? services) {
    if (services == null || services.isEmpty) {
      return const Row(
        children: [Icon(Icons.info, size: 16, color: Colors.grey)],
      );
    }

    int half = (services.length / 2).ceil();
    List<ServiceModel> topRow = services.take(half).toList();
    List<ServiceModel> bottomRow = services.skip(half).toList();

    Widget buildIcon(ServiceModel service) {
      return Padding(
        padding: const EdgeInsets.only(right: 0, bottom: 0),
        child: SizedBox(
          width: 15,
          height: 15,
          child: service.serviceImage != null && service.serviceImage!.isNotEmpty
              ? SvgPicture.network(
            "https://qadampayk.com/assets/services_images/${service.serviceImage!}",
            width: 12,
            height: 12,
            fit: BoxFit.contain,
            placeholderBuilder: (context) => const SizedBox(
              width: 12,
              height: 12,
              child: CircularProgressIndicator(strokeWidth: 1),
            ),
            errorBuilder: (ctx, _, __) => const Icon(Icons.miscellaneous_services, size: 18),
          )
              : const Icon(Icons.miscellaneous_services, size: 18),
        ),
      );
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(children: topRow.map((s) => buildIcon(s)).toList()),
        if (bottomRow.isNotEmpty) Row(children: bottomRow.map((s) => buildIcon(s)).toList()),
      ],
    );
  }
}

// ---------------- RIDE LOCATIONS (For Trips) -----------------
class _RideLocations extends StatelessWidget {
  final RideDataModel ride;
  const _RideLocations(this.ride, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 120,
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
          const SizedBox(width: 30),
          Expanded(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(
                  ride.pickupLocation ?? "Pickup Location",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 16),
                const RideDivider(),
                const SizedBox(height: 16),
                Text(
                  ride.destination ?? "Destination",
                  style: const TextStyle(fontWeight: FontWeight.bold),
                ),
                const SizedBox(height: 8),
                // Row(
                //   children: [
                //     Text(
                //       ride.rideDate ?? "Date: N/A",
                //       style: const TextStyle(color: Colors.grey, fontSize: 12),
                //     ),
                //     const SizedBox(width: 8),
                //     Text(
                //       ride.rideTime ?? "Time: N/A",
                //       style: const TextStyle(color: Colors.grey, fontSize: 12),
                //     ),
                //   ],
                // ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}

// ---------------- REQUEST RIDE LOCATIONS (For Passenger Requests) -----------------
class _RequestRideLocations extends StatelessWidget {
  final RideRequestModel request;
  const _RequestRideLocations(this.request, {super.key});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 90,
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
                lineLength: 25,
              ),
              const SizedBox(height: 4),
              SvgPicture.asset(
                "assets/images/blue_icon.svg",
                height: 15,
              ),            ],
          ),
          const SizedBox(width: 30),
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
          Column(
            crossAxisAlignment: CrossAxisAlignment.end,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              // Text(
              //   request.rideDate ?? "Date: N/A",
              //   style: const TextStyle(color: Colors.grey, fontSize: 11),
              // ),
              // Text(
              //   request.rideTime ?? "Time: N/A",
              //   style: const TextStyle(color: Colors.grey, fontSize: 11),
              // ),
            ],
          ),
        ],
      ),
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