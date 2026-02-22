import 'package:flutter/material.dart';
import 'package:equatable/equatable.dart';
import '../../core/theme/app_theme.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();
  @override
  List<Object?> get props => [];
}

class ChangeThemeType extends ThemeEvent {
  final AppThemeType themeType;
  const ChangeThemeType(this.themeType);
  @override
  List<Object?> get props => [themeType];
}

class ToggleBrightness extends ThemeEvent {}

class SetBrightness extends ThemeEvent {
  final ThemeMode themeMode;
  const SetBrightness(this.themeMode);
  @override
  List<Object?> get props => [themeMode];
}

/// Switch between adult and kids theme palettes.
/// Automatically selects [AppThemeType.classic] ↔ [AppThemeType.sunshine]
/// if the current theme doesn't belong to the new palette.
class ToggleKidsMode extends ThemeEvent {}
