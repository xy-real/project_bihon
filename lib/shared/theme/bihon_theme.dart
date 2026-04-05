import 'package:flutter/widgets.dart';
import 'package:shadcn_ui/shadcn_ui.dart';

class BihonTheme {
  static const Color bihonOrange = Color(0xFFFF7A1A);
  static const Color bihonOrangeDark = Color(0xFFE76500);
  static const Color bihonYellow = Color(0xFFFACC15);

  static ShadThemeData light() {
    return ShadThemeData(
      brightness: Brightness.light,
      radius: BorderRadius.circular(22),
      colorScheme: const ShadOrangeColorScheme.light(
        primary: bihonOrange,
        ring: bihonOrange,
        accent: bihonYellow,
        secondary: Color(0xFFF4F4F5),
      ),
    );
  }

  static ShadThemeData dark() {
    return ShadThemeData(
      brightness: Brightness.dark,
      radius: BorderRadius.circular(22),
      colorScheme: const ShadOrangeColorScheme.dark(
        primary: bihonOrangeDark,
        ring: bihonOrangeDark,
        accent: Color(0xFFCA8A04),
      ),
    );
  }
}
