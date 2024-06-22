import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'register.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';  // Para trabalhar com JSO
import 'total_horas_por_data.dart';
import 'total_horas.dart';
import 'total_horas_por_periodo.dart';


class AppDrawer extends StatelessWidget {
  final String email;

  const AppDrawer({Key? key, required this.email}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return Drawer(
      child: ListView(
        padding: EdgeInsets.zero,
        children: <Widget>[
          DrawerHeader(
            decoration: BoxDecoration(
              color: Colors.blue,
            ),
            child: Text(
              'Menu',
              style: TextStyle(
                color: Colors.white,
                fontSize: 24,
              ),
            ),
          ),
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Horas Apropriadas por Período'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HorasApropriadasPorPeriodoPage(email: email),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.date_range),
            title: Text('Horas Apropriadas por Data'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => HorasApropriadasPorDataPage(email: email),
                ),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.access_time),
            title: Text('Total de Horas Apropriadas'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(
                  builder: (context) => TotalHorasApropriadasPage(email: email),
                ),
              );
            },
          ),
        ],
      ),
    );
  }
}
