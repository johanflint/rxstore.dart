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
      int reducer(int state, Action<dynamic> action) {
        isCalled = true;
        return state;
      }

      final store = Store<int>(reducer, initialState: 42);
      expect(isCalled, isFalse);

      store.dispatcher.add(const AddIntAction(1337));
      await store.dispose();

      expect(isCalled, isTrue);
    });

    test('notifies subscribers with the updated state when an action is reduced', () {
      final store = Store<int>(intReducer, initialState: 42, sync: true);

      expect(store.state, emitsInOrder(<int>[42, 1337]));

      store.dispatcher.add(const AddIntAction(1337));
      store.dispose();
    });

    test('does not notify subscribers if the state did not change', () {
      final store = Store<int>(intReducer, initialState: 42, sync: true);

      expect(store.state, emitsInOrder(<int>[42]));

      store.dispatcher.add(const AddIntAction(42));
      store.dispose();
    });

    group('with epics', () {
      test('passes the action stream to the epic', () {
        Stream<Action<dynamic>> epic(Stream<Action<dynamic>> actions, ValueObservable<int> state) {
          expect(actions, emitsInOrder(<AddIntAction>[const AddIntAction(42), const AddIntAction(1337)]));

          return const Stream<Action<dynamic>>.empty();
        }

        final store = Store<int>(intReducer, initialState: 42, epic: epic);
        store.dispatcher.add(const AddIntAction(42));
        store.dispatcher.add(const AddIntAction(1337));
      });

      test('dispatches the emitted actions', () async {
        Stream<Action<dynamic>> epic(Stream<Action<dynamic>> actions, ValueObservable<int> state) {
          return Observable<Action<dynamic>>(actions)
              .ofType(const TypeToken<AddIntAction>())
              .map((AddIntAction action) => const MultiplyIntAction(2));
        }

        final store = Store<int>(intReducer, initialState: 0, epic: epic);

        store.dispatcher.add(const AddIntAction(3));

        expect(
            store.state,
            emitsInOrder(<int>[
              0, // Initial state
              3, // AddIntAction(3)
              6, // MultiplyIntAction(2)
            ]));
      });

      test('passes the action stream to combined epics', () {
        Stream<Action<dynamic>> epicOne(Stream<Action<dynamic>> actions, ValueObservable<int> state) {
          expect(actions, emitsInOrder(<AddIntAction>[const AddIntAction(42), const AddIntAction(1337)]));

          return const Stream<Action<dynamic>>.empty();
        }

        Stream<Action<dynamic>> epicTwo(Stream<Action<dynamic>> actions, ValueObservable<int> state) {
          expect(actions, emitsInOrder(<AddIntAction>[const AddIntAction(42), const AddIntAction(1337)]));

          return const Stream<Action<dynamic>>.empty();
        }

        final store = Store<int>(intReducer, initialState: 42, epic: combineEpics(<Epic<int>>[epicOne, epicTwo]));
        store.dispatcher.add(const AddIntAction(42));
        store.dispatcher.add(const AddIntAction(1337));
      });
    });
  });
}

class AddIntAction implements Action<int> {
  const AddIntAction(this.payload);

  @override
  final int payload;

  @override
  String toString() => 'AddIntAction{payload: $payload}';
}

class MultiplyIntAction implements Action<int> {
  const MultiplyIntAction(this.payload);

  @override
  final int payload;

  @override
  String toString() => 'MultiplyIntAction{payload: $payload}';
}

int intReducer(int state, Action<dynamic> action) {
  if (action is AddIntAction) {
    return action.payload;
  }

  if (action is MultiplyIntAction) {
    return state * action.payload;
  }

  return state;
}
