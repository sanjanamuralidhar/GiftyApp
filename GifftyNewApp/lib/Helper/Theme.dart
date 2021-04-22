import 'package:flutter/material.dart';
// import 'package:provider/provider.dart';


class ThemeNotifier with ChangeNotifier {
    ThemeMode _themeMode;

    ThemeNotifier(this._themeMode);

    getThemeMode() => _themeMode;

    setThemeMode(ThemeMode mode) async {
        _themeMode = mode;
        notifyListeners();
    }
}


