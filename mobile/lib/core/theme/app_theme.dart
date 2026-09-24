import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
class AppColors {
  // New Brand Tokens (CBT Companion Design Spec)
  static const bgPrimary = Color(0xFFFAF7F2); // warm cream
  static const bgSecondary = Color(0xFFF2EDE4); // soft beige
  static const bgCard = Color(0xFFFFFFFF); // white card
  
  static const textPrimary = Color(0xFF3D3229); // warm dark brown
  static const textSecondary = Color(0xFF6B5D4F); // muted brown
  static const textTertiary = Color(0xFF9B8B7A); // light brown
  
  static const primary = Color(0xFF7C9A7E); // sage green
  static const primaryHover = Color(0xFF6B876D);
  static const primaryLight = Color(0xFFE8EFE9); // sage tint
  
  // Semantic Colors
  static const success = Color(0xFF7C9A7E);
  static const warning = Color(0xFFD9A57E);
  static const error = Color(0xFFC97B7B);
  static const info = Color(0xFF8FA8B8);
  
  static const borderSoft = Color(0xFFE8E0D5);
  static const borderMedium = Color(0xFFD4C8B8);

  // Legacy variables to prevent errors in other files before full migration
  static const lightPrimary = primary;
  static const lightSecondary = Color(0xFFD9A57E);
  static const lightBackground = bgPrimary;
  static const lightSurface = bgSecondary;
  static const lightCard = bgCard;
  static const lightTextPrimary = textPrimary;
  static const lightTextSecondary = textSecondary;
  static const lightDivider = borderSoft;

  static const darkPrimary = Color(0xFF818CF8); 
  static const darkSecondary = Color(0xFF2DD4BF); 
  static const darkBackground = Color(0xFF0F1115); 
  static const darkSurface = Color(0xFF16181D); 
  static const darkCard = Color(0xFF1C1F26); 
  static const darkTextPrimary = Color(0xFFE2E8F0); 
  static const darkTextSecondary = Color(0xFF94A3B8); 
  static const darkDivider = Color(0xFF2A2D35); 
  
  static const crisisRed = error;
  static const crisisRedDark = error;

  static const chipColors = [
    Color(0xFF6C63FF),
    Color(0xFFFF6F91),
    Color(0xFF00BFA5),
    Color(0xFFFF8A65),
    Color(0xFF42A5F5),
    Color(0xFFAB47BC),
    Color(0xFFFFCA28),
    Color(0xFF26C6DA),
    Color(0xFFEF5350),
    Color(0xFF66BB6A),
  ];

