import 'package:flutter/material.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:bloc_test/bloc_test.dart';
import 'package:shared_preferences/shared_preferences.dart';
import 'package:my_flash_cards/blocs/theme/theme_bloc.dart';
import 'package:my_flash_cards/blocs/theme/theme_event.dart';
import 'package:my_flash_cards/blocs/theme/theme_state.dart';
import 'package:my_flash_cards/core/theme/app_theme.dart';

void main() {
  setUp(() {
    // Provide an in-memory SharedPreferences so _save() doesn't throw in tests.
    SharedPreferences.setMockInitialValues({});
  });
  group('ThemeBloc', () {
    test('initial state is classic theme with system brightness', () {
      final bloc = ThemeBloc();
      expect(bloc.state.themeType, AppThemeType.classic);
      expect(bloc.state.themeMode, ThemeMode.system);
      bloc.close();
    });

    blocTest<ThemeBloc, ThemeState>(
      'ChangeThemeType emits new themeType',
      build: ThemeBloc.new,
      act: (b) => b.add(const ChangeThemeType(AppThemeType.oceanBlue)),
      expect: () => [
        const ThemeState(
          themeType: AppThemeType.oceanBlue,
          themeMode: ThemeMode.system,
        ),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'ChangeThemeType to roseGarden emits roseGarden',
      build: ThemeBloc.new,
      act: (b) => b.add(const ChangeThemeType(AppThemeType.roseGarden)),
      expect: () => [
        const ThemeState(
          themeType: AppThemeType.roseGarden,
          themeMode: ThemeMode.system,
        ),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'ChangeThemeType to executive emits executive',
      build: ThemeBloc.new,
      act: (b) => b.add(const ChangeThemeType(AppThemeType.executive)),
      expect: () => [
        const ThemeState(
          themeType: AppThemeType.executive,
          themeMode: ThemeMode.system,
        ),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'ToggleBrightness cycles system → dark → light → system',
      build: ThemeBloc.new,
      act: (b) => b
        ..add(ToggleBrightness())
        ..add(ToggleBrightness())
        ..add(ToggleBrightness()),
      expect: () => [
        const ThemeState(
          themeType: AppThemeType.classic,
          themeMode: ThemeMode.dark,
        ),
        const ThemeState(
          themeType: AppThemeType.classic,
          themeMode: ThemeMode.light,
        ),
        const ThemeState(
          themeType: AppThemeType.classic,
          themeMode: ThemeMode.system,
        ),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'SetBrightness sets exact ThemeMode',
      build: ThemeBloc.new,
      act: (b) => b.add(const SetBrightness(ThemeMode.dark)),
      expect: () => [
        const ThemeState(
          themeType: AppThemeType.classic,
          themeMode: ThemeMode.dark,
        ),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'theme type and brightness can be changed independently',
      build: ThemeBloc.new,
      act: (b) => b
        ..add(const ChangeThemeType(AppThemeType.roseGarden))
        ..add(const SetBrightness(ThemeMode.dark)),
      expect: () => [
        const ThemeState(
          themeType: AppThemeType.roseGarden,
          themeMode: ThemeMode.system,
        ),
        const ThemeState(
          themeType: AppThemeType.roseGarden,
          themeMode: ThemeMode.dark,
        ),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'ToggleKidsMode switches isKidsMode and defaults to sunshine theme',
      build: ThemeBloc.new,
      act: (b) => b.add(ToggleKidsMode()),
      expect: () => [
        const ThemeState(
          themeType: AppThemeType.sunshine,
          themeMode: ThemeMode.system,
          isKidsMode: true,
        ),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'ToggleKidsMode back to adult resets to classic theme',
      build: () => ThemeBloc(
        initialState: const ThemeState(
          themeType: AppThemeType.sunshine,
          themeMode: ThemeMode.system,
          isKidsMode: true,
        ),
      ),
      act: (b) => b.add(ToggleKidsMode()),
      expect: () => [
        const ThemeState(
          themeType: AppThemeType.classic,
          themeMode: ThemeMode.system,
          isKidsMode: false,
        ),
      ],
    );

    blocTest<ThemeBloc, ThemeState>(
      'ToggleKidsMode preserves theme if it already belongs to new palette',
      build: () => ThemeBloc(
        initialState: const ThemeState(
          themeType: AppThemeType.sunshine,
          themeMode: ThemeMode.system,
          isKidsMode: true,
        ),
      ),
      // Already in sunshine (kids); toggling to adult should revert to classic.
      act: (b) => b
        ..add(ToggleKidsMode()) // → adult/classic
        ..add(const ChangeThemeType(AppThemeType.executive)) // pick adult theme
        ..add(ToggleKidsMode()), // → kids again: executive is adult, so → sunshine
      expect: () => [
        const ThemeState(
          themeType: AppThemeType.classic,
          themeMode: ThemeMode.system,
          isKidsMode: false,
        ),
        const ThemeState(
          themeType: AppThemeType.executive,
          themeMode: ThemeMode.system,
          isKidsMode: false,
        ),
        const ThemeState(
          themeType: AppThemeType.sunshine,
          themeMode: ThemeMode.system,
          isKidsMode: true,
        ),
      ],
    );
  });
}
