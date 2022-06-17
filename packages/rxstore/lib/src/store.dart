import 'dart:async';

import 'package:rxdart/rxdart.dart';

/// An action contains only data that is to be sent to a [Store] or an [Epic].
abstract class Action {}

/// A reducer takes the current [State] and an [Action] and returns the new
/// state.
///
/// ```dart
/// int counterReducer(int state, Action action) {
///   if (action is IncrementCounter) {
///     return state + action.payload;
///   }
///
///   return state;
/// }
/// ```
typedef Reducer<State> = State Function(State state, Action action);

/// Combines a list of [Reducer]s into one.
Reducer<State> combineReducers<State>(List<Reducer<State>> reducers) {
  return (State state, Action action) {
    return reducers.fold<State>(state, (State state, Reducer<State> reducer) => reducer(state, action));
  };
}

/// An epic is used for asynchronous operations based on an action.
///
/// It is a function which takes a stream of [Action]s and returns a stream of
/// actions. Returned actions are immediately dispatched.
///
/// Epics cannot prevent actions from being handled by the reducers.
///
/// If an incoming action is passed through, an infinite loop is created.
typedef Epic<State> = Stream<Action> Function(Stream<Action> actions, ValueStream<State> state);

/// Combines a list of [Epic]s into one.
Epic<State> combineEpics<State>(List<Epic<State>> epics) {
  return (Stream<Action> actions, ValueStream<State> state) {
    return MergeStream<Action>(epics.map((Epic<State> epic) => epic(actions, state)));
  };
}

/// A store to hold the state of the app.
///
/// The state can only be changed by passing an [Action] to the [dispatcher].
/// The action will be sent to the [Reducer] to calculate the new state.
///
/// [Epic]s are used for asynchronous operations.
///
/// Listen to the [state] stream to get the current state and receive updates.
class Store<State> {
  /// Creates a new instance of a store.
  ///
  /// The [_reducer] defines how state is changed when actions are dispatched.
  ///
  /// Provide the [initialState] to pass to the store. This is required so a
  /// value can always be emitted to subscribers, even if no actions have been
  /// dispatched.
  ///
  /// Optionally pass an [epic] to handle asynchronous operations. Epics are
  /// called after reducers to guarantee that the state is up-to-date.
  ///
  /// The [sync] argument determines whether synchronous dispatching is used.
  /// By default asynchronous dispatching is used. See [BehaviorSubject.seeded]
  /// for more information. Only change this if you know what you are doing.
  Store(this._reducer, {required State initialState, Epic<State>? epic, bool sync = false})
      : _changeSubject = BehaviorSubject<State>.seeded(initialState, sync: sync),
        _dispatchSubject = PublishSubject<Action>(sync: sync),
        _dispatchEpicSubject = PublishSubject<Action>(sync: sync) {
    if (epic != null) {
      _epicSubscription = epic(_dispatchEpicSubject.stream, state).listen(dispatcher.add);
    }

    _dispatchSubject.stream.map(_reduce).listen(_dispatchEpicSubject.add);
  }

  final Reducer<State> _reducer;
  final BehaviorSubject<State> _changeSubject;
  final PublishSubject<Action> _dispatchSubject;
  final PublishSubject<Action> _dispatchEpicSubject;

  StreamSubscription? _epicSubscription;

  /// A [Stream] that emits the latest state on subscribe and when it changes.
  ValueStream<State> get state => _changeSubject.stream;

  /// A [StreamSink] to dispatch actions.
  StreamSink<Action> get dispatcher => _dispatchSubject.sink;

  /// Dispatches an action by passing it to the reducer and, optionally, the epic.
  void dispatch(Action action) {
    dispatcher.add(action);
  }

  Action _reduce(Action action) {
    final currentState = state.requireValue;
    final newState = _reducer(currentState, action);
    if (newState != currentState) {
      _changeSubject.add(newState);
    }
    return action;
  }

  /// Disposes the streams of the store.
  /// Only use this if the store has to be disposed in a running app.
  Future<List<dynamic>> dispose() {
    return Future.wait<dynamic>(<Future<dynamic>>[
      if (_epicSubscription != null) _epicSubscription!.cancel(),
      _changeSubject.close(),
      _dispatchSubject.close(),
    ]);
  }
}
