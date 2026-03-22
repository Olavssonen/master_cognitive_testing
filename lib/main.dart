import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:flutter_master_app/app.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  // Hide system navigation bar and gesture indicator on Android
  SystemChrome.setEnabledSystemUIMode(SystemUiMode.immersiveSticky);
  
  runApp(const ProviderScope(child: MyApp()));
}
