
import 'package:fitnessapp/view/dashboard/dashboard_screen.dart';
import 'package:fitnessapp/view/finish_workout/finish_workout_screen.dart';
import 'package:fitnessapp/view/login/login_screen.dart';
import 'package:fitnessapp/view/on_boarding/on_boarding_screen.dart';
import 'package:fitnessapp/view/splash/splash_screen.dart';
import 'package:fitnessapp/view/profile/language_screen.dart';
import 'package:fitnessapp/view/legal/legal_screen.dart';
import 'package:fitnessapp/view/paywall/paywall_screen.dart';
import 'package:flutter/material.dart';

final Map<String, WidgetBuilder> routes = {
  SplashScreen.routeName: (context) => const SplashScreen(),
  OnBoardingScreen.routeName: (context) => const OnBoardingScreen(),
  LoginScreen.routeName: (context) => const LoginScreen(),
  DashboardScreen.routeName: (context) => const DashboardScreen(),
  FinishWorkoutScreen.routeName: (context) => const FinishWorkoutScreen(),
  PaywallScreen.routeName: (context) => const PaywallScreen(),
  LegalScreen.termsRoute: (context) => const LegalScreen(privacy: false),
  LegalScreen.privacyRoute: (context) => const LegalScreen(privacy: true),
  LanguageScreen.routeName: (context) => const LanguageScreen(),
};
