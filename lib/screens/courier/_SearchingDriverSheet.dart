import 'package:flutter/material.dart';
class _SearchingDriverSheet extends StatefulWidget {
  const _SearchingDriverSheet();

  @override
  State<_SearchingDriverSheet> createState() => _SearchingDriverSheetState();
}

class _SearchingDriverSheetState extends State<_SearchingDriverSheet>
    with SingleTickerProviderStateMixin {
  late AnimationController _controller;
  late Animation<double> _animation;

  @override
  void initState() {
    super.initState();

    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 2),
    )..repeat(reverse: true);

    _animation = Tween<double>(begin: 0.8, end: 1.2).animate(
      CurvedAnimation(parent: _controller, curve: Curves.easeInOut),
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  void _goToListScreen() {
    Navigator.pop(context); // Close bottom sheet
    Navigator.pushNamed(context, '/orderList'); // Change to your route
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.all(20),
      decoration: const BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.vertical(top: Radius.circular(25)),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [

          /// Drag Handle
          Container(
            height: 5,
            width: 60,
            decoration: BoxDecoration(
              color: Colors.grey.shade300,
              borderRadius: BorderRadius.circular(10),
            ),
          ),

          const SizedBox(height: 25),

          /// Animated Searching Icon
          AnimatedBuilder(
            animation: _animation,
            builder: (context, child) {
              return Transform.scale(
                scale: _animation.value,
                child: Container(
                  height: 90,
                  width: 90,
                  decoration: BoxDecoration(
                    color: Colors.green.withOpacity(0.1),
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.local_shipping_rounded,
                    size: 45,
                    color: Color(0xFF008955),
                  ),
                ),
              );
            },
          ),

          const SizedBox(height: 20),

          /// Title
          const Text(
            "Searching Best Driver",
            style: TextStyle(
              fontSize: 20,
              fontWeight: FontWeight.bold,
            ),
          ),

          const SizedBox(height: 10),

          /// Subtitle
          Text(
            "We are finding the nearest available driver\nfor your courier request.",
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 14,
              color: Colors.grey.shade600,
            ),
          ),

          const SizedBox(height: 25),

          /// Loading Indicator
          const CircularProgressIndicator(
            color: Color(0xFF008955),
          ),

          const SizedBox(height: 30),

          /// View Details Button
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: _goToListScreen,
              style: ElevatedButton.styleFrom(
                backgroundColor: const Color(0xFF008955),
                padding: const EdgeInsets.symmetric(vertical: 14),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(12),
                ),
              ),
              child: const Text(
                "View Details",
                style: TextStyle(
                  fontSize: 16,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 15),
        ],
      ),
    );
  }
}