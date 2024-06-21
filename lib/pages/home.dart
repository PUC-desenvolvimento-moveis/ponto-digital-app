import 'package:flutter/material.dart';
import 'package:timer_builder/timer_builder.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HomePageApp extends StatefulWidget {
  final String name;

  const HomePageApp({Key? key, required this.name}) : super(key: key);

  @override
  _HomePageAppState createState() => _HomePageAppState();
}

class _HomePageAppState extends State<HomePageApp> {
  bool _isJourneyStarted = false;
  Stopwatch? _stopwatch;
  List<String> _journeyHistory = [];
  late SharedPreferences _prefs;

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _initSharedPreferences();
  }

   void _initSharedPreferences() async {
    _prefs = await SharedPreferences.getInstance();
    _loadJourneyHistory();
  }

  void _loadJourneyHistory() {
    _journeyHistory = _prefs.getStringList('journeyHistory') ?? [];
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bem-vindo, ${widget.name}'),
        backgroundColor: Colors.blue,
        actions: <Widget>[
          IconButton(
            icon: Icon(Icons.logout),
            onPressed: () {
              _logout(context);
            },
          ),
        ],
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              onPressed: () async {
                if (_isJourneyStarted) {
                  _stopwatch!.stop();
                  _journeyHistory.add('Saída: ${_getCurrentDateTime()}');
                  _saveJourneyHistory();
                  setState(() {
                    _isJourneyStarted = false;
                  });
                } else {
                  await apropriar_hora_inicial(context, widget.name); // Call function when starting journey
                  _stopwatch!.start();
                  _journeyHistory.add('Entrada: ${_getCurrentDateTime()}');
                  setState(() {
                    _isJourneyStarted = true;
                  });
                }
              },
              style: ElevatedButton.styleFrom(
                padding: EdgeInsets.all(16.0),
                backgroundColor: _isJourneyStarted ? Colors.red : Colors.green,
              ),
              child: Text(
                _isJourneyStarted ? 'Finalizar jornada' : 'Iniciar jornada',
                style: TextStyle(fontSize: 18, color: Colors.white),
              ),
            ),
            SizedBox(height: 20),
            Text(
              _getCurrentDate(),
              style: TextStyle(fontSize: 16, fontWeight: FontWeight.bold),
              textAlign: TextAlign.center,
            ),
            SizedBox(height: 8),
            Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Icon(Icons.timer),
                SizedBox(width: 8),
                TimerBuilder.periodic(
                  Duration(seconds: 1),
                  builder: (context) {
                    return Text(
                      _isJourneyStarted ? _getTimeString() : '00:00:00',
                      style: TextStyle(fontSize: 24),
                    );
                  },
                ),
              ],
            ),
            SizedBox(height: 20),
            Expanded(
              child: ListView.builder(
                itemCount: _journeyHistory.length,
                itemBuilder: (context, index) {
                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(8.0),
                      child: Text(
                        _journeyHistory[index],
                        style: TextStyle(fontSize: 16),
                      ),
                    ),
                  );
                },
              ),
            ),
          ],
        ),
      ),
    );
  }

  String _getTimeString() {
    final milliseconds = _stopwatch!.elapsedMilliseconds;
    final seconds = (milliseconds / 1000).floor() % 60;
    final minutes = (milliseconds / (1000 * 60)).floor() % 60;
    final hours = (milliseconds / (1000 * 60 * 60)).floor();
    return '$hours:${minutes.toString().padLeft(2, '0')}:${seconds.toString().padLeft(2, '0')}';
  }

  String _getCurrentDate() {
    return DateFormat('dd/MM/yyyy').format(DateTime.now());
  }

  String _getCurrentDateTime() {
    return DateFormat('dd/MM/yyyy HH:mm').format(DateTime.now());
  }

  void _logout(BuildContext context) {
    Navigator.pushReplacementNamed(context, '/');
  }

   void _saveJourneyHistory() {
    _prefs.setStringList('journeyHistory', _journeyHistory);
  } 

  Future<void> apropriar_hora_inicial(BuildContext context, String name) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken'); // Retrieve the token
    print('Token: $token');

    if (token == null) {
      _showErrorSnackBar(context, 'Erro: Token de autenticação não encontrado.');
      return;
    }

    int userId = 0;
    final urlByEmail = 'http://localhost:8000/api/users/byemail/$name';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token' // Include the token in the headers
    };

    final response = await http.get(Uri.parse(urlByEmail), headers: headers);
    print('ByEmail response status: ${response.statusCode}');
    print('ByEmail response body: ${response.body}');

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      userId = responseData['id'];
    } else {
      _showErrorSnackBar(context, 'Erro ao buscar o usuário.');
      return;
    }

    final urlInicial = 'http://localhost:8000/api/pontos/inicial';
    final body = json.encode({'user_id': userId});
    final responseApropriacao =
        await http.post(Uri.parse(urlInicial), headers: headers, body: body);

    print('Apropriar response status: ${responseApropriacao.statusCode}');
    print('Apropriar response body: ${responseApropriacao.body}');

    if (responseApropriacao.statusCode == 201) {
      // Handle successful appropriation
      _showSuccessSnackBar(context, 'Apropriação realizada com sucesso!');
    } else {
      // Handle appropriation error
      _showErrorSnackBar(context, 'Erro ao realizar a apropriação.');
    }
  } catch (error) {
    print('Apropriar error: $error');
    _showErrorSnackBar(context, 'Erro de rede: $error');
  }
}


Future<void> apropriar_hora_final(BuildContext context, String name) async {
  try {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken'); // Retrieve the token
    print('Token: $token');

    if (token == null) {
      _showErrorSnackBar(context, 'Erro: Token de autenticação não encontrado.');
      return;
    }

    int userId = 0;
    final urlByEmail = 'http://localhost:8000/api/users/byemail/$name';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token' // Include the token in the headers
    };

    final response = await http.get(Uri.parse(urlByEmail), headers: headers);
    print('ByEmail response status: ${response.statusCode}');
    print('ByEmail response body: ${response.body}');

    if (response.statusCode == 201) {
      final responseData = json.decode(response.body);
      userId = responseData['id'];
    } else {
      _showErrorSnackBar(context, 'Erro ao buscar o usuário.');
      return;
    }

    final urlInicial = 'http://localhost:8000/api/pontos/final';
    final body = json.encode({'user_id': userId});
    final responseApropriacao =
        await http.post(Uri.parse(urlInicial), headers: headers, body: body);

    print('Apropriar response status: ${responseApropriacao.statusCode}');
    print('Apropriar response body: ${responseApropriacao.body}');

    if (responseApropriacao.statusCode == 201) {
      // Handle successful appropriation
      _showSuccessSnackBar(context, 'Apropriação realizada com sucesso!');
    } else {
      // Handle appropriation error
      _showErrorSnackBar(context, 'Erro ao realizar a apropriação.');
    }
  } catch (error) {
    print('Apropriar error: $error');
    _showErrorSnackBar(context, 'Erro de rede: $error');
  }
}

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.red),
    );
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text(message), backgroundColor: Colors.green),
    );
  }
}
