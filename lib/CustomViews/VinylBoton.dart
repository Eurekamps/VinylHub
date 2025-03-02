import 'package:flutter/material.dart';

class VinylBoton extends StatelessWidget {
  String sTitulo;
  String sImagenBoton;
  double dWidth;
  double dHeight;
  Color color;
  Function() onBotonVinylPressed;
  BorderRadius borderRadius; // Añadido para los bordes redondeados

  VinylBoton({
    super.key,
    this.color = Colors.black,
    this.sTitulo = "Login",
    this.sImagenBoton = 'assets/app_icon.png',
    this.dHeight = 40,
    this.dWidth = 120,
    required this.onBotonVinylPressed,
    this.borderRadius = BorderRadius.zero, // Valor predeterminado si no se pasa ningún valor
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: () {
        onBotonVinylPressed();
      },
      child: Container(
        decoration: BoxDecoration(
          color: Colors.black12, // Puedes cambiar el color de fondo si lo necesitas
          borderRadius: borderRadius, // Aplicamos los bordes redondeados
        ),
        height: dHeight,
        width: dWidth,
        child: Row(
          children: [
            Image.asset(
              sImagenBoton,
              height: dHeight * 0.7,
              width: dHeight * 0.7,
              fit: BoxFit.contain,
            ),
            const SizedBox(width: 8.0), // Espacio entre imagen y texto
            Flexible(
              child: FittedBox(
                fit: BoxFit.scaleDown, // Ajusta el texto si es necesario
                child: Text(
                  sTitulo,
                  style: TextStyle(color: color),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
