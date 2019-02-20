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
  });
}

class AddIntAction implements Action<int> {
  const AddIntAction(this.payload);

  @override
  final int payload;
}

int intReducer(int state, Action<dynamic> action) {
  if (action is AddIntAction) {
    return action.payload;
  }

  return state;
}
