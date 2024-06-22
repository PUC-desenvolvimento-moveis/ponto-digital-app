import 'package:flutter/material.dart';
import 'package:timer_builder/timer_builder.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';
import 'nav.dart';

void main() => runApp(MyApp());

class MyApp extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: HomePageApp(email: 'nome do usuario'),
    );
  }
}

class HomePageApp extends StatefulWidget {
  final String email;

  const HomePageApp({Key? key, required this.email}) : super(key: key);

  @override
  _HomePageAppState createState() => _HomePageAppState();
}

class _HomePageAppState extends State<HomePageApp> {
  bool _isJourneyStarted = false;
  bool _ponto_final = false;
  Stopwatch? _stopwatch;
  List<String> _journeyHistory = [];
  late SharedPreferences _prefs;
  late String _userName="user";

  @override
  void initState() {
    super.initState();
    _stopwatch = Stopwatch();
    _fetchUserDetails(widget.email);
  }

  Future<void> _fetchUserDetails(String email) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    
    if (token == null) {
      _showErrorSnackBar(context, 'Erro: Token de autenticação não encontrado.');
      return;
    }

    final urlByEmail = 'http://localhost:8000/api/users/byemail/$email';
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };

    try {
      final response = await http.get(Uri.parse(urlByEmail), headers: headers);
      if (response.statusCode == 201) {
        final responseData = json.decode(response.body);
        setState(() {
          _userName = responseData['name'];
        });
      } else {
        _showErrorSnackBar(context, 'Erro ao buscar o usuário.');
      }
    } catch (error) {
      _showErrorSnackBar(context, 'Erro de rede: $error');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Bem-vindo, $_userName'),
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
      drawer: AppDrawer(email: widget.email), // Adicionando o Drawer aqui
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            ElevatedButton(
              onPressed: () {
                if (_isJourneyStarted) {
                  _stopwatch!.stop();
                  _journeyHistory.add('Saída: ${_getCurrentDateTime()}');
                  apropriar_hora_final(context);
                } else {
                  _stopwatch!.start();
                  _journeyHistory.add('Entrada: ${_getCurrentDateTime()}');
                  apropriar_hora_inicial(context, widget.email);
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

  Future<void> apropriar_hora_inicial(BuildContext context, String email) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('authToken'); // Retrieve the token
      print('Token: $token');

      if (token == null) {
        _showErrorSnackBar(
            context, 'Erro: Token de autenticação não encontrado.');
        return;
      }

      int userId = 0;
      final urlByEmail = 'http://localhost:8000/api/users/byemail/$email';
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
        _showSuccessSnackBar(context, 'Apropriação realizada com sucesso!');
        final response_json = json.decode(responseApropriacao.body);
        int pontoId = response_json['data']['id'];
        await prefs.setInt('pontoId', pontoId);
        await prefs.setInt('userId', userId);
        setState(() {
          _isJourneyStarted = true;
        });
      } else {
        // Handle appropriation error
        _showErrorSnackBar(context, 'Erro ao realizar a apropriação.');
      }
    } catch (error) {
      print('Apropriar error: $error');
      _showErrorSnackBar(context, 'Erro de rede: $error');
    }
  }

  Future<void> apropriar_hora_final(BuildContext context) async {
    try {
      SharedPreferences prefs = await SharedPreferences.getInstance();
      String? token = prefs.getString('authToken'); // Retrieve the token
      int? pontoId =
          prefs.getInt('pontoId'); // Retrieve the initial appropriation ID
      int? userId = prefs.getInt('userId'); // Retrieve the user ID
      print('Token: $token');
      print('Ponto ID: $pontoId');
      print('User ID: $userId');

      if (token == null) {
        _showErrorSnackBar(
            context, 'Erro: Token de autenticação não encontrado.');
        return;
      }

      if (pontoId == null) {
        _showErrorSnackBar(
            context, 'Erro: ID de apropriação inicial não encontrado.');
        return;
      }

      if (userId == null) {
        _showErrorSnackBar(context, 'Erro: ID de usuário não encontrado.');
        return;
      }

      final urlFinal = 'http://localhost:8000/api/pontos/final/$pontoId';
      final headers = {
        'Content-Type': 'application/json',
        'Authorization': 'Bearer $token' // Include the token in the headers
      };
      final responseApropriacaoFinal = await http.put(
        Uri.parse(urlFinal),
        headers: headers,
        body: json.encode({'user_id': userId}),
      );

      print('Apropriar Final response status: ${responseApropriacaoFinal.statusCode}');
      print('Apropriar Final response body: ${responseApropriacaoFinal.body}');

      if (responseApropriacaoFinal.statusCode == 201) {
        _showSuccessSnackBar(
            context, 'Apropriação final realizada com sucesso!');
        setState(() {
          _isJourneyStarted = false;
        });
      } else {
        _showErrorSnackBar(context, 'Erro ao realizar a apropriação final.');
      }
    } catch (error) {
      print('Apropriar Final error: $error');
      _showErrorSnackBar(context, 'Erro de rede: $error');
    }
  }

  void _showSuccessSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }

  void _showErrorSnackBar(BuildContext context, String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }
}
