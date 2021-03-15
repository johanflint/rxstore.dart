# flutter_rxstore

A Flutter widget to easily obtain an [rxstore](https://pub.dev/packages/rxstore).

## StoreProvider

Pass the store to the provider by instantiating a `StoreProvider` widget.

```dart
StoreProvider(
  store: store,
  child: YourAwesomeApp()
);
```

If you need a reference to the store, call the static method `of<State>`. Be sure to pass the type of your store to the method, else it won't be able to find the provider.

```dart
final Store<State> store = StoreProvider.of<State>();
```
