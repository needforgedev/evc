import 'package:flutter/material.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

void main() => runApp(const EvcRiderApp());

/// EVC Rider — passenger app. A thin shell over the shared evc_* packages.
class EvcRiderApp extends StatelessWidget {
  const EvcRiderApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: EvcApp.rider.displayName,
      theme: evcTheme(),
      debugShowCheckedModeBanner: false,
      home: const EvcLandingScreen(app: EvcApp.rider),
    );
  }
}
