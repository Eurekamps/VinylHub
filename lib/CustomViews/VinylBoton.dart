import 'package:flutter/material.dart';

class VinylBoton extends StatelessWidget{

  String sTitulo;
  String sImagenBoton;
  double dWidth;
  double dHeight;
  Color color;
  Function() onBotonVinylPressed;

  VinylBoton({super.key,this.color=Colors.black, this.sTitulo="Login",
    this.sImagenBoton='assets/botonvinilo.png',
    this.dHeight=40, this.dWidth=120, required this.onBotonVinylPressed
  });

  @override
  Widget build(BuildContext context) {
    // TODO: implement build
    return InkWell(
      onTap: (){onBotonVinylPressed();},
      child: Container(
        color: Colors.black12,
        height: dHeight,
        width: dWidth,
        child: Row(
          children: [
            Image.asset(
              sImagenBoton,
              height: dHeight * 0.7, // Ajusta la altura relativa a dHeight del botón
              width: dHeight * 0.7,  // Ajusta el ancho de la imagen para mantener proporción
              fit: BoxFit.contain,   // Asegura que la imagen se ajuste sin desbordarse
            ),
            const SizedBox(width: 8.0), // Espacio entre imagen y texto
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown, // Ajusta el texto si es necesario
                child: Text(sTitulo, style: TextStyle(color: color),),
              ),
            ),
          ],
        ),
      ),

    );
  }

}