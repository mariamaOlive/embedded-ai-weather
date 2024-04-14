import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:lucky/models/weather_model.dart';
import 'package:lucky/services/weather_service.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';

class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState()=> _WeatherPageState();
}


class _WeatherPageState extends State<WeatherPage>{

  //api key
  final _weatherService = WeatherService("e3bd2e29341a2e86bbf173b5dd85e269");
  Weather? _weather; 

  // fetch weather
  _fetchWeather(String cityLabel) async {
    //get current city
    String cityName = _weatherService.getCurrentCity(cityLabel);
    // String cityName ="Jakarta";

    //get weather for city
    try{
      dynamic weather;
      if(cityName == "Unknown"){
        weather =  Weather(
          cityName: cityName, 
          temperature: null, 
          mainCondition: null
        );
      }else{
        weather = await _weatherService.getWeather(cityName);
      }
      setState(() {
        _weather = weather;
      });
    }catch(e){
      print(e);
    }
  }

  // weather animations


  ////Bluetooth  ///////// START HERE////////////

  final _ble = FlutterReactiveBle();

  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connectSub;
  StreamSubscription<List<int>>? _notifySub;

  var _found = false;
  var _value = 'nothing';

  @override
  void initState() {
    super.initState();
    _scanSub = _ble.scanForDevices(withServices: []).listen(_onScanUpdate);
  }

  @override
  void dispose() {
    _notifySub?.cancel();
    _connectSub?.cancel();
    _scanSub?.cancel();
    super.dispose();
  }

  void _onScanUpdate(DiscoveredDevice d) {
    if (d.name == 'BLE-TEMP' && !_found) {
      _found = true;
      _connectSub = _ble.connectToDevice(id: d.id).listen((update) {
        if (update.connectionState == DeviceConnectionState.connected) {
          _onConnected(d.id);
        }
      });
    }
  }

  void _onConnected(String deviceId) {
    final characteristic = QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: Uuid.parse('00000000-5EC4-4083-81CD-A10B8D5CF6EC'),
        characteristicId: Uuid.parse('00000001-5EC4-4083-81CD-A10B8D5CF6EC'));

    _notifySub = _ble.subscribeToCharacteristic(characteristic).listen((bytes) {
      // setState(() {
      _value = const Utf8Decoder().convert(bytes);  ///WITH city info
      _fetchWeather(_value);
      // });
    });
  }

/////////////////////////////////// END - BLUETOOTH /////////////////////

  // @override
  // void initState(){
  //   super.initState();

  //   //Fetch weather on startup
  //   _fetchWeather();
  // }

  String getWeatherAnimation(String? mainCondition){
   
    if (mainCondition == null) return 'assets/cat.json'; // default 
    
    switch (mainCondition.toLowerCase()){
      case 'clouds':
        return 'assets/cloud.json';
      case 'mist': 
      case 'smoke': 
      case 'haze': 
      case 'dust': 
      case 'fog':
        return 'assets/fog.json';
      case 'rain':
      case 'drizzle':
      case 'shower rain':
      case 'thunderstorm':
        return 'assets/rain.json';
      case 'snow':
        return 'assets/snow.json';
      case 'clear':
        return 'assets/sun.json';
      default:
        return 'assets/cat.json';
    }
  }

  @override
  Widget build(BuildContext context){
    return  Scaffold(
      backgroundColor: Colors.blue[400],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
          // Text(_value),
        
          Text(_weather?.cityName ?? "Loading city...", 
          style: TextStyle(fontSize: 30),
          ),

          // //Animation
          Lottie.asset(getWeatherAnimation(_weather?.mainCondition)),
        
          Text(_weather?.temperature == null ? "" : '${_weather?.temperature?.round()} °C',
            style: TextStyle(fontSize: 36, fontWeight: FontWeight.bold),
          ),

          //Main condition
          Text(_weather?.mainCondition ?? "",
          style: TextStyle(fontSize: 20),),
        ],),
      ),
    );
  }

}