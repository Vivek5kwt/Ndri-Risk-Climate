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
    final double screenH = MediaQuery.of(context).size.height;
    final double safeTop = MediaQuery.of(context).padding.top;
    final double headerBlock = 60.h;
    final double desiredCenter = (screenH + safeTop) * 0.38;
    final double dynamicGap = (desiredCenter - headerBlock).clamp(0.0, 120.0);

    return Scaffold(
      body: Stack(
        children: [
          Positioned(
            top: 150.h,
            left: 0,
            right: 0,
            child: Opacity(
              opacity: 0.6,
              child: FittedBox(
                fit: BoxFit.contain,
                alignment: Alignment.center,
                child: Image.asset(Assets.socioClimateDia),
              ),
            ),
          ),
          Positioned.fill(
            child: Container(color: Colors.white.withOpacity(0.15)),
          ),
          SafeArea(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Padding(
                  padding: EdgeInsets.only(top: 30.h),
                  child: Center(
                    child: AppText(
                      text: AppString.disclaimer,
                      color: const Color(0xFFC00000),
                      textSize: 28.sp,
                      fontFamily: AppString.fontFamily,
                      fontWeight: FontWeight.w500,
                      shadows: const [
                        Shadow(
                          offset: Offset(0, 2),
                          blurRadius: 4,
                          color: Colors.black38,
                        ),
                      ],
                    ),
                  ),
                ),
                SizedBox(height: dynamicGap),
                Expanded(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    padding: EdgeInsets.symmetric(horizontal: 10.w),
                    child: FadeTransition(
                      opacity: CurvedAnimation(
                        parent: _fadeCtrl,
                        curve: Curves.easeIn,
                      ),
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          Container(
                            padding: EdgeInsets.all(10.w),
                            decoration: BoxDecoration(
                              color: Colors.white.withOpacity(0.7),
                              borderRadius: BorderRadius.circular(6.r),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 6,
                                  offset: Offset(0, 3),
                                ),
                              ],
                            ),
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                _bullet(
                                  'The socio‑climatic risk associated with smallholder dairy farmers '
                                      'will be assessed based on the responses provided in the following '
                                      'sections. Respondents are therefore requested to provide their inputs '
                                      'with due care and attention.',
                                ),
                                SizedBox(height: 16.h),
                                _bullet(
                                  'No personal data will be utilized for commercial purposes. All collected '
                                      'information will be used exclusively for academic research and will remain '
                                      'anonymous. Furthermore, no data will be disclosed to any third party under '
                                      'any circumstances.',
                                ),
                              ],
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
                Padding(
                  padding: const EdgeInsets.all(6.0),
                  child: GestureDetector(
                    behavior: HitTestBehavior.translucent,
                    onTap: () => setState(() => _isAgreed = !_isAgreed),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.center,
                      children: [
                        SizedBox(width: 6.r,),
                        Container(
                          height: 25.r,
                          width: 22.r,
                          decoration: BoxDecoration(
                            border: Border.all(
                              color: const Color(0xFF355790),
                              width: 2.3.w,
                            ),
                            color: _isAgreed
                                ? const Color(0xFF31538F)
                                : const Color(0xFFb2d6c0),
                          ),
                          child: _isAgreed
                              ? const Center(
                            child: Icon(Icons.check,
                                size: 16, color: Colors.white),
                          )
                              : null,
                        ),
                        SizedBox(width: 2.w),
                        Expanded(
                          child: Padding(
                            padding: const EdgeInsets.all(8.0),
                            child: Container(
                              margin: EdgeInsets.only(top: 6.h),
                              padding: EdgeInsets.fromLTRB(4.w, 6.w, 4.w, 6.w),
                              decoration: BoxDecoration(
                                color: AppColors.yellowColor,
                                border: Border.all(
                                    color: const Color(0xFF0e86d4), width: 1),
                              ),
                              child: AppText(
                                text: AppString.iHereby,
                                color: Colors.black,
                                textSize: 13.sp,
                                fontWeight: FontWeight.w700,
                                lineHeight: 1.5,
                                letterSpacing: 1.3,
                              ),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ),
                Padding(
                  padding: EdgeInsets.only(bottom: 20.h),
                  child: Center(
                    child: SizedBox(
                      width: 160.w,
                      child: ElevatedButton(
                        onPressed: _isAgreed ? () => context.go('/home') : null,
                        style: ElevatedButton.styleFrom(
                          padding: EdgeInsets.symmetric(
                            horizontal: 17.w,
                            vertical: 6.h,
                          ),
                          minimumSize: Size(100.w, 43.h),
                          backgroundColor: const Color(0xFF833C0B),
                          shape: RoundedRectangleBorder(
                            borderRadius: BorderRadius.zero,
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
                ),
              ],
            ),
          ),
        ],
      ),
    );
  }

  Widget _bullet(String text) {
    const bulletColor = Color(0xFF082765);
    return Row(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        AppText(
          text: '➢',
          color: bulletColor,
          textSize: 14.sp,
          fontWeight: FontWeight.w800,
        ),
        SizedBox(width: 6.w),
        Expanded(
          child: AppText(
            text: text,
            color: bulletColor,
            textSize: 12.sp,
            fontWeight: FontWeight.w700,
            lineHeight: 1.40,
          ),
        ),
      ],
    );
  }
}
