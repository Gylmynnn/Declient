import 'package:flutter/material.dart';

class AppColors {
  AppColors._();

  // Netral: flat, mata nyaman. Hirarki kontras bertingkat:
  // foreground (~12:1) > muted (~5.7:1) > comment (~3.9:1) di atas input,
  // dan background < backgroundDark < surface untuk kedalaman tanpa gradien.
  static const Color background = Color(0xFF161C1E);
  static const Color backgroundDark = Color(0xFF232C2F);
  static const Color surface = Color(0xFF2F3A3D);
  static const Color foreground = Color(0xFFE7EBEB);
  static const Color mutedForeground = Color(0xFF9AA6A6);
  static const Color comment = Color(0xFF78888A);

  // Everblush Accent Colors ( dipertahankan: sudah match & lolos kontras
  // 4.9–8.9:1 di atas permukaan input untuk mata nyaman )
  static const Color red = Color(0xFFE57474);
  static const Color green = Color(0xFF8CCF7E);
  static const Color yellow = Color(0xFFE5C76B);
  static const Color blue = Color(0xFF67B0E8);
  static const Color magenta = Color(0xFFC47FD5);
  static const Color cyan = Color(0xFF6CBFBF);
  static const Color white = Color(0xFFB3B9B8);

  // Bright Variants
  static const Color brightRed = Color(0xFFEF7E7E);
  static const Color brightGreen = Color(0xFF96D988);
  static const Color brightYellow = Color(0xFFF4D67A);
  static const Color brightBlue = Color(0xFF71BAF2);
  static const Color brightMagenta = Color(0xFFCE89DF);
  static const Color brightCyan = Color(0xFF67CBE7);

  // Status Colors
  static const Color todo = Color(0xFF67B0E8);
  static const Color inProgress = Color(0xFFE5C76B);
  static const Color done = Color(0xFF8CCF7E);

  // Priority Colors
  static const Color priorityLow = Color(0xFF8CCF7E);
  static const Color priorityMedium = Color(0xFFE5C76B);
  static const Color priorityHigh = Color(0xFFE57474);
}
