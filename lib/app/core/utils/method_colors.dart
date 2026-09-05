import 'package:flutter/material.dart';
import 'app_colors.dart';

Color httpMethodColor(String method) {
  switch (method.toUpperCase()) {
    case 'GET':
      return AppColors.green;
    case 'POST':
      return AppColors.blue;
    case 'PUT':
      return AppColors.yellow;
    case 'PATCH':
      return AppColors.magenta;
    case 'DELETE':
      return AppColors.red;
    default:
      return AppColors.cyan;
  }
}

Color httpStatusColor(int code) {
  if (code >= 200 && code < 300) return AppColors.green;
  if (code >= 300 && code < 400) return AppColors.yellow;
  if (code >= 400) return AppColors.red;
  return AppColors.mutedForeground;
}
