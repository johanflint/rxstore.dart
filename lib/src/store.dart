import 'dart:async';

import 'package:rxdart/rxdart.dart';

/// An action contains only data that is to be sent to a [Store] or an [Epic].
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

/// An epic is used for asynchronous operations based on an action.
///
/// It is a function which takes a stream of [Action]s and returns a stream of
/// actions. Returned actions are immediately dispatched.
///
/// Epics cannot prevent actions from being handled by the reducers.
///
/// If an incoming action is passed through, an infinite loop is created.
typedef Epic<State> = Stream<Action<dynamic>> Function(Stream<Action<dynamic>> actions, ValueObservable<State> state);

/// Combines a list of [Epic]s into one.
Epic<State> combineEpics<State>(List<Epic<State>> epics) {
  return (Stream<Action<dynamic>> actions, ValueObservable<State> state) {
    return MergeStream<Action<dynamic>>(epics.map((Epic<State> epic) => epic(actions, state)));
  };
}

/// A store to hold the state of the app.
///
/// The state can only be changed by passing an [Action] to the [dispatcher].
/// The action will be sent to the [Reducer] to calculate the new state.
///
/// Listen to the [state] stream to get the current state and receive updates.
class Store<State> {
  Store(this._reducer, {State initialState, Epic<State> epic, bool sync = false})
      : _changeSubject = BehaviorSubject<State>(seedValue: initialState, sync: sync),
        _dispatchSubject = PublishSubject<Action<dynamic>>(sync: sync) {
    if (epic != null) {
      final actions = epic(_dispatchSubject.stream, state);
      assert(actions != null, 'An epic must return a stream of actions');
      actions.listen(dispatcher.add);
    }
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
