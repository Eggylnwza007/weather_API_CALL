import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:weather/weather.dart';
import 'package:flutter_dotenv/flutter_dotenv.dart';

void main() async {
  await dotenv.load(fileName: ".env");
  runApp(const MainApp());
}

class MainApp extends StatefulWidget {
  const MainApp({super.key});

  @override
  State<MainApp> createState() => _MainAppState();
}

class _MainAppState extends State<MainApp> {
  late Future<List<String>> cities;

  @override
  void initState() {
    super.initState();
    cities = fetchCities();
  }

  Future<List<String>> fetchCities() async {
    return ['Bangkok', 'London', 'New York', 'Tokyo', 'Sydney'];
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,
      home: Scaffold(
        appBar: AppBar(
          title: Text('Weather App'),
        ),
        body: FutureBuilder<List<String>>(
          future: cities,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              return ListView.builder(
                itemCount: snapshot.data!.length,
                itemBuilder: (context, index) {
                  return ListTile(
                    title: Text(snapshot.data![index]),
                    onTap: () {
                      Navigator.push(
                        context,
                        MaterialPageRoute(
                          builder: (context) => WeatherDetailPage(cityName: snapshot.data![index]),
                        ),
                      );
                    },
                  );
                },
              );
            } else if (snapshot.hasError) {
              return Center(child: Text('Error loading cities'));
            } else {
              return Center(child: CircularProgressIndicator());
            }
          },
        ),
      ),
    );
  }
}

class WeatherDetailPage extends StatefulWidget {
  final String cityName;

  const WeatherDetailPage({required this.cityName});

  @override
  _WeatherDetailPageState createState() => _WeatherDetailPageState();
}

class _WeatherDetailPageState extends State<WeatherDetailPage> {
  late Future<WeatherResponse> weatherData;

  @override
  void initState() {
    super.initState();
    weatherData = getData(widget.cityName);
  }

  Future<WeatherResponse> getData(String cityName) async {
    var client = http.Client();
    try {
      String apiKey = dotenv.env['API_KEY']!;
      var response = await client.get(Uri.parse(
          'https://api.openweathermap.org/data/2.5/weather?q=$cityName&units=metric&appid=$apiKey'));
      if (response.statusCode == 200) {
        return WeatherResponse.fromJson(
            jsonDecode(utf8.decode(response.bodyBytes)));
      } else {
        throw Exception("Failed to load data");
      }
    } finally {
      client.close();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(widget.cityName),
      ),
      body: Center(
        child: FutureBuilder<WeatherResponse>(
          future: weatherData,
          builder: (context, snapshot) {
            if (snapshot.hasData) {
              var data = snapshot.data!;
              return Column(
                mainAxisAlignment: MainAxisAlignment.center,
                children: [
                  Text(data.name ?? "", style: TextStyle(fontSize: 40)),
                  Text('Temperature: ${data.main!.temp} °C'),
                  Text('Min Temperature: ${data.main!.tempMin} °C'),
                  Text('Max Temperature: ${data.main!.tempMax} °C'),
                  Text('Pressure: ${data.main!.pressure} hPa'),
                  Text('Humidity: ${data.main!.humidity} %'),
                  Text('Sea Level: ${data.main!.seaLevel ?? 'N/A'} m'),
                  Text('Clouds: ${data.clouds!.all} %'),
                  Text('Rain (last hour): ${data.rain?.d1h ?? 0} mm'),
                  Text('Sunset: ${DateTime.fromMillisecondsSinceEpoch(data.sys!.sunset! * 1000)}'),
                  Image.network('http://openweathermap.org/img/wn/${data.weather![0].icon}@2x.png')
                ],
              );
            } else if (snapshot.hasError) {
              return Text('Error: ${snapshot.error}');
            } else {
              return CircularProgressIndicator();
            }
          },
        ),
      ),
    );
  }
}
