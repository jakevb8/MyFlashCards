import 'package:equatable/equatable.dart';

abstract class AnalyticsEvent extends Equatable {
  const AnalyticsEvent();
  @override
  List<Object?> get props => [];
}

/// Loads (or reloads) analytics from the session repository.
/// Dispatched on app start and after each completed study session.
class LoadAnalytics extends AnalyticsEvent {
  const LoadAnalytics();
}
