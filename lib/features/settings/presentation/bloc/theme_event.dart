import 'package:equatable/equatable.dart';

abstract class ThemeEvent extends Equatable {
  const ThemeEvent();

  @override
  List<Object?> get props => [];
}

class LoadTheme extends ThemeEvent {
  const LoadTheme();
}

class ToggleThemeMode extends ThemeEvent {
  const ToggleThemeMode();
}
