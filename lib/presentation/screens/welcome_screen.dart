import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';

import '../../config/app_colors.dart';
import '../../config/app_strings.dart';
import '../../config/assets.dart';
import '../widgets/app_text.dart';

class WelcomeScreen extends StatefulWidget {
  const WelcomeScreen({super.key});

  @override
  State<WelcomeScreen> createState() => _WelcomeScreenState();
}

class _WelcomeScreenState extends State<WelcomeScreen>
    with SingleTickerProviderStateMixin {
  late final AnimationController _controller;

  @override
  void initState() {
    super.initState();
    _controller = AnimationController(
      vsync: this,
      duration: const Duration(seconds: 4),
    )..forward();
    Future.delayed(const Duration(seconds: 4), () {
      if (mounted) context.go('/disclaimer');
    });
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: Colors.white,
      body: Container(
        padding: EdgeInsets.symmetric(horizontal: 16.w),
        child: SafeArea(
          child: Column(
            children: [
              SizedBox(height: 10.h),
              AppText(
                text: AppString.appName,
                textAlign: TextAlign.center,
                color: AppColors.headerBlueColor,
                textSize: 30.sp,
                fontWeight: FontWeight.w800,
                fontFamily: 'Roboto',
                shadows: const [
                  Shadow(
                    offset: Offset(0, 2),
                    blurRadius: 4,
                    color: Colors.black45,
                  ),
                ],
              ),
              Expanded(
                child: Center(
                  child: SingleChildScrollView(
                    physics: const BouncingScrollPhysics(),
                    child: Image.asset(
                      Assets.socioClimateDia,
                      height: 320.h,
                    ),
                  ),
                ),
              ),
              SizedBox(height: 8.h),
              AppText(
                text: AppString.aNovel,
                textAlign: TextAlign.center,
                color: const Color.fromRGBO(112, 48, 160, 1),
                textSize: 13.sp,
                fontWeight: FontWeight.w600,
                lineHeight: 1.4,
              ),
              SizedBox(height: 10.h),
              SizedBox(
                width: 200.w,
                height: 6.h,
                child: AnimatedBuilder(
                  animation: _controller,
                  builder: (context, child) {
                    return Stack(
                      children: [
                        Container(
                          decoration: BoxDecoration(
                            color: const Color(0xFFE0E0E0),
                            borderRadius: BorderRadius.circular(3.r),
                          ),
                        ),
                        FractionallySizedBox(
                          widthFactor: _controller.value,
                          child: Container(
                            decoration: BoxDecoration(
                              gradient: const LinearGradient(
                                colors: [Color(0xFF0e86d4), Color(0xFF01949a)],
                              ),
                              borderRadius: BorderRadius.circular(3.r),
                              boxShadow: const [
                                BoxShadow(
                                  color: Colors.black26,
                                  blurRadius: 4,
                                  offset: Offset(0, 1),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ],
                    );
                  },
                ),
              ),
              SizedBox(height: 10.h),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Image.asset(
                    Assets.iCarLogo,
                    height: 110.h,
                  ),
                  SizedBox(height: 6.h),
                  AppText(
                    text: AppString.iCarAdd,
                    textAlign: TextAlign.center,
                    color: Colors.black,
                    textSize: 15.sp,
                    fontWeight: FontWeight.w600,
                    lineHeight: 1.4,
                  ),
                  SizedBox(height: 6.h),
                  Image.asset(
                    Assets.appLogo,
                    height: 120.h,
                  ),
                ],
              ),
              SizedBox(height: 4.h),
            ],
          ),
        ),
      ),
    );
  }
}
