import 'package:fitnessapp/config/app_env.dart';
import 'package:fitnessapp/l10n/glow_l10n.dart';
import 'package:fitnessapp/routes.dart';
import 'package:fitnessapp/state/glow_store.dart';
import 'package:fitnessapp/utils/app_colors.dart';
import 'package:fitnessapp/view/splash/splash_screen.dart';
import 'package:flutter/material.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();
  await AppEnv.loadRuntime();
  await GlowStore.instance.load();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: GlowStore.instance,
      builder: (context, _) {
        final locale = Locale(GlowL10n.normalize(GlowStore.instance.localeCode));
        return MaterialApp(
      title: 'GlowCheck',
      locale: locale,
      supportedLocales: GlowL10n.supportedLocales,
      debugShowCheckedModeBanner: false,
      routes: routes,
      theme: ThemeData(
        useMaterial3: true,
        fontFamily: 'Poppins',
        scaffoldBackgroundColor: AppColors.canvas,
        colorScheme: ColorScheme.light(
          primary: AppColors.ink,
          onPrimary: AppColors.card,
          surface: AppColors.card,
          onSurface: AppColors.ink,
        ),
        appBarTheme: const AppBarTheme(
          backgroundColor: AppColors.canvas,
          foregroundColor: AppColors.ink,
          elevation: 0,
        ),
      ),
      home: const SplashScreen(),
    );
      },
    );
  }
}
