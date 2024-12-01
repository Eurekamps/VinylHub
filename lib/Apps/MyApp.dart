import 'package:flutter/material.dart';


import '../Views/LoginView.dart';
import '../Views/RegisterView.dart';
import '../Views/Splashview.dart';

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {


    Map<String, Widget Function(BuildContext)> rutas = {
      '/splashview':(context) =>   SplashView(),
      '/loginview':(context) =>   LoginView(),
      //'/homeview':(context) =>   HomeView(),
      '/registerview':(context) => RegisterView(),
      //'/profileview': (context) => ProfileView()
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