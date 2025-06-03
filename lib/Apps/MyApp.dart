import 'package:flutter/material.dart';
import 'package:http/http.dart';
import 'package:provider/provider.dart';
import 'package:vinylhub/Views/BusquedaView.dart';
import 'package:vinylhub/Views/ChatView.dart';
import 'package:vinylhub/Views/EditPost.dart';
import 'package:vinylhub/Views/FavoritosView.dart';
import 'package:vinylhub/Views/PerfilAjenoView.dart';
import 'package:vinylhub/Views/PostDetails.dart';
import 'package:vinylhub/Views/PostDetailsPropio.dart';
import 'package:vinylhub/Views/TuPerfil.dart';
import '../Singletone/ThemeProvider.dart';



import '../Views/AjustesView.dart';
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
    final themeProvider = Provider.of<ThemeProvider>(context);

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
      '/postdetailspropio': (context) => PostDetailsPropio(onClose: (){}),
      '/postdetailsajeno': (context) => PostDetails(onClose: () {  },),
      '/ajustesview': (context) => const AjustesView(),


    };

    MaterialApp app = MaterialApp(
        title: "VinylHub",
        routes: rutas,
        initialRoute: '/splashview',
        debugShowCheckedModeBanner: true,
        themeMode: themeProvider.themeMode,
        theme: ThemeData.light(),
        darkTheme: ThemeData.dark(),
        onGenerateRoute: (settings) {
          if (settings.name == '/perfilajeno') {
            final uidAjeno = settings.arguments as String;
            return MaterialPageRoute(
              builder: (context) => PerfilAjenoView(uidAjeno: uidAjeno),
            );
          }
        },
    );



    return app; //hey pequeña
  }
}