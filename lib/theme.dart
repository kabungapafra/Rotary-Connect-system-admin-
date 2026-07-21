import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Colors converted 1:1 from the source design's `oklch(...)` values so the
/// Flutter port matches the original palette exactly (Flutter has no native
/// oklch color support, so each value was pre-converted via the standard
/// OKLCH -> linear sRGB matrices).
class AdminColors {
  // Official Rotary brand: azure blue primary, gold secondary — matches
  // the Rotary Connect logo lockup used on the login screen and sidebar.
  static const accent = Color(0xFF17458F);
  static const gold = Color(0xFFF7A81B);
  static const accentOptions = [
    Color(0xFF17458F), // Rotary azure
    Color(0xFF00246B), // Rotary royal blue
    Color(0xFF0F766E), // teal
    Color(0xFF901F93), // Rotary violet
  ];

  static const pageBg = Color(0xFFF4F6FB);
  static const scrollbarThumb = Color(0xFFCACED3);
  static const placeholder = Color(0xFF83868C);
  static const textBase = Color(0xFF101828);
  // The sidebar is light so the official logo (dark-blue wordmark on
  // transparent) can be used exactly as provided.
  static const sidebarBg = Colors.white;
  static const navSectionLabel = Color(0xFF98A2B3);
  static const navInactiveText = Color(0xFF475467);
  static const sidebarAvatarBg = Color(0xFF17458F);
  static const sidebarEmailText = Color(0xFF98A2B3);
  static const borderLight = Color(0xFFE2E5E8);
  static const textMuted = Color(0xFF646972);
  static const clubInitialsBg = Color(0xFFE5EBF9);
  static const clubInitialsText = Color(0xFF31509D);
  static const memberAvatarBg = Color(0xFFE4E8EF);
  static const memberAvatarText = Color(0xFF434850);
  static const rowBorder = Color(0xFFECEFF1);
  static const sidebarFooterBorder = Color(0xFFE2E5E8);
  static const chartGridline = Color(0xFFE5E8EC);
  static const toastBg = Color(0xFF101828);

  static const paidDot = Color(0xFF0E9254);
  static const paidColor = Color(0xFF005129);
  static const paidTint = Color(0xFFD7F4E0);
  static const dueSoonDot = Color(0xFFC17A00);
  static const dueSoonColor = Color(0xFF9A5600);
  static const dueSoonTint = Color(0xFFFFE6C8);
  static const overdueDot = Color(0xFFD33A3C);
  static const overdueColor = Color(0xFFB71824);
  static const overdueTint = Color(0xFFFFDFDA);

  static const buttonBorder = Color(0xFFDBDEE2);
  static const buttonText = Color(0xFF363B43);
  static const dropdownShadow = Color(0x2911161F);
  static const modalOverlay = Color(0x7311161F);
  static const modalShadow = Color(0x4711161F);
  static const modalShadow2 = Color(0x2611161F);
  static const inputBorder = Color(0xFFD5D8DB);
  static const wizardInactiveBar = Color(0xFFDDE2E6);
  static const wizardTodoLabel = Color(0xFF757B83);
  static const wizardActiveLabel = Color(0xFF151B24);
  static const closeIcon = Color(0x99414853);
  static const statsPlaceholderBg = Color(0xFFE8EBEF);
  static const statsDashedBorder = Color(0xFFBABEC3);
  static const statsPlaceholderText = Color(0xFF6C727B);

  static const smsDeliveredLabel = Color(0xFF156F41);
  static const smsDeliveredValue = Color(0xFF005129);
  static const smsPendingLabel = Color(0xFFAE6800);
  static const smsPendingValue = Color(0xFF9A5600);
  static const smsFailedLabel = Color(0xFFC92F33);
  static const smsFailedValue = Color(0xFFB71824);
}

class StatusStyle {
  final String label;
  final Color dot;
  final Color color;
  final Color tint;
  const StatusStyle(this.label, this.dot, this.color, this.tint);
}

const Map<String, StatusStyle> paymentStatusStyles = {
  'paid': StatusStyle('Paid', AdminColors.paidDot, AdminColors.paidColor, AdminColors.paidTint),
  'due-soon': StatusStyle('Due Soon', AdminColors.dueSoonDot, AdminColors.dueSoonColor, AdminColors.dueSoonTint),
  'overdue': StatusStyle('Overdue', AdminColors.overdueDot, AdminColors.overdueColor, AdminColors.overdueTint),
};

const Map<String, StatusStyle> clubStatusStyles = {
  'active': StatusStyle('Active', AdminColors.paidDot, AdminColors.paidColor, AdminColors.paidTint),
  'suspended': StatusStyle('Suspended', AdminColors.overdueDot, AdminColors.overdueColor, AdminColors.overdueTint),
};

StatusStyle paymentStyleFor(String key) => paymentStatusStyles[key] ?? paymentStatusStyles['paid']!;
StatusStyle clubStyleFor(String key) => clubStatusStyles[key] ?? clubStatusStyles['active']!;

ThemeData buildAdminTheme(Color accent) {
  final textTheme = GoogleFonts.manropeTextTheme();
  return ThemeData(
    useMaterial3: true,
    scaffoldBackgroundColor: AdminColors.pageBg,
    fontFamily: GoogleFonts.manrope().fontFamily,
    textTheme: textTheme.apply(
      bodyColor: AdminColors.textBase,
      displayColor: AdminColors.textBase,
    ),
    colorScheme: ColorScheme.fromSeed(seedColor: accent, primary: accent),
    scrollbarTheme: ScrollbarThemeData(
      thumbColor: WidgetStateProperty.all(AdminColors.scrollbarThumb),
    ),
  );
}
