import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  ThemeBloc() : super(const ThemeState()) {
    on<ChangeThemeType>(_onChangeThemeType);
    on<ToggleBrightness>(_onToggleBrightness);
    on<SetBrightness>(_onSetBrightness);
  }

  void _onChangeThemeType(ChangeThemeType event, Emitter<ThemeState> emit) {
    emit(state.copyWith(themeType: event.themeType));
  }

  void _onToggleBrightness(ToggleBrightness event, Emitter<ThemeState> emit) {
    final next = switch (state.themeMode) {
      ThemeMode.system => ThemeMode.dark,
      ThemeMode.dark => ThemeMode.light,
      ThemeMode.light => ThemeMode.system,
    };
    emit(state.copyWith(themeMode: next));
  }

  void _onSetBrightness(SetBrightness event, Emitter<ThemeState> emit) {
    emit(state.copyWith(themeMode: event.themeMode));
  }
}
