import 'package:flutter/widgets.dart' hide Action;
import 'package:flutter_rxstore/flutter_rxstore.dart';
import 'package:rxdart/rxdart.dart';
import 'package:rxstore/rxstore.dart';

/// Function that dispatches the action by passing it to the reducer and,
/// optionally, the epic.
typedef Dispatch = void Function(Action action);

/// Called whenever the state in the [Store] changes.
///
/// This builder must only return a widget and should not have any side
/// effects as it may be called multiple times.
typedef AsyncWidgetBuilder<T> = Widget Function(BuildContext context, T state, Dispatch dispatch);

/// Widget that builds itself based on the latest state from the [Store].
///
/// The initial data is always set as the state stream from the store is never
/// empty.
///
/// Important: provide the full generic type when using the widget otherwise
/// Flutter will not be able to find the provider.
class StateStreamBuilder<State> extends StatelessWidget {
  const StateStreamBuilder({
    Key? key,
    required this.builder,
  }) : super(key: key);

  /// The build strategy currently used by this builder.
  ///
  /// This builder must only return a widget and should not have any side
  /// effects as it may be called multiple times.
  final AsyncWidgetBuilder<State> builder;

  @override
  Widget build(BuildContext context) {
    final Store<State> store = StoreProvider.of<State>(context);

    return StreamBuilder<State>(
      stream: store.state.map((event) => event),
      initialData: store.state.value,
      builder: (BuildContext context, AsyncSnapshot<State> snapshot) {
        return builder(context, snapshot.requireData, store.dispatch);
      },
    );
  }
}
