import 'package:flutter/material.dart';
import '../services/auth_service.dart';

class RegisterPage extends StatefulWidget {
  @override
  _RegisterPageState createState() => _RegisterPageState();
}

class _RegisterPageState extends State<RegisterPage> {
  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();
  final _confirmPasswordController = TextEditingController();
  String _role = "client";
  final _authService = AuthService();
  final _formKey = GlobalKey<FormState>();
  bool _isLoading = false;
  String? _errorMessage;

  Future<void> _register() async {
    if (!_formKey.currentState!.validate()) return;

    setState(() {
      _isLoading = true;
      _errorMessage = null;
    });

    final error = await _authService.register(
      _emailController.text.trim(),
      _passwordController.text.trim(),
      _role,
    );

    setState(() {
      _isLoading = false;
      _errorMessage = error;
    });

    if (error == null) {
      Navigator.pop(context); // zpět na login
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: Container(
        decoration: const BoxDecoration(
          gradient: LinearGradient(
            colors: [Colors.deepOrange, Colors.orange],
            begin: Alignment.topCenter,
            end: Alignment.bottomCenter,
          ),
        ),
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24.0),
            child: Card(
              color: Colors.white,
              elevation: 10,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(20),
              ),
              child: Padding(
                padding: const EdgeInsets.all(24.0),
                child: Form(
                  key: _formKey,
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      const Text(
                        "Vytvoř si účet",
                        style: TextStyle(
                          fontSize: 28,
                          fontWeight: FontWeight.bold,
                          color: Colors.orange,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        "Zadej údaje pro registraci",
                        style: TextStyle(fontSize: 16, color: Colors.grey),
                      ),
                      const SizedBox(height: 32),

                      TextFormField(
                        controller: _emailController,
                        decoration: const InputDecoration(
                          labelText: "E-mail",
                          prefixIcon: Icon(Icons.email, color: Colors.orange),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Zadej e-mail";
                          }
                          if (!value.contains("@")) {
                            return "Zadej platný e-mail";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _passwordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Heslo",
                          prefixIcon: Icon(Icons.lock, color: Colors.orange),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Zadej heslo";
                          }
                          if (value.length < 6) {
                            return "Heslo musí mít alespoň 6 znaků";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      TextFormField(
                        controller: _confirmPasswordController,
                        obscureText: true,
                        decoration: const InputDecoration(
                          labelText: "Potvrď heslo",
                          prefixIcon: Icon(Icons.lock_outline, color: Colors.orange),
                          border: OutlineInputBorder(),
                        ),
                        validator: (value) {
                          if (value == null || value.isEmpty) {
                            return "Potvrď své heslo";
                          }
                          if (value != _passwordController.text) {
                            return "Hesla se neshodují";
                          }
                          return null;
                        },
                      ),
                      const SizedBox(height: 16),

                      const Align(
                        alignment: Alignment.centerLeft,
                        child: Text(
                          "Vyber svou roli:",
                          style: TextStyle(fontSize: 16, fontWeight: FontWeight.w500),
                        ),
                      ),
                      const SizedBox(height: 8),
                      Column(
                        children: [
                          RadioListTile<String>(
                            title: const Text("Klient"),
                            value: "client",
                            groupValue: _role,
                            activeColor: Colors.orange,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) => setState(() => _role = value!),
                          ),
                          RadioListTile<String>(
                            title: const Text("Trenér"),
                            value: "trainer",
                            groupValue: _role,
                            activeColor: Colors.orange,
                            contentPadding: EdgeInsets.zero,
                            onChanged: (value) => setState(() => _role = value!),
                          ),
                        ],
                      ),
                      const SizedBox(height: 24),

                      if (_errorMessage != null)
                        Text(_errorMessage!, style: const TextStyle(color: Colors.red)),

                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: ElevatedButton(
                          onPressed: _isLoading ? null : _register,
                          style: ElevatedButton.styleFrom(
                            backgroundColor: Colors.orange,
                            foregroundColor: Colors.white,
                            padding: const EdgeInsets.symmetric(vertical: 16),
                            shape: RoundedRectangleBorder(
                              borderRadius: BorderRadius.circular(12),
                            ),
                          ),
                          child: _isLoading
                              ? const CircularProgressIndicator(color: Colors.white)
                              : const Text("Zaregistrovat se", style: TextStyle(fontSize: 18)),
                        ),
                      ),

                      const SizedBox(height: 16),

                      // Návrat na login
                      Row(
                        mainAxisAlignment: MainAxisAlignment.center,
                        children: [
                          const Text("Už máš účet?"),
                          TextButton(
                            onPressed: () => Navigator.pop(context),
                            child: const Text(
                              "Přihlas se",
                              style: TextStyle(color: Colors.orange, fontWeight: FontWeight.bold),
                            ),
                          ),
                        ],
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
