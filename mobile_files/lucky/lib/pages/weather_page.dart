import 'package:flutter/material.dart';
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
  _fetchWeather() async {
    //get current city
    // String cityName = await _weatherService.getCurrentCity();
    String cityName ="Jakarta";

    //get weather for city
    try{
      final weather = await _weatherService.getWeather(cityName);

      setState(() {
        _weather = weather;
      });
    }catch(e){
      print(e);
    }
  }

  // weather animations


  //Bluetooth  ///////// START HERE////////////

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
      setState(() {
        _value = const Utf8Decoder().convert(bytes);  ///WITH city info
      });
    });
  }

/////////////////////////////////// END - BLUETOOTH /////////////////////

  // @override
  // void initState(){
  //   super.initState();

  //   //Fetch weather on startup
  //   _fetchWeather();
  // }

  @override
  Widget build(BuildContext context){
    return  Scaffold(
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
             Text(_value)
        
          // Text(_weather?.cityName ?? "Loading city..."),
        
          // Text('${_weather?.temperature.round()} C')
        ],),
      ),
    );
  }

}