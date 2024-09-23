import 'dart:convert';
import 'package:flutter/foundation.dart';
import 'package:http/http.dart'as http;
import 'package:geocoding/geocoding.dart' as geo;
import 'package:shared_preferences/shared_preferences.dart';
import 'package:geolocator/geolocator.dart';
import 'package:weather_app/responses/current_response.dart';
import 'package:weather_app/responses/forecast_response.dart';
import 'package:weather_app/units/constans.dart';


class WeatherProvider with ChangeNotifier {

  final _statusKey='status';
  CurrentResponse? currentResponse;
  ForecastResponse? forecastResponse;
  double latitude = 0.0;
  double longitude = 0.0;
  String unitSymbol = celsius;
  String _unit = 'metric';

  bool get hasDataLoaded => currentResponse != null && forecastResponse != null;
  void setUnit(bool status){
    _unit = status? imperial: metric ;
    unitSymbol = status? fahrenheit : celsius;

  }


  Future<void>getWeatherData()async{
    await _getCurrentWeather();
    await _getForecastWeather();
  }


  Future<void> _getCurrentWeather() async {
    final uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/weather?lat=$latitude&lon=$longitude&appid=$weatherApiKey&units=$_unit');
    try {

    } catch (error) {
      print(error.toString());
    }
    http.Response response = await http.get(uri);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      currentResponse = CurrentResponse.fromJson(map);
      notifyListeners();
    }
    else {
      print(map['message']);
    }
  }

  Future<void> _getForecastWeather() async {
    final uri = Uri.parse(
        'https://api.openweathermap.org/data/2.5/forecast?lat=$latitude&lon=$longitude&appid=$weatherApiKey&units=$_unit');
    try {

    } catch (error) {
      print(error.toString());
    }
    http.Response response = await http.get(uri);
    final map = jsonDecode(response.body) as Map<String, dynamic>;
    if (response.statusCode == 200) {
      forecastResponse = ForecastResponse.fromJson(map);
      notifyListeners();
    }
    else {
      print(map['message']);
    }
  }



  Future<bool> setTemStatus(bool status)async{
    final prefs = await SharedPreferences.getInstance();
    return prefs.setBool(_statusKey, status);
  }

  Future<void>convertCityToLatLng(String city)async{
    try{
      final locationList = await geo.locationFromAddress(city);
      if (locationList.isNotEmpty){
        final location = locationList.first ;
        latitude = location.latitude;
        longitude = location.longitude;
      }
    }catch(error){
      print(error);
    }
  }


  Future<bool> getTemStatus()async{
    final prefs = await SharedPreferences.getInstance();
    return prefs.getBool(_statusKey)?? false;
  }


  /// Determine the current position of the device.
  ///
  /// When the location services are not enabled or permissions
  /// are denied the `Future` will return an error.
  Future<void >determinePosition() async {
    bool serviceEnabled;
    LocationPermission permission;

    // Test if location services are enabled.
    serviceEnabled = await Geolocator.isLocationServiceEnabled();
    if (!serviceEnabled) {
      // Location services are not enabled don't continue
      // accessing the position and request users of the
      // App to enable the location services.
      return Future.error('Location services are disabled.');
    }

    permission = await Geolocator.checkPermission();
    if (permission == LocationPermission.denied) {
      permission = await Geolocator.requestPermission();
      if (permission == LocationPermission.denied) {
        // Permissions are denied, next time you could try
        // requesting permissions again (this is also where
        // Android's shouldShowRequestPermissionRationale
        // returned true. According to Android guidelines
        // your App should show an explanatory UI now.
        return Future.error('Location permissions are denied');
      }
    }

    if (permission == LocationPermission.deniedForever) {
      // Permissions are denied forever, handle appropriately.
      return Future.error(
          'Location permissions are permanently denied, we cannot request permissions.');
    }

    // When we reach here, permissions are granted and we can
    // continue accessing the position of the device.
    final position= await Geolocator.getCurrentPosition();
    latitude = position.latitude;
    longitude = position.longitude;
  }
}