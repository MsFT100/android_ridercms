import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:ridercms/controllers/on_boarding_controller.dart';
import '../../utils/themes/app_theme.dart';
import 'content/onboard_1.dart';
import 'content/onboard_2.dart';
import 'content/onboard_3.dart';

class OnboardingScreen extends StatefulWidget {
  const OnboardingScreen({super.key});

  @override
  State<OnboardingScreen> createState() => _OnboardingScreenState();
}

class _OnboardingScreenState extends State<OnboardingScreen> {
  final OnBoardingController _controller = Get.put(OnBoardingController());


  final PageController _pageController = PageController();
  int _current = 0;

  final List<Widget> _pages = const [
    Onboard1(),
    Onboard2(),
    Onboard3(),
  ];

  void _onPageChanged(int index) {
    setState(() => _current = index);
  }


  void _next() {
    if (_current < _pages.length - 1) {
      _pageController.nextPage(
        duration: const Duration(milliseconds: 300),
        curve: Curves.easeInOut,
      );
    } else {
      _controller.finishOnboarding();
    }
  }

  @override
  void dispose() {
    _pageController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
            colors: [kBgDark, kBgDark2],
          ),
        ),
        child: SafeArea(
          child: Stack(
            children: [
              Column(
                children: [
                  // Skip Button
                  Align(
                    alignment: Alignment.topRight,
                    child: Padding(
                      padding: const EdgeInsets.all(20),
                      child: GestureDetector(
                        onTap: _controller.finishOnboarding,
                        child: const Text(
                          'Skip',
                          style: TextStyle(
                            color: kTextSecondary,
                            fontSize: 14,
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ),
                    ),
                  ),

                  // Page Content
                  Expanded(
                    child: PageView(
                      controller: _pageController,
                      onPageChanged: _onPageChanged,
                      children: _pages,
                    ),
                  ),

                  // Fixed spacing at the bottom
                  const SizedBox(height: 100),
                ],
              ),

              // Indicators - Centered at the bottom
              Positioned(
                bottom: 40,
                left: 0,
                right: 0,
                child: Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: List.generate(_pages.length, (i) {
                    return AnimatedContainer(
                      duration: const Duration(milliseconds: 300),
                      margin: const EdgeInsets.symmetric(horizontal: 4),
                      width: i == _current ? 24 : 8,
                      height: 8,
                      decoration: BoxDecoration(
                        color: i == _current
                            ? kPrimary
                            : Colors.white.withValues(alpha: 0.2),
                        borderRadius: BorderRadius.circular(4),
                      ),
                    );
                  }),
                ),
              ),

              // Next Button - Bottom Right
              Positioned(
                bottom: 24,
                right: 24,
                child: GestureDetector(
                  onTap: _next,
                  child: Container(
                    padding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
                    decoration: BoxDecoration(
                      color: kPrimary,
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: Text(
                      _current < _pages.length - 1 ? 'Next' : 'Get Started',
                      style: const TextStyle(
                        color: Colors.white,
                        fontSize: 14,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
