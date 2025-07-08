import 'package:flutter/foundation.dart';

class d{
  static p(String message) {
    if(kDebugMode) {
      print('[DEBUG]: $message');
    }
  }
}