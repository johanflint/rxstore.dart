import 'package:flutter/widgets.dart';
import 'package:rxstore/rxstore.dart';

/// Provides the [Store] to all child widgets.
///
/// It is recommended to wrap the [MaterialApp] or [CupertinoApp] with the
/// provider to ensure that the store is always accessible.
class StoreProvider<State> extends InheritedWidget {
  /// Create a new [StoreProvider] by passing the store and child widget.
  const StoreProvider({Key? key, required Store<State> store, required Widget child})
      : _store = store,
        super(key: key, child: child);

  final Store<State> _store;

  /// Finds the nearest [StoreProvider] in the widget tree and returns the
  /// [Store].
  ///
  /// Important: provide the full generic type when calling this method
  /// otherwise Flutter will not be able to find the provider.
  static Store<State> of<State>(BuildContext context) {
    final StoreProvider<State>? provider = context.dependOnInheritedWidgetOfExactType<StoreProvider<State>>();
    if (provider == null) {
      throw StoreProviderError<State>();
    }

    return provider._store;
  }

  @override
  bool updateShouldNotify(StoreProvider<State> oldWidget) => _store != oldWidget._store;
}

/// Thrown if [StoreProvider.of] fails.
class StoreProviderError<T> extends Error {
  /// Creates a StoreProviderError.
  StoreProviderError();

  @override
  String toString() => 'No StoreProvider of type "$T" found, did you specify the full type information?';
}
