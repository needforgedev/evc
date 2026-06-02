import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:evc_ui_kit/evc_ui_kit.dart';

void main() {
  test('evcTheme is Material 3 and uses the EV-green seed', () {
    final theme = evcTheme();
    expect(theme.useMaterial3, isTrue);
    expect(theme.colorScheme.brightness, Brightness.light);
  });
}