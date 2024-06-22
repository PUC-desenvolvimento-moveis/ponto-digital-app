import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'register.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';  // Para trabalhar com JSO


class TotalHoursPage extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('Ver horas totais apropriadas'),
      ),
      body: Center(
        child: Text('Conteúdo da página de horas totais apropriadas'),
      ),
    );
  }
}