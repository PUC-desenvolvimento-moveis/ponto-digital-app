import 'package:flutter/material.dart';
import 'package:intl/intl.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'login.dart';

class RegisterPage extends StatefulWidget {
  const RegisterPage({Key? key}) : super(key: key);

  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  TextEditingController nameController = TextEditingController();
  TextEditingController dobController = TextEditingController();
  TextEditingController phoneController = TextEditingController();
  TextEditingController emailController = TextEditingController();
  TextEditingController passwordController = TextEditingController();
  TextEditingController cpfController = TextEditingController();
  bool showPassword = false;
  String? genderSelected;
  bool emailNotification = false;
  bool phoneNotification = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SingleChildScrollView(
        padding: EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: <Widget>[
            Padding(
              padding: const EdgeInsets.only(top: 60.0),
              child: Center(
                child: Container(
                  width: 200,
                  height: 200,
                  child: Image.asset('logo.png'),
                ),
              ),
            ),
            SizedBox(height: 30),
            TextField(
              controller: nameController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Nome',
              ),
              maxLength: 50,
              keyboardType: TextInputType.name,
            ),
            SizedBox(height: 15),
            TextField(
              controller: phoneController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Telefone',
              ),
              maxLength: 15,
              keyboardType: TextInputType.phone,
            ),
            SizedBox(height: 15),
            TextField(
              controller: emailController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Email',
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            SizedBox(height: 15),
            TextField(
              controller: cpfController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'CPF',
              ),
              maxLength: 11,
              keyboardType: TextInputType.number,
            ),
            SizedBox(height: 15),
            TextField(
              controller: passwordController,
              decoration: InputDecoration(
                border: OutlineInputBorder(),
                labelText: 'Senha',
                suffixIcon: IconButton(
                  onPressed: () {
                    setState(() {
                      showPassword = !showPassword;
                    });
                  },
                  icon: Icon(
                    showPassword ? Icons.visibility : Icons.visibility_off,
                  ),
                ),
              ),
              obscureText: !showPassword,
              maxLength: 20,
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Text('Data de Nascimento: '),
                SizedBox(width: 10),
                Expanded(
                  child: TextField(
                    controller: dobController,
                    decoration: InputDecoration(
                      border: OutlineInputBorder(),
                      labelText: 'DD/MM/AAAA',
                    ),
                    maxLength: 10,
                    keyboardType: TextInputType.datetime,
                    onTap: () async {
                      FocusScope.of(context).requestFocus(new FocusNode());
                      final DateTime? picked = await showDatePicker(
                        context: context,
                        initialDate: DateTime.now(),
                        firstDate: DateTime(1900, 1, 1),
                        lastDate: DateTime.now(),
                      );
                      if (picked != null)
                        dobController.text =
                            DateFormat('dd/MM/yyyy').format(picked);
                    },
                  ),
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Text('Gênero: '),
                SizedBox(width: 10),
                Row(
                  children: [
                    Radio(
                      value: 'Masculino',
                      groupValue: genderSelected,
                      onChanged: (String? value) {
                        setState(() {
                          genderSelected = value;
                        });
                      },
                    ),
                    Text('Masculino'),
                  ],
                ),
                Row(
                  children: [
                    Radio(
                      value: 'Feminino',
                      groupValue: genderSelected,
                      onChanged: (String? value) {
                        setState(() {
                          genderSelected = value;
                        });
                      },
                    ),
                    Text('Feminino'),
                  ],
                ),
              ],
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Switch(
                  value: emailNotification,
                  onChanged: (bool value) {
                    setState(() {
                      emailNotification = value;
                    });
                  },
                ),
                Text('Notificações via E-mail'),
              ],
            ),
            SizedBox(height: 15),
            Row(
              children: [
                Switch(
                  value: phoneNotification,
                  onChanged: (bool value) {
                    setState(() {
                      phoneNotification = value;
                    });
                  },
                ),
                Text('Notificações via Telefone'),
              ],
            ),
            SizedBox(height: 30),
            ElevatedButton(
              onPressed: _registerUser,
              style: ElevatedButton.styleFrom(
                backgroundColor: Colors.blue,
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(20),
                ),
                minimumSize: Size(250, 50),
              ),
              child: Text(
                'Cadastrar',
                style: TextStyle(color: Colors.white, fontSize: 25),
              ),
            ),
          ],
        ),
      ),
    );
  }

  void _registerUser() async {
    final String name = nameController.text.trim();
    final String phone = phoneController.text.trim();
    final String email = emailController.text.trim();
    final String cpf = cpfController.text.trim();
    final String password = passwordController.text.trim();
    final String dob = dobController.text.trim();

    if (name.isEmpty || phone.isEmpty || email.isEmpty || cpf.isEmpty || password.isEmpty || dob.isEmpty) {
      _showErrorSnackBar('Todos os campos são obrigatórios');
      return;
    }

    if (!_isValidEmail(email)) {
      _showErrorSnackBar('Formato de e-mail inválido');
      return;
    }

    SharedPreferences prefs = await SharedPreferences.getInstance();
    await prefs.setString('name', name);
    await prefs.setString('phone', phone);
    await prefs.setString('email', email);
    await prefs.setString('cpf', cpf);
    await prefs.setString('password', password);
    await prefs.setString('dob', dob);
    await prefs.setString('gender', genderSelected ?? '');
    await prefs.setBool('emailNotification', emailNotification);
    await prefs.setBool('phoneNotification', phoneNotification);

    _showSuccessSnackBar('Cadastro realizado com sucesso');
  }

  bool _isValidEmail(String email) {
    final emailRegExp = RegExp(r'^[\w-\.]+@([\w-]+\.)+[\w-]{2,4}$');
    return emailRegExp.hasMatch(email);
  }

  void _showErrorSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.red,
      ),
    );
  }

  void _showSuccessSnackBar(String message) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: Colors.green,
      ),
    );
  }
}
