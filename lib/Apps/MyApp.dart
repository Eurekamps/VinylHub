import 'package:flutter/material.dart';
import 'package:vinylhub/Views/BusquedaView.dart';
import 'package:vinylhub/Views/ChatView.dart';
import 'package:vinylhub/Views/FavoritosView.dart';
import 'package:vinylhub/Views/PostDetails.dart';
import 'package:vinylhub/Views/PostDetailsPropio.dart';
import 'package:vinylhub/Views/TuPerfil.dart';



import '../Views/EditProfileView.dart';
import '../Views/HomeView.dart';
import '../Views/LoginView.dart';
import '../Views/ProfileView.dart';
import '../Views/RegisterView.dart';
import '../Views/Splashview.dart';

class MyApp extends StatelessWidget{
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {


    Map<String, Widget Function(BuildContext)> rutas = {
      '/splashview':(context) =>   SplashView(),
      '/loginview':(context) =>   LoginView(),
      '/homeview':(context) =>   HomeView(),
      '/registerview':(context) => RegisterView(),
      '/profileview': (context) => ProfileView(),
      '/chatview': (context) => ChatView(),
      '/postdetails': (context) => PostDetails(onClose: () {  },),
      '/tuperfil': (context) => TuPerfil(),
      '/editprofileview': (context) => EditProfileView(),
      '/favoritosview': (context) => FavoritosView(),
      '/busquedaview': (context) => BusquedaView(),
      '/postdetailspropio': (context) => PostDetailsPropio(onClose: (){})


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