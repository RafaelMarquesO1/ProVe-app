import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:prove/routes.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';
import 'package:prove/services/app_theme_controller.dart';
import 'package:prove/services/notification_service.dart';
import 'package:prove/services/update_service.dart';


void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await initializeDateFormatting('pt_BR', null);
  // Inicializa o serviço de notificações
  await NotificationService().init();
  // Verifica se há atualização disponível na Play Store
  await UpdateService.checkForUpdate();

  runApp(const MyApp());
}

class SmoothScrollBehavior extends ScrollBehavior {
  const SmoothScrollBehavior();

  @override
  ScrollPhysics getScrollPhysics(BuildContext context) {
    return const BouncingScrollPhysics(
      parent: AlwaysScrollableScrollPhysics(),
    );
  }
}

class MyApp extends StatefulWidget {
  const MyApp({super.key});

  @override
  State<MyApp> createState() => _MyAppState();
}

class _MyAppState extends State<MyApp> {
  final AppThemeController _themeController = AppThemeController.instance;

  @override
  void initState() {
    super.initState();
    _themeController.init();
  }

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Color.fromRGBO(224, 159, 62, 1);
    const Color lightBackgroundColor = Color(0xFFFFF9F0);
    const Color darkBackgroundColor = Color(0xFF121212);

    final TextTheme baseTextTheme = TextTheme(
      displayLarge: GoogleFonts.oswald(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: primarySeedColor,
      ),
      titleMedium: GoogleFonts.lato(fontSize: 16),
      labelLarge: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
      bodyMedium: GoogleFonts.lato(fontSize: 14),
    );

