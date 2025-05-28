import 'package:flutter/cupertino.dart';

import '../FbObjects/FbPost.dart';
import 'DataHolder.dart';

class AppNavigationUtils {
  static void onPostClicked(BuildContext context, FbPost post) {
    DataHolder().fbPostSelected = post;
    Navigator.of(context).pushNamed('/postdetails');
  }
}
