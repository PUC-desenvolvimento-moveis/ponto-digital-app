import 'package:flutter/material.dart';
import 'package:timer_builder/timer_builder.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';

class HorasApropriadasPorPeriodoPage extends StatefulWidget {
  final String email;

  HorasApropriadasPorPeriodoPage({required this.email});

  @override
  _HorasApropriadasPorPeriodoPageState createState() =>
      _HorasApropriadasPorPeriodoPageState();
}

class _HorasApropriadasPorPeriodoPageState
    extends State<HorasApropriadasPorPeriodoPage> {
  late String _dataSelecionada_inicial;
  late String _dataSelecionada_final;
  late Future<String> _totalHorasFuture;
  late Future<String> _msg;

  @override
  void initState() {
    super.initState();
    _dataSelecionada_inicial = ""; // Inicializa sem data selecionada
    _dataSelecionada_final = ""; // Inicializa sem data selecionada
    _totalHorasFuture = Future.value(""); // Inicializa com um future vazio
    _msg = Future.value("");
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

  Future<String> _verify_horas_ponto_por_mes(double minutos_trabalhados) async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final response = await http.get(
        Uri.parse(
            'http://localhost:8000/api/pontos/verify_horas_ponto_por_mes/$minutos_trabalhados'),
        headers: headers);
    final data = jsonDecode(response.body);
    print(data);
    return data['response'];
  }

  Future<String> _getTotalHoras() async {
    if (_dataSelecionada_inicial.isEmpty && _dataSelecionada_final.isEmpty)
      return '00:00'; // Evita chamadas desnecessárias
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final idUsuario = await _getIdUsuario(widget.email);
    final formattedDate =
        _dataSelecionada_inicial.substring(0, 10); // Ajuste conforme necessário
    final formattedDate_final =
        _dataSelecionada_final.substring(0, 10); // Ajuste conforme necessário
    final response = await http.get(
        Uri.parse(
            'http://localhost:8000/api/pontos/soma_minutos_trabalhados_por_periodo/$idUsuario/$formattedDate/$formattedDate_final'),
        headers: headers);
    final data = jsonDecode(response.body);
    print(data);

    final msg = await _verify_horas_ponto_por_mes(
        data['total_horas_trabalhadas_em_minutos']);
    await prefs.setString('message_por_periodo', msg); // Save the token

    // Formata a string para exibir apenas horas e minutos
    String totalHoras = data['total_horas_trabalhadas'];
    List<String> partes = totalHoras.split(':');
    String horasEMinutos = '${partes[0]}:${partes[1]}';

    return horasEMinutos;
  }

  Future<String> _mensagem() async {
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String msg = prefs.getString('message_por_periodo') ??
        ''; // Valor padrão vazio se for null
    return msg;
  }

  Future<List<dynamic>> _getListaApropriacoesByPeriodo() async {
    if (_dataSelecionada_inicial.isEmpty && _dataSelecionada_final.isEmpty)
      return []; // Evita chamadas desnecessárias
    SharedPreferences prefs = await SharedPreferences.getInstance();
    String? token = prefs.getString('authToken');
    final headers = {
      'Content-Type': 'application/json',
      'Authorization': 'Bearer $token'
    };
    final idUsuario = await _getIdUsuario(widget.email);
    final formattedDate =
        _dataSelecionada_inicial.substring(0, 10); // Ajuste conforme necessário
    final formattedDate_final =
        _dataSelecionada_final.substring(0, 10); // Ajuste conforme necessário
    final response = await http.get(
        Uri.parse(
            'http://localhost:8000/api/pontos/soma_minutos_trabalhados_por_periodo/$idUsuario/$formattedDate/$formattedDate_final'),
        headers: headers);
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
      DateTime dataHoraInicial =
          DateTime.parse(apropriacao['data_hora_inicial']);
      DateTime dataHoraFinal = DateTime.parse(apropriacao['data_hora_final']);

      // Subtrair 3 horas
      dataHoraInicial = dataHoraInicial.subtract(Duration(hours: 3));
      dataHoraFinal = dataHoraFinal.subtract(Duration(hours: 3));

      // Formatar de volta para string no formato desejado
      apropriacao['data_hora_inicial'] =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(dataHoraInicial);
      apropriacao['data_hora_final'] =
          DateFormat('yyyy-MM-dd HH:mm:ss').format(dataHoraFinal);
    }

    return apropriacoes;
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Horas Apropriadas por Período'),
        backgroundColor: Colors.blue,
      ),
      body: Padding(
        padding: const EdgeInsets.all(16.0),
        child: Center(
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: <Widget>[
              Card(
                elevation: 5,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(16.0),
                  child: Column(
                    children: [
                      Text('Selecione as datas:',
                          style: TextStyle(
                              fontSize: 18, fontWeight: FontWeight.bold)),
                      SizedBox(height: 10),
                      Row(
                        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
                        children: [
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
                                    _dataSelecionada_inicial = value.toString();
                                    _totalHorasFuture = _getTotalHoras();
                                    _msg =
                                        _mensagem(); // Recalcula as horas com base na nova data
                                  });
                                }
                              });
                            },
                            child: Text('Data Inicial'),
                          ),
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
                                    _dataSelecionada_final = value.toString();
                                    _totalHorasFuture =
                                        _getTotalHoras(); // Recalcula as horas com base na nova data
                                  });
                                }
                              });
                            },
                            child: Text('Data Final'),
                          ),
                        ],
                      ),
                      SizedBox(height: 10),
                      Text(
                        'Data Inicial: ${_dataSelecionada_inicial.isEmpty ? "Não selecionada" : DateFormat('dd/MM/yyyy').format(DateTime.parse(_dataSelecionada_inicial))}',
                      ),
                      Text(
                        'Data Final: ${_dataSelecionada_final.isEmpty ? "Não selecionada" : DateFormat('dd/MM/yyyy').format(DateTime.parse(_dataSelecionada_final))}',
                      ),
                    ],
                  ),
                ),
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
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time), // Ícone de relógio
                        SizedBox(width: 5),
                        Text(
                          'Tempo total: ${snapshot.data}',
                          style: TextStyle(
                            fontSize: 18,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              FutureBuilder<String>(
                future: _msg,
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Erro ao carregar mensagem');
                  } else {
                    return Row(
                      mainAxisAlignment: MainAxisAlignment.center,
                      children: [
                        Icon(Icons.access_time), // Ícone de relógio
                        SizedBox(width: 5),
                        Expanded(
                          child: Text(
                            '${snapshot.data}',
                            style: TextStyle(
                              fontSize: 18,
                              fontWeight: FontWeight.bold,
                            ),
                            overflow: TextOverflow
                                .ellipsis, // Adiciona '...' se o texto estiver muito longo
                          ),
                        ),
                      ],
                    );
                  }
                },
              ),
              SizedBox(height: 20),
              SizedBox(height: 20),
              FutureBuilder<List<dynamic>>(
                future: _getListaApropriacoesByPeriodo(),
                builder: (context, snapshot) {
                  if (snapshot.connectionState == ConnectionState.waiting) {
                    return CircularProgressIndicator();
                  } else if (snapshot.hasError) {
                    return Text('Erro ao buscar lista de apropriações');
                  } else {
                    List<dynamic> apropriacoes = snapshot.data!;
                    return Expanded(
                      child: ListView(
                        shrinkWrap: true,
                        children: apropriacoes.map((apropriacao) {
                          return Card(
                            elevation: 3,
                            margin: EdgeInsets.symmetric(
                                horizontal: 10, vertical: 5),
                            child: ListTile(
                              title: Text('Apropriação ${apropriacao['id']}'),
                              subtitle: Column(
                                crossAxisAlignment: CrossAxisAlignment.start,
                                children: <Widget>[
                                  Text(
                                      'Data inicial: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.parse(apropriacao['data_hora_inicial']))}'),
                                  Text(
                                      'Data final: ${DateFormat('dd/MM/yyyy HH:mm:ss').format(DateTime.parse(apropriacao['data_hora_final']))}'),
                                ],
                              ),
                            ),
                          );
                        }).toList(),
                      ),
                    );
                  }
                },
              ),
            ],
          ),
        ),
      ),
    );
  }
}
