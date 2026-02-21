import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ThemeState extends Equatable {
  final AppThemeType themeType;
  final ThemeMode themeMode;

  const ThemeState({
    this.themeType = AppThemeType.classic,
    this.themeMode = ThemeMode.system,
  });

  ThemeState copyWith({AppThemeType? themeType, ThemeMode? themeMode}) =>
      ThemeState(
        themeType: themeType ?? this.themeType,
        themeMode: themeMode ?? this.themeMode,
      );

  @override
  List<Object?> get props => [themeType, themeMode];
}
