import 'package:firebase_auth/firebase_auth.dart';
import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

class SplashView extends StatefulWidget{
  const SplashView({super.key});

  @override
  State<SplashView> createState() => _SplashViewState();
}

class _SplashViewState extends State<SplashView> {

  double dbPorcentaje=0.0;


  @override
  void initState() {
    // TODO: implement initState
    super.initState();
    loading();
  }

  void loading() async {
    while (dbPorcentaje <= 1.0) {
      print('Valor actual $dbPorcentaje');
      setState(() {
        dbPorcentaje += 0.05;
      });
      await Future.delayed(Duration(milliseconds: 50));
    }
    if(FirebaseAuth.instance.currentUser!=null) {
      Navigator.of(context).pushNamed('/homeview');
    }else{
      Navigator.of(context).pushNamed('/loginview');
    }
  }

  Widget build(BuildContext context) {
    return Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(
          "VinylHub",
          style: GoogleFonts.robotoMono(
            color: Colors.white,
            fontSize: 24, // Ajusta este valor para cambiar el tamaño del texto.
            decoration: TextDecoration.none,
          ),
        ),

        //sizedbox para el gif
        SizedBox(
          width: 150,  // Ajusta este valor para cambiar el ancho de la imagen.
          height: 150, // Ajusta este valor para cambiar la altura de la imagen.
          child: Image.network(
            "https://media3.giphy.com/media/Yq2DaPfhTMb3GEZWju/200w.gif?cid=6c09b952u6z1bho6usxh44yk3z393rwdnwc5advd8cx0dl6w&ep=v1_gifs_search&rid=200w.gif&ct=g",
            fit: BoxFit.contain,
          ),
        ),

        const CircularProgressIndicator(color: Colors.white54),

      ],
    );
  }

}