import 'dart:async';

import 'package:rxdart/rxdart.dart';
import 'package:rxstore/rxstore.dart';
import 'package:test/test.dart';

void main() {
  group('Store', () {
    test('passes the initial state to subscribers', () {
      final store = Store<int>(intReducer, initialState: 42);
      expect(store.state.value, equals(42));
      store.dispose();
    });

    test('calls the reducer when an action is received', () async {
      var isCalled = false;
      int reducer(int state, Action action) {
        isCalled = true;
        return state;
      }

      final store = Store<int>(reducer, initialState: 42);
      expect(isCalled, isFalse);

      store.dispatcher.add(const AddInt(1337));
      await store.dispose();

      expect(isCalled, isTrue);
    });

    test('calls the reducer when an action is received through dispatch', () async {
      var isCalled = false;
      int reducer(int state, Action action) {
        isCalled = true;
        return state;
      }

      final store = Store<int>(reducer, initialState: 42);
      expect(isCalled, isFalse);

      store.dispatch(const AddInt(1337));
      await store.dispose();

      expect(isCalled, isTrue);
    });

    test('calls combined reducers when an action is received', () {
      final store = Store<TestState>(
        combineReducers(<Reducer<TestState>>[reducerOne, reducerTwo]),
        initialState: const TestState(),
      );

      expect(
          store.state,
          emitsInOrder(<TestState>[
            const TestState(reducerOneCalled: false, reducerTwoCalled: false), // Initial state
            const TestState(reducerOneCalled: true, reducerTwoCalled: true), // AddInt(42)
          ]));

      store.dispatch(const AddInt(42));
      scheduleMicrotask(store.dispose);
    });

    test('notifies subscribers with the updated state when an action is reduced', () {
      final store = Store<int>(intReducer, initialState: 42, sync: true);

      expect(store.state, emitsInOrder(<int>[42, 1337]));

      store
        ..dispatch(const AddInt(1337))
        ..dispose();
    });

    test('does not notify subscribers if the state did not change', () {
      final store = Store<int>(intReducer, initialState: 42, sync: true);

      expect(store.state, emitsInOrder(<int>[42]));

      store
        ..dispatch(const AddInt(42))
        ..dispose();
    });

    group('with epics', () {
      test('passes the action stream to the epic', () {
        Stream<Action> epic(Stream<Action> actions, ValueStream<int> state) {
          expect(actions, emitsInOrder(<AddInt>[const AddInt(42), const AddInt(1337)]));

          return const Stream<Action>.empty();
        }

        Store<int>(intReducer, initialState: 42, epic: epic)..dispatch(const AddInt(42))..dispatch(const AddInt(1337));
      });

      test('dispatches the emitted actions', () async {
        Stream<Action> epic(Stream<Action> actions, ValueStream<int> state) =>
            actions.whereType<AddInt>().map((AddInt action) => const MultiplyInt(2));

        final store = Store<int>(intReducer, initialState: 0, epic: epic)..dispatch(const AddInt(3));

        expect(
            store.state,
            emitsInOrder(<int>[
              0, // Initial state
              3, // AddInt(3)
              6, // MultiplyInt(2)
            ]));
      });

      test('throws if null is emitted', () async {
        Stream<Action> epic(Stream<Action> actions, ValueStream<int> state) {
          return null;
        }

        expect(() => Store<int>(intReducer, initialState: 42, epic: epic), throwsA(isA<AssertionError>()));
      });

      test('passes the action stream to combined epics', () {
        Stream<Action> epicOne(Stream<Action> actions, ValueStream<int> state) {
          expect(actions, emitsInOrder(<AddInt>[const AddInt(42), const AddInt(1337)]));

          return const Stream<Action>.empty();
        }

        Stream<Action> epicTwo(Stream<Action> actions, ValueStream<int> state) {
          expect(actions, emitsInOrder(<AddInt>[const AddInt(42), const AddInt(1337)]));

          return const Stream<Action>.empty();
        }

        Store<int>(intReducer, initialState: 42, epic: combineEpics(<Epic<int>>[epicOne, epicTwo]))
          ..dispatch(const AddInt(42))
          ..dispatch(const AddInt(1337));
      });
    });
  });
}

class AddInt implements Action {
  const AddInt(this.payload);

  final int payload;

  @override
  String toString() => 'AddInt{payload: $payload}';
}

class MultiplyInt implements Action {
  const MultiplyInt(this.payload);

  final int payload;

  @override
  String toString() => 'MultiplyInt{payload: $payload}';
}

int intReducer(int state, Action action) {
  if (action is AddInt) {
    return action.payload;
  }

  if (action is MultiplyInt) {
    return state * action.payload;
  }

  return state;
}

class TestState {
  const TestState({this.reducerOneCalled = false, this.reducerTwoCalled = false});

  final bool reducerOneCalled;
  final bool reducerTwoCalled;

  @override
  bool operator ==(Object other) =>
      identical(this, other) ||
      other is TestState &&
          runtimeType == other.runtimeType &&
          reducerOneCalled == other.reducerOneCalled &&
          reducerTwoCalled == other.reducerTwoCalled;

  @override
  int get hashCode => reducerOneCalled.hashCode ^ reducerTwoCalled.hashCode;

  @override
  String toString() => 'TestState{reducerOneCalled: $reducerOneCalled, reducerTwoCalled: $reducerTwoCalled}';
}

TestState reducerOne(TestState state, Action action) =>
    TestState(reducerOneCalled: true, reducerTwoCalled: state.reducerTwoCalled);

TestState reducerTwo(TestState state, Action action) =>
    TestState(reducerOneCalled: state.reducerOneCalled, reducerTwoCalled: true);
