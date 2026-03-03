import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:myapp/routes.dart'; // Importa a configuração de rotas
import 'package:flutter_localizations/flutter_localizations.dart'; // Import para localização
import 'package:intl/date_symbol_data_local.dart'; // Import para inicialização de data

void main() async { // Transforma o main em assíncrono
  WidgetsFlutterBinding.ensureInitialized(); // Garante a inicialização dos widgets
  await initializeDateFormatting('pt_BR', null); // Inicializa a formatação para pt_BR
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    const Color primarySeedColor = Color.fromRGBO(224, 159, 62, 1);
    const Color backgroundColor = Color(0xFFFFF9F0);

    final TextTheme appTextTheme = TextTheme(
      displayLarge: GoogleFonts.oswald(
        fontSize: 48,
        fontWeight: FontWeight.bold,
        color: primarySeedColor,
      ),
      titleMedium: GoogleFonts.lato(fontSize: 16, color: Colors.black87),
      labelLarge: GoogleFonts.lato(fontSize: 16, fontWeight: FontWeight.bold),
      bodyMedium: GoogleFonts.lato(fontSize: 14),
    );

    final ThemeData theme = ThemeData(
      useMaterial3: true,
      scaffoldBackgroundColor: backgroundColor,
      colorScheme: ColorScheme.fromSeed(
        seedColor: primarySeedColor,
        brightness: Brightness.light,
        background: backgroundColor,
      ),
      textTheme: appTextTheme,
      appBarTheme: AppBarTheme(
        backgroundColor: Colors.transparent,
        elevation: 0,
        iconTheme: IconThemeData(color: primarySeedColor),
      ),
      elevatedButtonTheme: ElevatedButtonThemeData(
        style: ElevatedButton.styleFrom(
          backgroundColor: primarySeedColor,
          foregroundColor: Colors.white,
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(12),
          ),
          padding: const EdgeInsets.symmetric(vertical: 16),
          textStyle: appTextTheme.labelLarge,
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
        labelStyle: TextStyle(color: Colors.grey.shade600),
      ),
      textButtonTheme: TextButtonThemeData(
        style: TextButton.styleFrom(
          foregroundColor: primarySeedColor,
          textStyle: const TextStyle(
            fontWeight: FontWeight.bold,
            decoration: TextDecoration.underline,
          ),
        ),
      ),
    );

    return MaterialApp.router(
      title: 'Sabedoria Diária',
      theme: theme,
      routerConfig: router, // Usa o GoRouter para navegação
      // Configuração de Localização
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],
      supportedLocales: const [
        Locale('pt', 'BR'), // Português do Brasil
      ],
      locale: const Locale('pt', 'BR'), // Define o locale padrão
    );
  }
}
