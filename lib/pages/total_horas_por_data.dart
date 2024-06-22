import 'package:flutter/material.dart';
import 'package:timer_builder/timer_builder.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HorasApropriadasPorDataPage extends StatefulWidget {
  final String email;

  HorasApropriadasPorDataPage({required this.email});

  @override
  _HorasApropriadasPorDataPageState createState() =>
      _HorasApropriadasPorDataPageState();
}

class _HorasApropriadasPorDataPageState
    extends State<HorasApropriadasPorDataPage> {
  late String _dataSelecionada;
  late Future<String> _totalHorasFuture;

  @override
  void initState() {
    super.initState();
    _dataSelecionada = ""; // Inicializa sem data selecionada
    _totalHorasFuture = Future.value(""); // Inicializa com um future vazio
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
        headers: headers);
    final data = jsonDecode(response.body);
    print(data);
    return data['id'];
  }

  Future<String> _getTotalHoras() async {
    if (_dataSelecionada.isEmpty)
      return '00:00:00'; // Evita chamadas desnecessárias
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final idUsuario = await _getIdUsuario(widget.email);
    final formattedDate =
        _dataSelecionada.substring(0, 10); // Ajuste conforme necessário
    final response = await http.get(
        Uri.parse(
            'http://localhost:8000/api/pontos/soma_minutos_trabalhados_por_data/$idUsuario/$formattedDate'),
        headers: headers);
    final data = jsonDecode(response.body);
    print(data);
    return data['total_horas_trabalhadas'];
  }

  Future<List<dynamic>> _getListaApropriacoesByData() async {
    if (_dataSelecionada.isEmpty) return []; // Evita chamadas desnecessárias
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final idUsuario = await _getIdUsuario(widget.email);
    final formattedDate =
        _dataSelecionada.substring(0, 10); // Ajuste conforme necessário
    final response = await http.get(
        Uri.parse(
            'http://localhost:8000/api/pontos/soma_minutos_trabalhados_por_data/$idUsuario/$formattedDate'),
        headers: headers);
    final data = jsonDecode(response.body);
    print(data);

    if (data['lista_de_apropriacao'] is Map) {
      // Se a lista de apropriações for um objeto, transforma em uma lista
      return data['lista_de_apropriacao'].values.toList();
    } else {
      return data['lista_de_apropriacao'];
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Horas Apropriadas por Data'),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: <Widget>[
            Text('Escolha a data:'),
            SizedBox(height: 10),
            ElevatedButton(
              onPressed: () {
                showDatePicker(
                  context: context,
                  initialDate: DateTime.now(),
                  firstDate: DateTime(2000),
                  lastDate: DateTime(2100),
                ).then((value) {
                  if (value != null) {
                    setState(() {
                      _dataSelecionada =
                          value.toString(); // Atualiza a data selecionada
                      _totalHorasFuture =
                          _getTotalHoras(); // Recalcula as horas com base na nova data
                    });
                  }
                });
              },
              child: Text('Selecionar Data'),
            ),
            SizedBox(height: 20),
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
              future: _getListaApropriacoesByData(),
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
