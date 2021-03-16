import 'package:rxstore/rxstore.dart';

void main() {
  // Define a simple reducer to multiply the state
  int reducer(int state, Action action) {
    if (action is MultiplyInt) {
      return state * action.number;
    }
    return state;
  }

  // Create a store holding an int with an initial state of 42
  final store = Store<int>(reducer, initialState: 42);

  // Subscribe to state changes by printing them
  store.state.listen(print); // prints 42 (initial state), then 84

  // Dispatch an action
  store.dispatch(const MultiplyInt(2));
}

class MultiplyInt implements Action {
  const MultiplyInt(this.number);

  final int number;
}
