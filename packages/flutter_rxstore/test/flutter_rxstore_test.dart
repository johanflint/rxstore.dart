import 'package:flutter/widgets.dart' hide Action;
import 'package:flutter_rxstore/flutter_rxstore.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:rxstore/rxstore.dart';

void main() {
  group('Store provider', () {
    testWidgets('passes the store down to its descendants', (WidgetTester tester) async {
      final Store<int> store = Store<int>(reducer, initialState: 42);

      final StoreProvider<int> widget = StoreProvider<int>(
        store: store,
        child: StoreCaptor<int>(),
      );

      await tester.pumpWidget(widget);

      final StoreCaptor<int> captor = tester.firstWidget<StoreCaptor<int>>(find.byKey(StoreCaptor.captorKey));

      expect(captor.store, store);
    });

    testWidgets('throws an error if no store provider is found', (WidgetTester tester) async {
      final Store<int> store = Store<int>(reducer, initialState: 42);

      final Widget widget = StoreProvider<int>(store: store, child: StoreCaptor<String>());

      await tester.pumpWidget(widget);

      expect(tester.takeException(), isInstanceOf<StoreProviderError>());
    });

    testWidgets('should update child widgets if the store changes', (WidgetTester tester) async {
      Widget widget(int state) => StoreProvider<int>(
            store: Store<int>(reducer, initialState: state),
            child: StoreCaptor<int>(),
          );

      await tester.pumpWidget(widget(42));
      await tester.pumpWidget(widget(1337));

      final StoreCaptor<int> captor = tester.firstWidget<StoreCaptor<int>>(find.byKey(StoreCaptor.captorKey));

      expect(captor.store?.state.valueWrapper?.value, 1337);
    });
  });
}

int reducer(int store, Action action) => store;

// ignore: must_be_immutable
class StoreCaptor<State> extends StatelessWidget {
  static const Key captorKey = Key('storeCaptor');

  StoreCaptor() : super(key: captorKey);

  Store<State>? store;

  @override
  Widget build(BuildContext context) {
    store = StoreProvider.of<State>(context);
    return Container();
  }
}
