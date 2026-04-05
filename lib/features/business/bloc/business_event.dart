import 'package:equatable/equatable.dart';
import 'package:scheduler_frontend/features/business/data/business_model.dart';

sealed class BusinessEvent extends Equatable {
  const BusinessEvent();
  @override
  List<Object?> get props => [];
}

class BusinessLoadRequested extends BusinessEvent {
  const BusinessLoadRequested();
}

class BusinessSelected extends BusinessEvent {
  final BusinessModel business;
  const BusinessSelected(this.business);
  @override
  List<Object?> get props => [business];
}

/// Emitted on logout to wipe loaded data from memory.
class BusinessSessionCleared extends BusinessEvent {
  const BusinessSessionCleared();
}
