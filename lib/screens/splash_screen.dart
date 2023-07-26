import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:we_talk/screens/login_screen.dart';
import 'home_screen.dart';

class SplashScreen extends StatefulWidget {
  const SplashScreen({Key? key}) : super(key: key);

  @override
  State<SplashScreen> createState() => _SplashScreenState();
}

class _SplashScreenState extends State<SplashScreen> {

  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    navigateMethod();
  }

  @override
  Widget build(BuildContext context) {
    return const Scaffold(
      backgroundColor: Colors.indigo,
      body: Center(
        child:
      Text('We Talk',style: TextStyle(
        fontSize: 50,
        fontWeight: FontWeight.bold,
        color: Colors.white
      ))
      ,),);
  }

  void navigateMethod() {
    FirebaseAuth auth = FirebaseAuth.instance;
    Future.delayed(const Duration(seconds: 3)).then((value) {
      if(auth.currentUser != null )
      {
        Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const HomePage(),));
      }
      else
        {
          Navigator.of(context).pushReplacement(MaterialPageRoute(builder: (context) => const LoginScreen(),));
        }
    },);
  }
}
