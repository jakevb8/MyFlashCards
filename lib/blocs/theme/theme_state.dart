import 'package:equatable/equatable.dart';
import 'package:flutter/material.dart';
import '../../core/theme/app_theme.dart';

class ThemeState extends Equatable {
  final AppThemeType themeType;
  final ThemeMode themeMode;
  final bool isKidsMode;

  const ThemeState({
    this.themeType = AppThemeType.classic,
    this.themeMode = ThemeMode.system,
    this.isKidsMode = false,
  });

  ThemeState copyWith({
    AppThemeType? themeType,
    ThemeMode? themeMode,
    bool? isKidsMode,
  }) => ThemeState(
    themeType: themeType ?? this.themeType,
    themeMode: themeMode ?? this.themeMode,
    isKidsMode: isKidsMode ?? this.isKidsMode,
  );

  @override
  List<Object?> get props => [themeType, themeMode, isKidsMode];
}
