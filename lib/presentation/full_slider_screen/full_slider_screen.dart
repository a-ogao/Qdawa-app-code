import 'dart:async';
import 'package:flutter/material.dart';
import 'package:smooth_page_indicator/smooth_page_indicator.dart';
import '../../core/app_export.dart';
import '../../theme/custom_button_style.dart';
import '../../widgets/custom_elevated_button.dart';
import '../../widgets/custom_outlined_button.dart';
import '../sign_in_screen/sign_in_screen.dart';
import '../sign_up_screen/sign_up_screen.dart';

class FullSliderScreen extends StatefulWidget {
  const FullSliderScreen({Key? key}) : super(key: key);

  @override
  _FullSliderScreenState createState() => _FullSliderScreenState();
}

class _FullSliderScreenState extends State<FullSliderScreen> {
  final PageController _pageController = PageController();
  int _currentIndex = 0;
  Timer? _timer;
  bool _isHolding = false; // Track whether user is holding the slider

  final List<Map<String, String>> sliderContent = [
    {
      "title": "Patients",
      "description":
          "Our mission is to help you begin the\npath to recovery immediately.",
    },
    {
      "title": "Partners",
      "description":
          "We assist our partners in transforming\ntheir customer experience, cultivating trust, optimizing operations.\nboosting satisfaction, and reinforcing loyalty.",
    },
    {
      "title": "Us",
      "description":
          "We are establishing a lasting foundation\nof trust and broadening access to our services for you and your family.\nwherever you reside, work, or travel.",
    },
  ];

  @override
  void initState() {
    super.initState();
    _startAutoSlide();
  }

  void _startAutoSlide() {
    _timer = Timer.periodic(Duration(seconds: 5), (timer) {
      if (!_isHolding) {
        if (_currentIndex < sliderContent.length - 1) {
          _currentIndex++;
        } else {
          _currentIndex = 0;
        }
        _pageController.animateToPage(
          _currentIndex,
          duration: Duration(milliseconds: 300),
          curve: Curves.easeInOut,
        );
      }
    });
  }

  @override
  void dispose() {
    _timer?.cancel();
    _pageController.dispose();
    super.dispose();
  }

  void _onPageChanged(int index) {
    setState(() {
      _currentIndex = index;
    });
  }

  @override
  Widget build(BuildContext context) {
    double screenHeight = MediaQuery.of(context).size.height;

    return Scaffold(
      backgroundColor: appTheme.whiteA700,
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(height: screenHeight * 0.05), // Dynamic top padding
            Text(
              "WELCOME",
              style: CustomTextStyles.titleLargeOnPrimary.copyWith(
                fontFamily: '', // Change to your font family
                fontWeight: FontWeight.bold,
                fontSize: 25,
                color: const Color.fromRGBO(4, 78, 131, 1),
              ),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: screenHeight * 0.03),

            // **STATIC IMAGE**
            CustomImageView(
              imagePath: ImageConstant.imgRectangle159,
              //  height: screenHeight * 0.25,
              // width: screenHeight * 0.25,
              height: 178.h,
              width: 194.h,
            ),

            SizedBox(height: screenHeight * 0.02),

            // **SLIDER FOR TEXT CONTENT**
            Expanded(
              child: Container(
                width: double.maxFinite,
                padding: EdgeInsets.symmetric(horizontal: 34.h, vertical: 20.h),
                decoration: AppDecoration.column5,
                child: Column(
                  children: [
                    Expanded(
                      flex: 4,
                      child: GestureDetector(
                        onLongPress: () {
                          setState(() {
                            _isHolding = true; // Pause auto-slide
                          });
                        },
                        onLongPressUp: () {
                          setState(() {
                            _isHolding = false; // Resume auto-slide
                          });
                        },
                        child: PageView.builder(
                          controller: _pageController,
                          itemCount: sliderContent.length,
                          onPageChanged: _onPageChanged,
                          itemBuilder: (context, index) {
                            return Column(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Text(
                                  sliderContent[index]["title"]!,
                                  style: CustomTextStyles.headlineSmallWhiteA700
                                      .copyWith(
                                    fontFamily:
                                        'Poppins', // Or your chosen font
                                    fontSize: 24,
                                    fontWeight: FontWeight.w700,
                                    letterSpacing: 1,
                                    color: Colors.white,
                                  ),
                                  textAlign: TextAlign.center,
                                ),
                                SizedBox(height: 6.h),
                                Text(
                                  sliderContent[index]["description"]!,
                                  maxLines: 3,
                                  overflow: TextOverflow.ellipsis,
                                  textAlign: TextAlign.center,
                                  style: CustomTextStyles.bodyLargeWhiteA700
                                      .copyWith(
                                    fontFamily:
                                        'Poppins', // Or your chosen font
                                    fontSize: 16,
                                    fontWeight: FontWeight.w400,
                                    height: 1.75,
                                    letterSpacing: 0.5,
                                    color: Colors.white70,
                                  ),
                                ),
                              ],
                            );
                          },
                        ),
                      ),
                    ),

                    SizedBox(height: screenHeight * 0.02),

                    // **SMOOTH PAGE INDICATOR**
                    AnimatedSmoothIndicator(
                      activeIndex: _currentIndex,
                      count: sliderContent.length,
                      effect: ScrollingDotsEffect(
                        spacing: 8,
                        activeDotColor: appTheme.whiteA700,
                        dotColor: theme.colorScheme.onErrorContainer,
                        dotHeight: 8.h,
                        dotWidth: 8.h,
                      ),
                      onDotClicked: (index) {
                        _pageController.animateToPage(
                          index,
                          duration: Duration(milliseconds: 300),
                          curve: Curves.easeInOut,
                        );
                      },
                    ),

                    SizedBox(
                        height: screenHeight * 0.05), // Adjusted bottom space

                    // **BUTTONS**
                    Row(
                      children: [
                        Expanded(
                          child: CustomOutlinedButton(
                            height: 44.h,
                            text: "Register",
                            buttonTextStyle:
                                CustomTextStyles.titleMediumWhiteA700Bold_1,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignUpScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                        SizedBox(width: 10.h),
                        Expanded(
                          child: CustomElevatedButton(
                            height: 44.h,
                            text: "Login",
                            buttonStyle: CustomButtonStyles.fillWhiteA,
                            buttonTextStyle:
                                CustomTextStyles.titleMediumPrimaryBold,
                            onPressed: () {
                              Navigator.push(
                                context,
                                MaterialPageRoute(
                                  builder: (context) => SignInScreen(),
                                ),
                              );
                            },
                          ),
                        ),
                      ],
                    ),

                    SizedBox(
                        height: screenHeight * 0.02), // Minimal bottom padding
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