    final ThemeData lightTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: lightBackgroundColor,
      cardColor: Colors.white,
      dividerColor: Colors.grey.shade200,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
        surface: lightBackgroundColor,
      ),
      textTheme: baseTextTheme
          .apply(
            // Preto quase puro: contraste ~12:1 sobre o fundo creme (#FFF9F0)
            bodyColor: const Color(0xFF1A1A1A),
            displayColor: const Color(0xFF1A1A1A),
          )
          .copyWith(
            displayLarge: baseTextTheme.displayLarge,
          ),
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primarySeedColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primarySeedColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primarySeedColor.withOpacity(0.4),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: baseTextTheme.labelLarge?.copyWith(letterSpacing: 1.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: Colors.white,
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: Colors.grey.shade300),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primarySeedColor, width: 2),
        ),
        // Color(0xFF5C5C5C): contraste ~4.6:1 sobre branco — passa WCAG AA
        labelStyle: const TextStyle(color: Color(0xFF5C5C5C)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primarySeedColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primarySeedColor,
            );
          }
          // Color(0xFF5C5C5C): contraste ~4.6:1 sobre fundo claro — passa WCAG AA
          return GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF5C5C5C),
          );
        }),
      ),
      cardTheme: CardThemeData(
        color: Colors.white,
        elevation: 8,
        shadowColor: Colors.black.withOpacity(0.06),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      listTileTheme: const ListTileThemeData(
        // Color(0xFF424242): contraste ~7.5:1 sobre branco
        iconColor: Color(0xFF424242),
        textColor: Color(0xFF1A1A1A),
      ),
      dividerTheme: DividerThemeData(
        color: Colors.grey.shade200,
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: Colors.white,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
      ),
      snackBarTheme: SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Colors.black87,
        contentTextStyle: const TextStyle(color: Colors.white),
      ),
    );

    final ThemeData darkTheme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: darkBackgroundColor,
      cardColor: const Color(0xFF1E1E1E),
      dividerColor: const Color(0xFF2C2C2E),
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.dark,
        surface: darkBackgroundColor,
        surfaceContainerHighest: const Color(0xFF2C2C2E),
        onSurface: const Color(0xFFEAEAEA),
      ),
      textTheme: baseTextTheme
          .apply(
            bodyColor: const Color(0xFFEAEAEA),
            displayColor: const Color(0xFFEAEAEA),
          )
          .copyWith(
            displayLarge: baseTextTheme.displayLarge?.copyWith(color: primarySeedColor),
          ),
      appBarTheme: const AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: Colors.white),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primarySeedColor,
          foregroundColor: Colors.white,
          elevation: 4,
          shadowColor: primarySeedColor.withOpacity(0.25),
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(16),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16, horizontal: 24),
          textStyle: baseTextTheme.labelLarge?.copyWith(letterSpacing: 1.2),
        ),
      ),
      inputDecorationTheme: InputDecorationTheme(
        filled: true,
        fillColor: const Color(0xFF1E1E1E),
        contentPadding: const EdgeInsets.symmetric(
          horizontal: 20,
          vertical: 16,
        ),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide.none,
        ),
        enabledBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: Color(0xFF2C2C2E)),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: const BorderSide(color: primarySeedColor, width: 2),
        ),
        labelStyle: const TextStyle(color: Color(0xFFAAAAAA)),
        hintStyle: const TextStyle(color: Color(0xFF666666)),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primarySeedColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      navigationBarTheme: NavigationBarThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        surfaceTintColor: Colors.transparent,
        indicatorColor: primarySeedColor.withOpacity(0.15),
        labelTextStyle: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return GoogleFonts.lato(
              fontSize: 12,
              fontWeight: FontWeight.bold,
              color: primarySeedColor,
            );
          }
          return GoogleFonts.lato(
            fontSize: 12,
            fontWeight: FontWeight.w500,
            color: const Color(0xFF888888),
          );
        }),
        iconTheme: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return const IconThemeData(color: primarySeedColor);
          }
          return const IconThemeData(color: Color(0xFF888888));
        }),
      ),
      cardTheme: CardThemeData(
        color: const Color(0xFF1E1E1E),
        elevation: 0,
        shadowColor: Colors.transparent,
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(20)),
      ),
      listTileTheme: const ListTileThemeData(
        iconColor: Color(0xFFAAAAAA),
        textColor: Color(0xFFEAEAEA),
      ),
      dividerTheme: const DividerThemeData(
        color: Color(0xFF2C2C2E),
        thickness: 1,
      ),
      dialogTheme: DialogThemeData(
        backgroundColor: const Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(borderRadius: BorderRadius.circular(22)),
        titleTextStyle: const TextStyle(
          color: Color(0xFFEAEAEA),
          fontSize: 18,
          fontWeight: FontWeight.bold,
        ),
        contentTextStyle: const TextStyle(
          color: Color(0xFFAAAAAA),
          fontSize: 14,
        ),
      ),
      snackBarTheme: const SnackBarThemeData(
        behavior: SnackBarBehavior.floating,
        backgroundColor: Color(0xFF2C2C2E),
        contentTextStyle: TextStyle(color: Color(0xFFEAEAEA)),
        actionTextColor: primarySeedColor,
      ),
      switchTheme: SwitchThemeData(
        thumbColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) return primarySeedColor;
          return const Color(0xFF666666);
        }),
        trackColor: WidgetStateProperty.resolveWith((states) {
          if (states.contains(WidgetState.selected)) {
            return primarySeedColor.withOpacity(0.4);
          }
          return const Color(0xFF2C2C2E);
        }),
      ),
      bottomSheetTheme: const BottomSheetThemeData(
        backgroundColor: Color(0xFF1E1E1E),
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.vertical(top: Radius.circular(24)),
        ),
      ),
    );

    return AnimatedBuilder(
      animation: _themeController,
      builder: (context, _) {
        final isDark = _themeController.themeMode == ThemeMode.dark ||
            (_themeController.themeMode == ThemeMode.system &&
                WidgetsBinding.instance.platformDispatcher.platformBrightness ==
                    Brightness.dark);
        SystemChrome.setSystemUIOverlayStyle(
          SystemUiOverlayStyle(
            statusBarColor: Colors.transparent,
            statusBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
            statusBarBrightness: isDark ? Brightness.dark : Brightness.light,
            systemNavigationBarColor:
                isDark ? const Color(0xFF1C1C1E) : Colors.white,
            systemNavigationBarIconBrightness:
                isDark ? Brightness.light : Brightness.dark,
          ),
        );
        return MaterialApp.router(
          scrollBehavior: const SmoothScrollBehavior(),
          debugShowCheckedModeBanner: false,
          title: 'ProVê',
          theme: lightTheme,
          darkTheme: darkTheme,
          themeMode: _themeController.themeMode,
          routerConfig: router, // Usa o GoRouter para navegação
          localizationsDelegates: const [
            GlobalMaterialLocalizations.delegate,
            GlobalWidgetsLocalizations.delegate,
            GlobalCupertinoLocalizations.delegate,
          ],
          supportedLocales: const [
            Locale('pt', 'BR'),
          ],
          locale: const Locale('pt', 'BR'),
        );
      },
    );
  }
}
