import 'package:flutter/material.dart';

class CustomTextField extends StatelessWidget {
  final String hintText;
  final String? imageUrl; // URL de la imagen
  final TextEditingController controller;
  final bool isPassword; // Indica si el campo es para contraseñas
  final Color borderColor;
  final Color hintColor;

  const CustomTextField({
    Key? key,
    required this.hintText,
    this.imageUrl,
    required this.controller,
    this.isPassword = false,
    this.borderColor = Colors.black,
    this.hintColor = Colors.grey, required TextInputType keyboardType,
  }) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return TextFormField(
      controller: controller,
      obscureText: isPassword,
      decoration: InputDecoration(
        hintText: hintText,
        hintStyle: TextStyle(color: hintColor),
        border: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
        ),
        focusedBorder: OutlineInputBorder(
          borderRadius: BorderRadius.circular(12),
          borderSide: BorderSide(color: borderColor, width: 2.0),
        ),
        prefixIcon: imageUrl != null
            ? Padding(
          padding: const EdgeInsets.all(8.0),
          child: Image.network(
            imageUrl!,
            width: 24,
            height: 24,
            errorBuilder: (context, error, stackTrace) => const Icon(Icons.error),
          ),
        )
            : null,
      ),
    );
  }
}
