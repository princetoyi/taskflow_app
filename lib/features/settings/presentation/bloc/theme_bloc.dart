import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:flutter/material.dart';
import '../../data/repositories/theme_repository.dart';
import 'theme_event.dart';
import 'theme_state.dart';

class ThemeBloc extends Bloc<ThemeEvent, ThemeState> {
  final ThemeRepository themeRepository;

  ThemeBloc({required this.themeRepository}) : super(const ThemeInitial()) {
    on<LoadTheme>(_onLoadTheme);
    on<ToggleThemeMode>(_onToggleThemeMode);
  }

  Future<void> _onLoadTheme(LoadTheme event, Emitter<ThemeState> emit) async {
    final stored = await themeRepository.getThemeMode();
    final themeMode = stored == 'dark' ? ThemeMode.dark : ThemeMode.light;
    emit(ThemeLoaded(themeMode));
  }

  Future<void> _onToggleThemeMode(ToggleThemeMode event, Emitter<ThemeState> emit) async {
    final currentMode = state is ThemeLoaded ? (state as ThemeLoaded).mode : ThemeMode.light;
    final nextMode = currentMode == ThemeMode.dark ? ThemeMode.light : ThemeMode.dark;
    final modeString = nextMode == ThemeMode.dark ? 'dark' : 'light';
    await themeRepository.saveThemeMode(modeString);
    emit(ThemeLoaded(nextMode));
  }
}
