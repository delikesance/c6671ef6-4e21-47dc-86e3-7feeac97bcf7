// ignore_for_file: avoid_print, deprecated_member_use
import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bot_creator/core/theme/app_theme.dart';

void main() {
  test('Print theme colors', () {
    final light = AppTheme.lightTheme();
    print('Light Scheme surface: ${light.colorScheme.surface}');
    print('Light Scheme primary: ${light.colorScheme.primary}');
    print('Light Scheme primaryContainer: ${light.colorScheme.primaryContainer}');
    print('Light Scheme secondary: ${light.colorScheme.secondary}');
    print('Light Scheme secondaryContainer: ${light.colorScheme.secondaryContainer}');
    print('Light Scheme tertiary: ${light.colorScheme.tertiary}');
    print('Light Scheme tertiaryContainer: ${light.colorScheme.tertiaryContainer}');
    print('Light Scheme background: ${light.colorScheme.surface}');
    
    // Check some specific color components
    final c1 = const Color(0xFF141C2A);
    print('Color 0xFF141C2A: red=${c1.red/255}, green=${c1.green/255}, blue=${c1.blue/255}');
    
    final c2 = const Color(0xFF151C2A);
    print('Color 0xFF151C2A: red=${c2.red/255}, green=${c2.green/255}, blue=${c2.blue/255}');
    
    final c3 = const Color(0xFF141B2A);
    print('Color 0xFF141B2A: red=${c3.red/255}, green=${c3.green/255}, blue=${c3.blue/255}');
  });
}
