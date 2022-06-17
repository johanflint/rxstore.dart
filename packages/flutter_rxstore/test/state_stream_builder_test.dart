import 'package:flutter/widgets.dart' hide Action;
import 'package:flutter_rxstore/flutter_rxstore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxstore/rxstore.dart';

void main() {
  group('State stream builder', () {
    testWidgets('passes the initial state to the build function', (WidgetTester tester) async {
      final Store<int> store = Store<int>(intReducer, initialState: 42);

      int receivedState = 0;

      final StoreProvider<int> widget = StoreProvider<int>(
        store: store,
        child: StateStreamBuilder<int>(
          builder: (context, state) {
            receivedState = state;

            return const SizedBox();
          },
        ),
      );

      await tester.pumpWidget(widget);

      expect(receivedState, 42);
    });

    testWidgets('passes the updated state to the build function', (WidgetTester tester) async {
      final Store<int> store = Store<int>(intReducer, initialState: 42)..dispatch(AddInt(2));

      int receivedState = 0;

      final StoreProvider<int> widget = StoreProvider<int>(
        store: store,
        child: StateStreamBuilder<int>(
          builder: (context, state) {
            receivedState = state;

            return const SizedBox();
          },
        ),
      );

      await tester.pumpWidget(widget);

      expect(receivedState, 44);
    });
  });
}

class AddInt implements Action {
  const AddInt(this.payload);

  final int payload;

  @override
  String toString() => 'AddInt{payload: $payload}';
}

int intReducer(int state, Action action) {
  if (action is AddInt) {
    return state + action.payload;
  }

  return state;
}
