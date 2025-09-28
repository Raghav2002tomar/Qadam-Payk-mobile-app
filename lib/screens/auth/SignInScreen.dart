import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../service/colors.dart';
import 'OtpVerificationScreen.dart';
import 'controller/auth_provider.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  _PhoneNumberScreenState createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final TextEditingController phoneController = TextEditingController();

  @override
  Widget build(BuildContext context) {
    final loginProvider = context.watch<LoginProvider>();

    return Scaffold(
      backgroundColor: Colors.white,
      resizeToAvoidBottomInset: true, // ✅ allow screen to resize when keyboard opens
      body: SafeArea(
        child: GestureDetector(
          onTap: () => FocusScope.of(context).unfocus(), // ✅ dismiss keyboard on tap outside
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(vertical: 20),
            child: Column(
              children: [
                Align(
                  alignment: Alignment.topRight,
                  child: TextButton(
                    onPressed: () => Navigator.pop(context),
                    child: Text(
                      "Skip",
                      style: GoogleFonts.poppins(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Image.asset("assets/images/car.png", fit: BoxFit.contain),
                const SizedBox(height: 20),
                Text(
                  "Sign Up with Phone",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 22,
                    fontWeight: FontWeight.w600,
                    color: Colors.black87,
                  ),
                ),
                const SizedBox(height: 12),
                Text(
                  "Enter your phone number to get started",
                  textAlign: TextAlign.center,
                  style: GoogleFonts.poppins(
                    fontSize: 14,
                    color: Colors.grey.shade600,
                    height: 1.5,
                  ),
                ),
                const SizedBox(height: 20),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.phone,
                    decoration: InputDecoration(
                      labelText: "Phone Number",
                      labelStyle:
                      GoogleFonts.poppins(color: Colors.grey.shade600),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Image.asset(
                          "assets/images/flag_tj.png",
                          width: 30,
                          height: 30,
                        ),
                      ),
                      prefixIconConstraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(
                            color:
                            AppTheme.seedSecondary.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: AppTheme.seedPrimary, width: 2),
                      ),
                      hintText: "Enter your phone number",
                      hintStyle:
                      GoogleFonts.poppins(color: Colors.grey.shade600),
                    ),
                    style: GoogleFonts.poppins(color: Colors.black87),
                  ),
                ),
                const SizedBox(height: 30),
                GestureDetector(
                  onTap: () async {
                    final loginProvider = context.read<LoginProvider>();
                    final responseSuccess = await loginProvider.sendOtp(
                        context, phoneController.text);
                    if (responseSuccess) {
                      final otp = loginProvider.latestOtp;
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (_) => OtpVerificationScreen(
                            phoneNumber: phoneController.text,
                            otp: otp,
                          ),
                        ),
                      );
                    }
                  },
                  child: AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    height: 64,
                    width: 64,
                    decoration: BoxDecoration(
                      color: AppTheme.seedPrimary,
                      shape: BoxShape.circle,
                    ),
                    child: Center(
                      child: loginProvider.isLoading
                          ? const CircularProgressIndicator(
                          color: Colors.white, strokeWidth: 2)
                          : const Icon(Icons.arrow_forward, color: Colors.white),
                    ),
                  ),
                ),
                const SizedBox(height: 20),
                Text(
                  "We'll send a verification code to your number",
                  style: GoogleFonts.poppins(
                    fontSize: 12,
                    color: Colors.grey.shade600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

