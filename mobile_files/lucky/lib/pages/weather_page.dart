import 'package:flutter/material.dart';
import 'package:lottie/lottie.dart';
import 'package:lucky/models/weather_model.dart';
import 'package:lucky/services/weather_service.dart';
import 'package:lucky/config/keys.dart';
import 'dart:convert';
import 'dart:async';
import 'package:flutter_reactive_ble/flutter_reactive_ble.dart';


class WeatherPage extends StatefulWidget {
  const WeatherPage({super.key});

  @override
  State<WeatherPage> createState()=> _WeatherPageState();
}


/// The WeatherPage class is the class of the page that requests and show weather information
class _WeatherPageState extends State<WeatherPage>{

  ///////////////// Weather API request function /////////////////

  //Api Key in another file -> this file is not uploaded to GitHub due to security reasons
  final _weatherService = WeatherService(AppConfig.weatherOpenAPIKey);
  Weather? _weather; 

  // Fetches the weather on the API
  _fetchWeather(String cityLabel) async {
    //Get current city - Based on the bluetooth value
    String cityName = _weatherService.getCurrentCity(cityLabel);
    // String cityName ="Jakarta"; //Uncomment this part to test with Jakarta

    //Request on the API
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


  ///////////////// Bluetooth functions /////////////////

  final _ble = FlutterReactiveBle();
  StreamSubscription<DiscoveredDevice>? _scanSub;
  StreamSubscription<ConnectionStateUpdate>? _connectSub;
  StreamSubscription<List<int>>? _notifySub;

  var _found = false;
  var _value = 'nothing';

  //Initiate listening to bluetooth signal
  @override
  void initState() {
    super.initState();
    _scanSub = _ble.scanForDevices(withServices: []).listen(_onScanUpdate);
  }

  //Closes connection
  @override
  void dispose() {
    _notifySub?.cancel();
    _connectSub?.cancel();
    _scanSub?.cancel();
    super.dispose();
  }

  //Scans bluetooth device given a specific name
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

  //Connects to bluetooth device and receives information
  void _onConnected(String deviceId) {
    final characteristic = QualifiedCharacteristic(
        deviceId: deviceId,
        serviceId: Uuid.parse('00000000-5EC4-4083-81CD-A10B8D5CF6EC'),
        characteristicId: Uuid.parse('00000001-5EC4-4083-81CD-A10B8D5CF6EC'));

    _notifySub = _ble.subscribeToCharacteristic(characteristic).listen((bytes) {
      _value = const Utf8Decoder().convert(bytes);  ///Receive by bluetooth the city info
      _fetchWeather(_value);
    });
  }


  ///////////////// Get screen images  /////////////////

  ///Obtains the correct animation provided the weather condition
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


  ///////////////// App View - Main Page  /////////////////

  ///Creates page layout and update conditions
  @override
  Widget build(BuildContext context){
    return  Scaffold(
      backgroundColor: Colors.blue[400],
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
        
          Text(_weather?.cityName ?? "Waiting for city...", 
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