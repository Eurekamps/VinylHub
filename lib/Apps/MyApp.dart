import 'package:flutter/material.dart';
import 'package:hijos_de_fluttarkia/Views/ChatView.dart';
import 'package:hijos_de_fluttarkia/Views/PostDetails.dart';


import '../Views/HomeView.dart';
import '../Views/LoginView.dart';
import '../Views/ProfileView.dart';
import '../Views/RegisterView.dart';
import '../Views/Splashview.dart';
import '../Views/home_screen.dart';

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {


    Map<String, Widget Function(BuildContext)> rutas = {
      '/splashview':(context) =>   SplashView(),
      '/loginview':(context) =>   LoginView(),
      '/homeview':(context) =>   HomeScreen(),
      '/registerview':(context) => RegisterView(),
      '/profileview': (context) => ProfileView(),
      '/chatview': (context) => ChatView(),
      '/home'
      '/postdetails': (context) => PostDetails(onClose: () {  },)
    };

    MaterialApp app = MaterialApp(
        title: " Hijos de Flutter",
        routes: rutas,
        initialRoute: '/splashview',
        debugShowCheckedModeBanner: true
    );



    return app; //hey pequeña
  }
}