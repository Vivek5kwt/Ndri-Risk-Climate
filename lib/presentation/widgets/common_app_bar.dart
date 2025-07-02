import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:go_router/go_router.dart';
import 'package:ndri_dairy_risk/presentation/widgets/app_text.dart';

import '../../config/app_colors.dart';

PreferredSizeWidget cleanAppBar({
  required String title,
  String? subtitle,
  required BuildContext context,
}) {
  return PreferredSize(
    preferredSize: Size.fromHeight(80.h),
    child: Container(
      decoration: BoxDecoration(
        color: AppColors.primaryColor,
        borderRadius: BorderRadius.vertical(
          bottom: Radius.circular(20.r),
        ),
      ),
      child: SafeArea(
        child: Container(
          color: AppColors.primaryColor,
          padding: EdgeInsets.symmetric(horizontal: 16.w, vertical: 8.h),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.center,
            children: [
              InkWell(
                borderRadius: BorderRadius.circular(100.r),
                onTap: () {
                  context.pop();
                },
                child: Container(
                  padding: EdgeInsets.all(8.w),
                  decoration: BoxDecoration(
                    shape: BoxShape.circle,
                    color: Colors.grey.shade200,
                  ),
                  child: Icon(
                    Icons.arrow_back_ios_new_rounded,
                    size: 20.sp,
                    color: Colors.black87,
                  ),
                ),
              ),
              SizedBox(width: 12.w),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    AppText(
                      text: title,
                      textAlign: TextAlign.start,
                      color: Colors.white,
                      textSize: 20.sp,
                      fontWeight: FontWeight.bold,
                    ),
                    if (subtitle != null)
                      Padding(
                        padding: EdgeInsets.only(top: 2.h),
                        child: AppText(
                          text: subtitle,
                          textAlign: TextAlign.start,
                          color: Colors.white.withOpacity(0.8),
                          textSize: 14.sp,
                          fontWeight: FontWeight.w400,
                        ),
                      ),
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
  );
}
