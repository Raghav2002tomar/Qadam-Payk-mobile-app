import 'package:bla_bla_car/api_service/app_constocter.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:http/http.dart';
import '../../../service/colors.dart';
import '../../providers/translate_provider.dart';
import '../../service/local_cache.dart';
import '../../service/user_data_locatl.dart';
import '../mainView/HomeShell.dart';
import 'controller/auth_provider.dart';
import 'package:provider/provider.dart';

class OtpVerificationScreen extends StatefulWidget {
  final String phoneNumber;
  final String? otp; // Add OTP parameter
  const OtpVerificationScreen({super.key, required this.phoneNumber, this.otp});

  @override
  _OtpVerificationScreenState createState() => _OtpVerificationScreenState();
}

class _OtpVerificationScreenState extends State<OtpVerificationScreen> {
  final TextEditingController otpController = TextEditingController();
  bool _isLoading = false;
  final String _dummyOtp = "123456"; // Dummy OTP for testing
  bool _showOtpMessage = false;
  String _otpMessage = "";

  @override
  void initState() {
    super.initState();
    if (widget.otp != null) {
    if(App_Constructor().istestmode)  _triggerOtpMessage("OTP sent: ${widget.otp}");
    }
  }


  void _triggerOtpMessage(String message) {
    setState(() {
      _otpMessage = message;
      _showOtpMessage = true;
    });
    Future.delayed(const Duration(seconds: 5), () {
      if (mounted) {
        setState(() => _showOtpMessage = false);
      }
    });
  }

  void _verifyOtp() async {
    final loginProvider = context.read<LoginProvider>();
    final otp = otpController.text.trim();

    final success = await loginProvider.verifyOtp(context, widget.phoneNumber, otp);

    if (success && mounted) {
      Navigator.pushAndRemoveUntil(
        context,
        MaterialPageRoute(builder: (_) => const HomeShell()),
            (Route<dynamic> route) => false, // <-- This clears all previous routes
      );
    }

  }



  void _resendOtp() async {
    final loginProvider = context.read<LoginProvider>();
    final phoneNumber = widget.phoneNumber;

    // Call API to resend OTP
    final success = await loginProvider.sendOtp(context, phoneNumber);

    if (success) {
      // Show latest OTP from provider
    if(App_Constructor().istestmode)  _triggerOtpMessage("${context.watch<TranslateProvider>().t('txt_otp_resent')} ${loginProvider.latestOtp}");
    }
  }



  @override
  Widget build(BuildContext context) {
    return GestureDetector(
      onTap: () => FocusScope.of(context).unfocus(), // closes the keyboard
      child: Scaffold(
        backgroundColor: Colors.white,
        resizeToAvoidBottomInset: false, // prevents auto scroll when keyboard opens
        body: Stack(
          children: [
            SafeArea(
              child: SingleChildScrollView(
                padding: const EdgeInsets.symmetric(horizontal: 0),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.center,
                  children: [
                    const SizedBox(height: 12),
                    Image.asset(
                      "assets/images/car.png",
                      height: 250,
                      fit: BoxFit.contain,
                    ),
                    // const SizedBox(height: 20),
                    // Text(
                    //   context.watch<TranslateProvider>().t('txt_verify_otp'),
                    //   textAlign: TextAlign.center,
                    //   style: GoogleFonts.poppins(
                    //     fontSize: 22,
                    //     fontWeight: FontWeight.w600,
                    //     color: Colors.black87,
                    //   ),
                    // ),
                    // const SizedBox(height: 12),
                    Text(
                      "${context.watch<TranslateProvider>().t('txt_enter_6_digit_code')} ${widget.phoneNumber}",
                      textAlign: TextAlign.center,
                      style: GoogleFonts.notoSans(
                        fontSize: 14,
                        color: Colors.grey.shade600,
                        height: 1.5,
                      ),
                    ),
                    const SizedBox(height: 8),
                    Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: TextField(
                        controller: otpController,
                        keyboardType: TextInputType.number,
                        maxLength: 6,
                        textAlign: TextAlign.center,
                        decoration: InputDecoration(
                          counterText: "",
                          hintText: "------",
                          hintStyle: GoogleFonts.poppins(
                            fontSize: 28,
                            letterSpacing: 10,
                            color: Colors.grey.shade400,
                          ),
                          border: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.seedSecondary.withOpacity(0.3)),
                          ),
                          focusedBorder: OutlineInputBorder(
                            borderRadius: BorderRadius.circular(12),
                            borderSide: BorderSide(color: AppTheme.seedPrimary, width: 2),
                          ),
                        ),
                        style: GoogleFonts.poppins(color: Colors.black87),
                        onChanged: (value) {
                          if (value.length == 6) _verifyOtp();
                        },
                      ),
                    ),
                    const SizedBox(height: 16),
                    TextButton(
                      onPressed: _resendOtp,
                      child: Text(
                        context.watch<TranslateProvider>().t('txt_resend_otp'),
                        style: GoogleFonts.poppins(
                          fontSize: 14,
                          color: AppTheme.seedPrimary,
                        ),
                      ),
                    ),
                    const SizedBox(height: 16),
                    _buildBottomButton(),
                    const SizedBox(height: 20),
                    // Text(
                    //   context.watch<TranslateProvider>().t('txt_enter_the_code'),
                    //   style: GoogleFonts.poppins(
                    //     fontSize: 12,
                    //     color: Colors.grey.shade600,
                    //   ),
                    // ),
                    const SizedBox(height: 40),
                  ],
                ),
              ),
            ),
      
            // ✅ OTP message overlay
            if (_showOtpMessage)
              Positioned(
                top: 0,
                left: 0,
                right: 0,
                child: SafeArea(
                  child: Container(
                    margin: const EdgeInsets.all(16),
                    padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 12),
                    decoration: BoxDecoration(
                      color: AppTheme.seedPrimary,
                      borderRadius: BorderRadius.circular(8),
                      boxShadow: [
                        BoxShadow(
                          color: Colors.black.withOpacity(0.1),
                          blurRadius: 10,
                          offset: const Offset(0, 4),
                        ),
                      ],
                    ),
                    child: Row(
                      mainAxisAlignment: MainAxisAlignment.spaceBetween,
                      children: [
                        Expanded(
                          child: Text(
                            _otpMessage,
                            style: GoogleFonts.poppins(
                              color: Colors.white,
                              fontSize: 14,
                            ),
                          ),
                        ),
                        IconButton(
                          icon: const Icon(Icons.close, color: Colors.white),
                          onPressed: () => setState(() => _showOtpMessage = false),
                        ),
                      ],
                    ),
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }

  Widget _buildBottomButton() {
    return GestureDetector(
      onTap: _verifyOtp,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 300),
        height: 64,
        width: 64,
        decoration: BoxDecoration(
          color: AppTheme.seedPrimary,
          shape: BoxShape.circle,
          border: Border.all(color: Colors.transparent, width: 2),
        ),
        child: Center(
          child: _isLoading
              ? CircularProgressIndicator(
            color: Colors.white,
            strokeWidth: 2,
          )
              : Icon(Icons.arrow_forward, color: Colors.white),
        ),
      ),
    );
  }
}
