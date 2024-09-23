import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/pages/settings.dart';
import 'package:weather_app/pages/weather_home.dart';
import 'package:weather_app/weather_provider.dart';


void main() {
  WidgetsFlutterBinding.ensureInitialized();
  SystemChrome.setPreferredOrientations([
    DeviceOrientation.portraitUp
  ]);
  runApp(ChangeNotifierProvider(
      create: (context)=> WeatherProvider(),
      child: const MyApp()));
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {

    return MaterialApp(
      debugShowCheckedModeBanner: false,
      title: 'Flutter Demo',
      theme: ThemeData(

        colorScheme: ColorScheme.fromSeed(
            brightness: Brightness.dark,
            seedColor: Colors.deepPurple),
        useMaterial3: true,
      ),
      routes:{
        WeatherHome.routName : (context)=> const WeatherHome(),
        SettingsPage.routName : (context)=> const SettingsPage(),
      } ,
      initialRoute: WeatherHome.routName,
    );
  }
}