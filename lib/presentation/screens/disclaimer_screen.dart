import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/assets.dart';
import '../widgets/app_text.dart';

class DisclaimerScreen extends StatefulWidget {
  const DisclaimerScreen({super.key});

  @override
  State<DisclaimerScreen> createState() => _DisclaimerScreenState();
}

class _DisclaimerScreenState extends State<DisclaimerScreen>
    with SingleTickerProviderStateMixin {
  bool _isAgreed = false;
  late final AnimationController _fadeCtrl;

  @override
  void initState() {
    super.initState();
    _fadeCtrl = AnimationController(
      vsync: this,
      duration: const Duration(milliseconds: 600),
    )..forward();
  }

  @override
  void dispose() {
    _fadeCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: SafeArea(
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            SizedBox(height: 18.h),
            // Title
            Center(
              child: AppText(
                text: AppString.disclaimer,
                color: const Color(0xFFC00000),
                textSize: 26.sp,
                fontFamily: AppString.fontFamily,
                fontWeight: FontWeight.w600,
                shadows: const [
                  Shadow(
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    color: Colors.black26,
                  ),
                ],
              ),
            ),
            SizedBox(height: 16.h),
            Expanded(
              child: SingleChildScrollView(
                physics: const BouncingScrollPhysics(),
                padding: EdgeInsets.symmetric(horizontal: 12.w),
                child: FadeTransition(
                  opacity: CurvedAnimation(
                    parent: _fadeCtrl,
                    curve: Curves.easeInOut,
                  ),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      // Info Box
                      Container(
                        padding: EdgeInsets.all(12.w),
                        decoration: BoxDecoration(
                          color: Colors.white.withOpacity(0.85),
                          borderRadius: BorderRadius.circular(8.r),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black26,
                              blurRadius: 8,
                              spreadRadius: 1,
                              offset: Offset(0, 0), // shadow all sides
                            ),
                          ],
                        ),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            _bullet(
                              'The socio-climatic risk associated with smallholder dairy farmers '
                                  'will be assessed based on the responses provided in the following '
                                  'sections. Respondents are therefore requested to provide their inputs '
                                  'with due care and attention.',
                            ),
                            SizedBox(height: 14.h),
                            _bullet(
                              'No personal data will be utilized for commercial purposes. All collected '
                                  'information will be used exclusively for academic research and will remain '
                                  'anonymous. Furthermore, no data will be disclosed to any third party under '
                                  'any circumstances.',
                            ),
                            SizedBox(height: 14.h),
                            _bullet(
                              'All the fields are compulsory and if there is no value for any field, please fill 0 (zero).',
                              color: const Color(0xFFC00000),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 14.h),
                      // Image with reduced height
                      Container(
                        padding: EdgeInsets.all(8.w),
                        decoration: BoxDecoration(
                          color: Colors.white,
                          borderRadius: BorderRadius.circular(8.r),
                          boxShadow: const [
                            BoxShadow(
                              color: Colors.black12,
                              blurRadius: 6,
                              spreadRadius: 1,
                              offset: Offset(0, 0),
                            ),
                          ],
                        ),
                        child: SizedBox(
                          height: 250.h,
                          child: Image.asset(
                            Assets.socioClimateDia,
                            fit: BoxFit.contain,
                          ),
                        ),
                      ),
                      SizedBox(height: 16.h),
                      // Agreement checkbox
                      GestureDetector(
                        behavior: HitTestBehavior.translucent,
                        onTap: () => setState(() => _isAgreed = !_isAgreed),
                        child: Row(
                          crossAxisAlignment: CrossAxisAlignment.center,
                          children: [
                            SizedBox(width: 6.w),
                            Container(
                              height: 25.r,
                              width: 25.r,
                              decoration: BoxDecoration(
                                border: Border.all(
                                  color: const Color(0xFF355790),
                                  width: 2.w,
                                ),
                                color: _isAgreed
                                    ? const Color(0xFF31538F)
                                    : const Color(0xFFb2d6c0),
                              ),
                              child: _isAgreed
                                  ? const Icon(Icons.check,
                                  size: 16, color: Colors.white)
                                  : null,
                            ),
                            SizedBox(width: 6.w),
                            Expanded(
                              child: Container(
                                padding: EdgeInsets.symmetric(
                                  horizontal: 6.w,
                                  vertical: 6.h,
                                ),
                                decoration: BoxDecoration(
                                  color: AppColors.yellowColor,
                                  border: Border.all(
                                    color: const Color(0xFF0e86d4),
                                    width: 1,
                                  ),
                                ),
                                child: AppText(
                                  text: AppString.iHereby,
                                  color: Colors.black,
                                  textSize: 12.sp,
                                  fontFamily: AppString.fontFamily,
                                  fontWeight: FontWeight.w600,
                                  lineHeight: 1.4,
                                ),
                              ),
                            ),
                          ],
                        ),
                      ),
                      SizedBox(height: 18.h),
                      // Continue button
                      Center(
                        child: SizedBox(
                          width: 160.w,
                          child: ElevatedButton(
                            onPressed:
                            _isAgreed ? () => context.go('/home') : null,
                            style: ElevatedButton.styleFrom(
                              padding: EdgeInsets.symmetric(
                                horizontal: 18.w,
                                vertical: 8.h,
                              ),
                              backgroundColor: const Color(0xFF833C0B),
                              shape: RoundedRectangleBorder(
                                borderRadius: BorderRadius.circular(4.r),
                                side: _isAgreed
                                    ? const BorderSide(
                                    color: Color(0xFF0e86d4), width: 1)
                                    : BorderSide.none,
                              ),
                            ),
                            child: AppText(
                              text: AppString.cunt,
                              color: Colors.white,
                              textSize: 18.sp,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ),
                      SizedBox(height: 20.h),
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

  Widget _bullet(String text, {Color color = const Color(0xFF082765)}) {
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: '•',
          color: color,
          textSize: 14.sp,
          fontWeight: FontWeight.bold,
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: AppText(
            text: text,
            color: color,
            textSize: 12.sp,
            fontFamily: AppString.fontFamily,
            fontWeight: FontWeight.w600,
            lineHeight: 1.4,
          ),
        ),
      ],
    );
  }
}
