import 'dart:convert';
import '../models/weather_model.dart';       
import 'package:http/http.dart' as http;         

/// The WeatherService class is resposible for handling weather request at the API
class WeatherService{

  static const BASE_URL ='http://api.openweathermap.org/data/2.5/weather';
  final String apiKey;

  WeatherService(this.apiKey);

  /// Requests the weather on the API.
  Future<Weather> getWeather(String cityName) async {
    final response = await http
        .get(Uri.parse('$BASE_URL?q=$cityName&appid=$apiKey&units=metric'));

    if (response.statusCode == 200){
      return Weather.fromJson(jsonDecode(response.body));
    }else{
      throw Exception('Failed to load weather data');
    }
  }


  /// Selects the correct city name to request the weather
  String getCurrentCity(String cityLabel) {

    switch (cityLabel){
      case "0":
        return "Jakarta" ;
      case "1": 
        return "S%C3%A3o%20Paulo";
      default: 
        return "Unknown";
   
    }
  }


}