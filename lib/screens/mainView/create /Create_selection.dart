// lib/features/onboarding/welcome_screen.dart
import 'package:flutter/material.dart';

import 'Add_vehical.dart';
import 'Passenge_request.dart';
import 'Ride_Screen.dart';
import 'VehicleStorage.dart';

class SelectCrationScreen extends StatelessWidget {
  const SelectCrationScreen({super.key});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    final cs = theme.colorScheme;

    return Scaffold(
      backgroundColor: theme.scaffoldBackgroundColor,
      body: SafeArea(
        child: LayoutBuilder(
          builder: (context, constraints) {
            return SingleChildScrollView(
              padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 16),
              child: ConstrainedBox(
                constraints: BoxConstraints(
                  minHeight: constraints.maxHeight - 32,
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 16),
                    // Replace with your actual asset file, e.g. assets/images/welcome_car.png
                    AspectRatio(
                      aspectRatio: 20 / 18,
                      child: ClipRRect(
                        borderRadius: BorderRadius.circular(20),
                        child: Image.asset(
                          'assets/images/Welcome_Screen.png',
                          fit: BoxFit.cover,
                        ),
                      ),
                    ),
                    const SizedBox(height: 32),
                    Text(
                      'Welcome',
                      style: theme.textTheme.headlineMedium?.copyWith(
                        color: theme.colorScheme.onBackground,
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      'Have a better sharing experience\nwith Qadam Payk',
                      style: theme.textTheme.bodyMedium?.copyWith(
                        color: theme.colorScheme.onSurface.withOpacity(0.7),
                      ),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 70),
                    Row(
                      children: [
                        Expanded(
                          child: ElevatedButton(
                            onPressed: () {
                              Navigator.push(context, MaterialPageRoute(builder: (context)=>PassengerRequestScreen()));
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('I am a Passenger'),
                          ),
                        ),
                        const SizedBox(width: 16),
                        Expanded(
                          child: ElevatedButton(
                              onPressed: () async {
                                Navigator.push(
                                  context,
                                  MaterialPageRoute(builder: (context) => RideScreen()),
                                );
                                 // final vehicles = VehicleStorage.getAll();

                                // if (vehicles.isEmpty) {
                                //   // 🚗 No vehicle saved → go to VehicleScreen first
                                //   final addedVehicle = await Navigator.push(
                                //     context,
                                //     MaterialPageRoute(builder: (context) => const VehicleScreen()),
                                //   );
                                //
                                //   // If user added a vehicle, then navigate to RideScreen
                                //   if (addedVehicle != null) {
                                //     Navigator.push(
                                //       context,
                                //       MaterialPageRoute(builder: (context) => RideScreen()),
                                //     );
                                //   }
                                // } else {
                                //   // ✅ Already has vehicles → go directly to RideScreen
                                //   Navigator.push(
                                //     context,
                                //     MaterialPageRoute(builder: (context) => RideScreen()),
                                //   );
                                // }
                            },
                            style: ElevatedButton.styleFrom(
                              backgroundColor: cs.primary,
                              foregroundColor: cs.onPrimary,
                              minimumSize: const Size.fromHeight(54),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(14),
                              ),
                            ),
                            child: const Text('I am a Driver'),
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 12),
                  ],
                ),
              ),
            );
          },
        ),
      ),
    );
  }
}
