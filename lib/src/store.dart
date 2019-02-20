import 'dart:async';

import 'package:rxdart/rxdart.dart';

/// An action contains only data that is to be sent to a store.
abstract class Action<Payload> {
  Payload get payload;
}

/// A reducer takes the current [State] and an [Action] and returns the new
/// state.
///
/// ```dart
/// int counterReducer(int state, Action<dynamic> action) {
///   if (action is IncrementCounterAction) {
///     return state + action.payload;
///   }
///
///   return state;
/// }
/// ```
typedef Reducer<State> = State Function(State state, Action<dynamic> action);

/// A store to hold the state of the app.
///
/// The state can only be changed by passing an [Action] to the [dispatcher].
/// The action will be sent to the [Reducer] to calculate the new state.
///
/// Listen to the [state] stream to get the current state and receive updates.
class Store<State> {
  Store(this._reducer, {State initialState, bool sync = false})
      : _changeSubject = BehaviorSubject<State>(seedValue: initialState, sync: sync),
        _dispatchSubject = PublishSubject<Action<dynamic>>(sync: sync) {
    _dispatchSubject.stream.listen(_reduce);
  }

  final Reducer<State> _reducer;
  final BehaviorSubject<State> _changeSubject;
  final PublishSubject<Action<dynamic>> _dispatchSubject;

  ValueObservable<State> get state => _changeSubject.stream;

  StreamSink<Action<dynamic>> get dispatcher => _dispatchSubject.sink;

  void _reduce(Action<dynamic> action) {
    final currentState = state.value;
    final newState = _reducer(currentState, action);
    if (newState != currentState) {
      _changeSubject.add(newState);
    }
  }

  Future<List<dynamic>> dispose() {
    return Future.wait<dynamic>(<Future<dynamic>>[_changeSubject.close(), _dispatchSubject.close()]);
  }
}
