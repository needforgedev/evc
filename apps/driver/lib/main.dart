import 'package:flutter/material.dart';
import 'package:evc_core/evc_core.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

void main() => runApp(const EvcDriverApp());

/// EVC Driver — partner app. A thin shell over the shared evc_* packages.
class EvcDriverApp extends StatelessWidget {
  const EvcDriverApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: EvcApp.driver.displayName,
      theme: evcTheme(),
      debugShowCheckedModeBanner: false,
      home: const EvcLandingScreen(app: EvcApp.driver),
    );
  }
}
