import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';

import 'package:loqta/core/theme/app_theme.dart';

void main() {
  group('LoqtaTheme', () {
    test('light ThemeData brightness matches its ColorScheme', () {
      final theme = LoqtaTheme.light;

      expect(theme.brightness, Brightness.light);
      expect(theme.colorScheme.brightness, theme.brightness);
    });

    test('dark ThemeData brightness matches its ColorScheme', () {
      final theme = LoqtaTheme.dark;

      expect(theme.brightness, Brightness.dark);
      expect(theme.colorScheme.brightness, theme.brightness);
    });
  });
}
