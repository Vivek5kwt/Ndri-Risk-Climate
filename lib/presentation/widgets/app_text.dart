import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';

import '../../config/app_colors.dart';

enum AppTextStyle { title, medium, regular, small }

class AppText extends StatelessWidget {
  final String text;
  final dynamic color;
  final dynamic underlineColor;
  final AppTextStyle? style;
  final bool? underline;
  final bool? strikeThrough;
  final double? textSize;
  final bool? capitalise;
  final int? maxlines;
  final TextAlign? textAlign;
  final String? fontFamily;
  final FontWeight? fontWeight;
  final double? lineHeight;
  final FontStyle? fontStyle;
  final double? letterSpacing;
  final TextOverflow? overflow;
  final List<Shadow>? shadows;

  const AppText({
    super.key,
    required this.text,
    this.color,
    this.style,
    this.maxlines,
    this.textAlign,
    this.underline,
    this.textSize,
    this.fontFamily,
    this.fontWeight,
    this.lineHeight,
    this.fontStyle,
    this.underlineColor,
    this.strikeThrough,
    this.capitalise,
    this.letterSpacing,
    this.overflow,
    this.shadows,
  });

  @override
  Widget build(BuildContext context) {
    return Text(
      capitalise != null && capitalise! ? text.toUpperCase() : text,
      maxLines: maxlines,
      overflow: maxlines != null ? TextOverflow.ellipsis : null,
      textAlign: textAlign,
      style: getStyle(color ?? AppColors.blackColor, textSize ?? 16.sp),
    );
  }

  TextStyle getStyle(Color color, double textSize) {
    return TextStyle(
      overflow: overflow,
      color: color,
      letterSpacing: letterSpacing,
      fontWeight: fontWeight ?? FontWeight.w500,
      fontSize: textSize,
      fontStyle: fontStyle ?? FontStyle.normal,
      height: lineHeight ?? 1.5,
      // 👈 added default line height to give space
      //fontFamily: fontFamily ?? AppString.fontFamily,
      decorationColor: underlineColor ?? AppColors.blackColor,
      decorationThickness: 1,
      decoration: strikeThrough != null && strikeThrough!
          ? TextDecoration.lineThrough
          : underline != null
              ? TextDecoration.underline
              : null,
      shadows: shadows,
    );
  }

  FontWeight getWeight() {
    switch (style) {
      case AppTextStyle.title:
        return FontWeight.w600;
      case AppTextStyle.medium:
        return FontWeight.w500;
      case AppTextStyle.regular:
        return FontWeight.w400;
      case AppTextStyle.small:
        return FontWeight.w300;
      default:
        return FontWeight.w400;
    }
  }
}
