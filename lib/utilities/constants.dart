import 'dart:ui';

import 'package:firebase_auth/firebase_auth.dart';
import 'package:google_sign_in/google_sign_in.dart';

Color secondaryColor = Color.fromRGBO(44,50,190,1);
Color primaryColor = Color.fromRGBO(65,97,255,1);

final GoogleSignIn gSignIn = GoogleSignIn();
final FirebaseAuth firebaseauth = FirebaseAuth.instance ;
class ScreenSize {
  static Size size;
}
