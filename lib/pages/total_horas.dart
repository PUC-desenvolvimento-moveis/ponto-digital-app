import 'package:flutter/material.dart';
import 'package:timer_builder/timer_builder.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class TotalHorasApropriadasPage extends StatefulWidget {
  final String email;

  TotalHorasApropriadasPage({required this.email});

  @override
  _TotalHorasApropriadasPageState createState() =>
      _TotalHorasApropriadasPageState();
}

class _TotalHorasApropriadasPageState
    extends State<TotalHorasApropriadasPage> {
 
  late Future<String> _totalHorasFuture;

 @override
void initState() {
  super.initState();
  _totalHorasFuture = _getTotalHoras();
}

Future<int> _getIdUsuario(String email) async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('authToken');
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token'
  };
  final response = await http.get(
    Uri.parse('http://localhost:8000/api/users/byemail/$email'),
    headers: headers,
  );
  final data = jsonDecode(response.body);
  print(data);
  return data['id'];
}

Future<String> _getTotalHoras() async {
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('authToken');
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token'
  };
  final idUsuario = await _getIdUsuario(widget.email);
  final response = await http.get(
    Uri.parse('http://localhost:8000/api/pontos/soma_minutos_trabalhados/$idUsuario'),
    headers: headers,
  );
  final data = jsonDecode(response.body);
  print(data);
  return data['total_horas_trabalhadas'];
}

 Future<List<dynamic>> _getListaApropriacoes() async { 
  SharedPreferences prefs = await SharedPreferences.getInstance();
  String? token = prefs.getString('authToken');
  final headers = {
    'Content-Type': 'application/json',
    'Authorization': 'Bearer $token'
  };

  final idUsuario = await _getIdUsuario(widget.email);

  final response = await http.get(
    Uri.parse('http://localhost:8000/api/pontos/soma_minutos_trabalhados/$idUsuario'),
    headers: headers,
  );
  final data = jsonDecode(response.body);
  print(data);

  List<dynamic> apropriacoes = [];
  if (data['lista_de_apropriacao'] is Map) {
    // Se a lista de apropriações for um objeto, transforma em uma lista
    apropriacoes = data['lista_de_apropriacao'].values.toList();
  } else {
    apropriacoes = data['lista_de_apropriacao'];
  }

  // Subtrair 3 horas dos valores de data_hora_inicial e data_hora_final
  for (var apropriacao in apropriacoes) {
    // Parse dos valores de data e hora para DateTime
    DateTime dataHoraInicial = DateTime.parse(apropriacao['data_hora_inicial']);
    DateTime dataHoraFinal = DateTime.parse(apropriacao['data_hora_final']);

    // Subtrair 3 horas
    dataHoraInicial = dataHoraInicial.subtract(Duration(hours: 3));
    dataHoraFinal = dataHoraFinal.subtract(Duration(hours: 3));

    // Formatar de volta para string no formato desejado
    apropriacao['data_hora_inicial'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(dataHoraInicial);
    apropriacao['data_hora_final'] = DateFormat('yyyy-MM-dd HH:mm:ss').format(dataHoraFinal);
  }

  return apropriacoes;
}

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Suas apropriacoes'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            FutureBuilder<String>(
              future: _totalHorasFuture,
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Erro ao buscar total de horas');
                } else {
                  return Text('Total de horas: ${snapshot.data}');
                }
              },
            ),
            SizedBox(height: 20),
            FutureBuilder<List<dynamic>>(
              future: _getListaApropriacoes(),
              builder: (context, snapshot) {
                if (snapshot.connectionState == ConnectionState.waiting) {
                  return CircularProgressIndicator();
                } else if (snapshot.hasError) {
                  return Text('Erro ao buscar lista de apropriações');
                } else {
                  List<dynamic> apropriacoes = snapshot.data!;
                  return ListView(
                    shrinkWrap: true,
                    children: apropriacoes.map((apropriacao) {
                      return Card(
                        elevation: 3,
                        margin:
                            EdgeInsets.symmetric(horizontal: 10, vertical: 5),
                        child: ListTile(
                          title: Text('Apropriação ${apropriacao['id']}'),
                          subtitle: Column(
                            crossAxisAlignment: CrossAxisAlignment.start,
                            children: <Widget>[
                              Text(
                                  'Data inicial: ${apropriacao['data_hora_inicial']}'),
                              Text(
                                  'Data final: ${apropriacao['data_hora_final']}'),
                              Text('Tipo: ${apropriacao['tipo']}'),
                            ],
                          ),
                        ),
                      );
                    }).toList(),
                  );
                }
              },
            ),
          ],
        ),
      ),
    );
  }
}
