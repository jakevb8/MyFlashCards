import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../../core/theme/app_theme.dart';
import 'theme_event.dart';
import 'theme_state.dart';

const _kThemeTypeKey = 'theme_type';
const _kThemeModeKey = 'theme_mode';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc({ThemeState? initialState})
    : super(initialState ?? const ThemeState()) {
    on<ChangeThemeType>(_onChangeThemeType);
    on<ToggleBrightness>(_onToggleBrightness);
    on<SetBrightness>(_onSetBrightness);
  }

  /// Load persisted theme from SharedPreferences (call before runApp).
  static Future<ThemeState> loadSaved() async {
    final prefs = await SharedPreferences.getInstance();
    final typeIndex = prefs.getInt(_kThemeTypeKey) ?? 0;
    final modeIndex = prefs.getInt(_kThemeModeKey) ?? 0;
    final themeType =
        AppThemeType.values[typeIndex.clamp(0, AppThemeType.values.length - 1)];
    final themeMode =
        ThemeMode.values[modeIndex.clamp(0, ThemeMode.values.length - 1)];
    return ThemeState(themeType: themeType, themeMode: themeMode);
  }

  Future<void> _save(ThemeState s) async {
    final prefs = await SharedPreferences.getInstance();
    await prefs.setInt(_kThemeTypeKey, s.themeType.index);
    await prefs.setInt(_kThemeModeKey, s.themeMode.index);
  }

  void _onChangeThemeType(ChangeThemeType event, Emitter<ThemeState> emit) {
    final next = state.copyWith(themeType: event.themeType);
    emit(next);
    _save(next);
  }

  void _onToggleBrightness(ToggleBrightness event, Emitter<ThemeState> emit) {
    final nextMode = switch (state.themeMode) {
      ThemeMode.system => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.system,
    };
    final next = state.copyWith(themeMode: nextMode);
    emit(next);
    _save(next);
  }

  void _onSetBrightness(SetBrightness event, Emitter<ThemeState> emit) {
    final next = state.copyWith(themeMode: event.themeMode);
    emit(next);
    _save(next);
  }
}
