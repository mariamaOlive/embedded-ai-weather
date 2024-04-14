import 'dart:convert';

import '../models/weather_model.dart';       
import 'package:http/http.dart' as http;         


class WeatherService{

  static const BASE_URL ='http://api.openweathermap.org/data/2.5/weather';
  final String apiKey;

  WeatherService(this.apiKey);

  Future<Weather> getWeather(String cityName) async {
    final response = await http
        .get(Uri.parse('$BASE_URL?q=$cityName&appid=$apiKey&units=metric'));

    if (response.statusCode == 200){
      return Weather.fromJson(jsonDecode(response.body));
    }else{
      throw Exception('Failed to load weather data');
    }
  }

//http://api.openweathermap.org/data/2.5/weather?q=Jakarta&appid=e3bd2e29341a2e86bbf173b5dd85e269&units=metric

//Jakarta
//S%C3%A3o%20Paulo

  String getCurrentCity(String cityLabel) {

    switch (cityLabel){
      case "1":
        return "Jakarta" ;
      case "2": 
        return "S%C3%A3o%20Paulo";
      default: 
        return "Unknown";
   
    }
  }


}