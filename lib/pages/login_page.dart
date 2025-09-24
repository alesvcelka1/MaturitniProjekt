import 'package:flutter/material.dart';
import 'package:firebase_auth/firebase_auth.dart';
import '../services/auth_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);
  
  @override
  State<LoginPage> createState() => _LoginPageState();
}

class _LoginPageState extends State<LoginPage> {
  String _error = "";
  bool isLogin = true;

  final _emailController = TextEditingController();
  final _passwordController = TextEditingController();

  Future<void> signInWithEmailAndPassword() async {
    try{
      await FirebaseAuth.instance.signInWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? "An error occurred");
    }
  }
  Future<void> createUserWithEmailAndPassword() async {
    try{
      await FirebaseAuth.instance.createUserWithEmailAndPassword(
        email: _emailController.text.trim(),
        password: _passwordController.text.trim(),
      );
    } on FirebaseAuthException catch (e) {
      setState(() => _error = e.message ?? "An error occurred");
    }
  }
  Widget _title(){
    return const Text("Firebase Auth");
  }
  Widget _entryField(
    String title,
    TextEditingController controller, 
  ){
    return TextField(
      controller: controller,
      decoration: InputDecoration(labelText: title),
    );
  }
  Widget _errorMessage(){
    return Text(
      _error,
      style: const TextStyle(color: Colors.red),
    );
  }
  Widget _submitButton(){
    return ElevatedButton(
      onPressed: isLogin ? signInWithEmailAndPassword : createUserWithEmailAndPassword,
      child: Text(isLogin ? "Login" : "Create Account"),
    );
  }
  Widget _loginOrRegisterButton(){
    return TextButton(
      onPressed: (){
        setState(() {
          isLogin = !isLogin;
          _error = "";
        });
      },
      child: Text(isLogin ? "Create an account" : "Have an account? Sign in"),
    );
  }


  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: _title(),
      ),
      body:Column(
        crossAxisAlignment: CrossAxisAlignment.center,
        mainAxisAlignment: MainAxisAlignment.center,
        children:<Widget>[
          _entryField("Email", _emailController),
          _entryField("Password", _passwordController),
          _errorMessage(),
          _submitButton(),
          _loginOrRegisterButton(),
        ],//widgets
      ),
    );
  }
}
