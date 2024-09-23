import 'dart:async';
import 'dart:ui';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:connectivity_plus/connectivity_plus.dart';
import 'package:flutter/material.dart';
import 'package:provider/provider.dart';
import 'package:weather_app/custom_widgets/app_background.dart';
import 'package:weather_app/pages/settings.dart';
import 'package:weather_app/responses/current_response.dart';
import 'package:weather_app/responses/forecast_response.dart';
import 'package:weather_app/units/constans.dart';
import 'package:weather_app/units/helper_functions.dart';
import '../weather_provider.dart';

class WeatherHome extends StatefulWidget {
  const WeatherHome({super.key});
  static const String routName = '/';

  @override
  State<WeatherHome> createState() => _WeatherHomeState();
}

class _WeatherHomeState extends State<WeatherHome> {
  bool isConnected = true ;
  late StreamSubscription<List<ConnectivityResult>>subscription;
  Future<void>getData()async{
    if (await isConnectedToInternet()) {
      await context.read<WeatherProvider>().determinePosition();
      final status = await context.read<WeatherProvider>().getTemStatus();
      context.read<WeatherProvider>().setUnit(status);
      await context.read<WeatherProvider>().getWeatherData();
    }
    else{
      setState(() {
        isConnected = false ;
      });
    }
  }

  Future<bool>isConnectedToInternet()async{
    final result = await Connectivity().checkConnectivity();
    return result.contains(ConnectivityResult.mobile)||
        result.contains(ConnectivityResult.wifi);

  }

  @override
  void didChangeDependencies() {
    subscription = Connectivity().onConnectivityChanged.listen((result){
      if (result.contains(ConnectivityResult.wifi)|| result.contains(ConnectivityResult.mobile)){
        setState(() {
          isConnected = true;
          getData();
        });
      }
      else{
        setState(() {
          isConnected = false;
        });
      }
    });
    getData();
    super.didChangeDependencies();
  }

  @override
  Widget build(BuildContext context) {

    return Scaffold(
      extendBodyBehindAppBar: true,
      appBar: AppBar(
        backgroundColor: Colors.transparent,
        title: const Text('SKY SAGA',
          style: TextStyle( fontSize: 30.0 ),
        ),
        actions: [
          IconButton(
              onPressed: (){
                getData();
              },
              icon: const Icon(Icons.location_on)),

          IconButton(onPressed: (){
            showSearch(
                context: context,
                delegate: _citySearchDeligate()
            ).then((city)async{
              if (city!=null &&  city.isNotEmpty){
                await context.read<WeatherProvider>().convertCityToLatLng(city);
                await context.read<WeatherProvider>().getWeatherData();
              }
            });
          },
              icon: const Icon(Icons.search)
          ),
          IconButton(
              onPressed: ()=>Navigator.pushNamed(context, SettingsPage.routName),
              icon: const Icon(Icons.settings))
        ],
      ),


      body: Consumer<WeatherProvider>(
        builder: (context, provider, child) => provider.hasDataLoaded?
        Stack(
          children: [
            const AppBackground(),
            Column(
              children: [
                const SizedBox(
                  height: 80,
                ),
                if (!isConnected) Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Container(
                    padding: EdgeInsets.all(8.0),
                    width: double.infinity,
                    alignment: Alignment.center,
                    color: Colors.black26,
                    child: const Text('No internet connection'),
                  ),
                ),
                CurrentWeatherView(current: provider.currentResponse!,
                    symbol: provider.unitSymbol
                ),
                const Spacer(),
                ForecastWeatherView(items: provider.forecastResponse!.list!,
                    symbol: provider.unitSymbol),
              ],
            ),
          ],
        )
            :Center(child: isConnected?  const CircularProgressIndicator():
        Stack(
          children: [
            AppBackground(),
            BackdropFilter(filter: ImageFilter.blur(sigmaY: 10.0 , sigmaX: 10.0)),
            Center(child: Text('No internet connection')),
          ],
        )
        ),
      ),
    );

  }


  @override
  void dispose() {
    subscription.cancel();
    super.dispose();
  }


}



