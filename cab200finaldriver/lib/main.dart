//import 'package:cab200/screens/main_page.dart';
import 'package:cab200finaldriver/infoHandler/app_info.dart';
import 'package:cab200finaldriver/screens/car_info_screen.dart';
import 'package:cab200finaldriver/screens/login_screen.dart';
import 'package:cab200finaldriver/screens/register_screen.dart';
import 'package:cab200finaldriver/splashScreen/splash_screen.dart';
import 'package:cab200finaldriver/themeProvider/theme_provider.dart';
import 'package:firebase_core/firebase_core.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';


Future<void> main() async {
  runApp(const MyApp());
  WidgetsFlutterBinding.ensureInitialized();
  await Firebase.initializeApp();
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return  ChangeNotifierProvider(
      create: (context) => AppInfo(),
      child: MaterialApp(
      title: 'Flutter Demo',
      themeMode: ThemeMode.system,
      theme: MyThemes.lightTheme,
      darkTheme: MyThemes.darkTheme,
      debugShowCheckedModeBanner: false,
      home:  const SplashScreen(),
    ),
    );
  }
}