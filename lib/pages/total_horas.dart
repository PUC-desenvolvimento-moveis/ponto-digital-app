import 'package:flutter/material.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'home.dart';
import 'register.dart';
import 'package:http/http.dart' as http;
import 'dart:convert';  // Para trabalhar com JSO


class TotalHorasApropriadasPage extends StatelessWidget {
  final String email;

  TotalHorasApropriadasPage({required this.email});

  @override
  Widget build(BuildContext context) {
    // Use o email para buscar os dados e renderizar a página
    return Scaffold(
      appBar: AppBar(
        title: Text('Total de Horas Apropriadas'),
      ),
      body: Center(
        child: Text('Email do usuário: $email'),
      ),
    );
  }
}