class CurrentWeatherView extends StatelessWidget {
  const CurrentWeatherView({
    super.key ,
    required this.current,
    required this.symbol
  });
  final CurrentResponse current ;
  final String symbol ;


  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(8.0),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Text(getFormattedDateTime(current.dt!), style: TextStyle(fontSize: 18.0),),
          Text('${current.name},${current.sys!.country}', style: TextStyle(fontSize: 18.0),),
          Row(

            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Image.network(getIconUrl(current.weather!.first.icon!)),
              Text(
                '${current.main!.temp!.round()}$degree$symbol',
                style: const TextStyle(fontSize: 70),
              )
            ],
          ),
          Row(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Text(
                'Feels like ${current.main!.feelsLike!.round()}$degree$symbol ',
                style: const TextStyle(
                    fontSize: 18.0
                ),
              ),
              SizedBox(
                width: 10.0,
              ),

              Text(
                '${current.weather!.first.main} - ${current.weather!.first.description}',
                style: const TextStyle(
                    fontSize: 18.0
                ),
              ),

            ],
          ),
          Padding(
            padding: const EdgeInsets.all(8.0),
            child: Wrap(
              crossAxisAlignment: WrapCrossAlignment.center,
              children: [
                Card(
                  color: Colors.white12,
                  child: Padding(padding: EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text('Sunrise ${getFormattedDateTime(current.sys!.sunrise!, pattern: 'hh:mm a')}', ),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 10.0,
                ),
                Card(
                  color: Colors.white12,
                  child: Padding(padding: EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text('Sunset ${getFormattedDateTime(current.sys!.sunset!, pattern: 'hh:mm a')}'),
                      ],
                    ),
                  ),
                ),
                SizedBox(
                  width: 10.0,
                ),
                Card(
                  color: Colors.white12,
                  child: Padding(padding: EdgeInsets.all(8.0),
                    child: Column(
                      children: [
                        Text('Humidity ${current.main!.humidity}%'),
                      ],
                    ),
                  ),
                ),

              ],

            ),
          )

        ],
      ),
    );
  }
}


class ForecastWeatherView extends StatelessWidget {
  const ForecastWeatherView({
    super.key,
    required this.items,
    required this.symbol,

  });
  final List<ForecastItem> items;
  final String symbol ;
  @override
  Widget build(BuildContext context) {

    return SizedBox(
      height: 200,
      child: ListView.builder (
          scrollDirection: Axis.horizontal,
          itemCount: items.length,
          itemBuilder:  (context , index){
            final item = items[index];
            return SizedBox(
              width: 100.0,
              child: Card(
                color: Colors.white10,
                child: Padding(
                  padding: const EdgeInsets.all(8.0),
                  child: Column(
                    children: [
                      Text(getFormattedDateTime(item.dt! ,pattern: 'EEE hh:mm a')),
                      CachedNetworkImage(
                        imageUrl: getIconUrl(item.weather!.first.icon!),
                        width: 40.0,
                        height: 40.0,
                        placeholder: (context, url) => CircularProgressIndicator(),
                        errorWidget: (context, url, error) => const Icon(Icons.error),
                      ),
                      Text(
                        '${item.weather!.first.main}-\n ${item.weather!.first.description}',
                        textAlign: TextAlign.center,
                        style: const TextStyle(
                            fontSize: 18.0
                        ),
                      ),


                    ],
                  ),
                ),
              ),
            );
          }
      ),
    );
  }
}


class _citySearchDeligate extends SearchDelegate <String>{
  @override
  List<Widget>? buildActions(BuildContext context) {
    return [
      IconButton(onPressed: (){
        query = '';
      },
        icon: const Icon(Icons.clear),
      ),
    ];
  }

  @override
  Widget? buildLeading(BuildContext context) {
    return IconButton(
      onPressed: (){
        close(context, query);
      },
      icon: const Icon(Icons.arrow_back),
    );
  }

  @override
  Widget buildResults(BuildContext context) {
    return ListTile(
      onTap: (){
        close(context, query);
      } ,
      title: Text(query),
    );
  }

  @override
  Widget buildSuggestions(BuildContext context) {
    final filteredList = query.isEmpty? majorCities :
    majorCities.where((city)=>city.toLowerCase().startsWith(query.toLowerCase())).toList();
    return ListView.builder(
        itemCount: filteredList.length,
        itemBuilder: (context , index){
          final city = filteredList[index];
          return ListTile(
            onTap: (){
              close(context, city);
            } ,
            title: Text(city),
          );
        }
    );
  }
}