  static const Map<String, Map<String, List<Color>>> themeVariants = {
    'default': {
      'light': [Color(0xFF7C9A7E), Color(0xFFD9A57E), Color(0xFFFAF7F2), Color(0xFFF2EDE4), Color(0xFF3D3229), Color(0xFF6B5D4F)],
      'dark': [Color(0xFF8BA68D), Color(0xFFE0B494), Color(0xFF1E1A17), Color(0xFF2C2621), Color(0xFFF2EDE4), Color(0xFFC4B8A8)],
    },
    'bamboo': {
      'light': [Color(0xFF86A789), Color(0xFF739072), Color(0xFFF5F7F3), Color(0xFFE9EFE6), Color(0xFF2A3D2A), Color(0xFF4A5C4A)],
      'dark': [Color(0xFF4A5C4A), Color(0xFF86A789), Color(0xFF1B241B), Color(0xFF2A342A), Color(0xFFD2E3C6), Color(0xFF86A789)],
    },
    'marigold': {
      'light': [Color(0xFF909C7B), Color(0xFFD5A760), Color(0xFFF8F9F4), Color(0xFFEBECE0), Color(0xFF2C3224), Color(0xFF686C5A)],
      'dark': [Color(0xFFA5B38D), Color(0xFFE2B773), Color(0xFF1A1C16), Color(0xFF252720), Color(0xFFF8F9F4), Color(0xFF909C7B)],
    },
    'twilight': {
      'light': [Color(0xFF978FAD), Color(0xFFD5B4B4), Color(0xFFF7F5FA), Color(0xFFEBE7F2), Color(0xFF322E3D), Color(0xFF6B6577)],
      'dark': [Color(0xFFAFA9C1), Color(0xFFE0C1C1), Color(0xFF1C1A24), Color(0xFF262330), Color(0xFFF7F5FA), Color(0xFF978FAD)],
    },
    'coastal': {
      'light': [Color(0xFF7BA1A8), Color(0xFFDFBFA0), Color(0xFFF4F7F8), Color(0xFFE6EEF0), Color(0xFF26373A), Color(0xFF5D7175)],
      'dark': [Color(0xFF8FB2B9), Color(0xFFE8CBAD), Color(0xFF161E1F), Color(0xFF202A2C), Color(0xFFF4F7F8), Color(0xFF7BA1A8)],
    },
  };
}
class AppTheme {
  static ThemeData get lightTheme {
    return ThemeData(
      useMaterial3: true,
      brightness: Brightness.light,
      colorScheme: const ColorScheme.light(
        primary: AppColors.primary,
        secondary: AppColors.warning,
        surface: AppColors.bgSecondary,
        error: AppColors.error,
      ),
      scaffoldBackgroundColor: AppColors.bgPrimary,
      cardColor: AppColors.bgCard,
      dividerColor: AppColors.borderSoft,
      textTheme: _buildTextTheme(
        AppColors.textPrimary,
        AppColors.textSecondary,
      ),
      appBarTheme: AppBarTheme(
        backgroundColor: AppColors.bgPrimary,
        foregroundColor: AppColors.textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: AppColors.textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: AppColors.bgCard,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSoft),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: AppColors.bgSecondary,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSoft, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.nunito(
          color: AppColors.textTertiary,
          fontSize: 15,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: AppColors.primary,
          foregroundColor: AppColors.bgPrimary,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          textStyle: GoogleFonts.nunito(
            fontSize: 15,
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: AppColors.primary,
        foregroundColor: AppColors.bgPrimary,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: AppColors.bgCard,
        selectedItemColor: AppColors.primary,
        unselectedItemColor: AppColors.textTertiary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.nunito(
          fontSize: 12,
          fontWeight: FontWeight.bold,
        ),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: AppColors.bgSecondary,
        labelStyle: GoogleFonts.nunito(
          fontSize: 14,
          fontWeight: FontWeight.w500,
          color: AppColors.textSecondary,
        ),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: AppColors.textPrimary, // dark brown
        contentTextStyle: GoogleFonts.nunito(color: AppColors.bgPrimary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  static ThemeData getTheme(String themeName, {required Brightness brightness}) {
    final mode = brightness == Brightness.light ? 'light' : 'dark';
    
    final themeData = AppColors.themeVariants[themeName] ?? AppColors.themeVariants['default']!;
    final variant = themeData[mode]!;
    
    final primary = variant[0];
    final secondary = variant[1];
    final bg = variant[2];
    final surface = variant[3];
    final textPrimary = variant[4];
    final textSecondary = variant[5];

    return ThemeData(
      useMaterial3: true,
      brightness: brightness,
      colorScheme: ColorScheme(
        brightness: brightness,
        primary: primary,
        onPrimary: bg,
        secondary: secondary,
        onSecondary: bg,
        error: AppColors.error,
        onError: Colors.white,
        surface: surface,
        onSurface: textPrimary,
      ),
      scaffoldBackgroundColor: bg,
      cardColor: surface,
      dividerColor: AppColors.borderMedium,
      textTheme: _buildTextTheme(textPrimary, textSecondary),
      appBarTheme: AppBarTheme(
        backgroundColor: bg,
        foregroundColor: textPrimary,
        elevation: 0,
        centerTitle: false,
        titleTextStyle: GoogleFonts.fraunces(
          fontSize: 22,
          fontWeight: FontWeight.w600,
          color: textPrimary,
        ),
      ),
      cardTheme: CardThemeData(
        color: surface,
        elevation: 0,
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(20),
          side: const BorderSide(color: AppColors.borderSoft),
        ),
        margin: const EdgeInsets.symmetric(horizontal: 16, vertical: 6),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: surface,
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: AppColors.borderSoft, width: 1.5),
        ),
        contentPadding: const EdgeInsets.symmetric(horizontal: 16, vertical: 14),
        hintStyle: GoogleFonts.nunito(
          color: textSecondary,
          fontSize: 15,
        ),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primary,
          foregroundColor: bg,
          elevation: 0,
          padding: const EdgeInsets.symmetric(horizontal: 32, vertical: 16),
          shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(16)),
          textStyle: GoogleFonts.nunito(fontSize: 15, fontWeight: FontWeight.bold),
        ),
      ),
      floatingActionButtonTheme: FloatingActionButtonThemeData(
        backgroundColor: primary,
        foregroundColor: bg,
        elevation: 4,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(24)),
      ),
      bottomNavigationBarTheme: BottomNavigationBarThemeData(
        backgroundColor: surface,
        selectedItemColor: primary,
        unselectedItemColor: textSecondary,
        type: BottomNavigationBarType.fixed,
        elevation: 8,
        selectedLabelStyle: GoogleFonts.nunito(fontSize: 12, fontWeight: FontWeight.bold),
        unselectedLabelStyle: GoogleFonts.nunito(fontSize: 12),
      ),
      chipTheme: ChipThemeData(
        backgroundColor: surface,
        labelStyle: GoogleFonts.nunito(fontSize: 14, fontWeight: FontWeight.w500, color: textSecondary),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(999)),
        padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 8),
      ),
      snackBarTheme: SnackBarThemeData(
        backgroundColor: textPrimary,
        contentTextStyle: GoogleFonts.nunito(color: bg),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(12)),
        behavior: SnackBarBehavior.floating,
      ),
    );
  }
  static ThemeData get darkTheme => getTheme('default', brightness: Brightness.dark);
  static TextTheme _buildTextTheme(Color primary, Color secondary) {
    return TextTheme(
      displayLarge: GoogleFonts.fraunces(
        fontSize: 32,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      displayMedium: GoogleFonts.fraunces(
        fontSize: 28,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      displaySmall: GoogleFonts.fraunces(
        fontSize: 24,
        fontWeight: FontWeight.w600,
        color: primary,
      ),
      headlineLarge: GoogleFonts.fraunces(
        fontSize: 22,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      headlineMedium: GoogleFonts.fraunces(
        fontSize: 20,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      headlineSmall: GoogleFonts.fraunces(
        fontSize: 18,
        fontWeight: FontWeight.w500,
        color: primary,
      ),
      titleLarge: GoogleFonts.nunito(
        fontSize: 18,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
      titleMedium: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
      titleSmall: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
      bodyLarge: GoogleFonts.nunito(
        fontSize: 16,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: primary,
      ),
      bodyMedium: GoogleFonts.nunito(
        fontSize: 14,
        fontWeight: FontWeight.w400,
        height: 1.6,
        color: primary,
      ),
      bodySmall: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w400,
        height: 1.5,
        color: secondary,
      ),
      labelLarge: GoogleFonts.nunito(
        fontSize: 15,
        fontWeight: FontWeight.bold,
        color: primary,
      ),
      labelMedium: GoogleFonts.nunito(
        fontSize: 12,
        fontWeight: FontWeight.w600,
        color: secondary,
      ),
      labelSmall: GoogleFonts.nunito(
        fontSize: 10,
        fontWeight: FontWeight.w500,
        color: secondary,
      ),
    );
  }
}
