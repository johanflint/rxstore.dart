import 'package:flutter/material.dart' hide Action;
import 'package:flutter_rxstore/flutter_rxstore.dart';
import 'package:rxstore/rxstore.dart';

class IncrementCounter implements Action {
  const IncrementCounter();
}

void main() {
  int reducer(int state, Action action) {
    if (action is IncrementCounter) {
      return state + 1;
    }

    return state;
  }

  // Create the store once when the app starts. This works better with hot reload
  // than in a build method of a widget.
  final store = Store<int>(reducer, initialState: 0);
  runApp(RxStoreApp(store: store));
}

class RxStoreApp extends StatelessWidget {
  RxStoreApp({required this.store});

  final Store<int> store;

  @override
  Widget build(BuildContext context) {
    // The StoreProvider should wrap your MaterialApp or CupertinoApp to ensure
    // that the store is always accessible
    return StoreProvider(
      store: store,
      child: MaterialApp(
        title: 'RxStore',
        home: Scaffold(
          appBar: AppBar(
            title: Text('RxStore'),
          ),
          body: Center(
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: <Widget>[
                Text('You have pushed the button this many times:'),
                // Flutters built-in StreamBuilder rebuilds every time the store
                // emits a new state. Note that the store is accessed directly
                // as we're still in the app's build method.
                StreamBuilder<int>(
                  stream: store.state,
                  builder: (context, snapshot) {
                    return Text(
                      '${snapshot.data}',
                      style: Theme.of(context).textTheme.headline4,
                    );
                  },
                ),
              ],
            ),
          ),
          floatingActionButton: MyFloatingActionButton(),
        ),
      ),
    );
  }
}

class MyFloatingActionButton extends StatelessWidget {
  @override
  Widget build(BuildContext context) {
    // Use the StoreProvider.of method to access the store
    final store = StoreProvider.of<int>(context);
    return FloatingActionButton(
      onPressed: () {
        // Dispatch the action to increment the counter
        store.dispatch(const IncrementCounter());
      },
      tooltip: 'Increment',
      child: Icon(Icons.add),
    );
  }
}
