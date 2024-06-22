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
            leading: Icon(Icons.date_range),
            title: Text('Ver hora apropriada por período'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => PeriodPage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.calendar_today),
            title: Text('Ver hora apropriada por data'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => DatePage()),
              );
            },
          ),
          ListTile(
            leading: Icon(Icons.access_time),
            title: Text('Ver horas totais apropriadas'),
            onTap: () {
              Navigator.push(
                context,
                MaterialPageRoute(builder: (context) => TotalHoursPage()),
              );
            },
          ),
        ],
      ),
    );
  }
}