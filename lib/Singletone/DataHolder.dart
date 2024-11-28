import 'package:cloud_firestore/cloud_firestore.dart';

import '../FbObjects/FbPerfil.dart';

class DataHolder {

  static final DataHolder _instance = DataHolder._internal();


  FbPerfil? miPerfil;


  DataHolder._internal();

  factory DataHolder(){
    return _instance;
  }

}