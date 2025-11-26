import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:provider/provider.dart';

import '../../providers/translate_provider.dart';
import '../../service/colors.dart';
import '../../service/local_cache.dart';
import '../mainView/HomeShell.dart';


class OnboardingScreen extends StatefulWidget {
    const OnboardingScreen({Key? key}) : super(key: key);

    @override
    State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
    final PageController _controller = PageController();
    int _currentPage = 0;
    late List<_OnboardItem> _pages;

    @override
    void didChangeDependencies() {
      super.didChangeDependencies();
      _pages = [
        _OnboardItem(
          image: "assets/images/onboarding1.png",
          title: context.watch<TranslateProvider>().t('onBoarding_anywhere'),
          description: context.watch<TranslateProvider>().t('onBoarding_description'),
        ),
        _OnboardItem(
          image: "assets/images/onboarding2.png",
          title: context.watch<TranslateProvider>().t('onBoarding_anytime'),
          description: context.watch<TranslateProvider>().t('onBoarding_description'),
        ),
        _OnboardItem(
          image: "assets/images/onboarding3.png",
          title: context.watch<TranslateProvider>().t('onBoarding_book_car'),
          description: context.watch<TranslateProvider>().t('onBoarding_description'),
        ),
      ];
    }

    void _nextPage() async {
        if (_currentPage < _pages.length - 1) {
            _controller.nextPage(
                duration: const Duration(milliseconds: 400),
                curve: Curves.easeInOut
            );
        } else {
            await LocalCache.setOnboardingSeen();
            Navigator.pushReplacement(
                context,
                MaterialPageRoute(builder: (context) => HomeShell())
            );
        }
    }

    @override
    Widget build(BuildContext context) {
      return Scaffold(
            backgroundColor: Colors.white,
            body: SafeArea(
                child: Column(
                    children: [
                        Align(
                            alignment: Alignment.topRight,
                            child: TextButton(
                                onPressed: () {
                                    // TODO: Navigate to home directly
                                },
                                child: Text(
                                    context.watch<TranslateProvider>().t('onBoarding_skip'),
                                    style: GoogleFonts.poppins(
                                        fontSize: 16,
                                        fontWeight: FontWeight.w700,
                                        color: Colors.grey.shade600
                                    )
                                )
                            )
                        ),
                        Expanded(
                            child: PageView.builder(
                                controller: _controller,
                                itemCount: _pages.length,
                                onPageChanged: (index) {
                                    setState(() {
                                            _currentPage = index;
                                        });
                                },
                                itemBuilder: (context, index) {
                                    return _buildPage(_pages[index]);
                                }
                            )
                        ),
                        const SizedBox(height: 20),
                        _buildPageIndicator(),
                        const SizedBox(height: 30),
                        _buildBottomButton(),
                        const SizedBox(height: 20)
                    ]
                )
            )
        );
    }

    Widget _buildPage(_OnboardItem item) {
        return Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24.0),
            child: Column(
                children: [
                    Expanded(
                        flex: 3,
                        child: Image.asset(item.image, fit: BoxFit.contain)
                    ),
                    const SizedBox(height: 30),
                    Text(
                        item.title,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 22,
                            fontWeight: FontWeight.w600,
                            color: Colors.black87
                        )
                    ),
                    const SizedBox(height: 12),
                    Text(
                        item.description,
                        textAlign: TextAlign.center,
                        style: GoogleFonts.poppins(
                            fontSize: 14,
                            color: Colors.grey.shade600,
                            height: 1.5
                        )
                    ),
                    const Spacer()
                ]
            )
        );
    }

    Widget _buildPageIndicator() {
        return Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: List.generate(
                _pages.length,
                (index) => AnimatedContainer(
                    duration: const Duration(milliseconds: 300),
                    margin: const EdgeInsets.symmetric(horizontal: 4),
                    height: 6,
                    width: _currentPage == index ? 24 : 8,
                    decoration: BoxDecoration(
                        color: _currentPage == index
                            ? AppTheme.seedPrimary
                            : AppTheme.seedSecondary.withOpacity(0.3),
                        borderRadius: BorderRadius.circular(4)
                    )
                )
            )
        );
    }

    Widget _buildBottomButton() {
        final bool isLast = _currentPage == _pages.length - 1;
        return GestureDetector(
            onTap: _nextPage,
            child: Container(
                height: 64,
                width: 64,
                decoration: BoxDecoration(
                    color: AppTheme.seedPrimary,
                    shape: BoxShape.circle,
                    border: Border.all(color: Colors.transparent, width: 2)
                ),
                child: Center(
                    child: isLast
                        ? Text(
                            context.watch<TranslateProvider>().t('onBoarding_go'),
                            style: GoogleFonts.poppins(
                                fontSize: 16,
                                fontWeight: FontWeight.w600,
                                color: Colors.white
                            )
                        )
                        : Icon(Icons.arrow_forward, color: Colors.white)
                )
            )
        );
    }
}

class _OnboardItem {
    final String image;
    final String title;
    final String description;

    _OnboardItem({
        required this.image,
        required this.title,
        required this.description
    });
}
