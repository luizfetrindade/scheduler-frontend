import 'dart:async';
import 'package:flutter/foundation.dart';
import 'package:scheduler_frontend/core/auth/auth_bloc.dart';

/// Bridges AuthBloc's stream to GoRouter's refreshListenable.
/// GoRouter calls redirect() whenever this notifier fires,
/// which happens on every AuthState change.
class RouterNotifier extends ChangeNotifier {
  late final StreamSubscription<dynamic> _sub;

  RouterNotifier(AuthBloc authBloc) {
    _sub = authBloc.stream.listen((_) => notifyListeners());
  }

  @override
  void dispose() {
    _sub.cancel();
    super.dispose();
  }
}
