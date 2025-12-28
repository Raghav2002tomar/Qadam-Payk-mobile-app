import 'package:bla_bla_car/api_service/app_constocter.dart';
import 'package:bla_bla_car/providers/translate_provider.dart';
import 'package:flutter/gestures.dart';
import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_svg/svg.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';
import '../../../service/colors.dart';
import '../mainView/ProfileScreen/PrivacyPolicyScreen.dart';
import '../mainView/ProfileScreen/TermsConditionsScreen.dart';
import 'OtpVerificationScreen.dart';
import 'controller/auth_provider.dart';

class PhoneNumberScreen extends StatefulWidget {
  const PhoneNumberScreen({super.key});

  @override
  _PhoneNumberScreenState createState() => _PhoneNumberScreenState();
}

class _PhoneNumberScreenState extends State<PhoneNumberScreen> {
  final TextEditingController phoneController = TextEditingController();
  bool isAgreed = false;

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
                      context.watch<TranslateProvider>().t('onBoarding_skip'),
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
                // const SizedBox(height: 20),
                // Text(
                //   context.watch<TranslateProvider>().t('txt_signup_with_phone'),
                //   textAlign: TextAlign.center,
                //   style: GoogleFonts.poppins(
                //     fontSize: 22,
                //     fontWeight: FontWeight.w600,
                //     color: Colors.black87,
                //   ),
                // ),
                const SizedBox(height: 12),
                // Text(
                //   context.watch<TranslateProvider>().t('txt_enter_phone_to_start'),
                //   textAlign: TextAlign.center,
                //   style: GoogleFonts.poppins(
                //     fontSize: 14,
                //     color: Colors.grey.shade600,
                //     height: 1.5,
                //   ),
                // ),
                const SizedBox(height: 20),
                // Text(App_Constructor().istestmode.toString()),
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: TextField(
                    controller: phoneController,
                    keyboardType: TextInputType.number,
                    maxLength: App_Constructor().istestmode == true ?10: 9, // ✅ Only 9 digits allowed
                    inputFormatters: [
                      FilteringTextInputFormatter.digitsOnly, // ✅ Only numbers allowed
                      LengthLimitingTextInputFormatter(App_Constructor().istestmode == true ?10: 9), // ✅ Restrict exactly 9 digits
                    ],
                    decoration: InputDecoration(
                      counterText: "", // ✅ Hide character counter
                      labelStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
                      prefixIcon: Padding(
                        padding: const EdgeInsets.symmetric(horizontal: 8),
                        child: Container(
                          color: Colors.transparent,
                          child: Image.asset(
                            "assets/images/flog.png",
                            width: 30,
                            height: 30,
                          ),
                        ),
                      ),
                      prefixIconConstraints:
                      const BoxConstraints(minWidth: 40, minHeight: 40),
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide:
                        BorderSide(color: AppTheme.seedSecondary.withOpacity(0.3)),
                      ),
                      focusedBorder: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                        borderSide: BorderSide(color: AppTheme.seedPrimary, width: 2),
                      ),
                      hintText: "${context.watch<TranslateProvider>().t('enter_phone')}",
                      hintStyle: GoogleFonts.poppins(color: Colors.grey.shade600),
                    ),
                    style: GoogleFonts.poppins(color: Colors.black87),
                  ),
                ),
                // const SizedBox(height: 10),
              Padding(
                padding: const EdgeInsets.all(8.0),
                child: Row(
                  children: [
                    Checkbox(
                      value: isAgreed,
                      onChanged: (value) {
                        setState(() {
                          isAgreed = value!;
                        });
                      },
                    ),

                    Expanded(
                      child: RichText(
                        text: TextSpan(
                          style: GoogleFonts.poppins(color: Colors.black, fontSize: 14, height: 1.4),
                          children: [
                            TextSpan(text: context.watch<TranslateProvider>().t('agree_prefix')),

                            TextSpan(
                              text: context.watch<TranslateProvider>().t('terms_conditions'),
                              style: const TextStyle(color: Colors.blue),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const TermsConditionsScreen()),
                                  );
                                },
                            ),

                            TextSpan(text: "\n${context.watch<TranslateProvider>().t('and_text')}"),

                            TextSpan(
                              text: context.watch<TranslateProvider>().t('privacy_policy'),
                              style: const TextStyle(color: Colors.blue),
                              recognizer: TapGestureRecognizer()
                                ..onTap = () {
                                  Navigator.push(
                                    context,
                                    MaterialPageRoute(builder: (context) => const PrivacyPolicyScreen()),
                                  );
                                },
                            ),

                            TextSpan(text: context.watch<TranslateProvider>().t('dot')),
                          ],
                        ),
                      ),
                    ),
                  ],
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
                // Text(
                //   context.watch<TranslateProvider>().t('txt_we_send_code'),
                //   style: GoogleFonts.poppins(
                //     fontSize: 12,
                //     color: Colors.grey.shade600,
                //   ),
                // ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}

